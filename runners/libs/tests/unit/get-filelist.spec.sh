#!/usr/bin/env bash
# runners/libs/tests/unit/get-filelist.spec.sh
# @(#) : BDD unit tests for get-filelist.sh
#
# Copyright (c) 2026- atsushifx <https://github.com/atsushifx>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT
# shellcheck shell=bash
# get-filelist.spec.sh — BDD spec for get-filelist.sh

Include "${SHELLSPEC_PROJECT_ROOT}/runners/libs/tests/spec_helper.sh"
Include "${SHELLSPEC_PROJECT_ROOT}/runners/libs/get-filelist.sh"

Describe 'get_filelist()'
  Before 'setup_temp_specs'
  After 'teardown_temp_specs'

  Describe 'フィルタなし'
    It 'returns all spec files'
      When call get_filelist "$TEMP_DIR" "*.spec.sh"
      The output should include '.spec.sh'
      The status should be success
    End

    It 'output has no backslashes'
      When call get_filelist "$TEMP_DIR" "*.spec.sh"
      # shellcheck disable=SC1003
      The output should not include '\'
      The status should be success
    End
  End

  Describe 'str_filter（スラッシュなし引数）'
    It 'filters by plain string kv-store'
      When call get_filelist "$TEMP_DIR" "*.spec.sh" "kv-store"
      The output should include 'kv-store'
      The output should not include 'args-normalize'
      The status should be success
    End

    It 'filters by glob init*'
      When call get_filelist "$TEMP_DIR" "*.spec.sh" "init*"
      The output should include 'init'
      The status should be success
    End
  End

  Describe 'dir_filter（スラッシュあり引数）'
    It 'restricts to runners/ directory'
      When call get_filelist "$TEMP_DIR" "*.spec.sh" "runners/"
      The output should include 'runners/'
      The output should not include 'plugins/'
      The status should be success
    End

    It 'restricts to runners/libs/tests/unit path'
      When call get_filelist "$TEMP_DIR" "*.spec.sh" "runners/libs/tests/unit"
      The output should include 'tests/unit'
      The output should not include 'integration'
      The status should be success
    End

    It 'restricts to tests/unit path filter'
      When call get_filelist "$TEMP_DIR" "*.spec.sh" "tests/unit"
      The output should include 'tests/unit'
      The output should not include 'integration'
      The status should be success
    End
  End

  Describe 'dir_filter + str_filter 組み合わせ'
    It 'combines runners/ + kv-store'
      When call get_filelist "$TEMP_DIR" "*.spec.sh" "runners/" "kv-store"
      The output should include 'kv-store'
      The output should not include 'plugins/'
      The status should be success
    End
  End

  Describe 'バックスラッシュパス対応'
    It 'handles backslash dir_filter'
      When call get_filelist "$TEMP_DIR" "*.spec.sh" 'runners\libs\tests\unit'
      The output should include 'tests/unit'
      The output should not include 'integration'
      The status should be success
    End
  End

  Describe 'ファイルなし'
    It 'returns empty for nonexistent filter'
      When call get_filelist "$TEMP_DIR" "*.spec.sh" "nonexistent-filter-xyz"
      The output should equal ''
      The status should be success
    End
  End
End
