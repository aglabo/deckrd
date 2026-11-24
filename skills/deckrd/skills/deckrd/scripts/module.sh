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
#   module.sh <namespace>/<module> [--force] [--test-scope <SCOPE>]
#   module.sh <module> [--force] [--test-scope <SCOPE>]
#   module.sh create <namespace>/<module> [--force] [--test-scope <SCOPE>]
#   module.sh create <module> [--force] [--test-scope <SCOPE>]
#   (--test-scope also accepts the inline form --test-scope=<SCOPE>)
#
# @example
#   module.sh agt-kind/is-collection
#   module.sh myns/mymod --force
#   module.sh myns/mymod --test-scope=MYM
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

# No -u: an unbound variable would abort with bash's own message
# before the script prints an error the agent can act on
set -eo pipefail

# Load bootstrap (defines SYMBOL, PROJECT_ROOT, DECKRD_LOCAL_DATA, DECKRD_LIB_DIR, etc.)
_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
. "${_SCRIPT_DIR}/libs/bootstrap.lib.sh"
unset _SCRIPT_DIR

# validate_env runs in main, not at source time (requires jq or jaq)
. "${DECKRD_LIB_DIR}/validate-env.lib.sh"
. "${DECKRD_LIB_DIR}/utils.lib.sh"
. "${DECKRD_LIB_DIR}/args.lib.sh"

# ============================================================================
# Script Configuration
# ============================================================================
# Variables provided by bootstrap.lib.sh:
#   PROJECT_ROOT      - repository root
#   DECKRD_DOCS_DIR   - docs/.deckrd base directory
#   DECKRD_LOCAL_DATA - .local/deckrd directory

# ============================================================================
# Functions
# ============================================================================

##
# @description Initialize script configuration variables
# @description SESSION_FILE uses ${VAR:-default} to allow external override (mock)
# @description OPTIONS / OPTIONS_SET are not declared here: args_init (libs/args.lib.sh) owns them
# @description SUBCOMMAND is reset on every call
init_vars()
            {
  SESSION_FILE="${SESSION_FILE:-${DECKRD_LOCAL_DATA}/session.json}"
  SUBDIRS=("requirements" "specifications" "implementation" "tasks" "workspaces")
  MODULE_META_SUBPATH="workspaces/module/module.md"
  SUBCOMMAND=""
}

##
# @description Show usage information
# @stdout Usage text (stdout, also when reporting argument errors)
show_usage()
             {
  cat << EOF
Usage: module.sh <namespace>/<module> [--force] [--test-scope <SCOPE>]
       module.sh <module> [--force] [--test-scope <SCOPE>]
       module.sh create <namespace>/<module> [--force] [--test-scope <SCOPE>]
       module.sh create <module> [--force] [--test-scope <SCOPE>]

Initialize DECKRD module directory structure and update session.
If the module directory already exists, switch the active module instead
(--test-scope cannot be combined with switching; use --force to re-initialize).

Subcommands:
  create    Create module dirs and update session (alias for default behavior)

Arguments:
  <namespace>/<module>  Module path (e.g. agt-kind/is-collection)
  <module>              Module name only; namespace auto-resolved from project name
                        Allowed: a-z, hyphen, underscore (lowercase only)

Options:
  --force               Re-initialize an existing module (resets its progress);
                        without it, an existing module is switched to (progress is kept)
  --test-scope <SCOPE>  Test ID scope (2-4 uppercase alphanumerics); derived from the module name if omitted
                        Also accepts the inline form --test-scope=<SCOPE>
  -h, --help            Show this help message

Created directories:
  docs/.deckrd/<namespace>/<module>/
    ├── requirements/
    ├── specifications/
    ├── implementation/
    ├── tasks/
    └── workspaces/
        └── module/
            └── module.md

Session file:
  .local/deckrd/session.json
EOF
}

##
# @description Validate and normalize module path
# @arg $1 string Raw module path (namespace/module)
# @stdout Normalized path (lowercase)
# @return 0 on success, 1 on error (message on stderr)
validate_and_normalize()
                         {
  local raw="$1"

  if [[ $raw != */*   ]]; then
    echo "Error: Path must be in format <namespace>/<module>" >&2
    echo "  Example: agt-kind/is-collection" >&2
    return 1
  fi

  local namespace="${raw%%/*}"
  local module="${raw#*/}"

  if [[ -z $namespace || -z $module     ]]; then
    echo "Error: namespace and module must not be empty" >&2
    return 1
  fi

  if [[ ! $namespace =~ ^${SYMBOL}$   ]]; then
    echo "Error: namespace '${namespace}' contains invalid characters" >&2
    echo "  Allowed: a-z, hyphen (-), underscore (_)" >&2
    return 1
  fi
  if [[ ! $module =~ ^${SYMBOL}$   ]]; then
    echo "Error: module '${module}' contains invalid characters" >&2
    echo "  Allowed: a-z, hyphen (-), underscore (_)" >&2
    return 1
  fi

  echo "${namespace}/${module}"
}

##
# @description Resolve default namespace for module path fallback
# @description Priority: .project.json project field > git repository root directory name
# @stdout Namespace string (lowercase)
# @stderr Error message if neither source is available
# @return 0 on success, 1 on error
_get_default_ns()
                  {
  local project_file="${DECKRD_LOCAL_DATA}/.project.json"

  if [[ -f $project_file   ]]; then
    local project_name
    project_name=$(jq_read -r '.project // empty' "$project_file" 2> /dev/null)
    if [[ -n $project_name   ]]; then
      echo "$project_name"
      return 0
    fi
  fi

  local repo_root
  repo_root=$(git rev-parse --show-toplevel 2> /dev/null) || {
    echo "Error: Cannot resolve default namespace: no .project.json and not in a git repository" >&2
    return 1
  }
  local repo_name
  repo_name="${repo_root##*/}"
  repo_name="${repo_name,,}"
  if [[ -z $repo_name   ]]; then
    echo "Error: Cannot extract repository name from git root directory" >&2
    return 1
  fi
  echo "$repo_name"
}

##
# @description Validate and normalize module path with namespace fallback
# @arg $1 string Raw module path (<namespace>/<module> or <module>)
# @stdout Normalized path (lowercase)
# @stderr Error message if the default namespace cannot be resolved or the path is invalid
# @return 0 on success, 1 on error (namespace resolution or validation failure)
validate_and_normalize_with_fallback()
                                       {
  local raw="$1"
  if [[ $raw == */*   ]]; then
    validate_and_normalize "$raw"
  else
    local namespace
    namespace=$(_get_default_ns) || return 1
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
derive_test_scope()
                    {
  local rest="$1"
  local scope=""
  local word

  if [[ $rest != *[-_]*   ]]; then
    scope="${rest:0:3}"
  else
    while [[ -n $rest   ]]; do
      word="${rest%%[-_]*}"
      if [[ $rest == *[-_]*   ]]; then
        rest="${rest#*[-_]}"
      else
        rest=""
      fi
      if [[ -n $word   ]]; then
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
_read_frontmatter_scope()
                          {
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
# @description Reads test_scope from the frontmatter of ${DECKRD_DOCS_DIR}/*/*/workspaces/module/module.md
# @stdout One line per declared scope: <test_scope><TAB><path relative to DECKRD_DOCS_DIR>
# @exitcode 0 Always (no module.md means no output)
collect_declared_scopes()
                          {
  local module_file scope

  for module_file in "${DECKRD_DOCS_DIR}"/*/*/"${MODULE_META_SUBPATH}"; do
    # nullglob is not set: an unmatched glob stays as a literal path
    [[ -f $module_file   ]] || continue
    scope=$(_read_frontmatter_scope "$module_file")
    [[ -n $scope   ]] || continue
    printf '%s\t%s\n' "$scope" "${module_file#"${DECKRD_DOCS_DIR}"/}"
  done

  return 0
}

##
# @description Read the test scope a module already declares in its own module.md
# @arg $1 string Normalized module path (namespace/module)
# @stdout The declared test scope, or nothing when module.md or its test_scope is absent
# @exitcode 0 Always (an absent declaration is not an error)
read_declared_scope()
                      {
  local module_file="${DECKRD_DOCS_DIR}/$1/${MODULE_META_SUBPATH}"

  [[ -f $module_file   ]] || return 0
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
resolve_test_scope()
                     {
  local path="$1"
  local explicit="${2:-}"
  local candidate declared scope owner own_scope

  if [[ -n $explicit   ]]; then
    if [[ ! $explicit =~ ^[A-Z0-9]{2,4}$   ]]; then
      echo "Error: invalid test scope '${explicit}'" >&2
      echo "  A test scope must be 2-4 uppercase letters or digits (e.g. NOR)." >&2
      return 1
    fi
    # Rewriting a declared scope would invalidate every test ID already using it
    own_scope=$(read_declared_scope "$path")
    if [[ -n $own_scope && $own_scope != "$explicit"     ]]; then
      echo "Error: module '${path}' already declares test scope '${own_scope}'" >&2
      echo "  given explicit scope: '${explicit}'" >&2
      echo "  Edit module.md directly to change it; every existing test ID becomes invalid." >&2
      return 1
    fi
    candidate="$explicit"
  else
    candidate=$(derive_test_scope "${path#*/}") || return 1
  fi

  declared=$(collect_declared_scopes)
  while IFS=$'\t' read -r scope owner; do
    # The module's own declaration is not a conflict (--force re-initialization)
    [[ $owner != "${path}/${MODULE_META_SUBPATH}"   ]] || continue
    [[ $scope == "$candidate"   ]] || continue
    echo "Error: test scope '${candidate}' conflicts with an existing module" >&2
    echo "  already declared in: ${owner}" >&2
    echo "  Use --test-scope <another scope> to choose a different one." >&2
    return 1
  done <<< "$declared"

  echo "$candidate"
}

##
# @description Create module directory structure
# @arg $1 string Normalized module path (namespace/module)
# @arg $2 string "true" to re-initialize an existing module directory (default: "false")
# @stdout Progress messages and the module path
# @stderr Error message when the directory exists and force is "false",
#         or when a subdirectory cannot be created
# @return 0 on success, 1 if the module directory already exists and force is "false",
#         or if a subdirectory cannot be created
create_module_dirs()
                     {
  local path="$1"
  local force="${2:-false}"
  local namespace="${path%%/*}"
  local module="${path#*/}"
  local base="${DECKRD_DOCS_DIR}/${namespace}/${module}"

  if [[ -d $base && $force == false     ]]; then
    echo "Error: Module directory already exists: ${base}" >&2
    echo "  Use --force to re-initialize." >&2
    return 1
  fi

  echo "Initializing module: ${namespace}/${module}"
  for subdir in "${SUBDIRS[@]}"; do
    mkdir -p "${base}/${subdir}" || {
      echo "Error: failed to create directory: ${base}/${subdir}" >&2
      return 1
    }
    echo "  created: ${subdir}/"
  done
  echo ""
  echo "Module path: ${base}"
}

##
# @description Create the module metadata file (<module>/workspaces/module/module.md)
# @description An existing module.md is left untouched so that --force re-initialization keeps its test_scope
# @arg $1 string Normalized module path (namespace/module)
# @arg $2 string Resolved test scope
# @stdout Path of the module metadata file
# @exitcode 0 Success
create_module_meta()
                     {
  local path="$1"
  local scope="$2"
  local module="${path#*/}"
  local base="${DECKRD_DOCS_DIR}/${path}"
  local meta_file="${base}/${MODULE_META_SUBPATH}"

  if [[ -f $meta_file   ]]; then
    echo "Module meta: ${meta_file} (kept existing test_scope)"
    return 0
  fi

  mkdir -p "${meta_file%/*}"
  cat > "$meta_file" << EOF
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
# @description Writes through write_json_file, so a failed write leaves no partial file or temp file
# @arg $1 string Normalized module path
# @arg $2 string Resolved test scope
# @stdout "Session updated" summary (only when the write succeeds)
# @stderr Error message when session.json cannot be written ("Session updated" is not printed)
# @return 0 on success, 1 if the session.json write fails
update_session()
                 {
  local path="$1"
  local scope="$2"
  local timestamp
  timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  local -a jq_args=(--arg path "$path" --arg scope "$scope" --arg timestamp "$timestamp")

  mkdir -p "$DECKRD_LOCAL_DATA"

  if [[ -f $SESSION_FILE   ]]; then
    # shellcheck disable=SC2016
    write_json_file "$SESSION_FILE" "${jq_args[@]}" \
      '.active = $path |
        .updated_at = $timestamp |
        .modules[$path] = {
          current_step: "module",
          completed: ["module"],
          documents: {},
          test_scope: $scope
        }' \
      "$SESSION_FILE"
  else
    # shellcheck disable=SC2016
    write_json_file "$SESSION_FILE" -n "${jq_args[@]}" \
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
      }'
  fi || {
    echo "Error: update_session: failed to write: ${SESSION_FILE}" >&2
    return 1
  }

  echo ""
  echo "Session updated: ${SESSION_FILE}"
  echo "  active module: ${path}"
}

##
# @description Switch the active module of an existing session.json
# @description Sets only .active and .updated_at; every module entry (progress) is kept
# @arg $1 string Normalized module path
# @stdout "Switched active module" message (only when the write succeeds)
# @stderr Error message when the session or the module entry is missing, or the write fails
# @return 0 on success, 1 otherwise
switch_session()
                 {
  local path="$1"
  local timestamp
  timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

  if [[ ! -f $SESSION_FILE ]]; then
    echo "Error: switch_session: session not found: ${SESSION_FILE} (use --force to create the module)" >&2
    return 1
  fi

  # shellcheck disable=SC2016
  if ! jq_read -e --arg path "$path" 'has("modules") and (.modules | has($path))' "$SESSION_FILE" > /dev/null; then
    echo "Error: switch_session: no module entry for ${path} in ${SESSION_FILE} (use --force to create the module)" >&2
    return 1
  fi

  # shellcheck disable=SC2016
  write_json_file "$SESSION_FILE" --arg path "$path" --arg timestamp "$timestamp" \
    '.active = $path | .updated_at = $timestamp' "$SESSION_FILE" || {
      echo "Error: switch_session: failed to write: ${SESSION_FILE}" >&2
      return 1
  }

  echo "Switched active module: ${path}"
}

##
# @description Main entry point: parse arguments, then create the module or switch to an existing one
# @description An existing module directory without --force switches the active module (progress is kept)
# @description A missing directory, or --force, runs the create flow (re-initialization)
# @description Every exit of the script happens here; the other functions only return
# @arg $@ Command-line arguments
# @stdout Usage (on --help or argument errors), progress messages, and the session or switch summary
# @stderr Error message on failure
# @exitcode 0 Success, or usage shown by --help
# @exitcode 1 Missing jq/jaq, invalid arguments, a module creation/scope resolution failure, a session.json write failure,
#           or switch mode with --test-scope, no session.json, or no module entry
main()
       {
  local normalized scope

  validate_env || exit 1
  init_vars

  # Only the first argument can be the "create" subcommand; it is shifted off
  # before parsing, so a later "create" is an unexpected positional argument
  # shellcheck disable=SC2034 # SUBCOMMAND is informational; "create" is an alias for the default action
  if [[ ${1:-} == "create"   ]]; then
    SUBCOMMAND="create"
    shift
  else
    SUBCOMMAND=""
  fi

  # Options are declared on every call: args_init resets OPTIONS / OPTIONS_SET
  args_init
  args_positional module_path
  args_flag force --force
  args_value test_scope "" --test-scope

  parse_args "$@" || {
    echo "Error: ${ARGS_ERROR}" >&2
    show_usage
    exit 1
  }

  if [[ ${OPTIONS[SHOW_HELP]} == true   ]]; then
    show_usage
    exit 0
  fi

  if [[ -z ${OPTIONS[module_path]}   ]]; then
    echo "Error: <namespace>/<module> is required" >&2
    show_usage
    exit 1
  fi

  normalized=$(validate_and_normalize_with_fallback "${OPTIONS[module_path]}") || exit 1

  # An existing module directory without --force means "switch to it", not "create it"
  if [[ -d "${DECKRD_DOCS_DIR}/${normalized}" && ${OPTIONS[force]} != true   ]]; then
    if [[ -n ${OPTIONS[test_scope]}   ]]; then
      echo "Error: --test-scope cannot be changed by switching to an existing module: ${normalized}" >&2
      echo "  Edit module.md directly, or use --force to re-initialize." >&2
      exit 1
    fi
    switch_session "$normalized" || exit 1
    return 0
  fi

  create_module_dirs "$normalized" "${OPTIONS[force]}" || exit 1

  # The module's own module.md is the source of truth when no scope is given explicitly
  scope="${OPTIONS[test_scope]}"
  if [[ -z $scope   ]]; then
    scope=$(read_declared_scope "$normalized")
  fi

  scope=$(resolve_test_scope "$normalized" "$scope") || exit 1
  create_module_meta "$normalized" "$scope"
  update_session "$normalized" "$scope" || exit 1
}

# ============================================================================
# Main Execution
# ============================================================================

if [[ ${BASH_SOURCE[0]} == "$0"   ]]; then
  main "$@"
fi
