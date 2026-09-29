#!/usr/bin/env bash
# ai-runner-stdout-contract.unit.spec.sh - ShellSpec tests for the stdout contract of run_ai
#
# Unit test design:
#   - run_ai の 5 つのエラー経路が stdout へ何も書かないことだけを確かめるので unit が正しい階層である。
#     実 AI CLI は起こさず、経路ごとに必要な前提（PATH / CLI モック / timeout モック）だけを最小限に置く。
#   - stdout は完全一致で比べる。部分一致にすると空文字が常に含まれると判定され、契約を守れない。
#   - エラーの通知は終了ステータスと stderr のメッセージだけが担う。stdout は応答本文専用である。
#
# Copyright (c) 2026- atsushifx <https://github.com/atsushifx>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

# shellcheck disable=SC1090,SC1091
# cspell:words RASC sonnet

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

# _EMPTY_STDOUT - エラー経路で stdout に許される唯一の値。契約そのものを表す。
# `The output` は ShellSpec が末尾改行を落とすため「無出力」と「空行 1 行」を区別できない。
# 契約を厳密に固定するので、比較は `The entire output` で行う
_EMPTY_STDOUT=''

# _EXIT_INVALID_MODEL - モデルの検証に失敗したときの終了ステータス
_EXIT_INVALID_MODEL='1'

# _EXIT_CLI_NOT_FOUND - CLI が見つからないときの終了ステータス
_EXIT_CLI_NOT_FOUND='2'

# _EXIT_EMPTY_RESPONSE - CLI が exit 0 を返したのに応答が空だったときの終了ステータス
_EXIT_EMPTY_RESPONSE='4'

# _EXIT_TIMEOUT - timeout(1) が制限時間の超過を伝えるときの終了ステータス
_EXIT_TIMEOUT='124'

# _UNKNOWN_MODEL - resolve_ai_cli の case が拾わないモデル識別子。CLI 解決の手前で弾かれる
_UNKNOWN_MODEL='no-such-model'

# _UNSUPPORTED_MODEL - CLI は copilot に解決できるが _build_ai_command が組み立てを断るモデル識別子
_UNSUPPORTED_MODEL='github/unknown-model'

# 関数

# _arrange_no_cli - PATH を退避して /nonexistent に差し替え、command -v が CLI を見つけられない前提を作る
#
# resolve_ai_cli はシェル関数なので PATH を外してもモデルは解決でき、
# 失敗する場所を command -v のガードだけに絞れる。
#
# @return 0 always
_arrange_no_cli() {
  _saved_path="$PATH"
  # shellcheck disable=SC2123
  PATH=/nonexistent
}

# _restore_path - _arrange_no_cli が退避した PATH を戻し、退避先の変数を消す
#
# @return 0 always
_restore_path() {
  PATH="$_saved_path"
  unset _saved_path
}

# ============================================================================
# テスト本体
# ============================================================================

# ai-runner.lib.sh の run_ai がエラー経路で stdout へ何も書かないことの確認。
# run_ai の stdout は「AI の応答本文」という 1 つの意味だけを運ぶ経路であり、
# 失敗の理由と重さは終了ステータスと stderr のメッセージだけが伝える。
Describe "T-LIB-RASC: ai-runner.lib.sh run_ai の stdout 契約"

  # この分類グループのケースのうち、stdin を与えずに run_ai を直接呼んでいるものは、
  # 「stdin ガードが既存の検証より後にある」という不変条件の回帰ネットでもある。
  # ガードより手前で止まるからこそ stdin を渡さずに済んでいるのであり、揃えるつもりで
  # run_ai_piped へ移し替えてはならない。移すとガードを検証の前へ動かす変異が
  # どのケースも PASS のまま通り、順序の保護だけが静かに消える。
  # run_ai_piped を使っているケースが 1 つだけあるのは、そのケースが CLI 起動まで
  # 到達することを前提にしているためである。
  Describe "Given: モデル引数が空である"
    Describe "When: 異常系"
      It "Then: [Error] T-LIB-RASC-01: モデル引数が空でも stdout には何も残らない"
        When call run_ai ""
        The status should equal "$_EXIT_INVALID_MODEL"
        The entire output should equal "$_EMPTY_STDOUT"
        The stderr should include "model is required"
      End
    End
  End

  Describe "Given: resolve_ai_cli が解決できないモデルを渡す"
    Describe "When: 異常系"
      It "Then: [Error] T-LIB-RASC-02: 未知モデルでも stdout には何も残らない"
        When call run_ai "$_UNKNOWN_MODEL"
        The status should equal "$_EXIT_INVALID_MODEL"
        The entire output should equal "$_EMPTY_STDOUT"
        The stderr should include "unknown model"
      End
    End
  End

  Describe "Given: CLI は解決できるが _build_ai_command が失敗するモデルを渡す"

    # copilot - run_ai の command -v ガードを満たすための CLI モック。_build_ai_command の手前で止まるので呼ばれない
    copilot() {
      return 0
    }

    Describe "When: 異常系"
      It "Then: [Error] T-LIB-RASC-04: 非対応モデルでも stdout には何も残らない"
        When call run_ai "$_UNSUPPORTED_MODEL"
        The status should equal "$_EXIT_INVALID_MODEL"
        The entire output should equal "$_EMPTY_STDOUT"
        The stderr should include "unsupported model"
      End
    End
  End

  Describe "Given: CLI が PATH 上に存在しない"
    Before "_arrange_no_cli"
    After "_restore_path"

    Describe "When: 異常系"
      It "Then: [Error] T-LIB-RASC-03: CLI が見つからなくても stdout には何も残らない"
        When call run_ai "sonnet"
        The status should equal "$_EXIT_CLI_NOT_FOUND"
        The entire output should equal "$_EMPTY_STDOUT"
        The stderr should include "CLI not found"
      End
    End
  End

  Describe "Given: CLI の実行がタイムアウトする"

    # timeout - timeout(1) を差し替えるモック。本文もノイズも出さず制限時間の超過だけを伝える。
    # run_ai は stdin の読み取りも timeout 配下で行うため、読み取り側（cat）は実物へ素通しし、
    # 超過を伝えるのは CLI 起動側の呼び出しだけにする。両方で超過させると、
    # 読み取りの超過経路に吸われて CLI 実行の超過を確かめられなくなる。
    # ShellSpec は Describe ごとに評価するので、後続の Describe が同名で別のモックを
    # 置いてもこの定義はこのグループ内で生きている。SC2329 はその再定義を
    # 「一度も呼ばれない」と読むので、ここだけ黙らせる
    # shellcheck disable=SC2329
    timeout() {
      shift
      if [[ "$1" == "cat" ]]; then
        "$@"
        return
      fi

      return "$_EXIT_TIMEOUT"
    }

    # claude - run_ai の command -v ガードを満たすための CLI モック。timeout モックが起動しないので呼ばれない
    claude() {
      return 0
    }

    Describe "When: 異常系"
      It "Then: [Error] T-LIB-RASC-05: タイムアウトしても stdout には何も残らない"
        When call run_ai_piped "sonnet"
        The status should equal "$_EXIT_TIMEOUT"
        The entire output should equal "$_EMPTY_STDOUT"
        The stderr should include "timeout after"
      End
    End
  End

  Describe "Given: CLI が exit 0 を返しながら応答を返さない"

    # timeout - timeout(1) を差し替えるモック。制限時間は判定せず素通しで実行する。
    # 実物の timeout(1) は外部コマンドしか起動できず、シェル関数で差し替えた CLI へは
    # 届かない。この経路は CLI の終了ステータスと stdout を見るので、素通しが要る
    timeout() {
      shift
      "$@"
    }

    # codex - 起動拒否を exit 0 + 空 stdout で伝える CLI モック。
    # codex-cli 0.157 系が `Not inside a trusted directory ...` を返すときの形である
    codex() {
      return 0
    }

    Describe "When: 異常系"
      It "Then: [Error] T-LIB-RASC-06: 応答が空でも stdout には何も残らない"
        When call run_ai_piped "gpt-4o"
        The status should equal "$_EXIT_EMPTY_RESPONSE"
        The entire output should equal "$_EMPTY_STDOUT"
        The stderr should include "without a response"
      End
    End
  End
End
