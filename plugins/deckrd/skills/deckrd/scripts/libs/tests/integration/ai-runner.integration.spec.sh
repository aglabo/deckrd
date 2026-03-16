#!/usr/bin/env bash
# ai-runner.spec.sh - ShellSpec integration tests for run_ai with Mock CLI
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
  Describe "run_ai"
    # Common mock helper
    setup_mock_cli() {
      local name="$1"
      MOCK_BIN=$(mktemp -d)
      printf '#!/usr/bin/env bash\necho "MOCK_%s:$*"\n' "${name^^}" >"$MOCK_BIN/$name"
      chmod +x "$MOCK_BIN/$name"
      PATH="$MOCK_BIN:$PATH"
    }

    cleanup_mock() {
      rm -rf "$MOCK_BIN"
    }

    setup_mock_cli_sleep() {
      local name="$1"
      local secs="${2:-10}"
      MOCK_BIN=$(mktemp -d)
      printf '#!/usr/bin/env bash\nsleep %s\n' "$secs" >"$MOCK_BIN/$name"
      chmod +x "$MOCK_BIN/$name"
      PATH="$MOCK_BIN:$PATH"
    }

    setup_no_cli() {
      ORIG_PATH="$PATH"
      # shellcheck disable=SC2123
      PATH=/nonexistent
    }

    cleanup_no_cli() {
      PATH="$ORIG_PATH"
    }

    setup_claude_mock() { setup_mock_cli "claude"; }
    setup_codex_mock() { setup_mock_cli "codex"; }
    setup_gemini_mock() { setup_mock_cli "gemini"; }
    setup_copilot_mock() { setup_mock_cli "copilot"; }
    setup_opencode_mock() { setup_mock_cli "opencode"; }
    setup_timeout_mock() { setup_mock_cli_sleep "claude" 10; }

    Describe "Given: copilot 非対応モデル"
      Before 'setup_copilot_mock'
      After 'cleanup_mock'

      Describe "When: run_ai を呼ぶ"
        It "Then: [Error] copilot 非対応モデルは exit 1 と 'unsupported model' を返す"
          When call run_ai "copilot/unknown-model"
          The status should equal 1
          The output should equal "1"
          The error should include "unsupported model"
        End

        It "Then: [Error] github/unknown-model は exit 1 と 'unsupported model' を返す"
          When call run_ai "github/unknown-model"
          The status should equal 1
          The output should equal "1"
          The error should include "unsupported model"
        End

        It "Then: [Error] github-copilot/unknown-model は exit 1 と 'unsupported model' を返す"
          When call run_ai "github-copilot/unknown-model"
          The status should equal 1
          The output should equal "1"
          The error should include "unsupported model"
        End
      End
    End

    Describe "Given: claude CLI mock と claude 系モデル名"
      Before 'setup_claude_mock'
      After 'cleanup_mock'

      Describe "When: run_ai を呼ぶ"
        It "Then: [Normal] claude-3-opus は claude コマンドで --model claude-3-opus を渡す"
          When call run_ai "claude-3-opus"
          The status should equal 0
          The output should include "MOCK_CLAUDE:"
          The output should include "--model"
          The output should include "claude-3-opus"
        End

        It "Then: [Normal] sonnet エイリアスは --model sonnet を渡す"
          When call run_ai "sonnet"
          The status should equal 0
          The output should include "MOCK_CLAUDE:"
          The output should include "--model"
          The output should include "sonnet"
        End

        It "Then: [Normal] opus エイリアスは --model opus を渡す"
          When call run_ai "opus"
          The status should equal 0
          The output should include "MOCK_CLAUDE:"
          The output should include "--model"
          The output should include "opus"
        End

        It "Then: [Normal] haiku エイリアスは --model haiku を渡す"
          When call run_ai "haiku"
          The status should equal 0
          The output should include "MOCK_CLAUDE:"
          The output should include "--model"
          The output should include "haiku"
        End

        It "Then: [Normal] opusplan エイリアスは --thinking を渡す"
          When call run_ai "opusplan"
          The status should equal 0
          The output should include "MOCK_CLAUDE:"
          The output should include "--model"
          The output should include "opusplan"
          The output should include "--thinking"
        End

        It "Then: [Normal] sonnet-1m は --model sonnet と --context-window 1000000 を渡す"
          When call run_ai "sonnet-1m"
          The status should equal 0
          The output should include "MOCK_CLAUDE:"
          The output should include "--model"
          The output should include "sonnet"
          The output should include "--context-window"
          The output should include "1000000"
        End

        It "Then: [Normal] 完全モデル名 claude-sonnet-4-6 はそのまま渡す"
          When call run_ai "claude-sonnet-4-6"
          The status should equal 0
          The output should include "MOCK_CLAUDE:"
          The output should include "--model"
          The output should include "claude-sonnet-4-6"
        End

        It "Then: [Normal] default モデルは --model なし、-p のみ渡す"
          When call run_ai "default"
          The status should equal 0
          The output should include "MOCK_CLAUDE:"
          The output should include "-p"
          The output should not include "--model"
        End
      End
    End

    Describe "Given: codex CLI mock と openai 系モデル名"
      Before 'setup_codex_mock'
      After 'cleanup_mock'

      Describe "When: run_ai を呼ぶ"
        It "Then: [Normal] openai/gpt-4o は codex exec --model を渡す"
          When call run_ai "openai/gpt-4o"
          The status should equal 0
          The output should include "MOCK_CODEX:"
          The output should include "exec"
          The output should include "--model"
          The output should include "openai/gpt-4o"
        End
      End
    End

    Describe "Given: gemini CLI mock と google 系モデル名"
      Before 'setup_gemini_mock'
      After 'cleanup_mock'

      Describe "When: run_ai を呼ぶ"
        It "Then: [Normal] google/gemini-2.0 は gemini --model を渡す"
          When call run_ai "google/gemini-2.0"
          The status should equal 0
          The output should include "MOCK_GEMINI:"
          The output should include "--model"
          The output should include "google/gemini-2.0"
        End

        It "Then: [Normal] googleai/gemini-3 は gemini --model を渡す"
          When call run_ai "googleai/gemini-3"
          The status should equal 0
          The output should include "MOCK_GEMINI:"
          The output should include "--model"
          The output should include "googleai/gemini-3"
        End

        It "Then: [Normal] gemini-2.5-pro は gemini --model を渡す"
          When call run_ai "gemini-2.5-pro"
          The status should equal 0
          The output should include "MOCK_GEMINI:"
          The output should include "--model"
          The output should include "gemini-2.5-pro"
        End
      End
    End

    Describe "Given: copilot CLI mock と github 系モデル名"
      Before 'setup_copilot_mock'
      After 'cleanup_mock'

      Describe "When: run_ai を呼ぶ"
        It "Then: [Normal] github/gpt-4.1 は copilot suggest --model gpt-4.1 を渡す"
          When call run_ai "github/gpt-4.1"
          The status should equal 0
          The output should include "MOCK_COPILOT:"
          The output should include "suggest"
          The output should include "--model"
          The output should include "gpt-4.1"
        End

        It "Then: [Normal] github-copilot/gpt-4o は prefix を除去し --model gpt-4o を渡す"
          When call run_ai "github-copilot/gpt-4o"
          The status should equal 0
          The output should include "MOCK_COPILOT:"
          The output should include "--model"
          The output should include "gpt-4o"
          The output should not include "github-copilot"
        End

        It "Then: [Normal] github-copilot/gemini-2.0 は prefix を除去し --model gemini-2.0 を渡す"
          When call run_ai "github-copilot/gemini-2.0"
          The status should equal 0
          The output should include "MOCK_COPILOT:"
          The output should include "--model"
          The output should include "gemini-2.0"
          The output should not include "github-copilot"
        End
      End
    End

    Describe "Given: opencode CLI mock と opencode 系モデル名"
      Before 'setup_opencode_mock'
      After 'cleanup_mock'

      Describe "When: run_ai を呼ぶ"
        It "Then: [Normal] opencode/gpt-5 は opencode run --model を渡す"
          When call run_ai "opencode/gpt-5"
          The status should equal 0
          The output should include "MOCK_OPENCODE:"
          The output should include "run"
          The output should include "--model"
          The output should include "opencode/gpt-5"
        End
      End
    End

    Describe "Given: ランタイムエラー条件"
      Describe "When: CLI が存在しない"
        Before 'setup_no_cli'
        After 'cleanup_no_cli'

        Describe "When: run_ai を呼ぶ"
          It "Then: [Error] CLI が存在しない場合は exit 2 と 'CLI not found' を返す"
            When call run_ai 'claude-3-opus'
            The status should equal 2
            The output should equal "2"
            The error should include "CLI not found"
          End
        End
      End

      Describe "When: タイムアウト条件"
        Before 'setup_timeout_mock'
        After 'cleanup_mock'

        Describe "When: run_ai を呼ぶ"
          It "Then: [Error] タイムアウト時は exit 124 と 'timeout' を返す"
            When call run_ai 'sonnet' 1
            The status should equal 124
            The output should equal "124"
            The error should include "timeout"
          End
        End
      End

      Describe "When: エッジケース (claude mock)"
        Before 'setup_claude_mock'
        After 'cleanup_mock'

        Describe "When: run_ai を呼ぶ"
          It "Then: [Edge] 空 stdin でも exit 0 を返す"
            When call run_ai 'sonnet'
            The status should equal 0
            The output should include "MOCK_CLAUDE:"
          End

          It "Then: [Edge] タイムアウトに文字列を渡すと 'invalid time interval' を返す"
            When call run_ai 'sonnet' 'notanumber'
            The status should equal 125
            The output should include "invalid time interval"
          End
        End
      End
    End
  End
End
