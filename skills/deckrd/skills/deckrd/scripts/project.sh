#!/usr/bin/env bash
# src: ./skills/deckrd/scripts/project.sh
# @(#) : deckrd プロジェクト設定スクリプト
#
# Copyright (c) 2025 atsushifx <https://github.com/atsushifx>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT
#
# @file project.sh
# @brief Configure project settings (project name and programming language)
# @description
#   Creates or updates .local/deckrd/.project.json with project settings.
#   This enables bdd-coder to load programming-language-specific rules.
#
# @example
#   # Configure project with Go language
#   project.sh --project myapp --prog go
#
#   # Configure project with TypeScript
#   project.sh --project myapp --prog typescript
#
# @exitcode 0 Success
# @exitcode 1 Error during execution
#
# @author atsushifx
# @version 0.1.0
# @license MIT

#shellcheck disable=SC1091

# No -u: an unbound variable would abort with bash's own message
# before the script prints an error the agent can act on
set -eo pipefail

# ============================================================================
# Script Configuration
# ============================================================================

# Load bootstrap (defines SYMBOL, PROJECT_ROOT, DECKRD_LOCAL_DATA, DECKRD_LIB_DIR, etc.)
##
# @description Script directory path
_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
. "${_SCRIPT_DIR}/libs/bootstrap.lib.sh"
unset _SCRIPT_DIR

# validate_env runs in main, not at source time (requires jq or jaq)
# shellcheck disable=SC1091
. "${DECKRD_LIB_DIR}/validate-env.lib.sh"
. "${DECKRD_LIB_DIR}/utils.lib.sh"

##
# @description Project file path
PROJECT_FILE="${DECKRD_LOCAL_DATA}/.project.json"
readonly PROJECT_FILE

##
# @description Supported languages
SUPPORTED_LANGUAGES=(typescript go python rust shell)
readonly SUPPORTED_LANGUAGES

##
# @description Project name
PROJECT_NAME=""

##
# @description Project type
PROJECT_TYPE=""

##
# @description Programming language (default: typescript)
PROG="typescript"

##
# @description AI model (default: sonnet)
AI_MODEL="sonnet"

##
# @description Set to true by parse_options when -h/--help is given
SHOW_HELP=false

# ============================================================================
# Functions
# ============================================================================

##
# @description Show usage information
show_usage() {
  cat <<EOF
Usage: project.sh --project <name> [OPTIONS]

Configure project settings for deckrd.

Options:
  --project <name>              Project name (required)
  --project-type <type>         Project type (e.g. lib, cli, api)
  --prog <lang>, --language     Programming language (default: typescript)
                                Supported: ${SUPPORTED_LANGUAGES[*]}
                                Alias: bash → shell
  --ai-model <model>            AI model (default: sonnet)
  -h, --help                    Show this help message

Project file:
  .local/deckrd/.project.json

Example:
  project.sh --project myapp --prog go
  project.sh --project voift --project-type webapp --prog typescript --ai-model sonnet
EOF
}

##
# @description Validate language against supported list
# @arg $1 string Language to validate
# @return 0 if valid, 1 if unsupported (prints error to stderr)
validate_language() {
  local lang="$1" supported
  for supported in "${SUPPORTED_LANGUAGES[@]}"; do
    if [[ "$lang" == "$supported" ]]; then
      return 0
    fi
  done
  echo "Error: Unsupported language: ${lang}. Supported: ${SUPPORTED_LANGUAGES[*]}" >&2
  return 1
}

##
# @description Normalize language aliases (bash -> shell)
# @arg $1 string Language name
# @stdout Normalized language name
normalize_language() {
  case "$1" in
  bash) echo "shell" ;;
  *) echo "$1" ;;
  esac
}

##
# @description Require a non-empty value for a command-line option
# @arg $1 string Option name (e.g. --project)
# @arg $2 string Option value
# @return 0 if the value is non-empty, 1 if empty (prints error to stderr)
_require_value() {
  if [[ -z "${2:-}" ]]; then
    echo "Error: $1 requires a value" >&2
    return 1
  fi
  return 0
}

##
# @description Parse command-line options
# @arg $@ Command-line arguments
# @set SHOW_HELP true when -h/--help is given
# @return 0 on success (including -h/--help), 1 on invalid arguments (prints error to stderr)
parse_options() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
    -h | --help)
      SHOW_HELP=true
      return 0
      ;;
    --project)
      _require_value "$1" "${2:-}" || return 1
      PROJECT_NAME="$2"
      shift 2
      ;;
    --project=*)
      PROJECT_NAME="${1#*=}"
      shift
      ;;
    --project-type)
      _require_value "$1" "${2:-}" || return 1
      PROJECT_TYPE="$2"
      shift 2
      ;;
    --project-type=*)
      PROJECT_TYPE="${1#*=}"
      shift
      ;;
    --prog | --language)
      _require_value "$1" "${2:-}" || return 1
      PROG="$(normalize_language "$2")"
      shift 2
      ;;
    --prog=* | --language=*)
      PROG="$(normalize_language "${1#*=}")"
      shift
      ;;
    --ai-model)
      _require_value "$1" "${2:-}" || return 1
      AI_MODEL="$2"
      shift 2
      ;;
    --ai-model=*)
      AI_MODEL="${1#*=}"
      shift
      ;;
    -*)
      echo "Error: Unknown option: $1" >&2
      show_usage
      return 1
      ;;
    *)
      echo "Error: Unexpected argument: $1" >&2
      show_usage
      return 1
      ;;
    esac
  done
}

##
# @description Validate required parameters are set
# @return 0 if valid, 1 if missing or invalid (prints error to stderr)
validate_required_params() {
  if [[ -z "$PROJECT_NAME" ]]; then
    echo "Error: --project is required" >&2
    return 1
  fi
  if [[ ! "$PROJECT_NAME" =~ ^${SYMBOL}$ ]]; then
    echo "Error: project name '${PROJECT_NAME}' contains invalid characters" >&2
    echo "  Allowed: a-z, hyphen (-), underscore (_)" >&2
    return 1
  fi
  if [[ -n "$PROJECT_TYPE" && ! "$PROJECT_TYPE" =~ ^${SYMBOL}$ ]]; then
    echo "Error: project type '${PROJECT_TYPE}' contains invalid characters" >&2
    echo "  Allowed: a-z, hyphen (-), underscore (_)" >&2
    return 1
  fi
}

##
# @description Ensure the DECKRD_LOCAL_DATA directory (.local/deckrd) exists
ensure_deckrd_dir() {
  mkdir -p "${DECKRD_LOCAL_DATA}"
}

##
# @description Write project JSON file
write_project() {
  local timestamp
  timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

  local created_at existing_type existing_model
  if [[ -f "$PROJECT_FILE" ]]; then
    # Update: preserve created_at, merge existing fields for omitted options
    created_at=$(jq_read -r '.created_at // empty' "$PROJECT_FILE" 2>/dev/null || echo "$timestamp")
    existing_type=$(jq_read -r '.project_type // empty' "$PROJECT_FILE" 2>/dev/null || true)
    existing_model=$(jq_read -r '.ai_model // empty' "$PROJECT_FILE" 2>/dev/null || true)
    [[ -z "$PROJECT_TYPE" ]] && PROJECT_TYPE="$existing_type"
    [[ "$AI_MODEL" == "sonnet" ]] && [[ -n "$existing_model" ]] && AI_MODEL="$existing_model"
  else
    created_at="$timestamp"
  fi

  # shellcheck disable=SC2016
  jq_read -n \
    --arg project "$PROJECT_NAME" \
    --arg project_type "$PROJECT_TYPE" \
    --arg prog "$PROG" \
    --arg ai_model "$AI_MODEL" \
    --arg created_at "$created_at" \
    --arg updated_at "$timestamp" \
    '{
      project:      $project,
      project_type: $project_type,
      prog:         $prog,
      ai_model:     $ai_model,
      created_at:   $created_at,
      updated_at:   $updated_at
    }' >"${PROJECT_FILE}.tmp" && mv "${PROJECT_FILE}.tmp" "$PROJECT_FILE"
}

##
# @description Display result message
display_result() {
  echo "Deckrd project configured."
  echo ""
  echo "  project:      ${PROJECT_NAME}"
  echo "  project_type: ${PROJECT_TYPE}"
  echo "  prog:         ${PROG}"
  echo "  ai_model:     ${AI_MODEL}"
  echo "  project:      .local/deckrd/.project.json"
}

##
# @description Main entry point: parse options, validate them, and write the project file
# @description Every exit of the script happens here; the other functions only return
# @arg $@ Command-line arguments
# @stdout Usage (on --help or argument errors) and the configured settings
# @stderr Error message on failure
# @exitcode 0 Success, or usage shown by --help
# @exitcode 1 Missing jq/jaq, invalid arguments, or unsupported language
main() {
  validate_env || exit 1
  parse_options "$@" || exit 1
  if [[ "$SHOW_HELP" == true ]]; then
    show_usage
    exit 0
  fi
  validate_required_params || exit 1
  validate_language "$PROG" || exit 1

  # Called without || so that set -e still applies inside these functions
  ensure_deckrd_dir
  write_project
  display_result
}

# ============================================================================
# Main Execution
# ============================================================================

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  main "$@"
fi
