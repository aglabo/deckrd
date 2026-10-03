#!/usr/bin/env bash
# runners/__tests__/unit/shellspec-exec.spec.sh
# @(#) : BDD unit tests for shellspec-exec.sh
#
# Copyright (c) 2026- atsushifx <https://github.com/atsushifx>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT
# shellcheck shell=bash
# shellspec-exec.spec.sh — BDD spec for shellspec-exec.sh

Include "${SHELLSPEC_PROJECT_ROOT}/runners/__tests__/spec_helper.sh"
Include "${SHELLSPEC_PROJECT_ROOT}/runners/exec/shellspec-exec.sh"

SCRIPT="${SHELLSPEC_PROJECT_ROOT}/runners/exec/shellspec-exec.sh"

# --- internal helpers -------------------------------------------------------

# 定数

# setup_temp_specs() が作るフィクスチャの spec ファイル総数
# (unit 6 / integration 1 / system 1 / functional 1)
_FIXTURE_SPEC_COUNT=9

# extract_marked_path() へ渡す目印文字列。本番の目印と別綴りにして、実装が引数の
# 目印だけを見ていることを示す (T-RUN-EMP 群の入力)
_EMP_MARKER='__SPEC_MARKER__'

# 目印行が載せる PATH。区切り文字を含めて、行の残り全体が返ることを見分ける
# (T-RUN-EMP 群の期待値)
_EMP_REPORTED_PATH='/deckrd-stub/login/bin:/deckrd-stub/login/sbin'

# 2 つ目の目印行より前に現れる古い報告。最後の目印行が勝つことを見分ける
# (T-RUN-EMP-04 の入力)
_EMP_SHADOWED_PATH='/deckrd-stub/echoed/bin'

# 起動ファイル (profile チェーン) が stdout へ書く進捗行。PATH の報告ではないので
# 取り出し結果に混ざってはならない (T-RUN-EMP 群の入力)
_LOGIN_PROFILE_NOISE=$'Exec /opt/etc/profile\nExec: envrc\nExec: aliases'

# login shell のスタブが目印行に載せて報告する PATH。実在しないディレクトリにして、
# 実行者の本物の PATH と混ざらないようにする (T-RUN-EIP-01/04 の期待値)
_EIP_LOGIN_PATH='/deckrd-stub/login/bin'

# 空要素を 2 個含む報告。profile が `PATH="${PATH}:"` を重ねた形を模す
# (T-RUN-EIP-05 の入力)
_EIP_LOGIN_PATH_WITH_EMPTY='/deckrd-stub/login/bin::/deckrd-stub/login/sbin:'

# 上の報告から空要素を落とした形 (T-RUN-EIP-05 の期待値)
_EIP_LOGIN_PATH_WITHOUT_EMPTY='/deckrd-stub/login/bin:/deckrd-stub/login/sbin'

# 中身が空要素だけの報告。落とすと何も残らない (T-RUN-EIP-08 の入力)
_EIP_LOGIN_PATH_ALL_EMPTY='::'

# 失敗スタブが返す終了コード。0 でも 1 でもない値にして素通しでないことを見分ける
# (T-RUN-EIP-02 の入力)
_EIP_LOGIN_SHELL_EXIT_CODE=3

# ensure_integration_path() が login shell に渡すはずの起動フラグ
# (T-RUN-EIP-06 の期待値)
_EIP_EXPECTED_LOGIN_FLAG='-lic'

# 起動フラグを PATH の 1 要素として報告するときの前置き。フラグだけを報告すると
# PATH が `-` で始まって読みにくいので、ディレクトリの形に見せる (T-RUN-EIP-06)
_EIP_FLAG_REPORT_PREFIX='/deckrd-stub/login-flag/'

# 差し替えた profile が login shell の PATH へ足す目印のディレクトリ。実在しない
# 名前にして、実行者の本物の PATH と見分けられるようにする (T-RUN-MRS-10〜12 の期待値)
_MRS_LOGIN_MARKER_DIR='/deckrd-stub/login-marker/bin'

# 差し替えた profile が stdout へ出す進捗行。PATH に混ざってはならない
# (T-RUN-MRS-13 の期待値)
_MRS_LOGIN_NOISE='deckrd-profile-noise'

# 関数

#
# @description 目印行を 1 行書き出す。login shell スタブの共通本体。目印は呼ばれた
#              ときに渡された綴りをそのまま使うので、プローブが目印を位置パラメータで
#              渡していることも同時に押さえられる
# @arg $1 string スタブが報告する PATH
# @arg $2 string プローブが渡した目印
# @return 0 always
# @stdout 空行 1 行と目印行
#
_print_login_path_report() {
  printf '\n%s%s\n' "$2" "$1"
}

#
# @description login shell を、目印行だけを返すシェル関数に差し替える。
#              ensure_integration_path() は bash をフルパスではなく名前で呼ぶので、
#              シェル関数で覆える。実行者の profile に依存させないために使う
#              (T-RUN-EIP-01 の入力)
# @arg none
# @return 0 always
# @sideeffect Saves the current PATH into _EIP_ORIG_PATH
# @sideeffect Defines the bash shell function
#
_setup_login_shell_stub() {
  _EIP_ORIG_PATH="$PATH"
  # shellcheck disable=SC2329 # ensure_integration_path() から間接的に呼ばれる
  bash() { _print_login_path_report "$_EIP_LOGIN_PATH" "${4:-}"; }
}

#
# @description login shell を、何も出力せず失敗するシェル関数に差し替える。
#              profile の読み込みに失敗する環境を模す (T-RUN-EIP-02 の入力)
# @arg none
# @return 0 always
# @sideeffect Redefines the bash shell function
#
_setup_failing_login_shell_stub() {
  # shellcheck disable=SC2329 # ensure_integration_path() から間接的に呼ばれる
  bash() { return "$_EIP_LOGIN_SHELL_EXIT_CODE"; }
}

#
# @description login shell を、成功するが何も出力しないシェル関数に差し替える。
#              profile が PATH を出力しない環境を模す (T-RUN-EIP-03 の入力)
# @arg none
# @return 0 always
# @sideeffect Redefines the bash shell function
#
_setup_silent_login_shell_stub() {
  # shellcheck disable=SC2329 # ensure_integration_path() から間接的に呼ばれる
  bash() { return 0; }
}

#
# @description login shell を、profile の進捗行を出してから目印行を返すシェル関数に
#              差し替える。実行者の profile が stdout へ書く環境を模す
#              (T-RUN-EIP-04 の入力)
# @arg none
# @return 0 always
# @sideeffect Redefines the bash shell function
#
_setup_noisy_login_shell_stub() {
  # shellcheck disable=SC2329 # ensure_integration_path() から間接的に呼ばれる
  bash() {
    printf '%s\n' "$_LOGIN_PROFILE_NOISE"
    _print_login_path_report "$_EIP_LOGIN_PATH" "${4:-}"
  }
}

#
# @description login shell を、進捗行だけを出して目印行を返さないシェル関数に
#              差し替える。プローブ本文が profile に潰された環境を模す
#              (T-RUN-EIP-07 の入力)
# @arg none
# @return 0 always
# @sideeffect Redefines the bash shell function
#
_setup_markerless_login_shell_stub() {
  # shellcheck disable=SC2329 # ensure_integration_path() から間接的に呼ばれる
  bash() { printf '%s\n' "$_LOGIN_PROFILE_NOISE"; }
}

#
# @description login shell を、空要素を含む PATH を報告するシェル関数に差し替える。
#              実行者の profile が作る `::` を模す (T-RUN-EIP-05 の入力)
# @arg none
# @return 0 always
# @sideeffect Redefines the bash shell function
#
_setup_empty_entry_login_shell_stub() {
  # shellcheck disable=SC2329 # ensure_integration_path() から間接的に呼ばれる
  bash() { _print_login_path_report "$_EIP_LOGIN_PATH_WITH_EMPTY" "${4:-}"; }
}

#
# @description login shell を、空要素だけの PATH を報告するシェル関数に差し替える。
#              空要素を落とすと何も残らない報告を模す (T-RUN-EIP-08 の入力)
# @arg none
# @return 0 always
# @sideeffect Redefines the bash shell function
#
_setup_all_empty_login_shell_stub() {
  # shellcheck disable=SC2329 # ensure_integration_path() から間接的に呼ばれる
  bash() { _print_login_path_report "$_EIP_LOGIN_PATH_ALL_EMPTY" "${4:-}"; }
}

#
# @description login shell を、受け取った起動フラグを PATH として報告するシェル関数に
#              差し替える。スタブは command substitution の中で走るため、受け取った
#              引数を変数で持ち帰れない。報告経路 (目印行) に載せれば、呼び出し元の
#              PATH として観測できる (T-RUN-EIP-06 の入力)
# @arg none
# @return 0 always
# @sideeffect Redefines the bash shell function
#
_setup_flag_reporting_login_shell_stub() {
  # shellcheck disable=SC2329 # ensure_integration_path() から間接的に呼ばれる
  bash() { _print_login_path_report "${_EIP_FLAG_REPORT_PREFIX}${1}" "${4:-}"; }
}

#
# @description login shell スタブを外し、PATH を元へ戻す
# @arg none
# @return 0 always
# @sideeffect Restores PATH from _EIP_ORIG_PATH and unsets the stub variable
# @sideeffect Removes the bash shell function
#
_teardown_login_shell_stub() {
  unset -f bash
  PATH="$_EIP_ORIG_PATH"
  unset _EIP_ORIG_PATH
}

#
# @description Install a ShellSpec stub that reports what it was launched with
#              instead of running specs. The stub body is given by the caller and
#              is written verbatim below the shebang
# @arg $1 string bash statement the stub executes when launched
# @sideeffect Sets _STUB_DIR and _SHELLSPEC_STUB
#
_install_shellspec_stub() {
  _STUB_DIR="$(mktemp -d)"
  _SHELLSPEC_STUB="${_STUB_DIR}/shellspec-stub"
  printf '#!/usr/bin/env bash\n%s\n' "$1" >"$_SHELLSPEC_STUB"
}

#
# @description Install a ShellSpec stub that prints its argv instead of running specs
# @sideeffect Sets _STUB_DIR and _SHELLSPEC_STUB
#
_setup_shellspec_stub() {
  _install_shellspec_stub 'printf "[%s]" "$@"'
}

#
# @description Install a ShellSpec stub that prints the SKIP_INTEGRATION_TESTS value
#              it was launched with. run_shellspec() exports the variable into the
#              ShellSpec process, so the stub observes exactly what the real
#              ShellSpec would see
# @sideeffect Sets _STUB_DIR and _SHELLSPEC_STUB
#
_setup_integration_probe_stub() {
  # stub の起動時に評価させるため、ここでは展開しない
  # shellcheck disable=SC2016
  _install_shellspec_stub 'printf "%s" "${SKIP_INTEGRATION_TESTS:-unset}"'
}

#
# @description Install a ShellSpec stub that prints the PATH it was launched with,
#              together with a throwaway HOME whose profile appends _MRS_LOGIN_MARKER_DIR.
#              main() runs in a separate process, so the login shell cannot be a
#              shell function there; swapping HOME pins what `bash -lic` reports
#              instead, keeping the example independent of the runner's own profile.
#              The fixture is `~/.bash_profile` and not `~/.bashrc`: an interactive
#              *login* shell reads the login files, and reaches an rc only through a
#              source the login files make — which a throwaway HOME has none of
# @arg none
# @return 0 always
# @sideeffect Sets _STUB_DIR, _SHELLSPEC_STUB and _FAKE_HOME
# @sideeffect Creates the fake home directory and its .bash_profile on disk
#
_setup_login_path_probe() {
  # stub の起動時に評価させるため、ここでは展開しない
  # shellcheck disable=SC2016
  _install_shellspec_stub 'printf "%s" "$PATH"'
  _FAKE_HOME="${_STUB_DIR}/home"
  mkdir -p "$_FAKE_HOME"
  # 実行者の profile がしている 3 つを再現する: stdout への進捗行、対話シェルのときだけ
  # 効く PATH 追加、そして空要素。目印が付くのは login かつ対話のときだけなので、
  # 目印の有無が `-lic` で起動したことの証明になる
  {
    printf 'printf "%%s\\n" "%s"\n' "$_MRS_LOGIN_NOISE"
    # shellcheck disable=SC2016 # login shell 側で展開させる $- と $PATH
    printf 'case $- in *i*) PATH="${PATH}::%s" ;; esac\n' "$_MRS_LOGIN_MARKER_DIR"
  } >"${_FAKE_HOME}/.bash_profile"
}

#
# @description Remove the stub installed by _install_shellspec_stub()
# @sideeffect Deletes _STUB_DIR and unsets the stub variables
#
_teardown_shellspec_stub() {
  [[ -n "${_STUB_DIR:-}" ]] && rm -rf "$_STUB_DIR"
  unset _STUB_DIR _SHELLSPEC_STUB
}

#
# @description _setup_login_path_probe() が作ったスタブ環境を消す。差し替えた HOME は
#              _STUB_DIR の下にあるので、ShellSpec スタブと一緒に消える
# @arg none
# @return 0 always
# @sideeffect Deletes _STUB_DIR and unsets the stub variables
#
_teardown_login_path_probe() {
  _teardown_shellspec_stub
  unset _FAKE_HOME
}

Describe 'T-RUN-ITT: is_test_type()'
  Describe 'valid test types'
    It 'T-RUN-ITT-01: returns success for all'
      When call is_test_type 'all'
      The status should be success
    End

    It 'T-RUN-ITT-02: returns success for unit'
      When call is_test_type 'unit'
      The status should be success
    End

    It 'T-RUN-ITT-03: returns success for functional'
      When call is_test_type 'functional'
      The status should be success
    End

    It 'T-RUN-ITT-04: returns success for integration'
      When call is_test_type 'integration'
      The status should be success
    End

    It 'T-RUN-ITT-05: returns success for system'
      When call is_test_type 'system'
      The status should be success
    End

    It 'T-RUN-ITT-06: returns success for e2e'
      When call is_test_type 'e2e'
      The status should be success
    End
  End

  Describe 'invalid test types'
    It 'T-RUN-ITT-07: returns failure for spec'
      When call is_test_type 'spec'
      The status should be failure
    End

    It 'T-RUN-ITT-08: returns failure for empty string'
      When call is_test_type ''
      The status should be failure
    End

    It 'T-RUN-ITT-09: returns failure for uppercase ALL'
      When call is_test_type 'ALL'
      The status should be failure
    End

    It 'T-RUN-ITT-10: returns failure for unknowntype'
      When call is_test_type 'unknowntype'
      The status should be failure
    End
  End
End

Describe 'T-RUN-ISF: is_spec_file()'
  Describe 'valid spec file paths'
    It 'T-RUN-ISF-01: returns success for foo.spec.sh'
      When call is_spec_file 'foo.spec.sh'
      The status should be success
    End

    It 'T-RUN-ISF-02: returns success for path/to/bar.spec.sh'
      When call is_spec_file 'path/to/bar.spec.sh'
      The status should be success
    End
  End

  Describe 'invalid spec file paths'
    It 'T-RUN-ISF-03: returns failure for foo.sh'
      When call is_spec_file 'foo.sh'
      The status should be failure
    End

    It 'T-RUN-ISF-04: returns failure for unit'
      When call is_spec_file 'unit'
      The status should be failure
    End

    It 'T-RUN-ISF-05: returns failure for spec.sh (no .spec. pattern)'
      When call is_spec_file 'spec.sh'
      The status should be failure
    End

    It 'T-RUN-ISF-06: returns failure for empty string'
      When call is_spec_file ''
      The status should be failure
    End
  End
End

Describe 'get_spec_files()'
  Before 'setup_temp_specs'
  After 'teardown_temp_specs'

  Describe 'T-RUN-GSF: test type expansion'
    It 'T-RUN-GSF-01: returns spec files under tests/ for all'
      When call get_spec_files 'all'
      The output should include '.spec.sh'
      The status should be success
    End

    It 'T-RUN-GSF-02: returns only unit spec files for unit'
      When call get_spec_files 'unit'
      The output should include '__tests__/unit'
      The status should be success
    End

    It 'T-RUN-GSF-03: does not include integration files for unit'
      When call get_spec_files 'unit'
      The output should not include '__tests__/integration'
    End

    It 'T-RUN-GSF-04: filters by glob pattern init* for unit'
      When call get_spec_files 'unit' 'init*'
      The output should include 'init'
      The status should be success
    End

    It 'T-RUN-GSF-05: filters by exact name kv-store for unit'
      When call get_spec_files 'unit' 'kv-store'
      The output should include 'kv-store'
      The status should be success
    End

    It 'T-RUN-GSF-06: output paths do not contain backslashes'
      When call get_spec_files 'all'
      # shellcheck disable=SC1003
      The output should not include '\'
    End

    # 種別名が `__tests__/<type>/` として解決されることを確かめる
    Describe 'When: 正常系'
      It '[Normal] T-RUN-GSF-07: returns the functional spec for functional'
        When call get_spec_files 'functional'
        The output should include '__tests__/functional'
        The status should be success
      End

      It '[Normal] T-RUN-GSF-08: collects unit specs from nested __tests__ roots'
        When call get_spec_files 'unit'
        The output should include 'subcommands/__tests__/unit'
        The status should be success
      End

      It '[Normal] T-RUN-GSF-09: returns every fixture spec for all'
        When call get_spec_files 'all'
        The lines of output should equal "$_FIXTURE_SPEC_COUNT"
        The status should be success
      End
    End
  End
End

Describe 'T-RUN-PO: parse_options()'
  Before 'SKIP_INTEGRATION_TESTS=1'

  Describe '--integration flag handling'
    # ゲートの開閉は should_enable_integration() の責務。parse_options() は
    # フラグを取り除くだけで SKIP_INTEGRATION_TESTS に触れない
    It 'T-RUN-PO-01: removes a trailing --integration without touching SKIP_INTEGRATION_TESTS'
      When call parse_options 'unit' '--integration'
      The output should equal 'unit'
      The variable SKIP_INTEGRATION_TESTS should equal '1'
    End

    It 'T-RUN-PO-02: removes leading --integration flag'
      When call parse_options '--integration' 'unit'
      The output should equal 'unit'
    End
  End

  Describe 'passthrough of other options'
    It 'T-RUN-PO-03: passes --focus through unchanged'
      When call parse_options 'unit' '--focus'
      The output should include 'unit'
      The output should include '--focus'
    End

    It 'T-RUN-PO-04: returns empty output for no arguments'
      When call parse_options
      The output should equal ''
    End
  End
End

Describe 'T-RUN-ISG: is_spec_glob()'
  Describe 'spec glob patterns'
    It 'T-RUN-ISG-01: returns success for runners/libs/__tests__/unit/*.spec.sh'
      When call is_spec_glob 'runners/libs/__tests__/unit/*.spec.sh'
      The status should be success
    End
  End

  Describe 'non-spec-glob patterns'
    It 'T-RUN-ISG-02: returns failure for init* (no .spec.sh)'
      When call is_spec_glob 'init*'
      The status should be failure
    End

    It 'T-RUN-ISG-03: returns failure for foo.spec.sh (no glob)'
      When call is_spec_glob 'foo.spec.sh'
      The status should be failure
    End
  End
End

Describe 'expand_spec_glob()'
  Before 'setup_temp_specs'
  After 'teardown_temp_specs'

  Describe 'T-RUN-ESG: glob expansion'
    It 'T-RUN-ESG-01: returns matching spec files for runners/libs/__tests__/unit/*.spec.sh'
      When call expand_spec_glob 'runners/libs/__tests__/unit/*.spec.sh'
      The output should include '.spec.sh'
      The status should be success
    End

    It 'T-RUN-ESG-02: exits with 0 and warns for non-matching glob'
      When call expand_spec_glob 'runners/libs/__tests__/unit/nonexistent*.spec.sh'
      The stderr should include 'Warning'
      The status should be success
    End
  End
End

Describe 'T-RUN-RSF: resolve_spec_files()'
  Before 'SKIP_INTEGRATION_TESTS=1'

  Describe 'single spec file passthrough'
    It 'T-RUN-RSF-01: returns spec file unchanged for foo.spec.sh'
      When call resolve_spec_files 'foo.spec.sh'
      The output should equal 'foo.spec.sh'
      The status should be success
    End
  End

  Describe 'spec glob expansion'
    It 'T-RUN-RSF-02: expands glob pattern runners/libs/__tests__/unit/*.spec.sh'
      When call resolve_spec_files 'runners/libs/__tests__/unit/*.spec.sh'
      The output should include '.spec.sh'
      The status should be success
    End
  End

  Describe 'test type expansion'
    Before 'setup_temp_specs'
    After 'teardown_temp_specs'

    It 'T-RUN-RSF-03: expands unit to unit spec files'
      When call resolve_spec_files 'unit'
      The output should include '__tests__/unit'
      The status should be success
    End

    # 種別の展開だけを行う。ゲートの開閉は should_enable_integration() の責務
    It 'T-RUN-RSF-04: expands system without touching SKIP_INTEGRATION_TESTS'
      When call resolve_spec_files 'system'
      The variable SKIP_INTEGRATION_TESTS should equal '1'
      The output should include '__tests__/system'
      The status should be success
    End

    # 種別名が `__tests__/<type>/` として解決されることを確かめる
    Describe 'When: 正常系'
      It '[Normal] T-RUN-RSF-07: expands functional to the functional spec'
        When call resolve_spec_files 'functional'
        The output should include '__tests__/functional'
        The status should be success
      End

      # T-RUN-RSF-03 が stdout を見るのに対し、こちらは stderr を見る。
      # 種別が解決できないと "No spec files found" 警告が出る回帰を防ぐ
      It '[Normal] T-RUN-RSF-08: leaves stderr silent when unit specs are found'
        When call resolve_spec_files 'unit'
        The output should be present
        The stderr should be blank
      End
    End

    # フィクスチャに e2e ディレクトリは無い (spec_helper.sh の意図的な欠落)
    Describe 'When: 異常系'
      It '[Error] T-RUN-RSF-09: warns and succeeds when no spec matches the type'
        When call resolve_spec_files 'e2e'
        The stderr should include "No spec files found for test type 'e2e'"
        The output should be blank
        The status should be success
      End
    End
  End

  Describe 'error handling'
    It 'T-RUN-RSF-05: exits with failure for unknown test type'
      When call resolve_spec_files 'unknowntype'
      The stderr should include "Error: Unknown argument 'unknowntype'"
      The output should be blank
      The status should be failure
    End

    It 'T-RUN-RSF-06: reports missing arguments on stderr'
      When call resolve_spec_files
      The stderr should include 'Error: No arguments given.'
      The output should be blank
      The status should be failure
    End
  End

  # 2 本目以降の対象が黙って捨てられる回帰を防ぐ
  Describe 'multiple targets'
    Describe 'When: 正常系'
      It '[Normal] T-RUN-RSF-10: outputs every spec file when given two spec files'
        When call resolve_spec_files 'a.spec.sh' 'b.spec.sh'
        The output should equal "$(printf '%s\n' 'a.spec.sh' 'b.spec.sh')"
        The status should be success
      End

      It '[Normal] T-RUN-RSF-11: outputs the spec file then the glob expansion'
        When call resolve_spec_files 'a.spec.sh' 'runners/libs/__tests__/unit/*.spec.sh'
        The line 1 of output should equal 'a.spec.sh'
        The line 2 of output should include '.spec.sh'
        # glob 文字列も *.spec.sh で終わる。未展開のまま素通りした場合をここで弾く
        The output should not include '*'
        The status should be success
      End
    End

    Describe 'When: 異常系'
      It '[Error] T-RUN-RSF-12: fails without partial output when a later argument is unknown'
        When call resolve_spec_files 'a.spec.sh' 'unknownarg'
        The stderr should include "Unknown argument 'unknownarg'"
        The output should be blank
        The status should be failure
      End
    End
  End
End

# 引数列から実機テスト (integration) を有効化すべきかだけを判定する純粋関数。
# main() はこの判定を親シェルで行い、SKIP_INTEGRATION_TESTS へ反映する
Describe 'T-RUN-SEI: should_enable_integration()'
  Describe 'When: 正常系'
    It '[Normal] T-RUN-SEI-01: returns success when --integration is present'
      When call should_enable_integration 'foo.spec.sh' '--integration'
      The status should be success
    End

    It '[Normal] T-RUN-SEI-02: returns success for the system test type'
      When call should_enable_integration 'system'
      The status should be success
    End

    It '[Normal] T-RUN-SEI-03: returns failure for a plain test type'
      When call should_enable_integration 'unit'
      The status should be failure
    End
  End

  # ターゲットは先頭に並ぶ。オプションの値として現れた 'system' は種別ではない
  Describe 'When: エッジケース'
    It '[Edge] T-RUN-SEI-04: returns failure when system is only an option value'
      When call should_enable_integration 'foo.spec.sh' '--format' 'system'
      The status should be failure
    End
  End
End

# login shell のプローブの stdout には、起動ファイルの進捗行と PATH の報告が混ざる。
# 出力全体を PATH として扱うとゴミ要素が入るため、プローブが PATH の直前へ置いた
# 目印行を探し、その行の残りだけを取り出す。引数以外を読まない純粋関数とする
Describe 'T-RUN-EMP: extract_marked_path()'
  Describe 'When: 正常系'
    It '[Normal] T-RUN-EMP-01: returns the remainder of the marked line'
      When call extract_marked_path "$_EMP_MARKER" $'\n'"${_EMP_MARKER}${_EMP_REPORTED_PATH}"
      The output should equal "$_EMP_REPORTED_PATH"
      The status should be success
    End

    It '[Normal] T-RUN-EMP-02: leaves the startup output printed before the marked line out'
      When call extract_marked_path "$_EMP_MARKER" "${_LOGIN_PROFILE_NOISE}"$'\n\n'"${_EMP_MARKER}${_EMP_REPORTED_PATH}"
      The output should equal "$_EMP_REPORTED_PATH"
      The status should be success
    End

    It '[Normal] T-RUN-EMP-03: leaves the lines that follow the marked line out'
      When call extract_marked_path "$_EMP_MARKER" $'\n'"${_EMP_MARKER}${_EMP_REPORTED_PATH}"$'\nExec: aliases'
      The output should equal "$_EMP_REPORTED_PATH"
      The status should be success
    End

    # 起動ファイルが目印と同じ綴りを印字しても、プローブが最後に足した 1 行が勝つ
    It '[Normal] T-RUN-EMP-04: takes the last marked line when the output holds two'
      When call extract_marked_path "$_EMP_MARKER" $'\n'"${_EMP_MARKER}${_EMP_SHADOWED_PATH}"$'\n'"${_EMP_MARKER}${_EMP_REPORTED_PATH}"
      The output should equal "$_EMP_REPORTED_PATH"
      The status should be success
    End
  End

  # 目印行が見つからなければ、どこからどこまでが報告なのか決められない。黙って
  # 何かを返すと、呼び出し元が進捗行を PATH として採ってしまう
  Describe 'When: 異常系'
    It '[Error] T-RUN-EMP-05: fails when the output holds no marked line'
      When call extract_marked_path "$_EMP_MARKER" "$_LOGIN_PROFILE_NOISE"
      The output should be blank
      The status should be failure
    End

    # 行の途中の目印は、進捗行が目印の綴りを含んだだけと見なす
    It '[Error] T-RUN-EMP-06: fails when the marker appears only inside a line'
      When call extract_marked_path "$_EMP_MARKER" $'\nExec: '"${_EMP_MARKER}${_EMP_REPORTED_PATH}"
      The output should be blank
      The status should be failure
    End
  End

  Describe 'When: エッジケース'
    It '[Edge] T-RUN-EMP-07: fails for empty output'
      When call extract_marked_path "$_EMP_MARKER" ''
      The output should be blank
      The status should be failure
    End

    # 目印行はあるが PATH が空。報告そのものは届いているので成功とし、空を返す。
    # 空の報告をどう扱うかは呼び出し元が決める
    It '[Edge] T-RUN-EMP-08: returns nothing when the marked line carries no PATH'
      When call extract_marked_path "$_EMP_MARKER" "${_LOGIN_PROFILE_NOISE}"$'\n'"${_EMP_MARKER}"
      The output should be blank
      The status should be success
    End

    # 起動ファイルが何も出さなければ目印行が 1 行目に来る。行頭の目印として扱う
    It '[Edge] T-RUN-EMP-09: accepts a marked line that is the first line'
      When call extract_marked_path "$_EMP_MARKER" "${_EMP_MARKER}${_EMP_REPORTED_PATH}"
      The output should equal "$_EMP_REPORTED_PATH"
      The status should be success
    End
  End
End

# PATH の空要素はカレントディレクトリを指す。報告された PATH をそのまま使うと、
# ShellSpec が走っているディレクトリがコマンド探索の対象に入る。
# 引数以外を読まない純粋関数とする
Describe 'T-RUN-DPE: drop_empty_path_entries()'
  Describe 'When: 正常系'
    Parameters
      '/deckrd-stub/a:/deckrd-stub/b' '/deckrd-stub/a:/deckrd-stub/b'
      '/deckrd-stub/a::/deckrd-stub/b' '/deckrd-stub/a:/deckrd-stub/b'
      ':/deckrd-stub/a:/deckrd-stub/b' '/deckrd-stub/a:/deckrd-stub/b'
      '/deckrd-stub/a:/deckrd-stub/b:' '/deckrd-stub/a:/deckrd-stub/b'
      '/deckrd-stub/a::/deckrd-stub/b::/deckrd-stub/c' '/deckrd-stub/a:/deckrd-stub/b:/deckrd-stub/c'
      '/deckrd-stub/a' '/deckrd-stub/a'
    End

    It "[Normal] T-RUN-DPE-01: drops the empty entries of '$1' -> '$2'"
      When call drop_empty_path_entries "$1"
      The output should equal "$2"
      The status should be success
    End
  End

  # 残る要素が 1 個も無い報告。空の PATH を返し、どう扱うかは呼び出し元が決める
  Describe 'When: エッジケース'
    Parameters
      # shellcheck disable=SC2286 # Parameters の行は引数列。空の PATH を渡す 1 行であってコマンドではない
      ''
      ':'
      '::'
    End

    It "[Edge] T-RUN-DPE-02: returns nothing for '$1'"
      When call drop_empty_path_entries "$1"
      The output should be blank
      The status should be success
    End
  End
End

# 実機テストに必要な CLI は、ユーザーの profile が PATH へ足している。
# このスクリプトが動く非ログインシェルには profile が効かないため、
# login shell が報告する PATH で置き換えて届くようにする
Describe 'T-RUN-EIP: ensure_integration_path()'
  Before '_setup_login_shell_stub'
  After '_teardown_login_shell_stub'

  Describe 'When: 正常系'
    # 報告は継ぎ足すのではなく置き換える。報告は継承した PATH の上位集合なので、
    # 継承側を前に残すと profile が入れたツールが同名の古いもので隠れる
    It '[Normal] T-RUN-EIP-01: replaces PATH with the PATH the login shell reports'
      When call ensure_integration_path
      The variable PATH should equal "$_EIP_LOGIN_PATH"
      The status should be success
    End

    # 報告を丸ごと取り込むと、profile の進捗行が PATH の要素になる
    Describe 'profile が stdout へ進捗行を書く'
      Before '_setup_noisy_login_shell_stub'

      It '[Normal] T-RUN-EIP-04: keeps the profile output out of PATH'
        When call ensure_integration_path
        The variable PATH should equal "$_EIP_LOGIN_PATH"
        The status should be success
      End
    End

    Describe 'profile が空要素を作る'
      Before '_setup_empty_entry_login_shell_stub'

      It '[Normal] T-RUN-EIP-05: drops the empty entries of the reported PATH'
        When call ensure_integration_path
        The variable PATH should equal "$_EIP_LOGIN_PATH_WITHOUT_EMPTY"
        The status should be success
      End
    End

    # PATH を足す処理は login ファイルと対話 rc に分かれて置かれうる。login かつ
    # 対話のシェルで起動しないと、報告がどちらか片方だけになる
    Describe 'login shell の起動フラグ'
      Before '_setup_flag_reporting_login_shell_stub'

      It '[Normal] T-RUN-EIP-06: starts the login shell as a login and interactive shell'
        When call ensure_integration_path
        The variable PATH should equal "${_EIP_FLAG_REPORT_PREFIX}${_EIP_EXPECTED_LOGIN_FLAG}"
        The status should be success
      End
    End
  End

  # PATH の置き換えは実機テストの補助でしかない。login shell が起動できなくても
  # ShellSpec の実行そのものは止めない
  Describe 'When: エッジケース'
    Describe 'login shell が起動できない'
      Before '_setup_failing_login_shell_stub'

      It '[Edge] T-RUN-EIP-02: leaves PATH untouched and succeeds when the login shell fails'
        When call ensure_integration_path
        The variable PATH should equal "$_EIP_ORIG_PATH"
        The status should be success
      End
    End

    # 空の報告で置き換えると PATH が空になり、以降どのコマンドも解決できない
    Describe 'login shell が何も出力しない'
      Before '_setup_silent_login_shell_stub'

      It '[Edge] T-RUN-EIP-03: leaves PATH untouched when the login shell reports nothing'
        When call ensure_integration_path
        The variable PATH should equal "$_EIP_ORIG_PATH"
        The status should be success
      End
    End

    # 目印行が無ければ、どこからどこまでが報告なのか決められない
    Describe '目印行が返ってこない'
      Before '_setup_markerless_login_shell_stub'

      It '[Edge] T-RUN-EIP-07: leaves PATH untouched when no marked line is reported'
        When call ensure_integration_path
        The variable PATH should equal "$_EIP_ORIG_PATH"
        The status should be success
      End
    End

    # 空要素を落とすと何も残らない報告は、空の報告と同じに扱う
    Describe '報告が空要素だけ'
      Before '_setup_all_empty_login_shell_stub'

      It '[Edge] T-RUN-EIP-08: leaves PATH untouched when the report holds only empty entries'
        When call ensure_integration_path
        The variable PATH should equal "$_EIP_ORIG_PATH"
        The status should be success
      End
    End
  End
End

Describe 'T-RUN-MRS: main()'
  Describe 'invalid argument handling'
    # ShellSpec strips trailing newlines from captured stderr, so a stray blank
    # line is invisible to 'The lines of stderr'. Count the lines in-pipeline and
    # propagate the script exit code via PIPESTATUS.
    It 'T-RUN-MRS-01: writes exactly one stderr line for an unknown argument'
      When run bash -c "bash \"$SCRIPT\" unknowntype 2>&1 1>/dev/null | grep -c ^; exit \${PIPESTATUS[0]}"
      The output should equal '1'
      The status should equal 1
    End

    It 'T-RUN-MRS-02: reports the unknown argument on stderr'
      When run bash "$SCRIPT" unknowntype
      The stderr should include "Unknown argument 'unknowntype'"
      The output should be blank
      The status should equal 1
    End
  End

  Describe 'ShellSpec option passthrough'
    Before '_setup_shellspec_stub'
    After '_teardown_shellspec_stub'

    Describe 'When: 正常系'
      It '[Normal] T-RUN-MRS-03: forwards an option placed after the spec file to ShellSpec'
        When run env SHELLSPEC="$_SHELLSPEC_STUB" bash "$SCRIPT" 'foo.spec.sh' '--repair'
        The output should equal '[foo.spec.sh][--repair]'
        The status should be success
      End

      It '[Normal] T-RUN-MRS-04: keeps the value of a value-taking option out of the targets'
        When run env SHELLSPEC="$_SHELLSPEC_STUB" bash "$SCRIPT" 'foo.spec.sh' '--format' 'documentation'
        The output should equal '[foo.spec.sh][--format][documentation]'
        The status should be success
      End

      It '[Normal] T-RUN-MRS-05: consumes --integration itself and forwards the remaining options'
        When run env SHELLSPEC="$_SHELLSPEC_STUB" SKIP_INTEGRATION_TESTS=1 bash "$SCRIPT" 'foo.spec.sh' '--integration' '--repair'
        The output should equal '[foo.spec.sh][--repair]'
        The status should be success
      End
    End

    Describe 'When: エッジケース'
      It '[Edge] T-RUN-MRS-06: launches ShellSpec with the target alone when no option is given'
        When run env SHELLSPEC="$_SHELLSPEC_STUB" bash "$SCRIPT" 'foo.spec.sh'
        The output should equal '[foo.spec.sh]'
        The status should be success
      End
    End
  End

  # 実機テストの有効化は ShellSpec の起動環境に載って初めて効く。
  # 判定をサブシェルで行うと親シェルへ戻らず、既定値のまま起動してしまう。
  # 既定値 1 (開発モード) は env で明示し、テスト実行者の環境から切り離す
  Describe 'integration gate propagation'
    Before '_setup_integration_probe_stub'
    After '_teardown_shellspec_stub'

    Describe 'When: 正常系'
      It '[Normal] T-RUN-MRS-07: launches ShellSpec with SKIP_INTEGRATION_TESTS=0 for --integration'
        When run env SHELLSPEC="$_SHELLSPEC_STUB" SKIP_INTEGRATION_TESTS=1 bash "$SCRIPT" 'foo.spec.sh' '--integration'
        The output should equal '0'
        The status should be success
      End
    End

    # 種別を渡す経路はフィクスチャ (setup_temp_specs) の spec ツリーへ向ける
    Describe 'test type targets'
      Before 'setup_temp_specs'
      After 'teardown_temp_specs'

      Describe 'When: 正常系'
        It '[Normal] T-RUN-MRS-08: launches ShellSpec with SKIP_INTEGRATION_TESTS=0 for system'
          When run env SHELLSPEC="$_SHELLSPEC_STUB" SPEC_SEARCH_ROOT="$TEMP_DIR" SKIP_INTEGRATION_TESTS=1 bash "$SCRIPT" 'system'
          The output should equal '0'
          The status should be success
        End

        It '[Normal] T-RUN-MRS-09: keeps SKIP_INTEGRATION_TESTS=1 for unit'
          When run env SHELLSPEC="$_SHELLSPEC_STUB" SPEC_SEARCH_ROOT="$TEMP_DIR" SKIP_INTEGRATION_TESTS=1 bash "$SCRIPT" 'unit'
          The output should equal '1'
          The status should be success
        End
      End
    End
  End

  # 実機テストに必要な CLI はユーザーの profile が PATH へ足しており、この
  # スクリプトが動く非ログインシェルには届いていない。ゲートを開けるときに
  # login shell の PATH も ShellSpec の起動環境へ載せないと、全件 skip される
  Describe 'login PATH propagation'
    Before '_setup_login_path_probe'
    After '_teardown_login_path_probe'

    Describe 'When: 正常系'
      # 差し替えた profile は対話シェルのときだけ目印を足すので、この 1 件が
      # `-lic` で起動していることの end-to-end の証明にもなる
      It '[Normal] T-RUN-MRS-10: launches ShellSpec with the login PATH for --integration'
        When run env SHELLSPEC="$_SHELLSPEC_STUB" HOME="$_FAKE_HOME" SKIP_INTEGRATION_TESTS=1 bash "$SCRIPT" 'foo.spec.sh' '--integration'
        The output should include "$_MRS_LOGIN_MARKER_DIR"
        The status should be success
      End

      # 報告を丸ごと取り込むと、profile の進捗行が PATH の要素として ShellSpec に渡る
      It '[Normal] T-RUN-MRS-13: keeps the profile stdout out of the ShellSpec PATH'
        When run env SHELLSPEC="$_SHELLSPEC_STUB" HOME="$_FAKE_HOME" SKIP_INTEGRATION_TESTS=1 bash "$SCRIPT" 'foo.spec.sh' '--integration'
        The output should not include "$_MRS_LOGIN_NOISE"
        The status should be success
      End

      # 空要素はカレントディレクトリを指す。ShellSpec の実行位置が探索対象に入る
      It '[Normal] T-RUN-MRS-14: keeps the profile empty PATH entry out of the ShellSpec PATH'
        When run env SHELLSPEC="$_SHELLSPEC_STUB" HOME="$_FAKE_HOME" SKIP_INTEGRATION_TESTS=1 bash "$SCRIPT" 'foo.spec.sh' '--integration'
        The output should not include '::'
        The status should be success
      End
    End

    # 種別を渡す経路はフィクスチャ (setup_temp_specs) の spec ツリーへ向ける
    Describe 'test type targets'
      Before 'setup_temp_specs'
      After 'teardown_temp_specs'

      Describe 'When: 正常系'
        It '[Normal] T-RUN-MRS-11: launches ShellSpec with the login PATH for system'
          When run env SHELLSPEC="$_SHELLSPEC_STUB" HOME="$_FAKE_HOME" SPEC_SEARCH_ROOT="$TEMP_DIR" SKIP_INTEGRATION_TESTS=1 bash "$SCRIPT" 'system'
          The output should include "$_MRS_LOGIN_MARKER_DIR"
          The status should be success
        End

        # ゲートが閉じたままの種別では profile を読まない。読むと、呼び出し元が
        # 組み立てた PATH に無関係なエントリが混ざる
        It '[Normal] T-RUN-MRS-12: leaves the login PATH out for unit'
          When run env SHELLSPEC="$_SHELLSPEC_STUB" HOME="$_FAKE_HOME" SPEC_SEARCH_ROOT="$TEMP_DIR" SKIP_INTEGRATION_TESTS=1 bash "$SCRIPT" 'unit'
          The output should not include "$_MRS_LOGIN_MARKER_DIR"
          The status should be success
        End
      End
    End
  End
End
