#!/usr/bin/env bash
# runners/tests/unit/run-shellspec.spec.sh
# @(#) : BDD unit tests for run-shellspec.sh
#
# Copyright (c) 2026- atsushifx <https://github.com/atsushifx>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT
# shellcheck shell=bash
# run-shellspec.spec.sh — BDD spec for run-shellspec.sh

Include "${SHELLSPEC_PROJECT_ROOT}/runners/__tests__/spec_helper.sh"
Include "${SHELLSPEC_PROJECT_ROOT}/runners/run-shellspec.sh"

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
      The output should include 'tests/unit'
      The status should be success
    End

    It 'T-RUN-GSF-03: does not include integration files for unit'
      When call get_spec_files 'unit'
      The output should not include 'tests/integration'
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
    It 'T-RUN-ISG-01: returns success for runners/libs/tests/unit/*.spec.sh'
      When call is_spec_glob 'runners/libs/tests/unit/*.spec.sh'
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
    It 'T-RUN-ESG-01: returns matching spec files for runners/libs/tests/unit/*.spec.sh'
      When call expand_spec_glob 'runners/libs/tests/unit/*.spec.sh'
      The output should include '.spec.sh'
      The status should be success
    End

    It 'T-RUN-ESG-02: exits with 0 and warns for non-matching glob'
      When call expand_spec_glob 'runners/libs/tests/unit/nonexistent*.spec.sh'
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
    It 'T-RUN-RSF-02: expands glob pattern runners/libs/tests/unit/*.spec.sh'
      When call resolve_spec_files 'runners/libs/tests/unit/*.spec.sh'
      The output should include '.spec.sh'
      The status should be success
    End
  End

  Describe 'test type expansion'
    Before 'setup_temp_specs'
    After 'teardown_temp_specs'

    It 'T-RUN-RSF-03: expands unit to unit spec files'
      When call resolve_spec_files 'unit'
      The output should include 'tests/unit'
      The status should be success
    End

    It 'T-RUN-RSF-04: sets SKIP_INTEGRATION_TESTS=0 for system'
      When call resolve_spec_files 'system'
      The variable SKIP_INTEGRATION_TESTS should equal '0'
      The output should include 'tests/system'
      The status should be success
    End
  End

  Describe 'error handling'
    It 'T-RUN-RSF-05: exits with failure for unknown test type'
      When call resolve_spec_files 'unknowntype'
      The stderr should include 'Error'
      The status should be failure
    End
  End
End
