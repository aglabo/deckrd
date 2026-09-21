#!/usr/bin/env bash
# runners/__tests__/unit/run-shellspec.spec.sh
# @(#) : BDD unit tests for run-shellspec.sh
#
# Copyright (c) 2026- atsushifx <https://github.com/atsushifx>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT
# shellcheck shell=bash
# run-shellspec.spec.sh — BDD spec for run-shellspec.sh

# --- テスト基盤 -------------------------------------------------------------

Include "${SHELLSPEC_PROJECT_ROOT}/runners/__tests__/spec_helper.sh"

# --- テスト対象 -------------------------------------------------------------

Include "${SHELLSPEC_PROJECT_ROOT}/runners/run-shellspec.sh"

SCRIPT="${SHELLSPEC_PROJECT_ROOT}/runners/run-shellspec.sh"

# --- 内部ヘルパー -----------------------------------------------------------

# 定数

# Windows のシェル環境を表す `uname -s` の値。WSL 経路に入るべき入力
_WINDOWS_OS_NAME='MINGW64_NT-10.0-26200'

# Windows のシェル環境ではない `uname -s` の値。ローカル実行経路に入るべき入力
_LOCAL_OS_NAME='Linux'

# Windows のシェル環境ではない `uname -s` の値（T-RUN-SUW-03 の入力表）
%const _SUW_OTHER_OS_NAMES: Linux Darwin

# `%const` の語リストは空語を持てないため、空文字を表す番兵を置く
_NO_WSL_EMPTY_TOKEN='EMPTY'

# `1` 以外なら WSL 経路を維持することを確かめる SHELLSPEC_NO_WSL の値
# （T-RUN-SUW-04 の入力表。`EMPTY` は _NO_WSL_EMPTY_TOKEN が表す空文字）
%const _SUW_KEEP_WSL_FLAGS: 0 EMPTY

# 入口へ渡す spec ファイル引数。解釈されずに本体まで届くことを見る
_SPEC_ARG='foo.spec.sh'

# 入口へ渡す ShellSpec オプション引数。spec 引数との順序が保たれることを見る
_OPTION_ARG='--repair'

# dispatch() が本体へ素通しすべき引数列の観測結果
_FORWARDED_ARGS_OUTPUT="[${_SPEC_ARG}][${_OPTION_ARG}]"

# dispatch() が WSL 側へ渡すべき本体のパス（PROJECT_ROOT からの相対）
_EXPECTED_EXEC_SCRIPT='runners/exec/shellspec-exec.sh'

# _setup_dispatch_stubs() に渡す、wsl.exe を呼べる状態を表す指定
_WSL_AVAILABLE='available'

# _setup_dispatch_stubs() に渡す、wsl.exe を呼べない状態を表す指定
_WSL_MISSING='missing'

# 失敗スタブが返す終了コード。0 でも 1 でもない値にして素通しであることを見分ける
_DSP_STUB_EXIT_CODE=3

# dispatch() が WSL 起動前に見つける不足コマンド（T-RUN-DSP-07 の入力と期待出力）
_DSP_MISSING_COMMAND='jq'

# 関数

#
# @description 入力表に書かれた値を SHELLSPEC_NO_WSL に反映する。
#              `%const` の語リストで表現できない空文字は番兵 `EMPTY` で受け取る
# @arg $1 string 入力表の値、または _NO_WSL_EMPTY_TOKEN
# @return 0 always
# @sideeffect Sets SHELLSPEC_NO_WSL
#
_set_no_wsl_flag() {
  if [[ "$1" == "$_NO_WSL_EMPTY_TOKEN" ]]; then
    SHELLSPEC_NO_WSL=''
  else
    SHELLSPEC_NO_WSL="$1"
  fi
}

#
# @description ShellSpec を「引数を `[%s]` 形式で出力するだけ」のスタブに差し替える。
#              本体 (exec/shellspec-exec.sh) まで引数が届いたことを出力で観測する
# @arg none
# @return 0 when the stub is ready
# @sideeffect Sets _STUB_DIR and _SHELLSPEC_STUB
# @sideeffect Creates the stub directory and the stub script on disk
#
_setup_shellspec_stub() {
  _STUB_DIR="$(mktemp -d)"
  _SHELLSPEC_STUB="${_STUB_DIR}/shellspec-stub"
  {
    echo '#!/usr/bin/env bash'
    echo 'printf "[%s]" "$@"'
  } >"$_SHELLSPEC_STUB"
}

#
# @description _setup_shellspec_stub() が置いたスタブを消す
# @arg none
# @return 0 always
# @sideeffect Deletes _STUB_DIR and unsets the stub variables
#
_teardown_shellspec_stub() {
  [[ -n "${_STUB_DIR:-}" ]] && rm -rf "$_STUB_DIR"
  unset _STUB_DIR _SHELLSPEC_STUB
}

#
# @description dispatch() の協調相手を「自分の名前と引数を `[%s]` 形式で出力するだけ」の
#              シェル関数に差し替える。どちらの経路を通ったかと、渡した引数列を
#              出力だけで観測できるようにする。wsl.exe の実在に依存させないため、
#              is_wsl_available() と find_missing_wsl_commands() も併せて差し替える。
#              後者は既定で「不足コマンドなし」を返す。呼び出し元の環境に
#              SHELLSPEC_NO_WSL が残っていても判定が揺れないよう、併せて解除する
# @arg $1 string `available` なら is_wsl_available() を成功、それ以外なら失敗させる
# @return 0 always
# @sideeffect Defines the run_local, exec_in_wsl, is_wsl_available and
#             find_missing_wsl_commands shell functions
# @sideeffect Unsets SHELLSPEC_NO_WSL
#
_setup_dispatch_stubs() {
  local __wsl_state="$1"
  unset SHELLSPEC_NO_WSL
  # shellcheck disable=SC2329 # dispatch() から間接的に呼ばれる
  run_local() {
    printf '[run_local]'
    printf '[%s]' "$@"
  }
  # shellcheck disable=SC2329 # dispatch() から間接的に呼ばれる
  exec_in_wsl() {
    printf '[exec_in_wsl]'
    printf '[%s]' "$@"
  }
  if [[ "$__wsl_state" == "$_WSL_AVAILABLE" ]]; then
    # shellcheck disable=SC2329 # dispatch() から間接的に呼ばれる
    is_wsl_available() { return 0; }
  else
    # shellcheck disable=SC2329 # dispatch() から間接的に呼ばれる
    is_wsl_available() { return 1; }
  fi
  # shellcheck disable=SC2329 # dispatch() から間接的に呼ばれる
  find_missing_wsl_commands() { :; }
}

#
# @description dispatch() の協調相手を _DSP_STUB_EXIT_CODE で失敗するシェル関数に
#              差し替える。終了コードが加工されずに返ることを観測するために使う
# @arg $1 string `available` なら is_wsl_available() を成功、それ以外なら失敗させる
# @return 0 always
# @sideeffect Defines the run_local, exec_in_wsl, is_wsl_available and
#             find_missing_wsl_commands shell functions
# @sideeffect Unsets SHELLSPEC_NO_WSL
#
_setup_failing_dispatch_stubs() {
  _setup_dispatch_stubs "$1"
  # shellcheck disable=SC2329 # dispatch() から間接的に呼ばれる
  run_local() { return "$_DSP_STUB_EXIT_CODE"; }
  # shellcheck disable=SC2329 # dispatch() から間接的に呼ばれる
  exec_in_wsl() { return "$_DSP_STUB_EXIT_CODE"; }
}

#
# @description dispatch() の協調相手のうち find_missing_wsl_commands() だけを
#              「_DSP_MISSING_COMMAND を 1 行返す」スタブに差し替える。
#              WSL 側に必須コマンドが無い状況を、実機の WSL に依存せずに作る
# @arg $1 string `available` なら is_wsl_available() を成功、それ以外なら失敗させる
# @return 0 always
# @sideeffect Defines the same shell functions as _setup_dispatch_stubs()
# @sideeffect Unsets SHELLSPEC_NO_WSL
#
_setup_missing_commands_stubs() {
  _setup_dispatch_stubs "$1"
  # shellcheck disable=SC2329 # dispatch() から間接的に呼ばれる
  find_missing_wsl_commands() { printf '%s\n' "$_DSP_MISSING_COMMAND"; }
}

#
# @description _setup_dispatch_stubs() が差し替えたシェル関数を取り除く
# @arg none
# @return 0 always
# @sideeffect Undefines the run_local, exec_in_wsl, is_wsl_available and
#             find_missing_wsl_commands shell functions
#
_teardown_dispatch_stubs() {
  unset -f run_local exec_in_wsl is_wsl_available find_missing_wsl_commands
}

# --- テスト本体 -------------------------------------------------------------

#
# ShellSpec 実行の入口スクリプト。環境を判定して本体 (exec/shellspec-exec.sh) を
# ローカルで動かすか WSL 上で動かすかだけを決める。
# 割り当てたテスト ID: T-RUN-SUW-01..04 / T-RUN-DSP-01..07 / T-RUN-MSL-01
#
Describe 'run-shellspec.sh'
  #
  # `uname -s` の値と SHELLSPEC_NO_WSL だけを見て WSL 経路に入るかを決める純粋関数。
  # 自身では uname を呼ばないため、OS 名を表から流し込んで検証できる
  #
  Describe 'should_use_wsl()'
    # Windows のシェルから起動され、無効化もされていなければ WSL を使う
    Describe 'When: 正常系'
      It 'Then: [Normal] T-RUN-SUW-01: SHELLSPEC_NO_WSL 未設定の Windows ホストでは WSL を使うと判定する'
        unset SHELLSPEC_NO_WSL
        When call should_use_wsl "$_WINDOWS_OS_NAME"
        The status should be success
      End
    End

    # SHELLSPEC_NO_WSL=1 は WSL 経路の明示的な無効化を意味する
    Describe 'When: 異常系'
      It 'Then: [Error] T-RUN-SUW-02: SHELLSPEC_NO_WSL=1 なら Windows ホストでも WSL を使わない'
        # shellcheck disable=SC2034 # should_use_wsl() が読む
        SHELLSPEC_NO_WSL=1
        When call should_use_wsl "$_WINDOWS_OS_NAME"
        The status should be failure
      End

      # shellcheck disable=SC2086 # %const の表を 1 ケースずつに単語分割する
      Parameters:value $_SUW_OTHER_OS_NAMES

      It "Then: [Error] T-RUN-SUW-03: OS 名 $1 では WSL を使わない"
        unset SHELLSPEC_NO_WSL
        When call should_use_wsl "$1"
        The status should be failure
      End
    End

    # 無効化は `1` のときだけであり、それ以外の値は WSL 経路のままにする
    Describe 'When: エッジケース'
      # shellcheck disable=SC2086 # %const の表を 1 ケースずつに単語分割する
      Parameters:value $_SUW_KEEP_WSL_FLAGS

      It "Then: [Edge] T-RUN-SUW-04: SHELLSPEC_NO_WSL が $1 でも WSL 経路を無効化しない"
        _set_no_wsl_flag "$1"
        When call should_use_wsl "$_WINDOWS_OS_NAME"
        The status should be success
      End
    End
  End

  #
  # 判定結果に応じてローカル実行と WSL 実行を振り分ける。引数は一切解釈せず、
  # 受け取った順のまま本体へ渡す
  #
  Describe 'dispatch()'
    After '_teardown_dispatch_stubs'

    # Windows 以外のホストでは、従来どおりこのシェルで本体を動かす
    Describe 'When: 正常系'
      It 'Then: [Normal] T-RUN-DSP-01: Windows 以外のホストでは run_local に引数を素通しする'
        _setup_dispatch_stubs "$_WSL_MISSING"
        When call dispatch "$_LOCAL_OS_NAME" "$_SPEC_ARG" "$_OPTION_ARG"
        The output should equal "[run_local]${_FORWARDED_ARGS_OUTPUT}"
        The output should not include 'exec_in_wsl'
        The status should be success
      End

      It 'Then: [Normal] T-RUN-DSP-02: Windows ホストでは PROJECT_ROOT と本体パスを先頭に付けて exec_in_wsl を呼ぶ'
        _setup_dispatch_stubs "$_WSL_AVAILABLE"
        When call dispatch "$_WINDOWS_OS_NAME" "$_SPEC_ARG" "$_OPTION_ARG"
        The output should equal "[exec_in_wsl][${PROJECT_ROOT}][${_EXPECTED_EXEC_SCRIPT}]${_FORWARDED_ARGS_OUTPUT}"
        The output should not include 'run_local'
        The status should be success
      End

      It 'Then: [Normal] T-RUN-DSP-06: 不足コマンドが無ければ何も警告せずに exec_in_wsl を呼ぶ'
        _setup_dispatch_stubs "$_WSL_AVAILABLE"
        When call dispatch "$_WINDOWS_OS_NAME" "$_SPEC_ARG" "$_OPTION_ARG"
        The output should start with '[exec_in_wsl]'
        The stderr should be blank
        The status should be success
      End
    End

    # Windows なのに wsl.exe を呼べない環境は、黙って動かさず理由を 1 行で伝える
    Describe 'When: 異常系'
      It 'Then: [Error] T-RUN-DSP-03: wsl.exe を呼べない Windows ホストでは 1 行のエラーを出して失敗する'
        _setup_dispatch_stubs "$_WSL_MISSING"
        When call dispatch "$_WINDOWS_OS_NAME" "$_SPEC_ARG" "$_OPTION_ARG"
        The lines of stderr should equal 1
        The stderr should include 'wsl.exe'
        The output should be blank
        The status should equal 1
      End

      It 'Then: [Error] T-RUN-DSP-04: ローカル実行経路では run_local の終了コードをそのまま返す'
        _setup_failing_dispatch_stubs "$_WSL_MISSING"
        When call dispatch "$_LOCAL_OS_NAME" "$_SPEC_ARG" "$_OPTION_ARG"
        The status should equal "$_DSP_STUB_EXIT_CODE"
      End

      It 'Then: [Error] T-RUN-DSP-05: WSL 実行経路では exec_in_wsl の終了コードをそのまま返す'
        _setup_failing_dispatch_stubs "$_WSL_AVAILABLE"
        When call dispatch "$_WINDOWS_OS_NAME" "$_SPEC_ARG" "$_OPTION_ARG"
        The status should equal "$_DSP_STUB_EXIT_CODE"
      End

      It 'Then: [Error] T-RUN-DSP-07: WSL に必須コマンドが無ければ 1 行のエラーを出して WSL を起動しない'
        _setup_missing_commands_stubs "$_WSL_AVAILABLE"
        When call dispatch "$_WINDOWS_OS_NAME" "$_SPEC_ARG" "$_OPTION_ARG"
        The lines of stderr should equal 1
        The stderr should include "$_DSP_MISSING_COMMAND"
        The output should be blank
        The status should equal 1
      End
    End
  End

  #
  # 入口として実際に起動されたときの振る舞い。uname の結果を dispatch() へ渡すだけの
  # 薄い層なので、スクリプトを別プロセスで起動した結合として検証する
  #
  Describe 'main()'
    Before '_setup_shellspec_stub'
    After '_teardown_shellspec_stub'

    # WSL を無効化した状態なら、どのホストでも本体がこのシェルで走る
    Describe 'When: 正常系'
      It 'Then: [Normal] T-RUN-MSL-01: SHELLSPEC_NO_WSL=1 では本体経由で ShellSpec に引数が届く'
        When run env SHELLSPEC="$_SHELLSPEC_STUB" SHELLSPEC_NO_WSL=1 bash "$SCRIPT" "$_SPEC_ARG"
        The output should equal "[${_SPEC_ARG}]"
        The status should be success
      End
    End
  End
End
