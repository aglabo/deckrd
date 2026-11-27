#!/usr/bin/env bash
# skills/bdd-coder/skills/bdd-coder/scripts/check-ids/libs/declaration.lib.sh - Declaration reading
#
# Copyright (c) 2026- atsushifx <https://github.com/atsushifx>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT
#
# @version 0.1.0
# USAGE: source this file, do NOT execute directly.
#   . "$(dirname "${BASH_SOURCE[0]}")/declaration.lib.sh"

if [[ -n ${_LIB_DECLARATION_LOADED:-}   ]]; then
  return 0
fi
readonly _LIB_DECLARATION_LOADED=1

# The quote that opens a title
declare -g _QUOTE="(['\"\`])"

#
# @description Read a line as a declaration. The title ends at the next quote of the
#   kind that opens it. A case keyword with no title literal after it declares a
#   case with an empty title. The quote and the title are the last two captures,
#   as a pattern may have parentheses of its own before them
# @arg $1 string The line
# @arg $2 string The pattern of a group declaration
# @arg $3 string The pattern of a case declaration
# @arg $4 string The pattern of a line that starts with a case keyword
# @set _KIND  group or case (global)
# @set _TITLE The title (global)
# @exitcode 0 The line is a declaration
# @exitcode 1 The line is not a declaration
#
read_declaration() {
  local LC_ALL=C
  if [[ $1 =~ $2 ]]; then
    _KIND=group
  elif [[ $1 =~ $3 ]]; then
    _KIND=case
  elif [[ $1 =~ $4 ]]; then
    _KIND=case _TITLE=''
    return 0
  else
    return 1
  fi
  _TITLE="${BASH_REMATCH[-1]%%"${BASH_REMATCH[-2]}"*}"
}

#
# @description Count a group declaration and check its ID. Source report.lib.sh and
#   test-id.lib.sh before the call
# @arg $1 string The file and line number of an error
# @arg $2 string The title
# @set _ID, _ID_KIND The ID of the title, from parse_title_id (global)
# @set _COUNTS The counts of group IDs and errors (global)
# @set _GROUP_ID, _DECLARED The ID, from check_declared_id (global)
# @stderr The errors of check_declared_id
# @exitcode 0 always
#
count_group_declaration() {
  parse_title_id "$2"
  [[ $_ID_KIND == group ]] || return 0
  counts_add group
  check_declared_id group "$_ID" "$1"
}

#
# @description Count a case declaration and check its ID. Source report.lib.sh and
#   test-id.lib.sh before the call
# @arg $1 string The file and line number of an error
# @arg $2 string The title
# @set _ID, _ID_KIND The ID of the title, from parse_title_id (global)
# @set _COUNTS The counts of case IDs and errors (global)
# @set _DECLARED The ID, from check_declared_id (global)
# @stderr The errors of check_declared_id
# @exitcode 0 always
#
count_case_declaration() {
  parse_title_id "$2"
  if [[ $_ID_KIND == case ]]; then
    counts_add case
    check_declared_id case "$_ID" "$1"
  else
    report_error "$1: no case ID"
  fi
}

#
# @description Count the declaration of a line, if it is one, and check its ID. The
#   patterns are those of read_declaration. A line that is not a declaration is a
#   success too, so that a line handler can end with this call. Source report.lib.sh
#   and test-id.lib.sh before the call
# @arg $1 string The file and line number of an error
# @arg $2 string The line
# @arg $3 string The pattern of a group declaration
# @arg $4 string The pattern of a case declaration
# @arg $5 string The pattern of a line that starts with a case keyword
# @set _KIND, _TITLE The declaration, from read_declaration (global)
# @set _ID, _ID_KIND The ID of the title, from parse_title_id (global)
# @set _COUNTS The counts of group IDs, case IDs and errors (global)
# @set _GROUP_ID, _DECLARED The ID, from check_declared_id (global)
# @stderr The errors of count_group_declaration or count_case_declaration
# @exitcode 0 always
#
count_line_declaration() {
  read_declaration "${@:2}" || return 0
  "count_${_KIND}_declaration" "$1" "$_TITLE"
}
