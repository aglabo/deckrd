#!/usr/bin/env bash
# skills/bdd-coder/skills/bdd-coder/scripts/check-ids/libs/test-id.lib.sh - Test ID judgement and checks
#
# Copyright (c) 2026- atsushifx <https://github.com/atsushifx>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT
#
# @version 0.1.0
# USAGE: source this file, do NOT execute directly.
#   . "$(dirname "${BASH_SOURCE[0]}")/test-id.lib.sh"

if [[ -n ${_LIB_TEST_ID_LOADED:-}   ]]; then
  return 0
fi
readonly _LIB_TEST_ID_LOADED=1

# The first blank-separated word of a title that starts like T-<segment>-, up to a
# character other than a letter, a digit, or '-'
declare -g _ID_PATTERN='(^|[[:blank:]])(T-[A-Z0-9]+-[A-Za-z0-9-]*)'
# A case ID is an ID followed by -NN[-NN]. Any other ID is a group ID
declare -g _ID_FORM='^T(-[A-Z0-9]+){2,}$'
declare -g _CASE_SUFFIX='(-[0-9]{2}){1,2}$'
declare -g _CASE_FORM="${_ID_FORM%\$}${_CASE_SUFFIX}"
# A line that starts a for loop: for (, for await (, or await for (
declare -g _FOR_PATTERN='^([[:blank:]]*)(await[[:blank:]]+)?for([[:blank:]]+await)?[[:blank:]]*\('
# A URL: a scheme and '://', up to a blank or a quote
declare -g _URL_PATTERN=$'[A-Za-z][A-Za-z0-9+.-]*://[^[:blank:]\'"`]*'
# A line that ends with the opening brace of a block
declare -g _BLOCK_OPEN_PATTERN='\{[[:blank:]]*$'
# A line, after its indentation, that ends a for header and opens its block
declare -g _HEADER_END_PATTERN='[])}].*\{[[:blank:]]*$'
# The open for block: the indentation of its for line and '}', which starts the line
# that ends it. Empty outside a block
declare -g _IN_LOOP=''
# The for header that has not opened its block, in the form it takes in _IN_LOOP.
# Empty when no header is pending
declare -g _LOOP_PENDING=''

#
# @description Read the ID of a title and judge its kind. Letters and digits are
#   ASCII only. The trailing '-' of a table-driven ID is dropped from the ID and
#   recorded in _ID_TRAILING_HYPHEN. Only the ID read is judged, not the text after it
# @arg $1 string The title
# @set _ID      The ID, empty if the title has none (global)
# @set _ID_KIND group, case, or empty when the ID is neither (global)
# @set _ID_TRAILING_HYPHEN Non-empty if the ID as written ends with '-', empty
#   otherwise, including a title with no ID (global)
# @exitcode 0 always
#
parse_title_id() {
  local LC_ALL=C
  _ID='' _ID_KIND='' _ID_TRAILING_HYPHEN=''
  if [[ $1 =~ $_ID_PATTERN ]]; then
    _ID="${BASH_REMATCH[2]%-}"
    [[ ${BASH_REMATCH[2]} != *- ]] || _ID_TRAILING_HYPHEN=-
  fi
  [[ ! $_ID =~ $_ID_FORM ]] || _ID_KIND=group
  [[ ! $_ID =~ $_CASE_FORM ]] || _ID_KIND=case
}

#
# @description Forget the declared IDs. Call it before check_declared_id
# @set _DECLARED The declared IDs, emptied (global)
# @exitcode 0 always
#
declared_ids_init() {
  declare -gA _DECLARED=()
}

#
# @description Forget the group ID. Call it at the start of a file
# @set _GROUP_ID Empty (global)
# @exitcode 0 always
#
group_id_reset() {
  _GROUP_ID=''
}

#
# @description Check an ID against the declarations before it, and record it. A group
#   ID becomes the group of the cases after it. A case ID must be that ID and
#   -NN[-NN], so a case before the first group ID is outside the group too.
#   Errors go through report_error of report.lib.sh
# @arg $1 string group or case
# @arg $2 string The ID
# @arg $3 string The file and line number of an error
# @set _GROUP_ID The ID, when it is a group ID
# @set _DECLARED The ID, added
# @stderr An ID outside the group, then a duplicate ID
# @exitcode 0 always
#
check_declared_id() {
  local LC_ALL=C
  if [[ $1 == group ]]; then
    _GROUP_ID="$2"
  elif [[ ! $2 =~ ^"$_GROUP_ID"$_CASE_SUFFIX ]]; then
    report_error "$3: case ID outside the group: $2"
  fi
  [[ -z ${_DECLARED[$2]:-} ]] || report_error "$3: duplicate ID: $2"
  _DECLARED[$2]=1
}

#
# @description Put a line into _LOOP_LINE as track_loop_block reads it: without a
#   trailing CR, and without a line comment when its marker is given. The line is
#   cut from the first marker to its end, wherever the marker is, except a marker
#   in a URL. A URL is a scheme (a letter, then letters, digits, '+', '.', or '-')
#   and '://', up to a blank or a quote (', ", or `). The marker is compared as a
#   string, not as a pattern
# @arg $1 string The line
# @arg $2 string The line comment marker; no comment is dropped when it is empty
# @set _LOOP_LINE The line to judge (global)
# @exitcode 0 always
#
_read_loop_line() {
  local LC_ALL=C
  local rest="${1%$'\r'}" url
  _LOOP_LINE="$rest"
  [[ -n $2 ]] || return 0
  _LOOP_LINE=''
  while [[ $rest =~ $_URL_PATTERN ]]; do
    url="${BASH_REMATCH[0]}"
    [[ ${rest%%"$url"*} != *"$2"* ]] || break
    _LOOP_LINE+="${rest%%"$url"*}$url"
    rest="${rest#*"$url"}"
  done
  _LOOP_LINE+="${rest%%"$2"*}"
}

#
# @description Open the block of the pending for header, or keep it pending, at a
#   line that follows the for line
# @set _IN_LOOP The pending header when the line ends it (global)
# @set _LOOP_PENDING Empty unless the line is blank or deeper than the for line (global)
# @exitcode 0 always
#
_read_pending_line() {
  local indent="${_LOOP_PENDING%\}}"
  [[ $_LOOP_LINE != "$indent"[[:blank:]]* && -n ${_LOOP_LINE//[[:blank:]]/} ]] || return 0
  [[ ! $_LOOP_LINE =~ ^"$indent"$_HEADER_END_PATTERN ]] || _IN_LOOP="$_LOOP_PENDING"
  _LOOP_PENDING=''
}

#
# @description Read the next line of a file and track whether it is inside a for
#   block. Call it with each line in order. A trailing CR is ignored. When the line
#   comment marker is given, the text from the first marker outside a URL to the end
#   of the line is ignored too (see _read_loop_line), so a comment-only line counts
#   as a blank line.
#   A for line starts with for (, for await (, or await for (, after optional blanks.
#   Indentation is compared as written, spaces and tabs. Outside a block:
#   - A for line that ends with '{' opens a block. Any other for line leaves its
#     header pending, also when another header is pending
#   - While a header is pending, blank lines and lines indented deeper than the for
#     line are skipped. A line at the indentation of the for line that starts with
#     ')', ']', or '}' and ends with '{' opens the block. Any other line drops the
#     header
#   Inside a block, only a line that starts with '}' at the indentation of the for
#   line and does not end with '{' ends it. Other lines are ignored, so inner for
#   loops are not recorded.
#   Known limits:
#   - A header closed on a deeper line, as '    i++) {', opens no block
#   - An opening brace on its own line (Allman style) opens no block
#   - A for that does not start its line, as 'x(); for (;;) {', is not a for line
#   - Block comments are not recognized
#   - Strings that span lines are not recognized, so their lines are read as code
#   - A marker in a string that is not a URL, as 'a // b', cuts the line there
# @arg $1 string The line
# @arg $2 string Optional line comment marker of the language, e.g. '//'
# @set _IN_LOOP Non-empty inside a for block, empty otherwise (global)
# @set _LOOP_PENDING The for header that has not opened its block (global)
# @set _LOOP_LINE The line as judged (global)
# @exitcode 0 always
#
track_loop_block() {
  _read_loop_line "$1" "${2:-}"
  if [[ -n $_IN_LOOP ]]; then
    [[ $_LOOP_LINE != "$_IN_LOOP"* || $_LOOP_LINE =~ $_BLOCK_OPEN_PATTERN ]] || _IN_LOOP=''
  elif [[ $_LOOP_LINE =~ $_FOR_PATTERN ]]; then
    _LOOP_PENDING="${BASH_REMATCH[1]}}"
    [[ ! $_LOOP_LINE =~ $_BLOCK_OPEN_PATTERN ]] || _IN_LOOP="$_LOOP_PENDING" _LOOP_PENDING=''
  elif [[ -n $_LOOP_PENDING ]]; then
    _read_pending_line
  fi
}

#
# @description Forget the loop state of track_loop_block: the open for block and
#   the pending for header. Call it at the start of a file. _LOOP_LINE is not state,
#   as every call of track_loop_block overwrites it
# @set _IN_LOOP Empty (global)
# @set _LOOP_PENDING Empty (global)
# @exitcode 0 always
#
loop_block_reset() {
  _IN_LOOP='' _LOOP_PENDING=''
}
