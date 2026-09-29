#!/usr/bin/env bash
# ai-runner.spec.sh - ShellSpec system tests for run_ai with real CLI
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

Describe "T-LIB-RAS: run_ai"
  Describe "実機テスト (claude)"
    Skip if "integration tests are disabled" [ "${SKIP_INTEGRATION_TESTS:-1}" = "1" ]
    Skip if "claude is not installed" ! command -v claude >/dev/null 2>&1

    It "T-LIB-RAS-01: sonnet エイリアスで実際に応答を返す"
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

    It "T-LIB-RAS-02: $1 で $3 モデルが実際に応答を返す"
      Skip if "$2 is not installed" ! command -v "$2" >/dev/null 2>&1
      When run bash -c "
          . \"$SCRIPT\"
          echo \"Say 'OK' and nothing else.\" | run_ai '$3' $4
        "
      The status should equal 0
      The output should not equal ""
    End
  End

  # 報告された不具合そのものの回帰ネット。codex exec は cwd が git リポジトリ外だと
  # `Not inside a trusted directory and --skip-git-repo-check was not specified.` で
  # 起動を拒む。T-LIB-RAS-02 は repo root から走るのでこの経路を通らない。
  # 実機でしかフラグの受理は確かめられないため、system 層に置く
  Describe "実機テスト (codex, git リポジトリ外の cwd)"
    Skip if "integration tests are disabled" [ "${SKIP_INTEGRATION_TESTS:-1}" = "1" ]
    Skip if "codex is not installed" command_missing codex

    # 後片付けは握り潰さない。codex の MCP サーバ起動は --ignore-user-config
    # (_build_ai_command の codex 分岐) で止めているため、MCP サーバが cwd 配下に
    # 作業ファイルを作って掴んだままにすることがなく、rm が `Device or resource busy`
    # で落ちない。ここで後片付けが落ちたらフラグの退行をまず疑う。
    # ただし検出は rm の終了状態ではなく stderr 経由である。teardown_nongit_tmpdir は
    # 最後の unset で 0 を返すので、ShellSpec が after hook の stderr をエラーとして
    # 扱うことだけが手掛かりになる。cwd を掴む MCP サーバを設定していない環境なら
    # フラグを外しても通ってしまうため、この網は実行環境に依存する
    Before 'setup_nongit_tmpdir'
    After 'teardown_nongit_tmpdir'

    It "T-LIB-RAS-03: 非 git な cwd でも codex が応答を返す"
      When run bash -c "
          cd \"\$_NONGIT_TMPDIR\" || exit 1
          . \"$SCRIPT\"
          echo \"Say 'OK' and nothing else.\" | run_ai '$SPEC_CODEX_MODEL' 60
        "
      The status should equal 0
      The output should not equal ""
    End
  End
End
