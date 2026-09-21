#!/usr/bin/env bash
# runners/__tests__/unit/shellspec-exec.spec.sh
# @(#) : BDD unit tests for shellspec-exec.sh
#
# Copyright (c) 2026- atsushifx <https://github.com/atsushifx>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT
# shellcheck shell=bash
# shellspec-exec.spec.sh — BDD spec for shellspec-exec.sh

Include "${SHELLSPEC_PROJECT_ROOT}/runners/__tests__/spec_helper.sh"
Include "${SHELLSPEC_PROJECT_ROOT}/runners/exec/shellspec-exec.sh"

SCRIPT="${SHELLSPEC_PROJECT_ROOT}/runners/exec/shellspec-exec.sh"

# --- internal helpers -------------------------------------------------------

# 定数

# setup_temp_specs() が作るフィクスチャの spec ファイル総数
# (unit 6 / integration 1 / system 1 / functional 1)
_FIXTURE_SPEC_COUNT=9

# 関数

#
# @description Install a ShellSpec stub that prints its argv instead of running specs
# @sideeffect Sets _STUB_DIR and _SHELLSPEC_STUB
#
_setup_shellspec_stub() {
  _STUB_DIR="$(mktemp -d)"
  _SHELLSPEC_STUB="${_STUB_DIR}/shellspec-stub"
  {
    echo '#!/usr/bin/env bash'
    echo 'printf "[%s]" "$@"'
  } >"$_SHELLSPEC_STUB"
}

#
# @description Remove the stub installed by _setup_shellspec_stub()
# @sideeffect Deletes _STUB_DIR and unsets the stub variables
#
_teardown_shellspec_stub() {
  [[ -n "${_STUB_DIR:-}" ]] && rm -rf "$_STUB_DIR"
  unset _STUB_DIR _SHELLSPEC_STUB
}

Describe 'is_test_type()'
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

Describe 'is_spec_file()'
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

  Describe 'test type expansion'
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

    # 種別名が `__tests__/<type>/` として解決されることを確かめる
    Describe 'When: 正常系'
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

Describe 'parse_options()'
  Before 'SKIP_INTEGRATION_TESTS=1'

  Describe '--integration flag handling'
    It 'T-RUN-PO-01: removes --integration and sets SKIP_INTEGRATION_TESTS=0'
      When call parse_options 'unit' '--integration'
      The output should equal 'unit'
      The variable SKIP_INTEGRATION_TESTS should equal '0'
    End

    It 'T-RUN-PO-02: removes leading --integration flag'
      When call parse_options '--integration' 'unit'
      The output should equal 'unit'
    End
  End

  Describe 'passthrough of other options'
    It 'T-RUN-PO-03: passes --focus through unchanged'
      When call parse_options 'unit' '--focus'
      The output should include 'unit'
      The output should include '--focus'
    End

    It 'T-RUN-PO-04: returns empty output for no arguments'
      When call parse_options
      The output should equal ''
    End
  End
End

Describe 'is_spec_glob()'
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

  Describe 'glob expansion'
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

Describe 'resolve_spec_files()'
  Before 'SKIP_INTEGRATION_TESTS=1'

  Describe 'single spec file passthrough'
    It 'T-RUN-RSF-01: returns spec file unchanged for foo.spec.sh'
      When call resolve_spec_files 'foo.spec.sh'
      The output should equal 'foo.spec.sh'
      The status should be success
    End
  End

  Describe 'spec glob expansion'
    It 'T-RUN-RSF-02: expands glob pattern runners/libs/__tests__/unit/*.spec.sh'
      When call resolve_spec_files 'runners/libs/__tests__/unit/*.spec.sh'
      The output should include '.spec.sh'
      The status should be success
    End
  End

  Describe 'test type expansion'
    Before 'setup_temp_specs'
    After 'teardown_temp_specs'

    It 'T-RUN-RSF-03: expands unit to unit spec files'
      When call resolve_spec_files 'unit'
      The output should include '__tests__/unit'
      The status should be success
    End

    It 'T-RUN-RSF-04: sets SKIP_INTEGRATION_TESTS=0 for system'
      When call resolve_spec_files 'system'
      The variable SKIP_INTEGRATION_TESTS should equal '0'
      The output should include '__tests__/system'
      The status should be success
    End

    # 種別名が `__tests__/<type>/` として解決されることを確かめる
    Describe 'When: 正常系'
      It '[Normal] T-RUN-RSF-07: expands functional to the functional spec'
        When call resolve_spec_files 'functional'
        The output should include '__tests__/functional'
        The status should be success
      End

      # T-RUN-RSF-03 が stdout を見るのに対し、こちらは stderr を見る。
      # 種別が解決できないと "No spec files found" 警告が出る回帰を防ぐ
      It '[Normal] T-RUN-RSF-08: leaves stderr silent when unit specs are found'
        When call resolve_spec_files 'unit'
        The output should be present
        The stderr should be blank
      End
    End

    # フィクスチャに e2e ディレクトリは無い (spec_helper.sh の意図的な欠落)
    Describe 'When: 異常系'
      It '[Error] T-RUN-RSF-09: warns and succeeds when no spec matches the type'
        When call resolve_spec_files 'e2e'
        The stderr should include "No spec files found for test type 'e2e'"
        The output should be blank
        The status should be success
      End
    End
  End

  Describe 'error handling'
    It 'T-RUN-RSF-05: exits with failure for unknown test type'
      When call resolve_spec_files 'unknowntype'
      The stderr should include "Error: Unknown argument 'unknowntype'"
      The output should be blank
      The status should be failure
    End

    It 'T-RUN-RSF-06: reports missing arguments on stderr'
      When call resolve_spec_files
      The stderr should include 'Error: No arguments given.'
      The output should be blank
      The status should be failure
    End
  End
End

Describe 'main()'
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
    Before '_setup_shellspec_stub'
    After '_teardown_shellspec_stub'

    Describe 'When: 正常系'
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

    Describe 'When: エッジケース'
      It '[Edge] T-RUN-MRS-06: launches ShellSpec with the target alone when no option is given'
        When run env SHELLSPEC="$_SHELLSPEC_STUB" bash "$SCRIPT" 'foo.spec.sh'
        The output should equal '[foo.spec.sh]'
        The status should be success
      End
    End
  End
End
