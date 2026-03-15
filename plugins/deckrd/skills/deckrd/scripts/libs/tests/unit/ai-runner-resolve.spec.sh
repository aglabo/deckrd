#!/usr/bin/env bash
# ai-runner-resolve.spec.sh - ShellSpec tests for resolve_ai_cli
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

  Describe "ai-runner.sh loading"
    Describe "When: スクリプトを読み込む"
      It "Then: [Normal] resolve_ai_cli 関数が存在する"
        When call type resolve_ai_cli
        The status should equal 0
        The output should include "resolve_ai_cli"
      End

      It "Then: [Normal] run_ai 関数が存在する"
        When call type run_ai
        The status should equal 0
        The output should include "run_ai"
      End
    End
  End

  Describe "resolve_ai_cli"

    Describe "Given: provider プレフィックス付きモデル名"
      Describe "When: resolve_ai_cli を呼ぶ"
        Parameters
          "anthropic/claude-3-5"              "claude"
          "claude-3-opus"                     "claude"
          "openai/gpt-4o"                     "codex"
          "gpt-4-turbo"                       "codex"
          "o1-preview"                        "codex"
          "o3-mini"                           "codex"
          "google/gemini-2.0"                 "gemini"
          "gemini-1.5-pro"                    "gemini"
          "googleai/gemini-3"                 "gemini"
          "googleai/gemini-2.5"               "gemini"
          "github/gpt-4.1"                    "copilot"
          "github-copilot/gpt-5"              "copilot"
          "github-copilot/claude-sonnet-4.6"  "copilot"
          "github-copilot/grok-code-fast-1"   "copilot"
          "copilot/gpt-4.1"                   "copilot"
          "opencode/gpt-5"                    "opencode"
          "opencode/claude-sonnet-4-6"        "opencode"
          "opencode/big-pickle"               "opencode"
        End

        It "Then: [Normal] $1 -> $2 を返す"
          When call resolve_ai_cli "$1"
          The status should equal 0
          The output should equal "$2"
        End
      End
    End

    Describe "Given: エイリアスモデル名"
      Describe "When: resolve_ai_cli を呼ぶ"
        Parameters
          "default"   "claude"
          "sonnet"    "claude"
          "opus"      "claude"
          "haiku"     "claude"
          "sonnet-1m" "claude"
          "opusplan"  "claude"
        End

        It "Then: [Normal] $1 -> $2 を返す"
          When call resolve_ai_cli "$1"
          The status should equal 0
          The output should equal "$2"
        End
      End
    End

    Describe "Given: 不正なモデル名"
      Describe "When: resolve_ai_cli を呼ぶ"
        It "Then: [Error] 未知モデルは exit 1 を返す"
          When call resolve_ai_cli "unknown/model"
          The status should equal 1
        End

        It "Then: [Error] 引数なしは exit 1 を返す"
          When call resolve_ai_cli
          The status should equal 1
        End

        It "Then: [Error] 空文字列は exit 1 を返す"
          When call resolve_ai_cli ""
          The status should equal 1
        End
      End
    End

    Describe "Given: エッジケース入力 (glob マッチ境界)"
      Describe "When: resolve_ai_cli を呼ぶ"
        Describe "成功するケース"
          Parameters
            "anthropic/"         "claude"
            "openai/"            "codex"
            "opencode/"          "opencode"
            "copilot/"           "copilot"
            "claude-"            "claude"
            "o1-"                "codex"
            "claude-3 5"         "claude"
            "gpt-4;echo hacked"  "codex"
          End

          It "Then: [Edge] $1 -> $2 を返す"
            When call resolve_ai_cli "$1"
            The status should equal 0
            The output should equal "$2"
          End
        End

        Describe "失敗するケース"
          Parameters
            "anthropic"
            "anthropic-fake"
            "opencode-something"
            "github-something/model"
            "o3"
            "copilot"
            "gpt"
            "gemini"
            "12345"
          End

          It "Then: [Edge] $1 は exit 1 を返す"
            When call resolve_ai_cli "$1"
            The status should equal 1
          End
        End
      End
    End

  End

End
