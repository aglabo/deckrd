#!/usr/bin/env bash
# skills/bdd-coder/skills/bdd-coder/scripts/check-ids/plugins/__tests__/unit/go-id-checker.plugin.unit.spec.sh
# @(#) : BDD unit tests for go-id-checker.plugin.sh
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
Include "${_PLUGIN_DIR}/go-id-checker.plugin.sh"

# --- 内部ヘルパー ---

# 関数
# プラグインが言語の表に登録した go の値を出力する。$1: 表の名前
_registered_value() {
  local -n _table="$1"
  echo "${_table[go]}"
}

# 直前のグループ ID を設定して 1 行を読み、グループ・ケース・エラーの件数を出力する。
# counts_init と declared_ids_init の後に呼ぶ。$1: 直前のグループ ID、$2: 行
_check_line() {
  _GROUP_ID="$1"
  check_go_line a_test.go:1 "$2" || return 1
  echo "${_COUNTS[group]} ${_COUNTS[case]} ${_COUNTS[errors]}"
}

# --- テスト本体 ---

# go-id-checker.plugin.sh の check_go_line。言語の表への登録と、t.Run の宣言行の計数と検査
Describe 'T-RUN-PGO: check_go_line'
  BeforeEach 'counts_init' 'declared_ids_init'

  Describe 'When: 正常系'
    Describe 'language tables'
      # 枝番、説明、表の名前、期待する値
      Parameters
        '01' 'the file name glob' LANG_FILES '*_test.go'
        '02' 'the line handler' LANG_HANDLER check_go_line
      End

      It "Then: [Normal] T-RUN-PGO-01-$1: registers $2"
        When call _registered_value "$3"
        The status should be success
        The output should equal "$4"
      End
    End

    Describe 'group declarations'
      It 'Then: [Normal] T-RUN-PGO-02-01: counts a group declared by t.Run'
        When call _check_line '' 't.Run("T-ABC-AA: x", f)'
        The status should be success
        The output should equal '1 0 0'
        The stderr should equal ''
      End
    End

    Describe 'case declarations'
      # 枝番、説明、行
      Parameters
        '01' 'a case declared by t.Run' 't.Run("T-ABC-AA-01: x", f)'
        '02' 'a table-driven ID as a case' 't.Run("T-ABC-AA-03-"+tc.name, f)'
      End

      It "Then: [Normal] T-RUN-PGO-03-$1: counts $2"
        When call _check_line T-ABC-AA "$3"
        The status should be success
        The output should equal '0 1 0'
        The stderr should equal ''
      End
    End
  End

  Describe 'When: 異常系'
    Describe 't.Run lines without a readable ID'
      # 枝番、説明、行
      Parameters
        '01' 'a title without an ID' 't.Run("sample", f)'
        '02' 'a call without a title literal' 't.Run(name, f)'
        '03' 'a blank before the quote' 't.Run( "T-ABC-AA-01: x", f)'
      End

      It "Then: [Error] T-RUN-PGO-04-$1: reports $2"
        When call _check_line T-ABC-AA "$3"
        The status should be success
        The output should equal '0 0 1'
        The stderr should equal 'Error: a_test.go:1: no case ID'
      End
    End
  End

  Describe 'When: エッジケース'
    Describe 'indented lines'
      # 枝番、説明、直前のグループ ID、行、期待する件数
      Parameters
        '01' 'an indented group line' '' $' \tt.Run("T-ABC-AA: x", f)' '1 0 0'
        '02' 'an indented case line' T-ABC-AA $'\tt.Run("T-ABC-AA-01: x", f)' '0 1 0'
      End

      It "Then: [Edge] T-RUN-PGO-05-$1: counts $2"
        When call _check_line "$3" "$4"
        The status should be success
        The output should equal "$5"
        The stderr should equal ''
      End
    End

    Describe 'lines that declare nothing'
      # 枝番、説明、行
      Parameters
        '01' 'a call that does not start its line' 'if !t.Run("T-ABC-AA-01: x", f) {'
        '02' 'a word that differs from t.Run at the dot' $'\ttXRun(name, f)'
      End

      It "Then: [Edge] T-RUN-PGO-06-$1: ignores $2"
        When call _check_line T-ABC-AA "$3"
        The status should be success
        The output should equal '0 0 0'
        The stderr should equal ''
      End
    End
  End
End
