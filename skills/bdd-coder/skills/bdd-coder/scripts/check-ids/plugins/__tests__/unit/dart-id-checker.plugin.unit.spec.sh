#!/usr/bin/env bash
# skills/bdd-coder/skills/bdd-coder/scripts/check-ids/plugins/__tests__/unit/dart-id-checker.plugin.unit.spec.sh
# @(#) : BDD unit tests for dart-id-checker.plugin.sh
#
# Copyright (c) 2026- atsushifx <https://github.com/atsushifx>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

# shellcheck shell=bash
# SC2034: プラグインが使う言語の表は、このファイルでは宣言するだけ
# shellcheck disable=SC2034

# --- テスト対象 ---
_PLUGIN_DIR="${SHELLSPEC_PROJECT_ROOT}/skills/bdd-coder/skills/bdd-coder/scripts/check-ids/plugins"
# 検査スクリプトが宣言する言語の表。プラグインの読み込み前に宣言する
declare -gA LANG_FILES=() LANG_HANDLER=()
Include "${_PLUGIN_DIR}/dart-id-checker.plugin.sh"
Include "${_PLUGIN_DIR}/../libs/file-reader.lib.sh"

# --- テストデータ ---
# ファイルの先頭に置くグループ宣言の行
_GROUP_LINE="group('T-ABC-AA: x', () {"

# --- 内部ヘルパー ---

# 関数
# ファイルを書く一時ディレクトリを作り、削除する
_setup_tmpdir() {
  _TMPDIR="$(mktemp -d)"
}

_cleanup_tmpdir() {
  rm -rf "$_TMPDIR"
}

# 行をファイルに書き、dart のハンドラで読んで、グループ・ケース・エラーの件数を出力する。
# _setup_tmpdir、counts_init、declared_ids_init の後に呼ぶ。$@: ファイルの各行
_check_file() {
  printf '%s\n' "$@" > "${_TMPDIR}/a.spec.dart"
  read_file_lines "$_TMPDIR" a.spec.dart "${LANG_HANDLER[dart]}" || return 1
  _print_counts
}

# グループ・ケース・エラーの件数を出力する
_print_counts() {
  echo "${_COUNTS[group]} ${_COUNTS[case]} ${_COUNTS[errors]}"
}

# プラグインが言語の表に登録した dart の値を出力する。$1: 表の名前
_registered_value() {
  local -n _table="$1"
  echo "${_table[dart]}"
}

# 直前のグループ ID を設定して 1 行を読み、グループ・ケース・エラーの件数を出力する。
# counts_init と declared_ids_init の後に呼ぶ。$1: 直前のグループ ID、$2: 行、
# $3: 次の行 (省略時は渡さない)
_check_line() {
  _GROUP_ID="$1"
  check_dart_line a.spec.dart:1 "${@:2}" || return 1
  _print_counts
}

# --- テスト本体 ---

# dart-id-checker.plugin.sh の check_dart_line。言語の表への登録と、group と test の宣言行 (折り返しを含む) の計数と検査
Describe 'T-RUN-PDA: check_dart_line'
  BeforeEach 'counts_init' 'declared_ids_init'

  Describe 'When: 正常系'
    Describe 'language tables'
      # 枝番、説明、表の名前、期待する値
      Parameters
        '01' 'the file name glob' LANG_FILES '*.spec.dart'
        '02' 'the line handler' LANG_HANDLER check_dart_line
      End

      It "Then: [Normal] T-RUN-PDA-01-$1: registers $2"
        When call _registered_value "$3"
        The status should be success
        The output should equal "$4"
      End
    End

    Describe 'group declarations'
      It 'Then: [Normal] T-RUN-PDA-02-01: counts a group declared by group('
        When call _check_line '' "group('T-ABC-AA: x', () {"
        The status should be success
        The output should equal '1 0 0'
        The stderr should equal ''
      End
    End

    Describe 'case declarations'
      # 枝番、説明、行
      Parameters
        '01' 'a case declared by test(' "test('T-ABC-AA-01: x', f);"
        '02' 'a case declared by testWidgets(' "testWidgets('T-ABC-AA-01: x', f);"
      End

      It "Then: [Normal] T-RUN-PDA-03-$1: counts $2"
        When call _check_line T-ABC-AA "$3"
        The status should be success
        The output should equal '0 1 0'
        The stderr should equal ''
      End
    End

    Describe 'wrapped case declarations'
      It "Then: [Normal] T-RUN-PDA-07: reads the title of test( from the next line"
        When call _check_line T-ABC-AA 'test(' "  'T-ABC-AA-01: x',"
        The status should be success
        The output should equal '0 1 0'
        The stderr should equal ''
      End

      It "Then: [Normal] T-RUN-PDA-08: reads the title of testWidgets( from the next line"
        When call _check_line T-ABC-AA 'testWidgets(' "  'T-ABC-AA-01: x',"
        The status should be success
        The output should equal '0 1 0'
        The stderr should equal ''
      End
    End

    Describe 'wrapped case declarations read from a file'
      BeforeEach '_setup_tmpdir'
      AfterEach '_cleanup_tmpdir'

      It "Then: [Normal] T-RUN-PDA-09: reads a wrapped test( of a dart file"
        When call _check_file \
          "$_GROUP_LINE" '  test(' "    'T-ABC-AA-01: x'," '    f);' '});'
        The status should be success
        The output should equal '1 1 0'
        The stderr should equal ''
      End
    End

    Describe 'declarations without a next line'
      It "Then: [Normal] T-RUN-PDA-21: counts a one-line case declaration, under set -u"
        Set 'nounset:on'
        When call _check_line T-ABC-AA "test('T-ABC-AA-01: x', f);"
        The status should be success
        The output should equal '0 1 0'
        The stderr should equal ''
      End
    End
  End

  Describe 'When: 異常系'
    Describe 'case keyword lines without a readable title'
      # 枝番、説明、行
      Parameters
        '01' 'a test( call without a title literal' 'test(title, f);'
        '02' 'a testWidgets( call without a title literal' 'testWidgets(title, f);'
        '03' 'a blank before the quote' "test( 'T-ABC-AA-01: x', f);"
      End

      It "Then: [Error] T-RUN-PDA-04-$1: reports $2"
        When call _check_line T-ABC-AA "$3"
        The status should be success
        The output should equal '0 0 1'
        The stderr should equal 'Error: a.spec.dart:1: no case ID'
      End
    End

    Describe 'wrapped case declarations with an ID error'
      It "Then: [Error] T-RUN-PDA-10: reports a wrapped title with no ID at the keyword line"
        When call _check_line T-ABC-AA 'test(' "  'sample',"
        The status should be success
        The output should equal '0 0 1'
        The stderr should equal 'Error: a.spec.dart:1: no case ID'
      End

      It "Then: [Error] T-RUN-PDA-11: reports a wrapped case ID outside the group"
        When call _check_line T-ABC-AA 'test(' "  'T-ABC-BB-01: x',"
        The status should be success
        The output should equal '0 1 1'
        The stderr should equal 'Error: a.spec.dart:1: case ID outside the group: T-ABC-BB-01'
      End
    End

    Describe 'wrapped case declarations with an ID error, read from a file'
      BeforeEach '_setup_tmpdir'
      AfterEach '_cleanup_tmpdir'

      It "Then: [Error] T-RUN-PDA-12: reports a wrapped duplicate ID at the keyword line"
        When call _check_file \
          "$_GROUP_LINE" "test('T-ABC-AA-01: x', f);" 'testWidgets(' "  'T-ABC-AA-01: y'," '  f);'
        The status should be success
        The output should equal '1 2 1'
        The stderr should equal 'Error: a.spec.dart:3: duplicate ID: T-ABC-AA-01'
      End
    End

    Describe 'unreadable wrapped titles'
      It "Then: [Error] T-RUN-PDA-13: reports test( before a variable on the next line"
        When call _check_line T-ABC-AA 'test(' '  title,'
        The status should be success
        The output should equal '0 0 1'
        The stderr should equal 'Error: a.spec.dart:1: no case ID'
      End

      It "Then: [Error] T-RUN-PDA-15: does not read the next line after a variable behind ("
        When call _check_line T-ABC-AA 'test(name,' "  'T-ABC-AA-01: x',"
        The status should be success
        The output should equal '0 0 1'
        The stderr should equal 'Error: a.spec.dart:1: no case ID'
      End

      It "Then: [Error] T-RUN-PDA-16: does not read the next line after a space behind ("
        When call _check_line T-ABC-AA 'test( ' "  'T-ABC-AA-01: x',"
        The status should be success
        The output should equal '0 0 1'
        The stderr should equal 'Error: a.spec.dart:1: no case ID'
      End
    End

    Describe 'unreadable wrapped titles, read from a file'
      BeforeEach '_setup_tmpdir'
      AfterEach '_cleanup_tmpdir'

      It "Then: [Error] T-RUN-PDA-14: reports testWidgets( on the last line of a file"
        When call _check_file \
          "$_GROUP_LINE" '  testWidgets('
        The status should be success
        The output should equal '1 0 1'
        The stderr should equal 'Error: a.spec.dart:2: no case ID'
      End
    End

    Describe 'unreadable declarations without a next line'
      It "Then: [Error] T-RUN-PDA-22: reports test( without a next line, under set -u"
        Set 'nounset:on'
        When call _check_line T-ABC-AA 'test('
        The status should be success
        The output should equal '0 0 1'
        The stderr should equal 'Error: a.spec.dart:1: no case ID'
      End
    End
  End

  Describe 'When: エッジケース'
    Describe 'wrapped case declarations with CRLF line ends'
      BeforeEach '_setup_tmpdir'
      AfterEach '_cleanup_tmpdir'

      It "Then: [Edge] T-RUN-PDA-17: reads a wrapped test( of a CRLF file"
        When call _check_file \
          "$_GROUP_LINE"$'\r' $'  test(\r' "    'T-ABC-AA-01: x',"$'\r' $'    f);\r'
        The status should be success
        The output should equal '1 1 0'
        The stderr should equal ''
      End
    End

    Describe 'indented lines'
      # 枝番、説明、直前のグループ ID、行、期待する件数、期待する stderr
      Parameters
        '01' 'counts an indented group line' '' $' \tgroup(\'T-ABC-AA: x\', () {' '1 0 0' ''
        '02' 'counts an indented case line' T-ABC-AA $' \ttest(\'T-ABC-AA-01: x\', f);' '0 1 0' ''
        '03' 'reports an indented case line without a title literal' T-ABC-AA $'\ttest(title, f);' '0 0 1' 'Error: a.spec.dart:1: no case ID'
      End

      It "Then: [Edge] T-RUN-PDA-05-$1: $2"
        When call _check_line "$3" "$4"
        The status should be success
        The output should equal "$5"
        The stderr should equal "$6"
      End
    End

    Describe 'indented wrapped declarations'
      It "Then: [Edge] T-RUN-PDA-18: reads a tab-indented testWidgets( with a double-quoted next line"
        When call _check_line T-ABC-AA $'\ttestWidgets(' $'\t\t"T-ABC-AA-01: x",'
        The status should be success
        The output should equal '0 1 0'
        The stderr should equal ''
      End
    End

    Describe 'lines that declare nothing'
      # 枝番、説明、行
      Parameters
        '01' 'a case keyword after another character' "// test('T-ABC-AA-01: x', f);"
        '02' 'a case keyword not followed by (' "test.skip('T-ABC-AA-01: x', f);"
        '03' 'a group keyword after another character' "// group('T-ABC-BB: x', () {"
      End

      It "Then: [Edge] T-RUN-PDA-06-$1: ignores $2"
        When call _check_line T-ABC-AA "$3"
        The status should be success
        The output should equal '0 0 0'
        The stderr should equal ''
      End
    End

    Describe 'lines that do not read the next line'
      It "Then: [Edge] T-RUN-PDA-19: ignores a wrapped group("
        When call _check_line '' 'group(' "  'T-ABC-AA: x',"
        The status should be success
        The output should equal '0 0 0'
        The stderr should equal ''
      End

      It "Then: [Edge] T-RUN-PDA-20: ignores a wrapped case keyword after another word"
        When call _check_line T-ABC-AA 'await test(' "  'T-ABC-AA-01: x',"
        The status should be success
        The output should equal '0 0 0'
        The stderr should equal ''
      End
    End

    Describe 'non-declarations without a next line'
      It "Then: [Edge] T-RUN-PDA-23: ignores a line that declares nothing, under set -u"
        Set 'nounset:on'
        When call _check_line T-ABC-AA 'await f();'
        The status should be success
        The output should equal '0 0 0'
        The stderr should equal ''
      End
    End
  End
End
