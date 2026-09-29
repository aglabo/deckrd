#!/usr/bin/env bash
# ai-runner.spec.sh - ShellSpec integration tests for run_ai with Mock CLI
#
# Copyright (c) 2026- atsushifx <https://github.com/atsushifx>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

# shellcheck disable=SC1090

_RUNTIME_BOOTSTRAP="${SHELLSPEC_PROJECT_ROOT}/skills/deckrd/skills/deckrd/scripts/libs/bootstrap.lib.sh"
. "$_RUNTIME_BOOTSTRAP"
unset _RUNTIME_BOOTSTRAP

Include ../spec_helper.sh

SCRIPT="${DECKRD_LIB_DIR}/ai-runner.lib.sh"
. "$SCRIPT"

Describe "ai-runner.sh"
  Describe "T-LIB-RAI: run_ai"
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

    # setup_mock_cli_silent - exit 0 を返しながら stdout へ何も書かない CLI を置く。
    # codex-cli 0.157 系が起動拒否を exit 0 + 空 stdout で返す挙動をそのまま再現する
    setup_mock_cli_silent() {
      local name="$1"
      MOCK_BIN=$(mktemp -d)
      printf '#!/usr/bin/env bash\nexit 0\n' >"$MOCK_BIN/$name"
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

    # run_ai_with_empty_stdin - stdin を 0 バイト (/dev/null) に固定して run_ai を呼ぶ
    #
    # ShellSpec は `When call` の stdin を実行環境からそのまま引き継ぐ。stdin が空であること
    # 自体が前提のケースは、ここで明示的に固定しないと前提が実行環境任せになる。
    #
    # @arg $@  run_ai へそのまま渡す引数
    run_ai_with_empty_stdin() {
      run_ai "$@" </dev/null
    }

    setup_claude_mock() { setup_mock_cli "claude"; }
    setup_codex_mock() { setup_mock_cli "codex"; }
    setup_gemini_mock() { setup_mock_cli "gemini"; }
    setup_copilot_mock() { setup_mock_cli "copilot"; }
    setup_opencode_mock() { setup_mock_cli "opencode"; }
    setup_silent_codex_mock() { setup_mock_cli_silent "codex"; }
    setup_timeout_mock() { setup_mock_cli_sleep "claude" 10; }

    Describe "Given: copilot 非対応モデル"
      Before 'setup_copilot_mock'
      After 'cleanup_mock'

      Describe "When: run_ai を呼ぶ"
        It "Then: [Error] T-LIB-RAI-01: copilot 非対応モデルは exit 1 と 'unsupported model' を返す"
          When call run_ai "copilot/unknown-model"
          The status should equal 1
          The output should equal ""
          The error should include "unsupported model"
        End

        It "Then: [Error] T-LIB-RAI-02: github/unknown-model は exit 1 と 'unsupported model' を返す"
          When call run_ai "github/unknown-model"
          The status should equal 1
          The output should equal ""
          The error should include "unsupported model"
        End

        It "Then: [Error] T-LIB-RAI-03: github-copilot/unknown-model は exit 1 と 'unsupported model' を返す"
          When call run_ai "github-copilot/unknown-model"
          The status should equal 1
          The output should equal ""
          The error should include "unsupported model"
        End
      End
    End

    Describe "Given: claude CLI mock と claude 系モデル名"
      Before 'setup_claude_mock'
      After 'cleanup_mock'

      Describe "When: run_ai を呼ぶ"
        It "Then: [Normal] T-LIB-RAI-04: claude-3-opus は claude コマンドで --model claude-3-opus を渡す"
          When call run_ai_piped "claude-3-opus"
          The status should equal 0
          The output should include "MOCK_CLAUDE:"
          The output should include "--model"
          The output should include "claude-3-opus"
        End

        It "Then: [Normal] T-LIB-RAI-05: sonnet エイリアスは --model sonnet を渡す"
          When call run_ai_piped "sonnet"
          The status should equal 0
          The output should include "MOCK_CLAUDE:"
          The output should include "--model"
          The output should include "sonnet"
        End

        It "Then: [Normal] T-LIB-RAI-06: opus エイリアスは --model opus を渡す"
          When call run_ai_piped "opus"
          The status should equal 0
          The output should include "MOCK_CLAUDE:"
          The output should include "--model"
          The output should include "opus"
        End

        It "Then: [Normal] T-LIB-RAI-07: haiku エイリアスは --model haiku を渡す"
          When call run_ai_piped "haiku"
          The status should equal 0
          The output should include "MOCK_CLAUDE:"
          The output should include "--model"
          The output should include "haiku"
        End

        It "Then: [Normal] T-LIB-RAI-08: opusplan エイリアスは --thinking を渡す"
          When call run_ai_piped "opusplan"
          The status should equal 0
          The output should include "MOCK_CLAUDE:"
          The output should include "--model"
          The output should include "opusplan"
          The output should include "--thinking"
        End

        It "Then: [Normal] T-LIB-RAI-09: sonnet-1m は --model sonnet と --context-window 1000000 を渡す"
          When call run_ai_piped "sonnet-1m"
          The status should equal 0
          The output should include "MOCK_CLAUDE:"
          The output should include "--model"
          The output should include "sonnet"
          The output should include "--context-window"
          The output should include "1000000"
        End

        It "Then: [Normal] T-LIB-RAI-10: 完全モデル名 claude-sonnet-4-6 はそのまま渡す"
          When call run_ai_piped "claude-sonnet-4-6"
          The status should equal 0
          The output should include "MOCK_CLAUDE:"
          The output should include "--model"
          The output should include "claude-sonnet-4-6"
        End

        It "Then: [Normal] T-LIB-RAI-11: default モデルは --model なし、-p のみ渡す"
          When call run_ai_piped "default"
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
        It "Then: [Normal] T-LIB-RAI-12: openai/gpt-4o は codex exec --model を渡す"
          When call run_ai_piped "openai/gpt-4o"
          The status should equal 0
          The output should include "MOCK_CODEX:"
          The output should include "exec"
          The output should include "--model"
          The output should include "openai/gpt-4o"
        End

        # codex exec は git リポジトリ外・非 trusted な cwd だと起動を拒む。run_ai は cd
        # しないので、--skip-git-repo-check が argv まで届かないとリポジトリ外の呼び出しが必ず落ちる。
        # 隔離フラグは 2 つある。--ignore-user-config はユーザー設定の MCP サーバ起動を止める
        # (落ちると MCP サーバが呼び出し元 cwd を掴む)。-s read-only は CLI に書き込み権限を渡さない。
        # "-s" は "--skip-git-repo-check" の部分文字列としても一致してしまうため、
        # 値を取るフラグは値 (read-only / never) で確かめる
        It "Then: [Normal] T-LIB-RAI-24: codex には --skip-git-repo-check / --ignore-user-config / -s read-only / --color never を渡す"
          When call run_ai_piped "openai/gpt-4o"
          The status should equal 0
          The output should include "MOCK_CODEX:"
          The output should include "--skip-git-repo-check"
          The output should include "--ignore-user-config"
          The output should include "read-only"
          The output should include "--color"
          The output should include "never"
        End
      End
    End

    Describe "Given: gemini CLI mock と google 系モデル名"
      Before 'setup_gemini_mock'
      After 'cleanup_mock'

      Describe "When: run_ai を呼ぶ"
        It "Then: [Normal] T-LIB-RAI-13: google/gemini-2.0 は gemini --model を渡す"
          When call run_ai_piped "google/gemini-2.0"
          The status should equal 0
          The output should include "MOCK_GEMINI:"
          The output should include "--model"
          The output should include "google/gemini-2.0"
        End

        It "Then: [Normal] T-LIB-RAI-14: googleai/gemini-3 は gemini --model を渡す"
          When call run_ai_piped "googleai/gemini-3"
          The status should equal 0
          The output should include "MOCK_GEMINI:"
          The output should include "--model"
          The output should include "googleai/gemini-3"
        End

        It "Then: [Normal] T-LIB-RAI-15: gemini-2.5-pro は gemini --model を渡す"
          When call run_ai_piped "gemini-2.5-pro"
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
        It "Then: [Normal] T-LIB-RAI-16: github/gpt-4.1 は copilot --model gpt-4.1 を渡す"
          When call run_ai_piped "github/gpt-4.1"
          The status should equal 0
          The output should include "MOCK_COPILOT:"
          The output should include "--model"
          The output should include "gpt-4.1"
        End

        It "Then: [Normal] T-LIB-RAI-17: github-copilot/gpt-4o は prefix を除去し --model gpt-4o を渡す"
          When call run_ai_piped "github-copilot/gpt-4o"
          The status should equal 0
          The output should include "MOCK_COPILOT:"
          The output should include "--model"
          The output should include "gpt-4o"
          The output should not include "github-copilot"
        End

        It "Then: [Normal] T-LIB-RAI-18: github-copilot/gemini-2.0 は prefix を除去し --model gemini-2.0 を渡す"
          When call run_ai_piped "github-copilot/gemini-2.0"
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
        It "Then: [Normal] T-LIB-RAI-19: opencode/gpt-5 は opencode run --model を渡す"
          When call run_ai_piped "opencode/gpt-5"
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
          It "Then: [Error] T-LIB-RAI-20: CLI が存在しない場合は exit 2 と 'CLI not found' を返す"
            When call run_ai_piped 'claude-3-opus'
            The status should equal 2
            The output should equal ""
            The error should include "CLI not found"
          End
        End
      End

      Describe "When: タイムアウト条件"
        Before 'setup_timeout_mock'
        After 'cleanup_mock'

        Describe "When: run_ai を呼ぶ"
          It "Then: [Error] T-LIB-RAI-21: タイムアウト時は exit 124 と 'timeout' を返す"
            When call run_ai_piped 'sonnet' 1
            The status should equal 124
            The output should equal ""
            The error should include "timeout"
          End
        End
      End

      Describe "When: 空 stdin (claude mock)"
        Before 'setup_claude_mock'
        After 'cleanup_mock'

        # unit の stdin ガードと同じ振る舞いを、実 mock CLI と実 timeout(1) の下で確かめる。
        # ガードが unit のモック構成でしか働かないという取りこぼしを、この層で 1 件だけ押さえる。
        Describe "When: 異常系"
          It "Then: [Error] T-LIB-RAI-22: 空 stdin では CLI を起動せず exit 3 を返す"
            When call run_ai_with_empty_stdin 'sonnet'
            The status should equal 3
            The error should include "empty prompt on stdin"
            # mock CLI が起動していれば MOCK_CLAUDE: が stdout に出る
            The output should equal ""
          End
        End
      End

      Describe "When: エッジケース (claude mock)"
        Before 'setup_claude_mock'
        After 'cleanup_mock'

        Describe "When: run_ai を呼ぶ"
          # 'invalid time interval' は timeout(1) 自身が stderr へ出す診断である。
          # run_ai は CLI の stderr を stdout へ畳み込まないので、期待は stderr 側に置く
          # (同じ形を T-LIB-RAI-21 がタイムアウト診断に対して既に使っている)。
          # 秒数は stdin の読み取りを包む timeout(1) にも渡るため、診断はそちらで先に出る。
          # 読み取りが打ち切り (124) 以外の非 0 で終わった場合の終了コードは 3 である。
          It "Then: [Edge] T-LIB-RAI-23: タイムアウトに文字列を渡すと 'invalid time interval' を返す"
            When call run_ai_piped 'sonnet' 'notanumber'
            The status should equal 3
            The error should include "invalid time interval"
            The output should be blank
          End
        End
      End

      Describe "When: CLI が exit 0 で何も返さない (codex mock)"
        Before 'setup_silent_codex_mock'
        After 'cleanup_mock'

        # codex-cli 0.157 系は起動拒否 (`Not inside a trusted directory ...`) を
        # exit 0 + 空 stdout で返す。CLI の終了コードを素通しすると、呼び出し元には
        # 「空の応答で成功した」としか見えない。run_ai 自身が失敗させることを固定する
        Describe "When: 異常系"
          It "Then: [Error] T-LIB-RAI-25: exit 0 でも応答が空なら exit 4 を返す"
            When call run_ai_piped 'gpt-4o'
            The status should equal 4
            The output should equal ""
            The error should include "without a response"
          End
        End
      End
    End
  End
End
