#!/usr/bin/env bash
# src: ./skills/deckrd/skills/deckrd/scripts/__tests__/unit/update.unit.spec.sh
# @(#) : BDD unit tests for update.sh - parse_args function
#
# Copyright (c) 2026- atsushifx <https://github.com/atsushifx>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

# shellcheck disable=SC1090

_RUNTIME_BOOTSTRAP="${SHELLSPEC_PROJECT_ROOT}/skills/deckrd/skills/deckrd/scripts/libs/bootstrap.lib.sh"
. "$_RUNTIME_BOOTSTRAP" --no-finalize
unset _RUNTIME_BOOTSTRAP

Include ../spec_helper.sh

SCRIPT="${DECKRD_SCRIPTS_DIR}/update.sh"

# ============================================================================
# Internal helpers
# ============================================================================

##
# @description Source update.sh to load its functions (main is guarded)
_load_update_script() {
  . "$SCRIPT"
}

##
# @description Call parse_args with a fresh options array and copy its elements
#   into plain variables (ShellSpec cannot address associative-array elements)
# @arg $@ CLI arguments passed to parse_args
# @set OPT_UPDATE OPT_HELP OPT_ERROR Element values, or `<unset>` when missing
# @return The status of parse_args
_call_parse_args() {
  declare -A opts
  _parse_args_into opts "$@"
}

##
# @description Like _call_parse_args, but the options array already holds stale values
#   (help=true, error="stale") from an earlier call
# @arg $@ CLI arguments passed to parse_args
# @set OPT_UPDATE OPT_HELP OPT_ERROR Element values, or `<unset>` when missing
# @return The status of parse_args
_call_parse_args_prefilled() {
  # shellcheck disable=SC2034 # read by parse_args through its nameref
  declare -A opts=([help]=true [error]="stale")
  _parse_args_into opts "$@"
}

##
# @description Run parse_args on the named array and copy its elements into OPT_* variables
# @arg $1 Name of the associative array passed to parse_args
# @arg $@ CLI arguments passed to parse_args
# @return The status of parse_args
# shellcheck disable=SC2034 # OPT_* are read by ShellSpec `The variable`
_parse_args_into() {
  local -n _arr_ref="$1"
  local rc=0
  parse_args "$@" || rc=$?
  OPT_UPDATE="${_arr_ref[update]-<unset>}"
  OPT_HELP="${_arr_ref[help]-<unset>}"
  OPT_ERROR="${_arr_ref[error]-<unset>}"
  return "$rc"
}

# ============================================================================
# update.sh: parse_args
# ============================================================================

Describe "T-CLI-UPA: update.sh: parse_args"
  Before "_load_update_script"

  Describe "When: 正常系"
    It "[Normal] T-CLI-UPA-01: Should: return 0 and fill update=true, help=false, error=empty for --update"
      When call _call_parse_args --update
      The status should equal 0
      The variable OPT_UPDATE should equal "true"
      The variable OPT_HELP should equal "false"
      The variable OPT_ERROR should equal ""
    End

    It "[Normal] T-CLI-UPA-02: Should: return 0 and fill help=true without output for -h"
      When call _call_parse_args -h
      The status should equal 0
      The variable OPT_HELP should equal "true"
      The stdout should equal ""
      The stderr should equal ""
    End

    It "[Normal] T-CLI-UPA-03: Should: return 0 and fill help=true without output for --help"
      When call _call_parse_args --help
      The status should equal 0
      The variable OPT_HELP should equal "true"
      The stdout should equal ""
      The stderr should equal ""
    End

    It "[Normal] T-CLI-UPA-09: Should: leave UPDATE_MODE, HELP_REQUESTED and PARSE_ARGS_ERROR undefined"
      When call _call_parse_args --update
      The status should equal 0
      The variable UPDATE_MODE should be undefined
      The variable HELP_REQUESTED should be undefined
      The variable PARSE_ARGS_ERROR should be undefined
    End
  End

  Describe "When: 異常系"
    It "[Error] T-CLI-UPA-04: Should: return 1 and fill error with Unknown option for --unknown"
      When call _call_parse_args --unknown
      The status should equal 1
      The variable OPT_ERROR should equal "Unknown option: --unknown"
    End

    It "[Error] T-CLI-UPA-05: Should: return 1 and fill error with Unexpected argument for a positional argument"
      When call _call_parse_args foo
      The status should equal 1
      The variable OPT_ERROR should equal "Unexpected argument: foo"
    End
  End

  Describe "When: エッジケース"
    It "[Edge] T-CLI-UPA-06: Should: return 0 and fill the defaults when no CLI argument is given"
      When call _call_parse_args
      The status should equal 0
      The variable OPT_UPDATE should equal "false"
      The variable OPT_HELP should equal "false"
      The variable OPT_ERROR should equal ""
    End

    It "[Edge] T-CLI-UPA-07: Should: return 0 with help=true and ignore an invalid option after -h"
      When call _call_parse_args -h --unknown
      The status should equal 0
      The variable OPT_HELP should equal "true"
      The variable OPT_ERROR should equal ""
    End

    It "[Edge] T-CLI-UPA-08: Should: reset stale help and error values on every call"
      When call _call_parse_args_prefilled --update
      The status should equal 0
      The variable OPT_UPDATE should equal "true"
      The variable OPT_HELP should equal "false"
      The variable OPT_ERROR should equal ""
    End
  End
End
