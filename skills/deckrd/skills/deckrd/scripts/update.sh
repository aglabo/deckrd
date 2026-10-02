#!/usr/bin/env bash
# src: ./skills/deckrd/scripts/update.sh
# @(#) : deckrd assets 更新一覧・更新スクリプト
#
# Copyright (c) 2026- atsushifx <https://github.com/atsushifx>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT
#
# @file update.sh
# @brief List or update deployed assets that are outdated
# @description
#   Compares each asset source directory with its deployed directory and lists
#   the assets that list_asset_files reports: files missing from the deployed
#   directory, and deployed files that are older than and differ from the source,
#   including files in subdirectories (e.g. rules/, workspaces/README.md).
#   An existing deployed `.gitignore` is never listed or overwritten.
#   Each is printed as `[label] dst_rel` (destination relative path,
#   `.org` dropped).
#   It also reports an existing `.local/deckrd/.gitignore` that lacks the
#   `!/workspaces/` rule as `[local-deckrd] .gitignore (workspaces rule)`.
#   Deployed files are not modified unless --update is given, in which case
#   each listed file is copied from its source and the workspaces rule
#   block of the template is appended to the old gitignore.
#   With --update, a deployed file that has the same content as its source
#   but is older also gets the source's mtime (copy_assets ->
#   sync_asset_mtimes); it is not listed and its content is not changed.
#
# @usage
#   update.sh [OPTIONS]
#
# @exitcode 0 Success
# @exitcode 1 Error during execution
#
# @stdout Assets as `[label] dst_rel` (or `Updated: [label] dst_rel` with --update), one per line
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
. "${DECKRD_LIB_DIR}/asset-copy.lib.sh"
validate_env || exit 1

# Label reported for an old local gitignore that lacks the workspaces rule
readonly WORKSPACES_RULE_LABEL='[local-deckrd] .gitignore (workspaces rule)'

# ============================================================================
# Functions
# ============================================================================

##
# @description Show usage information
# @stderr Usage text
show_usage() {
  cat >&2 <<EOF
Usage: update.sh [OPTIONS]

List asset files that are missing from each deployed directory, or are
older than and differ from their source, including files in subdirectories
such as rules/ and workspaces/README.md. An existing deployed .gitignore is
never overwritten; an existing .local/deckrd/.gitignore that lacks the
workspaces rule is listed instead.
Deployed files are not modified unless --update is given.

Options:
  --update      Copy each listed file from its source, append the
                workspaces rule block to the old .gitignore, and set the
                mtime of each deployed file that has the same content as
                its source but is older to the source's mtime
  -h, --help    Show this help message
EOF
}

##
# @description Parse command-line options into a caller-provided associative array
#   The array is reset on every call. Help returns immediately without output,
#   so arguments after it are not checked; the caller shows usage.
# @arg $1 Name of an associative array to fill (nameref): keys update, help, error
# @arg $@ CLI arguments
# @return 0 on success (including help), 1 on invalid argument (error key set)
parse_args() {
  local -n _opts_ref="$1"
  shift
  _opts_ref=(['update']=false ['help']=false ['error']="")

  while [[ $# -gt 0 ]]; do
    case "$1" in
    -h | --help)
      _opts_ref['help']=true
      return 0
      ;;
    --update)
      _opts_ref['update']=true
      shift
      ;;
    -*)
      _opts_ref['error']="Unknown option: $1"
      return 1
      ;;
    *)
      _opts_ref['error']="Unexpected argument: $1"
      return 1
      ;;
    esac
  done
}

##
# @description Append the workspaces rule block of the local gitignore template to a gitignore
#   The template is read here and its content is passed to workspaces_rule_block. The block is
#   obtained before anything is written, so a missing or unreadable template, or one without
#   the block, leaves the file untouched (all three report the same "block not found" error).
#   The file is rewritten in one go from the given content with CRs removed (LF line endings),
#   the original lines followed by exactly one blank line and the block, so a CRLF file does
#   not end up mixed. The gitignore itself is not read again.
# @arg $1 Path to the gitignore to update
# @arg $2 Current content of the gitignore, as read by the caller
# @stderr Error message when the template block cannot be obtained or the file cannot be
#   written (exits 1)
apply_workspaces_rule() {
  local gitignore="$1" content="${2//$'\r'/}" template template_content block
  template="${LOCAL_SRC_DIR}/.gitignore.org"
  if ! template_content="$(cat -- "$template" 2>/dev/null)" ||
    ! block="$(workspaces_rule_block "$template_content")"; then
    echo "Error: workspaces rule block not found: ${template}" >&2
    exit 1
  fi
  # The caller's $(...) dropped trailing newlines, so the printf below always leaves one blank line
  printf '%s\n\n%s\n' "$content" "$block" >"$gitignore" || {
    echo "Error: failed to update: ${gitignore}" >&2
    exit 1
  }
}

##
# @description Print (and in update mode, append to) the local gitignore when it lacks the
#   workspaces rule
#   The local gitignore is not a migration target when it does not exist; otherwise it is read
#   once and its content is checked with workspaces_rule_missing and passed to apply_workspaces_rule.
# @arg $1 true to append the workspaces rule, false to only list it
# @stdout WORKSPACES_RULE_LABEL (`Updated: ` prefixed in update mode) when the rule is missing
# @stderr Error message when the local gitignore cannot be read or updated (exits 1)
# @return 0 when the local gitignore was reported, 1 otherwise
print_workspaces_rule() {
  local update_mode="$1" gitignore="${DECKRD_LOCAL_DATA}/.gitignore" content
  [[ -f "$gitignore" ]] ||
    return 1
  content="$(cat -- "$gitignore" 2>/dev/null)" || {
    echo "Error: cannot read: ${gitignore}" >&2
    exit 1
  }
  workspaces_rule_missing "$content" ||
    return 1
  if [[ "$update_mode" != true ]]; then
    printf '%s\n' "$WORKSPACES_RULE_LABEL"
    return 0
  fi
  apply_workspaces_rule "$gitignore" "$content"
  printf 'Updated: %s\n' "$WORKSPACES_RULE_LABEL"
}

##
# @description Print the destination relative paths of the assets of one ASSET_TARGETS entry
#   List mode maps each path from list_asset_files to its destination by dropping `.org`.
#   Update mode copies with copy_assets, which already prints destination relative paths.
#   The caller captures the output, so a failed copy leaves no partial line on stdout.
# @arg $1 true to copy the assets, false to only list them
# @arg $2 Source directory
# @arg $3 Destination directory
# @stdout Destination relative path per asset, one per line
# @stderr `Error:` line from copy_assets when a file cannot be copied
# @return 0 on success, 1 when a copy fails
target_asset_paths() {
  local update_mode="$1" src="$2" dest="$3" src_rel
  if [[ "$update_mode" == true ]]; then
    copy_assets "$src" "$dest" "${ASSET_KEEP_PATTERNS[@]}"
    return
  fi
  while IFS= read -r src_rel; do
    strip_suffix "$src_rel" .org
  done < <(list_asset_files "$src" "$dest" "${ASSET_KEEP_PATTERNS[@]}")
}

##
# @description Print (and in update mode, copy) the assets of one ASSET_TARGETS entry that
#   list_asset_files reports (missing from or outdated in the destination)
#   In update mode the lines are printed only after every copy of the entry has succeeded.
# @arg $1 true to copy the listed assets, false to only list them
# @arg $2 ASSET_TARGETS entry (`<label>|<src_dir>|<dest_dir>`)
# @arg $3 Name of an integer variable to add the number of listed assets to (nameref)
# @stdout `[label] dst_rel` (`Updated: [label] dst_rel` in update mode) per listed asset
# @stderr Error message from copy_assets when a file cannot be copied (exits 1)
print_target_assets() {
  local update_mode="$1" label src dest paths dst_rel prefix=''
  local -n _count_ref="$3"
  IFS='|' read -r label src dest <<<"$2"
  [[ "$update_mode" == true ]] && prefix='Updated: '

  paths="$(target_asset_paths "$update_mode" "$src" "$dest")" ||
    exit 1
  while IFS= read -r dst_rel; do
    # an empty list yields one empty line
    [[ -n "$dst_rel" ]] || continue
    printf '%s[%s] %s\n' "$prefix" "$label" "$dst_rel"
    _count_ref=$((_count_ref + 1))
  done <<<"$paths"
}

##
# @description Print (and in update mode, copy) the assets of every ASSET_TARGETS entry,
#   then the local gitignore that lacks the workspaces rule (appended to in update mode).
#   The two parts are delegated to print_target_assets and print_workspaces_rule.
# @arg $1 true to copy the listed assets, false to only list them
# @stdout `[label] dst_rel` (`Updated: [label] dst_rel` in update mode) per listed asset,
#   WORKSPACES_RULE_LABEL for the local gitignore, or `Assets are up to date.` when none
# @stderr Error message when a file cannot be copied or the local gitignore cannot be read (exits 1)
print_updated_assets() {
  local update_mode="$1" entry count=0

  for entry in "${ASSET_TARGETS[@]}"; do
    print_target_assets "$update_mode" "$entry" count
  done

  if print_workspaces_rule "$update_mode"; then
    count=$((count + 1))
  fi

  if [[ "$count" -eq 0 ]]; then
    echo "Assets are up to date."
  fi
}

# ============================================================================
# Main Execution
# ============================================================================

main() {
  local -A opts
  parse_args opts "$@" || {
    echo "Error: ${opts[error]}" >&2
    show_usage
    exit 1
  }

  if [[ "${opts[help]}" == true ]]; then
    show_usage
    exit 0
  fi

  if [[ ! -f "${DECKRD_LOCAL_DATA}/session.json" ]]; then
    echo "Error: session not found: ${DECKRD_LOCAL_DATA}/session.json. Run init first." >&2
    exit 1
  fi

  init_asset_dirs
  print_updated_assets "${opts[update]}"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  main "$@"
fi
