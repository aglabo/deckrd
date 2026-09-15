#!/usr/bin/env bash
# src: ./skills/deckrd/scripts/update.sh
# @(#) : deckrd rules assets 更新一覧・更新スクリプト
#
# Copyright (c) 2026- atsushifx <https://github.com/atsushifx>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT
#
# @file update.sh
# @brief List or update deployed rules assets that are outdated
# @description
#   Compares each asset source directory with its deployed directory and lists
#   deployed files that are older than and differ from the source.
#   Deployed files are not modified unless --update is given, in which case
#   each outdated file is overwritten with its source.
#
# @usage
#   update.sh [OPTIONS]
#
# @exitcode 0 Success
# @exitcode 1 Error during execution
#
# @stdout Outdated assets as `[label] name` (or `Updated: [label] name` with --update), one per line
# @stderr Usage and error messages
#
# @author atsushifx
# @version 0.1.0
# @license MIT

# shellcheck disable=SC1091

# don't use -u for checking error by Agent
set -o pipefail

# Load bootstrap (defines PROJECT_ROOT, DECKRD_LOCAL_DATA, DECKRD_LIB_DIR, etc.)
_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
. "${_SCRIPT_DIR}/libs/bootstrap.lib.sh"
unset _SCRIPT_DIR

. "${DECKRD_LIB_DIR}/validate-env.lib.sh"
. "${DECKRD_LIB_DIR}/utils.lib.sh"
. "${DECKRD_LIB_DIR}/asset-diff.lib.sh"
validate_env || exit 1

# ============================================================================
# Functions
# ============================================================================

##
# @description Show usage information
# @stderr Usage text
show_usage() {
  cat >&2 <<EOF
Usage: update.sh [OPTIONS]

List deployed rules assets that are older than and differ from the source.
Deployed files are not modified unless --update is given.

Options:
  --update      Overwrite outdated deployed files with their source
  -h, --help    Show this help message
EOF
}

##
# @description Parse command-line options
# @return 0 on success, 1 on error (no output; caller handles error message)
# @var PARSE_ARGS_ERROR set to error description on failure
# @var UPDATE_MODE set to true when --update is given, false otherwise
parse_args() {
  PARSE_ARGS_ERROR=""
  UPDATE_MODE=false

  while [[ $# -gt 0 ]]; do
    case "$1" in
    -h | --help)
      show_usage
      exit 0
      ;;
    --update)
      UPDATE_MODE=true
      shift
      ;;
    -*)
      PARSE_ARGS_ERROR="Unknown option: $1"
      return 1
      ;;
    *)
      PARSE_ARGS_ERROR="Unexpected argument: $1"
      return 1
      ;;
    esac
  done
}

##
# @description Print (and with UPDATE_MODE, overwrite) outdated deployed assets of every ASSET_TARGETS entry
# @stdout `[label] name` (`Updated: [label] name` in UPDATE_MODE) per outdated asset,
#   or `Rules are up to date.` when none
# @stderr Error message when a file cannot be updated (exits 1)
print_updated_assets() {
  local entry label src dest name count=0

  for entry in "${ASSET_TARGETS[@]}"; do
    IFS='|' read -r label src dest <<<"$entry"
    while IFS= read -r name; do
      if [[ "$UPDATE_MODE" == true ]]; then
        cp "$(asset_src_path "$src" "$name")" "${dest}/${name}" || {
          echo "Error: failed to update: ${dest}/${name}" >&2
          exit 1
        }
        printf 'Updated: [%s] %s\n' "$label" "$name"
      else
        printf '[%s] %s\n' "$label" "$name"
      fi
      count=$((count + 1))
    done < <(list_updated_assets "$src" "$dest")
  done

  if [[ "$count" -eq 0 ]]; then
    echo "Rules are up to date."
  fi
}

# ============================================================================
# Main Execution
# ============================================================================

main() {
  parse_args "$@" || {
    echo "Error: ${PARSE_ARGS_ERROR}" >&2
    show_usage
    exit 1
  }

  if [[ ! -f "${DECKRD_LOCAL_DATA}/session.json" ]]; then
    echo "Error: session not found: ${DECKRD_LOCAL_DATA}/session.json. Run init first." >&2
    exit 1
  fi

  init_asset_dirs
  print_updated_assets
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  main "$@"
fi
