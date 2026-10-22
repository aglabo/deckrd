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

# Marker the T-RUN-EMP examples put in front of the reported PATH. Deliberately not
# LOGIN_PATH_MARKER: extract_marked_path() must take the marker from its argument
_EMP_MARKER='__SPEC_MARKER__'

# PATH carried by the marked line. It holds a separator, so a result that stops at
# the first colon is told apart from the whole remainder (T-RUN-EMP expectation)
_EMP_REPORTED_PATH='/deckrd-stub/login/bin:/deckrd-stub/login/sbin'

# Older report printed before a second marked line; tells the last marked line
# winning apart from the first (T-RUN-EMP-04 input)
_EMP_SHADOWED_PATH='/deckrd-stub/echoed/bin'

# Progress lines the startup files (profile chain) write to stdout. They are not
# the PATH report and must never leak into the result (T-RUN-EMP input)
_LOGIN_PROFILE_NOISE=$'Exec /opt/etc/profile\nExec: envrc\nExec: aliases'

# PATH the login shell stub reports on the marked line. The directory does not
# exist, so it never mixes with the runner's real PATH (T-RUN-EIP-01/04 expectation;
# the T-RUN-MRS-12..17 file stub puts it in front of its own directory and the real PATH)
_EIP_LOGIN_PATH='/deckrd-stub/login/bin'

# Report holding two empty entries, as a profile that stacks `PATH="${PATH}:"`
# would produce (T-RUN-EIP-05 input)
_EIP_LOGIN_PATH_WITH_EMPTY='/deckrd-stub/login/bin::/deckrd-stub/login/sbin:'

# The report above with its empty entries dropped (T-RUN-EIP-05 expectation)
_EIP_LOGIN_PATH_WITHOUT_EMPTY='/deckrd-stub/login/bin:/deckrd-stub/login/sbin'

# Report holding nothing but empty entries; dropping them leaves nothing
# (T-RUN-EIP-08 input)
_EIP_LOGIN_PATH_ALL_EMPTY='::'

# Exit code of the failing stub. Neither 0 nor 1, so a passed-through status is
# told apart (T-RUN-EIP-02 input)
_EIP_LOGIN_SHELL_EXIT_CODE=3

# Start-up flag ensure_integration_path() must pass to the login shell
# (T-RUN-EIP-06 expectation)
_EIP_EXPECTED_LOGIN_FLAG='-lic'

# PATH the probe-running stub hands the probe body. It holds a separator, so a
# report cut at the first colon is told apart; the directories do not exist
# (T-RUN-EIP-09 input and expectation)
_EIP_PROBE_PATH='/deckrd-stub/probe/bin:/deckrd-stub/probe/sbin'

# Prefix put in front of the flag when it is reported as a PATH entry. A PATH that
# starts with `-` reads poorly, so the flag is dressed as a directory (T-RUN-EIP-06)
_EIP_FLAG_REPORT_PREFIX='/deckrd-stub/login-flag/'

# Functions

#
# @description Print the marked line. Common body of the login shell stubs. The marker
#              is the one the probe passed, so the stubs also pin down that the probe
#              hands the marker over as a positional parameter
# @arg $1 string PATH the stub reports
# @arg $2 string Marker the probe passed
# @stdout One empty line followed by the marked line
#
_print_login_path_report() {
  printf '\n%s%s\n' "$2" "$1"
}

#
# @description Replace the login shell with a shell function that prints the marked
#              line only. ensure_integration_path() calls bash by name, not by full
#              path, so a shell function shadows it; keeps the runner's own startup
#              files out of the result (T-RUN-EIP-01 input)
# @sideeffect Saves the current PATH into _EIP_ORIG_PATH
# @sideeffect Defines the bash shell function
#
_setup_login_shell_stub() {
  _EIP_ORIG_PATH="$PATH"
  # shellcheck disable=SC2329 # called indirectly by ensure_integration_path()
  bash() { _print_login_path_report "$_EIP_LOGIN_PATH" "${4:-}"; }
}

#
# @description Replace the login shell with a shell function that prints the startup
#              files' progress lines before the marked line. Mimics a runner whose
#              startup files write to stdout (T-RUN-EIP-04 input)
# @sideeffect Redefines the bash shell function
#
_setup_noisy_login_shell_stub() {
  # shellcheck disable=SC2329 # called indirectly by ensure_integration_path()
  bash() {
    printf '%s\n' "$_LOGIN_PROFILE_NOISE"
    _print_login_path_report "$_EIP_LOGIN_PATH" "${4:-}"
  }
}

#
# @description Replace the login shell with a shell function that reports a PATH
#              holding empty entries, as a runner's profile may build
#              (T-RUN-EIP-05 input)
# @sideeffect Redefines the bash shell function
#
_setup_empty_entry_login_shell_stub() {
  # shellcheck disable=SC2329 # called indirectly by ensure_integration_path()
  bash() { _print_login_path_report "$_EIP_LOGIN_PATH_WITH_EMPTY" "${4:-}"; }
}

#
# @description Replace the login shell with a shell function that reports the
#              start-up flag it received as the PATH. The stub runs inside a command
#              substitution, so it cannot hand its arguments back through a variable;
#              the report (marked line) carries them to the caller's PATH instead
#              (T-RUN-EIP-06 input)
# @sideeffect Redefines the bash shell function
#
_setup_flag_reporting_login_shell_stub() {
  # shellcheck disable=SC2329 # called indirectly by ensure_integration_path()
  bash() { _print_login_path_report "${_EIP_FLAG_REPORT_PREFIX}${1}" "${4:-}"; }
}

#
# @description Replace the login shell with a shell function that runs the probe body
#              (`$2`) with the real non-login bash under _EIP_PROBE_PATH. The flag
#              (`$1`) is dropped, so no startup file is read and no real login shell
#              starts; `$3` and `$4` (name and marker) are passed on as given. Unlike
#              the other stubs, a probe that reports anything but its own PATH fails
#              (T-RUN-EIP-09 input)
# @sideeffect Redefines the bash shell function
#
_setup_probe_running_login_shell_stub() {
  # shellcheck disable=SC2329 # called indirectly by ensure_integration_path()
  bash() { PATH="$_EIP_PROBE_PATH" command "$BASH" -c "$2" "$3" "$4"; }
}

#
# @description Replace the login shell with a shell function that fails without any
#              output. Mimics a runner whose startup files fail to load
#              (T-RUN-EIP-02 input)
# @sideeffect Redefines the bash shell function
#
_setup_failing_login_shell_stub() {
  # shellcheck disable=SC2329 # called indirectly by ensure_integration_path()
  bash() { return "$_EIP_LOGIN_SHELL_EXIT_CODE"; }
}

#
# @description Replace the login shell with a shell function that succeeds without
#              any output. Mimics startup files that swallow the probe's report
#              (T-RUN-EIP-03 input)
# @sideeffect Redefines the bash shell function
#
_setup_silent_login_shell_stub() {
  # shellcheck disable=SC2329 # called indirectly by ensure_integration_path()
  bash() { return 0; }
}

#
# @description Replace the login shell with a shell function that prints the progress
#              lines only and no marked line. Mimics startup files that clobber the
#              probe body (T-RUN-EIP-07 input)
# @sideeffect Redefines the bash shell function
#
_setup_markerless_login_shell_stub() {
  # shellcheck disable=SC2329 # called indirectly by ensure_integration_path()
  bash() { printf '%s\n' "$_LOGIN_PROFILE_NOISE"; }
}

#
# @description Replace the login shell with a shell function that reports a PATH of
#              empty entries only; dropping them leaves nothing (T-RUN-EIP-08 input)
# @sideeffect Redefines the bash shell function
#
_setup_all_empty_login_shell_stub() {
  # shellcheck disable=SC2329 # called indirectly by ensure_integration_path()
  bash() { _print_login_path_report "$_EIP_LOGIN_PATH_ALL_EMPTY" "${4:-}"; }
}

#
# @description Remove the login shell stub and restore PATH
# @sideeffect Restores PATH from _EIP_ORIG_PATH and unsets _EIP_ORIG_PATH
# @sideeffect Removes the bash shell function
#
_teardown_login_shell_stub() {
  unset -f bash
  PATH="$_EIP_ORIG_PATH"
  unset _EIP_ORIG_PATH
}

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
# @description Write a login shell stub as `${_STUB_DIR}/bash`. main() runs in a
#              separate process, so a shell function cannot shadow bash; this file
#              stub on PATH does. Each login call appends its `$1` to _LOGIN_CALLS_LOG
#              and reports `/deckrd-stub/login/bin:`, the stub directory and the PATH at
#              setup time, in that order. The stub directory stays on the report, so
#              after main() adopts it a second login call still reaches this stub and
#              is logged instead of starting the real login bash; that is what lets
#              T-RUN-MRS-17 pin down "exactly once".
#              Written without write_bash_stub(): under `#!/usr/bin/env bash` a stub
#              named bash would resolve its own interpreter to itself and loop forever,
#              so its shebang names the real bash by absolute path. A non-login call
#              (`bash "$SHELLSPEC"`, before or after the report is adopted) is handed
#              to the real bash, so only login shell starts are logged.
#              Callers put `${_STUB_DIR}` in front of PATH and start the script with
#              the absolute "$BASH". Never starts a real login shell
# @arg _STUB_DIR string (global) Directory the stub is written to
# @sideeffect Sets _LOGIN_CALLS_LOG
#
_write_login_shell_stub() {
  _LOGIN_CALLS_LOG="${_STUB_DIR}/login-calls.log"
  local real_bash log report
  printf -v real_bash '%q' "$BASH"
  printf -v log '%q' "$_LOGIN_CALLS_LOG"
  printf -v report '%q' "${_EIP_LOGIN_PATH}:${_STUB_DIR}:${PATH}"
  # SC2016: `$1`, `$@` and `$4` belong to the stub and expand when it runs
  # shellcheck disable=SC2016
  printf '#!%s\n%s\n%s\n%s\n' "$BASH" \
    '[[ "${1:-}" == -l* ]] || exec '"${real_bash}"' "$@"' \
    'printf "%s\n" "$1" >>'"${log}" \
    'printf "\n%s%s\n" "${4:-}" '"${report}" >"${_STUB_DIR}/bash" || return 1
  chmod +x "${_STUB_DIR}/bash"
}

#
# @description Install the login shell stub (_write_login_shell_stub) and a ShellSpec
#              stub that reports the PATH it inherited, which tells whether main()
#              adopted the login PATH. Removed by teardown_shellspec_stub()
#              (spec_helper.sh)
# @sideeffect Sets _STUB_DIR, _SHELLSPEC_STUB and _LOGIN_CALLS_LOG
#
_setup_login_path_stubs() {
  make_temp_dir _STUB_DIR || return 1
  _SHELLSPEC_STUB="${_STUB_DIR}/shellspec-stub"
  # SC2016: the single quotes are intentional; the stub expands PATH when it runs
  # shellcheck disable=SC2016
  write_bash_stub "$_SHELLSPEC_STUB" 'printf "PATH=%s" "$PATH"' || return 1
  _write_login_shell_stub
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

#
# @description Prepare an in-process main() call: pin the default mode, point SHELLSPEC
#              at the argv stub and save the globals main() rewrites
# @sideeffect Sets _STUB_DIR, _SHELLSPEC_STUB, SHELLSPEC and SKIP_INTEGRATION_TESTS=1;
#             saves SHELLSPEC, SKIP_INTEGRATION_TESTS, PARSED_ARGS and RESOLVED_SPEC_FILES
#
_setup_in_process_main() {
  _MRS_ORIG_SHELLSPEC="$SHELLSPEC"
  _MRS_ORIG_SKIP="$SKIP_INTEGRATION_TESTS"
  _MRS_ORIG_PARSED=(${PARSED_ARGS[@]+"${PARSED_ARGS[@]}"})
  _MRS_ORIG_RESOLVED=(${RESOLVED_SPEC_FILES[@]+"${RESOLVED_SPEC_FILES[@]}"})
  setup_shellspec_stub || return 1
  SHELLSPEC="$_SHELLSPEC_STUB"
  SKIP_INTEGRATION_TESTS=1
}

#
# @description Undo _setup_in_process_main(): remove the stub and restore the globals
# @sideeffect Restores SHELLSPEC, SKIP_INTEGRATION_TESTS, PARSED_ARGS and
#             RESOLVED_SPEC_FILES
#
_teardown_in_process_main() {
  teardown_shellspec_stub
  SHELLSPEC="$_MRS_ORIG_SHELLSPEC"
  SKIP_INTEGRATION_TESTS="$_MRS_ORIG_SKIP"
  PARSED_ARGS=(${_MRS_ORIG_PARSED[@]+"${_MRS_ORIG_PARSED[@]}"})
  RESOLVED_SPEC_FILES=(${_MRS_ORIG_RESOLVED[@]+"${_MRS_ORIG_RESOLVED[@]}"})
}

#
# @description Call main() in this shell, then report that control came back. An
#              `exit` inside main() would end the shell before the report is printed
# @arg $@ Arguments passed to main()
# @stdout `continued after main: <main's return value>`
# @exitcode main()'s return value
#
_call_main_then_continue() {
  local rc=0
  main "$@" || rc=$?
  printf 'continued after main: %s
' "$rc"
  return "$rc"
}

#
# @description Point SPEC_SEARCH_ROOT at an empty directory, so no test type matches
# @sideeffect Sets _MRS_EMPTY_ROOT and SPEC_SEARCH_ROOT (saving _MRS_ORIG_ROOT)
#
_setup_empty_search_root() {
  make_temp_dir _MRS_EMPTY_ROOT || return 1
  _MRS_ORIG_ROOT="$SPEC_SEARCH_ROOT"
  SPEC_SEARCH_ROOT="$_MRS_EMPTY_ROOT"
}

#
# @description Undo _setup_empty_search_root()
# @sideeffect Restores SPEC_SEARCH_ROOT and unsets _MRS_EMPTY_ROOT
#
_teardown_empty_search_root() {
  SPEC_SEARCH_ROOT="$_MRS_ORIG_ROOT"
  remove_temp_dir _MRS_EMPTY_ROOT
}

Describe 'T-RUN-MRS: main()'
  Describe 'invalid argument handling'
    # ShellSpec strips trailing newlines from captured stderr, so a stray blank
    # line is invisible to 'The lines of stderr'. Count the lines in-pipeline and
    # propagate the script exit code via PIPESTATUS.
    It 'T-RUN-MRS-01: writes exactly one stderr line for an unknown argument'
      When run bash -c "SKIP_INTEGRATION_TESTS=1 bash \"$SCRIPT\" unknowntype 2>&1 1>/dev/null | grep -c ^; exit \${PIPESTATUS[0]}"
      The output should equal '1'
      The status should equal 1
    End

    It 'T-RUN-MRS-02: reports the unknown argument on stderr'
      When run env SKIP_INTEGRATION_TESTS=1 bash "$SCRIPT" unknowntype
      The stderr should include "Unknown argument 'unknowntype'"
      The output should be blank
      The status should equal 1
    End
  End

  Describe 'ShellSpec option passthrough'
    Before 'setup_shellspec_stub'
    # --integration (MRS-05) makes main() start the login shell
    Before '_write_login_shell_stub'
    After 'teardown_shellspec_stub'

    Describe 'When: Normal cases'
      It '[Normal] T-RUN-MRS-03: forwards an option placed after the spec file to ShellSpec'
        When run env SKIP_INTEGRATION_TESTS=1 SHELLSPEC="$_SHELLSPEC_STUB" bash "$SCRIPT" 'foo.spec.sh' '--repair'
        The output should equal '[foo.spec.sh][--repair]'
        The status should be success
      End

      It '[Normal] T-RUN-MRS-04: keeps the value of a value-taking option out of the targets'
        When run env SKIP_INTEGRATION_TESTS=1 SHELLSPEC="$_SHELLSPEC_STUB" bash "$SCRIPT" 'foo.spec.sh' '--format' 'documentation'
        The output should equal '[foo.spec.sh][--format][documentation]'
        The status should be success
      End

      It '[Normal] T-RUN-MRS-05: consumes --integration itself and forwards the remaining options'
        When run env PATH="${_STUB_DIR}:${PATH}" SHELLSPEC="$_SHELLSPEC_STUB" "$BASH" "$SCRIPT" 'foo.spec.sh' '--integration' '--repair'
        The output should equal '[foo.spec.sh][--repair]'
        The status should be success
      End
    End

    Describe 'When: Edge cases'
      It '[Edge] T-RUN-MRS-06: launches ShellSpec with the target alone when no option is given'
        When run env SKIP_INTEGRATION_TESTS=1 SHELLSPEC="$_SHELLSPEC_STUB" bash "$SCRIPT" 'foo.spec.sh'
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
    # Integration mode makes main() start the login shell (MRS-07/08)
    Before '_write_login_shell_stub'
    After 'teardown_shellspec_stub'
    After 'teardown_temp_specs'

    Describe 'When: Normal cases'
      It '[Normal] T-RUN-MRS-07: hands SKIP_INTEGRATION_TESTS=0 to ShellSpec for --integration'
        When run env PATH="${_STUB_DIR}:${PATH}" SHELLSPEC="$_SHELLSPEC_STUB" "$BASH" "$SCRIPT" 'foo.spec.sh' '--integration'
        The output should equal 'SKIP_INTEGRATION_TESTS=0'
        The status should be success
      End

      It '[Normal] T-RUN-MRS-08: hands SKIP_INTEGRATION_TESTS=0 to ShellSpec for the system type'
        When run env PATH="${_STUB_DIR}:${PATH}" SPEC_SEARCH_ROOT="$TEMP_DIR" SHELLSPEC="$_SHELLSPEC_STUB" "$BASH" "$SCRIPT" 'system'
        The output should equal 'SKIP_INTEGRATION_TESTS=0'
        The status should be success
      End
    End

    Describe 'When: Edge cases'
      It '[Edge] T-RUN-MRS-09: keeps SKIP_INTEGRATION_TESTS=1 for a plain unit run'
        When run env SKIP_INTEGRATION_TESTS=1 SPEC_SEARCH_ROOT="$TEMP_DIR" SHELLSPEC="$_SHELLSPEC_STUB" bash "$SCRIPT" 'unit'
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
        When run env SKIP_INTEGRATION_TESTS=1 SPEC_SEARCH_ROOT="$TEMP_DIR" SHELLSPEC="$_SHELLSPEC_STUB" bash "$SCRIPT"
        The output should include '__tests__/unit/'
        The output should include '__tests__/system/'
        The status should be success
      End

      It '[Edge] T-RUN-MRS-11: falls back to the all suite when only options are given'
        When run env SKIP_INTEGRATION_TESTS=1 SPEC_SEARCH_ROOT="$TEMP_DIR" SHELLSPEC="$_SHELLSPEC_STUB" bash "$SCRIPT" '--repair'
        The output should include '__tests__/unit/'
        The output should include '[--repair]'
        The status should be success
      End
    End
  End

  # Real-machine tests need the tools the user's startup files install, and the
  # non-login shell that runs this script has none of them. The outer script is
  # started by the absolute "$BASH" so that it never picks up the login shell stub
  Describe 'login PATH for integration runs'
    Before 'setup_temp_specs'
    Before '_setup_login_path_stubs'
    After 'teardown_shellspec_stub'
    After 'teardown_temp_specs'

    Describe 'When: Normal cases'
      It '[Normal] T-RUN-MRS-12: hands the login PATH to ShellSpec for --integration'
        When run env PATH="${_STUB_DIR}:${PATH}" SHELLSPEC="$_SHELLSPEC_STUB" "$BASH" "$SCRIPT" 'foo.spec.sh' '--integration'
        The output should start with "PATH=${_EIP_LOGIN_PATH}:"
        The status should be success
      End

      It '[Normal] T-RUN-MRS-13: hands the login PATH to ShellSpec for the system type'
        When run env PATH="${_STUB_DIR}:${PATH}" SPEC_SEARCH_ROOT="$TEMP_DIR" SHELLSPEC="$_SHELLSPEC_STUB" "$BASH" "$SCRIPT" 'system'
        The output should start with "PATH=${_EIP_LOGIN_PATH}:"
        The status should be success
      End

      It '[Normal] T-RUN-MRS-14: hands the login PATH to ShellSpec for an inherited SKIP_INTEGRATION_TESTS=0'
        When run env PATH="${_STUB_DIR}:${PATH}" SKIP_INTEGRATION_TESTS=0 SPEC_SEARCH_ROOT="$TEMP_DIR" SHELLSPEC="$_SHELLSPEC_STUB" "$BASH" "$SCRIPT" 'unit'
        The output should start with "PATH=${_EIP_LOGIN_PATH}:"
        The contents of file "$_LOGIN_CALLS_LOG" should equal "$_EIP_EXPECTED_LOGIN_FLAG"
        The status should be success
      End
    End

    Describe 'When: Error cases'
      It '[Error] T-RUN-MRS-15: fails without starting the login shell when an unknown type comes with --integration'
        When run env PATH="${_STUB_DIR}:${PATH}" SHELLSPEC="$_SHELLSPEC_STUB" "$BASH" "$SCRIPT" 'unknowntype' '--integration'
        The stderr should include "Unknown argument 'unknowntype'"
        The path "$_LOGIN_CALLS_LOG" should not be exist
        The status should equal 1
      End

      # No spec file resolved means nothing to run, so the login shell is not
      # started either (the fixture has no `nomatch` directory)
      It '[Error] T-RUN-MRS-24: starts no login shell when a glob given with --integration matches nothing'
        When run env PATH="${_STUB_DIR}:${PATH}" SPEC_SEARCH_ROOT="$TEMP_DIR" SHELLSPEC="$_SHELLSPEC_STUB" "$BASH" "$SCRIPT" 'nomatch/__tests__/unit/*.spec.sh' '--integration'
        The stderr should include "No spec files found matching glob 'nomatch/__tests__/unit/*.spec.sh'"
        The output should be blank
        The path "$_LOGIN_CALLS_LOG" should not be exist
        The status should be success
      End

      # Arithmetic evaluation of an inherited value would treat it as a variable
      # name or an expression, so only a string comparison may decide the mode
      Describe 'inherited SKIP_INTEGRATION_TESTS that is not a number'
        It '[Error] T-RUN-MRS-21: neither aborts nor starts the login shell for an inherited SKIP_INTEGRATION_TESTS=true'
          When run env PATH="${_STUB_DIR}:${PATH}" SKIP_INTEGRATION_TESTS=true SPEC_SEARCH_ROOT="$TEMP_DIR" SHELLSPEC="$_SHELLSPEC_STUB" "$BASH" "$SCRIPT" 'unit'
          The output should start with 'PATH='
          The output should not include "$_EIP_LOGIN_PATH"
          The stderr should not include 'unbound variable'
          The path "$_LOGIN_CALLS_LOG" should not be exist
          The status should be success
        End

        # The array has to be set: bash evaluates the subscript of a set array only
        # (an unset name such as `a` aborts first), and BASH_VERSINFO always is
        It '[Error] T-RUN-MRS-22: never executes a command embedded in an inherited SKIP_INTEGRATION_TESTS'
          _MRS_INJECTION_MARKER="${_STUB_DIR}/injected.marker"
          When run env PATH="${_STUB_DIR}:${PATH}" SKIP_INTEGRATION_TESTS="BASH_VERSINFO[\$(touch \"${_MRS_INJECTION_MARKER}\")]" SPEC_SEARCH_ROOT="$TEMP_DIR" SHELLSPEC="$_SHELLSPEC_STUB" "$BASH" "$SCRIPT" 'unit'
          The output should start with 'PATH='
          The path "$_MRS_INJECTION_MARKER" should not be exist
          The path "$_LOGIN_CALLS_LOG" should not be exist
          The status should be success
        End
      End
    End

    Describe 'When: Edge cases'
      It '[Edge] T-RUN-MRS-16: never starts the login shell for a plain unit run'
        When run env PATH="${_STUB_DIR}:${PATH}" SKIP_INTEGRATION_TESTS=1 SPEC_SEARCH_ROOT="$TEMP_DIR" SHELLSPEC="$_SHELLSPEC_STUB" "$BASH" "$SCRIPT" 'unit'
        The output should not include "$_EIP_LOGIN_PATH"
        The path "$_LOGIN_CALLS_LOG" should not be exist
        The status should be success
      End

      It '[Edge] T-RUN-MRS-17: starts the login shell exactly once for the system type with --integration'
        When run env PATH="${_STUB_DIR}:${PATH}" SPEC_SEARCH_ROOT="$TEMP_DIR" SHELLSPEC="$_SHELLSPEC_STUB" "$BASH" "$SCRIPT" 'system' '--integration'
        The output should start with "PATH=${_EIP_LOGIN_PATH}:"
        The contents of file "$_LOGIN_CALLS_LOG" should equal "$_EIP_EXPECTED_LOGIN_FLAG"
        The status should be success
      End

      # The fixture has no `e2e` directory, so the test type resolves no spec file
      It '[Edge] T-RUN-MRS-25: starts no login shell when the test type given with --integration matches nothing'
        When run env PATH="${_STUB_DIR}:${PATH}" SPEC_SEARCH_ROOT="$TEMP_DIR" SHELLSPEC="$_SHELLSPEC_STUB" "$BASH" "$SCRIPT" 'e2e' '--integration'
        The stderr should include "No spec files found for test type 'e2e'"
        The output should be blank
        The path "$_LOGIN_CALLS_LOG" should not be exist
        The status should be success
      End

      # Numerically equal to 0 but not the string 0: integration mode stays off
      It '[Edge] T-RUN-MRS-23: keeps the default mode for an inherited SKIP_INTEGRATION_TESTS=00'
        When run env PATH="${_STUB_DIR}:${PATH}" SKIP_INTEGRATION_TESTS=00 SPEC_SEARCH_ROOT="$TEMP_DIR" SHELLSPEC="$_SHELLSPEC_STUB" "$BASH" "$SCRIPT" 'unit'
        The output should start with 'PATH='
        The output should not include "$_EIP_LOGIN_PATH"
        The path "$_LOGIN_CALLS_LOG" should not be exist
        The status should be success
      End
    End
  End

  # When this suite itself runs with `--integration` (or `system`), the outer runner
  # exports SKIP_INTEGRATION_TESTS=0 and every subprocess inherits it. The examples
  # that expect the default mode therefore pin SKIP_INTEGRATION_TESTS=1 in their
  # `env`; otherwise they would start a real login shell. The Before hook below
  # simulates that outer export (each example runs in its own subshell, so it does
  # not leak)
  Describe 'outer integration mode does not leak into default-mode runs'
    Before 'setup_temp_specs'
    Before '_setup_login_path_stubs'
    Before 'export SKIP_INTEGRATION_TESTS=0'
    After 'teardown_shellspec_stub'
    After 'teardown_temp_specs'

    Describe 'When: Normal cases'
      It '[Normal] T-RUN-MRS-18: keeps the default mode for a pinned unit run when the outer suite exports SKIP_INTEGRATION_TESTS=0'
        When run env PATH="${_STUB_DIR}:${PATH}" SKIP_INTEGRATION_TESTS=1 SPEC_SEARCH_ROOT="$TEMP_DIR" SHELLSPEC="$_SHELLSPEC_STUB" "$BASH" "$SCRIPT" 'unit'
        The output should not include "$_EIP_LOGIN_PATH"
        The path "$_LOGIN_CALLS_LOG" should not be exist
        The status should be success
      End
    End

    Describe 'When: Error cases'
      It '[Error] T-RUN-MRS-19: fails without starting the login shell when an unknown type comes with a pinned SKIP_INTEGRATION_TESTS=1'
        When run env PATH="${_STUB_DIR}:${PATH}" SKIP_INTEGRATION_TESTS=1 SHELLSPEC="$_SHELLSPEC_STUB" "$BASH" "$SCRIPT" 'unknowntype'
        The stderr should include "Unknown argument 'unknowntype'"
        The path "$_LOGIN_CALLS_LOG" should not be exist
        The status should equal 1
      End
    End

    Describe 'When: Edge cases'
      It '[Edge] T-RUN-MRS-20: keeps the default mode for a pinned run without arguments when the outer suite exports SKIP_INTEGRATION_TESTS=0'
        When run env PATH="${_STUB_DIR}:${PATH}" SKIP_INTEGRATION_TESTS=1 SPEC_SEARCH_ROOT="$TEMP_DIR" SHELLSPEC="$_SHELLSPEC_STUB" "$BASH" "$SCRIPT"
        The output should start with 'PATH='
        The output should not include "$_EIP_LOGIN_PATH"
        The path "$_LOGIN_CALLS_LOG" should not be exist
        The status should be success
      End
    End
  End
  # main() leaves with return, not exit: a caller that runs it in its own shell
  # (`When call` here) keeps going afterwards. ShellSpec is the stub and
  # SKIP_INTEGRATION_TESTS is pinned to 1, so neither a real ShellSpec nor a login
  # shell starts
  Describe 'called in the caller shell'
    Before '_setup_in_process_main'
    After '_teardown_in_process_main'

    Describe 'When: Error cases'
      It '[Error] T-RUN-MRS-26: returns 1 for an unknown argument and lets the caller continue'
        When call _call_main_then_continue 'unknowntype'
        The output should equal 'continued after main: 1'
        The stderr should include "Unknown argument 'unknowntype'"
        The status should equal 1
      End
    End

    Describe 'When: Edge cases'
      Before '_setup_empty_search_root'
      After '_teardown_empty_search_root'

      It '[Edge] T-RUN-MRS-27: returns 0 without launching ShellSpec when no spec file is found and lets the caller continue'
        When call _call_main_then_continue 'unit'
        The output should equal 'continued after main: 0'
        The stderr should include "No spec files found for test type 'unit'"
        The status should equal 0
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

# A login shell's startup files print their own lines to stdout, so the probe's
# report has to be picked out by the marker. Pure function: called directly
Describe 'T-RUN-EMP: extract_marked_path()'
  Describe 'When: Normal cases'
    It '[Normal] T-RUN-EMP-01: returns the remainder of the marked line'
      When call extract_marked_path "$_EMP_MARKER" $'\n'"${_EMP_MARKER}${_EMP_REPORTED_PATH}"
      The output should equal "$_EMP_REPORTED_PATH"
      The status should be success
    End

    It '[Normal] T-RUN-EMP-02: leaves the startup output printed before the marked line out'
      When call extract_marked_path "$_EMP_MARKER" "${_LOGIN_PROFILE_NOISE}"$'\n\n'"${_EMP_MARKER}${_EMP_REPORTED_PATH}"
      The output should equal "$_EMP_REPORTED_PATH"
      The status should be success
    End

    It '[Normal] T-RUN-EMP-03: leaves the lines that follow the marked line out'
      When call extract_marked_path "$_EMP_MARKER" $'\n'"${_EMP_MARKER}${_EMP_REPORTED_PATH}"$'\nExec: aliases'
      The output should equal "$_EMP_REPORTED_PATH"
      The status should be success
    End

    # A startup file printing the marker's spelling must not shadow the line the
    # probe appended last
    It '[Normal] T-RUN-EMP-04: takes the last marked line when the output holds two'
      When call extract_marked_path "$_EMP_MARKER" $'\n'"${_EMP_MARKER}${_EMP_SHADOWED_PATH}"$'\n'"${_EMP_MARKER}${_EMP_REPORTED_PATH}"
      The output should equal "$_EMP_REPORTED_PATH"
      The status should be success
    End
  End

  # Without a marked line there is no telling where the report is. Returning
  # anything would let the caller take a progress line for the PATH
  Describe 'When: Error cases'
    It '[Error] T-RUN-EMP-05: fails when the output holds no marked line'
      When call extract_marked_path "$_EMP_MARKER" "$_LOGIN_PROFILE_NOISE"
      The output should be blank
      The status should be failure
    End

    # A marker inside a line is a progress line that merely contains its spelling
    It '[Error] T-RUN-EMP-06: fails when the marker appears only inside a line'
      When call extract_marked_path "$_EMP_MARKER" $'\nExec: '"${_EMP_MARKER}${_EMP_REPORTED_PATH}"
      The output should be blank
      The status should be failure
    End
  End

  Describe 'When: Edge cases'
    It '[Edge] T-RUN-EMP-07: fails for empty output'
      When call extract_marked_path "$_EMP_MARKER" ''
      The output should be blank
      The status should be failure
    End

    # The report did arrive, so this succeeds with nothing; what an empty report
    # means is for the caller to decide
    It '[Edge] T-RUN-EMP-08: returns nothing when the marked line carries no PATH'
      When call extract_marked_path "$_EMP_MARKER" "${_LOGIN_PROFILE_NOISE}"$'\n'"${_EMP_MARKER}"
      The output should be blank
      The status should be success
    End

    # Startup files that print nothing put the marked line first; it still counts
    # as a marker at the start of a line
    It '[Edge] T-RUN-EMP-09: accepts a marked line that is the first line'
      When call extract_marked_path "$_EMP_MARKER" "${_EMP_MARKER}${_EMP_REPORTED_PATH}"
      The output should equal "$_EMP_REPORTED_PATH"
      The status should be success
    End
  End
End

# An empty PATH entry names the current directory, so the reported PATH loses its
# empty entries before it replaces PATH. Pure function: called directly
Describe 'T-RUN-DPE: drop_empty_path_entries()'
  Describe 'When: Normal cases'
    It '[Normal] T-RUN-DPE-01: returns a PATH without empty entries as is'
      When call drop_empty_path_entries '/deckrd-stub/a:/deckrd-stub/b'
      The output should equal '/deckrd-stub/a:/deckrd-stub/b'
      The status should be success
    End

    It '[Normal] T-RUN-DPE-02: drops an empty entry in the middle'
      When call drop_empty_path_entries '/deckrd-stub/a::/deckrd-stub/b'
      The output should equal '/deckrd-stub/a:/deckrd-stub/b'
      The status should be success
    End

    It '[Normal] T-RUN-DPE-03: drops an empty entry at the start'
      When call drop_empty_path_entries ':/deckrd-stub/a:/deckrd-stub/b'
      The output should equal '/deckrd-stub/a:/deckrd-stub/b'
      The status should be success
    End

    It '[Normal] T-RUN-DPE-04: drops an empty entry at the end'
      When call drop_empty_path_entries '/deckrd-stub/a:/deckrd-stub/b:'
      The output should equal '/deckrd-stub/a:/deckrd-stub/b'
      The status should be success
    End

    It '[Normal] T-RUN-DPE-05: drops every empty entry when several are present'
      When call drop_empty_path_entries '/deckrd-stub/a::/deckrd-stub/b::/deckrd-stub/c'
      The output should equal '/deckrd-stub/a:/deckrd-stub/b:/deckrd-stub/c'
      The status should be success
    End
  End

  Describe 'When: Edge cases'
    It '[Edge] T-RUN-DPE-06: returns a single entry as is'
      When call drop_empty_path_entries '/deckrd-stub/a'
      The output should equal '/deckrd-stub/a'
      The status should be success
    End

    It '[Edge] T-RUN-DPE-07: returns nothing for an empty string'
      When call drop_empty_path_entries ''
      The output should be blank
      The status should be success
    End

    It '[Edge] T-RUN-DPE-08: returns nothing for a lone separator'
      When call drop_empty_path_entries ':'
      The output should be blank
      The status should be success
    End

    It '[Edge] T-RUN-DPE-09: returns nothing for two separators alone'
      When call drop_empty_path_entries '::'
      The output should be blank
      The status should be success
    End
  End
End

# Integration runs need the tools the user's startup files install. The login shell
# is replaced by a bash() function stub, so no real login shell ever starts
Describe 'T-RUN-EIP: ensure_integration_path()'
  Before '_setup_login_shell_stub'
  After '_teardown_login_shell_stub'

  Describe 'When: Normal cases'
    # The report replaces PATH instead of extending it: it is a superset of the
    # inherited PATH, and inherited entries left in front would shadow the tools
    # the startup files installed
    It '[Normal] T-RUN-EIP-01: replaces PATH with the PATH the login shell reports'
      When call ensure_integration_path
      The variable PATH should equal "$_EIP_LOGIN_PATH"
      The status should be success
    End

    # Taking the report wholesale would turn the progress lines into PATH entries
    Describe 'startup files write progress lines to stdout'
      Before '_setup_noisy_login_shell_stub'

      It '[Normal] T-RUN-EIP-04: keeps the startup output out of PATH'
        When call ensure_integration_path
        The variable PATH should equal "$_EIP_LOGIN_PATH"
        The status should be success
      End
    End

    # An empty entry names the current directory
    Describe 'startup files leave empty entries in PATH'
      Before '_setup_empty_entry_login_shell_stub'

      It '[Normal] T-RUN-EIP-05: drops the empty entries of the reported PATH'
        When call ensure_integration_path
        The variable PATH should equal "$_EIP_LOGIN_PATH_WITHOUT_EMPTY"
        The status should be success
      End
    End

    # Startup chains split their PATH additions between the login files and the
    # interactive rc; only a shell that is both reads both halves
    Describe 'start-up flag of the login shell'
      Before '_setup_flag_reporting_login_shell_stub'

      It '[Normal] T-RUN-EIP-06: starts the login shell as a login and interactive shell'
        When call ensure_integration_path
        The variable PATH should equal "${_EIP_FLAG_REPORT_PREFIX}${_EIP_EXPECTED_LOGIN_FLAG}"
        The status should be success
      End
    End

    # The other stubs ignore the probe body, so a probe that reports anything but
    # its own PATH would go unnoticed; this stub runs the body for real
    Describe 'the probe body runs for real'
      Before '_setup_probe_running_login_shell_stub'

      It '[Normal] T-RUN-EIP-09: adopts the PATH the probe body itself reports'
        When call ensure_integration_path
        The variable PATH should equal "$_EIP_PROBE_PATH"
        The status should be success
      End
    End
  End

  # Replacing PATH only helps real-machine tests; a login shell that cannot give a
  # usable report must not stop the ShellSpec run itself
  Describe 'When: Edge cases'
    Describe 'the login shell fails'
      Before '_setup_failing_login_shell_stub'

      It '[Edge] T-RUN-EIP-02: leaves PATH untouched and succeeds when the login shell fails'
        When call ensure_integration_path
        The variable PATH should equal "$_EIP_ORIG_PATH"
        The status should be success
      End
    End

    # Replacing PATH with an empty report would leave no command resolvable
    Describe 'the login shell prints nothing'
      Before '_setup_silent_login_shell_stub'

      It '[Edge] T-RUN-EIP-03: leaves PATH untouched when the login shell reports nothing'
        When call ensure_integration_path
        The variable PATH should equal "$_EIP_ORIG_PATH"
        The status should be success
      End
    End

    # Without a marked line there is no telling where the report is
    Describe 'no marked line comes back'
      Before '_setup_markerless_login_shell_stub'

      It '[Edge] T-RUN-EIP-07: leaves PATH untouched when no marked line is reported'
        When call ensure_integration_path
        The variable PATH should equal "$_EIP_ORIG_PATH"
        The status should be success
      End
    End

    # A report that is empty once its empty entries are dropped counts as no report
    Describe 'the report holds only empty entries'
      Before '_setup_all_empty_login_shell_stub'

      It '[Edge] T-RUN-EIP-08: leaves PATH untouched when the report holds only empty entries'
        When call ensure_integration_path
        The variable PATH should equal "$_EIP_ORIG_PATH"
        The status should be success
      End
    End
  End
End
