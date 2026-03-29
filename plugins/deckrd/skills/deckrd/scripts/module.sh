#!/usr/bin/env bash
# src: ./skills/deckrd/scripts/module.sh
# @(#) : deckrd モジュールディレクトリ初期化スクリプト
#
# Copyright (c) 2025 atsushifx <https://github.com/atsushifx>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT
#
# @file module.sh
# @brief Initialize DECKRD module directory structure and session
# @description
#   Creates the standard DECKRD directory structure for a module
#   under docs/.deckrd/<namespace>/<module>/ and updates session.json.
#
#   namespace and module names:
#     - Allowed characters: lowercase letters (a-z), hyphen (-), underscore (_)
#     - Case-sensitive: uppercase letters and digits are not allowed
#
# @usage
#   module.sh <namespace>/<module> [--force]
#   module.sh create <namespace>/<module> [--force]
#   module.sh create <module> [--force]
#
# @example
#   module.sh agt-kind/is-collection
#   module.sh myns/mymod --force
#   module.sh create myns/mymod
#   module.sh create myfeature
#
# @exitcode 0 Success
# @exitcode 1 Error during execution
#
# @author atsushifx
# @version 0.1.0
# @license MIT

# shellcheck disable=SC1091

# don't use -u for checking error by Agent
set -eo pipefail

# Load bootstrap (defines SYMBOL, PROJECT_ROOT, DECKRD_LOCAL_DATA, DECKRD_LIB_DIR, etc.)
# shellcheck disable=SC1091
_PROJECT_ROOT="$(git -C "$(dirname "${BASH_SOURCE[0]}")" rev-parse --show-toplevel)"
. "${_PROJECT_ROOT}/plugins/_runtime/libs/bootstrap.lib.sh"
unset _PROJECT_ROOT

# Validate environment (requires jq)
. "${DECKRD_LIB_DIR}/validate-env.sh"
_validate_env_errmsg=$(validate_env) || {
  echo "$_validate_env_errmsg" >&2
  exit 1
}
unset _validate_env_errmsg

# ============================================================================
# Script Configuration
# ============================================================================
# Variables provided by bootstrap.sh:
#   PROJECT_ROOT      - repository root
#   DECKRD_DOCS_DIR   - docs/.deckrd base directory
#   DECKRD_LOCAL_DATA - .local/deckrd directory

##
# @description Session file path
SESSION_FILE="${DECKRD_LOCAL_DATA}/session.json"
readonly SESSION_FILE

##
# @description Module subdirectories to create
SUBDIRS=("requirements" "specifications" "implementation" "tasks")
readonly SUBDIRS

##
# @description Module path (namespace/module, raw input)
MODULE_PATH=""

##
# @description Subcommand (e.g. "create")
SUBCOMMAND=""

##
# @description Force re-initialization
FORCE=false

# ============================================================================
# Functions
# ============================================================================

##
# @description Show usage information
show_usage() {
  cat <<EOF
Usage: module.sh <namespace>/<module> [--force]
       module.sh <module> [--force]
       module.sh create <namespace>/<module> [--force]
       module.sh create <module> [--force]

Initialize DECKRD module directory structure and update session.

Subcommands:
  create    Create module dirs and update session (alias for default behavior)

Arguments:
  <namespace>/<module>  Module path (e.g. agt-kind/is-collection)
  <module>              Module name only; namespace auto-resolved from project name
                        Allowed: a-z, hyphen, underscore (lowercase only)

Options:
  --force   Re-initialize even if module directory already exists
  -h, --help  Show this help message

Created directories:
  docs/.deckrd/<namespace>/<module>/
    ├── requirements/
    ├── specifications/
    ├── implementation/
    └── tasks/

Session file:
  .local/deckrd/session.json
EOF
}

##
# @description Parse command-line arguments
parse_args() {
  # Check for "create" subcommand as first positional argument
  if [[ $# -gt 0 && "$1" == "create" ]]; then
    # shellcheck disable=SC2034
    SUBCOMMAND="create"
    shift
  fi

  while [[ $# -gt 0 ]]; do
    case "$1" in
    -h | --help)
      show_usage
      exit 0
      ;;
    --force)
      FORCE=true
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
# @description Validate and normalize module path
# @arg $1 string Raw module path (namespace/module)
# @stdout Normalized path (lowercase)
# @return 0 on success, exits on error
validate_and_normalize() {
  local raw="$1"

  # Must contain exactly one slash
  if [[ "$raw" != */* ]]; then
    echo "Error: Path must be in format <namespace>/<module>" >&2
    echo "  Example: agt-kind/is-collection" >&2
    exit 1
  fi

  local namespace="${raw%%/*}"
  local module="${raw#*/}"

  # Reject empty parts
  if [[ -z "$namespace" || -z "$module" ]]; then
    echo "Error: namespace and module must not be empty" >&2
    exit 1
  fi

  # Validate characters using SYMBOL pattern (lowercase, hyphen, underscore only)
  if [[ ! "$namespace" =~ ^${SYMBOL}$ ]]; then
    echo "Error: namespace '${namespace}' contains invalid characters" >&2
    echo "  Allowed: a-z, hyphen (-), underscore (_)" >&2
    exit 1
  fi
  if [[ ! "$module" =~ ^${SYMBOL}$ ]]; then
    echo "Error: module '${module}' contains invalid characters" >&2
    echo "  Allowed: a-z, hyphen (-), underscore (_)" >&2
    exit 1
  fi

  echo "${namespace}/${module}"
}

##
# @description Resolve default namespace for module path fallback
# @description Priority: .project.json project field > git remote origin repo name
# @stdout Namespace string (lowercase)
# @stderr Error message if neither source is available
# @return 0 on success, 1 on error
_get_default_ns() {
  local project_file="${DECKRD_LOCAL_DATA}/.project.json"

  # 1st priority: .project.json の project フィールド
  if [[ -f "$project_file" ]]; then
    local project_name
    project_name=$(jq -r '.project // empty' "$project_file" 2>/dev/null)
    if [[ -n "$project_name" ]]; then
      echo "$project_name"
      return 0
    fi
  fi

  # 2nd priority: ローカルリポジトリのルートディレクトリ名を取得
  local repo_root
  repo_root=$(git rev-parse --show-toplevel 2>/dev/null) || {
    echo "Error: Cannot resolve default namespace: no .project.json and not in a git repository" >&2
    return 1
  }
  local repo_name
  repo_name="${repo_root##*/}"
  repo_name="${repo_name,,}"
  if [[ -z "$repo_name" ]]; then
    echo "Error: Cannot extract repository name from git root directory" >&2
    return 1
  fi
  echo "$repo_name"
}

##
# @description Validate and normalize module path with namespace fallback
# @arg $1 string Raw module path (<namespace>/<module> or <module>)
# @stdout Normalized path (lowercase)
# @return 0 on success, exits on error
validate_and_normalize_with_fallback() {
  local raw="$1"
  if [[ "$raw" == */* ]]; then
    # <namespace>/<module> form: delegate to existing validator
    validate_and_normalize "$raw"
  else
    # <module> form: auto-resolve namespace from project name or git remote
    local namespace
    namespace=$(_get_default_ns) || exit 1
    validate_and_normalize "${namespace}/${raw}"
  fi
}

##
# @description Create module directory structure
# @arg $1 string Normalized module path (namespace/module)
create_module_dirs() {
  local path="$1"
  local namespace="${path%%/*}"
  local module="${path#*/}"
  local base="${DECKRD_DOCS_DIR}/${namespace}/${module}"

  # Check existing (without --force)
  if [[ -d "$base" && "$FORCE" == false ]]; then
    echo "Error: Module directory already exists: ${base}" >&2
    echo "  Use --force to re-initialize." >&2
    exit 1
  fi

  echo "Initializing module: ${namespace}/${module}"
  for subdir in "${SUBDIRS[@]}"; do
    mkdir -p "${base}/${subdir}"
    echo "  created: ${subdir}/"
  done
  echo ""
  echo "Module path: ${base}"
}

##
# @description Update session.json with active module
# @arg $1 string Normalized module path
update_session() {
  local path="$1"
  local timestamp
  timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

  mkdir -p "$DECKRD_LOCAL_DATA"

  if [[ -f "$SESSION_FILE" ]]; then
    # Update: set active module, add/reset module entry in modules hierarchy
    jq --arg path "$path" \
      --arg timestamp "$timestamp" \
      '.active = $path |
        .updated_at = $timestamp |
        .modules[$path] = {
          current_step: "module",
          completed: ["module"],
          documents: {}
        }' \
      "$SESSION_FILE" >"${SESSION_FILE}.tmp" &&
      mv "${SESSION_FILE}.tmp" "$SESSION_FILE"
  else
    # Create new session file with modules hierarchy
    jq -n \
      --arg path "$path" \
      --arg timestamp "$timestamp" \
      '{
        active:      $path,
        modules:     {
          ($path): {
            current_step: "module",
            completed:    ["module"],
            documents:    {}
          }
        },
        created_at:  $timestamp,
        updated_at:  $timestamp
      }' >"$SESSION_FILE"
  fi

  echo ""
  echo "Session updated: ${SESSION_FILE}"
  echo "  active module: ${path}"
}

# ============================================================================
# Main Execution
# ============================================================================

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  parse_args "$@"

  if [[ -z "$MODULE_PATH" ]]; then
    echo "Error: <namespace>/<module> is required" >&2
    show_usage
    exit 1
  fi

  NORMALIZED=$(validate_and_normalize_with_fallback "$MODULE_PATH")
  create_module_dirs "$NORMALIZED"
  update_session "$NORMALIZED"
fi
