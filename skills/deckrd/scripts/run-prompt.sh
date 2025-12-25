#!/usr/bin/env bash
# deckrd run-prompt.sh - Execute prompt with specified model and language
#
# @file run-prompt.sh
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
#   run-prompt.sh requirements "ユーザー入力" --lang ja
#
#   # Generate spec with context from file
#   run-prompt.sh spec @docs/input.md --model claude-sonnet-4-5 --lang en
#
# @exitcode 0 Success
# @exitcode 1 Error during execution
#
# @author atsushifx
# @version 2.1.0
# @license MIT

set -euo pipefail

# ============================================================================
# deckrd Path Initialization
# ============================================================================

##
# @description Session file path
SESSION_FILE="docs/.deckrd/.session.json"

##
# @description deckrd base path (set from session)
DECKRD_BASE=""

##
# @description Load DECKRD_BASE from session.json
# Reads "active" field and sets DECKRD_BASE="docs/.deckrd/${active}"
load_deckrd_base_from_session() {
  if [[ ! -f "$SESSION_FILE" ]]; then
    return 0
  fi

  local active=""

  # Try jq first (most reliable)
  if command -v jq >/dev/null 2>&1; then
    active=$(jq -r '.active // empty' "$SESSION_FILE" 2>/dev/null || true)
  # Fallback to node
  elif command -v node >/dev/null 2>&1; then
    active=$(node -e "try{console.log(require('./${SESSION_FILE}').active||'')}catch(e){}" 2>/dev/null || true)
  fi

  if [[ -n "$active" ]]; then
    DECKRD_BASE="docs/.deckrd/${active}"
    export DECKRD_BASE
  fi
}

# Initialize DECKRD_BASE from session
load_deckrd_base_from_session

# Set default if not loaded
if [[ -z "${DECKRD_BASE}" ]]; then
  DECKRD_BASE="docs/.deckrd"
  export DECKRD_BASE
fi

# ============================================================================
# Script Configuration
# ============================================================================

##
# @description Script directory path
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR

##
# @description deckrd assets directory
ASSETS_DIR="${SCRIPT_DIR}/../assets"
readonly ASSETS_DIR

##
# @description Supported document types
SUPPORTED_TYPES=("requirements" "spec" "tasks" "impl")

##
# @description Default AI model
AI_MODEL="gpt-5.2"

##
# @description Document language (system, en, ja, etc.)
LANG_OPT="system"

##
# @description Document type (requirements, spec, tasks, impl)
DOC_TYPE=""

##
# @description Context input (from stdin or argument)
CONTEXT_INPUT=""

##
# @description Output file path (empty = stdout)
OUTPUT_FILE=""

# ============================================================================
# Functions
# ============================================================================

##
# @description Show usage information
show_usage() {
  cat <<EOF
Usage: run-prompt.sh <type> [context] [OPTIONS]

Execute AI prompt with auto-loaded prompt and template files.

Arguments:
  <type>            Document type (required): ${SUPPORTED_TYPES[*]}
  [context]         Context/input text or @filepath for file content
                    If starts with @, reads content from the specified file

Document Types:
  requirements    Generate requirements document
  spec            Generate specification document
  tasks           Generate task breakdown
  impl            Generate implementation guide

Options:
  --model <model>   AI model name (default: gpt-5.2)
                    Supported: gpt-*, o1-*, claude-*, haiku, sonnet, opus
  --lang <lang>     Document language (default: system)
                    Values: system, en, ja, or any language name
  --output <file>   Output file path relative to DECKRD_BASE (default: stdout)
                    Example: --output requirements/requirements.md
                    → writes to \${DECKRD_BASE}/requirements/requirements.md
  -h, --help        Show this help message

File Resolution:
  requirements  →  prompts/requirements.prompt.md
                   templates/requirements.template.md

Execution Flow:
  cat <prompt.md> <template.md> | prepend LANG: <lang> | append <context> | <ai>

Examples:
  # Generate requirements in Japanese
  run-prompt.sh requirements "ユーザー入力" --lang ja

  # Generate spec with context from file
  run-prompt.sh spec @docs/input.md --model claude-sonnet-4-5 --lang en

  # Read context from stdin
  echo "My requirements" | run-prompt.sh requirements --lang ja
EOF
}

##
# @description Parse command-line options
parse_options() {
  local positional_count=0

  while [[ $# -gt 0 ]]; do
    case "$1" in
      -h|--help)
        show_usage
        exit 0
        ;;
      --model)
        if [[ -z "${2:-}" ]]; then
          echo "Error: --model requires a model name" >&2
          exit 1
        fi
        AI_MODEL="$2"
        shift 2
        ;;
      --model=*)
        AI_MODEL="${1#*=}"
        shift
        ;;
      --lang)
        if [[ -z "${2:-}" ]]; then
          echo "Error: --lang requires a value" >&2
          exit 1
        fi
        LANG_OPT="$2"
        shift 2
        ;;
      --lang=*)
        LANG_OPT="${1#*=}"
        shift
        ;;
      --output)
        if [[ -z "${2:-}" ]]; then
          echo "Error: --output requires a file path" >&2
          exit 1
        fi
        OUTPUT_FILE="$2"
        shift 2
        ;;
      --output=*)
        OUTPUT_FILE="${1#*=}"
        shift
        ;;
      -*)
        echo "Error: Unknown option: $1" >&2
        show_usage
        exit 1
        ;;
      *)
        if [[ $positional_count -eq 0 ]]; then
          DOC_TYPE="$1"
        elif [[ $positional_count -eq 1 ]]; then
          CONTEXT_INPUT="$1"
        else
          echo "Error: Too many positional arguments" >&2
          show_usage
          exit 1
        fi
        ((positional_count++))
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
# @description Validate document type
# @arg $1 string Document type
validate_doc_type() {
  local doc_type="$1"

  for supported in "${SUPPORTED_TYPES[@]}"; do
    if [[ "$doc_type" == "$supported" ]]; then
      return 0
    fi
  done

  echo "Error: Unknown document type: $doc_type" >&2
  echo "Supported types: ${SUPPORTED_TYPES[*]}" >&2
  exit 1
}

##
# @description Map document type to file base name
# @arg $1 string Document type (short form)
# @stdout File base name (full form)
map_doc_type_to_filename() {
  local doc_type="$1"
  case "$doc_type" in
    requirements) echo "requirements" ;;
    spec)         echo "specifications" ;;
    impl)         echo "implementation" ;;
    tasks)        echo "tasks" ;;
    *)            echo "$doc_type" ;;
  esac
}

##
# @description Resolve prompt and template paths for document type
# @arg $1 string Document type
# @stdout Two lines: prompt path, template path
resolve_doc_paths() {
  local doc_type="$1"
  local file_base
  file_base=$(map_doc_type_to_filename "$doc_type")

  local prompt_path="${ASSETS_DIR}/prompts/${file_base}.prompt.md"
  local template_path="${ASSETS_DIR}/templates/${file_base}.template.md"

  if [[ ! -f "$prompt_path" ]]; then
    echo "Error: Prompt file not found: $prompt_path" >&2
    exit 1
  fi

  if [[ ! -f "$template_path" ]]; then
    echo "Error: Template file not found: $template_path" >&2
    exit 1
  fi

  echo "$prompt_path"
  echo "$template_path"
}

##
# @description Get CLI command for specified AI model
# @arg $1 string AI model name
# @stdout CLI command string
get_model_command() {
  local model="${1:-gpt-5.2}"
  local cmd=""

  case "$model" in
    gpt-* | o1-*)
      cmd="codex exec --model ${model}"
      ;;
    claude-* | haiku | sonnet | opus)
      cmd="claude -p --model ${model}"
      ;;
    */*)
      cmd="opencode run --model ${model}"
      ;;
    *)
      echo "Error: Unsupported model: ${model}" >&2
      return 1
      ;;
  esac

  echo "$cmd"
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
execute_prompt() {
  local prompt_path="$1"
  local template_path="$2"
  local lang="$3"
  local context="$4"

  local cmd
  cmd=$(get_model_command "${AI_MODEL}") || return 1

  # NOTE: eval is used intentionally; model command is strictly controlled.
  build_ai_input "$prompt_path" "$template_path" "$lang" "$context" | eval "$cmd"
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
    echo "$result" > "$full_path"
    echo "Output written to: $full_path" >&2
  fi
}

# ============================================================================
# Main Execution
# ============================================================================

parse_options "$@"

if [[ -z "$DOC_TYPE" ]]; then
  echo "Error: Document type is required" >&2
  show_usage
  exit 1
fi

validate_doc_type "$DOC_TYPE"

paths=$(resolve_doc_paths "$DOC_TYPE")
PROMPT_PATH=$(echo "$paths" | head -1)
TEMPLATE_PATH=$(echo "$paths" | tail -1)

if [[ -n "$CONTEXT_INPUT" ]]; then
  CONTEXT_INPUT=$(resolve_context "$CONTEXT_INPUT") || exit 1
elif [[ ! -t 0 ]]; then
  CONTEXT_INPUT=$(cat)
fi

# Debug output
echo "DECKRD_BASE: $DECKRD_BASE" >&2
echo "Document type: $DOC_TYPE" >&2
echo "Prompt: $PROMPT_PATH" >&2
echo "Template: $TEMPLATE_PATH" >&2
echo "Language: $LANG_OPT" >&2
echo "Model: $AI_MODEL" >&2
echo "" >&2

result=$(execute_prompt "$PROMPT_PATH" "$TEMPLATE_PATH" "$LANG_OPT" "$CONTEXT_INPUT")

output_result "$result" "$OUTPUT_FILE"
