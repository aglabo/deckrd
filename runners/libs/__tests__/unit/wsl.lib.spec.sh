#!/usr/bin/env bash
# runners/libs/__tests__/unit/wsl.lib.spec.sh
# @(#) : BDD unit tests for wsl.lib.sh
#
# Copyright (c) 2026- atsushifx <https://github.com/atsushifx>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT
# shellcheck shell=bash
# wsl.lib.spec.sh — BDD spec for wsl.lib.sh

# --- テスト基盤 -------------------------------------------------------------

Include "${SHELLSPEC_PROJECT_ROOT}/runners/libs/__tests__/spec_helper.sh"

# --- テスト対象 -------------------------------------------------------------

Include "${SHELLSPEC_PROJECT_ROOT}/runners/libs/wsl.lib.sh"

# --- 内部ヘルパー -----------------------------------------------------------

# 定数

# is_windows_host() が Windows ホストと判定すべき `uname -s` の値（T-RUN-IWH-01 の入力表）
%const _IWH_WINDOWS_OS_NAMES: MINGW64_NT-10.0-26200 MSYS_NT-10.0-26200 CYGWIN_NT-10.0

# is_windows_host() が Windows ホストと判定してはならない `uname -s` の値（T-RUN-IWH-02 の入力表）
%const _IWH_OTHER_OS_NAMES: Linux Darwin

# テスト対象の lib。PATH を差し替えたプローブから読み込むため絶対パスで持つ
_WSL_LIB="${SHELLSPEC_PROJECT_ROOT}/runners/libs/wsl.lib.sh"

# exec_in_wsl() に渡す Windows 側カレントディレクトリ（`wsl.exe --cd` の引数）
_EIW_WIN_CWD='C:\ws\deckrd'

# exec_in_wsl() に渡す WSL 側で実行するスクリプト（cwd からの相対パス）
_EIW_SCRIPT='runners/exec/shellspec-exec.sh'

# 失敗スタブが返す終了コード。0 でも 1 でもない値にして素通しであることを見分ける
_EIW_STUB_EXIT_CODE=3

# find_missing_wsl_commands() の検査対象のうち、擬似 WSL 内で呼べるコマンド
# （T-RUN-FMW-01/04 の入力。ここに無い名前は「欠けているコマンド」として扱われる）
_FMW_PRESENT_COMMANDS=('bash' 'git' 'rg')

# 擬似 WSL 内に無いコマンドを 1 個だけ混ぜた引数列（T-RUN-FMW-02 の入力）
_FMW_ONE_MISSING_COMMANDS=('bash' 'jq' 'git')

# _FMW_ONE_MISSING_COMMANDS のうち擬似 WSL 内で呼べないもの（T-RUN-FMW-02 の期待出力）
_FMW_ONE_MISSING_EXPECTED='jq'

# 擬似 WSL 内に無いコマンドを 2 個混ぜた引数列（T-RUN-FMW-03 の入力）
_FMW_TWO_MISSING_COMMANDS=('jq' 'bash' 'fzf')

# _FMW_TWO_MISSING_COMMANDS のうち擬似 WSL 内で呼べないもの。引数順に並ぶ（T-RUN-FMW-03 の期待出力）
_FMW_TWO_MISSING_EXPECTED=('jq' 'fzf')

# wsl.exe の起動回数。調べるコマンドが何個でもこの回数に収める（T-RUN-FMW-04 の期待値）
_FMW_EXPECTED_WSL_CALLS=1

# 関数

#
# @description PATH 差し替え用のスタブ環境を作る。実機の wsl.exe に依存させないため、
#              wsl.exe を持つディレクトリと持たないディレクトリを用意し、渡された
#              PATH で is_wsl_available() を呼ぶプローブスクリプトを置く。
#              PATH を env(1) で渡すと env 自身が新しい PATH から bash を探して
#              失敗するため、PATH の差し替えはプローブの内側で行う
# @arg none
# @return 0 when the stub tree is ready
# @sideeffect Sets _STUB_DIR, _WSL_BIN_DIR, _EMPTY_BIN_DIR and _WSL_PROBE
# @sideeffect Creates those directories, the wsl.exe stub and the probe script on disk
#
_setup_wsl_path_probe() {
  _STUB_DIR="$(mktemp -d)"
  _WSL_BIN_DIR="${_STUB_DIR}/with-wsl"
  _EMPTY_BIN_DIR="${_STUB_DIR}/without-wsl"
  mkdir -p "$_WSL_BIN_DIR" "$_EMPTY_BIN_DIR"

  {
    echo '#!/usr/bin/env bash'
    echo 'printf "[%s]" "$@"'
  } >"${_WSL_BIN_DIR}/wsl.exe"
  chmod +x "${_WSL_BIN_DIR}/wsl.exe"

  _WSL_PROBE="${_STUB_DIR}/is-wsl-available-probe.sh"
  # shellcheck disable=SC2016 # プローブに書き込むスクリプト本文。ここで展開してはならない
  {
    echo '#!/usr/bin/env bash'
    echo 'PATH="$1"'
    printf '. %q\n' "$_WSL_LIB"
    echo 'is_wsl_available'
  } >"$_WSL_PROBE"
}

#
# @description _setup_wsl_path_probe() が作ったスタブ環境を消す
# @arg none
# @return 0 always
# @sideeffect Deletes _STUB_DIR and unsets the stub variables
#
_teardown_wsl_path_probe() {
  [[ -n "${_STUB_DIR:-}" ]] && rm -rf "$_STUB_DIR"
  unset _STUB_DIR _WSL_BIN_DIR _EMPTY_BIN_DIR _WSL_PROBE
}

#
# @description wsl.exe を「引数を [%s] 形式で並べて出力するだけ」のシェル関数に差し替える。
#              exec_in_wsl() が組み立てた引数列をそのまま観測するために使う
# @arg none
# @return 0 always
# @sideeffect Defines the wsl.exe shell function
#
_setup_wsl_exe_stub() {
  # shellcheck disable=SC2329 # exec_in_wsl() から間接的に呼ばれる
  wsl.exe() { printf '[%s]' "$@"; }
}

#
# @description wsl.exe を _EIW_STUB_EXIT_CODE で失敗するシェル関数に差し替える
# @arg none
# @return 0 always
# @sideeffect Defines the wsl.exe shell function
#
_setup_failing_wsl_exe_stub() {
  # shellcheck disable=SC2329 # exec_in_wsl() から間接的に呼ばれる
  wsl.exe() { return "$_EIW_STUB_EXIT_CODE"; }
}

#
# @description wsl.exe のスタブ関数を取り除く
# @arg none
# @return 0 always
# @sideeffect Undefines the wsl.exe shell function
#
_teardown_wsl_exe_stub() {
  unset -f wsl.exe
}

#
# @description 擬似 WSL として振る舞う wsl.exe をシェル関数に差し替える。
#              引数から `-c <プローブ>` を取り出し、_FMW_PRESENT_COMMANDS だけを
#              置いた bin ディレクトリを PATH にした bash でプローブを走らせる。
#              実機の WSL にも実機の PATH にも依存しない。
#              PATH を差し替えた先からは bash を探せないため、bash は絶対パスで起動する。
#              起動のたびに _FMW_CALL_LOG へ 1 行足し、起動回数を後から数えられるようにする
# @arg none
# @return 0 when the fake WSL is ready
# @sideeffect Sets _FMW_STUB_DIR, _FMW_WSL_BIN, _FMW_CALL_LOG and _FMW_BASH
# @sideeffect Creates the fake bin tree and defines the wsl.exe shell function
#
_setup_fake_wsl() {
  _FMW_STUB_DIR="$(mktemp -d)"
  _FMW_WSL_BIN="${_FMW_STUB_DIR}/bin"
  _FMW_CALL_LOG="${_FMW_STUB_DIR}/wsl-calls.log"
  _FMW_BASH="$(command -v bash)"
  mkdir -p "$_FMW_WSL_BIN"
  : >"$_FMW_CALL_LOG"

  local __command
  for __command in "${_FMW_PRESENT_COMMANDS[@]}"; do
    echo '#!/usr/bin/env bash' >"${_FMW_WSL_BIN}/${__command}"
    chmod +x "${_FMW_WSL_BIN}/${__command}"
  done

  # shellcheck disable=SC2329 # find_missing_wsl_commands() から間接的に呼ばれる
  wsl.exe() {
    printf 'wsl.exe\n' >>"$_FMW_CALL_LOG"
    local __probe=''
    while (($# > 0)); do
      if [[ "$1" == '-c' ]]; then
        __probe="$2"
        shift 2
        break
      fi
      shift
    done
    # `bash -c <script> <$0> <引数>...` の $0 に当たる語を捨て、検査対象だけを残す
    if (($# > 0)); then
      shift
    fi
    PATH="$_FMW_WSL_BIN" "$_FMW_BASH" -c "$__probe" 'wsl-probe' "$@"
  }
}

#
# @description _setup_fake_wsl() が作った擬似 WSL を片付ける
# @arg none
# @return 0 always
# @sideeffect Deletes _FMW_STUB_DIR, undefines wsl.exe and unsets the stub variables
#
_teardown_fake_wsl() {
  [[ -n "${_FMW_STUB_DIR:-}" ]] && rm -rf "$_FMW_STUB_DIR"
  unset -f wsl.exe
  unset _FMW_STUB_DIR _FMW_WSL_BIN _FMW_CALL_LOG _FMW_BASH
}

#
# @description _setup_fake_wsl() が記録した擬似 WSL の起動回数を返す
# @arg none
# @return 0 when at least one launch was recorded
# @stdout The number of wsl.exe launches recorded so far
#
_fake_wsl_call_count() {
  grep -c . "$_FMW_CALL_LOG"
}

# --- テスト本体 -------------------------------------------------------------

#
# Windows ホスト判定と WSL への委譲だけを担う lib。
#
Describe 'wsl.lib.sh'
  #
  # `uname -s` の値だけを見て Windows のシェル環境かどうかを判定する純粋関数。
  # 自身では uname を呼ばないため、OS 名を表から流し込んで検証できる
  #
  Describe 'T-RUN-IWH: is_windows_host()'
    # Git Bash / MSYS2 / Cygwin の uname -s は Windows ホストを表す
    Describe 'When: 正常系'
      # shellcheck disable=SC2086 # %const の表を 1 ケースずつに単語分割する
      Parameters:value $_IWH_WINDOWS_OS_NAMES

      It "Then: [Normal] T-RUN-IWH-01: OS 名 $1 を Windows ホストと判定する"
        When call is_windows_host "$1"
        The status should be success
      End
    End

    # Windows 以外の OS 名は判定を通してはならない
    Describe 'When: 異常系'
      # shellcheck disable=SC2086 # %const の表を 1 ケースずつに単語分割する
      Parameters:value $_IWH_OTHER_OS_NAMES

      It "Then: [Error] T-RUN-IWH-02: OS 名 $1 を Windows ホストと判定しない"
        When call is_windows_host "$1"
        The status should be failure
      End
    End

    # uname の取得に失敗した呼び出し元は空文字を渡しうる
    Describe 'When: エッジケース'
      It 'Then: [Edge] T-RUN-IWH-03: 空の OS 名を Windows ホストと判定しない'
        When call is_windows_host ''
        The status should be failure
      End
    End
  End

  #
  # このシェルから wsl.exe を呼べるかどうかを判定する。
  # 実機の WSL に依存しないよう、PATH を差し替えたプローブ経由で検証する
  #
  Describe 'T-RUN-IWA: is_wsl_available()'
    Before '_setup_wsl_path_probe'
    After '_teardown_wsl_path_probe'

    Describe 'When: 正常系'
      It 'Then: [Normal] T-RUN-IWA-01: PATH に wsl.exe があれば success を返す'
        When run bash "$_WSL_PROBE" "$_WSL_BIN_DIR"
        The status should be success
      End
    End

    Describe 'When: 異常系'
      It 'Then: [Error] T-RUN-IWA-02: PATH に wsl.exe が無ければ failure を返す'
        When run bash "$_WSL_PROBE" "$_EMPTY_BIN_DIR"
        The status should be failure
      End
    End
  End

  #
  # WSL 上でスクリプトを実行する。Windows 側のパスを持つ変数は引き継がず、
  # SKIP_INTEGRATION_TESTS だけを env(1) 経由で渡す
  #
  Describe 'T-RUN-EIW: exec_in_wsl()'
    After '_teardown_wsl_exe_stub'

    Describe 'When: 正常系'
      Before '_setup_wsl_exe_stub'

      It 'Then: [Normal] T-RUN-EIW-01: --cd / -e env / bash / スクリプト / 追加引数 の順で wsl.exe を呼ぶ'
        # shellcheck disable=SC2034 # exec_in_wsl() が読む
        SKIP_INTEGRATION_TESTS=0
        When call exec_in_wsl "$_EIW_WIN_CWD" "$_EIW_SCRIPT" 'foo.spec.sh' '--repair'
        The output should equal "[--cd][${_EIW_WIN_CWD}][-e][env][SKIP_INTEGRATION_TESTS=0][bash][${_EIW_SCRIPT}][foo.spec.sh][--repair]"
        The status should be success
      End
    End

    Describe 'When: エッジケース'
      Before '_setup_wsl_exe_stub'

      It 'Then: [Edge] T-RUN-EIW-02: SKIP_INTEGRATION_TESTS 未設定なら 1 を引き継ぐ'
        unset SKIP_INTEGRATION_TESTS
        When call exec_in_wsl "$_EIW_WIN_CWD" "$_EIW_SCRIPT"
        The output should equal "[--cd][${_EIW_WIN_CWD}][-e][env][SKIP_INTEGRATION_TESTS=1][bash][${_EIW_SCRIPT}]"
        The status should be success
      End
    End

    Describe 'When: 異常系'
      Before '_setup_failing_wsl_exe_stub'

      It 'Then: [Error] T-RUN-EIW-03: wsl.exe の終了コードをそのまま返す'
        When call exec_in_wsl "$_EIW_WIN_CWD" "$_EIW_SCRIPT"
        The status should equal "$_EIW_STUB_EXIT_CODE"
      End
    End
  End

  #
  # WSL 側で呼べないコマンドを洗い出す。wsl.exe の起動コストが高いため、
  # 何個調べても起動は 1 回に収める。
  # 実機の WSL に依存しないよう、擬似 WSL を返す wsl.exe スタブ経由で検証する
  #
  Describe 'T-RUN-FMW: find_missing_wsl_commands()'
    Before '_setup_fake_wsl'
    After '_teardown_fake_wsl'

    # WSL 側に一式揃っているなら、呼び出し元に伝えることは何も無い
    Describe 'When: 正常系'
      It 'Then: [Normal] T-RUN-FMW-01: すべて WSL 内で呼べるときは何も出力しない'
        When call find_missing_wsl_commands "${_FMW_PRESENT_COMMANDS[@]}"
        The output should be blank
        The status should be success
      End

      It 'Then: [Normal] T-RUN-FMW-04: 複数のコマンドを調べても wsl.exe の起動は 1 回だけ'
        When call find_missing_wsl_commands "${_FMW_PRESENT_COMMANDS[@]}"
        The value "$(_fake_wsl_call_count)" should equal "$_FMW_EXPECTED_WSL_CALLS"
        The status should be success
      End
    End

    # 呼べないものだけを返す。揃っているコマンドを混ぜて報告してはならない
    Describe 'When: 異常系'
      It 'Then: [Error] T-RUN-FMW-02: WSL 内に無いコマンドだけを出力する'
        When call find_missing_wsl_commands "${_FMW_ONE_MISSING_COMMANDS[@]}"
        The output should equal "$_FMW_ONE_MISSING_EXPECTED"
        The status should be success
      End

      It 'Then: [Error] T-RUN-FMW-03: 複数欠けているときは引数順に 1 行ずつ出力する'
        When call find_missing_wsl_commands "${_FMW_TWO_MISSING_COMMANDS[@]}"
        The output should equal "$(printf '%s\n' "${_FMW_TWO_MISSING_EXPECTED[@]}")"
        The status should be success
      End
    End
  End
End
