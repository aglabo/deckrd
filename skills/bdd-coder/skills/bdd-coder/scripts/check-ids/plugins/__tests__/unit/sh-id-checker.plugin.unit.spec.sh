#!/usr/bin/env bash
# skills/bdd-coder/skills/bdd-coder/scripts/check-ids/plugins/__tests__/unit/sh-id-checker.plugin.unit.spec.sh
# @(#) : BDD unit tests for sh-id-checker.plugin.sh
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
Include "${_PLUGIN_DIR}/sh-id-checker.plugin.sh"

# --- 内部ヘルパー ---

# 関数
# プラグインが言語の表に登録した sh の値を出力する。$1: 表の名前
_registered_value() {
  local -n _table="$1"
  echo "${_table[sh]}"
}

# 直前のグループ ID を設定して 1 行を読み、グループ・ケース・エラーの件数を出力する。
# counts_init と declared_ids_init の後に呼ぶ。$1: 直前のグループ ID、$2: 行
_check_line() {
  _GROUP_ID="$1"
  check_sh_line a.spec.sh:1 "$2" || return 1
  echo "${_COUNTS[group]} ${_COUNTS[case]} ${_COUNTS[errors]}"
}

# --- テスト本体 ---

# sh-id-checker.plugin.sh の check_sh_line。言語の表への登録と、ShellSpec の宣言行の計数と検査
Describe 'T-RUN-PSH: check_sh_line'
  BeforeEach 'counts_init' 'declared_ids_init'

  Describe 'When: 正常系'
    Describe 'language tables'
      # 枝番、説明、表の名前、期待する値
      Parameters
        '01' 'the file name glob' LANG_FILES '*.spec.sh'
        '02' 'the line handler' LANG_HANDLER check_sh_line
      End

      It "Then: [Normal] T-RUN-PSH-01-$1: registers $2"
        When call _registered_value "$3"
        The status should be success
        The output should equal "$4"
      End
    End

    Describe 'group keywords'
      # 枝番、キーワード、行
      Parameters
        '01' 'Describe' "Describe 'T-ABC-AA: x'"
        '02' 'Context' "Context 'T-ABC-AA: x'"
        '03' 'ExampleGroup' "ExampleGroup 'T-ABC-AA: x'"
      End

      It "Then: [Normal] T-RUN-PSH-02-$1: counts a group declared by $2"
        When call _check_line '' "$3"
        The status should be success
        The output should equal '1 0 0'
        The stderr should equal ''
      End
    End

    Describe 'case keywords'
      # 枝番、キーワード、行
      Parameters
        '01' 'It' "It 'T-ABC-AA-01: x'"
        '02' 'Example' "Example 'T-ABC-AA-01: x'"
        '03' 'Specify' "Specify 'T-ABC-AA-01: x'"
      End

      It "Then: [Normal] T-RUN-PSH-03-$1: counts a case declared by $2"
        When call _check_line T-ABC-AA "$3"
        The status should be success
        The output should equal '0 1 0'
        The stderr should equal ''
      End
    End
  End

  Describe 'When: 異常系'
    Describe 'case keywords without a title'
      # 枝番、キーワードの後ろの説明、行
      Parameters
        '01' 'a space' 'It $title'
        '02' 'a tab' $'Example\t$title'
        '03' 'a CR' $'Specify\r'
        '04' 'the line end' 'It'
        '05' 'the line end after an indent' $' \tIt'
      End

      It "Then: [Error] T-RUN-PSH-04-$1: reports a case keyword before $2"
        When call _check_line T-ABC-AA "$3"
        The status should be success
        The output should equal '0 0 1'
        The stderr should equal 'Error: a.spec.sh:1: no case ID'
      End
    End
  End

  Describe 'When: エッジケース'
    Describe 'indented lines'
      # 枝番、説明、直前のグループ ID、行、期待する件数
      Parameters
        '01' 'an indented group line' '' $' \tDescribe \'T-ABC-AA: x\'' '1 0 0'
        '02' 'an indented case line' T-ABC-AA $' \tIt \'T-ABC-AA-01: x\'' '0 1 0'
      End

      It "Then: [Edge] T-RUN-PSH-05-$1: counts $2"
        When call _check_line "$3" "$4"
        The status should be success
        The output should equal "$5"
        The stderr should equal ''
      End
    End

    Describe 'blanks before the quote'
      # 枝番、説明、直前のグループ ID、行、期待する件数
      Parameters
        '01' 'a group line' '' $'Describe \t\'T-ABC-AA: x\'' '1 0 0'
        '02' 'a case line' T-ABC-AA $'It\t \'T-ABC-AA-01: x\'' '0 1 0'
      End

      It "Then: [Edge] T-RUN-PSH-06-$1: counts $2 with blanks before the quote"
        When call _check_line "$3" "$4"
        The status should be success
        The output should equal "$5"
        The stderr should equal ''
      End
    End

    Describe 'lines that declare nothing'
      # 枝番、説明、行
      Parameters
        '01' 'a case keyword followed by another character' 'It=1'
        '02' 'a group keyword joined to its quote' "Describe'T-ABC-AA: x'"
        '03' 'a case keyword joined to its quote' "It'T-ABC-AA-01: x'"
        '04' 'a group keyword with no title literal' 'Describe $title'
        '05' 'a group keyword after another character' "# Describe 'T-ABC-AA: x'"
        '06' 'a case keyword after another character' "# It 'T-ABC-AA-01: x'"
      End

      It "Then: [Edge] T-RUN-PSH-07-$1: ignores $2"
        When call _check_line T-ABC-AA "$3"
        The status should be success
        The output should equal '0 0 0'
        The stderr should equal ''
      End
    End
  End
End
