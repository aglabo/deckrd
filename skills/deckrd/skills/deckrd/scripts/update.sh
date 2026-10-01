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
#   deployed files that are older than and differ from the source.
#   It also reports an existing `.local/deckrd/.gitignore` that lacks the
#   `!/workspaces/` rule as `[local-deckrd] .gitignore (workspaces rule)`, and a
#   workspaces README whose source exists but which is not deployed as
#   `[local-workspaces] README.md (missing)`.
#   Deployed files are not modified unless --update is given, in which case
#   each outdated file is overwritten with its source and the workspaces rule
#   block of the template is appended to the old gitignore.
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

# Label reported for an old local gitignore that lacks the workspaces rule
readonly WORKSPACES_RULE_LABEL='[local-deckrd] .gitignore (workspaces rule)'
# Label reported for a workspaces README that has a source but is not deployed
readonly WORKSPACES_README_LABEL='[local-workspaces] README.md (missing)'

# ============================================================================
# Functions
# ============================================================================

##
# @description Show usage information
# @stderr Usage text
show_usage() {
  cat >&2 <<EOF
Usage: update.sh [OPTIONS]

List deployed assets that are older than and differ from the source,
and an existing .local/deckrd/.gitignore that lacks the workspaces rule.
A missing .local/deckrd/workspaces/README.md is reported as well when its source exists.
Deployed files are not modified unless --update is given.

Options:
  --update      Overwrite outdated deployed files with their source,
                append the workspaces rule block to the old .gitignore,
                and copy the missing workspaces README from its source
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
  template="$(asset_src_path "$LOCAL_SRC_DIR" .gitignore)"
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
# @description Print (and in update mode, deploy) the workspaces README when its source exists
#   but it is not deployed ("not deployed" means nothing exists at the README path; any existing
#   entry, even a directory or a dangling symlink, counts as deployed and is left untouched)
#   A README missing from both sides is not reported and nothing is created. In list mode
#   neither the workspaces directory nor the README is created; in update mode the directory
#   is created if needed and the source README is copied into it.
# @arg $1 true to deploy the missing README, false to only list it
# @stdout WORKSPACES_README_LABEL (`Updated: ` prefixed in update mode) when the README is missing
# @stderr Error message when the directory cannot be created or the README cannot be copied (exits 1)
# @return 0 when the README was reported, 1 otherwise
print_missing_workspaces_readme() {
  local update_mode="$1" readme="${DECKRD_LOCAL_WORKSPACES}/README.md"
  [[ -f "${LOCAL_WORKSPACES_SRC_DIR}/README.md" && ! -e "$readme" && ! -L "$readme" ]] ||
    return 1
  if [[ "$update_mode" != true ]]; then
    printf '%s\n' "$WORKSPACES_README_LABEL"
    return 0
  fi
  { mkdir -p "$DECKRD_LOCAL_WORKSPACES" && cp "${LOCAL_WORKSPACES_SRC_DIR}/README.md" "$readme"; } || {
    echo "Error: failed to update: ${readme}" >&2
    exit 1
  }
  printf 'Updated: %s\n' "$WORKSPACES_README_LABEL"
}

##
# @description Print (and in update mode, overwrite) outdated deployed assets of every ASSET_TARGETS entry,
#   then the local gitignore that lacks the workspaces rule (appended to in update mode),
#   then the workspaces README that has a source but is not deployed.
#   The last two are delegated to print_workspaces_rule and print_missing_workspaces_readme.
# @arg $1 true to overwrite outdated assets, false to only list them
# @stdout `[label] name` (`Updated: [label] name` in update mode) per outdated asset
#   WORKSPACES_RULE_LABEL for the local gitignore, WORKSPACES_README_LABEL for a missing
#   workspaces README, or `Assets are up to date.` when none
# @stderr Error message when a file cannot be updated or the local gitignore cannot be read (exits 1)
print_updated_assets() {
  local update_mode="$1"
  local entry label src dest name count=0

  for entry in "${ASSET_TARGETS[@]}"; do
    IFS='|' read -r label src dest <<<"$entry"
    while IFS= read -r name; do
      if [[ "$update_mode" == true ]]; then
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

  if print_workspaces_rule "$update_mode"; then
    count=$((count + 1))
  fi

  if print_missing_workspaces_readme "$update_mode"; then
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
