#!/usr/bin/env bash
# skills/bdd-coder/skills/bdd-coder/scripts/check-ids/libs/__tests__/unit/file-reader.lib.unit.spec.sh
# @(#) : BDD unit tests for file-reader.lib.sh
#
# Copyright (c) 2026- atsushifx <https://github.com/atsushifx>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

# shellcheck shell=bash

# --- テスト対象 ---
_LIBRARY_DIR="${SHELLSPEC_PROJECT_ROOT}/skills/bdd-coder/skills/bdd-coder/scripts/check-ids/libs"
_LIBRARY="${_LIBRARY_DIR}/file-reader.lib.sh"
Include "${_LIBRARY_DIR}/report.lib.sh"
Include "${_LIBRARY_DIR}/test-id.lib.sh"
Include "$_LIBRARY"

# --- 内部ヘルパー ---

# 定数
# UTF-8 のバイトオーダーマーク。ライブラリの _BOM とは別の名前にする
_UTF8_BOM=$'\xEF\xBB\xBF'

# 関数
# 空のフィクスチャディレクトリを作る
_setup_fixture() {
  _FIXTURE="$(mktemp -d)"
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

# 受け取った引数を | でつないで出力するハンドラ
_record() {
  local IFS='|'
  echo "$*"
}

# 呼び出し時点のグループ ID を [] で囲んで出力するハンドラ
_print_group_id() {
  echo "[${_GROUP_ID}]"
}

# 行の for ループ状態を追跡し、_IN_LOOP を [] で囲んで出力するハンドラ
_track_loop() {
  track_loop_block "$2"
  echo "[${_IN_LOOP}]"
}

# 前のファイル a.txt ($1 の 1 行) を _track_loop で読み、出力は捨てる
_read_previous_file() {
  _write_file a.txt "$1"
  read_file_lines "$_FIXTURE" a.txt _track_loop >/dev/null
}

# --- テスト本体 ---

# file-reader.lib.sh の read_file_lines。ファイルの各行を、次の行とともにハンドラに渡す
Describe 'T-RUN-RFL: read_file_lines'
  BeforeEach 'counts_init' '_setup_fixture'
  AfterEach '_teardown_fixture'

  Describe 'When: 正常系'
    It 'Then: [Normal] T-RUN-RFL-01: passes each line with its number, the extra arguments and the next line'
      _write_file sub/a.txt '  a\b ' '' 'c'
      When call read_file_lines "$_FIXTURE" sub/a.txt _record 'x y' '*'
      The status should be success
      The output should equal $'sub/a.txt:1|  a\x5cb |x y|*|\nsub/a.txt:2||x y|*|c\nsub/a.txt:3|c|x y|*|'
    End

    It 'Then: [Normal] T-RUN-RFL-02: resets the group ID at the start of a file'
      _write_file a.txt a
      _GROUP_ID=T-ABC-AA
      When call read_file_lines "$_FIXTURE" a.txt _print_group_id
      The status should be success
      The output should equal '[]'
    End

    It 'Then: [Normal] T-RUN-RFL-06: passes the next line as the third argument without extra arguments'
      _write_file a.txt a b
      When call read_file_lines "$_FIXTURE" a.txt _record
      The status should be success
      The output should equal $'a.txt:1|a|b\na.txt:2|b|'
    End

    It 'Then: [Normal] T-RUN-RFL-10: does not carry an unclosed for block to the next file'
      _read_previous_file 'for (const x of xs) {'
      _write_file b.txt 'f(x);'
      When call read_file_lines "$_FIXTURE" b.txt _track_loop
      The status should be success
      The output should equal '[]'
    End

    It 'Then: [Normal] T-RUN-RFL-11: does not carry a pending for header to the next file'
      _read_previous_file 'for (final c in ['
      _write_file b.txt ']) {'
      When call read_file_lines "$_FIXTURE" b.txt _track_loop
      The status should be success
      The output should equal '[]'
    End
  End

  Describe 'When: 異常系'
    It 'Then: [Error] T-RUN-RFL-03: reports an unreadable file without calling the handler'
      When call read_file_lines "$_FIXTURE" gone.txt _record
      The status should be success
      The output should equal ''
      The stderr should include 'Error: gone.txt: cannot read'
      The variable '_COUNTS[errors]' should equal 1
    End

    It 'Then: [Error] T-RUN-RFL-12: leaves the loop state unchanged for an unreadable file'
      _IN_LOOP='}'
      When call read_file_lines "$_FIXTURE" gone.txt _record
      The status should be success
      The stderr should include 'Error: gone.txt: cannot read'
      The variable '_IN_LOOP' should equal '}'
    End
  End

  Describe 'When: エッジケース'
    Describe 'a byte order mark'
      # 枝番、説明、期待する出力、ファイルの各行
      Parameters
        '01' 'strips it from the first line' $'a.txt:1|a|b\na.txt:2|b|' "${_UTF8_BOM}a" b
        '02' 'keeps it on the second line, as the next line and as the current line' $'a.txt:1|a|'"${_UTF8_BOM}b"$'\na.txt:2|'"${_UTF8_BOM}b|" a "${_UTF8_BOM}b"
      End

      It "Then: [Edge] T-RUN-RFL-04-$1: $2"
        _write_file a.txt "${@:4}"
        When call read_file_lines "$_FIXTURE" a.txt _record
        The status should be success
        The output should equal "$3"
      End
    End

    It 'Then: [Edge] T-RUN-RFL-05: does not call the handler for an empty file'
      : >"${_FIXTURE}/a.txt"
      When call read_file_lines "$_FIXTURE" a.txt _record
      The status should be success
      The output should equal ''
      The stderr should equal ''
    End

    It 'Then: [Edge] T-RUN-RFL-07: passes the next line with special characters unchanged'
      _write_file a.txt a '  b\c * '
      When call read_file_lines "$_FIXTURE" a.txt _record
      The status should be success
      The output should equal $'a.txt:1|a|  b\x5cc * \na.txt:2|  b\x5cc * |'
    End

    It 'Then: [Edge] T-RUN-RFL-08: passes an empty next line for a one-line file'
      Set 'nounset:on'
      _write_file a.txt a
      When call read_file_lines "$_FIXTURE" a.txt _record
      The status should be success
      The output should equal 'a.txt:1|a|'
    End

    It 'Then: [Edge] T-RUN-RFL-09: passes the last line of a file without a final newline'
      printf 'a\nb' >"${_FIXTURE}/a.txt"
      When call read_file_lines "$_FIXTURE" a.txt _record
      The status should be success
      The output should equal $'a.txt:1|a|b\na.txt:2|b|'
    End

    It 'Then: [Edge] T-RUN-RFL-13: resets the loop state for an empty file without calling the handler'
      : >"${_FIXTURE}/a.txt"
      _IN_LOOP='}' _LOOP_PENDING='}'
      When call read_file_lines "$_FIXTURE" a.txt _record
      The status should be success
      The output should equal ''
      The variable '_IN_LOOP' should equal ''
      The variable '_LOOP_PENDING' should equal ''
    End
  End

  Describe 'When: 状態遷移'
    It 'Then: [Normal] T-RUN-RFL-14: keeps the loop state from line to line within a file'
      _write_file a.txt 'for (const x of xs) {' '  f(x);'
      When call read_file_lines "$_FIXTURE" a.txt _track_loop
      The status should be success
      The output should equal $'[}]\n[}]'
    End
  End
End
