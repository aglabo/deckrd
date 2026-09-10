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
_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
. "${_SCRIPT_DIR}/libs/bootstrap.lib.sh"
unset _SCRIPT_DIR

# Validate environment (requires jq)
. "${DECKRD_LIB_DIR}/validate-env.lib.sh"
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

##
# @description Explicit test scope given via --test-scope (empty means derive it)
TEST_SCOPE=""

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
  --test-scope <SCOPE>  Test ID scope (2-4 uppercase alphanumerics); derived from the module name if omitted
  -h, --help  Show this help message

Created directories:
  docs/.deckrd/<namespace>/<module>/
    ├── requirements/
    ├── specifications/
    ├── implementation/
    ├── tasks/
    └── module.md

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
    --test-scope)
      if [[ $# -lt 2 || -z "$2" ]]; then
        echo "Error: --test-scope requires a value" >&2
        show_usage
        exit 1
      fi
      TEST_SCOPE="$2"
      shift 2
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
    project_name=$(${jqexe:-jq} -r '.project // empty' "$project_file" 2>/dev/null)
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
# @description Derive a test ID scope abbreviation from a module name
# @description Multi-word names use each word initial (max 4); single words use the first 3 characters
# @arg $1 string Module name (the <module> part of <namespace>/<module>)
# @stdout Scope abbreviation (uppercase, 2-4 characters)
# @stderr Error message if the derived scope is shorter than 2 characters
# @exitcode 0 Success
# @exitcode 1 Derived scope is shorter than 2 characters
derive_test_scope() {
  local rest="$1"
  local scope=""
  local word

  if [[ "$rest" != *[-_]* ]]; then
    # Single word: take the first 3 characters
    scope="${rest:0:3}"
  else
    # Multiple words: concatenate each initial, up to 4 characters
    while [[ -n "$rest" ]]; do
      word="${rest%%[-_]*}"
      if [[ "$rest" == *[-_]* ]]; then
        rest="${rest#*[-_]}"
      else
        rest=""
      fi
      if [[ -n "$word" ]]; then
        scope+="${word:0:1}"
      fi
      if [[ ${#scope} -ge 4 ]]; then
        break
      fi
    done
  fi

  scope="${scope^^}"
  if [[ ${#scope} -lt 2 ]]; then
    echo "Error: cannot derive a test scope from module name '$1'" >&2
    echo "  A test scope needs at least 2 characters; derived '${scope}'." >&2
    return 1
  fi

  echo "$scope"
}

##
# @description Read test_scope from the YAML frontmatter of a module.md
# @arg $1 string Path to a module.md file
# @stdout The declared test scope, or nothing when there is no frontmatter test_scope
# @exitcode 0 Always
_read_frontmatter_scope() {
  awk '
    NR == 1 && $0 != "---" { exit }
    NR > 1 && $0 == "---" { exit }
    NR > 1 && /^test_scope:/ {
      value = $0
      sub(/^test_scope:[[:space:]]*/, "", value)
      gsub(/[[:space:]]+$/, "", value)
      # Unwrap only a matching pair of quotes; an unbalanced quote stays in the value
      if (length(value) >= 2 && substr(value, 1, 1) == substr(value, length(value), 1) && (substr(value, 1, 1) == "\"" || substr(value, 1, 1) == "\047")) {
        unwrapped = substr(value, 2, length(value) - 2)
        # Empty quotes are a declared-but-invalid value, not an undeclared field:
        # keep the quotes so the caller format check rejects it loudly
        if (unwrapped != "") { value = unwrapped }
      }
      print value
      exit
    }
  ' "$1"
}

##
# @description List the test scopes already declared by existing modules
# @description Reads test_scope from the frontmatter of ${DECKRD_DOCS_DIR}/*/*/module.md
# @stdout One line per declared scope: <test_scope><TAB><path relative to DECKRD_DOCS_DIR>
# @exitcode 0 Always (no module.md means no output)
collect_declared_scopes() {
  local module_file scope

  for module_file in "${DECKRD_DOCS_DIR}"/*/*/module.md; do
    # nullglob is not set: an unmatched glob stays as a literal path
    [[ -f "$module_file" ]] || continue
    scope=$(_read_frontmatter_scope "$module_file")
    [[ -n "$scope" ]] || continue
    printf '%s\t%s\n' "$scope" "${module_file#"${DECKRD_DOCS_DIR}"/}"
  done

  return 0
}

##
# @description Read the test scope a module already declares in its own module.md
# @arg $1 string Normalized module path (namespace/module)
# @stdout The declared test scope, or nothing when module.md or its test_scope is absent
# @exitcode 0 Always (an absent declaration is not an error)
read_declared_scope() {
  local module_file="${DECKRD_DOCS_DIR}/$1/module.md"

  [[ -f "$module_file" ]] || return 0
  _read_frontmatter_scope "$module_file"
}

##
# @description Resolve the test scope a module should declare
# @description An explicit scope is validated as given; otherwise it is derived from the module name
# @description The module's own module.md is excluded from conflict detection (--force re-initialization)
# @arg $1 string Normalized module path (namespace/module)
# @arg $2 string Explicit test scope (optional, may be empty)
# @stdout The resolved scope (uppercase alphanumeric, 2-4 characters)
# @stderr Error message if the explicit scope is malformed, underivable, or already taken
# @exitcode 0 Success
# @exitcode 1 Malformed explicit scope, underivable scope, or conflict with an existing module
resolve_test_scope() {
  local path="$1"
  local explicit="${2:-}"
  local candidate declared scope owner

  if [[ -n "$explicit" ]]; then
    if [[ ! "$explicit" =~ ^[A-Z0-9]{2,4}$ ]]; then
      echo "Error: invalid test scope '${explicit}'" >&2
      echo "  A test scope must be 2-4 uppercase letters or digits (e.g. NOR)." >&2
      return 1
    fi
    candidate="$explicit"
  else
    candidate=$(derive_test_scope "${path#*/}") || return 1
  fi

  declared=$(collect_declared_scopes)
  while IFS=$'\t' read -r scope owner; do
    # The module's own declaration is not a conflict (--force re-initialization)
    [[ "$owner" != "${path}/module.md" ]] || continue
    [[ "$scope" == "$candidate" ]] || continue
    echo "Error: test scope '${candidate}' conflicts with an existing module" >&2
    echo "  already declared in: ${owner}" >&2
    echo "  Use --test-scope <another scope> to choose a different one." >&2
    return 1
  done <<<"$declared"

  echo "$candidate"
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
# @description Create the module metadata file (module.md)
# @description An existing module.md is left untouched so that --force re-initialization keeps its test_scope
# @arg $1 string Normalized module path (namespace/module)
# @arg $2 string Resolved test scope
# @stdout Path of the module metadata file
# @exitcode 0 Success
create_module_meta() {
  local path="$1"
  local scope="$2"
  local module="${path#*/}"
  local base="${DECKRD_DOCS_DIR}/${path}"
  local meta_file="${base}/module.md"

  if [[ -f "$meta_file" ]]; then
    echo "Module meta: ${meta_file} (kept existing test_scope)"
    return 0
  fi

  mkdir -p "$base"
  cat >"$meta_file" <<EOF
---
title: ${module}
test_scope: ${scope}
owns:
  - # TODO: このモジュールが所有するソース・テストのルートを書く（glob 可・複数可）
---

## ${module}

（モジュールの概要をここに書く）

## テスト対象の略語

| 略語 | 対象 |
| ---- | ---- |
|      |      |
EOF

  echo "Module meta: ${meta_file}"
}

##
# @description Update session.json with active module
# @description Records the module test scope alongside the workflow state
# @arg $1 string Normalized module path
# @arg $2 string Resolved test scope
update_session() {
  local path="$1"
  local scope="$2"
  local timestamp
  timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

  mkdir -p "$DECKRD_LOCAL_DATA"

  if [[ -f "$SESSION_FILE" ]]; then
    # Update: set active module, add/reset module entry in modules hierarchy
    # shellcheck disable=SC2016
    ${jqexe:-jq} --arg path "$path" \
      --arg scope "$scope" \
      --arg timestamp "$timestamp" \
      '.active = $path |
        .updated_at = $timestamp |
        .modules[$path] = {
          current_step: "module",
          completed: ["module"],
          documents: {},
          test_scope: $scope
        }' \
      "$SESSION_FILE" >"${SESSION_FILE}.tmp" &&
      mv "${SESSION_FILE}.tmp" "$SESSION_FILE"
  else
    # Create new session file with modules hierarchy
    # shellcheck disable=SC2016
    ${jqexe:-jq} -n \
      --arg path "$path" \
      --arg scope "$scope" \
      --arg timestamp "$timestamp" \
      '{
        active:      $path,
        modules:     {
          ($path): {
            current_step: "module",
            completed:    ["module"],
            documents:    {},
            test_scope:   $scope
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

  # The module's own module.md is the source of truth when no scope is given explicitly
  if [[ -z "$TEST_SCOPE" ]]; then
    TEST_SCOPE=$(read_declared_scope "$NORMALIZED")
  fi

  RESOLVED_SCOPE=$(resolve_test_scope "$NORMALIZED" "$TEST_SCOPE") || exit 1
  create_module_meta "$NORMALIZED" "$RESOLVED_SCOPE"
  update_session "$NORMALIZED" "$RESOLVED_SCOPE"
fi
