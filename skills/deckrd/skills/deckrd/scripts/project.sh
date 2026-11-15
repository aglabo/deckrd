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
. "${DECKRD_LIB_DIR}/args.lib.sh"

##
# @description Project file path
PROJECT_FILE="${DECKRD_LOCAL_DATA}/.project.json"
readonly PROJECT_FILE

##
# @description Supported languages
SUPPORTED_LANGUAGES=(typescript go python rust shell)
readonly SUPPORTED_LANGUAGES

# OPTIONS / OPTIONS_SET are not declared here: args_init (libs/args.lib.sh) owns them

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
# @description Validate required parameters are set
# @var OPTIONS project, project_type
# @return 0 if valid, 1 if missing or invalid (prints error to stderr)
validate_required_params() {
  local project="${OPTIONS[project]}" project_type="${OPTIONS[project_type]}"
  if [[ -z "$project" ]]; then
    echo "Error: --project is required" >&2
    return 1
  fi
  if [[ ! "$project" =~ ^${SYMBOL}$ ]]; then
    echo "Error: project name '${project}' contains invalid characters" >&2
    echo "  Allowed: a-z, hyphen (-), underscore (_)" >&2
    return 1
  fi
  if [[ -n "$project_type" && ! "$project_type" =~ ^${SYMBOL}$ ]]; then
    echo "Error: project type '${project_type}' contains invalid characters" >&2
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
# @description On update, created_at is preserved, and project_type / ai_model are taken
#   from the existing file when they were not given on the command line
# @var OPTIONS     project, project_type, prog, ai_model (project_type / ai_model may be updated)
# @var OPTIONS_SET ai_model is `true` when --ai-model was given
write_project() {
  local timestamp
  timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

  local created_at existing_type existing_model
  if [[ -f "$PROJECT_FILE" ]]; then
    # Update: preserve created_at, merge existing fields for omitted options
    created_at=$(jq_read -r '.created_at // empty' "$PROJECT_FILE" 2>/dev/null || echo "$timestamp")
    existing_type=$(jq_read -r '.project_type // empty' "$PROJECT_FILE" 2>/dev/null || true)
    existing_model=$(jq_read -r '.ai_model // empty' "$PROJECT_FILE" 2>/dev/null || true)
    [[ -z "${OPTIONS[project_type]}" ]] && OPTIONS[project_type]="$existing_type"
    [[ "${OPTIONS_SET[ai_model]:-false}" != true ]] && [[ -n "$existing_model" ]] && OPTIONS[ai_model]="$existing_model"
  else
    created_at="$timestamp"
  fi

  # shellcheck disable=SC2016
  jq_read -n \
    --arg project "${OPTIONS[project]}" \
    --arg project_type "${OPTIONS[project_type]}" \
    --arg prog "${OPTIONS[prog]}" \
    --arg ai_model "${OPTIONS[ai_model]}" \
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
# @var OPTIONS project, project_type, prog, ai_model
display_result() {
  echo "Deckrd project configured."
  echo ""
  echo "  project:      ${OPTIONS[project]}"
  echo "  project_type: ${OPTIONS[project_type]}"
  echo "  prog:         ${OPTIONS[prog]}"
  echo "  ai_model:     ${OPTIONS[ai_model]}"
  echo "  project:      .local/deckrd/.project.json"
}

##
# @description Entry point: validate_env -> option declarations (args_init, args_value) -> parse_args
#   -> help -> normalize (`--prog bash` becomes `shell`) -> validate -> write the project file
# @description Every exit of the script happens here; the other functions only return
# @arg $@ string Command-line arguments (see show_usage)
# @var OPTIONS     Parse result (libs/args.lib.sh): project, project_type, prog, ai_model, SHOW_HELP
# @var OPTIONS_SET `true` for each option given on the command line (ai_model is used by write_project)
# @stdout Usage (on --help or argument errors) and the configured settings
# @stderr `Error:` lines on failure
# @exitcode 0 Success, or usage shown by --help
# @exitcode 1 Missing jq/jaq, parse error, invalid arguments, or unsupported language
main() {
  validate_env || exit 1

  args_init
  args_value project "" --project
  args_value project_type "" --project-type
  args_value prog typescript --prog --language
  args_value ai_model sonnet --ai-model

  parse_args "$@" || {
    echo "Error: ${ARGS_ERROR}" >&2
    show_usage
    exit 1
  }

  if [[ "${OPTIONS[SHOW_HELP]}" == true ]]; then
    show_usage
    exit 0
  fi

  OPTIONS[prog]="$(normalize_language "${OPTIONS[prog]}")"

  validate_required_params || exit 1
  validate_language "${OPTIONS[prog]}" || exit 1

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
