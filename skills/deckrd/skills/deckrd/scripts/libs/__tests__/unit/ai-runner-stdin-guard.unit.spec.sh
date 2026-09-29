#!/usr/bin/env bash
# ai-runner-stdin-guard.unit.spec.sh - ShellSpec tests for the stdin guard of run_ai
#
# Unit test design:
#   - run_ai が AI CLI を起動する前に stdin を検査することだけを確かめるので unit が正しい階層である。
#     実 AI CLI は起こさず、timeout(1) を素通しモックに差し替えてシェル関数の CLI モックへ制御を渡す。
#   - CLI を起動したかどうかは、CLI モックが stdout へ書くマーカーの有無だけで観測する。
#   - プロンプトが CLI の stdin へ届いたかどうかは、stdin を stdout へ返す CLI モックの
#     出力がプロンプトと完全一致するかだけで観測する。
#   - ガードは stdout へ何も書かない。`The output` は ShellSpec が末尾改行を落とすため
#     「無出力」と「空行 1 行」を区別できないので、比較は `The entire output` で行う。
#
# Copyright (c) 2026- atsushifx <https://github.com/atsushifx>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

# shellcheck disable=SC1090,SC1091
# cspell:words RASI sonnet

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

# _EMPTY_STDOUT - ガード経路で stdout に許される唯一の値。`The entire output` で比較する
_EMPTY_STDOUT=''

# _EXIT_STDIN_GUARD - stdin ガードの終了ステータス。run_ai の 1 / 2 / 124 と衝突しない値
_EXIT_STDIN_GUARD='3'

# _CLI_LAUNCHED_MARKER - claude モックが stdout へ書く印。これが出たらガードを素通りしている
_CLI_LAUNCHED_MARKER='CLI-WAS-LAUNCHED'

# _STDIN_PROMPT - stdin で渡すプロンプト本文。_CLI_LAUNCHED_MARKER の部分文字列にならない値にする
_STDIN_PROMPT='STDIN-PROMPT-BODY'

# _EXIT_READ_TIMEOUT - 読み取りが打ち切られたときの終了ステータス。timeout(1) が返す 124 に寄せる
_EXIT_READ_TIMEOUT='124'

# _MOCK_READ_FAILURE_STATUS - 読み取りが打ち切り以外で失敗したときにモックが返す終了ステータス。
# run_ai が返す 0 / 1 / 2 / 3 / 124 のどれとも異なる値にする。素通しならこの値が見えるので、
# 3 が返ること自体が「読み取り失敗を 3 へ写している」ことの証拠になる
_MOCK_READ_FAILURE_STATUS='42'

# 関数
#
# ShellSpec は `When call` の stdin を実行環境からそのまま引き継ぐ。stdin を与えずに
# run_ai を呼ぶと前提が実行環境任せになり、端末から走らせたときは cat が入力待ちで止まる。
# stdin の状態そのものが前提であるこのグループでは、各ケースが呼ぶヘルパーで明示的に固定する。

# _run_ai_with_empty_stdin - stdin を 0 バイト（/dev/null）に固定して run_ai を呼ぶ
#
# @arg $@  run_ai へそのまま渡す引数
_run_ai_with_empty_stdin() {
  run_ai "$@" </dev/null
}

# _run_ai_with_stdin_prompt - 非空のプロンプト（_STDIN_PROMPT）を stdin に与えて run_ai を呼ぶ
#
# @arg $@  run_ai へそのまま渡す引数
_run_ai_with_stdin_prompt() {
  run_ai "$@" <<<"$_STDIN_PROMPT"
}

# ============================================================================
# テスト本体
# ============================================================================

# ai-runner.lib.sh の run_ai が AI CLI を起動する前に stdin を検査することの確認。
# run_ai がプロンプトを受け取る口は stdin だけであり、渡されていない stdin を
# そのまま CLI へ流すと、呼び出し側の書き方ミスが CLI 側の無関係に見えるエラーに化ける。
# ガードは CLI を起動せず、stdout へ何も書かず、終了ステータスと stderr だけで理由を伝える。
Describe "T-LIB-RASI: ai-runner.lib.sh run_ai の stdin ガード"

  # timeout - timeout(1) の素通しモック。第 1 引数の秒数を捨てて残りをそのまま実行する。
  # 実物の timeout(1) は外部バイナリを exec するのでシェル関数の claude を見ない。
  # 素通しにして初めて claude モックが呼ばれ、CLI を起動したかどうかを観測できる
  # shellcheck disable=SC2329 # run_ai から間接的に呼ばれる。下位グループの差し替えは ShellSpec のスコープに閉じる
  timeout() {
    shift
    "$@"
  }

  # claude - resolve_ai_cli "sonnet" が解決する CLI のモック。起動された印を stdout へ書く。
  # ガードが働けば呼ばれず、stdout は空のままになる
  # shellcheck disable=SC2329 # run_ai の "${_AI_CMD[@]}" から間接的に呼ばれる
  claude() {
    echo "$_CLI_LAUNCHED_MARKER"
  }

  Describe "Given: stdin が空のまま run_ai を呼ぶ"
    Describe "When: 異常系"
      It "Then: [Error] T-LIB-RASI-01: 空 stdin では CLI を起動せず 3 を返す"
        When call _run_ai_with_empty_stdin "sonnet"
        The status should equal "$_EXIT_STDIN_GUARD"
        The entire output should equal "$_EMPTY_STDOUT"
        The stderr should include "empty prompt on stdin"
      End
    End
  End

  Describe "Given: stdin が端末である"

    # _ai_stdin_is_tty - 端末判定を真に固定するモック。ShellSpec の実行環境の stdin は
    # 端末にならないため、`[[ -t 0 ]]` を直接は踏めない。判定を関数へ切り出す唯一の理由がここにある
    _ai_stdin_is_tty() {
      return 0
    }

    Describe "When: 異常系"
      It "Then: [Error] T-LIB-RASI-02: stdin が端末なら CLI を起動せず 3 を返す"
        When call _run_ai_with_stdin_prompt "sonnet"
        The status should equal "$_EXIT_STDIN_GUARD"
        The entire output should equal "$_EMPTY_STDOUT"
        The stderr should include "piped via stdin"
      End
    End
  End

  Describe "Given: stdin にプロンプトがある"

    # claude - CLI の stdin をそのまま stdout へ返すモック。run_ai が受け取ったプロンプトを
    # CLI の stdin へ素通しできているかは、返ってきた stdout がプロンプトと一致するかで観測する
    claude() {
      cat
    }

    Describe "When: 正常系"
      It "Then: [Normal] T-LIB-RASI-03: stdin のプロンプトが CLI の stdin へ素通しで届く"
        When call _run_ai_with_stdin_prompt "sonnet"
        The status should equal 0
        The output should equal "$_STDIN_PROMPT"
      End
    End
  End

  # 読み取りの失敗はプロデューサ側の事情で起きるのでテストからは直接作れない。
  # 読み取りを包む timeout(1) の終了ステータスだけがガードへの入力なので、
  # 以下の 2 グループはその値だけを前提として撃ち分ける。どちらのモックも stdin を読まず
  # stdout へ何も書かないため、CLI 起動まで届いていれば claude モックの印が stdout に現れる。

  Describe "Given: stdin の読み取りが制限時間内に終わらない"

    # timeout - 読み取りを打ち切った timeout(1) のモック。実物が打ち切り時に返す 124 だけを返す
    # shellcheck disable=SC2329 # run_ai から間接的に呼ばれる。次のグループの定義とは ShellSpec のスコープが別
    timeout() {
      return "$_EXIT_READ_TIMEOUT"
    }

    Describe "When: 異常系"
      It "Then: [Error] T-LIB-RASI-04: 読み取りが打ち切られたら CLI を起動せず 124 を返す"
        When call _run_ai_with_stdin_prompt "sonnet"
        The status should equal "$_EXIT_READ_TIMEOUT"
        The entire output should equal "$_EMPTY_STDOUT"
        The stderr should include "timeout"
        # 打ち切られたのが CLI の実行ではなく読み取りであることまで見る。
        # 文言を問わないと、CLI 実行側のタイムアウト経路と区別できない
        The stderr should include "while reading the prompt from stdin"
      End
    End
  End

  Describe "Given: stdin の読み取りが打ち切り以外の理由で失敗する"

    # timeout - 読み取りが打ち切り以外で終わった timeout(1) のモック。
    # 実物は起動した子プロセスの終了ステータスをそのまま返すので、124 以外の値もここへ来る
    timeout() {
      return "$_MOCK_READ_FAILURE_STATUS"
    }

    Describe "When: 異常系"
      It "Then: [Error] T-LIB-RASI-05: 読み取りが失敗したら CLI を起動せず 3 を返す"
        When call _run_ai_with_stdin_prompt "sonnet"
        The status should equal "$_EXIT_STDIN_GUARD"
        The entire output should equal "$_EMPTY_STDOUT"
        The stderr should include "failed to read prompt"
      End
    End
  End
End
