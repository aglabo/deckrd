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

# タイトルを順に読み、最後の結果を ID|種類|yes の形で出力する。yes は書かれた ID が - で終わるときだけ。$@: タイトル
_parse_trailing_hyphen() {
  _parse_titles "$@" >/dev/null || return 1
  echo "${_ID}|${_ID_KIND}|${_ID_TRAILING_HYPHEN:+yes}"
}

# 1 手順を実行する。loop_block_reset は関数を呼び、それ以外は行として track_loop_block へ渡す。$1: 手順、$2: 行コメント記号 (省略可)
_feed_loop_step() {
  if [[ $1 == loop_block_reset ]]; then loop_block_reset; else track_loop_block "$@"; fi
}

# 手順を順に _feed_loop_step へ渡し、最後の状態を in (ループ内) か out で出力する。$1: 行コメント記号 (空なら引数を省く)、$2 以降: 手順。戻り値: 手順が失敗したら 1
_track_marked_lines() {
  local marker="$1" line
  shift
  for line in "$@"; do
    _feed_loop_step "$line" ${marker:+"$marker"} || return 1
  done
  if [[ -n $_IN_LOOP ]]; then echo in; else echo out; fi
}

# 行コメント記号なしで _track_marked_lines を呼ぶ。$@: 手順
_track_lines() {
  _track_marked_lines '' "$@"
}

# set -u の新しい bash でライブラリを読み込み、手順を順に _feed_loop_step へ渡して、最後の状態を [<_IN_LOOP>] で出力する。読み込みの後に自動の reset はしない。$@: 手順
_track_lines_fresh() {
  bash -u -c "$(declare -f _feed_loop_step)"'
    . "$1" || exit 1
    shift
    for step in "$@"; do _feed_loop_step "$step" || exit 1; done
    echo "[$_IN_LOOP]"' _ "$_LIBRARY" "$@"
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

  Describe 'When: 末尾の - の判定'
    # 枝番、分類、説明、期待する ID|種類|yes、順に読むタイトル
    Parameters
      '01' 'Normal' 'an ID followed by a variable' 'T-A-B-01|case|yes' 'T-A-B-01-$branch'
      '02' 'Normal' 'a branch number followed by a variable' 'T-A-B-01-02|case|yes' 'T-A-B-01-02-${x}'
      '03' 'Normal' 'a hyphen followed by a colon' 'T-A-B-01|case|yes' 'T-A-B-01-: title'
      '04' 'Normal' 'a case ID alone' 'T-A-B-01|case|' 'T-A-B-01'
      '05' 'Normal' 'a case ID with a branch number' 'T-A-B-01-01|case|' 'T-A-B-01-01'
      '06' 'Normal' 'a hyphen and a variable only after the ID' 'T-A-B-01|case|' 'T-A-B-01: x-${y}'
      '07' 'Error' 'an empty title' '||' ''
      '08' 'Edge' 'a title that ends with a hyphen' 'T-A-B-01|case|yes' 'T-A-B-01-'
      '09' 'Edge' 'a hyphen only on the second ID' 'T-A-B-01|case|' 'T-A-B-01 T-A-B-02-$x'
      '10' 'Edge' 'a title without an ID after one with a trailing hyphen' '||' 'T-A-B-01-$x' 'sample'
    End

    It "Then: [$2] T-RUN-TIP-03-$1: judges $3"
      When call _parse_trailing_hyphen "${@:5}"
      The status should be success
      The output should equal "$4"
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

# test-id.lib.sh の track_loop_block。行を順に読み、for ブロックの内外を追跡する
Describe 'T-RUN-TLB: track_loop_block'
  Describe 'When: 正常系'
    # 枝番、説明、期待する状態、順に読む行
    Parameters
      '01' 'a body line of a block' 'in' 'for (const x of xs) {' '  f(x);'
      '02' 'the closing brace of a block' 'out' 'for (const x of xs) {' '  f(x);' '}' 'g();'
      '03' 'a for await line' 'in' 'for await (const x of xs) {' '  f(x);'
      '04' 'a Dart await for line' 'in' 'await for (final x in xs) {' '  f(x);'
      '05' 'a for line indented with a tab and spaces' 'in' $'\t  for (const x of xs) {' $'\t    f(x);'
      '06' 'a closing brace at the indentation of the for line' 'out' $'\t  for (const x of xs) {' $'\t    f(x);' $'\t  }'
      '07' 'the last line of a multi-line header' 'in' 'for (final c in [' '  1,' '  2,' ']) {' '  f(c);'
      '08' 'the closing brace of a multi-line header block' 'out' '  for (final c in [' '    1,' '  ]) {' '    f(c);' '  }'
      '09' 'a C-style header closed on a deeper line (known limit)' 'out' 'for (let i = 0;' '    i < n;' '    i++) {' '  f(i);'
    End

    It "Then: [Normal] T-RUN-TLB-01-$1: is $3 of a loop after $2"
      When call _track_lines "${@:4}"
      The status should be success
      The output should equal "$3"
    End
  End

  Describe 'When: 入れ子と連続するループ'
    # 枝番、説明、期待する状態、順に読む行
    Parameters
      '01' 'the end of an inner block' 'in' 'for (const x of xs) {' '  for (const y of ys) {' '    f(y);' '  }' '  g(x);'
      '02' 'the ends of both nested blocks' 'out' 'for (const x of xs) {' '  for (const y of ys) {' '  }' '}'
      '03' 'a for line that follows a closed block' 'in' 'for (const x of xs) {' '}' 'for (const y of ys) {' '  f(y);'
      '04' 'two sequential blocks' 'out' 'for (const x of xs) {' '}' 'for (const y of ys) {' '}' 'g();'
    End

    It "Then: [Normal] T-RUN-TLB-02-$1: is $3 of a loop after $2"
      When call _track_lines "${@:4}"
      The status should be success
      The output should equal "$3"
    End
  End

  Describe 'When: 異常系'
    # 枝番、説明、期待する状態、順に読む行
    Parameters
      '01' 'a for loop closed on one line' 'out' 'for (const x of xs) { f(x); }' 'g();'
      '02' 'a for loop without a brace' 'out' 'for (const x of xs) f(x);' 'g();'
      '03' 'a for loop without a brace and its body line' 'out' 'for (const x of xs)' '  f(x);'
      '04' 'a multi-line header without a brace' 'out' 'for (const x of [' '  1,' ']) f(x);' 'g();'
      '05' 'a call of format' 'out' 'format(x, {' '  a: 1,'
      '06' 'a call of forEach' 'out' 'forEach(xs, (x) => {' '  f(x);'
      '07' 'a for that does not start its line' 'out' '// for (const x of xs) {' 'g();'
    End

    It "Then: [Error] T-RUN-TLB-03-$1: is $3 of a loop after $2"
      When call _track_lines "${@:4}"
      The status should be success
      The output should equal "$3"
    End
  End

  Describe 'When: エッジケース'
    # 枝番、説明、期待する状態、順に読む行
    Parameters
      '01' 'a closing brace indented deeper than the for line' 'in' 'for (const x of xs) {' '  if (x) {' '  }' '  f(x);'
      '02' 'a closing brace indented with other blanks of the same width' 'in' $'\tfor (const x of xs) {' ' }'
      '03' 'a closing brace followed by other text' 'out' 'for (const x of xs) {' '} // end'
      '04' 'a deeper closing brace in a multi-line header' 'in' 'for (final c in [' '  {' '    1,' '  },' ']) {' '  f(c);'
      '05' 'an empty line in a block' 'in' 'for (const x of xs) {' ''
      '06' 'a for without a brace inside a block' 'out' 'for (const x of xs) {' '  for (const y of ys)' '    f(y);' '}'
      '07' 'a for closed on one line inside a block' 'in' 'for (const x of xs) {' '  for (const y of ys) { f(y); }' '  g(x);'
      '08' 'a CRLF for line' 'in' $'for (const x of xs) {\r' $'  f(x);\r'
      '09' 'a CRLF closing brace' 'out' $'for (const x of xs) {\r' $'}\r' $'g();\r'
      '10' 'a CRLF for loop without a brace' 'out' $'for (const x of xs)\r' $'  f(x);\r'
      '11' 'a destructuring header that opens a block at the for indentation' 'in' 'for (const {' '  a,' '} of rows) {' '  f(a);'
    End

    It "Then: [Edge] T-RUN-TLB-04-$1: is $3 of a loop after $2"
      When call _track_lines "${@:4}"
      The status should be success
      The output should equal "$3"
    End
  End

  Describe 'When: 行コメント記号を指定する'
    # 枝番、説明、期待する状態、行コメント記号 (空は指定なし)、順に読む行
    Parameters
      '01' 'a comment that follows the opening brace' 'in' '//' 'for (const x of xs) { // each' '  f(x);'
      '02' 'a comment without a marker' 'out' '' 'for (const x of xs) { // each' '  f(x);'
      '03' 'a comment with a parenthesis right after the brace' 'in' '//' 'for (const x of xs) {// see (a' '  f(x);'
      '04' 'a comment at the end of a multi-line header' 'in' '//' 'for (final c in [' '  1,' ']) { // rows' '  f(c);'
      '05' 'a comment after a block closed on one line' 'out' '//' 'for (const x of xs) { f(x); } // done' 'g();'
      '06' 'a marker in a URL' 'in' '//' "for (const u of ['http://x']) {" '  f(u);'
      '07' 'a comment with the marker #' 'in' '#' 'for (x) { # note' '  f(x);'
      '08' 'a comment on a CRLF line' 'in' '//' $'for (const x of xs) { // each\r' $'  f(x);\r'
      '09' 'a comment that ends with a brace after a for without a brace' 'out' '//' 'for (const x of xs) f(x); // builds {' 'g();'
      '10' 'a comment that ends with a brace after an empty block' 'out' '//' 'for (const x of xs) {} // noop {' 'g();'
      '11' 'a comment that ends with a brace after the end of a block' 'out' '//' 'for (const x of xs) {' '} // end of {' 'g();'
      '12' 'a second // in a URL' 'in' '//' "for (const u of ['http://a.com//p']) {" '  f(u);'
      '13' 'a comment that follows a URL' 'out' '//' "for (const u of ['https://a.com']) f(u); // old {" 'g();'
      '14' 'a file:/// URL and a comment' 'in' '//' "for (const u of ['file:///tmp']) { // each" '  f(u);'
      '15' 'a marker in a string that is not a URL (known limit)' 'out' '//' "for (const s of ['a // b']) {" '  f(s);'
      '16' 'a comment-only line in a pending header' 'in' '//' 'for (final c in [' '  // see {' '  1,' ']) {' '  f(c);'
      '17' 'a shallower line in a pending header' 'out' '//' '  for (const x of xs)' '}' '  ) {'
    End

    It "Then: [Normal] T-RUN-TLB-05-$1: is $3 of a loop after $2"
      When call _track_marked_lines "${@:4}"
      The status should be success
      The output should equal "$3"
    End
  End

  Describe 'When: set -u で読み込み直後'
    # 枝番、説明、順に読む行
    Parameters
      '01' 'no line'
      '02' 'a closing brace outside any block' '}'
      '03' 'an extra closing brace after all blocks are closed' 'for (const x of xs) {' '}' '}'
    End

    It "Then: [Edge] T-RUN-TLB-06-$1: is out of a loop after $2, under set -u"
      When call _track_lines_fresh "${@:3}"
      The status should be success
      The output should equal '[]'
      The stderr should equal ''
    End
  End

  Describe 'When: for ヘッダの終わりの判定'
    # 枝番、説明、期待する状態、順に読む行
    Parameters
      '01' 'the closing brace of a destructuring header block' 'out' 'for (const {' '  a,' '} of rows) {' '  f(a);' '}' 'g();'
      '02' 'a header with a callback' 'in' 'for (const x of items.map((i) => {' '  return i;' '})) {' '  f(x);'
      '03' 'the closing brace of a block whose header has a callback' 'out' 'for (const x of items.map((i) => {' '  return i;' '})) {' '  f(x);' '}' 'g();'
      '04' 'a multi-line header closed by ") {"' 'in' 'for (' '  let i = 0;' '  i < n;' '  i++' ') {' '  f(i);'
      '05' 'a block that follows a for loop without a brace' 'out' 'for (const x of xs) f(x);' 'if (a) {' '  g();'
      '06' 'a shallower line that follows a for loop without a brace' 'out' '  for (const x of xs)' '    f(x);' '}' 'test((t) => {'
    End

    It "Then: [Normal] T-RUN-TLB-07-$1: is $3 of a loop after $2"
      When call _track_lines "${@:4}"
      The status should be success
      The output should equal "$3"
    End
  End
End

# test-id.lib.sh の loop_block_reset。track_loop_block が持つループの状態を消去する
Describe 'T-RUN-LBR: loop_block_reset'
  Describe 'When: 正常系'
    # 枝番、説明、期待する状態、順に読む行と呼ぶ関数
    Parameters
      '01' 'a reset inside a block' 'out' 'for (const x of xs) {' 'loop_block_reset'
    End

    It "Then: [Normal] T-RUN-LBR-01-$1: is $3 of a loop after $2"
      When call _track_lines "${@:4}"
      The status should be success
      The output should equal "$3"
    End
  End

  Describe 'When: reset の後に行を読む'
    # 枝番、説明、期待する状態、順に読む行と呼ぶ関数
    Parameters
      '01' 'one block that follows a reset in nested loops' 'out' 'for (const x of xs) {' '  for (const y of ys) {' 'loop_block_reset' 'for (const x of xs) {' '}'
      '02' 'a reset in a pending multi-line header' 'out' 'for (final c in [' 'loop_block_reset' ']) {' '  f(c);'
      '03' 'a for line that follows a reset' 'in' 'for (const x of xs) {' 'loop_block_reset' 'for (const x of xs) {' '  f(x);'
    End

    It "Then: [Normal] T-RUN-LBR-02-$1: is $3 of a loop after $2"
      When call _track_lines "${@:4}"
      The status should be success
      The output should equal "$3"
    End
  End

  Describe 'When: 対応するブロックのない終端'
    # 枝番、説明、順に読む行と呼ぶ関数
    Parameters
      '01' 'the closing brace of a block forgotten by a reset' 'for (const x of xs) {' 'loop_block_reset' '}'
    End

    It "Then: [Error] T-RUN-LBR-03-$1: is out of a loop after $2, under set -u"
      When call _track_lines_fresh "${@:3}"
      The status should be success
      The output should equal '[]'
      The stderr should equal ''
    End
  End

  Describe 'When: set -u で読み込み直後'
    # 枝番、説明、順に読む行と呼ぶ関数
    Parameters
      '01' 'a reset before any line' 'loop_block_reset'
    End

    It "Then: [Edge] T-RUN-LBR-04-$1: is out of a loop after $2, under set -u"
      When call _track_lines_fresh "${@:3}"
      The status should be success
      The output should equal '[]'
      The stderr should equal ''
    End
  End
End
