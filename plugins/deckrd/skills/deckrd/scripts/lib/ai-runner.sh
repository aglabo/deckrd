#!/usr/bin/env bash
# scripts/lib/ai-runner.sh - Run AI model with prompt and return response
#
# Copyright (c) 2026- atsushifx <https://github.com/atsushifx>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT
#
# USAGE: dot-source this file, do NOT execute directly.
#   . "$(dirname "${BASH_SOURCE[0]}")/ai-runner.sh"

# Guard: prevent re-sourcing
if [[ -n "${_AI_RUNNER_LOADED:-}" ]]; then
  return 0
fi
readonly _AI_RUNNER_LOADED=1

# resolve_ai_cli - Resolve AI model name to CLI command name
#
# @arg $1  string  AI model identifier: "<org>/<model>" or "<model>"
# @stdout  string  CLI command name (e.g. "claude", "codex", "gemini")
# @exitcode 0  Success
# @exitcode 1  Unknown model / empty argument
resolve_ai_cli() {
  local model="${1:-}"

  if [[ -z "$model" ]]; then
    return 1
  fi

  case "$model" in
    anthropic/* | claude-* | default | sonnet | opus | haiku | sonnet-1m | opusplan)
      echo "claude"
      ;;
    openai/* | gpt-* | o1-* | o3-*)
      echo "codex"
      ;;
    googleai/* | google/* | gemini-*)
      echo "gemini"
      ;;
    github/* | github-copilot/* | copilot/*)
      echo "copilot"
      ;;
    opencode/*)
      echo "opencode"
      ;;
    *)
      return 1
      ;;
  esac

  return 0
}

# _build_ai_command - Build CLI command array for given CLI and model
#
# Prompt is passed via stdin (pipe). Do NOT include prompt in the array.
#
# @arg $1  string  CLI name (e.g. "claude", "codex")
# @arg $2  string  AI model identifier
# @set _AI_CMD  array  Command array ready for execution (stdin = prompt)
# @exitcode 0  Success
_build_ai_command() {
  local cli="$1"
  local model="$2"

  case "$cli" in
    claude)
      # Claude aliases are passed as-is; claude CLI resolves them natively.
      # Special handling: sonnet-1m adds --context-window, opusplan adds --thinking.
      case "$model" in
        default)   _AI_CMD=( "claude" "-p" ) ;;
        sonnet-1m) _AI_CMD=( "claude" "--model" "sonnet" "-p" "--context-window" "1000000" ) ;;
        opusplan)  _AI_CMD=( "claude" "--model" "opusplan" "-p" "--thinking" ) ;;
        *)         _AI_CMD=( "claude" "--model" "$model" "-p" ) ;;
      esac
      ;;
    codex)
      _AI_CMD=( "codex" "exec" "--model" "$model" )
      ;;
    gemini)
      _AI_CMD=( "gemini" "--model" "$model" "-p" )
      ;;
    copilot)
      # Extract model name after prefix (github/<model>, github-copilot/<model>, copilot/<model>)
      local copilot_model="${model#*/}"
      # Validate against supported copilot model families: claude-*, gpt-*, gemini-*, grok-*
      case "$copilot_model" in
        claude-* | gpt-* | gemini-* | grok-*)
          _AI_CMD=( "copilot" "suggest" "--model" "$copilot_model" )
          ;;
        *)
          return 1
          ;;
      esac
      ;;
    opencode)
      _AI_CMD=( "opencode" "run" "--model" "$model" )
      ;;
  esac
}

# run_ai - Run AI model with prompt via stdin pipe and return response
#
# @arg $1  string  AI model identifier: "<org>/<model>" or "<model>"
# @arg $2  int     Timeout in seconds (default: 5)
# @stdin   string  Prompt text (piped in)
# @stdout  string  AI response on success; exit status code on error
# @stderr  string  Error reason on failure
# @exitcode 0    Success
# @exitcode 1    Unknown model / empty argument
# @exitcode 2    CLI command not found
# @exitcode 124  Timeout exceeded
#
# Usage:
#   echo "prompt" | run_ai "sonnet"
#   echo "prompt" | run_ai "openai/gpt-4o" 30
run_ai() {
  local model="${1:-}"
  local timeout_sec="${2:-5}"

  if [[ -z "$model" ]]; then
    echo "Error: model is required" >&2
    echo 1
    return 1
  fi

  local cli
  cli=$(resolve_ai_cli "$model") || {
    echo "Error: unknown model: $model" >&2
    echo 1
    return 1
  }

  if ! command -v "$cli" >/dev/null 2>&1; then
    echo "Error: CLI not found: $cli" >&2
    echo 2
    return 2
  fi

  local _AI_CMD=()
  _build_ai_command "$cli" "$model" || {
    echo "Error: unsupported model for $cli: $model" >&2
    echo 1
    return 1
  }

  local output
  output=$(timeout "$timeout_sec" "${_AI_CMD[@]}" 2>&1)
  local exit_code=$?

  if [[ $exit_code -eq 124 ]]; then
    echo "Error: timeout after ${timeout_sec}s (model: $model)" >&2
    echo 124
    return 124
  fi

  echo "$output"
  return $exit_code
}
