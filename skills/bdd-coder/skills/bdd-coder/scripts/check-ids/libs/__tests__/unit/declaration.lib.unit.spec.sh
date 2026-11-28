#!/usr/bin/env bash
# skills/bdd-coder/skills/bdd-coder/scripts/check-ids/libs/__tests__/unit/declaration.lib.unit.spec.sh
# @(#) : BDD unit tests for declaration.lib.sh
#
# Copyright (c) 2026- atsushifx <https://github.com/atsushifx>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

# shellcheck shell=bash
# shellcheck disable=SC2016

# --- テスト対象 ---
_LIBRARY_DIR="${SHELLSPEC_PROJECT_ROOT}/skills/bdd-coder/skills/bdd-coder/scripts/check-ids/libs"
_LIBRARY="${_LIBRARY_DIR}/declaration.lib.sh"
Include "${_LIBRARY_DIR}/report.lib.sh"
Include "${_LIBRARY_DIR}/test-id.lib.sh"
Include "$_LIBRARY"

# 見本のケース開始パターン (tsjs プラグインと同形)
_CASE_START='^[[:blank:]]*(it|test)[(]'

# --- 内部ヘルパー ---

# 関数
# 言語に依存しない見本のパターンで行を読み、種類|タイトル の形で出力する。$1: 行
_read_line() {
  read_declaration "$1" "^(Describe) +${_QUOTE}(.*)" "^(It) +${_QUOTE}(.*)" '^(It)( |$)' || return 1
  echo "${_KIND}|${_TITLE}"
}

# 前の行のタイトルが残った状態で、UTF-8 ロケールから行を読む。$1: 行
_read_after_stale() {
  local LC_ALL=C.UTF-8
  _TITLE=stale
  _read_line "$1"
}

# 宣言を順に数え、グループ ID・ケース ID・エラーの件数を出力する。$@: "group|case <at> <title>"
_count_declarations() {
  local step kind at title
  for step in "$@"; do
    read -r kind at title <<<"$step"
    "count_${kind}_declaration" "$at" "$title" || return 1
  done
  echo "${_COUNTS[group]} ${_COUNTS[case]} ${_COUNTS[errors]}"
}

# 折り返された宣言なら、次の行の一致を 引用符|残り の形で出力する。引数は is_wrapped_declaration と同じ
_read_wrapped() {
  is_wrapped_declaration "$@" || return 1
  echo "${BASH_REMATCH[-2]}|${BASH_REMATCH[-1]}"
}

# 見本のパターンで 1 行を数え、グループ・ケース・エラーの件数と直前のグループ ID を出力する。
# $1: 直前のグループ ID、$2: ファイル名と行番号、$3: 行、$4: 次の行 (省略可)
_count_line() {
  _GROUP_ID="$1"
  count_line_declaration "$2" "$3" "^(Describe) ${_QUOTE}(.*)" "^(It) ${_QUOTE}(.*)" '^(It)$' "${@:4}" || return 1
  echo "${_COUNTS[group]} ${_COUNTS[case]} ${_COUNTS[errors]} ${_GROUP_ID}"
}

# 見本のパターン (tsjs プラグインと同形) で 1 行を数える。引数は count_line_declaration の
# パターン以外と同じ。$1: ファイル名と行番号、$2: 行、$3: 次の行 (省略可)
_declare_wrapped() {
  count_line_declaration "$1" "$2" "^[[:blank:]]*(describe)[(]${_QUOTE}(.*)" \
    "^[[:blank:]]*(it|test)[(]${_QUOTE}(.*)" "$_CASE_START" "${@:3}"
}

# 見本のパターンで行を順に数え、グループ・ケース・エラーの件数と直前のグループ ID を出力する。
# $1: 直前のグループ ID、$2 以降: _declare_wrapped の引数。複数の呼び出しは -- で区切る
_count_wrapped() {
  _GROUP_ID="$1"
  local arg
  local -a call=()
  for arg in "${@:2}" --; do
    if [[ $arg != -- ]]; then
      call+=("$arg")
      continue
    fi
    _declare_wrapped "${call[@]}" || return 1
    call=()
  done
  echo "${_COUNTS[group]} ${_COUNTS[case]} ${_COUNTS[errors]} ${_GROUP_ID}"
}

# UTF-8 ロケールから _count_wrapped を呼ぶ。引数は _count_wrapped と同じ
_count_wrapped_in_utf8() {
  local LC_ALL=C.UTF-8
  _count_wrapped "$@"
}

# --- テスト本体 ---

# declaration.lib.sh の read_declaration。行を宣言として読む
Describe 'T-RUN-RDC: read_declaration'
  Describe 'When: 正常系'
    # 枝番、説明、行、期待する 種類|タイトル
    Parameters
      '01' 'the kind and the title of a group declaration' "Describe 'T-ABC-AA: x'" 'group|T-ABC-AA: x'
      '02' 'a double-quoted title holding another quote' "It \"it's T-ABC-AA-01: x\"" "case|it's T-ABC-AA-01: x"
      '03' 'a backquoted title' 'It `T-ABC-AA-01: x`' 'case|T-ABC-AA-01: x'
      '04' 'a title that ends at the closing quote' "It 'sample' # T-ABC-AA-01" 'case|sample'
    End

    It "Then: [Normal] T-RUN-RDC-01-$1: reads $2"
      When call _read_line "$3"
      The status should be success
      The output should equal "$4"
    End
  End

  Describe 'When: 異常系'
    It 'Then: [Error] T-RUN-RDC-03: rejects a line that is not a declaration'
      When call _read_line 'echo x'
      The status should equal 1
      The output should equal ''
    End
  End

  Describe 'When: エッジケース'
    # 枝番、説明、行、期待する 種類|タイトル
    Parameters
      '01' 'an empty title for a case keyword with no title literal' 'It $title' 'case|'
      '02' 'a title holding a byte that is not UTF-8' $'It \x27\xff T-ABC-AA-01\x27' $'case|\xff T-ABC-AA-01'
    End

    It "Then: [Edge] T-RUN-RDC-02-$1: reads $2"
      When call _read_after_stale "$3"
      The status should be success
      The output should equal "$4"
    End
  End
End

# declaration.lib.sh の count_group_declaration。グループ宣言の ID の計数と検査
Describe 'T-RUN-CGD: count_group_declaration'
  BeforeEach 'counts_init' 'declared_ids_init' 'group_id_reset'

  Describe 'When: 正常系'
    It 'Then: [Normal] T-RUN-CGD-01: counts a group declaration with a group ID'
      When call _count_declarations 'group a.spec.sh:1 T-ABC-AA: x'
      The status should be success
      The output should equal '1 0 0'
      The stderr should equal ''
    End
  End

  Describe 'When: 異常系'
    It 'Then: [Error] T-RUN-CGD-02: reports a duplicate group ID'
      When call _count_declarations 'group a.spec.sh:1 T-ABC-AA: x' 'group a.spec.sh:2 T-ABC-AA: x'
      The status should be success
      The output should equal '2 0 1'
      The stderr should equal 'Error: a.spec.sh:2: duplicate ID: T-ABC-AA'
    End
  End

  Describe 'When: エッジケース'
    # 枝番、説明、数えない宣言
    Parameters
      '01' 'a group declaration without an ID' 'group a.spec.sh:1 When: x'
      '02' 'a group declaration with a case ID' 'group a.spec.sh:1 T-ABC-AA-01: y'
    End

    It "Then: [Edge] T-RUN-CGD-03-$1: counts nothing for $2"
      _GROUP_ID=T-ABC-BB
      When call _count_declarations "$3"
      The status should be success
      The output should equal '0 0 0'
      The stderr should equal ''
      The variable '_GROUP_ID' should equal 'T-ABC-BB'
    End
  End
End

# declaration.lib.sh の count_case_declaration。ケース宣言の ID の計数と検査
Describe 'T-RUN-CCD: count_case_declaration'
  BeforeEach 'counts_init' 'declared_ids_init' 'group_id_reset'

  Describe 'When: 正常系'
    It 'Then: [Normal] T-RUN-CCD-01: counts a case declaration with a case ID in its group'
      When call _count_declarations 'group a.spec.sh:1 T-ABC-AA: x' 'case a.spec.sh:2 T-ABC-AA-01: x'
      The status should be success
      The output should equal '1 1 0'
      The stderr should equal ''
    End
  End

  Describe 'When: 異常系'
    # 枝番、説明、期待する件数、期待するエラー出力、順に数える宣言
    Parameters
      '01' 'a case declaration without an ID' '0 0 1' 'Error: a.spec.sh:1: no case ID' 'case a.spec.sh:1 sample'
      '02' 'a case declaration with a group ID' '0 0 1' 'Error: a.spec.sh:1: no case ID' 'case a.spec.sh:1 T-ABC-AA: x'
      '03' 'a case ID outside the group' '0 1 1' 'Error: a.spec.sh:1: case ID outside the group: T-ABC-AA-01' 'case a.spec.sh:1 T-ABC-AA-01: x'
    End

    It "Then: [Error] T-RUN-CCD-02-$1: reports $2"
      When call _count_declarations "${@:5}"
      The status should be success
      The output should equal "$3"
      The stderr should equal "$4"
    End
  End
End

# declaration.lib.sh の is_wrapped_declaration。次の行にタイトルがある折り返し宣言の判定
Describe 'T-RUN-IWD: is_wrapped_declaration'
  Describe 'When: 正常系'
    It 'Then: [Normal] T-RUN-IWD-01: accepts a keyword line ending with "(" before a quoted next line'
      When call _read_wrapped 'it(' "$_CASE_START" "  'T-ABC-AA-01: x',"
      The status should be success
      The output should equal "'|T-ABC-AA-01: x',"
    End
  End

  Describe 'When: 異常系'
    It 'Then: [Error] T-RUN-IWD-02: rejects a line with text after "("'
      When call is_wrapped_declaration 'it(name,' "$_CASE_START" "  'T-ABC-AA-01: x',"
      The status should equal 1
    End
  End

  Describe 'When: エッジケース'
    It 'Then: [Edge] T-RUN-IWD-03: does not treat the CR of a CRLF line as text after "("'
      When call is_wrapped_declaration $'it(\r' "$_CASE_START" $'  \'T-ABC-AA-01: x\',\r'
      The status should be success
    End

    It 'Then: [Edge] T-RUN-IWD-04: rejects a call without a next line, under set -u'
      Set 'nounset:on'
      When call is_wrapped_declaration 'it(' "$_CASE_START"
      The status should equal 1
      The stderr should equal ''
    End
  End
End

# declaration.lib.sh の count_line_declaration。行を読み、宣言なら計数と検査をする
Describe 'T-RUN-CLD2: count_line_declaration'
  BeforeEach 'counts_init' 'declared_ids_init'

  Describe 'When: 正常系'
    Describe 'a one-line declaration'
      # 枝番、説明、直前のグループ ID、ファイル名と行番号、行、期待する件数とグループ ID
      Parameters
        '01' 'a group line' '' a:1 "Describe 'T-ABC-AA: x'" '1 0 0 T-ABC-AA'
        '02' 'a case line' T-ABC-AA a:2 "It 'T-ABC-AA-01: x'" '0 1 0 T-ABC-AA'
      End

      It "Then: [Normal] T-RUN-CLD2-01-$1: counts $2"
        When call _count_line "$3" "$4" "$5"
        The status should be success
        The output should equal "$6"
        The stderr should equal ''
      End
    End

    Describe 'a wrapped case declaration'
      It 'Then: [Normal] T-RUN-CLD2-04: reads a single-quoted title on the next line'
        When call _count_wrapped T-ABC-AA a:2 'it(' "  'T-ABC-AA-01: x',"
        The status should be success
        The output should equal '0 1 0 T-ABC-AA'
        The stderr should equal ''
      End

      It 'Then: [Normal] T-RUN-CLD2-05: reads a double-quoted title on the next line'
        When call _count_wrapped T-ABC-AA a:2 'it(' '  "T-ABC-AA-01: x",'
        The status should be success
        The output should equal '0 1 0 T-ABC-AA'
        The stderr should equal ''
      End

      It 'Then: [Normal] T-RUN-CLD2-06: reads a backquoted title on the next line'
        When call _count_wrapped T-ABC-AA a:2 'it(' '  `T-ABC-AA-01: x`,'
        The status should be success
        The output should equal '0 1 0 T-ABC-AA'
        The stderr should equal ''
      End

      It 'Then: [Normal] T-RUN-CLD2-07: reads a next line without indentation'
        When call _count_wrapped T-ABC-AA a:2 'it(' "'T-ABC-AA-01: x',"
        The status should be success
        The output should equal '0 1 0 T-ABC-AA'
        The stderr should equal ''
      End

      It 'Then: [Normal] T-RUN-CLD2-08: reads a next line indented with a tab'
        When call _count_wrapped T-ABC-AA a:2 'it(' $'\t\'T-ABC-AA-01: x\','
        The status should be success
        The output should equal '0 1 0 T-ABC-AA'
        The stderr should equal ''
      End

      It 'Then: [Normal] T-RUN-CLD2-09: does not treat the CR of a CRLF line as text after "("'
        When call _count_wrapped T-ABC-AA a:2 $'it(\r' $'  \'T-ABC-AA-01: x\',\r'
        The status should be success
        The output should equal '0 1 0 T-ABC-AA'
        The stderr should equal ''
      End
    End
  End

  Describe 'When: 異常系'
    It 'Then: [Error] T-RUN-CLD2-02: reports a case keyword line without a title'
      When call _count_line '' a:2 'It'
      The status should be success
      The output should equal '0 0 1 '
      The stderr should equal 'Error: a:2: no case ID'
    End

    Describe 'checks of a wrapped case declaration'
      It 'Then: [Error] T-RUN-CLD2-10: reports a wrapped title without an ID'
        When call _count_wrapped T-ABC-AA a:2 'it(' "  'sample',"
        The status should be success
        The output should equal '0 0 1 T-ABC-AA'
        The stderr should equal 'Error: a:2: no case ID'
      End

      It 'Then: [Error] T-RUN-CLD2-11: reports a wrapped title with a group ID'
        When call _count_wrapped T-ABC-AA a:2 'it(' "  'T-ABC-AA: x',"
        The status should be success
        The output should equal '0 0 1 T-ABC-AA'
        The stderr should equal 'Error: a:2: no case ID'
      End

      It 'Then: [Error] T-RUN-CLD2-12: reports a wrapped case ID outside the group'
        When call _count_wrapped T-ABC-AA a:2 'it(' "  'T-ABC-BB-01: x',"
        The status should be success
        The output should equal '0 1 1 T-ABC-AA'
        The stderr should equal 'Error: a:2: case ID outside the group: T-ABC-BB-01'
      End

      It 'Then: [Error] T-RUN-CLD2-13: reports a wrapped case ID before any group declaration'
        When call _count_wrapped '' a:2 'it(' "  'T-ABC-AA-01: x',"
        The status should be success
        The output should equal '0 1 1 '
        The stderr should equal 'Error: a:2: case ID outside the group: T-ABC-AA-01'
      End

      It 'Then: [Error] T-RUN-CLD2-14: reports a wrapped declaration of a declared ID at its keyword line'
        When call _count_wrapped T-ABC-AA a:2 "it('T-ABC-AA-01: x'" -- a:5 'it(' "  'T-ABC-AA-01: y',"
        The status should be success
        The output should equal '0 2 1 T-ABC-AA'
        The stderr should equal 'Error: a:5: duplicate ID: T-ABC-AA-01'
      End

      It 'Then: [Error] T-RUN-CLD2-29: reports a one-line declaration of an ID declared by a wrapped one'
        When call _count_wrapped T-ABC-AA a:2 'it(' "  'T-ABC-AA-01: x'," -- a:5 "it('T-ABC-AA-01: y'"
        The status should be success
        The output should equal '0 2 1 T-ABC-AA'
        The stderr should equal 'Error: a:5: duplicate ID: T-ABC-AA-01'
      End
    End

    Describe 'a title that cannot be read'
      It 'Then: [Error] T-RUN-CLD2-15: reports a variable on the next line'
        When call _count_wrapped T-ABC-AA a:2 'it(' '  title,'
        The status should be success
        The output should equal '0 0 1 T-ABC-AA'
        The stderr should equal 'Error: a:2: no case ID'
      End

      It 'Then: [Error] T-RUN-CLD2-16: reports an empty next line'
        When call _count_wrapped T-ABC-AA a:2 'it(' ''
        The status should be success
        The output should equal '0 0 1 T-ABC-AA'
        The stderr should equal 'Error: a:2: no case ID'
      End

      It 'Then: [Error] T-RUN-CLD2-17: reports a call without a next line, under set -u'
        Set 'nounset:on'
        When call _count_wrapped T-ABC-AA a:2 'it('
        The status should be success
        The output should equal '0 0 1 T-ABC-AA'
        The stderr should equal 'Error: a:2: no case ID'
      End

      It 'Then: [Error] T-RUN-CLD2-18: does not read the next line after a variable that follows "("'
        When call _count_wrapped T-ABC-AA a:2 'it(name,' "  'T-ABC-AA-01: x',"
        The status should be success
        The output should equal '0 0 1 T-ABC-AA'
        The stderr should equal 'Error: a:2: no case ID'
      End

      It 'Then: [Error] T-RUN-CLD2-19: does not read the next line after a space that follows "("'
        When call _count_wrapped T-ABC-AA a:2 'it( ' "  'T-ABC-AA-01: x',"
        The status should be success
        The output should equal '0 0 1 T-ABC-AA'
        The stderr should equal 'Error: a:2: no case ID'
      End

      It 'Then: [Error] T-RUN-CLD2-20: does not read the next line when the last "(" is not the one of the keyword'
        When call _count_wrapped T-ABC-AA a:2 'it(wrap(' "  'T-ABC-AA-01: x',"
        The status should be success
        The output should equal '0 0 1 T-ABC-AA'
        The stderr should equal 'Error: a:2: no case ID'
      End

      It 'Then: [Error] T-RUN-CLD2-21: does not read the next line after a start pattern match without "("'
        When call _count_line T-ABC-AA a:2 'It' "  'T-ABC-AA-01: x'"
        The status should be success
        The output should equal '0 0 1 T-ABC-AA'
        The stderr should equal 'Error: a:2: no case ID'
      End
    End
  End

  Describe 'When: エッジケース'
    It 'Then: [Edge] T-RUN-CLD2-03: ignores a line that is not a declaration'
      When call _count_line '' a:1 'It=1'
      The status should be success
      The output should equal '0 0 0 '
      The stderr should equal ''
    End

    Describe 'the title on the next line'
      Describe 'text after the closing quote'
        # 枝番、説明、次の行
        Parameters
          '01' 'a quoted ID' "  'sample', 'T-ABC-AA-01'"
          '02' 'a bare ID' "  'sample', // T-ABC-AA-01"
        End

        It "Then: [Edge] T-RUN-CLD2-22-$1: does not read $2 after the closing quote"
          When call _count_wrapped T-ABC-AA a:2 'it(' "$3"
          The status should be success
          The output should equal '0 0 1 T-ABC-AA'
          The stderr should equal 'Error: a:2: no case ID'
        End
      End

      It 'Then: [Edge] T-RUN-CLD2-23: reads a wrapped title holding another quote'
        When call _count_wrapped T-ABC-AA a:2 'it(' "  \"it's T-ABC-AA-01: x\","
        The status should be success
        The output should equal '0 1 0 T-ABC-AA'
        The stderr should equal ''
      End

      It 'Then: [Edge] T-RUN-CLD2-24: counts a wrapped case ID with a branch number'
        When call _count_wrapped T-ABC-AA a:2 'it(' "  'T-ABC-AA-01-02: x',"
        The status should be success
        The output should equal '0 1 0 T-ABC-AA'
        The stderr should equal ''
      End

      It 'Then: [Edge] T-RUN-CLD2-25: reads to the end of the line when the wrapped literal is not closed'
        When call _count_wrapped T-ABC-AA a:2 'it(' "  'T-ABC-AA-01: x"
        The status should be success
        The output should equal '0 1 0 T-ABC-AA'
        The stderr should equal ''
      End

      It 'Then: [Edge] T-RUN-CLD2-26: reads a wrapped title holding a byte that is not UTF-8'
        When call _count_wrapped_in_utf8 T-ABC-AA a:2 'it(' $'  \'\xff T-ABC-AA-01: x\''
        The status should be success
        The output should equal '0 1 0 T-ABC-AA'
        The stderr should equal ''
      End

      It 'Then: [Edge] T-RUN-CLD2-27: reports an empty wrapped literal'
        When call _count_wrapped T-ABC-AA a:2 'it(' "  '',"
        The status should be success
        The output should equal '0 0 1 T-ABC-AA'
        The stderr should equal 'Error: a:2: no case ID'
      End

      It 'Then: [Edge] T-RUN-CLD2-28: does not read a quote that does not open the next line'
        When call _count_wrapped T-ABC-AA a:2 'it(' "  // 'T-ABC-AA-01: x'"
        The status should be success
        The output should equal '0 0 1 T-ABC-AA'
        The stderr should equal 'Error: a:2: no case ID'
      End
    End

    Describe 'lines that are not read with the next line'
      It 'Then: [Edge] T-RUN-CLD2-30: does not count a wrapped group declaration or change the group ID'
        When call _count_wrapped T-ABC-BB a:2 'describe(' "  'T-ABC-AA: x',"
        The status should be success
        The output should equal '0 0 0 T-ABC-BB'
        The stderr should equal ''
      End

      It 'Then: [Edge] T-RUN-CLD2-31: does not read the next line of a one-line declaration'
        When call _count_wrapped T-ABC-AA a:2 "it('T-ABC-AA-01: x'," "  'sample',"
        The status should be success
        The output should equal '0 1 0 T-ABC-AA'
        The stderr should equal ''
      End

      It 'Then: [Edge] T-RUN-CLD2-32: ignores a line that is not a declaration before a literal'
        When call _count_wrapped T-ABC-AA a:2 'foo(' "  'T-ABC-AA-01: x',"
        The status should be success
        The output should equal '0 0 0 T-ABC-AA'
        The stderr should equal ''
      End
    End
  End
End
