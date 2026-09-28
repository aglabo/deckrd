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

# ============================================================================
# テスト本体
# ============================================================================

# ai-runner.lib.sh の run_ai が返す stdout に、AI CLI の stderr が混ざらないことの確認。
# run_ai の stdout は「AI の応答本文」という 1 つの意味を持つ経路であり、
# CLI の進捗表示・警告・診断はそこではなく呼び出し元の stderr へ届かなければならない。
# 各ケースは応答本文の量と CLI の終了ステータスだけを変え、2 つの経路の中身を確かめる。
Describe "T-LIB-RASE: ai-runner.lib.sh run_ai の stdout/stderr 分離"

  After "_restore_mock_state"

  # timeout - timeout(1) を差し替えるモック。stdout へ応答本文を、stderr へ診断の印を出して CLI は起動しない
  timeout() {
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
        When call run_ai "sonnet"
        The status should equal 0
        The output should equal "$_BODY_SENTINEL"
        The stderr should include "$_NOISE_SENTINEL"
      End
    End
  End

  Describe "Given: AI CLI が stdout へ何も出さず stderr へ診断だけを出す"
    Before "_arrange_cli '' 0"

    Describe "When: エッジケース"
      It "Then: [Edge] T-LIB-RASE-02: 応答本文が無ければ stdout は空になる"
        When call run_ai "sonnet"
        The status should equal 0
        The output should equal ""
        The stderr should include "$_NOISE_SENTINEL"
      End
    End
  End

  Describe "Given: AI CLI が診断を stderr へ出して非 0 で終了する"
    Before "_arrange_cli '$_BODY_SENTINEL' '$_EXIT_CLI_FAILURE'"

    Describe "When: 異常系"
      It "Then: [Error] T-LIB-RASE-03: 非 0 終了でも stdout は応答本文のみで、終了ステータスはそのまま返る"
        When call run_ai "sonnet"
        The status should equal "$_EXIT_CLI_FAILURE"
        The output should equal "$_BODY_SENTINEL"
        The stderr should include "$_NOISE_SENTINEL"
      End
    End
  End
End
