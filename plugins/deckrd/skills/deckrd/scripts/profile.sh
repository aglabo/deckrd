#!/usr/bin/env bash
# src: ./skills/deckrd/scripts/profile.sh
# @(#) : deckrd プロジェクトプロファイル設定スクリプト
#
# Copyright (c) 2025 atsushifx <https://github.com/atsushifx>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT
#
# @file profile.sh
# @brief Configure project profile (project name and language)
# @description
#   Creates or updates .local/deckrd/profile.json with project settings.
#   This enables deckrd-coder to load language-specific rules.
#
# @example
#   # Configure project with Go language
#   profile.sh --project myapp --language go
#
#   # Configure project with TypeScript
#   profile.sh --project myapp --language typescript
#
# @exitcode 0 Success
# @exitcode 1 Error during execution

# don't use -u for checking error by Agent
set -eo pipefail

# ============================================================================
# Script Configuration
# ============================================================================

##
# @description Script directory path
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR

##
# @description Repository root directory
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
readonly REPO_ROOT

##
# @description Deckrd local config directory
DECKRD_DIR="${REPO_ROOT}/.local/deckrd"
readonly DECKRD_DIR

##
# @description Profile file path
PROFILE_FILE="${DECKRD_DIR}/profile.json"
readonly PROFILE_FILE

##
# @description Supported languages
SUPPORTED_LANGUAGES=(go typescript python rust)
readonly SUPPORTED_LANGUAGES

##
# @description Project name
PROJECT_NAME=""

##
# @description Development language (default: typescript)
LANGUAGE="typescript"

# ============================================================================
# Functions
# ============================================================================

##
# @description Show usage information
show_usage() {
  cat <<EOF
Usage: profile.sh --project <name> --language <lang>

Configure project profile for deckrd.

Options:
  --project <name>              Project name (required)
  --language <lang>, --lang     Development language (default: typescript)
                                Supported: go, typescript, python, rust
  -h, --help          Show this help message

Profile file:
  .local/deckrd/profile.json

Example:
  profile.sh --project myapp --language go
  profile.sh --project voift --language typescript
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
      -h|--help)
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
      --language|--lang)
        if [[ -z "${2:-}" ]]; then
          echo "Error: ${1} requires a value" >&2
          exit 1
        fi
        LANGUAGE="$2"
        shift 2
        ;;
      --language=*|--lang=*)
        LANGUAGE="${1#*=}"
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
}

##
# @description Ensure .deckrd directory exists
ensure_deckrd_dir() {
  mkdir -p "${DECKRD_DIR}"
}

##
# @description Write profile JSON file
write_profile() {
  local timestamp
  timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

  if [[ -f "$PROFILE_FILE" ]] && command -v jq >/dev/null 2>&1; then
    # Update: preserve created_at
    local created_at
    created_at=$(jq -r '.created_at // empty' "$PROFILE_FILE" 2>/dev/null || echo "$timestamp")
    jq -n \
      --arg project "$PROJECT_NAME" \
      --arg language "$LANGUAGE" \
      --arg created_at "$created_at" \
      --arg updated_at "$timestamp" \
      '{project: $project, language: $language, created_at: $created_at, updated_at: $updated_at}' \
      > "${PROFILE_FILE}.tmp" && mv "${PROFILE_FILE}.tmp" "$PROFILE_FILE"
  else
    # New file (also works without jq)
    cat > "$PROFILE_FILE" <<EOF
{
  "project": "${PROJECT_NAME}",
  "language": "${LANGUAGE}",
  "created_at": "${timestamp}",
  "updated_at": "${timestamp}"
}
EOF
  fi
}

##
# @description Display result message
display_result() {
  echo "Deckrd profile configured."
  echo ""
  echo "Project : ${PROJECT_NAME}"
  echo "Language: ${LANGUAGE}"
  echo "Profile : .local/deckrd/profile.json"
}

# ============================================================================
# Main Execution
# ============================================================================

parse_options "$@"
validate_required_params
validate_language "$LANGUAGE"
ensure_deckrd_dir
write_profile
display_result
