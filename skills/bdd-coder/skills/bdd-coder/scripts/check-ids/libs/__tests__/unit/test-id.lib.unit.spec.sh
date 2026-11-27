#!/usr/bin/env bash
# skills/bdd-coder/skills/bdd-coder/scripts/check-ids/libs/__tests__/unit/test-id.lib.unit.spec.sh
# @(#) : BDD unit tests for test-id.lib.sh
#
# Copyright (c) 2026- atsushifx <https://github.com/atsushifx>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

# shellcheck shell=bash
# shellcheck disable=SC2016

# --- テスト対象 ---
_LIBRARY_DIR="${SHELLSPEC_PROJECT_ROOT}/skills/bdd-coder/skills/bdd-coder/scripts/check-ids/libs"
_LIBRARY="${_LIBRARY_DIR}/test-id.lib.sh"
Include "${_LIBRARY_DIR}/report.lib.sh"
Include "$_LIBRARY"

# --- 内部ヘルパー ---

# 関数
# タイトルを順に読み、最後の結果を ID|種類 の形で出力する。$@: タイトル
_parse_titles() {
  local title
  for title in "$@"; do
    parse_title_id "$title" || return 1
  done
  echo "${_ID}|${_ID_KIND}"
}

# 手順を順に実行する。$@: "group|case <id> [<at>]" の宣言、または関数名
_run_steps() {
  local step kind id at
  for step in "$@"; do
    read -r kind id at <<<"$step"
    case "$kind" in
      group | case) check_declared_id "$kind" "$id" "${at:-a.spec.sh:1}" ;;
      *) "$kind" ;;
    esac
  done
}

# --- テスト本体 ---

# test-id.lib.sh の parse_title_id。タイトルの ID とグループ・ケースの判定
Describe 'T-RUN-TIP: parse_title_id'
  Describe 'When: 正常系'
    # 枝番、説明、タイトル、期待する ID|種類
    Parameters
      '01' 'a tab before the ID' $'Then:\tT-ABC-AA-01: x' 'T-ABC-AA-01|case'
      '02' 'a lowercase word that starts with T-' 'T-shirt-size T-ABC-AA-01: x' 'T-ABC-AA-01|case'
      '03' 'an ID ending at an underscore' 'T-ABC-AA-01_x' 'T-ABC-AA-01|case'
      '04' 'a case ID with a branch number' 'T-ABC-AA-01-02: x' 'T-ABC-AA-01-02|case'
      '05' 'a table-driven ID with a trailing hyphen' 'T-ABC-AA-03-${branch}: x' 'T-ABC-AA-03|case'
      '06' 'a group of three segments' 'T-ABC-AA-BB: x' 'T-ABC-AA-BB|group'
      '07' 'a group of two segments ending in a number' 'T-AB-01: x' 'T-AB-01|group'
      '08' 'segments of any length' 'T-A-ABCDE: x' 'T-A-ABCDE|group'
      '09' 'a one-digit sequence number as a group' 'T-ABC-AA-5: x' 'T-ABC-AA-5|group'
      '10' 'a three-digit sequence number as a group' 'T-ABC-AA-001: x' 'T-ABC-AA-001|group'
    End

    It "Then: [Normal] T-RUN-TIP-01-$1: reads $2"
      When call _parse_titles "$3"
      The status should be success
      The output should equal "$4"
    End
  End

  Describe 'When: 異常系'
    # 枝番、説明、期待する ID|種類、順に読むタイトル
    Parameters
      '01' 'a lowercase segment' 'T-ABC-aa|' 'T-ABC-aa: x'
      '02' 'a letter after the sequence number' 'T-ABC-AA-01a|' 'T-ABC-AA-01a: x'
      '03' 'a first T- word that is not an ID' 'T-ABC-x|' 'T-ABC-x T-ABC-AA-01: x'
      '04' 'a T- that follows another character' '|' 'Then:xT-ABC-AA-01: x'
      '05' 'a title after one with an ID' '|' 'T-ABC-AA-01: x' 'sample'
    End

    It "Then: [Error] T-RUN-TIP-02-$1: finds no kind for $2"
      When call _parse_titles "${@:4}"
      The status should be success
      The output should equal "$3"
    End
  End
End

# test-id.lib.sh の check_declared_id。ID の所属と重複の検査、記録
Describe 'T-RUN-CDI: check_declared_id'
  BeforeEach 'counts_init' 'declared_ids_init' 'group_id_reset'

  Describe 'When: 正常系'
    # 枝番、説明、順に実行する手順
    Parameters
      '01' 'a case of the second group' 'group T-ABC-AA' 'group T-ABC-BB' 'case T-ABC-BB-01'
      '02' 'case IDs that differ only in the branch number' 'group T-ABC-AA' 'case T-ABC-AA-01-01' 'case T-ABC-AA-01-02'
    End

    It "Then: [Normal] T-RUN-CDI-01-$1: accepts $2"
      When call _run_steps "${@:3}"
      The status should be success
      The stderr should equal ''
    End
  End

  Describe 'When: 異常系'
    # 枝番、説明、期待するエラー出力 (全行)、順に実行する手順
    Parameters
      '01' 'a case of another group' 'Error: a.spec.sh:2: case ID outside the group: T-ABC-BB-01' 'group T-ABC-AA' 'case T-ABC-BB-01 a.spec.sh:2'
      '02' 'a case ID with three number suffixes' 'Error: a.spec.sh:2: case ID outside the group: T-ABC-AA-01-02-03' 'group T-ABC-AA' 'case T-ABC-AA-01-02-03 a.spec.sh:2'
      '03' 'a case with no group ID before it' 'Error: a.spec.sh:1: case ID outside the group: T-ABC-AA-01' 'group_id_reset' 'case T-ABC-AA-01 a.spec.sh:1'
      '04' 'the second and the third declaration of an ID' $'Error: a.spec.sh:3: duplicate ID: T-ABC-AA-01\nError: a.spec.sh:4: duplicate ID: T-ABC-AA-01' 'group T-ABC-AA' 'case T-ABC-AA-01 a.spec.sh:2' 'case T-ABC-AA-01 a.spec.sh:3' 'case T-ABC-AA-01 a.spec.sh:4'
      '05' 'the outside-group error before the duplicate error' $'Error: sub/b.spec.sh:2: case ID outside the group: T-ABC-AA-01\nError: sub/b.spec.sh:2: duplicate ID: T-ABC-AA-01' 'group T-ABC-AA' 'case T-ABC-AA-01' 'group_id_reset' 'group T-ABC-BB sub/b.spec.sh:1' 'case T-ABC-AA-01 sub/b.spec.sh:2'
    End

    It "Then: [Error] T-RUN-CDI-02-$1: reports $2"
      When call _run_steps "${@:4}"
      The status should be success
      The stderr should equal "$3"
    End
  End
End

# test-id.lib.sh の declared_ids_init。宣言済み ID の消去
Describe 'T-RUN-DII: declared_ids_init'
  BeforeEach 'counts_init' 'declared_ids_init' 'group_id_reset'

  It 'Then: [Normal] T-RUN-DII-01: forgets the declared IDs'
    When call _run_steps 'group T-ABC-AA' 'declared_ids_init' 'group T-ABC-AA'
    The status should be success
    The stderr should equal ''
  End
End

# test-id.lib.sh の group_id_reset。グループ ID の消去
Describe 'T-RUN-GRR: group_id_reset'
  BeforeEach 'counts_init' 'declared_ids_init' 'group_id_reset'

  It 'Then: [Normal] T-RUN-GRR-01: forgets the group ID'
    When call _run_steps 'group T-ABC-AA' 'group_id_reset' 'case T-ABC-AA-01 b.spec.sh:1'
    The status should be success
    The stderr should equal 'Error: b.spec.sh:1: case ID outside the group: T-ABC-AA-01'
  End
End
