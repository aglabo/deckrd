#!/usr/bin/env bash
# runners/libs/tests/unit/args-normalize.spec.sh
# @(#) : BDD unit tests for args normalization functions in get-filelist.sh
#
# Copyright (c) 2026- atsushifx <https://github.com/atsushifx>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT
# shellcheck shell=bash
# args-normalize.spec.sh — BDD spec for argument normalization functions in get-filelist.sh

Include "${SHELLSPEC_PROJECT_ROOT}/runners/libs/get-filelist.sh"

Describe 'args_to_filter()'
  Describe '* wildcard conversion'
    It 'converts trailing wildcard init* to init.*'
      When call args_to_filter "init*"
      The output should equal "init.*"
      The status should be success
    End
  End

  Describe '? wildcard conversion'
    It 'converts single-char wildcard init? to init.'
      When call args_to_filter "init?"
      The output should equal "init."
      The status should be success
    End
  End

  Describe 'no-glob and path patterns'
    It 'returns kv-store unchanged (no glob)'
      When call args_to_filter "kv-store"
      The output should equal "kv-store"
      The status should be success
    End

    It 'converts path with wildcard unit/init* to unit/init.*'
      When call args_to_filter "unit/init*"
      The output should equal "unit/init.*"
      The status should be success
    End
  End
End

Describe 'normalize_path()'
  Describe 'backslash to forward slash conversion'
    It 'converts backslash separator to forward slash'
      When call normalize_path 'runners\libs\tests'
      The output should equal 'runners/libs/tests'
      The status should be success
    End

    It 'converts spec file path with multiple backslashes'
      When call normalize_path 'runners\libs\tests\unit\kv-store.spec.sh'
      The output should equal 'runners/libs/tests/unit/kv-store.spec.sh'
      The status should be success
    End

    It 'leaves forward slash path unchanged'
      When call normalize_path 'runners/libs/tests'
      The output should equal 'runners/libs/tests'
      The status should be success
    End

    It 'leaves plain filename unchanged'
      When call normalize_path 'kv-store.spec.sh'
      The output should equal 'kv-store.spec.sh'
      The status should be success
    End
  End
End

Describe 'is_glob_pattern()'
  Describe 'glob patterns'
    It 'returns success for trailing wildcard init*'
      When call is_glob_pattern 'init*'
      The status should be success
    End

    It 'returns success for single-char wildcard init?'
      When call is_glob_pattern 'init?'
      The status should be success
    End

    It 'returns success for path with wildcard unit/init*'
      When call is_glob_pattern 'unit/init*'
      The status should be success
    End
  End

  Describe 'non-glob patterns'
    It 'returns failure for plain name kv-store'
      When call is_glob_pattern 'kv-store'
      The status should be failure
    End

    It 'returns failure for full file path without glob'
      When call is_glob_pattern 'runners/libs/tests/unit/kv-store.spec.sh'
      The status should be failure
    End
  End
End
