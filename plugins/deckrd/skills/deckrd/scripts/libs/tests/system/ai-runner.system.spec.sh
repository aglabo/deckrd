#!/usr/bin/env bash
# ai-runner.spec.sh - ShellSpec system tests for run_ai with real CLI
#
# Copyright (c) 2026- atsushifx <https://github.com/atsushifx>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

_LIB_DIR="$(cd "${SHELLSPEC_PROJECT_ROOT}/plugins/deckrd/skills/deckrd/scripts/libs" && pwd)"
# shellcheck disable=SC1091
. "${_LIB_DIR}/bootstrap.sh"
unset _LIB_DIR

Include ../spec_helper.sh

SCRIPT="${DECKRD_LIB_DIR}/ai-runner.sh"

# shellcheck disable=SC1090
. "$SCRIPT"

Describe "ai-runner.sh"
  Describe "実機テスト (claude)"
    Skip if "integration tests are disabled" [ "${SKIP_INTEGRATION_TESTS:-1}" = "1" ]
    Skip if "claude is not installed" ! command -v claude >/dev/null 2>&1

    It "sonnet エイリアスで実際に応答を返す"
      When run bash -c "
          unset CLAUDECODE
          . \"$SCRIPT\"
          echo \"Say 'OK' and nothing else.\" | run_ai 'sonnet' 60
        "
      The status should equal 0
      The output should not equal ""
    End
  End

  Describe "実機テスト"
    Skip if "integration tests are disabled" [ "${SKIP_INTEGRATION_TESTS:-1}" = "1" ]

    Parameters
      "codex" "codex" "gpt-5" 60
      # "gemini" "gemini" "gemini-2.5-pro" 60   # quota limit
      # "copilot" "copilot" "github/gpt-4.1" 60 # too many requests
      "opencode" "opencode" "opencode/gpt-5" 60
    End

    It "$1 で $3 モデルが実際に応答を返す"
      Skip if "$2 is not installed" ! command -v "$2" >/dev/null 2>&1
      When run bash -c "
          . \"$SCRIPT\"
          echo \"Say 'OK' and nothing else.\" | run_ai '$3' $4
        "
      The status should equal 0
      The output should not equal ""
    End
  End
End
