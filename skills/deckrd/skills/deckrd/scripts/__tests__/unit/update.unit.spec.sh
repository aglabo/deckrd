#!/usr/bin/env bash
# src: ./skills/deckrd/skills/deckrd/scripts/__tests__/unit/update.unit.spec.sh
# @(#) : BDD unit tests for update.sh - main() argument parsing (args.lib.sh)
#
# Copyright (c) 2026- atsushifx <https://github.com/atsushifx>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

# shellcheck disable=SC1090

_RUNTIME_BOOTSTRAP="${SHELLSPEC_PROJECT_ROOT}/skills/deckrd/skills/deckrd/scripts/libs/bootstrap.lib.sh"
. "$_RUNTIME_BOOTSTRAP" --no-finalize
unset _RUNTIME_BOOTSTRAP

Include "${SHELLSPEC_SPECFILE%/*}/../spec_helper.sh"

SCRIPT="${DECKRD_SCRIPTS_DIR}/update.sh"

# ============================================================================
# Internal helpers
# ============================================================================

##
# @description Point DECKRD_LOCAL_DATA at a fresh temp dir holding session.json,
#   source update.sh (main is guarded), and stub the steps after argument parsing
#   so `main` runs the real declarations and the library parse_args without
#   touching the deployed assets.
#   DECKRD_LOCAL_DATA is set before sourcing: update.sh finalizes the bootstrap
#   variables as readonly.
# @stdout (from main) `update_mode=<value>` handed to print_updated_assets
_load_update_script() {
  DECKRD_LOCAL_DATA="$(mktemp -d "${SHELLSPEC_TMPBASE}/update-unit.XXXXXX")"
  printf '{}\n' >"${DECKRD_LOCAL_DATA}/session.json"
  . "$SCRIPT"

  # shellcheck disable=SC2329
  init_asset_dirs() { :; }
  # shellcheck disable=SC2329
  print_updated_assets() { printf 'update_mode=%s\n' "$1"; }
}

##
# @description Run main twice in the current shell: first with --update (output
#   discarded), then with no arguments, so the second call shows whether the
#   parse state of the first call leaks into it.
# @stdout (from the second main) `update_mode=<value>`
_main_update_then_default() {
  main --update >/dev/null
  main
}

# ============================================================================
# update.sh: main argument parsing
# ============================================================================

Describe "T-CLI-UPA: update.sh: main argument parsing"
  Before "_load_update_script"

  Describe "When: 正常系"
    It "[Normal] T-CLI-UPA-10: Should: hand true to print_updated_assets for --update"
      When run main --update
      The status should equal 0
      The stdout should equal "update_mode=true"
      The stderr should equal ""
    End

    It "[Normal] T-CLI-UPA-11: Should: show usage and stop for --help"
      When run main --help
      The status should equal 0
      The stderr should include "Usage: update.sh"
      The stdout should not include "update_mode="
    End

    It "[Normal] T-CLI-UPA-12: Should: show usage and stop for -h"
      When run main -h
      The status should equal 0
      The stderr should include "Usage: update.sh"
      The stdout should not include "update_mode="
    End
  End

  Describe "When: 異常系"
    It "[Error] T-CLI-UPA-20: Should: report the unknown option with usage and exit 1"
      When run main --unknown
      The status should equal 1
      The line 1 of stderr should equal "Error: Unknown option: --unknown"
      The stderr should include "Usage: update.sh"
      The stdout should be blank
    End

    It "[Error] T-CLI-UPA-21: Should: report the unexpected positional argument with usage and exit 1"
      When run main foo
      The status should equal 1
      The line 1 of stderr should equal "Error: Unexpected argument: foo"
      The stderr should include "Usage: update.sh"
      The stdout should be blank
    End

    It "[Error] T-CLI-UPA-22: Should: reject a value given to the --update flag with usage and exit 1"
      When run main --update=yes
      The status should equal 1
      The line 1 of stderr should equal "Error: --update does not take a value"
      The stderr should include "Usage: update.sh"
      The stdout should be blank
    End
  End

  Describe "When: エッジケース"
    It "[Edge] T-CLI-UPA-30: Should: hand false to print_updated_assets when no arguments are given"
      When run main
      The status should equal 0
      The stdout should equal "update_mode=false"
      The stderr should equal ""
    End

    It "[Edge] T-CLI-UPA-31: Should: show usage and exit 0 when -h precedes an unknown option"
      When run main -h --unknown
      The status should equal 0
      The stderr should include "Usage: update.sh"
      The stderr should not include "Error:"
      The stdout should not include "update_mode="
    End

    It "[Edge] T-CLI-UPA-32: Should: report the unknown option and exit 1 when it precedes -h"
      When run main --unknown -h
      The status should equal 1
      The line 1 of stderr should equal "Error: Unknown option: --unknown"
      The stdout should be blank
    End

    It "[Edge] T-CLI-UPA-33: Should: hand true to print_updated_assets when --update is repeated"
      When run main --update --update
      The status should equal 0
      The stdout should equal "update_mode=true"
      The stderr should equal ""
    End
  End

  Describe "When: FN確認"
    It "[Normal] T-CLI-UPA-40: Should: use the args.lib.sh parse_args, not the old nameref parser"
      When call declare -f parse_args
      The status should equal 0
      The stdout should include "SHOW_HELP"
      The stdout should not include "_opts_ref"
    End

    It "[Normal] T-CLI-UPA-41: Should: declare options via args_flag, with no local opts array in main"
      When call declare -f main
      The status should equal 0
      The stdout should include "args_flag update --update"
      The stdout should not include "opts["
    End
  End

  Describe "When: 状態遷移"
    It "[Edge] T-CLI-UPA-50: Should: hand false to the second main after main --update in the same shell"
      When call _main_update_then_default
      The status should equal 0
      The stdout should equal "update_mode=false"
      The stderr should equal ""
    End

    Context "session.json is absent"
      _remove_session_json() { rm -f "${DECKRD_LOCAL_DATA}/session.json"; }
      Before "_remove_session_json"

      It "[Edge] T-CLI-UPA-51: Should: show usage and exit 0 on --help before the session check"
        When run main --help
        The status should equal 0
        The stderr should include "Usage:"
        The stderr should not include "session not found"
      End

      It "[Edge] T-CLI-UPA-52: Should: exit 1 with session not found on --update after a successful parse"
        When run main --update
        The status should equal 1
        The stderr should include "Error: session not found"
        The stdout should not include "update_mode="
      End
    End
  End
End
