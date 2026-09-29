#!/usr/bin/env bash
# ai-runner-stderr-separation.unit.spec.sh - ShellSpec tests for stdout/stderr separation in run_ai
#
# Unit test design:
#   - 実 AI CLI を起こさずにリダイレクトの配線だけを確かめるので unit が正しい階層である。
#     timeout と CLI コマンドをシェル関数で差し替え、stdout と stderr の両方へ
#     互いに区別できる印を出させて、どちらの経路にどちらの印が届くかを見る。
#   - stdout は完全一致で比べる。部分一致にすると、本文にノイズが混ざっていても通ってしまう。
#   - モックは 1 組に保ち、ケースごとの前提の違いは Before が渡す状態変数だけに現れるようにする。
#
# Copyright (c) 2026- atsushifx <https://github.com/atsushifx>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

# shellcheck disable=SC1090,SC1091
# cspell:words RASE sonnet

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

# shellcheck source=../../ai-runner.lib.sh
. "${DECKRD_LIB_DIR}/ai-runner.lib.sh"

# ============================================================================
# 内部ヘルパー
# ============================================================================

# 定数

# _BODY_SENTINEL - AI CLI が stdout へ出す応答本文の印。_NOISE_SENTINEL の部分文字列にならない値にする
_BODY_SENTINEL='AI-RESPONSE-BODY'

# _NOISE_SENTINEL - AI CLI が stderr へ出す診断の印。_BODY_SENTINEL の部分文字列にならない値にする
_NOISE_SENTINEL='CLI-DIAGNOSTIC-NOISE'

# _EXIT_CLI_FAILURE - CLI の異常終了を表す終了ステータス。run_ai 自身が返す 1 / 2 / 124 のどれとも異なる値にする
_EXIT_CLI_FAILURE='3'

# _EXIT_CLI_TIMEOUT - CLI の実行が打ち切られたことを表す終了ステータス。timeout(1) が打ち切り時に返す 124 に合わせる
_EXIT_CLI_TIMEOUT='124'

# 関数

# _arrange_cli - timeout モックが出す応答本文と返す終了ステータスをケースの前提へ整える
#
# 本文の量と終了ステータスだけがケース間の違いなので、モックを増やさず
# モックが読む状態変数を差し替えて前提を撃ち分ける。
#
# @arg $1 string  モックが stdout へ出す応答本文。空文字なら何も出さない
# @arg $2 string  モックが返す終了ステータス
# @return 0 always
_arrange_cli() {
  _mock_body="$1"
  _mock_exit="$2"
}

# _restore_mock_state - _arrange_cli が置いた状態変数を消してケース間に持ち越さない
#
# @return 0 always
_restore_mock_state() {
  unset _mock_body _mock_exit
}

# _run_ai_with_errexit - errexit を有効にしたうえで、固定プロンプトを stdin に与えて run_ai を呼ぶ
#
# 実際の呼び出し元 (generate-doc.sh) は `set -eo pipefail` 配下でパイプラインの要素として
# run_ai を呼び、errexit はパイプライン要素のサブシェルでも生きている。CLI の実行結果を
# 伝える経路が errexit に奪われないことは、errexit を有効にしたケースだけが観測できる。
# set -e はシェル全体の設定であり関数スコープに閉じないため、このヘルパーは
# ShellSpec 自身のシェルへ設定を漏らさないよう `When run` (サブシェル) から呼ぶ。
#
# @arg $@  run_ai へそのまま渡す引数
_run_ai_with_errexit() {
  set -e
  run_ai_piped "$@"
}

# ============================================================================
# テスト本体
# ============================================================================

# ai-runner.lib.sh の run_ai が返す stdout に、AI CLI の stderr が混ざらないことの確認。
# run_ai の stdout は「AI の応答本文」という 1 つの意味を持つ経路であり、
# CLI の進捗表示・警告・診断はそこではなく呼び出し元の stderr へ届かなければならない。
# 各ケースは応答本文の量と CLI の終了ステータスだけを変え、2 つの経路の中身を確かめる。
Describe "T-LIB-RASE: ai-runner.lib.sh run_ai の stdout/stderr 分離"

  After "_restore_mock_state"

  # timeout - timeout(1) を差し替えるモック。stdout へ応答本文を、stderr へ診断の印を出して CLI は起動しない。
  # run_ai は stdin の読み取りも timeout 配下で行うため、このモックは 1 回の呼び出しで 2 度踏まれる。
  # 読み取り側（cat）を模してしまうと応答本文がプロンプトに化けるので、そちらは実物へ素通しし、
  # CLI 起動側の呼び出しだけを差し替える
  timeout() {
    shift
    if [[ "$1" == "cat" ]]; then
      "$@"
      return
    fi

    [[ -n "${_mock_body:-}" ]] && echo "${_mock_body}"
    echo "${_NOISE_SENTINEL}" >&2
    return "${_mock_exit:-0}"
  }

  # claude - run_ai の command -v ガードを満たすための CLI モック。timeout モックが起動しないので呼ばれない
  claude() {
    return 0
  }

  Describe "Given: AI CLI が stdout へ応答本文を、stderr へ診断を出して正常終了する"
    Before "_arrange_cli '$_BODY_SENTINEL' 0"

    Describe "When: 正常系"
      It "Then: [Normal] T-LIB-RASE-01: stdout に応答本文だけが残り、診断は stderr へ届く"
        When call run_ai_piped "sonnet"
        The status should equal 0
        The output should equal "$_BODY_SENTINEL"
        The stderr should include "$_NOISE_SENTINEL"
      End
    End
  End

  Describe "Given: AI CLI が stdout へ何も出さず stderr へ診断だけを出す"
    Before "_arrange_cli '' 0"

    # CLI が exit 0 を返しても応答本文が無ければ run_ai は成功にしない (exit 4)。
    # codex-cli 0.157 系は起動拒否を exit 0 + 空 stdout で返すため、ここを成功として
    # 通すと呼び出し元には「空の応答で成功した」としか見えなくなる。
    # このケースが見ているのは経路の分離なので、stdout が空のままであること、
    # CLI の診断が stderr へ届くことは変わらない
    Describe "When: エッジケース"
      It "Then: [Edge] T-LIB-RASE-02: 応答本文が無ければ stdout は空のまま exit 4 になる"
        When call run_ai_piped "sonnet"
        The status should equal 4
        The output should equal ""
        The stderr should include "$_NOISE_SENTINEL"
        The stderr should include "without a response"
      End
    End
  End

  Describe "Given: AI CLI が診断を stderr へ出して非 0 で終了する"
    Before "_arrange_cli '$_BODY_SENTINEL' '$_EXIT_CLI_FAILURE'"

    Describe "When: 異常系"
      It "Then: [Error] T-LIB-RASE-03: 非 0 終了でも stdout は応答本文のみで、終了ステータスはそのまま返る"
        When call run_ai_piped "sonnet"
        The status should equal "$_EXIT_CLI_FAILURE"
        The output should equal "$_BODY_SENTINEL"
        The stderr should include "$_NOISE_SENTINEL"
      End

      It "Then: [Error] T-LIB-RASE-04: errexit 有効でも応答本文と終了ステータスがそのまま返る"
        When run _run_ai_with_errexit "sonnet"
        The status should equal "$_EXIT_CLI_FAILURE"
        The output should equal "$_BODY_SENTINEL"
        The stderr should include "$_NOISE_SENTINEL"
      End
    End
  End

  # CLI の実行が打ち切られたときだけを見るグループ。モックに応答本文を出させるのは、
  # 本文が空だと errexit 下でモック自身の `[[ ]] &&` が先に死に、run_ai ではなく
  # モックを測ってしまうためである。打ち切り経路は $output を出さずに戻るので、
  # 本文を出しても stdout が空のままであることは変わらない
  Describe "Given: AI CLI の実行が制限時間内に終わらない"
    Before "_arrange_cli '$_BODY_SENTINEL' '$_EXIT_CLI_TIMEOUT'"

    Describe "When: 異常系"
      It "Then: [Error] T-LIB-RASE-05: errexit 有効でも打ち切りの診断を出して 124 を返す"
        When run _run_ai_with_errexit "sonnet"
        The status should equal "$_EXIT_CLI_TIMEOUT"
        The entire output should equal ""
        The stderr should include "timeout after"
      End
    End
  End
End
