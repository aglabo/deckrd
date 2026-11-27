#!/usr/bin/env bash
# src: ./skills/deckrd/skills/deckrd/scripts/libs/__tests__/unit/module-decl.lib.unit.spec.sh
# @(#) : ShellSpec tests for module-decl.lib.sh
#
# Copyright (c) 2026- atsushifx <https://github.com/atsushifx>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

# shellcheck shell=bash

# --- テスト基盤 ---
Include "${SHELLSPEC_SPECFILE%/*}/../spec_helper.sh"

# --- テスト対象 ---
Include "${SHELLSPEC_PROJECT_ROOT}/skills/deckrd/skills/deckrd/scripts/libs/module-decl.lib.sh"

# --- 内部ヘルパー ---

# 定数

# _MDL_SUFFIX - 宣言ファイルの <ns>/<mod> ディレクトリから見た位置。期待値は lib の定数を使わずに書く
_MDL_SUFFIX='workspaces/module/module.md'

# _MDL_NL - 改行 1 文字。解決したパスに改行が無いことを確かめる
_MDL_NL=$'\n'

# 関数

# _mdl_setup - 空の一時ディレクトリを作り、その下を docs ルート _MDL_DOCS とする
#   (docs ルート自体は作らない)
# @return 0 成功
_mdl_setup() {
  _MDL_TMPDIR="$(mktemp -d)"
  _MDL_DOCS="${_MDL_TMPDIR}/docs"
}

# _mdl_teardown - _mdl_setup が作った一時ディレクトリを削除する
# @return 0 always
_mdl_teardown() {
  [[ -n "${_MDL_TMPDIR:-}" && -d "$_MDL_TMPDIR" ]] && rm -rf "$_MDL_TMPDIR"
  unset _MDL_TMPDIR _MDL_DOCS
}

# _mdl_add_file - docs ルート配下に空でないファイルを置く。親ディレクトリが無ければ作る
# 前提: _mdl_setup 済みであること
# @arg $1 string docs ルートからの相対パス
# @return 0 成功
_mdl_add_file() {
  local path="${_MDL_DOCS}/$1"
  mkdir -p "${path%/*}"
  printf -- '---\ntest_scope: SMP\n---\n' >"$path"
}

# _mdl_round_trip - 参照をパスに解決し、そのパスから参照を導き直す
# @arg $1 string docs ルート
# @arg $2 string モジュール参照 (<ns>/<mod>)
# @set _MODULE_FILE, _MODULE_REF
# @return 0 成功
_mdl_round_trip() {
  module_decl_file_of "$1" "$2"
  module_decl_ref_of "$1" "$_MODULE_FILE"
}

# --- テスト本体 ---

Describe "module-decl.lib.sh"

  # docs ルート配下のモジュール宣言を列挙する
  Describe "T-LIB-MDLS: module_decl_list"
    Before "_mdl_setup"
    After "_mdl_teardown"

    Describe "When: 正常系"
      It "Then: [Normal] T-LIB-MDLS-01: workspaces/module 配下の宣言をソートしたフルパスで出力する"
        _mdl_add_file "ns/beta/${_MDL_SUFFIX}"
        _mdl_add_file "ns/alpha/${_MDL_SUFFIX}"
        When call module_decl_list "$_MDL_DOCS"
        The status should be success
        The lines of output should equal 2
        The line 1 of output should equal "${_MDL_DOCS}/ns/alpha/${_MDL_SUFFIX}"
        The line 2 of output should equal "${_MDL_DOCS}/ns/beta/${_MDL_SUFFIX}"
      End
    End

    Describe "When: 異常系"
      It "Then: [Error] T-LIB-MDLS-02: docs ルートが無ければ何も出力せず成功する"
        When call module_decl_list "${_MDL_TMPDIR}/absent"
        The status should be success
        The output should equal ""
        The stderr should equal ""
      End
    End

    Describe "When: エッジケース"
      It "Then: [Edge] T-LIB-MDLS-03: 旧配置 <ns>/<mod>/module.md は列挙しない"
        _mdl_add_file "ns/legacy/module.md"
        When call module_decl_list "$_MDL_DOCS"
        The status should be success
        The output should equal ""
      End
    End
  End

  # 宣言ファイルのパスから <ns>/<mod> 参照を導く。module_decl_file_of の逆
  Describe "T-LIB-MDRF: module_decl_ref_of"
    Describe "When: 正常系"
      It "Then: [Normal] T-LIB-MDRF-01: 宣言ファイルのパスから <ns>/<mod> を _MODULE_REF に代入し何も出力しない"
        When call module_decl_ref_of "/r/docs" "/r/docs/ns/alpha/${_MDL_SUFFIX}"
        The status should be success
        The output should equal ""
        The variable _MODULE_REF should equal "ns/alpha"
      End
    End

    Describe "When: 異常系"
      It "Then: [Error] T-LIB-MDRF-02: docs ルート外のパスは接尾辞だけを剥がす"
        When call module_decl_ref_of "/r/docs" "/other/ns/alpha/${_MDL_SUFFIX}"
        The status should be success
        The variable _MODULE_REF should equal "/other/ns/alpha"
      End
    End

    Describe "When: エッジケース"
      It "Then: [Edge] T-LIB-MDRF-03: 多階層の名前空間を保つ"
        When call module_decl_ref_of "/r/docs" "/r/docs/ns/sub/alpha/${_MDL_SUFFIX}"
        The status should be success
        The variable _MODULE_REF should equal "ns/sub/alpha"
      End
    End
  End

  # <ns>/<mod> 参照を宣言ファイルのパスに解決する。ファイルの存在は問わない
  Describe "T-LIB-MDFL: module_decl_file_of"
    Describe "When: 正常系"
      It "Then: [Normal] T-LIB-MDFL-01: 参照を宣言ファイルのパスとして _MODULE_FILE に代入し何も出力しない"
        When call module_decl_file_of "/r/docs" "ns/alpha"
        The status should be success
        The output should equal ""
        The variable _MODULE_FILE should equal "/r/docs/ns/alpha/${_MDL_SUFFIX}"
      End
    End

    Describe "When: 異常系"
      It "Then: [Error] T-LIB-MDFL-02: 宣言ファイルの無い参照もパスを解決し前回の値を残さない"
        _MODULE_FILE="stale"
        When call module_decl_file_of "/r/docs" "ns/missing"
        The status should be success
        The variable _MODULE_FILE should equal "/r/docs/ns/missing/${_MDL_SUFFIX}"
      End
    End

    Describe "When: エッジケース"
      It "Then: [Edge] T-LIB-MDFL-03: 解決したパスに改行を付けない"
        When call module_decl_file_of "/r/docs" "ns/alpha"
        The status should be success
        The variable _MODULE_FILE should not include "$_MDL_NL"
      End

      It "Then: [Edge] T-LIB-MDFL-04: 空白を含む docs ルートで参照がパスを経て元に戻る"
        When call _mdl_round_trip "/r x/docs" "ns/alpha"
        The status should be success
        The variable _MODULE_REF should equal "ns/alpha"
      End
    End
  End
End
