#!/usr/bin/env bash
# scripts/libs/ai-runner.sh - Run AI model with prompt and return response
#
# Copyright (c) 2026- atsushifx <https://github.com/atsushifx>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT
#
# @version 0.1.0
# USAGE: dot-source this file, do NOT execute directly.
#   . "$(dirname "${BASH_SOURCE[0]}")/ai-runner.sh"
#   NG: `. "<path>/ai-runner.sh" echo "prompt" | run_ai "sonnet"` は `.` が echo を飲み込み stdin が空になる

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

# validate_ai_model - Validate AI model identifier
#
# @arg $1  string  AI model identifier: "<org>/<model>" or "<model>"
# @stdout  string  モデル識別子そのまま（有効な場合） / エラーメッセージ（無効な場合）
# @exitcode 0  有効なモデル識別子
# @exitcode 1  無効なモデル識別子 or 空引数
validate_ai_model() {
  local model="${1:-}"

  if [[ -z "$model" ]]; then
    echo "Error: AI model is required" >&2
    return 1
  fi

  # <provider>/ 形式（モデル部分が空）は無効
  if [[ "$model" == */ ]]; then
    echo "Error: unknown AI model: ${model}" >&2
    return 1
  fi

  if resolve_ai_cli "$model" >/dev/null 2>&1; then
    echo "$model"
    return 0
  fi

  echo "Error: unknown AI model: ${model}" >&2
  return 1
}

# resolve_ai_model - Validate and normalize AI model identifier per provider rules
#
# provider ごとにモデル名の形式を検証し、プレフィックスを除去した正規化モデル名を返す。
# 形式不明な provider（copilot, opencode）はモデル部分をそのまま返す。
#
# @arg $1  string  AI model identifier: "<provider>/<model>" or "<model>"
# @stdout  string  正規化されたモデル名（有効な場合） / エラーメッセージ（無効な場合）
# @exitcode 0  有効
# @exitcode 1  無効 or 空引数
resolve_ai_model() {
  local model="${1:-}"

  if [[ -z "$model" ]]; then
    echo "Error: AI model is required" >&2
    return 1
  fi

  # <provider>/ 形式（モデル部分が空）は無効
  if [[ "$model" == */ ]]; then
    local provider="${model%/}"
    echo "Error: model name is required after provider: ${provider}" >&2
    return 1
  fi

  local raw_model
  case "$model" in
  anthropic/*)
    raw_model="${model#anthropic/}"
    case "$raw_model" in
    claude-*) echo "$raw_model" ;;
    *)
      echo "Error: invalid model for anthropic: ${raw_model}" >&2
      return 1
      ;;
    esac
    ;;
  claude-* | default | sonnet | opus | haiku | sonnet-1m | opusplan)
    echo "$model"
    ;;
  openai/*)
    raw_model="${model#openai/}"
    case "$raw_model" in
    gpt-* | o1-* | o3-*) echo "$raw_model" ;;
    *)
      echo "Error: invalid model for openai: ${raw_model}" >&2
      return 1
      ;;
    esac
    ;;
  gpt-* | o1-* | o3-*)
    echo "$model"
    ;;
  googleai/*)
    raw_model="${model#googleai/}"
    case "$raw_model" in
    gemini-*) echo "$raw_model" ;;
    *)
      echo "Error: invalid model for google: ${raw_model}" >&2
      return 1
      ;;
    esac
    ;;
  google/*)
    raw_model="${model#google/}"
    case "$raw_model" in
    gemini-*) echo "$raw_model" ;;
    *)
      echo "Error: invalid model for google: ${raw_model}" >&2
      return 1
      ;;
    esac
    ;;
  gemini-*)
    echo "$model"
    ;;
  github/*)
    raw_model="${model#github/}"
    case "$raw_model" in
    claude-* | gpt-* | gemini-* | grok-*) echo "$raw_model" ;;
    *)
      echo "Error: invalid model for copilot: ${raw_model}" >&2
      return 1
      ;;
    esac
    ;;
  github-copilot/*)
    raw_model="${model#github-copilot/}"
    case "$raw_model" in
    claude-* | gpt-* | gemini-* | grok-*) echo "$raw_model" ;;
    *)
      echo "Error: invalid model for copilot: ${raw_model}" >&2
      return 1
      ;;
    esac
    ;;
  copilot/*)
    raw_model="${model#copilot/}"
    case "$raw_model" in
    claude-* | gpt-* | gemini-* | grok-*) echo "$raw_model" ;;
    *)
      echo "Error: invalid model for copilot: ${raw_model}" >&2
      return 1
      ;;
    esac
    ;;
  opencode/*)
    raw_model="${model#opencode/}"
    echo "$raw_model"
    ;;
  *)
    echo "Error: unknown AI model: ${model}" >&2
    return 1
    ;;
  esac

  return 0
}

# _build_ai_command - Build CLI command array for given CLI and model
#
# Prompt is passed via stdin (pipe). Do NOT include prompt in the array.
#
# 組み立てる argv は呼び出し元の cwd に依存してはならない。run_ai は cd しないので、
# cwd に制約を持つ CLI には制約を外すフラグをここで渡しきる (codex 分岐を参照)。
#
# @arg $1  string   CLI name (e.g. "claude", "codex")
# @arg $2  string   AI model identifier
# @arg $3  nameref  Array variable to store the command (passed by name)
# @exitcode 0  Success
# @exitcode 1  Unknown CLI
_build_ai_command() {
  local cli="$1"
  local model="$2"
  local -n _cmd_ref="$3"
  local _ai_options=()

  case "$cli" in
  claude)
    # Claude aliases are passed as-is; claude CLI resolves them natively.
    # Special handling: sonnet-1m adds --context-window, opusplan adds --thinking.

    case "$model" in
    default)
      _ai_options=()
      ;;
    sonnet-1m)
      _ai_options=("--model" "sonnet" "--context-window" "1000000")
      ;;
    opusplan)
      _ai_options=("--model" "opusplan" "--thinking")
      ;;
    *)
      _ai_options=("--model" "$model")
      ;;
    esac
    _ai_options+=("--strict-mcp-config" "--mcp-config" '{"mcpServers":{}}')
    _cmd_ref=("claude" "${_ai_options[@]}" "-p")
    ;;
  codex)
    # codex exec は cwd が git リポジトリ内でも ~/.codex/config.toml の trusted project
    # でもないと起動を拒む (`Not inside a trusted directory and --skip-git-repo-check was
    # not specified.`)。run_ai は cd せず呼び出し元の cwd をそのまま引き継ぐので、
    # リポジトリ外から dot-source して呼ばれた時点で落ちる。しかも codex-cli 0.157 系は
    # この拒否を exit 0 で返すため、stdout が空のまま「成功」に化ける。
    # argv が cwd に依存しないことが _build_ai_command の契約なので、
    # --skip-git-repo-check は条件付きではなく常に付ける。
    # --ignore-user-config は claude 分岐の --strict-mcp-config / 空 MCP 設定と同じ
    # 「ユーザー設定の MCP を読ませない」役割である。これがないと codex exec は
    # ~/.codex/config.toml の [mcp_servers.*] を起動し、MCP サーバが cwd 配下へ作業ファイル
    # (`.cocoindex_code/` など) を作って掴んだままにする。run_ai は cd しないので、
    # 汚れるのは呼び出し元の cwd である。-c 'mcp_servers={}' では止まらない。codex は TOML の
    # テーブルを再帰マージするので、空テーブルでは既存のキーが消えない。
    # 認証は維持される。auth.json は config.toml ではなく CODEX_HOME から読まれる
    # (help: `Do not load $CODEX_HOME/config.toml; auth still uses CODEX_HOME`)。
    # 落ちるのは config.toml に書かれた設定だけであり、そのすべてが落ちる。model_reasoning_effort
    # や service_tier のような既定値のほか、[windows] sandbox や [shell_environment_policy]、
    # 独自の model_providers も含む。~/.codex/AGENTS.md は config.toml 由来ではないので
    # 読まれ続ける (実測)。モデルは --model で明示しているので影響しない。
    # 副作用: コマンド実行を許す設定 ([windows] sandbox = "elevated" など) も落ちるため、
    # codex にシェルコマンドを実行させたい用途にこのフラグは使えない。run_ai はプロンプトを
    # 渡して stdout を読むだけなので影響しない。codex にコマンドを走らせる呼び出し
    # (deckrd-review / code-reviewer) では付けてはならない。
    # 代替が使えない理由と検証の記録は docs/specs/mcp-servers.md の
    # 「Isolating Codex from the user's MCP servers」に置く。
    # -s read-only は CLI に書き込み権限を渡さないための隔離である。生成物をファイルへ書くのは
    # run_ai の呼び出し元だけで、CLI 側に書き込み権限は要らない。
    # --color never は stdout を「AI の応答本文だけ」に保つ。ANSI が混ざると stdout 契約が崩れる。
    _cmd_ref=("codex" "exec" "--model" "$model" "--skip-git-repo-check" "--ignore-user-config" "-s" "read-only" "--color" "never")
    ;;
  gemini)
    _cmd_ref=("gemini" "--model" "$model")
    ;;
  copilot)
    # Extract model name after prefix (github/<model>, github-copilot/<model>, copilot/<model>)
    local copilot_model="${model#*/}"
    # Validate against supported copilot model families: claude-*, gpt-*, gemini-*, grok-*
    case "$copilot_model" in
    claude-* | gpt-* | gemini-* | grok-*)
      _cmd_ref=("copilot" "--model" "$copilot_model")
      ;;
    *)
      return 1
      ;;
    esac
    ;;
  opencode)
    _cmd_ref=("opencode" "run" "--model" "$model")
    ;;
  *)
    return 1
    ;;
  esac
}

# resolve_ai_timeout - Resolve the timeout (in seconds) used to run an AI CLI
#
# Priority: positional arg > DECKRD_AI_TIMEOUT > default (300). Keep this the single
# source of the default so the docstring and the callers cannot drift apart again.
#
# @arg $1  int     Timeout in seconds. Empty or omitted falls back to DECKRD_AI_TIMEOUT
# @stdout  int     Resolved timeout in seconds (no trailing newline)
# @exitcode 0  Always succeeds; the value itself is validated by timeout(1)
resolve_ai_timeout() {
  printf '%s' "${1:-${DECKRD_AI_TIMEOUT:-300}}"
}

# _ai_stdin_is_tty - stdin が端末かを判定する。ShellSpec から差し替えられるよう関数に切り出す
#
# @exitcode 0  stdin は端末である
# @exitcode 1  stdin は端末ではない（パイプ・リダイレクト・クローズ）
_ai_stdin_is_tty() {
  [[ -t 0 ]]
}

# run_ai - Run AI model with prompt via stdin pipe and return response
#
# @arg $1  string  AI model identifier: "<org>/<model>" or "<model>"
# @arg $2  int     Timeout in seconds. Empty or omitted falls back to DECKRD_AI_TIMEOUT,
#                  then to 300. See resolve_ai_timeout. It bounds the stdin read and the
#                  CLI run separately, so the worst-case total wait is 2 x this value
# @stdin   string  Prompt text. Required: it MUST be piped in. A terminal stdin or an
#                  empty pipe is an error, never a request with an empty prompt
# @stdout  string  AI response only. The 1 / 2 / 3 / 4 / 124 error branches write nothing
# @stderr  string  Error reason on failure
# @exitcode 0    Success
# @exitcode 1    Unknown model / empty argument
# @exitcode 2    CLI command not found
# @exitcode 3    stdin が端末である / stdin が空である / stdin の読み取りに失敗した
# @exitcode 4    CLI が exit 0 を返したのに応答が空だった
# @exitcode 124  Timeout exceeded (stdin の読み取り中・CLI の実行中のどちらでも)
#
# Usage:
#   # source と実行は必ず別コマンドにする
#   . "<path>/ai-runner.lib.sh"
#   echo "prompt" | run_ai "sonnet"
#   echo "prompt" | run_ai "openai/gpt-4o" 30
#
#   # NG: `.` が echo を引数として飲み込み、stdin が空になる
#   #   . "<path>/ai-runner.lib.sh" echo "prompt" | run_ai "sonnet"
run_ai() {
  local model="${1:-}"
  local timeout_sec
  timeout_sec="$(resolve_ai_timeout "${2:-}")"

  if [[ -z "$model" ]]; then
    echo "Error: model is required" >&2
    return 1
  fi

  local cli
  cli=$(resolve_ai_cli "$model") || {
    echo "Error: unknown model: $model" >&2
    return 1
  }

  if ! command -v "$cli" >/dev/null 2>&1; then
    echo "Error: CLI not found: $cli" >&2
    return 2
  fi

  local _AI_CMD=()
  _build_ai_command "$cli" "$model" _AI_CMD || {
    echo "Error: unsupported model for $cli: $model" >&2
    return 1
  }

  # プロンプトは stdin だけで受け取る。端末のままだと cat が入力待ちで止まり、
  # 空 stdin をそのまま渡すと CLI 側の「入力が無い」エラーに化けて原因が追えない。
  if _ai_stdin_is_tty; then
    echo "Error: prompt must be piped via stdin (model: $model)" >&2
    return 3
  fi

  # stdin の読み取りも timeout 配下に置く。プロデューサがパイプを開いたまま止まると、
  # ここが CLI 起動前に無制限にブロックしてしまう。
  # 代入を local と分けるのは、local の終了ステータスが cat の終了ステータスを
  # 上書きして read_status が常に 0 になるのを避けるためである。
  local prompt read_status
  prompt=$(timeout "$timeout_sec" cat)
  read_status=$?

  if [[ $read_status -eq 124 ]]; then
    echo "Error: timeout after ${timeout_sec}s while reading the prompt from stdin (model: $model)" >&2
    return 124
  fi

  if [[ $read_status -ne 0 ]]; then
    echo "Error: failed to read prompt from stdin (model: $model)" >&2
    return 3
  fi

  if [[ -z "$prompt" ]]; then
    echo "Error: empty prompt on stdin (model: $model)" >&2
    return 3
  fi

  local output
  output=$(timeout "$timeout_sec" "${_AI_CMD[@]}" <<<"$prompt")
  local exit_code=$?

  if [[ $exit_code -eq 124 ]]; then
    echo "Error: timeout after ${timeout_sec}s (model: $model)" >&2
    return 124
  fi

  # CLI が exit 0 なのに何も返さない場合を失敗として扱う。codex-cli 0.157 系は
  # 起動拒否 (trusted directory / git リポジトリ判定) を exit 0 + 空 stdout で返すため、
  # ここを素通しすると呼び出し元には「空の応答で成功した」としか見えない。
  # 他のエラー経路と同じく stdout へは何も書かず、理由は stderr だけが伝える。
  if [[ $exit_code -eq 0 && -z "$output" ]]; then
    echo "Error: ${cli} exited 0 without a response (model: $model); see its stderr above" >&2
    return 4
  fi

  echo "$output"
  return $exit_code
}
