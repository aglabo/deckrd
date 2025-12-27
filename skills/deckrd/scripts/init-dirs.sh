#!/usr/bin/env bash
# deckrd init_dirs.sh - Initialize documentation directory structure and session
#
# @file init_dirs.sh
# @brief Initialize DECKRD documentation directory structure and session
# @description
#   Creates the standard DECKRD directory structure for a module
#   and initializes/updates the session file.
#
#   When called without arguments, creates only the base directory
#   (docs/.deckrd) and displays help.
#
#   Created directories:
#     docs/.deckrd/<namespace>/<module>/
#       ├── requirements/
#       ├── specifications/
#       ├── implementation/
#       └── tasks/
#
# @example
#   # Create base directory only and show help
#   init_dirs.sh
#
#   # Initialize with default settings
#   init_dirs.sh AGTKind/isCollection
#
#   # Initialize with Japanese language
#   init_dirs.sh AGTKind/isCollection --lang ja
#
#   # Initialize with specific AI model
#   init_dirs.sh AGTKind/isCollection --ai-model claude-sonnet-4-5
#
# @exitcode 0 Success
# @exitcode 1 Error during execution
#
# @author atsushifx
# @version 2.0.0
# @license MIT

set -euo pipefail

# ============================================================================
# Script Configuration
# ============================================================================

##
# @description Script directory path
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR

##
# @description Assets inits directory (template files for base directory)
INITS_DIR="${SCRIPT_DIR}/../assets/inits"
readonly INITS_DIR

##
# @description Repository root directory
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
readonly REPO_ROOT

##
# @description DECKRD base directory
DECKRD_BASE="${REPO_ROOT}/docs/.deckrd"
readonly DECKRD_BASE

##
# @description Session file path
SESSION_FILE="${DECKRD_BASE}/.session.json"
readonly SESSION_FILE

##
# @description Default AI model
DEFAULT_AI_MODEL="sonnet"

##
# @description Base subdirectories to create in DECKRD_BASE
BASE_SUBDIRS=("notes" "temp")

##
# @description Module subdirectories to create
SUBDIRS=("requirements" "specifications" "implementation" "tasks")

##
# @description Module path (namespace/module format)
MODULE_PATH=""

##
# @description Document language (system, en, ja, etc.)
LANG_OPT="system"

##
# @description AI model for session
AI_MODEL=""

##
# @description Force new session creation (ignore existing)
FORCE_INIT=false

# ============================================================================
# Functions
# ============================================================================

##
# @description Show usage information
show_usage() {
  cat <<EOF
Usage: init_dirs.sh [OPTIONS] <namespace>/<module>

Initialize DECKRD documentation directory structure and session.

Arguments:
  <namespace>/<module>  Path in format "Namespace/ModuleName"
                        Example: AGTKind/isCollection

Options:
  --lang <lang>         Document language (default: system)
                        Values: system, en, ja, or any language name
  --ai-model <model>    AI model for session (default: ${DEFAULT_AI_MODEL})
                        Supported: gpt-*, o1-*, claude-*, haiku, sonnet, opus
  --force               Force new session creation (ignore existing session)
  -h, --help            Show this help message

Created directories:
  docs/.deckrd/<namespace>/<module>/
    ├── requirements/
    ├── specifications/
    ├── implementation/
    └── tasks/

Session file:
  docs/.deckrd/.session.json
EOF
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
# @description Parse command-line options
parse_options() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -h|--help)
        show_usage
        exit 0
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
      --force)
        FORCE_INIT=true
        shift
        ;;
      -*)
        echo "Error: Unknown option: $1" >&2
        show_usage
        exit 1
        ;;
      *)
        if [[ -n "$MODULE_PATH" ]]; then
          echo "Error: Multiple module paths specified" >&2
          show_usage
          exit 1
        fi
        MODULE_PATH="$1"
        shift
        ;;
    esac
  done
}

##
# @description Initialize base directory only
# @stdout Created directory message
init_base_directory() {
  mkdir -p "$DECKRD_BASE"

  # Create base subdirectories
  for subdir in "${BASE_SUBDIRS[@]}"; do
    mkdir -p "${DECKRD_BASE}/${subdir}"
  done

  echo "Created base directory: ${DECKRD_BASE}"

  # Copy template files from inits directory if they don't exist
  if [[ -d "$INITS_DIR" ]] && [[ -n "$(ls -A "$INITS_DIR" 2>/dev/null)" ]]; then
    cp -n "$INITS_DIR"/* "$DECKRD_BASE/" 2>/dev/null && echo "  Copied template files" || true
  fi
}

##
# @description Validate module path format
# @arg $1 string Module path to validate
# @return 0 if valid, 1 if empty (base-only mode), exits on invalid format
validate_module_path() {
  local path="$1"

  # Empty path: base-only mode
  if [[ -z "$path" ]]; then
    return 1
  fi

  # Invalid format
  if [[ "$path" != */* ]]; then
    echo "Error: Path must be in format <namespace>/<module>" >&2
    echo "  Example: AGTKind/isCollection" >&2
    exit 1
  fi

  # Extract namespace and module
  local namespace="${path%%/*}"
  local module="${path#*/}"

  # Validate namespace (only letters, numbers, hyphens, underscores)
  if [[ ! "$namespace" =~ ^[A-Za-z0-9_-]+$ ]]; then
    echo "Error: Namespace must contain only letters, numbers, hyphens, and underscores" >&2
    echo "  Invalid namespace: ${namespace}" >&2
    exit 1
  fi

  # Validate module (only letters, numbers, hyphens, underscores)
  if [[ ! "$module" =~ ^[A-Za-z0-9_-]+$ ]]; then
    echo "Error: Module must contain only letters, numbers, hyphens, and underscores" >&2
    echo "  Invalid module: ${module}" >&2
    exit 1
  fi

  return 0
}

##
# @description Initialize directory structure
# @arg $1 string Module path (namespace/module)
init_directories() {
  local path="$1"
  local namespace module
  namespace="${path%%/*}"
  module="${path#*/}"

  local base_path="${DECKRD_BASE}/${namespace}/${module}"

  echo "Initializing DECKRD structure: ${namespace}/${module}"

  # Create base directory
  mkdir -p "$DECKRD_BASE"

  for subdir in "${SUBDIRS[@]}"; do
    local full_path="${base_path}/${subdir}"
    mkdir -p "$full_path"
    echo "  Created: ${subdir}/"
  done

  echo ""
  echo "Base path: ${base_path}"
}

##
# @description Create new session file
# @arg $1 string Module path
# @arg $2 string Timestamp
# @arg $3 string Language
# @arg $4 string AI model
create_new_session() {
  local path="$1"
  local timestamp="$2"
  local lang="$3"
  local model="$4"

  cat > "$SESSION_FILE" <<EOF
{
  "active": "${path}",
  "lang": "${lang}",
  "ai_model": "${model}",
  "created_at": "${timestamp}",
  "updated_at": "${timestamp}",
  "modules": {
    "${path}": {
      "current_step": "init",
      "completed": ["init"],
      "documents": {}
    }
  }
}
EOF
}

##
# @description Initialize or update session file
# @arg $1 string Module path
# @arg $2 string Language
# @arg $3 string AI model
init_session() {
  local path="$1"
  local lang="$2"
  local model="$3"
  local timestamp
  timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

  # Force mode: always create new session
  if [[ "$FORCE_INIT" == true ]]; then
    create_new_session "$path" "$timestamp" "$lang" "$model"
    echo ""
    echo "Session created (forced): ${SESSION_FILE}"
    echo "  Active module: ${path}"
    echo "  Language: ${lang}"
    echo "  AI Model: ${model}"
    return 0
  fi

  if [[ -f "$SESSION_FILE" ]]; then
    # Check if jq is available
    if ! command -v jq >/dev/null 2>&1; then
      echo "Warning: jq is not installed. Cannot update session file." >&2
      return 1
    fi

    # Check current active module
    local current_active
    current_active=$(jq -r '.active // empty' "$SESSION_FILE" 2>/dev/null || true)

    if [[ "$current_active" == "$path" ]]; then
      # Same module: preserve existing session
      echo ""
      echo "Session preserved (already active): ${SESSION_FILE}"
      echo "  Active module: ${path}"
      return 0
    fi

    # Different module: update session with jq
    jq --arg path "$path" \
       --arg lang "$lang" \
       --arg model "$model" \
       --arg timestamp "$timestamp" \
       '.active = $path |
        .lang = $lang |
        .ai_model = $model |
        .updated_at = $timestamp |
        .modules[$path] = {
          current_step: "init",
          completed: ["init"],
          documents: {}
        }' "$SESSION_FILE" > "${SESSION_FILE}.tmp" && mv "${SESSION_FILE}.tmp" "$SESSION_FILE"
  else
    create_new_session "$path" "$timestamp" "$lang" "$model"
  fi

  echo ""
  echo "Session updated: ${SESSION_FILE}"
  echo "  Active module: ${path}"
  echo "  Language: ${lang}"
  echo "  AI Model: ${model}"
}

# ============================================================================
# Main Execution
# ============================================================================

parse_options "$@"

# Always create base directory structure (including temp, notes)
init_base_directory

# Validate module path and handle base-only mode
if ! validate_module_path "$MODULE_PATH"; then
  # No module path: show help and exit
  echo ""
  show_usage
  exit 0
fi

# Set default AI model if not specified
if [[ -z "$AI_MODEL" ]]; then
  AI_MODEL="$DEFAULT_AI_MODEL"
fi

init_directories "$MODULE_PATH"
init_session "$MODULE_PATH" "$LANG_OPT" "$AI_MODEL"
