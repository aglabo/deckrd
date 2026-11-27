#!/usr/bin/env bash
# skills/bdd-coder/skills/bdd-coder/scripts/check-ids/libs/report.lib.sh - Check counts and reports
#
# Copyright (c) 2026- atsushifx <https://github.com/atsushifx>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT
#
# @version 0.1.0
# USAGE: source this file, do NOT execute directly.
#   . "$(dirname "${BASH_SOURCE[0]}")/report.lib.sh"

if [[ -n ${_LIB_REPORT_LOADED:-}   ]]; then
  return 0
fi
readonly _LIB_REPORT_LOADED=1

#
# @description Set every count to 0. Call it before the other functions
# @set _COUNTS The counts of files, group IDs, case IDs and errors (global)
# @exitcode 0 always
#
counts_init() {
  declare -gA _COUNTS=([files]=0 [group]=0 [case]=0 [errors]=0)
}

#
# @description Add one to a count
# @arg $1 string files, group, case or errors
# @set _COUNTS The count of the kind
# @exitcode 0 always
#
counts_add() {
  _COUNTS[$1]=$((_COUNTS[$1] + 1))
}

#
# @description Print the counts of files, group IDs and case IDs, unless an error is
#   counted
# @stdout The counts, when there is no error
# @exitcode 0 No error
# @exitcode 1 An error is counted
#
counts_summary() {
  [[ ${_COUNTS[errors]} -eq 0 ]] || return 1
  echo "OK: ${_COUNTS[files]} files, ${_COUNTS[group]} group IDs, ${_COUNTS[case]} case IDs"
}

#
# @description Print an error and count it
# @arg $1 string The subject and the reason of the error
# @set _COUNTS The count of errors
# @stderr The error
# @exitcode 0 always
#
report_error() {
  echo "Error: $1" >&2
  counts_add errors
}
