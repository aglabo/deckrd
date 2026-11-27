#!/usr/bin/env bash
# src: ./skills/bdd-coder/skills/bdd-coder/scripts/check-test-abbrs.sh
# @(#) : test target abbreviation checker
#
# Copyright (c) 2026- atsushifx <https://github.com/atsushifx>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

set -euo pipefail

# The directory of this script, which holds the libraries
_SCRIPT_DIR="${BASH_SOURCE[0]%/*}"
[[ $_SCRIPT_DIR != "${BASH_SOURCE[0]}" ]] || _SCRIPT_DIR='.'

# shellcheck source=libs/module-decl.lib.sh disable=SC1091
. "${_SCRIPT_DIR}/libs/module-decl.lib.sh"

# A heading line of any level
_HEADING_LINE='^#+[[:blank:]]'
# A line that starts with a fence mark, captured
# shellcheck disable=SC2016
_FENCE_LINE='^[[:blank:]]*(```|~~~)'
# A line of inline code, which opens no block: another backquote follows the
# leading run of three or more
# shellcheck disable=SC2016
_INLINE_CODE_LINE='^[[:blank:]]*```+[^`]+`'
# The heading of the abbreviation table
_ABBR_HEADING='## テスト対象の略語'
# A table row whose first column is an abbreviation in backquotes
# shellcheck disable=SC2016
_ABBR_ROW='^\|[[:blank:]]*`([^`]+)`'

#
# @description Print the command usage
# @stdout Usage text
# @exitcode 0 always
#
usage() {
  echo 'Usage: check-test-abbrs.sh [-h|--help]'
}

#
# @description Print the root to scan: TEST_ID_CHECK_ROOT when set, otherwise the git
#   toplevel of the current directory, or the current directory itself outside git
#   (or without git). git is not called when TEST_ID_CHECK_ROOT is set. Any other git
#   failure, such as a repository that git rejects, is an error and not a reason to
#   scan the current directory. LC_ALL=C keeps the message of git untranslated, so
#   that "outside git" can be told apart. The caller must propagate the failure, as
#   set -e does not stop in every context
# @stdout The scan root
# @stderr The first line of the message of the failing git
# @exitcode 0 The scan root is printed
# @exitcode 1 git fails inside what may be a repository
#
scan_root() {
  if [[ -n ${TEST_ID_CHECK_ROOT:-} ]]; then
    echo "$TEST_ID_CHECK_ROOT"
    return 0
  fi
  if ! command -v git > /dev/null; then
    echo .
    return 0
  fi
  local root message
  if root="$(LC_ALL=C git rev-parse --show-toplevel 2> /dev/null)"; then
    echo "$root"
    return 0
  fi
  # A second run keeps the warnings of a successful git out of the root
  message="$(LC_ALL=C git rev-parse --show-toplevel 2>&1 > /dev/null)" || true
  if [[ $message == *'not a git repository'* ]]; then
    echo .
    return 0
  fi
  echo "Error: cannot find the git toplevel: ${message%%$'\n'*}" >&2
  return 1
}

#
# @description Follow the fenced code blocks, line by line. A block is opened by
#   three backquotes or tildes, indented or not, and closed by the same mark only.
#   A line of three or more backquotes with another backquote after them is inline
#   code and opens no block, though it closes an open backquote block
# @arg $1 string The next line
# @set fence The mark of the open block, empty outside a block (caller's)
# @exitcode 0 The line is a fence or inside a block
# @exitcode 1 The line is outside a block
#
in_fence() {
  [[ -n $fence || ! $1 =~ $_INLINE_CODE_LINE ]] || return 1
  if [[ $1 =~ $_FENCE_LINE ]]; then
    if [[ -z $fence ]]; then
      fence="${BASH_REMATCH[1]}"
    elif [[ $fence == "${BASH_REMATCH[1]}" ]]; then
      fence=''
    fi
    return 0
  fi
  [[ -n $fence ]]
}

#
# @description Record the abbreviations in the table of a declaration. The table
#   follows its heading and ends at the next heading, a line of `#`s followed by a
#   space or a tab. Spaces and tabs at the end of a heading are ignored.
#   Fenced code blocks (see in_fence) are not read. A block left open ends with the
#   declaration, which is an error. Lines may end in CRLF
# @arg $1 string The declaration
# @arg $@ string The lines of the declaration, from the second argument on
# @set holders    The declarations of each abbreviation, each of them once (caller's)
# @set duplicated The abbreviations that appear twice (caller's)
# @set failed     1 when the declaration ends inside a fenced code block (caller's)
# @stderr That the declaration ends inside a fenced code block
# @exitcode 0 always
#
record_table() {
  local line abbr heading='' fence=''
  for line in "${@:2}"; do
    line="${line%$'\r'}"
    ! in_fence "$line" || continue
    [[ ! $line =~ $_HEADING_LINE ]] || heading="${line%"${line##*[![:blank:]]}"}"
    [[ $heading == "$_ABBR_HEADING" && $line =~ $_ABBR_ROW ]] || continue
    abbr="${BASH_REMATCH[1]}"
    if [[ -z ${holders[$abbr]:-} ]]; then
      holders[$abbr]="$1"
      continue
    fi
    duplicated[$abbr]=1
    # The declarations are read one by one, so one already named is the last one
    [[ ", ${holders[$abbr]}" == *", $1" ]] || holders[$abbr]+=", $1"
  done
  [[ -z $fence ]] || {
    echo "Error: $1: unclosed code fence" >&2
    failed=1
  }
}

#
# @description Check that every abbreviation appears only once in the abbreviation
#   tables of the module declarations under MODULE_DOCS_SUBDIR (docs/.deckrd when
#   not set) of the current directory.
#   A declaration that cannot be read, or ends inside a fenced code block, does not
#   stop the check of the others.
#   Arrays that may be empty are not expanded bare, which bash 4.3 rejects under set -u
# @stdout The counts of abbreviations and declarations, when there is no error
# @stderr One line per unreadable declaration, per declaration that ends inside a
#   fenced code block, and per duplicate abbreviation, which names each of its
#   declarations once. Otherwise that the declarations cannot be listed, or that no
#   abbreviation is found
# @exitcode 0 No error
# @exitcode 1 The listing or a read failed, a declaration ends inside a fenced code
#   block, an abbreviation appears twice, or no abbreviation is found
#
check_abbrs() {
  local docs="${MODULE_DOCS_SUBDIR:-docs/.deckrd}"
  local list file abbr failed='' decls=0
  local -a lines
  local -A holders=() duplicated=()
  if ! list="$(module_decl_list "$docs")"; then
    echo "Error: cannot list the module declarations under ${docs}" >&2
    return 1
  fi
  while IFS= read -r file; do
    # An empty listing is one empty line in a here-string
    [[ -n $file ]] || continue
    decls=$((decls + 1))
    if ! mapfile -t lines < "$file"; then
      echo "Error: ${file}: cannot read" >&2
      failed=1
      continue
    fi
    record_table "$file" ${lines[@]+"${lines[@]}"}
  done <<< "$list"

  if ((${#duplicated[@]} > 0)); then
    for abbr in "${!duplicated[@]}"; do
      echo "Error: duplicate abbreviation ${abbr}: ${holders[$abbr]}" >&2
    done
    return 1
  fi
  [[ -z $failed ]] || return 1
  if [[ ${#holders[@]} -eq 0 ]]; then
    echo 'Error: no abbreviation found' >&2
    return 1
  fi
  echo "OK: ${#holders[@]} abbreviations, ${decls} declarations"
}

#
# @description Main entry point
# @arg $@ string The command line arguments
# @stdout The usage when -h or --help is given, otherwise the output of check_abbrs
# @stderr The rejected argument, or the errors of the check
# @exitcode 0 The check passed, or help was requested
# @exitcode 1 An argument is rejected, or the check has an error
#
main() {
  if [[ ${1-} == -h || ${1-} == --help ]]; then
    usage
    return 0
  fi
  if (($# > 0)); then
    echo "Error: Unexpected argument: $1" >&2
    return 1
  fi
  local root
  root="$(scan_root)" || return 1
  cd "$root"
  check_abbrs
}

if [[ ${BASH_SOURCE[0]} == "${0}" ]]; then
  main "$@"
fi
