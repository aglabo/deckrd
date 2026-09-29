#!/usr/bin/env bash
# ai-runner.system.spec.sh - ShellSpec system tests for run_ai with real CLI
#
# System test design:
#   - AI CLI の stub を置かない。実機の CLI をそのまま起動して応答が返ることを見る。
#     それが system（実行環境を含めた全体）と functional / integration を分ける点である。
#   - 既定の SKIP_INTEGRATION_TESTS=1 では全ケースを skip する。
#     `pnpm run test:sh system` が 0 を立てるので、そのときだけ実行される。
#     spec ファイルを直接指定するときは `--integration` を付ける。
#   - 実機の stderr は空にならない。バージョン管理ツールの警告、ログインシェルの
#     起動ファイルの出力、CLI 自身のバナーや進捗表示（codex の起動バナー、
#     opencode の build 行）が必ず混ざる。run_ai は CLI の stderr を捕まえず
#     呼び出し元へ素通しする契約なので、これは仕様どおりの姿である。
#     `should be blank` や `should equal ""` は書けない。
#   - それでも各ケースは stderr へ必ず 1 つ期待値を置く。ShellSpec は期待値の無い
#     stderr を「出力があるが期待値が見つからない」警告で報せるが、その警告が
#     常時 4 件出ている状態では、本物の stderr 異常が増えても件数の変化としてしか
#     現れず埋もれる。期待値は「出てはならない失敗の署名が無いこと」に限る。
#     雑音の綴りを期待値にすると、CLI や実行環境が更新されるたびに、
#     応答は返っているのにテストが落ちる。
#
# Copyright (c) 2026- atsushifx <https://github.com/atsushifx>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

# shellcheck disable=SC1090

# ============================================================================
# テスト基盤
# ============================================================================

_RUNTIME_BOOTSTRAP="${SHELLSPEC_PROJECT_ROOT}/skills/deckrd/skills/deckrd/scripts/libs/bootstrap.lib.sh"
. "$_RUNTIME_BOOTSTRAP"
unset _RUNTIME_BOOTSTRAP

Include ../spec_helper.sh

# ============================================================================
# テスト対象
# ============================================================================

# SCRIPT は各ケースの `bash -c` 本文が取り込み直すため、変数のまま持つ
SCRIPT="${DECKRD_LIB_DIR}/ai-runner.lib.sh"
. "$SCRIPT"

# ============================================================================
# 内部ヘルパー
# ============================================================================

# 定数

# _RUN_AI_ERROR_PREFIX - run_ai 自身が stderr へ出す診断の綴り。末尾の空白までが値である
#
# run_ai の診断はすべて `Error: ` で始まり、それを出す分岐はすべて非 0 を返す。
# よって成功したケースの stderr にこの綴りが現れてはならない。実機の stderr には
# CLI と実行環境の雑音が必ず混ざるので、見るのは「run_ai 自身は何も言わなかった」
# ことだけに限る。末尾の空白を落とすと `Error:` で始まる CLI の出力まで拾い、
# 応答は返っているのにテストが落ちる。
# 成功時の stderr にこの綴りを書く CLI が現れたら、この行を消すのではなく
# 衝突しない具体的なメッセージ（`Error: unknown model: ` など）へ狭めるか、
# `grep -q '^Error: '` を使う satisfy matcher に切り替えて行頭で照合する。
# 絶対に現れない綴りへ逃げてはならない。警告だけ消えて何も検査しない状態は、
# カバレッジがあるように見えるぶん警告より悪い
readonly _RUN_AI_ERROR_PREFIX='Error: '

# _CODEX_NONGIT_REFUSAL - codex exec が git リポジトリ外で起動を拒むときの文面
#
# --skip-git-repo-check が抜けたときだけ stderr に現れる。codex-cli 0.157 系は
# この拒否を exit 0 + 空 stdout で返すので、終了ステータスだけでは
# 「拒否された」と「応答が空だった」の区別が付かない。文面そのものを見れば
# 失敗メッセージが原因を名指しする
readonly _CODEX_NONGIT_REFUSAL='Not inside a trusted directory'

# ============================================================================
# テスト本体
# ============================================================================

# ai-runner.lib.sh の run_ai を実機の AI CLI で動かし、応答が返ることを確かめる。
# 各ケースは「終了ステータスが 0」「stdout が空でない」「stderr に失敗の署名が無い」の
# 3 点を見る。stderr を見る理由は冒頭の System test design を参照
Describe "T-LIB-RAS: run_ai"
  Describe "実機テスト (claude)"
    Skip if "integration tests are disabled" [ "${SKIP_INTEGRATION_TESTS:-1}" = "1" ]
    Skip if "claude is not installed" command_missing claude

    It "T-LIB-RAS-01: sonnet エイリアスで実際に応答を返す"
      When run bash -c "
          unset CLAUDECODE
          . \"$SCRIPT\"
          echo \"Say 'OK' and nothing else.\" | run_ai 'sonnet' 60
        "
      The status should equal 0
      The output should not equal ""
      The stderr should not include "$_RUN_AI_ERROR_PREFIX"
    End
  End

  Describe "実機テスト"
    Skip if "integration tests are disabled" [ "${SKIP_INTEGRATION_TESTS:-1}" = "1" ]

    Parameters
      "codex" "codex" "$SPEC_CODEX_MODEL" 60
      # "gemini" "gemini" "gemini-2.5-pro" 60   # quota limit
      # "copilot" "copilot" "github/gpt-4.1" 60 # too many requests
      "opencode" "opencode" "opencode/${SPEC_OPENCODE_MODEL}" 60
    End

    It "T-LIB-RAS-02: $1 で $3 モデルが実際に応答を返す"
      Skip if "$2 is not installed" command_missing "$2"
      When run bash -c "
          . \"$SCRIPT\"
          echo \"Say 'OK' and nothing else.\" | run_ai '$3' $4
        "
      The status should equal 0
      The output should not equal ""
      # 期待値は必ず名前付き変数で書く。Parameters 配下では $1..$4 が行の値なので、
      # 綴りを直書きすると行の値と取り違える
      The stderr should not include "$_RUN_AI_ERROR_PREFIX"
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
    # フラグを外しても通ってしまうため、この網は実行環境に依存する。
    # after hook は例の評価の外で走り、その stderr は例の stderr とは別経路で
    # 拾われる。下の The stderr の期待値がこの網を代替することも弱めることもない
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
      # 拒否の文面そのものを見る。status だけでは exit 4（応答が空）と区別が付かず、
      # 失敗メッセージが原因を示さない。将来 codex が拒否を stdout にも書いたり
      # 部分的な応答を返したりすれば status と output は通ってしまうので、
      # この 1 行だけがフラグの退行を名指しで捕える
      The stderr should not include "$_CODEX_NONGIT_REFUSAL"
      The stderr should not include "$_RUN_AI_ERROR_PREFIX"
    End
  End
End
