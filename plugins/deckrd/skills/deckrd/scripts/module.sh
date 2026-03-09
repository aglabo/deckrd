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
#     - Allowed characters: alphabet (a-z, A-Z), digits (0-9), hyphen (-), underscore (_)
#     - Case-insensitive: normalized to lowercase
#
# @usage
#   module.sh <namespace>/<module> [--force]
#   module.sh create <namespace>/<module> [--force]
#   module.sh create <module> [--force]
#
# @example
#   module.sh AGTKind/isCollection
#   module.sh myns/mymod --force
#   module.sh create myns/mymod
#   module.sh create myfeature
#
# @exitcode 0 Success
# @exitcode 1 Error during execution
#
# @author atsushifx
# @version 1.1.0
# @license MIT

# don't use -u for checking error by Agent
set -eo pipefail

# ============================================================================
# Script Configuration
# ============================================================================

##
# @description Repository root directory
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
readonly REPO_ROOT

##
# @description DECKRD docs directory
DECKRD_DOCS="${DECKRD_DOCS:-${REPO_ROOT}/docs/.deckrd}"
readonly DECKRD_DOCS

##
# @description DECKRD local config directory
DECKRD_LOCAL="${REPO_ROOT}/.local/deckrd"
readonly DECKRD_LOCAL

##
# @description Session file path
SESSION_FILE="${DECKRD_LOCAL}/session.json"
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
       module.sh create <namespace>/<module> [--force]
       module.sh create <module> [--force]

Initialize DECKRD module directory structure and update session.

Subcommands:
  create    Create module dirs and .profile.json (subdomain auto-resolved if omitted)

Arguments:
  <namespace>/<module>  Module path (e.g. AGTKind/isCollection)
  <module>              Module name only; subdomain auto-resolved from git remote name
                        Allowed: a-z, A-Z, 0-9, hyphen, underscore
                        Case-insensitive: normalized to lowercase

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
    SUBCOMMAND="create"
    shift
  fi

  while [[ $# -gt 0 ]]; do
    case "$1" in
      -h|--help)
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
    echo "  Example: AGTKind/isCollection" >&2
    exit 1
  fi

  local namespace="${raw%%/*}"
  local module="${raw#*/}"

  # Reject empty parts
  if [[ -z "$namespace" || -z "$module" ]]; then
    echo "Error: namespace and module must not be empty" >&2
    exit 1
  fi

  # Validate characters (alphabet, digits, hyphen, underscore only)
  local pattern='^[A-Za-z0-9_-]+$'
  if [[ ! "$namespace" =~ $pattern ]]; then
    echo "Error: namespace '${namespace}' contains invalid characters" >&2
    echo "  Allowed: a-z, A-Z, 0-9, hyphen (-), underscore (_)" >&2
    exit 1
  fi
  if [[ ! "$module" =~ $pattern ]]; then
    echo "Error: module '${module}' contains invalid characters" >&2
    echo "  Allowed: a-z, A-Z, 0-9, hyphen (-), underscore (_)" >&2
    exit 1
  fi

  # Normalize to lowercase
  local ns_lower mod_lower
  ns_lower="${namespace,,}"
  mod_lower="${module,,}"

  echo "${ns_lower}/${mod_lower}"
}

##
# @description Get repository name from git remote origin URL
# @stdout Repository name (lowercase, without .git suffix)
# @return 0 on success, exits on error
get_repo_name() {
  local remote_url
  remote_url=$(git remote get-url origin 2>/dev/null) || {
    echo "Error: Cannot get git remote origin URL" >&2
    exit 1
  }
  local repo_name
  repo_name="${remote_url##*/}"
  repo_name="${repo_name##*:}"
  repo_name="${repo_name%.git}"
  repo_name="${repo_name,,}"
  [[ -z "$repo_name" ]] && { echo "Error: Cannot extract repository name" >&2; exit 1; }
  echo "$repo_name"
}

##
# @description Validate and normalize module path for create subcommand
# @arg $1 string Raw module path (<subdomain>/<module> or <module>)
# @stdout Normalized path (lowercase)
# @return 0 on success, exits on error
validate_and_normalize_create() {
  local raw="$1"
  if [[ "$raw" == */* ]]; then
    # <subdomain>/<module> form: delegate to existing validator
    validate_and_normalize "$raw"
  else
    # <module> form: auto-resolve subdomain from git remote name
    local subdomain
    subdomain=$(get_repo_name)
    validate_and_normalize "${subdomain}/${raw}"
  fi
}

##
# @description Create .profile.json for a module
# @arg $1 string Normalized module path (namespace/module)
create_module_profile() {
  local path="$1"
  local namespace="${path%%/*}"
  local module="${path#*/}"
  local base="${DECKRD_DOCS}/${namespace}/${module}"
  local profile_file="${base}/.profile.json"
  local timestamp
  timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

  if command -v jq >/dev/null 2>&1; then
    jq -n \
      --arg name        "$module" \
      --arg description "" \
      --arg created_at  "$timestamp" \
      --arg updated_at  "$timestamp" \
      '{name: $name, description: $description, created_at: $created_at, updated_at: $updated_at}' \
      > "$profile_file"
  else
    printf '{\n  "name": "%s",\n  "description": "",\n  "created_at": "%s",\n  "updated_at": "%s"\n}\n' \
      "$module" "$timestamp" "$timestamp" > "$profile_file"
  fi

  echo "  created: .profile.json"
}

##
# @description Create module directory structure
# @arg $1 string Normalized module path (namespace/module)
create_module_dirs() {
  local path="$1"
  local namespace="${path%%/*}"
  local module="${path#*/}"
  local base="${DECKRD_DOCS}/${namespace}/${module}"

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

  mkdir -p "$DECKRD_LOCAL"

  if [[ -f "$SESSION_FILE" ]] && command -v jq >/dev/null 2>&1; then
    # Update: set active module, add/reset module entry
    jq --arg path      "$path" \
       --arg timestamp "$timestamp" \
       '.active       = $path |
        .updated_at   = $timestamp |
        .current_step = "init" |
        .completed    = ["init"] |
        .documents    = {}' \
       "$SESSION_FILE" > "${SESSION_FILE}.tmp" \
    && mv "${SESSION_FILE}.tmp" "$SESSION_FILE"
  else
    # Fallback: create/overwrite without jq
    cat > "$SESSION_FILE" <<EOF
{
  "active":       "${path}",
  "current_step": "init",
  "completed":    ["init"],
  "documents":    {},
  "created_at":   "${timestamp}",
  "updated_at":   "${timestamp}"
}
EOF
  fi

  echo ""
  echo "Session updated: ${SESSION_FILE}"
  echo "  active module: ${path}"
}

# ============================================================================
# Main Execution
# ============================================================================

parse_args "$@"

if [[ -z "$MODULE_PATH" ]]; then
  echo "Error: <namespace>/<module> is required" >&2
  show_usage
  exit 1
fi

if [[ "$SUBCOMMAND" == "create" ]]; then
  NORMALIZED=$(validate_and_normalize_create "$MODULE_PATH")
  create_module_dirs "$NORMALIZED"
  create_module_profile "$NORMALIZED"
  update_session "$NORMALIZED"
else
  NORMALIZED=$(validate_and_normalize "$MODULE_PATH")
  create_module_dirs "$NORMALIZED"
  update_session "$NORMALIZED"
fi
