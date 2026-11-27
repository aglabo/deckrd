#!/usr/bin/env bash
# frontmatter.lib.unit.spec.sh - ShellSpec unit tests for frontmatter.lib.sh
#
# Copyright (c) 2026- atsushifx <https://github.com/atsushifx>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

# shellcheck disable=SC1090,SC1091

# --- テスト基盤 ---
Include "${SHELLSPEC_SPECFILE%/*}/../spec_helper.sh"

# --- テスト対象 ---
Include "${SHELLSPEC_PROJECT_ROOT}/skills/deckrd/skills/deckrd/scripts/libs/frontmatter.lib.sh"

# --- 内部ヘルパー ---

# 一時ディレクトリを作り、各ケースが読む文書のパスを _DOC に設定する
_setup_doc() {
  setup_tmpdir
  _DOC="${NAMING_TMPDIR}/module.md"
}

# 引数の行を frontmatter ブロックに包んで _DOC へ書く
# @arg $@ frontmatter の行
_write_frontmatter() {
  printf '%s\n' '---' "$@" '---' > "$_DOC"
}

# test_scope だけを持つ frontmatter を書く
# @arg $1 test_scope の値 (引用符を含めてそのまま書く)
_given_scope() {
  _write_frontmatter "test_scope: $1"
}

# owns に 2 項目を持つ frontmatter を書く
_given_owns() {
  _write_frontmatter 'owns:' '  - src/alpha/**' '  - src/shared/*.sh'
}

# owns の後に tags を持つ frontmatter を書く
_given_owns_and_tags() {
  _write_frontmatter 'owns:' '  - a/**' 'tags:' '  - t1'
}

# owns に短い glob 2 項目を持つ frontmatter を書く
_given_two_globs() {
  _write_frontmatter 'owns:' '  - a/**' '  - b/*.sh'
}

# owns を持たず、別のリストを持つ frontmatter を書く
_given_no_owns() {
  _write_frontmatter 'test_scope: ALP' 'tags:' '  - t1'
}

# 1 行目が見出しで frontmatter を持たない文書を書く
_given_no_frontmatter() {
  printf '%s\n' '# heading' 'test_scope: ALP' > "$_DOC"
}

# 現シェルで 1 回読んでキャッシュに載せた後、文書を削除する
_given_cached_then_removed() {
  _given_scope 'ALP'
  fm_read_scalar "$_DOC" 'test_scope' > /dev/null
  rm -f "$_DOC"
}

# AWK を未設定にし、set -u の下で読む (`When run` のサブシェルで呼ぶ)
# @arg $@ fm_read_scalar の引数
# @stdout fm_read_scalar の出力
_read_scalar_without_awk() {
  unset AWK
  set -u
  fm_read_scalar "$@"
}

# 項目でない行の後にもう 1 つ項目の行が続く frontmatter を書く
_given_interrupted_list() {
  _write_frontmatter 'owns:' '  - a/**' 'title: x' '  - z/**'
}

# 同じ文書の owns を先に読み込んでおく
_given_owns_loaded() {
  _given_owns_and_tags
  fm_load_list "$_DOC" 'owns'
}

# owns の無い frontmatter を書き、前回の出力が残った状態にする
_given_stale_list() {
  _given_no_owns
  _FM_LIST=(stale)
}

# test_scope を書いた文書を、awk が失敗する状態で現シェルで 1 回読み、awk を戻す
_given_scalar_read_failed() {
  _given_scope 'ALP'
  AWK='false' fm_read_scalar "$_DOC" 'test_scope' > /dev/null || true
}

# owns を書いた文書を、awk が失敗する状態で現シェルで 1 回読み、awk を戻す
_given_list_read_failed() {
  _given_two_globs
  AWK='false' fm_read_list "$_DOC" 'owns' > /dev/null || true
}

# --- テスト本体 ---

#
# frontmatter のスカラー値を読む
#
Describe 'T-LIB-FMSC: fm_read_scalar()'
  BeforeEach '_setup_doc'
  AfterEach 'teardown_tmpdir'

  Describe 'When: 正常系'
    It 'Then: [Normal] T-LIB-FMSC-01: 宣言された値を返す'
      _given_scope 'ALP'
      When call fm_read_scalar "$_DOC" 'test_scope'
      The status should be success
      The output should equal 'ALP'
    End

    It 'Then: [Normal] T-LIB-FMSC-02: 対になったダブルクォートを剥がす'
      _given_scope '"DQT"'
      When call fm_read_scalar "$_DOC" 'test_scope'
      The output should equal 'DQT'
    End

    It 'Then: [Normal] T-LIB-FMSC-03: 対になったシングルクォートを剥がす'
      _given_scope "'SQT'"
      When call fm_read_scalar "$_DOC" 'test_scope'
      The output should equal 'SQT'
    End
  End

  Describe 'When: 異常系'
    It 'Then: [Error] T-LIB-FMSC-04: 宣言されていないフィールドには空を返す'
      _given_scope 'ALP'
      When call fm_read_scalar "$_DOC" 'nonexistent'
      The status should be success
      The output should equal ''
    End

    It 'Then: [Error] T-LIB-FMSC-05: 末尾だけの引用符は剥がさない'
      _given_scope 'TRL"'
      When call fm_read_scalar "$_DOC" 'test_scope'
      The output should equal 'TRL"'
    End

    It 'Then: [Error] T-LIB-FMSC-06: 先頭だけの引用符は剥がさない'
      _given_scope '"LED'
      When call fm_read_scalar "$_DOC" 'test_scope'
      The output should equal '"LED'
    End

    It 'Then: [Error] T-LIB-FMSC-07: 種類の違う引用符の組は剥がさない'
      _given_scope "'MIX\""
      When call fm_read_scalar "$_DOC" 'test_scope'
      The output should equal "'MIX\""
    End

    It 'Then: [Error] T-LIB-FMSC-08: 存在しないファイルには空を返す'
      When call fm_read_scalar "${NAMING_TMPDIR}/absent.md" 'test_scope'
      The status should be success
      The output should equal ''
      The stderr should equal ''
    End

    It 'Then: [Error] T-LIB-FMSC-16: awk が失敗すれば何も出力せず失敗する'
      _given_scope 'ALP'
      AWK='false'
      When call fm_read_scalar "$_DOC" 'test_scope'
      The status should be failure
      The output should equal ''
    End

    It 'Then: [Error] T-LIB-FMSC-17: awk が見つからなければ失敗する'
      _given_scope 'ALP'
      AWK="${NAMING_TMPDIR}/no-such-awk"
      When call fm_read_scalar "$_DOC" 'test_scope'
      The status should be failure
      The output should equal ''
      The stderr should include 'no-such-awk'
    End

    It 'Then: [Error] T-LIB-FMSC-18: 失敗した読み取りはキャッシュせず、次の読み取りは値を返す'
      _given_scalar_read_failed
      When call fm_read_scalar "$_DOC" 'test_scope'
      The status should be success
      The output should equal 'ALP'
    End
  End

  Describe 'When: エッジケース'
    It 'Then: [Edge] T-LIB-FMSC-09: 空のダブルクォートペアは剥がさずそのまま返す'
      _given_scope '""'
      When call fm_read_scalar "$_DOC" 'test_scope'
      The output should equal '""'
    End

    It 'Then: [Edge] T-LIB-FMSC-10: 引用符 1 文字はペアではないので剥がさない'
      _given_scope '"'
      When call fm_read_scalar "$_DOC" 'test_scope'
      The output should equal '"'
    End

    It 'Then: [Edge] T-LIB-FMSC-11: 空のシングルクォートペアは剥がさずそのまま返す'
      _given_scope "''"
      When call fm_read_scalar "$_DOC" 'test_scope'
      The output should equal "''"
    End

    It 'Then: [Edge] T-LIB-FMSC-12: 末尾の CR を空白として除去し module.sh のリーダーと同じ値を返す'
      # T-CLI-CDS-15 と対になるケース。CR を行末に置くと Windows の gawk が落とすため、
      # CR の後ろに半角スペースを 1 つ置いて行末を避ける。
      _given_scope "$(printf '"ALP"\r ')"
      When call fm_read_scalar "$_DOC" 'test_scope'
      The output should equal 'ALP'
    End

    It 'Then: [Edge] T-LIB-FMSC-13: 先頭行が区切り線でないファイルは読まない'
      _given_no_frontmatter
      When call fm_read_scalar "$_DOC" 'test_scope'
      The output should equal ''
    End

    It 'Then: [Edge] T-LIB-FMSC-14: 2 回目はキャッシュから返す'
      _given_cached_then_removed
      When call fm_read_scalar "$_DOC" 'test_scope'
      The output should equal 'ALP'
    End

    It 'Then: [Edge] T-LIB-FMSC-15: AWK 未設定かつ set -u でも読める'
      _given_scope 'ALP'
      When run _read_scalar_without_awk "$_DOC" 'test_scope'
      The status should be success
      The output should equal 'ALP'
      The stderr should equal ''
    End
  End
End

#
# frontmatter のブロック形式リストを読む
#
Describe 'T-LIB-FMLS: fm_read_list()'
  BeforeEach '_setup_doc'
  AfterEach 'teardown_tmpdir'

  Describe 'When: 正常系'
    It 'Then: [Normal] T-LIB-FMLS-01: リストを宣言順に返す'
      _given_owns
      When call fm_read_list "$_DOC" 'owns'
      The lines of output should equal 2
      The line 1 of output should equal 'src/alpha/**'
      The line 2 of output should equal 'src/shared/*.sh'
    End

    It 'Then: [Normal] T-LIB-FMLS-02: キー引数で指定したリストだけを返す'
      _given_owns_and_tags
      When call fm_read_list "$_DOC" 'tags'
      The output should equal 't1'
    End
  End

  Describe 'When: 異常系'
    It 'Then: [Error] T-LIB-FMLS-03: 宣言されていないリストキーには空を返す'
      _given_no_owns
      When call fm_read_list "$_DOC" 'owns'
      The status should be success
      The output should equal ''
    End

    It 'Then: [Error] T-LIB-FMLS-06: awk が失敗すれば何も出力せず失敗する'
      _given_two_globs
      AWK='false'
      When call fm_read_list "$_DOC" 'owns'
      The status should be failure
      The output should equal ''
    End

    It 'Then: [Error] T-LIB-FMLS-07: 失敗した読み取りはキャッシュせず、次の読み取りは項目を返す'
      _given_list_read_failed
      When call fm_read_list "$_DOC" 'owns'
      The status should be success
      The lines of output should equal 2
    End
  End

  Describe 'When: エッジケース'
    It 'Then: [Edge] T-LIB-FMLS-04: リストは次の非項目行で終わる'
      _given_interrupted_list
      When call fm_read_list "$_DOC" 'owns'
      The output should equal 'a/**'
    End

    It 'Then: [Edge] T-LIB-FMLS-05: 同じファイルの別キーはキャッシュが衝突しない'
      _given_owns_loaded
      When call fm_read_list "$_DOC" 'tags'
      The output should equal 't1'
    End
  End
End

#
# リストを fork せず出力変数 _FM_LIST に積む
#
Describe 'T-LIB-FMLL: fm_load_list()'
  BeforeEach '_setup_doc'
  AfterEach 'teardown_tmpdir'

  Describe 'When: 正常系'
    It 'Then: [Normal] T-LIB-FMLL-01: リストを _FM_LIST に積み、stdout には出力しない'
      _given_two_globs
      When call fm_load_list "$_DOC" 'owns'
      The output should equal ''
      The value "${#_FM_LIST[@]}" should equal 2
      The value "${_FM_LIST[0]}" should equal 'a/**'
      The value "${_FM_LIST[1]}" should equal 'b/*.sh'
    End
  End

  Describe 'When: 異常系'
    It 'Then: [Error] T-LIB-FMLL-03: awk が失敗すれば _FM_LIST を空にして失敗する'
      _given_two_globs
      _FM_LIST=(stale)
      AWK='false'
      When call fm_load_list "$_DOC" 'owns'
      The status should be failure
      The value "${#_FM_LIST[@]}" should equal 0
    End
  End

  Describe 'When: エッジケース'
    It 'Then: [Edge] T-LIB-FMLL-04: 存在しないファイルは awk を起動せず空のリストで成功する'
      AWK='false'
      When call fm_load_list "${NAMING_TMPDIR}/absent.md" 'owns'
      The status should be success
      The value "${#_FM_LIST[@]}" should equal 0
    End

    It 'Then: [Edge] T-LIB-FMLL-02: 未宣言キーは前回の出力を空にする'
      _given_stale_list
      When call fm_load_list "$_DOC" 'owns'
      The status should be success
      The value "${#_FM_LIST[@]}" should equal 0
    End
  End
End
