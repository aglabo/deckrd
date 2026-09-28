#!/usr/bin/env bash
# ai-runner-resolve-timeout.unit.spec.sh - ShellSpec tests for resolve_ai_timeout in ai-runner.lib.sh
#
# Unit test design:
#   - 環境変数の設定・解除は各ケースの Before / グループの After に閉じ込める。
#     DECKRD_AI_TIMEOUT はリポジトリの誰も設定しないので、復元は unset が元の状態である。
#   - センチネルは現行の既定値とも新しい既定値とも異なる値にする。一致させると、
#     解決が効いていないのに通ってしまう。
#   - 異常系のケースは無い。resolve_ai_timeout は失敗パスを持たず値の検証もしない
#     (数値以外の扱いは timeout コマンドの責務) ため、無効入力の同値クラスが存在しない。
#
# Copyright (c) 2026- atsushifx <https://github.com/atsushifx>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

# shellcheck disable=SC1090,SC1091
# cspell:words RAIT RATW sonnet

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

# _UNSET - 「その変数を unset する / その位置引数を渡さない」と伝える印。実際の値と衝突しない固有値
_UNSET='<unset>'

# _SENTINEL_ARG_TIMEOUT - 位置引数に渡すセンチネル。最優先で返ることの確認に使う
_SENTINEL_ARG_TIMEOUT='45'

# _SENTINEL_ENV_TIMEOUT - DECKRD_AI_TIMEOUT に入れるセンチネル。_SENTINEL_ARG_TIMEOUT と必ず異なる値にする
_SENTINEL_ENV_TIMEOUT='77'

# _EXPECTED_DEFAULT_TIMEOUT - どちらも未設定のときの期待値。旧既定値 120 と必ず異なる値にする
_EXPECTED_DEFAULT_TIMEOUT='300'

# _MOCK_TIMEOUT_PREFIX - timeout モックが受け取ったタイムアウト秒数を出力するときの印
_MOCK_TIMEOUT_PREFIX='MOCK_TIMEOUT_SEC:'

# 関数

# _apply_env - DECKRD_AI_TIMEOUT をケースの前提状態へ整える
#
# 「未設定」と「空文字」は resolve_ai_timeout にとって別の入力ではないことを
# 確かめるケースがあるため、両者を引数で撃ち分けられるようにする。
# $_UNSET を渡したときだけ unset し、それ以外は空文字も含めてそのまま export する。
#
# @arg $1 string  DECKRD_AI_TIMEOUT に入れる値。$_UNSET なら unset する
# @return 0 always
_apply_env() {
  local _timeout="$1"

  if [[ "$_timeout" == "$_UNSET" ]]; then
    unset DECKRD_AI_TIMEOUT
  else
    export DECKRD_AI_TIMEOUT="$_timeout"
  fi
}

# _restore_env - ケースが触った環境変数を bootstrap 直後の状態へ戻す
#
# DECKRD_AI_TIMEOUT は誰も設定しない変数なので unset が元の状態である。
#
# @return 0 always
_restore_env() {
  unset DECKRD_AI_TIMEOUT
}

# _resolve_with_arg - 位置引数の有無を 1 つの仕組みで撃ち分けて resolve_ai_timeout を呼ぶ
#
# 「位置引数を渡さない」と「空文字を渡す」は別のケースなので、
# $_UNSET を渡したときだけ引数無しで呼び、それ以外は受け取った値をそのまま渡す。
#
# @arg $1 string  位置引数に渡す値。$_UNSET なら位置引数を渡さない
# @stdout resolve_ai_timeout が返した値
# @return resolve_ai_timeout の終了ステータス
_resolve_with_arg() {
  local _arg="$1"

  if [[ "$_arg" == "$_UNSET" ]]; then
    resolve_ai_timeout
  else
    resolve_ai_timeout "$_arg"
  fi
}

# ============================================================================
# テスト本体
# ============================================================================

# ai-runner.lib.sh のタイムアウト解決。
# 位置引数 → DECKRD_AI_TIMEOUT → 既定値の 3 段で解決し、既定値の出どころを 1 箇所へ畳む。
# 各ケースは前提となる位置引数と環境変数の状態だけを変え、返る値がどの段から来たかを確かめる。
Describe "T-LIB-RAIT: ai-runner.lib.sh resolve_ai_timeout"

  After "_restore_env"

  Describe "Given: 位置引数と DECKRD_AI_TIMEOUT が相異なる値で設定されている"
    Before "_apply_env '$_SENTINEL_ENV_TIMEOUT'"

    Describe "When: 正常系"
      It "Then: [Normal] T-LIB-RAIT-01: 位置引数を最優先で返す"
        When call _resolve_with_arg "$_SENTINEL_ARG_TIMEOUT"
        The status should equal 0
        The output should equal "$_SENTINEL_ARG_TIMEOUT"
        The stderr should be blank
      End
    End
  End

  Describe "Given: 位置引数が無く DECKRD_AI_TIMEOUT だけが設定されている"
    Before "_apply_env '$_SENTINEL_ENV_TIMEOUT'"

    Describe "When: 正常系"
      It "Then: [Normal] T-LIB-RAIT-02: DECKRD_AI_TIMEOUT の値を返す"
        When call _resolve_with_arg "$_UNSET"
        The status should equal 0
        The output should equal "$_SENTINEL_ENV_TIMEOUT"
        The stderr should be blank
      End
    End
  End

  Describe "Given: 位置引数も DECKRD_AI_TIMEOUT も設定されていない"
    Before "_apply_env '$_UNSET'"

    Describe "When: 正常系"
      It "Then: [Normal] T-LIB-RAIT-03: 既定値を返す"
        When call _resolve_with_arg "$_UNSET"
        The status should equal 0
        The output should equal "$_EXPECTED_DEFAULT_TIMEOUT"
        The stderr should be blank
      End
    End
  End

  Describe "Given: 位置引数が空文字で DECKRD_AI_TIMEOUT が設定されている"
    Before "_apply_env '$_SENTINEL_ENV_TIMEOUT'"

    Describe "When: エッジケース"
      It "Then: [Edge] T-LIB-RAIT-04: 空文字を未設定として扱い DECKRD_AI_TIMEOUT の値を返す"
        When call _resolve_with_arg ""
        The status should equal 0
        The output should equal "$_SENTINEL_ENV_TIMEOUT"
        The stderr should be blank
      End
    End
  End

  Describe "Given: 位置引数と DECKRD_AI_TIMEOUT がどちらも空文字"
    Before "_apply_env ''"

    Describe "When: エッジケース"
      It "Then: [Edge] T-LIB-RAIT-05: どちらの空文字も未設定として扱い既定値を返す"
        When call _resolve_with_arg ""
        The status should equal 0
        The output should equal "$_EXPECTED_DEFAULT_TIMEOUT"
        The stderr should be blank
      End
    End
  End
End

# ai-runner.lib.sh の run_ai が、タイムアウト秒数を resolve_ai_timeout から受け取って
# timeout へ渡していることの確認。resolve_ai_timeout 単体が正しくても、run_ai が
# 自前の既定値を持ったままなら不具合は直らないので、配線そのものを 1 段だけ確かめる。
# 外部プロセスを起こさないよう、timeout と CLI コマンドをシェル関数で差し替える。
Describe "T-LIB-RATW: ai-runner.lib.sh run_ai のタイムアウト解決の配線"

  After "_restore_env"

  # timeout - timeout(1) を差し替えるモック。受け取った秒数だけを印付きで出力し、CLI は起動しない
  timeout() {
    echo "${_MOCK_TIMEOUT_PREFIX}$1"
    return 0
  }

  # claude - run_ai の command -v ガードを満たすための CLI モック。timeout モックが起動しないので呼ばれない
  claude() {
    return 0
  }

  Describe "Given: DECKRD_AI_TIMEOUT だけが設定されている"
    Before "_apply_env '$_SENTINEL_ENV_TIMEOUT'"

    Describe "When: 正常系"
      It "Then: [Normal] T-LIB-RATW-01: DECKRD_AI_TIMEOUT の値で timeout を起動する"
        When call run_ai "sonnet"
        The status should equal 0
        The output should equal "${_MOCK_TIMEOUT_PREFIX}${_SENTINEL_ENV_TIMEOUT}"
      End
    End
  End

  Describe "Given: 位置引数と DECKRD_AI_TIMEOUT が相異なる値で設定されている"
    Before "_apply_env '$_SENTINEL_ENV_TIMEOUT'"

    Describe "When: 正常系"
      It "Then: [Normal] T-LIB-RATW-02: 位置引数の値で timeout を起動する"
        When call run_ai "sonnet" "$_SENTINEL_ARG_TIMEOUT"
        The status should equal 0
        The output should equal "${_MOCK_TIMEOUT_PREFIX}${_SENTINEL_ARG_TIMEOUT}"
      End
    End
  End

  # 既定値の経路を run_ai 側でも 1 段だけ押さえる。
  # この例が無いと、run_ai が resolve_ai_timeout を呼ばずに
  # ${2:-${DECKRD_AI_TIMEOUT:-<既定値>}} を自前で持ち直す変異を検出できない。
  # その変異は resolve_ai_timeout を死にコードに変え、既定値の出どころを再び 2 つに割る。
  Describe "Given: 位置引数も DECKRD_AI_TIMEOUT も設定されていない"
    Before "_apply_env '$_UNSET'"

    Describe "When: 正常系"
      It "Then: [Normal] T-LIB-RATW-03: 既定値で timeout を起動する"
        When call run_ai "sonnet"
        The status should equal 0
        The output should equal "${_MOCK_TIMEOUT_PREFIX}${_EXPECTED_DEFAULT_TIMEOUT}"
      End
    End
  End
End
