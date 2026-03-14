#!/usr/bin/env bash
# ai-runner-build.spec.sh - ShellSpec tests for _build_ai_command
#
# Copyright (c) 2026- atsushifx <https://github.com/atsushifx>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

Include spec_helper.sh

SCRIPT="${DECKRD_LIB_DIR}/ai-runner.sh"

# shellcheck disable=SC1090
. "$SCRIPT"

Describe "ai-runner.sh"

  Describe "_build_ai_command"

    Describe "Given: claude CLI とモデル名"
      Describe "When: _build_ai_command を呼ぶ"
        Parameters
          "claude"  "claude-3-opus"  "--model"  "claude-3-opus"
          "claude"  "sonnet"         "--model"  "sonnet"
          "claude"  "opus"           "--model"  "opus"
          "claude"  "haiku"          "--model"  "haiku"
          "claude"  "opusplan"       "--model"  "opusplan"
        End

        It "Then: [Normal] cmd に $3 $4 が含まれる"
          _cmd=()
          When call _build_ai_command "$1" "$2" _cmd
          The status should equal 0
          The variable '_cmd[*]' should include "$3"
          The variable '_cmd[*]' should include "$4"
        End
      End
    End

    Describe "Given: 特殊オプションを持つモデル名"
      Describe "When: _build_ai_command を呼ぶ"
        It "Then: [Normal] opusplan は --thinking を含む"
          _cmd=()
          When call _build_ai_command "claude" "opusplan" _cmd
          The status should equal 0
          The variable '_cmd[*]' should include "--thinking"
        End

        It "Then: [Normal] sonnet-1m は --context-window 1000000 を含む"
          _cmd=()
          When call _build_ai_command "claude" "sonnet-1m" _cmd
          The status should equal 0
          The variable '_cmd[*]' should include "--context-window"
          The variable '_cmd[*]' should include "1000000"
        End

        It "Then: [Normal] default は --model を含まない"
          _cmd=()
          When call _build_ai_command "claude" "default" _cmd
          The status should equal 0
          The variable '_cmd[*]' should not include "--model"
        End
      End
    End

    Describe "Given: copilot CLI とプレフィックス付きモデル名"
      Describe "When: _build_ai_command を呼ぶ"
        It "Then: [Normal] github-copilot/gpt-4o -> model は gpt-4o (prefix 除去)"
          _cmd=()
          When call _build_ai_command "copilot" "github-copilot/gpt-4o" _cmd
          The status should equal 0
          The variable '_cmd[*]' should include "gpt-4o"
          The variable '_cmd[*]' should not include "github-copilot"
        End
      End
    End

    Describe "Given: copilot CLI と非対応モデル名"
      Describe "When: _build_ai_command を呼ぶ"
        It "Then: [Error] exit 1 を返す"
          _cmd=()
          When call _build_ai_command "copilot" "unknown-model" _cmd
          The status should equal 1
        End
      End
    End

  End

End
