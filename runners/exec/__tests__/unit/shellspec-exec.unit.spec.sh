#!/usr/bin/env bash
# runners/exec/__tests__/unit/shellspec-exec.unit.spec.sh
# @(#) : BDD unit tests for shellspec-exec.sh
#
# Copyright (c) 2026- atsushifx <https://github.com/atsushifx>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT
# shellcheck shell=bash
# shellspec-exec.spec.sh - BDD spec for shellspec-exec.sh

Include "${SHELLSPEC_PROJECT_ROOT}/runners/exec/__tests__/spec_helper.sh"
Include "${SHELLSPEC_PROJECT_ROOT}/runners/exec/shellspec-exec.sh"

SCRIPT="${SHELLSPEC_PROJECT_ROOT}/runners/exec/shellspec-exec.sh"

# --- internal helpers -------------------------------------------------------

# Constants

# Total number of spec files in the fixture built by setup_temp_specs()
# (unit 6 / integration 1 / system 1 / functional 1)
_FIXTURE_SPEC_COUNT=9

# Functions

#
# @description Install a ShellSpec stub that reports the integration mode it inherited
#              instead of its argv. Used to prove the flag actually crosses into the
#              ShellSpec process: a mode set inside a subshell never gets that far.
#              Removed by teardown_shellspec_stub() (spec_helper.sh)
# @sideeffect Sets _STUB_DIR and _SHELLSPEC_STUB
#
_setup_mode_stub() {
  make_temp_dir _STUB_DIR || return 1
  _SHELLSPEC_STUB="${_STUB_DIR}/shellspec-stub"
  # SC2016: the single quotes are intentional. This line only writes the stub body,
  # so SKIP_INTEGRATION_TESTS must be expanded when the stub runs.
  # With double quotes, the value at write time (unset) would be baked in,
  # and all 3 examples using this stub would see SKIP_INTEGRATION_TESTS=unset
  # shellcheck disable=SC2016
  write_bash_stub "$_SHELLSPEC_STUB" 'printf "SKIP_INTEGRATION_TESTS=%s" "${SKIP_INTEGRATION_TESTS:-unset}"'
}

#
# @description Build a private tree holding both a real spec root (pkg/__tests__/unit)
#              and a decoy directory whose name merely ends in __tests__. The shared
#              fixture cannot be used here: it is read-only for every example in the run
# @sideeffect Sets _DECOY_ROOT and repoints SPEC_SEARCH_ROOT at it (saving _ORIG_ROOT)
#
_setup_decoy_tree() {
  make_temp_dir _DECOY_ROOT || return 1
  mkdir -p "${_DECOY_ROOT}/not__tests__/unit" "${_DECOY_ROOT}/pkg/__tests__/unit"
  touch "${_DECOY_ROOT}/not__tests__/unit/decoy.spec.sh"     "${_DECOY_ROOT}/pkg/__tests__/unit/real.spec.sh"
  _ORIG_ROOT="${SPEC_SEARCH_ROOT:-}"
  # shellcheck disable=SC2034
  SPEC_SEARCH_ROOT="$_DECOY_ROOT"
}

#
# @description Print the RESOLVED_SPEC_FILES elements outside a /__tests__/unit/ directory.
#              Blank output means every element is a unit spec
# @stdout Each non-unit element, newline-separated
#
_resolved_non_unit() {
  local f
  for f in ${RESOLVED_SPEC_FILES[@]+"${RESOLVED_SPEC_FILES[@]}"}; do
    [[ "$f" == */__tests__/unit/* ]] || printf '%s\n' "$f"
  done
}

#
# @description Remove the tree built by _setup_decoy_tree() and restore SPEC_SEARCH_ROOT
# @sideeffect Unsets _DECOY_ROOT
#
_teardown_decoy_tree() {
  # shellcheck disable=SC2034
  SPEC_SEARCH_ROOT="${_ORIG_ROOT:-}"
  remove_temp_dir _DECOY_ROOT
}

Describe 'T-RUN-ITT: is_test_type()'
  Describe 'valid test types'
    It 'T-RUN-ITT-01: returns success for all'
      When call is_test_type 'all'
      The status should be success
    End

    It 'T-RUN-ITT-02: returns success for unit'
      When call is_test_type 'unit'
      The status should be success
    End

    It 'T-RUN-ITT-03: returns success for functional'
      When call is_test_type 'functional'
      The status should be success
    End

    It 'T-RUN-ITT-04: returns success for integration'
      When call is_test_type 'integration'
      The status should be success
    End

    It 'T-RUN-ITT-05: returns success for system'
      When call is_test_type 'system'
      The status should be success
    End

    It 'T-RUN-ITT-06: returns success for e2e'
      When call is_test_type 'e2e'
      The status should be success
    End
  End

  Describe 'invalid test types'
    It 'T-RUN-ITT-07: returns failure for spec'
      When call is_test_type 'spec'
      The status should be failure
    End

    It 'T-RUN-ITT-08: returns failure for empty string'
      When call is_test_type ''
      The status should be failure
    End

    It 'T-RUN-ITT-09: returns failure for uppercase ALL'
      When call is_test_type 'ALL'
      The status should be failure
    End

    It 'T-RUN-ITT-10: returns failure for unknowntype'
      When call is_test_type 'unknowntype'
      The status should be failure
    End
  End
End

Describe 'T-RUN-ISF: is_spec_file()'
  Describe 'valid spec file paths'
    It 'T-RUN-ISF-01: returns success for foo.spec.sh'
      When call is_spec_file 'foo.spec.sh'
      The status should be success
    End

    It 'T-RUN-ISF-02: returns success for path/to/bar.spec.sh'
      When call is_spec_file 'path/to/bar.spec.sh'
      The status should be success
    End
  End

  Describe 'invalid spec file paths'
    It 'T-RUN-ISF-03: returns failure for foo.sh'
      When call is_spec_file 'foo.sh'
      The status should be failure
    End

    It 'T-RUN-ISF-04: returns failure for unit'
      When call is_spec_file 'unit'
      The status should be failure
    End

    It 'T-RUN-ISF-05: returns failure for spec.sh (no .spec. pattern)'
      When call is_spec_file 'spec.sh'
      The status should be failure
    End

    It 'T-RUN-ISF-06: returns failure for empty string'
      When call is_spec_file ''
      The status should be failure
    End
  End
End

Describe 'get_spec_files()'
  Before 'setup_temp_specs'
  After 'teardown_temp_specs'

  Describe 'T-RUN-GSF: test type expansion'
    It 'T-RUN-GSF-01: returns spec files under tests/ for all'
      When call get_spec_files 'all'
      The output should include '.spec.sh'
      The status should be success
    End

    It 'T-RUN-GSF-02: returns only unit spec files for unit'
      When call get_spec_files 'unit'
      The output should include '__tests__/unit'
      The status should be success
    End

    It 'T-RUN-GSF-03: does not include integration files for unit'
      When call get_spec_files 'unit'
      The output should not include '__tests__/integration'
    End

    It 'T-RUN-GSF-04: filters by glob pattern init* for unit'
      When call get_spec_files 'unit' 'init*'
      The output should include 'init'
      The status should be success
    End

    It 'T-RUN-GSF-05: filters by exact name kv-store for unit'
      When call get_spec_files 'unit' 'kv-store'
      The output should include 'kv-store'
      The status should be success
    End

    It 'T-RUN-GSF-06: output paths do not contain backslashes'
      When call get_spec_files 'all'
      # shellcheck disable=SC1003
      The output should not include '\'
    End

    # Verify that a type name resolves to `__tests__/<type>/`
    Describe 'When: Normal cases'
      It '[Normal] T-RUN-GSF-07: returns the functional spec for functional'
        When call get_spec_files 'functional'
        The output should include '__tests__/functional'
        The status should be success
      End

      It '[Normal] T-RUN-GSF-08: collects unit specs from nested __tests__ roots'
        When call get_spec_files 'unit'
        The output should include 'subcommands/__tests__/unit'
        The status should be success
      End

      It '[Normal] T-RUN-GSF-09: returns every fixture spec for all'
        When call get_spec_files 'all'
        The lines of output should equal "$_FIXTURE_SPEC_COUNT"
        The status should be success
      End
    End
  End
End

# The shared fixture is read-only, so build the decoy directories in a dedicated tree
Describe 'get_spec_files() - path component anchoring'
  Before '_setup_decoy_tree'
  After '_teardown_decoy_tree'

  Describe 'When: Edge cases'
    It '[Edge] T-RUN-GSF-10: collects the real __tests__ root for all'
      When call get_spec_files 'all'
      The output should include 'pkg/__tests__/unit/real.spec.sh'
      The status should be success
    End

    # A directory that merely ends with `__tests__` is not a test root
    It '[Edge] T-RUN-GSF-11: skips a directory that merely ends in __tests__'
      When call get_spec_files 'all'
      The output should not include 'decoy.spec.sh'
    End
  End
End

Describe 'T-RUN-PO: parse_options()'
  Before 'SKIP_INTEGRATION_TESTS=1'

  Describe '--integration flag handling'
    It 'T-RUN-PO-01: removes --integration and sets SKIP_INTEGRATION_TESTS=0'
      When call parse_options 'unit' '--integration'
      The value "${PARSED_ARGS[*]}" should equal 'unit'
      The variable SKIP_INTEGRATION_TESTS should equal '0'
    End

    It 'T-RUN-PO-02: removes leading --integration flag'
      When call parse_options '--integration' 'unit'
      The value "${PARSED_ARGS[*]}" should equal 'unit'
    End
  End

  Describe 'passthrough of other options'
    It 'T-RUN-PO-03: passes --focus through unchanged'
      When call parse_options 'unit' '--focus'
      The value "${PARSED_ARGS[*]}" should include 'unit'
      The value "${PARSED_ARGS[*]}" should include '--focus'
    End

    It 'T-RUN-PO-04: leaves PARSED_ARGS empty for no arguments'
      When call parse_options
      The value "${#PARSED_ARGS[@]}" should equal '0'
    End
  End
End

Describe 'T-RUN-ISG: is_spec_glob()'
  Describe 'spec glob patterns'
    It 'T-RUN-ISG-01: returns success for runners/libs/__tests__/unit/*.spec.sh'
      When call is_spec_glob 'runners/libs/__tests__/unit/*.spec.sh'
      The status should be success
    End
  End

  Describe 'non-spec-glob patterns'
    It 'T-RUN-ISG-02: returns failure for init* (no .spec.sh)'
      When call is_spec_glob 'init*'
      The status should be failure
    End

    It 'T-RUN-ISG-03: returns failure for foo.spec.sh (no glob)'
      When call is_spec_glob 'foo.spec.sh'
      The status should be failure
    End
  End
End

Describe 'expand_spec_glob()'
  Before 'setup_temp_specs'
  After 'teardown_temp_specs'

  Describe 'T-RUN-ESG: glob expansion'
    It 'T-RUN-ESG-01: returns matching spec files for runners/libs/__tests__/unit/*.spec.sh'
      When call expand_spec_glob 'runners/libs/__tests__/unit/*.spec.sh'
      The output should include '.spec.sh'
      The status should be success
    End

    It 'T-RUN-ESG-02: exits with 0 and warns for non-matching glob'
      When call expand_spec_glob 'runners/libs/__tests__/unit/nonexistent*.spec.sh'
      The stderr should include 'Warning'
      The status should be success
    End
  End
End

Describe 'T-RUN-RSF: resolve_spec_files()'
  Before 'SKIP_INTEGRATION_TESTS=1'

  Describe 'single spec file passthrough'
    It 'T-RUN-RSF-01: returns spec file unchanged for foo.spec.sh'
      When call resolve_spec_files 'foo.spec.sh'
      The value "${RESOLVED_SPEC_FILES[*]}" should equal 'foo.spec.sh'
      The status should be success
    End
  End

  Describe 'spec glob expansion'
    Before 'setup_temp_specs'
    After 'teardown_temp_specs'

    It 'T-RUN-RSF-02: expands glob pattern runners/libs/__tests__/unit/*.spec.sh'
      When call resolve_spec_files 'runners/libs/__tests__/unit/*.spec.sh'
      The value "${RESOLVED_SPEC_FILES[*]}" should include '.spec.sh'
      The status should be success
    End
  End

  Describe 'test type expansion'
    Before 'setup_temp_specs'
    After 'teardown_temp_specs'

    # Regression guard: the test-type path must keep expanding through get_spec_files
    It 'T-RUN-RSF-03: expands unit to unit spec files'
      When call resolve_spec_files 'unit'
      The value "${#RESOLVED_SPEC_FILES[@]}" should not equal 0
      The result of function _resolved_non_unit should be blank
      The output should be blank
      The stderr should be blank
      The status should be success
    End

    It 'T-RUN-RSF-04: sets SKIP_INTEGRATION_TESTS=0 for system'
      When call resolve_spec_files 'system'
      The variable SKIP_INTEGRATION_TESTS should equal '0'
      The value "${RESOLVED_SPEC_FILES[*]}" should include '__tests__/system'
      The status should be success
    End

    # Verify that a type name resolves to `__tests__/<type>/`
    Describe 'When: Normal cases'
      It '[Normal] T-RUN-RSF-07: expands functional to the functional spec'
        When call resolve_spec_files 'functional'
        The value "${RESOLVED_SPEC_FILES[*]}" should include '__tests__/functional'
        The status should be success
      End

      # Overlaps T-RUN-RSF-03 (which also asserts a blank stderr); kept as the focused guard.
      # Guards against a regression where an unresolved type emits a "No spec files found" warning
      It '[Normal] T-RUN-RSF-08: leaves stderr silent when unit specs are found'
        When call resolve_spec_files 'unit'
        The value "${#RESOLVED_SPEC_FILES[@]}" should not equal '0'
        The stderr should be blank
      End
    End

    # The fixture has no e2e directory (intentionally omitted by runners/libs/__tests__/spec_helper.sh)
    Describe 'When: Error cases'
      It '[Error] T-RUN-RSF-09: warns and succeeds when no spec matches the type'
        When call resolve_spec_files 'e2e'
        The stderr should include "No spec files found for test type 'e2e'"
        The value "${#RESOLVED_SPEC_FILES[@]}" should equal '0'
        The status should be success
      End
    End
  End

  Describe 'error handling'
    It 'T-RUN-RSF-05: exits with failure for unknown test type'
      When call resolve_spec_files 'unknowntype'
      The stderr should include "Error: Unknown argument 'unknowntype'"
      The value "${#RESOLVED_SPEC_FILES[@]}" should equal '0'
      The status should be failure
    End

    It 'T-RUN-RSF-06: reports missing arguments on stderr'
      When call resolve_spec_files
      The stderr should include 'Error: No arguments given.'
      The value "${#RESOLVED_SPEC_FILES[@]}" should equal '0'
      The status should be failure
    End
  End
End

Describe 'T-RUN-MRS: main()'
  Describe 'invalid argument handling'
    # ShellSpec strips trailing newlines from captured stderr, so a stray blank
    # line is invisible to 'The lines of stderr'. Count the lines in-pipeline and
    # propagate the script exit code via PIPESTATUS.
    It 'T-RUN-MRS-01: writes exactly one stderr line for an unknown argument'
      When run bash -c "bash \"$SCRIPT\" unknowntype 2>&1 1>/dev/null | grep -c ^; exit \${PIPESTATUS[0]}"
      The output should equal '1'
      The status should equal 1
    End

    It 'T-RUN-MRS-02: reports the unknown argument on stderr'
      When run bash "$SCRIPT" unknowntype
      The stderr should include "Unknown argument 'unknowntype'"
      The output should be blank
      The status should equal 1
    End
  End

  Describe 'ShellSpec option passthrough'
    Before 'setup_shellspec_stub'
    After 'teardown_shellspec_stub'

    Describe 'When: Normal cases'
      It '[Normal] T-RUN-MRS-03: forwards an option placed after the spec file to ShellSpec'
        When run env SHELLSPEC="$_SHELLSPEC_STUB" bash "$SCRIPT" 'foo.spec.sh' '--repair'
        The output should equal '[foo.spec.sh][--repair]'
        The status should be success
      End

      It '[Normal] T-RUN-MRS-04: keeps the value of a value-taking option out of the targets'
        When run env SHELLSPEC="$_SHELLSPEC_STUB" bash "$SCRIPT" 'foo.spec.sh' '--format' 'documentation'
        The output should equal '[foo.spec.sh][--format][documentation]'
        The status should be success
      End

      It '[Normal] T-RUN-MRS-05: consumes --integration itself and forwards the remaining options'
        When run env SHELLSPEC="$_SHELLSPEC_STUB" bash "$SCRIPT" 'foo.spec.sh' '--integration' '--repair'
        The output should equal '[foo.spec.sh][--repair]'
        The status should be success
      End
    End

    Describe 'When: Edge cases'
      It '[Edge] T-RUN-MRS-06: launches ShellSpec with the target alone when no option is given'
        When run env SHELLSPEC="$_SHELLSPEC_STUB" bash "$SCRIPT" 'foo.spec.sh'
        The output should equal '[foo.spec.sh]'
        The status should be success
      End
    End
  End

  # If main() sets SKIP_INTEGRATION_TESTS inside a subshell, ShellSpec receives
  # the default of 1 and integration tests are silently skipped.
  # Unit tests of parse_options() / resolve_spec_files() do not take this path,
  # so verify here the value the ShellSpec process actually received
  Describe 'integration mode propagation'
    Before 'setup_temp_specs'
    Before '_setup_mode_stub'
    After 'teardown_shellspec_stub'
    After 'teardown_temp_specs'

    Describe 'When: Normal cases'
      It '[Normal] T-RUN-MRS-07: hands SKIP_INTEGRATION_TESTS=0 to ShellSpec for --integration'
        When run env SHELLSPEC="$_SHELLSPEC_STUB" bash "$SCRIPT" 'foo.spec.sh' '--integration'
        The output should equal 'SKIP_INTEGRATION_TESTS=0'
        The status should be success
      End

      It '[Normal] T-RUN-MRS-08: hands SKIP_INTEGRATION_TESTS=0 to ShellSpec for the system type'
        When run env SPEC_SEARCH_ROOT="$TEMP_DIR" SHELLSPEC="$_SHELLSPEC_STUB" bash "$SCRIPT" 'system'
        The output should equal 'SKIP_INTEGRATION_TESTS=0'
        The status should be success
      End
    End

    Describe 'When: Edge cases'
      It '[Edge] T-RUN-MRS-09: keeps SKIP_INTEGRATION_TESTS=1 for a plain unit run'
        When run env SPEC_SEARCH_ROOT="$TEMP_DIR" SHELLSPEC="$_SHELLSPEC_STUB" bash "$SCRIPT" 'unit'
        The output should equal 'SKIP_INTEGRATION_TESTS=1'
        The status should be success
      End
    End
  End

  # `pnpm run test:sh` calls this runner without arguments. Without a default type,
  # the standard test command would always fail
  Describe 'default target'
    Before 'setup_temp_specs'
    Before 'setup_shellspec_stub'
    After 'teardown_shellspec_stub'
    After 'teardown_temp_specs'

    Describe 'When: Edge cases'
      It '[Edge] T-RUN-MRS-10: falls back to the all suite when no argument is given'
        When run env SPEC_SEARCH_ROOT="$TEMP_DIR" SHELLSPEC="$_SHELLSPEC_STUB" bash "$SCRIPT"
        The output should include '__tests__/unit/'
        The output should include '__tests__/system/'
        The status should be success
      End

      It '[Edge] T-RUN-MRS-11: falls back to the all suite when only options are given'
        When run env SPEC_SEARCH_ROOT="$TEMP_DIR" SHELLSPEC="$_SHELLSPEC_STUB" bash "$SCRIPT" '--repair'
        The output should include '__tests__/unit/'
        The output should include '[--repair]'
        The status should be success
      End
    End
  End
End

# --- internal helpers -------------------------------------------------------

#
# @description Print RESOLVED_SPEC_FILES one element per line.
#              Lets one comparison check the whole array (length, order, elements)
# @stdout Each element of RESOLVED_SPEC_FILES, newline-separated
#
_resolved_list() {
  printf '%s\n' ${RESOLVED_SPEC_FILES[@]+"${RESOLVED_SPEC_FILES[@]}"}
}

#
# @description Print the error resolve_spec_files() reports for a rejected argument
# @arg $1 string The rejected argument
# @stdout The expected error message
#
_unknown_argument_error() {
  printf "Error: Unknown argument '%s'. Expected a test type, spec file, or glob pattern." "$1"
}

Describe 'T-RUN-RSF: resolve_spec_files()'
  Before 'SKIP_INTEGRATION_TESTS=1'

  # Guards against targets after the first one being silently dropped
  Describe 'When: Normal cases'
    It '[Normal] T-RUN-RSF-10: stores every spec file when given two spec files'
      When call resolve_spec_files 'a.spec.sh' 'b.spec.sh'
      The value "${#RESOLVED_SPEC_FILES[@]}" should equal 2
      The result of function _resolved_list should equal "$(printf '%s\n' 'a.spec.sh' 'b.spec.sh')"
      The output should be blank
      The status should be success
    End

    Describe 'glob targets'
      Before 'setup_temp_specs'
      After 'teardown_temp_specs'

      It '[Normal] T-RUN-RSF-11: stores the spec file then the glob expansion'
        When call resolve_spec_files 'a.spec.sh' 'runners/libs/__tests__/unit/*.spec.sh'
        The value "${#RESOLVED_SPEC_FILES[@]}" should equal 2
        The result of function _resolved_list should equal "$(printf '%s\n' 'a.spec.sh' 'runners/libs/__tests__/unit/get-filelist.spec.sh')"
        # A glob string also ends in *.spec.sh; reject one passed through unexpanded
        The result of function _resolved_list should not include '*'
        The output should be blank
        The status should be success
      End

      # A leading glob must not drop the spec file after it
      It '[Normal] T-RUN-RSF-13: stores the glob expansion then the spec file'
        When call resolve_spec_files 'runners/libs/__tests__/unit/*.spec.sh' 'b.spec.sh'
        The value "${#RESOLVED_SPEC_FILES[@]}" should equal 2
        The result of function _resolved_list should equal "$(printf '%s\n' 'runners/libs/__tests__/unit/get-filelist.spec.sh' 'b.spec.sh')"
        The output should be blank
        The status should be success
      End
    End
  End

  # A bad target anywhere must fail the whole call before anything is stored
  Describe 'When: Error cases'
    It '[Error] T-RUN-RSF-12: rejects an unknown argument after a spec file'
      When call resolve_spec_files 'a.spec.sh' 'unknownarg'
      The stderr should equal "$(_unknown_argument_error 'unknownarg')"
      The value "${#RESOLVED_SPEC_FILES[@]}" should equal 0
      The output should be blank
      The status should be failure
    End

    Describe 'glob targets'
      Before 'setup_temp_specs'
      After 'teardown_temp_specs'

      # Validation must run before the leading glob is expanded and stored
      It '[Error] T-RUN-RSF-14: rejects a non-spec file after a glob'
        When call resolve_spec_files 'runners/libs/__tests__/unit/*.spec.sh' 'foo.sh'
        The stderr should equal "$(_unknown_argument_error 'foo.sh')"
        The value "${#RESOLVED_SPEC_FILES[@]}" should equal 0
        The output should be blank
        The status should be failure
      End
    End
  End

  # A test type selects a whole category, so it is only valid as the first argument
  Describe 'When: Edge cases'
    It '[Edge] T-RUN-RSF-15: rejects a test type after a spec file'
      When call resolve_spec_files 'a.spec.sh' 'unit'
      The stderr should equal "$(_unknown_argument_error 'unit')"
      The value "${#RESOLVED_SPEC_FILES[@]}" should equal 0
      The output should be blank
      The status should be failure
    End
  End
End
