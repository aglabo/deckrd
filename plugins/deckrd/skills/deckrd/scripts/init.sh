#!/usr/bin/env bash
# src: ./skills/deckrd/scripts/init-dirs.sh
# @(#) : deckrd プロジェクト初期化スクリプト
#
# Copyright (c) 2025 atsushifx <https://github.com/atsushifx>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT
#
# @file init-dirs.sh
# @brief Bootstrap and initialize DECKRD project structure
# @description
#   1. Bootstrap: copy deckrd-rules to .claude/rules/ and docs templates
#      to docs/.deckrd/ (no overwrite)
#   2. Create docs/.deckrd/ base directory structure
#   3. Write .local/deckrd/.project.json with project settings
#   4. Initialize .local/deckrd/session.json
#
# @usage
#   init-dirs.sh <project> <project-type> [OPTIONS]
#
# @example
#   init-dirs.sh myapp webapp
#   init-dirs.sh myapp webapp --language go
#   init-dirs.sh myapp lib --language typescript --ai-model claude-sonnet-4-5
#
# @exitcode 0 Success
# @exitcode 1 Error during execution
#
# @stdout Machine-readable output only (currently empty)
# @stderr User-visible logs, progress messages, usage, and error messages
#
# @author atsushifx
# @version 3.0.0
# @license MIT

# shellcheck disable=SC1091

# don't use -u for checking error by Agent
set -o pipefail

# Load bootstrap (defines SYMBOL, PROJECT_ROOT, DECKRD_LOCAL_DATA, DECKRD_LIB_DIR, etc.)
_INIT_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "${_INIT_SCRIPT_DIR}/libs/bootstrap.sh"
unset _INIT_SCRIPT_DIR

. "${DECKRD_LIB_DIR}/validate-env.sh"
_validate_env_errmsg=$(validate_env) || {
  echo "$_validate_env_errmsg" >&2
  exit 1
}
unset _validate_env_errmsg

. "${DECKRD_LIB_DIR}/ai-runner.sh"

# ============================================================================
# Functions
# ============================================================================

##
# @description Initialize script configuration variables
# @description All variables use ${VAR:-default} to allow external override (mock)
init_vars() {
  SCRIPT_DIR="${SCRIPT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"
  INITS_DIR="${INITS_DIR:-${SCRIPT_DIR}/../assets/inits}"
  RULES_SRC_DIR="${RULES_SRC_DIR:-${INITS_DIR}/deckrd-rules}"
  DOCS_SRC_DIR="${DOCS_SRC_DIR:-${INITS_DIR}/docs}"
  LOCAL_SRC_DIR="${LOCAL_SRC_DIR:-${INITS_DIR}/local-deckrd}"
  CLAUDE_RULES_DIR="${CLAUDE_RULES_DIR:-${PROJECT_ROOT}/.claude/rules}"
  DECKRD_DOCS="${DECKRD_DOCS:-${PROJECT_ROOT}/docs/.deckrd}"
  PROJECT_FILE="${PROJECT_FILE:-${DECKRD_LOCAL_DATA}/.project.json}"
  SESSION_FILE="${SESSION_FILE:-${DECKRD_LOCAL_DATA}/session.json}"
  BASE_SUBDIRS=("notes" "temp")
  SUPPORTED_LANGUAGES=(typescript go python rust)
  PROJECT_NAME="${PROJECT_NAME:-}"
  PROJECT_TYPE="${PROJECT_TYPE:-}"
  LANGUAGE="${LANGUAGE:-typescript}"
  AI_MODEL="${AI_MODEL:-sonnet}"
}

##
# @description Show usage information
# @stderr Usage text
show_usage() {
  cat >&2 <<EOF
Usage: init-dirs.sh <project> <project-type> [OPTIONS]

Bootstrap and initialize a DECKRD project.

Arguments:
  <project>       Project name (e.g. myapp)
  <project-type>  Project type (e.g. webapp, lib, cli, api)

Options:
  --language <lang>, --lang   Programming language (default: typescript)
                              Supported: ${SUPPORTED_LANGUAGES[*]}
  --ai-model <model>          AI model (default: sonnet)
                              Supported: gpt-*, o1-*, claude-*, haiku, sonnet, opus
  -h, --help                  Show this help message

Project file:
  .local/deckrd/project.json

Example:
  init-dirs.sh myapp webapp
  init-dirs.sh myapp lib --language go
  init-dirs.sh voift webapp --language typescript --ai-model claude-sonnet-4-5
EOF
}

##
# @description Validate programming language against supported list
# @arg $1 string Language to validate
# @return 0 if valid, 1 if invalid (no output; caller handles error message)
validate_language() {
  local lang="$1"
  for supported in "${SUPPORTED_LANGUAGES[@]}"; do
    if [[ "$lang" == "$supported" ]]; then
      return 0
    fi
  done
  return 1
}

##
# @description Parse command-line arguments and options
# @return 0 on success, 1 on error (no output; caller handles error message)
# @var PARSE_ARGS_ERROR set to error description on failure
parse_args() {
  local positional=()
  PARSE_ARGS_ERROR=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
    -h | --help)
      show_usage
      exit 0
      ;;
    --language | --lang)
      if [[ -z "${2:-}" ]]; then
        PARSE_ARGS_ERROR="${1} requires a value"
        return 1
      fi
      LANGUAGE="$2"
      shift 2
      ;;
    --language=* | --lang=*)
      LANGUAGE="${1#*=}"
      shift
      ;;
    --ai-model)
      if [[ -z "${2:-}" ]]; then
        PARSE_ARGS_ERROR="--ai-model requires a value"
        return 1
      fi
      AI_MODEL="$2"
      shift 2
      ;;
    --ai-model=*)
      AI_MODEL="${1#*=}"
      shift
      ;;
    -*)
      PARSE_ARGS_ERROR="Unknown option: $1"
      return 1
      ;;
    *)
      positional+=("$1")
      shift
      ;;
    esac
  done

  PROJECT_NAME="${positional[0]:-}"
  PROJECT_TYPE="${positional[1]:-}"
}

##
# @description Validate required positional arguments
# @return 0 on success, 1 on error (no output; caller handles error message)
# @var VALIDATE_ARGS_ERROR set to error description on failure
validate_args() {
  VALIDATE_ARGS_ERROR=""

  if [[ -z "$PROJECT_NAME" ]]; then
    VALIDATE_ARGS_ERROR="<project> is required"
    return 1
  fi
  if [[ -z "$PROJECT_TYPE" ]]; then
    VALIDATE_ARGS_ERROR="<project-type> is required"
    return 1
  fi
  if [[ ! "$PROJECT_NAME" =~ ^${SYMBOL}$ ]]; then
    VALIDATE_ARGS_ERROR="project name '${PROJECT_NAME}' contains invalid characters. Allowed: a-z, hyphen (-), underscore (_)"
    return 1
  fi
  if [[ ! "$PROJECT_TYPE" =~ ^${SYMBOL}$ ]]; then
    VALIDATE_ARGS_ERROR="project type '${PROJECT_TYPE}' contains invalid characters. Allowed: a-z, hyphen (-), underscore (_)"
    return 1
  fi
}

##
# @description Create directory and optionally copy assets without overwriting
# @arg $1 string Destination directory
# @arg $2 string Source directory (optional; if omitted, only creates dest dir)
# @arg $3 string Label for display (optional; defaults to basename of dest dir)
# @stderr Progress messages
init_directory() {
  local dest_dir="$1"
  local src_dir="${2:-}"
  local label="${3:-$(basename "$dest_dir")}"

  mkdir -p "$dest_dir"

  if [[ -z "$src_dir" ]]; then
    return 0
  fi

  if [[ ! -d "$src_dir" ]]; then
    echo "  [init/${label}] source not found, skipping: ${src_dir}" >&2
    return 0
  fi

  local copied=0 skipped=0
  for src_file in "$src_dir"/* "$src_dir"/.*; do
    [[ -e "$src_file" ]] || continue
    [[ "$(basename "$src_file")" == "." || "$(basename "$src_file")" == ".." ]] && continue
    local filename dest_file
    filename="$(basename "$src_file")"
    dest_file="${dest_dir}/${filename}"
    if [[ -e "$dest_file" ]]; then
      echo "  [init/${label}] skip (exists): ${filename}" >&2
      skipped=$((skipped + 1))
    else
      cp "$src_file" "$dest_file"
      echo "  [init/${label}] copied: ${filename}" >&2
      copied=$((copied + 1))
    fi
  done

  echo "  [init/${label}] done: ${copied} copied, ${skipped} skipped" >&2
}

##
# @description Initialize all project directories and install assets
# @stderr Progress messages
init_directories() {
  echo "Init: creating directories and installing assets..." >&2
  init_directory "$CLAUDE_RULES_DIR" "$RULES_SRC_DIR" "deckrd-rules"
  init_directory "$DECKRD_DOCS" "$DOCS_SRC_DIR" "docs"
  init_directory "$DECKRD_LOCAL_DATA" "$LOCAL_SRC_DIR" "local-deckrd"
  for subdir in "${BASE_SUBDIRS[@]}"; do
    init_directory "${DECKRD_DOCS}/${subdir}"
  done
  echo "Init complete." >&2
  echo "" >&2
}

##
# @description Write project.json with project settings
# @stderr Progress messages
write_project() {
  local timestamp
  timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

  local created_at
  if [[ -f "$PROJECT_FILE" ]]; then
    created_at=$(jq -r '.created_at // empty' "$PROJECT_FILE" 2>/dev/null || echo "$timestamp")
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

  echo "" >&2
  echo "Project written: ${PROJECT_FILE}" >&2
  echo "  project:      ${PROJECT_NAME}" >&2
  echo "  project_type: ${PROJECT_TYPE}" >&2
  echo "  language:     ${LANGUAGE}" >&2
  echo "  ai_model:     ${AI_MODEL}" >&2
}

##
# @description Initialize session.json
# @stderr Progress messages
init_session() {
  local timestamp
  timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

  if [[ -f "$SESSION_FILE" ]]; then
    # Already exists: preserve as-is, just reset current_step
    echo "" >&2
    echo "Session preserved: ${SESSION_FILE}" >&2
    return 0
  fi

  cat >"$SESSION_FILE" <<EOF
{
  "current_step": "init",
  "completed": ["init"],
  "documents": {},
  "created_at": "${timestamp}",
  "updated_at": "${timestamp}"
}
EOF

  echo "" >&2
  echo "Session created: ${SESSION_FILE}" >&2
}

# ============================================================================
# Main Execution
# ============================================================================

main() {
  init_vars

  parse_args "$@" || {
    echo "Error: ${PARSE_ARGS_ERROR}" >&2
    if [[ "$PARSE_ARGS_ERROR" == "Unknown option:"* ]]; then
      show_usage
    fi
    exit 1
  }

  validate_args || {
    echo "Error: ${VALIDATE_ARGS_ERROR}" >&2
    if [[ "$VALIDATE_ARGS_ERROR" == *"is required" ]]; then
      show_usage
    fi
    exit 1
  }

  validate_language "$LANGUAGE" || {
    echo "Error: Unsupported language: ${LANGUAGE}. Supported: ${SUPPORTED_LANGUAGES[*]}" >&2
    exit 1
  }

  _ai_model_errmsg=$(validate_ai_model "$AI_MODEL") || {
    echo "$_ai_model_errmsg" >&2
    exit 1
  }
  unset _ai_model_errmsg

  init_directories
  write_project
  init_session
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  main "$@"
fi
