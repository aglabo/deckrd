#!/usr/bin/env bash
# skills/bdd-coder/skills/bdd-coder/scripts/__tests__/unit/check-test-ids.unit.spec.sh
# @(#) : BDD unit tests for check-test-ids.sh
#
# Copyright (c) 2026- atsushifx <https://github.com/atsushifx>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

# shellcheck shell=bash
# shellcheck disable=SC1003,SC2016

# --- 内部ヘルパー ---

# 定数
# テスト対象。サブプロセスとして実行する
_SCRIPT="${SHELLSPEC_PROJECT_ROOT}/skills/bdd-coder/skills/bdd-coder/scripts/check-test-ids.sh"
# usage の出力
_USAGE_LINE='Usage: check-test-ids.sh [--lang <lang>[,<lang>...]]'
# sh のグループ宣言の行
_GROUP_LINE="Describe 'T-ABC-AA: x'"
# sh のケース宣言の行
_CASE_LINE="It 'T-ABC-AA-01: x'"
# ts と js のグループ宣言の行
_TS_GROUP_LINE="describe('T-ABC-AA: x', f)"
# ts と js のケース宣言の行
_TS_CASE_LINE="it('T-ABC-AA-01: x', f)"
# go のグループ宣言の行
_GO_GROUP_LINE='t.Run("T-ABC-AA: x", f)'
# go のケース宣言の行。gofmt の書式でタブで字下げする
_GO_CASE_LINE=$'\tt.Run("T-ABC-AA-01: x", f)'
# dart のグループ宣言の行
_DART_GROUP_LINE="group('T-ABC-AA: x', () {"
# 1 ファイル・グループ 1・ケース 1 の成功出力
_ONE_EACH='OK: 1 files, 1 group IDs, 1 case IDs'
# a.spec.sh の 2 行目にケース ID が無いときのエラー出力
_NO_CASE_ERROR='Error: a.spec.sh:2: no case ID'
# 所有者の違うリポジトリを拒む git のメッセージの 1 行目
_DUBIOUS="fatal: detected dubious ownership in repository at '/r'"
# 壊れたリポジトリを読んだ git のメッセージ
_BROKEN_REPO='fatal: not a git repository: /r/.git/worktrees/w'
# LC_ALL=C のときだけ英語で「リポジトリの外」を返す偽の git の各行
_OUTSIDE_GIT=(
  '[[ ${LC_ALL-} == C ]] && echo "fatal: not a git repository (or any of the parent directories): .git" >&2'
  '[[ ${LC_ALL-} == C ]] || echo "fatal: translated message" >&2'
  'exit 128'
)
# テストで足す言語 zz のプラグインの各行
_ZZ_PLUGIN=(
  '. "${BASH_SOURCE[0]%/*}/../libs/report.lib.sh" || return 1'
  '. "${BASH_SOURCE[0]%/*}/../libs/test-id.lib.sh" || return 1'
  '. "${BASH_SOURCE[0]%/*}/../libs/declaration.lib.sh" || return 1'
  'declare -g _ZZ_GROUP_PATTERN="^(Describe) +${_QUOTE}(.*)"'
  'declare -g _ZZ_CASE_PATTERN="^(It) +${_QUOTE}(.*)"'
  "declare -g _ZZ_CASE_START_PATTERN='^(It)( |\$)'"
  'check_zz_line() {'
  '  count_line_declaration "$1" "$2" "$_ZZ_GROUP_PATTERN" "$_ZZ_CASE_PATTERN" "$_ZZ_CASE_START_PATTERN"'
  '}'
  "LANG_FILES[zz]='*.spec.zz'"
  'LANG_HANDLER[zz]=check_zz_line'
)

# 関数
# git 管理外の空のフィクスチャディレクトリを作り、走査ルートの上書きを解除する。
# 呼び出し元が指すリポジトリを読んだり初期化したりしないように git の環境変数も解除する
_setup_fixture() {
  _FIXTURE="$(mktemp -d)"
  unset TEST_ID_CHECK_ROOT GIT_DIR GIT_WORK_TREE
}

# フィクスチャディレクトリを削除する
_teardown_fixture() {
  rm -rf "$_FIXTURE"
}

# フィクスチャ内にファイルを作る。$1: ルート相対のパス、$2 以降: ファイルの各行
_write_file() {
  local path="${_FIXTURE}/$1"
  shift
  mkdir -p "${path%/*}"
  printf '%s\n' "$@" >"$path"
}

# 引数を 1 行ずつ書き込んだ a.spec.sh を作る。$@: ファイルの各行
_write_spec() {
  _write_file a.spec.sh "$@"
}

# グループ 1・ケース 1 の a.spec.sh を作る
_write_one_each() {
  _write_spec "$_GROUP_LINE" "$_CASE_LINE"
}

# 検査が走れば no case ID を出す a.spec.sh を作る。検査を実行しないケースの入力
_write_unchecked_spec() {
  _write_spec "$_GROUP_LINE" "It 'sample'"
}

# ID が重ならない sh と ts のテストファイルを 1 件ずつ作る
_write_sh_and_ts() {
  _write_one_each
  _write_file b.spec.ts "describe('T-ABC-BB: x', f)" "it('T-ABC-BB-01: x', f)"
}

# 言語のグループ宣言に続けて引数を 1 行ずつ書き込んだテストファイルを作る。
# $1: ts、go、dart のいずれか、$2 以降: 2 行目以降の各行
_write_lang_spec() {
  local lang="$1"
  shift
  case "$lang" in
    ts) _write_file a.spec.ts "$_TS_GROUP_LINE" "$@" ;;
    go) _write_file a_test.go "$_GO_GROUP_LINE" "$@" ;;
    dart) _write_file a.spec.dart "$_DART_GROUP_LINE" "$@" ;;
  esac
}

# 同梱の言語テーブルの言語をカンマ区切りで出力する
_shipped_languages() (
  # shellcheck source=/dev/null
  . "${_SCRIPT%/*}/check-ids/languages.sh" || return 1
  IFS=,
  printf '%s' "${!LANG_PLUGIN[*]}"
)

# パスと内容の組からファイルを作る。$@: パス、内容の繰り返し
_write_pairs() {
  while [[ $# -gt 0 ]]; do
    _write_file "$1" "$2"
    shift 2
  done
}

# 指定したディレクトリを cwd にしてチェッカーを実行する。$1: cwd、$2 以降: チェッカーの引数
_run_check_in() {
  cd "$1" && shift && bash "$_SCRIPT" "$@"
}

# フィクスチャのルートを cwd にしてチェッカーを実行する。$@: チェッカーの引数
_run_check() {
  _run_check_in "$_FIXTURE" "$@"
}

# フィクスチャの .bin/ にコマンドを作る。$1: コマンド名、$2 以降: bash スクリプトの各行
_write_command() {
  local name="$1"
  shift
  _write_file ".bin/${name}" "#!${BASH}" "$@"
  chmod +x "${_FIXTURE}/.bin/${name}"
}

# .bin/ の偽のコマンドを PATH の先頭に置いてチェッカーを実行する。$@: チェッカーの引数
_run_check_with_fakes() {
  PATH="${_FIXTURE}/.bin:${PATH}" _run_check "$@"
}

# rg と git が無い PATH でチェッカーを実行し、find の列挙を通す。
# .bin/ にはチェッカーが使うコマンドを呼ぶスクリプトだけを置く
_run_check_with_find() {
  local name
  for name in sed sort find; do
    _write_command "$name" "exec '$(command -v "$name")' \"\$@\""
  done
  cd "$_FIXTURE" && PATH="${_FIXTURE}/.bin" "$BASH" "$_SCRIPT"
}

# フィクスチャを git の toplevel と認めさせてサブディレクトリ sub からチェッカーを実行する。
# 所有者を記録しないファイルシステムでは git が dubious ownership で止まるので、
# 利用者の git 設定は変えず、このプロセスにだけ safe.directory を渡す
_run_check_in_git_sub() {
  GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=safe.directory GIT_CONFIG_VALUE_0='*' \
    _run_check_in "${_FIXTURE}/sub"
}

# 偽の git を PATH の先頭に置いてサブディレクトリ sub からチェッカーを実行する。
# $@: 偽の git の bash スクリプトの各行
_run_check_in_sub_with_git() {
  _write_command git "$@"
  PATH="${_FIXTURE}/.bin:${PATH}" _run_check_in "${_FIXTURE}/sub"
}

# git が終了コード 128 で失敗する状態でチェッカーを実行する。$1: git の stderr
_run_check_with_failing_git() {
  _FAKE_GIT_STDERR="$1" _run_check_in_sub_with_git 'printf "%s\n" "$_FAKE_GIT_STDERR" >&2' 'exit 128'
}

# LC_ALL を解除し、git がリポジトリの外と答える状態でチェッカーを実行する
_run_check_outside_git() {
  unset LC_ALL
  _run_check_in_sub_with_git "${_OUTSIDE_GIT[@]}"
}

# rg が PATH に無ければ成功する。rg の列挙を検証するケースの Skip 条件
_rg_missing() {
  ! command -v rg >/dev/null 2>&1
}

# 利用者の git の無視指定を rg が読まないように、設定の場所をフィクスチャに向ける
_isolate_ignore_config() {
  export HOME="$_FIXTURE" XDG_CONFIG_HOME="$_FIXTURE"
}

# チェッカー一式のコピーをフィクスチャ外に作る。テスト用のプラグインはコピーにだけ足す
_setup_tool() {
  _TOOL="$(mktemp -d)"
  mkdir -p "${_TOOL}/libs" "${_TOOL}/check-ids/libs" "${_TOOL}/check-ids/plugins"
  cp "$_SCRIPT" "$_TOOL"
  cp "${_SCRIPT%/*}"/libs/*.lib.sh "${_TOOL}/libs"
  cp "${_SCRIPT%/*}"/check-ids/*.sh "${_TOOL}/check-ids"
  cp "${_SCRIPT%/*}"/check-ids/plugins/*.plugin.sh "${_TOOL}/check-ids/plugins"
  cp "${_SCRIPT%/*}"/check-ids/libs/*.lib.sh "${_TOOL}/check-ids/libs"
}

# チェッカー一式のコピーを削除する
_teardown_tool() {
  rm -rf "$_TOOL"
}

# コピーに zz のプラグインのファイルだけを作る。$@: _ZZ_PLUGIN の各行の後に足す行
_write_zz_plugin() {
  printf '%s\n' "${_ZZ_PLUGIN[@]}" "$@" >"${_TOOL}/check-ids/plugins/zz-id-checker.plugin.sh"
}

# コピーの言語テーブルに zz の行を足す。$1: プラグインのファイル名の ID
_add_zz_row() {
  printf 'LANG_PLUGIN[zz]=%s\n' "$1" >>"${_TOOL}/check-ids/languages.sh"
}

# コピーに zz のプラグインとテーブルの行を足す。$@: _ZZ_PLUGIN の各行の後に足す行
_add_zz_plugin() {
  _write_zz_plugin "$@"
  _add_zz_row zz
}

# フィクスチャのルートを cwd にしてコピーのチェッカーを実行する。$@: チェッカーの引数
_run_tool_check() {
  cd "$_FIXTURE" && bash "${_TOOL}/check-test-ids.sh" "$@"
}

# コピーのディレクトリを cwd にして、ディレクトリ部分の無いパスでチェッカーを実行する
_run_tool_in_own_dir() {
  export TEST_ID_CHECK_ROOT="$_FIXTURE"
  cd "$_TOOL" && bash check-test-ids.sh
}

# --- テスト本体 ---

# check-test-ids.sh のコマンドライン。usage、言語の選択、引数の拒否
Describe 'T-RUN-CLI: check-test-ids.sh command line'
  BeforeEach '_setup_fixture'
  AfterEach '_teardown_fixture'

  Describe 'When: 正常系'
    Describe 'usage'
      Parameters
        '01' -h
        '02' --help
      End

      It "Then: [Normal] T-RUN-CLI-01-$1: $2 prints the usage"
        When run command bash "$_SCRIPT" "$2"
        The status should be success
        The output should equal "$_USAGE_LINE"
      End
    End

    Describe 'selected languages'
      BeforeEach '_write_sh_and_ts'

      # 枝番、説明、期待する出力、チェッカーの引数
      Parameters
        '01' 'checks only sh without --lang' "$_ONE_EACH"
        '02' 'counts a language repeated in --lang= once' "$_ONE_EACH" --lang=sh,sh
        '03' 'reads only the files of the selected language' "$_ONE_EACH" --lang=ts
      End

      It "Then: [Normal] T-RUN-CLI-02-$1: $2"
        When run _run_check "${@:4}"
        The status should be success
        The output should equal "$3"
      End
    End
  End

  Describe 'When: 異常系'
    BeforeEach '_write_unchecked_spec'

    # 枝番、説明、期待するエラー出力、チェッカーの引数。空の言語名のエラーは空白で終わる
    Parameters
      '01' 'an unknown option' 'Error: Unknown option: --scopes' --scopes
      '02' 'an extra argument' 'Error: Unexpected argument: extra' extra
      '03' 'an unknown language' 'Error: Unknown language: zz' --lang zz
      '04' 'the empty language after a trailing comma' 'Error: Unknown language: ' --lang sh,
    End

    It "Then: [Error] T-RUN-CLI-03-$1: rejects $2 and runs no check"
      When run _run_check "${@:4}"
      The status should equal 1
      The output should equal ''
      The stderr should equal "$3"
    End
  End
End

# check-test-ids.sh の sh の宣言の行の判定とエラー報告。宣言の読み取りと計数の詳細は
# declaration.lib.sh の spec で、ID の判定と、所属と重複の検査の詳細は test-id.lib.sh の
# spec で検証する
Describe 'T-RUN-DCL: check-test-ids.sh declarations'
  BeforeEach '_setup_fixture'
  AfterEach '_teardown_fixture'

  Describe 'When: 正常系'
    Describe 'a group line and a case line'
      # 枝番、説明、グループ宣言の行、ケース宣言の行
      Parameters
        '01' 'tabs and spaces mixed before a keyword' $' \t '"$_GROUP_LINE" $'\t  \t'"$_CASE_LINE"
        '03' 'a tab before a title' "$_GROUP_LINE" $'It\t\'T-ABC-AA-01: x\''
      End

      It "Then: [Normal] T-RUN-DCL-01-$1: reads $2"
        _write_spec "$3" "$4"
        When run _run_check
        The status should be success
        The output should equal "$_ONE_EACH"
      End
    End

    Describe 'a line between a group and its case'
      # 枝番、説明、グループ宣言とケース宣言の間に置く行。数えず、直前のグループも変えない
      Parameters
        '04' 'a derived keyword' "xIt 'T-ABC-AA-01: x'"
        '05' 'a keyword that a quote follows directly' "It'T-ABC-AA-01: x'"
        '06' 'a keyword that = follows' 'It=1'
      End

      It "Then: [Normal] T-RUN-DCL-02-$1: adds nothing for $2"
        _write_spec "$_GROUP_LINE" "$3" "$_CASE_LINE"
        When run _run_check
        The status should be success
        The output should equal "$_ONE_EACH"
      End
    End
  End

  Describe 'When: 異常系'
    Describe 'a case declaration without a case ID'
      # 枝番、説明、グループ宣言に続く行 (折り返しは 2 行)
      Parameters
        '02' 'a wrapped declaration' $'It \\\n  \'T-ABC-AA-01: x\''
        '04' 'a keyword that the line end follows' 'It'
        '05' 'a keyword that a CRLF line end follows' $'It\r'
      End

      It "Then: [Error] T-RUN-DCL-04-$1: reports $2"
        _write_spec "$_GROUP_LINE" "$3"
        When run _run_check
        The status should equal 1
        The output should equal ''
        The stderr should equal "$_NO_CASE_ERROR"
      End
    End

    It 'Then: [Error] T-RUN-DCL-05-04: reports a heredoc body line read as a declaration'
      _write_spec "$_GROUP_LINE" "cat <<'EOF'" "It 'sample'" 'EOF'
      When run _run_check
      The status should equal 1
      The output should equal ''
      The stderr should equal 'Error: a.spec.sh:3: no case ID'
    End

    It 'Then: [Error] T-RUN-DCL-06-01: reports a group ID not carried over to the next file'
      _write_spec "$_GROUP_LINE"
      _write_file sub/b.spec.sh "$_CASE_LINE"
      When run _run_check
      The status should equal 1
      The output should equal ''
      The stderr should equal 'Error: sub/b.spec.sh:1: case ID outside the group: T-ABC-AA-01'
    End
  End
End

# check-test-ids.sh の言語プラグインごとのファイル名と行の読み方
Describe 'T-RUN-LNG: check-test-ids.sh languages'
  BeforeEach '_setup_fixture'
  AfterEach '_teardown_fixture'

  Describe 'When: 正常系'
    Describe 'file names and keywords'
      # 枝番、言語、ファイル名、グループ宣言の行、ケース宣言の行
      Parameters
        '01' sh a.spec.sh "Context 'T-ABC-AA: x'" "Example 'T-ABC-AA-01: x'"
        '02' sh a.spec.sh "ExampleGroup 'T-ABC-AA: x'" "Specify 'T-ABC-AA-01: x'"
        '03' ts a.spec.tsx "$_TS_GROUP_LINE" "test('T-ABC-AA-01: x', f)"
        '04' js a.spec.jsx "$_TS_GROUP_LINE" "test('T-ABC-AA-01: x', f)"
        '05' js a.spec.mjs "$_TS_GROUP_LINE" "$_TS_CASE_LINE"
        '06' js a.spec.cjs "$_TS_GROUP_LINE" "$_TS_CASE_LINE"
        '07' dart a.spec.dart "$_DART_GROUP_LINE" "  test('T-ABC-AA-01: x', f);"
        '08' dart a.spec.dart "$_DART_GROUP_LINE" "testWidgets('T-ABC-AA-01: x', f);"
      End

      It "Then: [Normal] T-RUN-LNG-01-$1: counts a $2 group and case in $3"
        _write_file "$3" "$4" "$5"
        When run _run_check --lang "$2"
        The status should be success
        The output should equal "$_ONE_EACH"
      End
    End

    Describe 'go ID forms'
      # 枝番、説明、期待する出力、グループ宣言に続く t.Run の行。ID の形でグループとケースを分ける
      Parameters
        '01' 'a table-driven ID as a case' "$_ONE_EACH" $'\tt.Run("T-ABC-AA-03-"+tc.name, f)'
        '02' 'an ID that is not a case ID as a group' 'OK: 1 files, 2 group IDs, 0 case IDs' $'\tt.Run("T-ABC-AA-5: x", f)'
      End

      It "Then: [Normal] T-RUN-LNG-02-$1: counts $2"
        _write_lang_spec go "$4"
        When run _run_check --lang go
        The status should be success
        The output should equal "$3"
      End
    End

    Describe 'lines that are not declarations'
      # 枝番、言語、説明、ケース宣言の行、読まない行
      Parameters
        '01' ts 'the derived keyword fit(' "$_TS_CASE_LINE" "fit('T-ABC-AA-01: x', f)"
        '02' ts 'the modified call it.each(' "$_TS_CASE_LINE" "it.each(rows)('T-ABC-AA-02: x', f)"
        '03' ts 'a call that does not start its line' "$_TS_CASE_LINE" "await it('T-ABC-AA-02: x', f)"
        '04' ts 'a keyword that the line end follows' "$_TS_CASE_LINE" 'it'
        '05' go 'a word that differs from t.Run at the dot' "$_GO_CASE_LINE" $'\ttXRun(name, f)'
      End

      It "Then: [Normal] T-RUN-LNG-03-$1: does not read $3"
        _write_lang_spec "$2" "$4" "$5"
        When run _run_check --lang "$2"
        The status should be success
        The output should equal "$_ONE_EACH"
      End
    End

    # テーブルに言語を足したら、その言語のファイルをここに足す
    It 'Then: [Normal] T-RUN-LNG-06: counts every language of the shipped table loaded together'
      _write_one_each
      _write_file b.spec.ts "describe('T-ABC-BB: x', f)" "it('T-ABC-BB-01: x', f)"
      _write_file c.spec.js "describe('T-ABC-CC: x', f)" "it('T-ABC-CC-01: x', f)"
      _write_file d.spec.dart "group('T-ABC-DD: x', () {" "test('T-ABC-DD-01: x', f);"
      _write_file e_test.go 't.Run("T-ABC-EE: x", f)' $'\tt.Run("T-ABC-EE-01: x", f)'
      When run _run_check --lang "$(_shipped_languages)"
      The status should be success
      The output should equal 'OK: 5 files, 5 group IDs, 5 case IDs'
    End
  End

  Describe 'When: 異常系'
    Describe 'a case declaration without a case ID'
      # 枝番、言語、説明、グループ宣言に続く行、期待するエラー出力
      Parameters
        '01' ts 'a variable title' 'it(title, f)' 'Error: a.spec.ts:2: no case ID'
        '02' ts 'a space before the quote' "it( 'T-ABC-AA-01: x', f)" 'Error: a.spec.ts:2: no case ID'
        '03' go 'a title without an ID' $'\tt.Run("sample", f)' 'Error: a_test.go:2: no case ID'
        '04' go 'a call without a title literal' $'\tt.Run(name, f)' 'Error: a_test.go:2: no case ID'
        '06' dart 'a variable title' 'test(title, f);' 'Error: a.spec.dart:2: no case ID'
      End

      It "Then: [Error] T-RUN-LNG-04-$1: reports $2 $3"
        _write_lang_spec "$2" "$4"
        When run _run_check --lang "$2"
        The status should equal 1
        The output should equal ''
        The stderr should equal "$5"
      End
    End

    Describe 'other file names'
      # 枝番、言語、列挙しないファイル名
      Parameters
        '01' sh a.sh
        '02' ts a.test.ts
        '03' js a.test.js
        '04' dart a_test.dart
        '05' go a.go
      End

      It "Then: [Error] T-RUN-LNG-05-$1: does not list $3 for $2"
        _write_file "$3" 'x'
        When run _run_check --lang "$2"
        The status should equal 1
        The output should equal ''
        The stderr should equal "Error: $2: no test file"
      End
    End
  End
End

# check-test-ids.sh の走査ルートと、列挙しないファイル
Describe 'T-RUN-LST: check-test-ids.sh file listing and scan root'
  BeforeEach '_setup_fixture' '_write_one_each'
  AfterEach '_teardown_fixture'

  Describe 'When: 正常系'
    It 'Then: [Normal] T-RUN-LST-01: TEST_ID_CHECK_ROOT overrides the scan root'
      mkdir "${_FIXTURE}/empty"
      export TEST_ID_CHECK_ROOT="$_FIXTURE"
      When run _run_check_in "${_FIXTURE}/empty"
      The status should be success
      The output should equal "$_ONE_EACH"
    End

    It 'Then: [Normal] T-RUN-LST-02: scans the toplevel inside a git repository'
      git init -q "$_FIXTURE"
      mkdir "${_FIXTURE}/sub"
      When run _run_check_in_git_sub
      The status should be success
      The output should equal "$_ONE_EACH"
    End

    It 'Then: [Normal] T-RUN-LST-06: scans the current directory outside git, whatever the locale'
      _write_file sub/b.spec.sh "$_GROUP_LINE" "$_CASE_LINE"
      When run _run_check_outside_git
      The status should be success
      The output should equal "$_ONE_EACH"
      The stderr should equal ''
    End
  End

  Describe 'When: 異常系'
    Describe 'a git failure'
      # sub のファイルは検査に通るので、sub を走査すると成功する
      BeforeEach '_write_file sub/a.spec.sh "$_GROUP_LINE" "$_CASE_LINE"'

      # 枝番、説明、git の stderr、その 1 行目
      Parameters
        '01' 'dubious ownership, with its first line only' "${_DUBIOUS}"$'\nTo add an exception, call:' "$_DUBIOUS"
        '02' 'a broken repository' "$_BROKEN_REPO" "$_BROKEN_REPO"
      End

      It "Then: [Error] T-RUN-LST-05-$1: runs no check and reports $2"
        When run _run_check_with_failing_git "$3"
        The status should equal 1
        The output should equal ''
        The stderr should equal "Error: cannot find the git toplevel: $4"
      End
    End
  End

  Describe 'When: エッジケース'
    # 一覧から除くファイルは同じケース ID を宣言する。読まれると重複エラーになる
    Describe 'with rg'
      BeforeEach '_isolate_ignore_config'

      # 枝番、説明、一覧から除くファイル
      Parameters
        '01' 'a hidden directory' .hidden/b.spec.sh
        '02' 'an ignored file' ignored/b.spec.sh
        '03' 'node_modules without an ignore rule' node_modules/p/b.spec.sh
      End

      It "Then: [Edge] T-RUN-LST-03-$1: does not read $2 with rg"
        Skip if 'rg is not installed' _rg_missing
        _write_file .ignore 'ignored/'
        _write_file "$3" "$_CASE_LINE"
        When run _run_check
        The status should be success
        The output should equal "$_ONE_EACH"
      End
    End

    Describe 'with find'
      # 枝番、説明、一覧から除くファイル
      Parameters
        '01' 'a hidden directory' .hidden/b.spec.sh
        '02' 'node_modules' node_modules/p/b.spec.sh
      End

      It "Then: [Edge] T-RUN-LST-04-$1: does not read $2 without rg and git"
        _write_file "$3" "$_CASE_LINE"
        When run _run_check_with_find
        The status should be success
        The output should equal "$_ONE_EACH"
      End
    End
  End
End

# check-test-ids.sh の言語ごとのテストファイル 0 件とグループ ID 0 件、一覧と読み取りの失敗
Describe 'T-RUN-FLR: check-test-ids.sh failures of a language and a file'
  BeforeEach '_setup_fixture'
  AfterEach '_teardown_fixture'

  Describe 'When: 正常系'
    It 'Then: [Normal] T-RUN-FLR-01: accepts a group ID only in another file of the language'
      _write_spec "Describe 'When: x'"
      _write_file b.spec.sh "$_GROUP_LINE"
      When run _run_check
      The status should be success
      The output should equal 'OK: 2 files, 1 group IDs, 0 case IDs'
    End
  End

  Describe 'When: 異常系'
    Describe 'the checked languages'
      # 枝番、説明、言語、期待するエラー出力、ファイルのパスと内容の組
      Parameters
        '01' 'a second language with no test file' ts,js 'Error: js: no test file' a.spec.ts "$_TS_GROUP_LINE"
        '02' 'a second language with no group ID' ts,js 'Error: js: no group ID' a.spec.ts "$_TS_GROUP_LINE" b.spec.js "describe('When: x', f)"
        '03' 'an ID declared in two languages' ts,js 'Error: b.spec.js:1: duplicate ID: T-ABC-AA' a.spec.ts "$_TS_GROUP_LINE" b.spec.js "$_TS_GROUP_LINE"
      End

      It "Then: [Error] T-RUN-FLR-02-$1: reports $2"
        _write_pairs "${@:5}"
        When run _run_check --lang "$3"
        The status should equal 1
        The output should equal ''
        The stderr should equal "$4"
      End
    End

    It 'Then: [Error] T-RUN-FLR-03: reports a failed listing of every language, not as no test file'
      export TEST_ID_CHECK_ROOT="${_FIXTURE}/missing"
      When run _run_check --lang sh,ts
      The status should equal 1
      The output should equal ''
      The stderr should include "Error: sh: cannot list the test files under ${_FIXTURE}/missing"
      The stderr should include "Error: ts: cannot list the test files under ${_FIXTURE}/missing"
      The stderr should not include 'no test file'
    End

    It 'Then: [Error] T-RUN-FLR-04: reports an unreadable file and checks the next one'
      _write_file b.spec.sh "$_GROUP_LINE" "It 'sample'"
      _write_command rg "printf '%s\n' a-gone.spec.sh b.spec.sh"
      When run _run_check_with_fakes
      The status should equal 1
      The output should equal ''
      The stderr should include 'Error: a-gone.spec.sh: cannot read'
      The stderr should include 'Error: b.spec.sh:2: no case ID'
    End
  End
End

# check-test-ids.sh の言語プラグインの選択と読み込み。チェッカーのコピーにプラグインを足して検証する
Describe 'T-RUN-PLG: check-test-ids.sh language plugins'
  BeforeEach '_setup_fixture' '_setup_tool'
  AfterEach '_teardown_fixture' '_teardown_tool'

  Describe 'When: 正常系'
    It 'Then: [Normal] T-RUN-PLG-01: selects an added plugin whose keyword pattern has parentheses'
      _add_zz_plugin '_ZZ_CASE_PATTERN="^(It(em)?) +${_QUOTE}(.*)"'
      _write_file a.spec.zz "$_GROUP_LINE" "Item 'T-ABC-AA-01: x'"
      When run _run_tool_check --lang zz
      The status should be success
      The output should equal "$_ONE_EACH"
    End

    It 'Then: [Normal] T-RUN-PLG-02: finds its files when run without a directory part'
      _write_one_each
      When run _run_tool_in_own_dir
      The status should be success
      The output should equal "$_ONE_EACH"
    End
  End

  Describe 'When: 異常系'
    Describe 'a broken plugin'
      BeforeEach '_write_unchecked_spec'

      # 枝番、説明、プラグインに足す行、期待するエラー出力
      Parameters
        '01' 'fails to load' 'return 1' 'Error: zz: cannot load the plugin'
        '02' 'leaves LANG_FILES empty' "LANG_FILES[zz]=''" 'Error: zz: empty value: LANG_FILES'
        '03' 'does not set LANG_HANDLER' "unset 'LANG_HANDLER[zz]'" 'Error: zz: empty value: LANG_HANDLER'
        '04' 'registers an undefined handler' 'LANG_HANDLER[zz]=zz_undefined' 'Error: zz: empty value: LANG_HANDLER'
      End

      It "Then: [Error] T-RUN-PLG-03-$1: runs no check when a plugin $2"
        _add_zz_plugin "$3"
        When run _run_tool_check --lang sh,zz
        The status should equal 1
        The output should equal ''
        The stderr should equal "$4"
      End
    End

    Describe 'a name without a table row'
      BeforeEach '_write_zz_plugin'

      # 枝番、説明、言語名
      Parameters
        '03' 'the all-elements subscript' '@'
        '04' 'a plugin file without a table row' zz
      End

      It "Then: [Error] T-RUN-PLG-04-$1: does not select $2"
        When run _run_tool_check --lang "$3"
        The status should equal 1
        The output should equal ''
        The stderr should equal "Error: Unknown language: $3"
      End
    End
  End

  Describe 'When: エッジケース'
    BeforeEach '_write_one_each'

    It 'Then: [Edge] T-RUN-PLG-05: does not source a file of the checked repository'
      _write_file check-ids/languages.sh 'exit 9'
      _write_file check-ids/plugins/sh-id-checker.plugin.sh 'exit 9'
      When run _run_tool_check
      The status should be success
      The output should equal "$_ONE_EACH"
    End

    It 'Then: [Edge] T-RUN-PLG-06: does not load a plugin of a language that is not selected'
      _add_zz_plugin 'echo LOADED >&2' 'return 1'
      When run _run_tool_check --lang sh
      The status should be success
      The output should equal "$_ONE_EACH"
      The stderr should equal ''
    End
  End
End
