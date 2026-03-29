#!/usr/bin/env bash
# ai-runner-model.spec.sh - ShellSpec tests for resolve_ai_model
#
# Copyright (c) 2026- atsushifx <https://github.com/atsushifx>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

# shellcheck disable=SC1090
# shellcheck disable=SC2287

_RUNTIME_BOOTSTRAP="${SHELLSPEC_PROJECT_ROOT}/plugins/_runtime/libs/bootstrap.lib.sh"
. "$_RUNTIME_BOOTSTRAP"
unset _RUNTIME_BOOTSTRAP

Include ../spec_helper.sh

SCRIPT="${DECKRD_LIB_DIR}/ai-runner.sh"
. "$SCRIPT"

Describe "ai-runner.sh"
  Describe "ai-runner.sh loading"
    Describe "When: スクリプトを読み込む"
      It "Then: [Normal] resolve_ai_model 関数が存在する"
        When call type resolve_ai_model
        The status should equal 0
        The output should include "resolve_ai_model"
      End
    End
  End

  Describe "resolve_ai_model"
    Describe "Given: anthropic プレフィックス付きモデル名"
      Describe "When: resolve_ai_model を呼ぶ"
        Parameters
          "anthropic/claude-3-5" "claude-3-5"
        End

        It "Then: [Normal] $1 -> $2 を返す"
          When call resolve_ai_model "$1"
          The status should equal 0
          The output should equal "$2"
        End
      End
    End

    Describe "Given: claude プレフィックス付きモデル名"
      Describe "When: resolve_ai_model を呼ぶ"
        Parameters
          "claude-3-opus" "claude-3-opus"
        End

        It "Then: [Normal] $1 -> $2 を返す"
          When call resolve_ai_model "$1"
          The status should equal 0
          The output should equal "$2"
        End
      End
    End

    Describe "Given: claude エイリアスモデル名"
      Describe "When: resolve_ai_model を呼ぶ"
        Parameters
          "sonnet" "sonnet"
          "opus" "opus"
          "haiku" "haiku"
          "default" "default"
          "sonnet-1m" "sonnet-1m"
          "opusplan" "opusplan"
        End

        It "Then: [Normal] $1 -> $2 を返す"
          When call resolve_ai_model "$1"
          The status should equal 0
          The output should equal "$2"
        End
      End
    End

    Describe "Given: openai プレフィックス付きモデル名"
      Describe "When: resolve_ai_model を呼ぶ"
        Parameters
          "openai/gpt-4o" "gpt-4o"
          "openai/o1-preview" "o1-preview"
          "openai/o3-mini" "o3-mini"
        End

        It "Then: [Normal] $1 -> $2 を返す"
          When call resolve_ai_model "$1"
          The status should equal 0
          The output should equal "$2"
        End
      End
    End

    Describe "Given: gpt/o1/o3 系プレフィックス付きモデル名"
      Describe "When: resolve_ai_model を呼ぶ"
        Parameters
          "gpt-4-turbo" "gpt-4-turbo"
          "o1-preview" "o1-preview"
          "o3-mini" "o3-mini"
        End

        It "Then: [Normal] $1 -> $2 を返す"
          When call resolve_ai_model "$1"
          The status should equal 0
          The output should equal "$2"
        End
      End
    End

    Describe "Given: googleai/google プレフィックス付きモデル名"
      Describe "When: resolve_ai_model を呼ぶ"
        Parameters
          "googleai/gemini-3" "gemini-3"
          "google/gemini-2.0" "gemini-2.0"
        End

        It "Then: [Normal] $1 -> $2 を返す"
          When call resolve_ai_model "$1"
          The status should equal 0
          The output should equal "$2"
        End
      End
    End

    Describe "Given: gemini プレフィックス付きモデル名"
      Describe "When: resolve_ai_model を呼ぶ"
        Parameters
          "gemini-1.5-pro" "gemini-1.5-pro"
        End

        It "Then: [Normal] $1 -> $2 を返す"
          When call resolve_ai_model "$1"
          The status should equal 0
          The output should equal "$2"
        End
      End
    End

    Describe "Given: copilot 系プレフィックス付きモデル名"
      Describe "When: resolve_ai_model を呼ぶ"
        Parameters
          "github/gpt-4.1" "gpt-4.1"
          "github-copilot/gpt-5-mini" "gpt-5-mini"
          "copilot/claude-sonnet-4.6" "claude-sonnet-4.6"
          "github-copilot/grok-code-fast-1" "grok-code-fast-1"
        End

        It "Then: [Normal] $1 -> $2 を返す"
          When call resolve_ai_model "$1"
          The status should equal 0
          The output should equal "$2"
        End
      End
    End

    Describe "Given: opencode プレフィックス付きモデル名（形式不問）"
      Describe "When: resolve_ai_model を呼ぶ"
        Parameters
          "opencode/big-pickle" "big-pickle"
          "opencode/gpt-5" "gpt-5"
        End

        It "Then: [Normal] $1 -> $2 を返す"
          When call resolve_ai_model "$1"
          The status should equal 0
          The output should equal "$2"
        End
      End
    End

    Describe "Given: モデル部分が空のプレフィックス"
      Describe "When: resolve_ai_model を呼ぶ"
        Parameters
          "anthropic/"
          "openai/"
          "copilot/"
          "opencode/"
        End

        It "Then: [Error] $1 は exit 1 を返す"
          When call resolve_ai_model "$1"
          The status should equal 1
          The output should include "Error:"
        End
      End
    End

    Describe "Given: provider のモデル形式不一致"
      Describe "When: resolve_ai_model を呼ぶ"
        Parameters
          "anthropic/gpt-4o"
          "openai/claude-3"
          "google/gpt-4"
          "github/unknown-model"
        End

        It "Then: [Error] $1 は exit 1 を返す"
          When call resolve_ai_model "$1"
          The status should equal 1
          The output should include "Error:"
        End
      End
    End

    Describe "Given: 未知のモデル"
      Describe "When: resolve_ai_model を呼ぶ"
        Parameters
          "unknown/model"
          "12345"
        End

        It "Then: [Error] $1 は exit 1 を返す"
          When call resolve_ai_model "$1"
          The status should equal 1
          The output should include "Error:"
        End
      End
    End

    Describe "Given: 空引数"
      Describe "When: resolve_ai_model を呼ぶ"
        It "Then: [Error] 引数なしは exit 1 を返す"
          When call resolve_ai_model
          The status should equal 1
          The output should include "Error:"
        End

        It "Then: [Error] 空文字列は exit 1 を返す"
          When call resolve_ai_model ""
          The status should equal 1
          The output should include "Error:"
        End
      End
    End
  End
End
