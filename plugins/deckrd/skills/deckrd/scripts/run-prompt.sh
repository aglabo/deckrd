#!/usr/bin/env bash
# src: ./skills/deckrd/scripts/run-prompt.sh
# @(#) : deckrd script for executing AI prompts with configurable models
#
# Copyright (c) 2025 atsushifx <https://github.com/atsushifx>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

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
#   run-prompt.sh requirements "user input" --lang ja
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

# don't use  -u for checking error by Agent
set -eo pipefail

# ============================================================================
# deckrd Path Initialization
# ============================================================================

##
# @description Session file path
SESSION_FILE="docs/.deckrd/.session.json"

##
# @description deckrd base path - DECKRD_BASE may point to module root when session is active
DECKRD_BASE=""

##
# @description Session AI model (set from session)
SESSION_AI_MODEL=""

##
# @description Session language (set from session)
SESSION_LANG=""


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
# @description Document type mapping (short form -> normalized form)
# Maps short aliases to their normalized file-matching form
declare -A SHORT_TO_LONG=(
  [req]="requirements"
  [spec]="specifications"
  [impl]="implementation"
  [task]="tasks"
  [review]="review"
)

##
# @description Review phase (explore, harden, fix) - only for review command
REVIEW_PHASE=""

##
# @description Primary document types for display (derived from SHORT_TO_LONG values)
# Populated after SHORT_TO_LONG declaration to get unique long form values
PRIMARY_TYPES=($(printf '%s\n' "${SHORT_TO_LONG[@]}" | sort -u))

##
# @description Document type (requirements, spec, impl, tasks)
DOC_TYPE=""

##
# @description Context input (from stdin or argument)
CONTEXT_INPUT=""

##
# @description Output file path (empty = stdout)
OUTPUT_FILE=""

##
# @description AI command array (populated by get_model_command)
declare -a AI_COMMAND

# ============================================================================
# Functions
# ============================================================================

# @description Extract JSON value using grep/sed fallback
# @arg $1 string JSON file path
# @arg $2 string JSON key name
# @stdout Extracted value (empty if not found)
extract_json_value_fallback() {
  local file="$1"
  local key="$2"

  # Match: "key": "value" or "key":"value"
  # Handles whitespace variations and returns empty if not found
  grep -o "\"${key}\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" "$file" 2>/dev/null | \
    sed -E 's/[^:]*:[[:space:]]*"([^"]*)".*/\1/' || echo ""
}

##
# @description Load configuration from session.json
# Reads "active", "ai_model", and "lang" fields from session
load_session_config() {
  if [[ ! -f "$SESSION_FILE" ]]; then
    return 0
  fi

  local active=""
  local ai_model=""
  local lang=""

  if [[ CAN_USE_JQ -eq 1 ]]; then
    # Preferred: use jq
    active=$(jq -r '.active // empty' "$SESSION_FILE" 2>/dev/null || true)
    ai_model=$(jq -r '.ai_model // empty' "$SESSION_FILE" 2>/dev/null || true)
    lang=$(jq -r '.lang // empty' "$SESSION_FILE" 2>/dev/null || true)
  else
    # Fallback: use grep/sed
    echo "Warning: session.json loaded via fallback; values may be incomplete" >&2

    active=$(extract_json_value_fallback "$SESSION_FILE" "active")
    ai_model=$(extract_json_value_fallback "$SESSION_FILE" "ai_model")
    lang=$(extract_json_value_fallback "$SESSION_FILE" "lang")
  fi

  if [[ -n "$active" ]]; then
    DECKRD_BASE="docs/.deckrd/${active}"
    export DECKRD_BASE
  fi

  if [[ -n "$ai_model" ]]; then
    SESSION_AI_MODEL="$ai_model"
    export SESSION_AI_MODEL
  fi

  if [[ -n "$lang" ]]; then
    SESSION_LANG="$lang"
    export SESSION_LANG
  fi
}

##
# @description Validate AI model name format
# @arg $1 string AI model name
# @return 0 if valid, exits on invalid format
validate_ai_model() {
  local model="$1"

  # Allow simple model name: letters, numbers, hyphens, underscores, dots
  if [[ "$model" =~ ^[A-Za-z0-9_.-]+$ ]]; then
    return 0
  fi

  # Allow org/model format
  if [[ "$model" =~ ^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$ ]]; then
    return 0
  fi

  echo "Error: AI model must contain only letters, numbers, hyphens, underscores, and dots" >&2
  echo "  Allowed formats: 'model-name' or 'org/model-name'" >&2
  echo "  Invalid model: ${model}" >&2
  exit 1
}

##
# @description Show usage information
show_usage() {
  cat <<EOF
Usage: run-prompt.sh <type> [context] [OPTIONS]

Execute AI prompt with auto-loaded prompt and template files.

Arguments:
  <type>            Document type (required): ${PRIMARY_TYPES[*]}
  [context]         Context/input text or @filepath for file content
                    If starts with @, reads content from the specified file

Document Types:
  requirements    Generate requirements document
  spec            Generate specification document
  tasks           Generate task breakdown
  impl            Generate implementation guide
  review          Review existing document (requires --phase)

Options:
  --ai-model <model>  AI model name (default: loaded from session, or gpt-5.2)
                      Supported: gpt-*, o1-*, claude-*, haiku, sonnet, opus
                      Formats: 'model-name' or 'org/model-name'
  --lang <lang>       Document language (default: loaded from session, or system)
                      Values: system, en, ja, or any language name
  --output <file>     Output file path relative to DECKRD_BASE (default: stdout)
                      Example: --output requirements/requirements.md
                      → writes to \${DECKRD_BASE}/requirements/requirements.md
  --phase <phase>     Review phase (only for review command)
                      Values: explore, harden, fix (default: explore)
  -h, --help          Show this help message

Session Configuration:
  Default values for --ai-model and --lang are loaded from:
    docs/.deckrd/.session.json

File Resolution:
  requirements  →  prompts/requirements.prompt.md
                   templates/requirements.template.md

Execution Flow:
  cat <prompt.md> <template.md> | prepend LANG: <lang> | append <context> | <ai>

Examples:
  # Generate requirements in Japanese
  run-prompt.sh requirements "user input" --lang ja

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
      --ai-model)
        if [[ -z "${2:-}" ]]; then
          echo "Error: --ai-model requires a model name" >&2
          exit 1
        fi
        validate_ai_model "$2"
        AI_MODEL="$2"
        shift 2
        ;;
      --ai-model=*)
        AI_MODEL="${1#*=}"
        validate_ai_model "$AI_MODEL"
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
      --phase)
        if [[ -z "${2:-}" ]]; then
          echo "Error: --phase requires a value (explore|harden|fix)" >&2
          exit 1
        fi
        if [[ ! "$2" =~ ^(explore|harden|fix)$ ]]; then
          echo "Error: Invalid review phase: $2" >&2
          echo "  Valid phases: explore, harden, fix" >&2
          exit 1
        fi
        REVIEW_PHASE="$2"
        shift 2
        ;;
      --phase=*)
        REVIEW_PHASE="${1#*=}"
        if [[ ! "$REVIEW_PHASE" =~ ^(explore|harden|fix)$ ]]; then
          echo "Error: Invalid review phase: $REVIEW_PHASE" >&2
          echo "  Valid phases: explore, harden, fix" >&2
          exit 1
        fi
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
# @description Validate and normalize document type
# @arg $1 string Document type (short or long form)
# @stdout Normalized long form document type
validate_doc_type() {
  local input="$1"

  # Check if input is a short form
  if [[ -v SHORT_TO_LONG[$input] ]]; then
    echo "${SHORT_TO_LONG[$input]}"
    return 0
  fi

  # Check if input is already a normalized long form
  for long_form in "${PRIMARY_TYPES[@]}"; do
    if [[ "$input" == "$long_form" ]]; then
      echo "$input"
      return 0
    fi
  done

  echo "Error: Unknown document type: $input" >&2
  echo "Supported types: ${PRIMARY_TYPES[*]} (or short forms: req, spec, impl, task)" >&2
  exit 1
}

##
# @description Resolve prompt and template paths for document type
# @arg $1 string Document type (normalized form from validate_doc_type)
# @stdout Two lines: prompt path, template path
resolve_doc_paths() {
  local doc_type="$1"

  local prompt_path="${ASSETS_DIR}/prompts/${doc_type}.prompt.md"

  # review タイプの場合はフェーズ別テンプレートを選択
  local template_path
  if [[ "$doc_type" == "review" && -n "$REVIEW_PHASE" ]]; then
    template_path="${ASSETS_DIR}/templates/${doc_type}-${REVIEW_PHASE}.template.md"
  else
    template_path="${ASSETS_DIR}/templates/${doc_type}.template.md"
  fi

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
# @description Set AI command array for specified AI model
# @arg $1 string AI model name
# @return 0 on success, 1 on unsupported model
# @global AI_COMMAND array populated with command and arguments
get_model_command() {
  local model="${1:-sonnet}"

  case "$model" in
    gpt-* | o1-*)
      AI_COMMAND=("codex" "exec" "--model" "$model")
      ;;
    claude-* | haiku | sonnet | opus)
      AI_COMMAND=("claude" "-p" "--model" "$model")
      ;;
    */*)
      AI_COMMAND=("opencode" "run" "--model" "$model")
      ;;
    *)
      echo "Error: Unsupported model: ${model}" >&2
      return 1
      ;;
  esac

  return 0
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
  if [[ -n "$REVIEW_PHASE" ]]; then
    echo "PHASE: ${REVIEW_PHASE}"
  fi
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

  get_model_command "${AI_MODEL}" || return 1

  # Execute AI command using array (no eval needed)
  build_ai_input "$prompt_path" "$template_path" "$lang" "$context" | "${AI_COMMAND[@]}"
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

# check if jq is installed for session.json parsing
command -v jq >/dev/null 2>&1 && CAN_USE_JQ=1 || CAN_USE_JQ=0

## Initialize deckrd base and session config

# Initialize configuration from session
load_session_config

# Set default if not loaded
if [[ -z "${DECKRD_BASE}" ]]; then
  DECKRD_BASE="docs/.deckrd"
  export DECKRD_BASE
fi


## Initialize command-line options

# @description AI model (loaded from session or default)
# Can be overridden with --model option
AI_MODEL="${SESSION_AI_MODEL:-sonnet}"

##
# @description Document language (loaded from session or default)
# Can be overridden with --lang option
LANG_OPT="${SESSION_LANG:-system}"

# Parse command-line options
parse_options "$@"

if [[ -z "$DOC_TYPE" ]]; then
  echo "Error: Document type is required" >&2
  show_usage
  exit 1
fi

DOC_TYPE=$(validate_doc_type "$DOC_TYPE")

# Set default review phase for review command
if [[ "$DOC_TYPE" == "review" && -z "$REVIEW_PHASE" ]]; then
  REVIEW_PHASE="explore"
fi

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
if [[ -n "$REVIEW_PHASE" ]]; then
  echo "Review Phase: $REVIEW_PHASE" >&2
fi
echo "" >&2

result=$(execute_prompt "$PROMPT_PATH" "$TEMPLATE_PATH" "$LANG_OPT" "$CONTEXT_INPUT")

output_result "$result" "$OUTPUT_FILE"
