#!/usr/bin/env bash
# ai-runner.spec.sh - ShellSpec functional tests for run_ai argument validation
#
# Copyright (c) 2026- atsushifx <https://github.com/atsushifx>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

# shellcheck disable=SC1090

_RUNTIME_BOOTSTRAP="${SHELLSPEC_PROJECT_ROOT}/plugins/_runtime/libs/bootstrap.lib.sh"
. "$_RUNTIME_BOOTSTRAP"
unset _RUNTIME_BOOTSTRAP

Include ../spec_helper.sh

SCRIPT="${DECKRD_LIB_DIR}/ai-runner.sh"
. "$SCRIPT"

Describe "ai-runner.sh"
  Describe "run_ai"
    Describe "Given: 不正な引数"
      Describe "When: run_ai を呼ぶ"
        It "Then: [Error] モデル引数なしは exit 1 と 'model is required' を返す"
          When call run_ai
          The status should equal 1
          The output should equal "1"
          The error should include "model is required"
        End

        It "Then: [Error] 未知モデルは exit 1 と 'unknown model' を返す"
          When call run_ai "unknown/model"
          The status should equal 1
          The output should equal "1"
          The error should include "unknown model"
        End
      End
    End
  End
End
