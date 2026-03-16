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
# @author atsushifx
# @version 3.0.0
# @license MIT

# don't use -u for checking error by Agent
set -eo pipefail

DECKRD_LIB_DIR="$(dirname "${BASH_SOURCE[0]}")/libs"
# shellcheck disable=SC1091
. "${DECKRD_LIB_DIR}/validate-env.sh"
_validate_env_errmsg=$(validate_env) || {
  echo "$_validate_env_errmsg" >&2
  exit 1
}
unset _validate_env_errmsg

# ============================================================================
# Script Configuration
# ============================================================================

##
# @description Script directory path
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR

##
# @description Assets inits directory
INITS_DIR="${SCRIPT_DIR}/../assets/inits"
readonly INITS_DIR

##
# @description Bootstrap source: deckrd-rules
RULES_SRC_DIR="${INITS_DIR}/deckrd-rules"
readonly RULES_SRC_DIR

##
# @description Bootstrap source: docs templates
DOCS_SRC_DIR="${INITS_DIR}/docs"
readonly DOCS_SRC_DIR

##
# @description Repository root directory
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
readonly REPO_ROOT

##
# @description Bootstrap destination: .claude/rules/
CLAUDE_RULES_DIR="${REPO_ROOT}/.claude/rules"
readonly CLAUDE_RULES_DIR

##
# @description DECKRD docs directory
DECKRD_DOCS="${DECKRD_DOCS:-${REPO_ROOT}/docs/.deckrd}"
readonly DECKRD_DOCS

##
# @description DECKRD local config directory
DECKRD_LOCAL="${REPO_ROOT}/.local/deckrd"
readonly DECKRD_LOCAL

##
# @description Project file path
PROJECT_FILE="${DECKRD_LOCAL}/.project.json"
readonly PROJECT_FILE

##
# @description Session file path
SESSION_FILE="${DECKRD_LOCAL}/session.json"
readonly SESSION_FILE

##
# @description Base subdirectories to create under DECKRD_DOCS
BASE_SUBDIRS=("notes" "temp")

##
# @description Supported programming languages
SUPPORTED_LANGUAGES=(typescript go python rust)
readonly SUPPORTED_LANGUAGES

##
# @description Project name (positional arg 1)
PROJECT_NAME=""

##
# @description Project type (positional arg 2)
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
# @description Validate AI model name format
# @arg $1 string AI model name
# @return 0 if valid, exits on invalid
validate_ai_model() {
  local model="$1"
  if [[ "$model" =~ ^[A-Za-z0-9_.-]+(/[A-Za-z0-9_.-]+)?$ ]]; then
    return 0
  fi
  echo "Error: AI model must contain only letters, numbers, hyphens, underscores, and dots" >&2
  echo "  Allowed formats: 'model-name' or 'org/model-name'" >&2
  echo "  Invalid model: ${model}" >&2
  exit 1
}

##
# @description Parse command-line arguments and options
parse_args() {
  local positional=()

  while [[ $# -gt 0 ]]; do
    case "$1" in
    -h | --help)
      show_usage
      exit 0
      ;;
    --language | --lang)
      if [[ -z "${2:-}" ]]; then
        echo "Error: ${1} requires a value" >&2
        exit 1
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
validate_args() {
  if [[ -z "$PROJECT_NAME" ]]; then
    echo "Error: <project> is required" >&2
    show_usage
    exit 1
  fi
  if [[ -z "$PROJECT_TYPE" ]]; then
    echo "Error: <project-type> is required" >&2
    show_usage
    exit 1
  fi
  if [[ ! "$PROJECT_NAME" =~ ^${SYMBOL}$ ]]; then
    echo "Error: project name '${PROJECT_NAME}' contains invalid characters" >&2
    echo "  Allowed: a-z, hyphen (-), underscore (_)" >&2
    exit 1
  fi
  if [[ ! "$PROJECT_TYPE" =~ ^${SYMBOL}$ ]]; then
    echo "Error: project type '${PROJECT_TYPE}' contains invalid characters" >&2
    echo "  Allowed: a-z, hyphen (-), underscore (_)" >&2
    exit 1
  fi
}

##
# @description Bootstrap: copy files without overwriting existing ones
# @arg $1 string Source directory
# @arg $2 string Destination directory
# @arg $3 string Label for display
bootstrap_copy() {
  local src_dir="$1"
  local dest_dir="$2"
  local label="$3"

  if [[ ! -d "$src_dir" ]]; then
    echo "  [bootstrap/${label}] source not found, skipping: ${src_dir}"
    return 0
  fi

  mkdir -p "$dest_dir"

  local copied=0 skipped=0
  for src_file in "$src_dir"/*; do
    [[ -e "$src_file" ]] || continue
    local filename dest_file
    filename="$(basename "$src_file")"
    dest_file="${dest_dir}/${filename}"
    if [[ -e "$dest_file" ]]; then
      echo "  [bootstrap/${label}] skip (exists): ${filename}"
      skipped=$((skipped + 1))
    else
      cp "$src_file" "$dest_file"
      echo "  [bootstrap/${label}] copied: ${filename}"
      copied=$((copied + 1))
    fi
  done

  echo "  [bootstrap/${label}] done: ${copied} copied, ${skipped} skipped"
}

##
# @description Bootstrap: install deckrd-rules and docs templates (no overwrite)
bootstrap_project() {
  echo "Bootstrap: installing deckrd assets..."
  bootstrap_copy "$RULES_SRC_DIR" "$CLAUDE_RULES_DIR" "deckrd-rules"
  bootstrap_copy "$DOCS_SRC_DIR" "$DECKRD_DOCS" "docs"
  echo "Bootstrap complete."
  echo ""
}

##
# @description Create base directory structure under docs/.deckrd/
init_base_directory() {
  mkdir -p "$DECKRD_LOCAL"
  mkdir -p "$DECKRD_DOCS"
  for subdir in "${BASE_SUBDIRS[@]}"; do
    mkdir -p "${DECKRD_DOCS}/${subdir}"
  done
  echo "Base directory: ${DECKRD_DOCS}"
}

##
# @description Write project.json with project settings
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

  echo ""
  echo "Project written: ${PROJECT_FILE}"
  echo "  project:      ${PROJECT_NAME}"
  echo "  project_type: ${PROJECT_TYPE}"
  echo "  language:     ${LANGUAGE}"
  echo "  ai_model:     ${AI_MODEL}"
}

##
# @description Initialize session.json
init_session() {
  local timestamp
  timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

  if [[ -f "$SESSION_FILE" ]]; then
    # Already exists: preserve as-is, just reset current_step
    echo ""
    echo "Session preserved: ${SESSION_FILE}"
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

  echo ""
  echo "Session created: ${SESSION_FILE}"
}

# ============================================================================
# Main Execution
# ============================================================================

parse_args "$@"
validate_args
validate_language "$LANGUAGE"
validate_ai_model "$AI_MODEL"

bootstrap_project
init_base_directory
write_project
init_session
