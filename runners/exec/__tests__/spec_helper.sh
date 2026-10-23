#!/usr/bin/env bash
# runners/exec/__tests__/spec_helper.sh
# @(#) : shared test helper for runners/exec tests
#
# Copyright (c) 2026- atsushifx <https://github.com/atsushifx>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

# shellcheck shell=bash
# shellcheck disable=SC1091

# Load the runners helpers (common helpers + shared spec fixture)
. "${SHELLSPEC_PROJECT_ROOT}/runners/__tests__/spec_helper.sh"

#
# @description Install a ShellSpec stub that prints its argv as `[arg]...` instead
#              of running specs. Removed by teardown_shellspec_stub()
# @sideeffect Sets _STUB_DIR and _SHELLSPEC_STUB
#
setup_shellspec_stub() {
  make_temp_dir _STUB_DIR || return 1
  _SHELLSPEC_STUB="${_STUB_DIR}/shellspec-stub"
  # The stub expands its own argv when launched, so keep it unexpanded here
  # shellcheck disable=SC2016
  write_bash_stub "$_SHELLSPEC_STUB" 'printf "[%s]" "$@"'
}

#
# @description Remove the stub installed by setup_shellspec_stub() (or any helper
#              that sets _STUB_DIR and _SHELLSPEC_STUB)
# @sideeffect Unsets _STUB_DIR and _SHELLSPEC_STUB
#
teardown_shellspec_stub() {
  remove_temp_dir _STUB_DIR
  unset _SHELLSPEC_STUB
}
