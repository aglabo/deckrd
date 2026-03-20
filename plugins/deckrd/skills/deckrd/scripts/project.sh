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
# @brief Configure project settings (project name and language)
# @description
#   Creates or updates .local/deckrd/project.json with project settings.
#   This enables deckrd-coder to load language-specific rules.
#
# @example
#   # Configure project with Go language
#   project.sh --project myapp --language go
#
#   # Configure project with TypeScript
#   project.sh --project myapp --language typescript
#
# @exitcode 0 Success
# @exitcode 1 Error during execution
#
# @author atsushifx
# @version 0.1.0
# @license MIT

# don't use -u for checking error by Agent
set -eo pipefail

# ============================================================================
# Script Configuration
# ============================================================================

##
# @description Script directory path
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC2034
readonly SCRIPT_DIR

# Load bootstrap (defines SYMBOL, REPO_ROOT, DECKRD_LIB_DIR, etc.)
# shellcheck disable=SC1091
. "${SCRIPT_DIR}/libs/bootstrap.sh"

# Validate environment (requires jq)
# shellcheck disable=SC1091
. "${DECKRD_LIB_DIR}/validate-env.sh"
_validate_env_errmsg=$(validate_env) || {
  echo "$_validate_env_errmsg" >&2
  exit 1
}
unset _validate_env_errmsg

##
# @description DECKRD local data directory
readonly DECKRD_LOCAL_DATA

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
LANGUAGE="typescript"

##
# @description AI model (default: sonnet)
AI_MODEL="sonnet"

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
  --language <lang>, --lang     Programming language (default: typescript)
                                Supported: ${SUPPORTED_LANGUAGES[*]}
                                Alias: bash → shell
  --ai-model <model>            AI model (default: sonnet)
  -h, --help                    Show this help message

Project file:
  .local/deckrd/project.json

Example:
  project.sh --project myapp --language go
  project.sh --project voift --project-type webapp --language typescript --ai-model sonnet
EOF
}

##
# @description Validate language against supported list
# @arg $1 string Language to validate
# @return 0 if valid, exits on invalid
validate_language() {
  local lang="$1"
  for supported in "${SUPPORTED_LANGUAGES[@]}"; do
    if [[ "$lang" == "$supported" ]]; then
      return 0
    fi
  done
  echo "Error: Unsupported language: ${lang}. Supported: ${SUPPORTED_LANGUAGES[*]}" >&2
  exit 1
}

##
# @description Parse command-line options
parse_options() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
    -h | --help)
      show_usage
      exit 0
      ;;
    --project)
      if [[ -z "${2:-}" ]]; then
        echo "Error: --project requires a value" >&2
        exit 1
      fi
      PROJECT_NAME="$2"
      shift 2
      ;;
    --project=*)
      PROJECT_NAME="${1#*=}"
      shift
      ;;
    --project-type)
      if [[ -z "${2:-}" ]]; then
        echo "Error: --project-type requires a value" >&2
        exit 1
      fi
      PROJECT_TYPE="$2"
      shift 2
      ;;
    --project-type=*)
      PROJECT_TYPE="${1#*=}"
      shift
      ;;
    --language | --lang)
      if [[ -z "${2:-}" ]]; then
        echo "Error: ${1} requires a value" >&2
        exit 1
      fi
      LANGUAGE="$2"
      [[ "$LANGUAGE" == "bash" ]] && LANGUAGE="shell"
      shift 2
      ;;
    --language=* | --lang=*)
      LANGUAGE="${1#*=}"
      [[ "$LANGUAGE" == "bash" ]] && LANGUAGE="shell"
      shift
      ;;
    --ai-model)
      if [[ -z "${2:-}" ]]; then
        echo "Error: --ai-model requires a value" >&2
        exit 1
      fi
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
      exit 1
      ;;
    *)
      echo "Error: Unexpected argument: $1" >&2
      show_usage
      exit 1
      ;;
    esac
  done
}

##
# @description Validate required parameters are set
validate_required_params() {
  if [[ -z "$PROJECT_NAME" ]]; then
    echo "Error: --project is required" >&2
    exit 1
  fi
  if [[ ! "$PROJECT_NAME" =~ ^${SYMBOL}$ ]]; then
    echo "Error: project name '${PROJECT_NAME}' contains invalid characters" >&2
    echo "  Allowed: a-z, hyphen (-), underscore (_)" >&2
    exit 1
  fi
  if [[ -n "$PROJECT_TYPE" && ! "$PROJECT_TYPE" =~ ^${SYMBOL}$ ]]; then
    echo "Error: project type '${PROJECT_TYPE}' contains invalid characters" >&2
    echo "  Allowed: a-z, hyphen (-), underscore (_)" >&2
    exit 1
  fi
}

##
# @description Ensure .deckrd directory exists
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
    created_at=$(jq -r '.created_at // empty' "$PROJECT_FILE" 2>/dev/null || echo "$timestamp")
    existing_type=$(jq -r '.project_type // empty' "$PROJECT_FILE" 2>/dev/null || true)
    existing_model=$(jq -r '.ai_model // empty' "$PROJECT_FILE" 2>/dev/null || true)
    [[ -z "$PROJECT_TYPE" ]] && PROJECT_TYPE="$existing_type"
    [[ "$AI_MODEL" == "sonnet" ]] && [[ -n "$existing_model" ]] && AI_MODEL="$existing_model"
  else
    created_at="$timestamp"
  fi

  jq -n \
    --arg project "$PROJECT_NAME" \
    --arg project_type "$PROJECT_TYPE" \
    --arg language "$LANGUAGE" \
    --arg ai_model "$AI_MODEL" \
    --arg created_at "$created_at" \
    --arg updated_at "$timestamp" \
    '{
      project:      $project,
      project_type: $project_type,
      language:     $language,
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
  echo "  language:     ${LANGUAGE}"
  echo "  ai_model:     ${AI_MODEL}"
  echo "  project:      .local/deckrd/project.json"
}

# ============================================================================
# Main Execution
# ============================================================================

parse_options "$@"
validate_required_params
validate_language "$LANGUAGE"
ensure_deckrd_dir
write_project
display_result
