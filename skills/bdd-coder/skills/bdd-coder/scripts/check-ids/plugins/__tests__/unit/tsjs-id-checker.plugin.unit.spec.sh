#!/usr/bin/env bash
# skills/bdd-coder/skills/bdd-coder/scripts/check-ids/plugins/__tests__/unit/tsjs-id-checker.plugin.unit.spec.sh
# @(#) : BDD unit tests for tsjs-id-checker.plugin.sh
#
# Copyright (c) 2026- atsushifx <https://github.com/atsushifx>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

# shellcheck shell=bash
# SC2034: プラグインが使う言語の表は、このファイルでは宣言するだけ
# shellcheck disable=SC2016,SC2034

# --- テスト対象 ---
_PLUGIN_DIR="${SHELLSPEC_PROJECT_ROOT}/skills/bdd-coder/skills/bdd-coder/scripts/check-ids/plugins"
# 検査スクリプトが宣言する言語の表。プラグインの読み込み前に宣言する
declare -gA LANG_FILES=() LANG_HANDLER=()
Include "${_PLUGIN_DIR}/tsjs-id-checker.plugin.sh"
Include "${_PLUGIN_DIR}/../libs/file-reader.lib.sh"

# --- テストデータ ---
# ファイルの先頭に置くグループ宣言の行
_DESCRIBE_LINE="describe('T-ABC-AA: x', () => {"

# --- 内部ヘルパー ---

# 関数
# ファイルを書く一時ディレクトリを作り、削除する
_setup_tmpdir() {
  _TMPDIR="$(mktemp -d)"
}

_cleanup_tmpdir() {
  rm -rf "$_TMPDIR"
}

# 行をファイルに書き、言語のハンドラで読んで、グループ・ケース・エラーの件数を出力する。
# _setup_tmpdir、counts_init、declared_ids_init の後に呼ぶ。
# $1: 言語 (ts / js)、$2: ファイル名、$3 以降: ファイルの各行
_check_file() {
  printf '%s\n' "${@:3}" > "${_TMPDIR}/$2"
  read_file_lines "$_TMPDIR" "$2" "${LANG_HANDLER[$1]}" || return 1
  _print_counts
}

# グループ・ケース・エラーの件数を出力する
_print_counts() {
  echo "${_COUNTS[group]} ${_COUNTS[case]} ${_COUNTS[errors]}"
}

# プラグインが言語の表に登録した値を出力する。$1: 表の名前、$2: 言語 (ts / js)
_registered_value() {
  local -n _table="$1"
  echo "${_table[$2]}"
}

# 直前のグループ ID を設定して 1 行を読み、グループ・ケース・エラーの件数を出力する。
# counts_init と declared_ids_init の後に呼ぶ。$1: 直前のグループ ID、$2: 行、
# $3: 次の行 (省略時は渡さない)
_check_line() {
  _GROUP_ID="$1"
  check_tsjs_line a.spec.ts:1 "${@:2}" || return 1
  _print_counts
}

# --- テスト本体 ---

# tsjs-id-checker.plugin.sh の check_tsjs_line。言語の表への登録と、ts / js の宣言行の計数と検査
Describe 'T-RUN-PTS: check_tsjs_line'
  BeforeEach 'counts_init' 'declared_ids_init'

  Describe 'When: 正常系'
    Describe 'language tables'
      # 枝番、説明、表の名前、言語、期待する値
      Parameters
        '01' 'the ts file name glob' LANG_FILES ts '*.spec.ts *.spec.tsx'
        '02' 'the ts line handler' LANG_HANDLER ts check_tsjs_line
        '03' 'the js file name glob' LANG_FILES js '*.spec.js *.spec.jsx *.spec.mjs *.spec.cjs'
        '04' 'the js line handler' LANG_HANDLER js check_tsjs_line
      End

      It "Then: [Normal] T-RUN-PTS-01-$1: registers $2"
        When call _registered_value "$3" "$4"
        The status should be success
        The output should equal "$5"
      End
    End

    Describe 'group keywords'
      It "Then: [Normal] T-RUN-PTS-02: counts a group declared by describe"
        When call _check_line '' "describe('T-ABC-AA: x'"
        The status should be success
        The output should equal '1 0 0'
        The stderr should equal ''
      End
    End

    Describe 'case keywords'
      # 枝番、キーワード、行
      Parameters
        '01' 'it' "it('T-ABC-AA-01: x'"
        '02' 'test' "test('T-ABC-AA-01: x'"
      End

      It "Then: [Normal] T-RUN-PTS-03-$1: counts a case declared by $2"
        When call _check_line T-ABC-AA "$3"
        The status should be success
        The output should equal '0 1 0'
        The stderr should equal ''
      End
    End

    Describe 'title quotes'
      # 枝番、引用符の種類、行
      Parameters
        '01' 'a double quote' 'it("T-ABC-AA-01: x"'
        '02' 'a backquote' 'it(`T-ABC-AA-01: x`'
      End

      It "Then: [Normal] T-RUN-PTS-04-$1: reads a title opened by $2"
        When call _check_line T-ABC-AA "$3"
        The status should be success
        The output should equal '0 1 0'
        The stderr should equal ''
      End
    End

    Describe 'wrapped case declarations'
      It "Then: [Normal] T-RUN-PTS-08: reads the title of it( from the next line"
        When call _check_line T-ABC-AA 'it(' "  'T-ABC-AA-01: x',"
        The status should be success
        The output should equal '0 1 0'
        The stderr should equal ''
      End

      It "Then: [Normal] T-RUN-PTS-09: reads the title of test( from the next line"
        When call _check_line T-ABC-AA 'test(' "  'T-ABC-AA-01: x',"
        The status should be success
        The output should equal '0 1 0'
        The stderr should equal ''
      End
    End

    Describe 'wrapped case declarations read from a file'
      BeforeEach '_setup_tmpdir'
      AfterEach '_cleanup_tmpdir'

      It "Then: [Normal] T-RUN-PTS-10: reads a wrapped it( of a ts file"
        When call _check_file ts a.spec.ts \
          "$_DESCRIBE_LINE" '  it(' "    'T-ABC-AA-01: x'," '    f);' '});'
        The status should be success
        The output should equal '1 1 0'
        The stderr should equal ''
      End

      It "Then: [Normal] T-RUN-PTS-11: reads a wrapped test( of a js file"
        When call _check_file js a.spec.js \
          "$_DESCRIBE_LINE" '  test(' "    'T-ABC-AA-01: x'," '    f);' '});'
        The status should be success
        The output should equal '1 1 0'
        The stderr should equal ''
      End
    End

    Describe 'declarations without a next line'
      It "Then: [Normal] T-RUN-PTS-23: counts a one-line case declaration, under set -u"
        Set 'nounset:on'
        When call _check_line T-ABC-AA "it('T-ABC-AA-01: x', f);"
        The status should be success
        The output should equal '0 1 0'
        The stderr should equal ''
      End
    End
  End

  Describe 'When: 異常系'
    Describe 'case keywords without a title literal'
      # 枝番、キーワードの後ろの説明、行
      Parameters
        '01' 'a variable title' 'it(title, fn)'
        '02' 'the line end' 'test('
        '03' 'the line end after an indent' $' \tit('
        '04' 'a space and a quoted title' "it( 'T-ABC-AA-01: x'"
      End

      It "Then: [Error] T-RUN-PTS-05-$1: reports a case keyword before $2"
        When call _check_line T-ABC-AA "$3"
        The status should be success
        The output should equal '0 0 1'
        The stderr should equal 'Error: a.spec.ts:1: no case ID'
      End
    End

    Describe 'wrapped case declarations with an ID error'
      It "Then: [Error] T-RUN-PTS-12: reports a wrapped title with no ID at the keyword line"
        When call _check_line T-ABC-AA 'it(' "  'sample',"
        The status should be success
        The output should equal '0 0 1'
        The stderr should equal 'Error: a.spec.ts:1: no case ID'
      End

      It "Then: [Error] T-RUN-PTS-13: reports a wrapped case ID outside the group"
        When call _check_line T-ABC-AA 'it(' "  'T-ABC-BB-01: x',"
        The status should be success
        The output should equal '0 1 1'
        The stderr should equal 'Error: a.spec.ts:1: case ID outside the group: T-ABC-BB-01'
      End
    End

    Describe 'wrapped case declarations with an ID error, read from a file'
      BeforeEach '_setup_tmpdir'
      AfterEach '_cleanup_tmpdir'

      It "Then: [Error] T-RUN-PTS-14: reports a wrapped duplicate ID at the keyword line"
        When call _check_file ts a.spec.ts \
          "$_DESCRIBE_LINE" "it('T-ABC-AA-01: x', f);" 'it(' "  'T-ABC-AA-01: y'," '  f);'
        The status should be success
        The output should equal '1 2 1'
        The stderr should equal 'Error: a.spec.ts:3: duplicate ID: T-ABC-AA-01'
      End
    End

    Describe 'unreadable wrapped titles'
      It "Then: [Error] T-RUN-PTS-15: reports it( before a variable on the next line"
        When call _check_line T-ABC-AA 'it(' '  title,'
        The status should be success
        The output should equal '0 0 1'
        The stderr should equal 'Error: a.spec.ts:1: no case ID'
      End

      It "Then: [Error] T-RUN-PTS-17: does not read the next line after a variable behind ("
        When call _check_line T-ABC-AA 'it(name,' "  'T-ABC-AA-01: x',"
        The status should be success
        The output should equal '0 0 1'
        The stderr should equal 'Error: a.spec.ts:1: no case ID'
      End

      It "Then: [Error] T-RUN-PTS-18: does not read the next line after a space behind ("
        When call _check_line T-ABC-AA 'it( ' "  'T-ABC-AA-01: x',"
        The status should be success
        The output should equal '0 0 1'
        The stderr should equal 'Error: a.spec.ts:1: no case ID'
      End
    End

    Describe 'unreadable wrapped titles, read from a file'
      BeforeEach '_setup_tmpdir'
      AfterEach '_cleanup_tmpdir'

      It "Then: [Error] T-RUN-PTS-16: reports it( on the last line of a file"
        When call _check_file ts a.spec.ts \
          "$_DESCRIBE_LINE" '  it('
        The status should be success
        The output should equal '1 0 1'
        The stderr should equal 'Error: a.spec.ts:2: no case ID'
      End
    End

    Describe 'unreadable declarations without a next line'
      It "Then: [Error] T-RUN-PTS-24: reports it( without a next line, under set -u"
        Set 'nounset:on'
        When call _check_line T-ABC-AA 'it('
        The status should be success
        The output should equal '0 0 1'
        The stderr should equal 'Error: a.spec.ts:1: no case ID'
      End
    End
  End

  Describe 'When: エッジケース'
    Describe 'wrapped case declarations with CRLF line ends'
      BeforeEach '_setup_tmpdir'
      AfterEach '_cleanup_tmpdir'

      It "Then: [Edge] T-RUN-PTS-19: reads a wrapped it( of a CRLF file"
        When call _check_file ts a.spec.ts \
          "$_DESCRIBE_LINE"$'\r' $'  it(\r' "    'T-ABC-AA-01: x',"$'\r' $'    f);\r'
        The status should be success
        The output should equal '1 1 0'
        The stderr should equal ''
      End
    End

    Describe 'indented lines'
      # 枝番、説明、直前のグループ ID、行、期待する件数
      Parameters
        '01' 'an indented group line' '' $' \tdescribe(\'T-ABC-AA: x\'' '1 0 0'
        '02' 'an indented case line' T-ABC-AA $' \tit(\'T-ABC-AA-01: x\'' '0 1 0'
      End

      It "Then: [Edge] T-RUN-PTS-06-$1: counts $2"
        When call _check_line "$3" "$4"
        The status should be success
        The output should equal "$5"
        The stderr should equal ''
      End
    End

    Describe 'indented wrapped declarations'
      It "Then: [Edge] T-RUN-PTS-20: reads a tab-indented test( with a double-quoted next line"
        When call _check_line T-ABC-AA $'\ttest(' $'\t\t"T-ABC-AA-01: x",'
        The status should be success
        The output should equal '0 1 0'
        The stderr should equal ''
      End
    End

    Describe 'lines that declare nothing'
      # 枝番、説明、行
      Parameters
        '01' 'a derived case keyword' "it.each(rows)('T-ABC-AA-01: x'"
        '02' 'a case keyword separated from "("' "it ('T-ABC-AA-01: x'"
        '03' 'a group keyword with no title literal' "describe(name, 'T-ABC-AA: x'"
        '04' 'a group keyword joined to its quote' "describe'T-ABC-AA: x'"
        '05' 'a group keyword after another character' "// describe('T-ABC-AA: x'"
        '06' 'a case keyword after another character' "// it('T-ABC-AA-01: x'"
      End

      It "Then: [Edge] T-RUN-PTS-07-$1: ignores $2"
        When call _check_line T-ABC-AA "$3"
        The status should be success
        The output should equal '0 0 0'
        The stderr should equal ''
      End
    End

    Describe 'lines that do not read the next line'
      It "Then: [Edge] T-RUN-PTS-21: ignores a wrapped describe("
        When call _check_line '' 'describe(' "  'T-ABC-AA: x',"
        The status should be success
        The output should equal '0 0 0'
        The stderr should equal ''
      End

      It "Then: [Edge] T-RUN-PTS-22: ignores a wrapped case keyword after another word"
        When call _check_line T-ABC-AA 'await it(' "  'T-ABC-AA-01: x',"
        The status should be success
        The output should equal '0 0 0'
        The stderr should equal ''
      End
    End

    Describe 'non-declarations without a next line'
      It "Then: [Edge] T-RUN-PTS-25: ignores a line that declares nothing, under set -u"
        Set 'nounset:on'
        When call _check_line T-ABC-AA 'await f();'
        The status should be success
        The output should equal '0 0 0'
        The stderr should equal ''
      End
    End
  End
End
