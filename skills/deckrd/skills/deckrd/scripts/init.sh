#!/usr/bin/env bash
# src: ./skills/deckrd/scripts/init.sh
# @(#) : deckrd project initialization script
#
# Copyright (c) 2025 atsushifx <https://github.com/atsushifx>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT
#
# @file init.sh
# @brief Bootstrap and initialize DECKRD project structure
# @description
#   1. Bootstrap: create .local/deckrd/temp/ and .local/deckrd/workspaces/, then copy
#      recursively claude-rules to .claude/rules/claude-rules/, the rules index to
#      .claude/rules/deckrd-rules/, docs templates (incl. rules/) to docs/.deckrd/, and
#      local-deckrd (incl. workspaces/README.md) to .local/deckrd/. Only missing
#      files are copied; existing files (outdated ones and user edits included) are never
#      overwritten. With --force, every asset is overwritten, .gitignore files and user edits
#      included (session.json is kept)
#   2. Create docs/.deckrd/ base directory structure
#   3. Write .local/deckrd/.project.json with project settings
#   4. Initialize .local/deckrd/session.json
#
# @usage
#   init.sh <project> <project-type> [OPTIONS]
#
# @example
#   init.sh myapp webapp
#   init.sh myapp webapp --language go
#   init.sh myapp lib --language typescript --ai-model claude-sonnet-4-5
#   init.sh myapp webapp --force
#
# @exitcode 0 Success
# @exitcode 1 Error during execution
#
# @stdout Machine-readable output only (currently empty)
# @stderr User-visible logs, progress messages, usage, and error messages
#
# @author atsushifx
# @version 0.1.0
# @license MIT

# shellcheck disable=SC1091

# don't use -u for checking error by Agent
set -o pipefail

# Load bootstrap (defines SYMBOL, PROJECT_ROOT, DECKRD_LOCAL_DATA, DECKRD_LIB_DIR, etc.)
_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
. "${_SCRIPT_DIR}/libs/bootstrap.lib.sh"
unset _SCRIPT_DIR

. "${DECKRD_LIB_DIR}/validate-env.lib.sh"
. "${DECKRD_LIB_DIR}/utils.lib.sh"
. "${DECKRD_LIB_DIR}/asset-diff.lib.sh"
. "${DECKRD_LIB_DIR}/asset-copy.lib.sh"
validate_env || exit 1

. "${DECKRD_LIB_DIR}/ai-runner.lib.sh"

# ============================================================================
# Functions
# ============================================================================

##
# @description Initialize script configuration variables
# @description Asset source/destination path variables and ASSET_TARGETS come from
#   init_asset_dirs (libs/asset-diff.lib.sh), the single asset target list shared with update
# @description Path variables use ${VAR:-default} to allow external override (mock)
# @description OPTIONS is declared here and filled by parse_args
init_vars() {
  init_asset_dirs
  PROJECT_FILE="${PROJECT_FILE:-${DECKRD_LOCAL_DATA}/.project.json}"
  SESSION_FILE="${SESSION_FILE:-${DECKRD_LOCAL_DATA}/session.json}"
  BASE_SUBDIRS=("notes" "temp")
  SUPPORTED_LANGUAGES=(typescript go python rust shell)
  declare -gA OPTIONS=()
}

##
# @description Show usage information
# @stderr Usage text
show_usage() {
  cat >&2 <<EOF
Usage: init.sh <project> <project-type> [OPTIONS]

Bootstrap and initialize a DECKRD project.

Arguments:
  <project>       Project name (e.g. myapp)
  <project-type>  Project type (e.g. webapp, lib, cli, api)

Options:
  --language <lang>, --lang   Programming language (default: typescript)
                              Supported: ${SUPPORTED_LANGUAGES[*]}
                              Alias: bash → shell
  --ai-model <model>          AI model (default: sonnet)
                              Supported: gpt-*, o1-*, claude-*, haiku, sonnet, opus
  --force                     Overwrite all assets, including .gitignore files and user-edited files
  -h, --help                  Show this help message

Project file:
  .local/deckrd/project.json

Example:
  init.sh myapp webapp
  init.sh myapp lib --language go
  init.sh voift webapp --language typescript --ai-model claude-sonnet-4-5
  init.sh myapp webapp --force
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
# @return 0 on success or help request, 1 on error (no output; caller handles usage and error message)
# @var PARSE_ARGS_ERROR set to error description on failure
# @var OPTIONS reset to defaults, then filled from args (keys: project, project_type, language, ai_model, help, force)
parse_args() {
  local positional=()
  PARSE_ARGS_ERROR=""
  OPTIONS=([project]="" [project_type]="" [language]=typescript [ai_model]=sonnet [help]=false [force]=false)

  while [[ $# -gt 0 ]]; do
    case "$1" in
    -h | --help)
      OPTIONS[help]=true
      return 0
      ;;
    --language | --lang)
      if [[ -z "${2:-}" ]]; then
        PARSE_ARGS_ERROR="${1} requires a value"
        return 1
      fi
      OPTIONS[language]="$2"
      [[ "${OPTIONS[language]}" == "bash" ]] && OPTIONS[language]="shell"
      shift 2
      ;;
    --language=* | --lang=*)
      OPTIONS[language]="${1#*=}"
      [[ "${OPTIONS[language]}" == "bash" ]] && OPTIONS[language]="shell"
      shift
      ;;
    --ai-model)
      if [[ -z "${2:-}" ]]; then
        PARSE_ARGS_ERROR="--ai-model requires a value"
        return 1
      fi
      OPTIONS[ai_model]="$2"
      shift 2
      ;;
    --ai-model=*)
      OPTIONS[ai_model]="${1#*=}"
      shift
      ;;
    --force)
      OPTIONS[force]=true
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

  OPTIONS[project]="${positional[0]:-}"
  OPTIONS[project_type]="${positional[1]:-}"
}

##
# @description Validate required positional arguments
# @return 0 on success, 1 on error (no output; caller handles error message)
# @var VALIDATE_ARGS_ERROR set to error description on failure
validate_args() {
  VALIDATE_ARGS_ERROR=""

  if [[ -z "${OPTIONS[project]}" ]]; then
    VALIDATE_ARGS_ERROR="<project> is required"
    return 1
  fi
  if [[ -z "${OPTIONS[project_type]}" ]]; then
    VALIDATE_ARGS_ERROR="<project-type> is required"
    return 1
  fi
  if [[ ! "${OPTIONS[project]}" =~ ^${SYMBOL}$ ]]; then
    VALIDATE_ARGS_ERROR="project name '${OPTIONS[project]}' contains invalid characters. Allowed: a-z, hyphen (-), underscore (_)"
    return 1
  fi
  if [[ ! "${OPTIONS[project_type]}" =~ ^${SYMBOL}$ ]]; then
    VALIDATE_ARGS_ERROR="project type '${OPTIONS[project_type]}' contains invalid characters. Allowed: a-z, hyphen (-), underscore (_)"
    return 1
  fi
}

##
# @description Create directories (all missing levels) in order, without copying anything
# @description Stops at the first directory that cannot be created
# @arg $@ string Directories to create
# @exitcode 0 Every directory exists or was created
# @exitcode 1 A directory could not be created
# @stderr Error message naming the directory on failure
make_directories() {
  local dir
  for dir in "$@"; do
    mkdir -p "$dir" || {
      echo "Error: failed to create directory: ${dir}" >&2
      return 1
    }
  done
}

##
# @description Install one asset target with copy_assets and report each copied file
# @description Copies only the assets under src that are missing from dest (copy_assets
#   --missing-only); an existing file is never overwritten and is not reported, even when it is
#   older than and differs from its source
# @description When OPTIONS[force] is true, copy_assets --force overwrites every file under src
#   regardless of ASSET_KEEP_PATTERNS and the dest state, and each one is reported as copied
# @description A missing src is not an error: dest is still created, the source is reported, and
#   no done line is printed
# @arg $1 string Label shown in the progress messages (e.g. `docs`)
# @arg $2 string Source dir
# @arg $3 string Destination dir
# @exitcode 0 Assets installed, or src does not exist
# @exitcode 1 dest could not be created or an asset could not be copied
# @stderr `  [init/<label>] copied: <rel>` per copied file (kept files are not reported), then
#   `  [init/<label>] done: N copied`
# @stderr Error message naming the directory or file that failed
install_assets() {
  local label="$1" src="$2" dest="$3"
  local out rel copied=0
  local -a mode_opt=(--missing-only)
  if [[ ! -d "$src" ]]; then
    make_directories "$dest" || return 1
    echo "  [init/${label}] source not found, skipping: ${src}" >&2
    return 0
  fi
  [[ "${OPTIONS[force]:-false}" == true ]] && mode_opt=(--force)
  out=$(copy_assets "${mode_opt[@]}" "$src" "$dest" "${ASSET_KEEP_PATTERNS[@]}") || return 1
  while IFS= read -r rel; do
    [[ -n "$rel" ]] || continue
    echo "  [init/${label}] copied: ${rel}" >&2
    copied=$((copied + 1))
  done <<<"$out"
  printf '  [init/%s] done: %d copied\n' "$label" "$copied" >&2
}

##
# @description Initialize all project directories and install assets
# @description Order: DECKRD_LOCAL_TEMP and DECKRD_LOCAL_WORKSPACES (directories only), then each
#   ASSET_TARGETS entry (`<label>|<src>|<dest>`, set by init_asset_dirs) copied recursively with
#   install_assets (copy_assets + ASSET_KEEP_PATTERNS), then the BASE_SUBDIRS under DECKRD_DOCS_DIR
# @description On re-run, only missing files are copied; an existing file is never overwritten,
#   even when it is older than and differs from its source (refresh it with `update --update`);
#   with --force (OPTIONS[force]) every asset is overwritten, `.gitignore` and user edits included
# @description workspaces/README.md always goes to ${DECKRD_LOCAL_DATA}/workspaces/ through the
#   local-deckrd copy; an overridden DECKRD_LOCAL_WORKSPACES is only created, never filled
# @description Stops at the first failure without printing "Init complete."
# @exitcode 0 All directories initialized
# @exitcode 1 A directory could not be created or an asset could not be copied
# @stderr Progress messages
# @stderr Error message naming the directory or file that failed
init_directories() {
  local entry label src dest
  echo "Init: creating directories and installing assets..." >&2
  make_directories "$DECKRD_LOCAL_TEMP" "$DECKRD_LOCAL_WORKSPACES" || return 1
  for entry in "${ASSET_TARGETS[@]}"; do
    IFS='|' read -r label src dest <<<"$entry"
    install_assets "$label" "$src" "$dest" || return 1
  done
  make_directories "${BASE_SUBDIRS[@]/#/${DECKRD_DOCS_DIR}/}" || return 1
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
    created_at=$(jq_read -r '.created_at // empty' "$PROJECT_FILE" 2>/dev/null || echo "$timestamp")
  else
    created_at="$timestamp"
  fi

  # shellcheck disable=SC2016
  jq_read -n \
    --arg project "${OPTIONS[project]}" \
    --arg project_type "${OPTIONS[project_type]}" \
    --arg language "${OPTIONS[language]}" \
    --arg ai_model "${OPTIONS[ai_model]}" \
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
  echo "  project:      ${OPTIONS[project]}" >&2
  echo "  project_type: ${OPTIONS[project_type]}" >&2
  echo "  language:     ${OPTIONS[language]}" >&2
  echo "  ai_model:     ${OPTIONS[ai_model]}" >&2
}

##
# @description Initialize session.json
# @stderr Progress messages
init_session() {
  local timestamp
  timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

  if [[ -f "$SESSION_FILE" ]]; then
    # Already exists: preserve as-is
    echo "" >&2
    echo "Session preserved: ${SESSION_FILE}" >&2
    return 0
  fi

  # shellcheck disable=SC2016
  jq_read -n \
    --arg lang "${OPTIONS[language]}" \
    --arg ai_model "${OPTIONS[ai_model]}" \
    --arg timestamp "$timestamp" \
    '{
      active:     null,
      lang:       $lang,
      ai_model:   $ai_model,
      modules:    {},
      created_at: $timestamp,
      updated_at: $timestamp
    }' >"$SESSION_FILE"

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

  if [[ "${OPTIONS[help]}" == true ]]; then
    show_usage
    exit 0
  fi

  validate_args || {
    echo "Error: ${VALIDATE_ARGS_ERROR}" >&2
    if [[ "$VALIDATE_ARGS_ERROR" == *"is required" ]]; then
      show_usage
    fi
    exit 1
  }

  validate_language "${OPTIONS[language]}" || {
    echo "Error: Unsupported language: ${OPTIONS[language]}. Supported: ${SUPPORTED_LANGUAGES[*]}" >&2
    exit 1
  }

  _ai_model_errmsg=$(validate_ai_model "${OPTIONS[ai_model]}") || {
    echo "$_ai_model_errmsg" >&2
    exit 1
  }
  unset _ai_model_errmsg

  init_directories || exit 1
  write_project
  init_session
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  main "$@"
fi
