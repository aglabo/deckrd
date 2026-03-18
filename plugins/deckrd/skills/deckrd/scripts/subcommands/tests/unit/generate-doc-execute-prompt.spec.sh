#!/usr/bin/env bash
# generate-doc-execute-prompt.spec.sh - ShellSpec tests for ai-runner.sh integration in generate-doc.sh
#
# Copyright (c) 2026- atsushifx <https://github.com/atsushifx>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

# shellcheck disable=SC1091

_LIB_DIR="$(cd "${SHELLSPEC_PROJECT_ROOT}/plugins/deckrd/skills/deckrd/scripts/libs" && pwd)"
. "${_LIB_DIR}/bootstrap.sh"
unset _LIB_DIR


Include ../spec_helper.sh

# shellcheck source=../generate-doc.sh
. "${SUBCOMMANDS_DIR}/generate-doc.sh"

Describe "generate-doc.sh ai-runner.sh integration"

  Before "setup_deckrd_tmpdir"
  After "teardown_deckrd_tmpdir"

  Describe "ai-runner.sh loading"
    Describe "When: generate-doc.sh を source する"
      It "Then: [Normal] run_ai 関数が存在する"
        When call type run_ai
        The status should equal 0
        The output should include "run_ai"
      End

      It "Then: [Normal] validate_ai_model は ai-runner.sh 版（空引数でｴGﾗ臆[出力）"
        When call validate_ai_model ""
        The status should equal 1
        The output should include "Error:"
      End
    End
  End

  Describe "validate_ai_model (ai-runner.sh 版)"

    Describe "Given: 有効なﾓづﾞfﾙ去ｯ別子"
      Describe "When: validate_ai_model を呼ぶ"
        Parameters
          "sonnet"              "sonnet"
          "claude-3-opus"       "claude-3-opus"
          "openai/gpt-4o"       "openai/gpt-4o"
          "gpt-4-turbo"         "gpt-4-turbo"
          "gemini-1.5-pro"      "gemini-1.5-pro"
          "github/gpt-4.1"      "github/gpt-4.1"
          "opencode/big-pickle" "opencode/big-pickle"
        End

        It "Then: [Normal] $1 → exit 0､Astdout に $2 を返す"
          When call validate_ai_model "$1"
          The status should equal 0
          The output should equal "$2"
        End
      End
    End

    Describe "Given: 独自版では通っていた不正なﾓづﾞfﾙ去ｯ別子"
      Describe "When: validate_ai_model を呼ぶ"
        Parameters
          "12345"
          "unknown-provider/model"
          "anthropic/"
          "openai/"
        End

        It "Then: [Error] $1 → exit 1､Astdout に Error: を含む"
          When call validate_ai_model "$1"
          The status should equal 1
          The output should include "Error:"
        End
      End
    End

  End

  Describe "execute_prompt (run_ai 呼び出し確認)"

    setup_execute_prompt_tmpdir() {
      setup_deckrd_tmpdir
      mkdir -p "${DECKRD_TMPDIR}/assets/prompts"
      mkdir -p "${DECKRD_TMPDIR}/assets/templates"
      printf '%s\n' "test prompt" > "${DECKRD_TMPDIR}/assets/prompts/requirements.prompt.md"
      printf '%s\n' "test template" > "${DECKRD_TMPDIR}/assets/templates/requirements.template.md"
    }

    Before "setup_execute_prompt_tmpdir"
    After "teardown_deckrd_tmpdir"

    Describe "When: run_ai をﾓけbｸNして execute_prompt を呼ぶ"
      run_ai() {
        cat >/dev/null
        echo "MOCK_RUN_AI_CALLED:model=$1"
        return 0
      }

      It "Then: [Normal] run_ai が ai_model で呼ばれる"
        config_init ""
        config_set "ai_model" "sonnet"
        When call execute_prompt \
          "${DECKRD_TMPDIR}/assets/prompts/requirements.prompt.md" \
          "${DECKRD_TMPDIR}/assets/templates/requirements.template.md" \
          "ja" ""
        The status should equal 0
        The output should include "MOCK_RUN_AI_CALLED:model=sonnet"
      End
    End

  End

End
