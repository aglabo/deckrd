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

#
# @description Read the ID of a title and judge its kind. Letters and digits are
#   ASCII only. The trailing '-' of a table-driven ID is dropped
# @arg $1 string The title
# @set _ID      The ID, empty if the title has none (global)
# @set _ID_KIND group, case, or empty when the ID is neither (global)
# @exitcode 0 always
#
parse_title_id() {
  local LC_ALL=C
  _ID='' _ID_KIND=''
  [[ ! $1 =~ $_ID_PATTERN ]] || _ID="${BASH_REMATCH[2]%-}"
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
