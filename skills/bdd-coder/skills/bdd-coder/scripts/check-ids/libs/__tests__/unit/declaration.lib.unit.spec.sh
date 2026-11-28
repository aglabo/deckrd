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

# 見本のパターンで 1 行を数え、グループ・ケース・エラーの件数と直前のグループ ID を出力する。
# $1: 直前のグループ ID、$2: ファイル名と行番号、$3: 行
_count_line() {
  _GROUP_ID="$1"
  count_line_declaration "$2" "$3" "^(Describe) ${_QUOTE}(.*)" "^(It) ${_QUOTE}(.*)" '^(It)$' || return 1
  echo "${_COUNTS[group]} ${_COUNTS[case]} ${_COUNTS[errors]} ${_GROUP_ID}"
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

# declaration.lib.sh の count_line_declaration。行を読み、宣言なら計数と検査をする
Describe 'T-RUN-CLD2: count_line_declaration'
  BeforeEach 'counts_init' 'declared_ids_init'

  Describe 'When: 正常系'
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

  Describe 'When: 異常系'
    It 'Then: [Error] T-RUN-CLD2-02: reports a case keyword line without a title'
      When call _count_line '' a:2 'It'
      The status should be success
      The output should equal '0 0 1 '
      The stderr should equal 'Error: a:2: no case ID'
    End
  End

  Describe 'When: エッジケース'
    It 'Then: [Edge] T-RUN-CLD2-03: ignores a line that is not a declaration'
      When call _count_line '' a:1 'It=1'
      The status should be success
      The output should equal '0 0 0 '
      The stderr should equal ''
    End
  End
End
