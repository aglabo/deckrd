#!/usr/bin/env bash
# src: ./skills/deckrd/scripts/generate-doc.sh
# @(#) : deckrd script for executing AI prompts with configurable models
#
# Copyright (c) 2025 atsushifx <https://github.com/atsushifx>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

#
# @file generate-doc.sh
# @brief Execute AI prompt with configurable model and language
# @description
#   Runs an AI prompt with auto-loaded prompt and template files.
#   Supports multiple AI providers (OpenAI, Anthropic, OpenCode).
#
#   Execution flow:
#     cat <prompt> <template> <lang> <context> | <ai command>
#
# @example
#   # Generate requirements in Japanese
#   generate-doc.sh requirements "user input" --lang ja
#
#   # Generate spec with context from file
#   generate-doc.sh spec @docs/input.md --model claude-sonnet-4-5 --lang en
#
# @exitcode 0 Success
# @exitcode 1 Error during execution
#
# @author atsushifx
# @version 0.1.0
# @license MIT

# don't use  -u for checking error by Agent
set -eo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR

# Load bootstrap (defines SYMBOL, PROJECT_ROOT, DECKRD_LOCAL_DATA, DECKRD_LIB_DIR, etc.)
# shellcheck disable=SC1091
. "${SCRIPT_DIR}/../libs/bootstrap.sh"

# ============================================================================
# Library Dependencies
# ============================================================================

readonly DECKRD_LIB_DIR

# shellcheck disable=SC1091
. "${DECKRD_LIB_DIR}/session.sh"
# shellcheck disable=SC1091
. "${DECKRD_LIB_DIR}/config.sh"
# shellcheck disable=SC1091
. "${DECKRD_LIB_DIR}/ai-runner.sh"
# shellcheck disable=SC1091
. "${DECKRD_LIB_DIR}/normalize-doc-type.sh"

# ============================================================================
# deckrd Path Initialization
# ============================================================================

##
# @description Session file path
SESSION_FILE="${DECKRD_LOCAL_DATA}/session.json"

# ============================================================================
# Script Configuration
# ============================================================================

##
# @description deckrd assets directory
ASSETS_DIR="${SCRIPT_DIR}/../assets"
readonly ASSETS_DIR

# ============================================================================
# Functions
# ============================================================================

##
# @description Show usage information
show_usage() {
  cat <<EOF
Usage: generate-doc.sh <type> [context] [OPTIONS]

Execute AI prompt with auto-loaded prompt and template files.

Arguments:
  <type>            Document type (required): ${LONG_TYPES[*]}
  [context]         Context/input text or @filepath for file content
                    If starts with @, reads content from the specified file

Document Types:
  requirements    Generate requirements document
  spec            Generate specification document
  tasks           Generate task breakdown
  impl            Generate implementation guide
  review-explore  Review: explore phase
  review-harden   Review: harden phase
  review-fix      Review: fix phase

Options:
  --ai-model <model>  AI model name (default: loaded from session, or gpt-5.2)
                      Supported: gpt-*, o1-*, claude-*, haiku, sonnet, opus
                      Formats: 'model-name' or 'org/model-name'
  --lang <lang>       Document language (default: loaded from session, or system)
                      Values: system, en, ja, or any language name
  --output <file>     Output file path relative to DECKRD_BASE (default: stdout)
                      Example: --output requirements/requirements.md
                      → writes to \${DECKRD_BASE}/requirements/requirements.md
  -h, --help          Show this help message

Session Configuration:
  Default values for --ai-model and --lang are loaded from:
    .local/deckrd/session.json

File Resolution:
  requirements  →  prompts/requirements.prompt.md
                   templates/requirements.template.md

Execution Flow:
  cat <prompt.md> <template.md> | prepend LANG: <lang> | append <context> | <ai>

Examples:
  # Generate requirements in Japanese
  generate-doc.sh requirements "user input" --lang ja

  # Generate spec with context from file
  generate-doc.sh spec @docs/input.md --model claude-sonnet-4-5 --lang en

  # Read context from stdin
  echo "My requirements" | generate-doc.sh requirements --lang ja
EOF
}

##
# @description Parse command-line options
parse_options() {
  local positional_count=0

  while [[ $# -gt 0 ]]; do
    case "$1" in
    -h | --help)
      show_usage
      exit 0
      ;;
    --ai-model)
      if [[ -z "${2:-}" ]]; then
        echo "Error: --ai-model requires a model name" >&2
        exit 1
      fi
      local _validated
      _validated=$(validate_ai_model "$2") || {
        echo "$_validated" >&2
        exit 1
      }
      config_set "ai_model" "$2"
      shift 2
      ;;
    --ai-model=*)
      local _model="${1#*=}"
      local _validated
      _validated=$(validate_ai_model "$_model") || {
        echo "$_validated" >&2
        exit 1
      }
      config_set "ai_model" "$_model"
      shift
      ;;
    --lang)
      if [[ -z "${2:-}" ]]; then
        echo "Error: --lang requires a value" >&2
        exit 1
      fi
      config_set "lang" "$2"
      shift 2
      ;;
    --lang=*)
      config_set "lang" "${1#*=}"
      shift
      ;;
    --output)
      if [[ -z "${2:-}" ]]; then
        echo "Error: --output requires a file path" >&2
        exit 1
      fi
      config_set "output_file" "$2"
      shift 2
      ;;
    --output=*)
      config_set "output_file" "${1#*=}"
      shift
      ;;
    -*)
      echo "Error: Unknown option: $1" >&2
      show_usage
      exit 1
      ;;
    *)
      if [[ $positional_count -eq 0 ]]; then
        if [[ "$1" == @* ]]; then
          config_set "doc_type" "${1:1}"
          config_set "prompt_mode" "1"
        else
          config_set "doc_type" "$1"
          config_set "prompt_mode" "0"
        fi
      elif [[ $positional_count -eq 1 ]]; then
        config_set "context_input" "$1"
      else
        echo "Error: Too many positional arguments" >&2
        show_usage
        exit 1
      fi
      positional_count=$((positional_count + 1))
      shift
      ;;
    esac
  done
}

##
# @description Resolve context input (handle @filepath syntax)
# @arg $1 string Context input
# @stdout Resolved context content
# @note @filepath is resolved relative to DECKRD_BASE
resolve_context() {
  local input="$1"

  if [[ -z "$input" ]]; then
    echo ""
    return 0
  fi

  if [[ "$input" == @* ]]; then
    local relative_path="${input:1}"
    local filepath="${DECKRD_BASE}/${relative_path}"

    if [[ ! -f "$filepath" ]]; then
      echo "Error: Context file not found: $filepath" >&2
      echo "  (DECKRD_BASE: ${DECKRD_BASE})" >&2
      return 1
    fi

    cat "$filepath"
  else
    echo "$input"
  fi
}

##
# @description Get prompt content from doc-type or detect prompt-file mode
# @arg $1 string Raw first argument (doc-type name or @<keyword>)
# @stdout Prompt content string
# @return 0  doc-type mode: prompt content written to stdout
# @return 1  prompt-file mode: caller should use cat on PROMPT_PATH
get_prompt() {
  local arg="$1"

  if [[ "$arg" == @* ]]; then
    # @<keyword> mode: caller uses cat on PROMPT_PATH
    return 1
  fi

  # prompt-text mode: arg is the prompt string itself
  echo "$arg"
  return 0
}

##
# @description Resolve doc type from @<keyword> argument
# @arg $1 string Argument starting with @ (e.g. @requirements)
# @stdout Normalized doc type string (e.g. requirements)
# @return 0  success
# @return 1  invalid argument (missing @, or unsupported doctype)
get_prompt_file() {
  local arg="$1"

  if [[ "$arg" != @* ]]; then
    echo "Error: argument must start with @"
    return 1
  fi

  local doc_type="${arg:1}"
  local normalized
  normalized=$(normalize_doc_type "$doc_type") || return 1

  echo "$normalized"
}

##
# @description Resolve prompt and template paths for document type
# @arg $1 string Document type (normalized form from validate_doc_type)
# @stdout Two lines: prompt path, template path
resolve_doc_paths() {
  local doc_type="$1"

  local prompt_path="${ASSETS_DIR}/prompts/${doc_type}.prompt.md"
  local template_path="${ASSETS_DIR}/templates/${doc_type}.template.md"

  if [[ ! -f "$prompt_path" ]]; then
    echo "Error: Prompt file not found: $prompt_path" >&2
    return 1
  fi

  if [[ ! -f "$template_path" ]]; then
    echo "Error: Template file not found: $template_path" >&2
    return 1
  fi

  echo "$prompt_path"
  echo "$template_path"
}

##
# @description Build combined input for AI
# @arg $1 string Prompt file path
# @arg $2 string Template file path
# @arg $3 string Language setting
# @arg $4 string Context input
# @stdout Combined content
build_ai_input() {
  local prompt_path="$1"
  local template_path="$2"
  local lang="$3"
  local context="$4"

  echo "===== PROMPT ====="
  cat "$prompt_path"
  echo ""

  echo "===== TEMPLATE ====="
  cat "$template_path"
  echo ""

  echo "===== PARAMETERS ====="
  echo "LANG: ${lang}"
  echo ""

  if [[ -n "$context" ]]; then
    echo "===== USER INPUT ====="
    echo "$context"
    echo "===== END INPUT ====="
  fi
}

##
# @description Execute prompt with AI model
# @stdout AI response
# @see run_ai
execute_prompt() {
  local prompt_path="$1"
  local template_path="$2"
  local lang="$3"
  local context="$4"

  local ai_model
  ai_model=$(config_get "ai_model")

  build_ai_input "$prompt_path" "$template_path" "$lang" "$context" | run_ai "$ai_model" 300
}

##
# @description Output result to stdout or file
# @arg $1 string Result
# @arg $2 string Output file (relative to DECKRD_BASE)
output_result() {
  local result="$1"
  local output_file="$2"

  if [[ -z "$output_file" ]]; then
    echo "$result"
  else
    # Prepend DECKRD_BASE to output path
    local full_path="${DECKRD_BASE}/${output_file}"
    mkdir -p "$(dirname "$full_path")"
    echo "$result" >"$full_path"
    echo "Output written to: $full_path" >&2
  fi
}

# ============================================================================
# Main Execution
# ============================================================================

main() {
  # セッションファイルパス
  local session_file="${SESSION_FILE}"

  # config 初期化（デフォルト + セッション読込）
  config_init "$session_file"

  # コマンドライン引数の解析
  parse_options "$@"

  # DECKRD_BASE の解決（CONFIG 経由）
  local deckrd_base
  deckrd_base=$(config_get "deckrd_base")
  if [[ -z "$deckrd_base" ]]; then
    deckrd_base="${DECKRD_DOCS:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)/docs/.deckrd}"
    config_set "deckrd_base" "$deckrd_base"
  fi
  export DECKRD_BASE="$deckrd_base"

  # doc_type チェック
  local doc_type prompt_mode
  doc_type=$(config_get "doc_type")
  prompt_mode=$(config_get "prompt_mode")

  if [[ -z "$doc_type" ]]; then
    echo "Error: prompt or @keyword is required" >&2
    show_usage
    exit 1
  fi

  # @keyword モード: prompt/template パスを解決
  if [[ "$prompt_mode" -eq 1 ]]; then
    local paths
    paths=$(resolve_doc_paths "$doc_type") || exit 1
    config_set "prompt_path" "$(echo "$paths" | head -1)"
    config_set "template_path" "$(echo "$paths" | tail -1)"
  fi

  # コンテキスト入力の解決
  local context_input
  context_input=$(config_get "context_input")
  if [[ -n "$context_input" ]]; then
    context_input=$(resolve_context "$context_input") || exit 1
    config_set "context_input" "$context_input"
  elif [[ ! -t 0 ]]; then
    config_set "context_input" "$(cat)"
  fi

  # デバッグ出力
  config_all >&2
  echo "" >&2

  # prompt_path チェック
  local prompt_path
  prompt_path=$(config_get "prompt_path")
  if [[ -z "$prompt_path" ]]; then
    echo "Error: No prompt file resolved. Use @<type> to specify document type." >&2
    exit 1
  fi

  # 実行
  local template_path lang context
  template_path=$(config_get "template_path")
  lang=$(config_get "lang")
  context=$(config_get "context_input")

  local result
  result=$(execute_prompt "$prompt_path" "$template_path" "$lang" "$context")

  local output_file
  output_file=$(config_get "output_file")
  output_result "$result" "$output_file"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  main "$@"
fi
