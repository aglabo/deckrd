#!/usr/bin/env bash
# src: ./skills/deckrd/skills/deckrd/scripts/libs/__tests__/unit/glob.lib.unit.spec.sh
# @(#) : ShellSpec tests for glob.lib.sh
#
# Copyright (c) 2026- aglabo <https://github.com/aglabo>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

# shellcheck disable=SC1091

# --- テスト基盤 ---

Include "${SHELLSPEC_SPECFILE%/*}/../spec_helper.sh"

# --- テスト対象 ---

. "${SHELLSPEC_PROJECT_ROOT}/skills/deckrd/skills/deckrd/scripts/libs/glob.lib.sh"

# --- 内部ヘルパー ---

# 定数

# _GLT_RECURSIVE_GLOB - `**` で配下すべてを指す glob。階層をまたぐ一致と不一致の Case で使う
_GLT_RECURSIVE_GLOB='runners/**'

# _GLT_SHALLOW_GLOB - `*` で 1 階層だけを指す glob。`/` を跨がないことを確かめる Case で使う
_GLT_SHALLOW_GLOB='scripts/*.sh'

# _GLT_SUFFIX_GLOB - 拡張子を限定する glob。末尾アンカーとキャッシュの Case で使う
_GLT_SUFFIX_GLOB='runners/*.sh'

# 関数

# _flls_setup - 空の走査 root を例ごとに作る
_flls_setup() {
  _FLLS_ROOT="$(mktemp -d)"
}

_flls_teardown() {
  # root 配下へ cd した例があると、Windows では root を削除できない
  cd "$SHELLSPEC_PROJECT_ROOT" || return 1
  [[ -n ${_FLLS_ROOT:-} && -d $_FLLS_ROOT ]] && rm -rf "$_FLLS_ROOT"
  unset _FLLS_ROOT
}

# _flls_add <path>... - root 配下に空ファイルを置く
_flls_add() {
  local path
  for path in "$@"; do
    mkdir -p "$(dirname "${_FLLS_ROOT}/${path}")"
    : > "${_FLLS_ROOT}/${path}"
  done
}

# _flls_sorted <glob>... - 出力順は不定なので、ソートして比較する
_flls_sorted() {
  file_list_by_globs "$_FLLS_ROOT" "$@" | sort
}

# _flls_hide_rg - `command -v rg` を失敗させて find への切り替えを起こす。
#   rg 自体も失敗させ、切り替えずに rg を呼ぶ実装を通さない
_flls_hide_rg() {
  command() {
    [[ "$1" == '-v' && "$2" == 'rg' ]] && return 1
    builtin command "$@"
  }
  rg() { return 127; }
}
_flls_restore_rg() { unset -f command rg; }

# _flls_rg_missing - rg が無ければ成功する。実際の rg 経路を通す例の Skip 判定に使う
_flls_rg_missing() { ! command -v rg > /dev/null 2>&1; }

# _flls_fail_rg - rg を、一部を出力してから終了コード 2 (列挙の失敗) で終わるスタブにする
_flls_fail_rg() {
  rg() {
    echo 'partial.spec.sh'
    echo 'rg: stub failure' >&2
    return 2
  }
}

# _flls_fail_find - rg を隠し、find を一部を出力してから失敗するスタブにする
_flls_fail_find() {
  _flls_hide_rg
  find() {
    echo './partial.spec.sh'
    echo 'find: stub failure' >&2
    return 1
  }
}
_flls_restore_find() {
  _flls_restore_rg
  unset -f find
}

# _flls_run_errexit <-o|+o> - `set -e` のシェルで空でない glob を指定して呼び出し、
#   呼び出し元が続行できたら 'continued' を出力する。$1 は pipefail の有効・無効
_flls_run_errexit() {
  (
    set -e "$1" pipefail
    file_list_by_globs "$_FLLS_ROOT" '*.spec.sh'
    echo 'continued'
  )
}

# _flls_options_after_failure - 失敗する列挙の前後でシェルオプションを比べ、
#   変わらなければ 'unchanged'、変われば 'changed' を出力する
_flls_options_after_failure() {
  local before after
  before="$(set +o && shopt -p || :)"
  file_list_by_globs "${_FLLS_ROOT}/absent" '*.spec.sh' || :
  after="$(set +o && shopt -p || :)"
  if [[ $before == "$after" ]]; then
    echo 'unchanged'
  else
    echo 'changed'
  fi
}

# --- テスト本体 ---

#
# glob を先頭と末尾にアンカーを持つ ERE に変換する
#
Describe 'T-LIB-GLRE: glob_to_regex()'
  Describe 'When: 正常系'
    It "Then: [Normal] T-LIB-GLRE-01: 単一の * は / を跨がない ERE になる"
      When call glob_to_regex "$_GLT_SHALLOW_GLOB"
      The status should be success
      The output should equal '^scripts/[^/]*[.]sh$'
    End

    It "Then: [Normal] T-LIB-GLRE-02: ** は任意の文字列に一致する ERE になる"
      When call glob_to_regex "$_GLT_RECURSIVE_GLOB"
      The status should be success
      The output should equal '^runners/.*$'
    End
  End

  Describe 'When: エッジケース'
    It "Then: [Edge] T-LIB-GLRE-03: 空の glob は ^$ になる"
      When call glob_to_regex ''
      The status should be success
      The output should equal '^$'
    End
  End
End

#
# パスが glob に一致するかを終了コードで返し、変換結果をキャッシュする
#
Describe 'T-LIB-GLPM: path_matches_glob()'
  Describe 'When: 正常系'
    It "Then: [Normal] T-LIB-GLPM-01-01: ** は深い階層のパスに一致する"
      When call path_matches_glob 'runners/__tests__/unit/a.spec.sh' "$_GLT_RECURSIVE_GLOB"
      The status should be success
    End

    It "Then: [Normal] T-LIB-GLPM-01-02: ** は直下のパスに一致する"
      When call path_matches_glob 'runners/a.spec.sh' "$_GLT_RECURSIVE_GLOB"
      The status should be success
    End

    It "Then: [Normal] T-LIB-GLPM-01-03: * は同じ階層のパスに一致する"
      When call path_matches_glob 'scripts/a.sh' "$_GLT_SHALLOW_GLOB"
      The status should be success
    End
  End

  Describe 'When: 異常系'
    It "Then: [Error] T-LIB-GLPM-03: 空パスは一致しない"
      When call path_matches_glob '' "$_GLT_RECURSIVE_GLOB"
      The status should be failure
    End

    It "Then: [Error] T-LIB-GLPM-02-01: * は / を跨いで一致しない"
      When call path_matches_glob 'scripts/libs/a.sh' "$_GLT_SHALLOW_GLOB"
      The status should be failure
    End

    It "Then: [Error] T-LIB-GLPM-02-02: パスの途中からは一致しない"
      When call path_matches_glob 'other/runners/a.spec.sh' "$_GLT_RECURSIVE_GLOB"
      The status should be failure
    End
  End

  Describe 'When: エッジケース'
    It "Then: [Edge] T-LIB-GLPM-05-01: 末尾に余分な文字があるパスは一致しない"
      When call path_matches_glob 'runners/a.sh.bak' "$_GLT_SUFFIX_GLOB"
      The status should be failure
    End

    It "Then: [Edge] T-LIB-GLPM-05-02: ディレクトリ名の前方一致はしない"
      When call path_matches_glob 'runnersX/a.spec.sh' "$_GLT_RECURSIVE_GLOB"
      The status should be failure
    End

    It "Then: [Edge] T-LIB-GLPM-05-03: . は任意の 1 文字に一致しない"
      When call path_matches_glob 'runners/aXsh' 'runners/a.sh'
      The status should be failure
    End

    # When call は現シェルで実行するので、呼び出しが積んだキャッシュを直後に参照できる
    It "Then: [Edge] T-LIB-GLPM-04: 変換した ERE を現シェルのキャッシュに残す"
      When call path_matches_glob 'runners/a.sh' "$_GLT_SUFFIX_GLOB"
      The status should be success
      The value "${_GLOB_REGEX_CACHE[$_GLT_SUFFIX_GLOB]:-}" should equal '^runners/[^/]*[.]sh$'
    End
  End
End

#
# ファイル名の glob のいずれかに一致するファイルを root 相対パスで列挙する
#
Describe 'T-LIB-FLLS: file_list_by_globs()'
  BeforeEach '_flls_setup'
  AfterEach '_flls_teardown'

  Describe 'When: 正常系'
    It 'Then: [Normal] T-LIB-FLLS-01: 一致するファイルだけを root 相対パスで出力する'
      _flls_add 'alpha/a.spec.sh' 'alpha/helper.sh'
      When call file_list_by_globs "$_FLLS_ROOT" '*.spec.sh'
      The status should be success
      The output should equal 'alpha/a.spec.sh'
    End

    It 'Then: [Normal] T-LIB-FLLS-02: 複数の glob のいずれかに一致するファイルをすべて出力する'
      _flls_add 'alpha/a.spec.sh' 'alpha/b_spec.sh' 'alpha/helper.sh'
      When call _flls_sorted '*.spec.sh' '*_spec.sh'
      The status should be success
      The output should equal "alpha/a.spec.sh"$'\n'"alpha/b_spec.sh"
    End
  End

  Describe 'When: 正常系 (rg が無く find で列挙する)'
    BeforeEach '_flls_hide_rg'
    AfterEach '_flls_restore_rg'

    It 'Then: [Normal] T-LIB-FLLS-03: rg 経路と同じ root 相対パスで出力する'
      _flls_add 'alpha/a.spec.sh' 'alpha/helper.sh'
      When call file_list_by_globs "$_FLLS_ROOT" '*.spec.sh'
      The status should be success
      The output should equal 'alpha/a.spec.sh'
    End
  End

  Describe 'When: 異常系'
    It 'Then: [Error] T-LIB-FLLS-04: 存在しない root は失敗し、cd のエラーを stderr に出す'
      When call file_list_by_globs "${_FLLS_ROOT}/absent" '*.spec.sh'
      The status should be failure
      The output should equal ''
      The stderr should include 'absent'
    End

    It 'Then: [Error] T-LIB-FLLS-11: rg が終了コード 2 なら同じコードで失敗し、原因を stderr に残す'
      _flls_fail_rg
      When call file_list_by_globs "$_FLLS_ROOT" '*.spec.sh'
      The status should equal 2
      The output should equal ''
      The stderr should include 'rg: stub failure'
    End

    It 'Then: [Error] T-LIB-FLLS-05: glob に似ているだけの名前は出力しない'
      _flls_add 'alpha/a.spec.sh.bak'
      When call file_list_by_globs "$_FLLS_ROOT" '*.spec.sh'
      The status should be success
      The output should equal ''
    End

    It 'Then: [Error] T-LIB-FLLS-06: glob を指定しなければ全ファイルを列挙せず何も出力しない'
      _flls_add 'alpha/a.spec.sh'
      When call file_list_by_globs "$_FLLS_ROOT"
      The status should be success
      The output should equal ''
    End
  End

  Describe 'When: 異常系 (set -e の呼び出し元)'
    BeforeEach '_flls_fail_rg'
    AfterEach 'unset -f rg'

    # 1 列目はテストケース ID の分岐、2 列目は pipefail の指定
    Parameters
      '01' '-o'
      '02' '+o'
    End

    It "Then: [Error] T-LIB-FLLS-14-${1}: set ${2} pipefail でも列挙の失敗で呼び出し元が止まる"
      When run _flls_run_errexit "$2"
      The status should equal 2
      The output should equal ''
      The stderr should include 'rg: stub failure'
    End
  End

  Describe 'When: 異常系 (呼び出し元のシェルオプション)'
    It 'Then: [Error] T-LIB-FLLS-15: 列挙が失敗しても呼び出し元のシェルオプションを変えない'
      When call _flls_options_after_failure
      The output should equal 'unchanged'
      The stderr should include 'absent'
    End
  End

  Describe 'When: 異常系 (rg が無く find で列挙する)'
    BeforeEach '_flls_fail_find'
    AfterEach '_flls_restore_find'

    It 'Then: [Error] T-LIB-FLLS-13: find が失敗すれば失敗し、原因を stderr に残す'
      When call file_list_by_globs "$_FLLS_ROOT" '*.spec.sh'
      The status should be failure
      The output should equal ''
      The stderr should include 'find: stub failure'
    End
  End

  Describe 'When: エッジケース'
    Describe 'rg が無く find で列挙する'
      BeforeEach '_flls_hide_rg'
      AfterEach '_flls_restore_rg'

      It 'Then: [Edge] T-LIB-FLLS-07: 隠しディレクトリ配下は出力しない'
        _flls_add '.hidden/c.spec.sh'
        When call file_list_by_globs "$_FLLS_ROOT" '*.spec.sh'
        The status should be success
        The output should equal ''
      End

      It 'Then: [Edge] T-LIB-FLLS-08: node_modules 配下は出力しない'
        _flls_add 'node_modules/d.spec.sh'
        When call file_list_by_globs "$_FLLS_ROOT" '*.spec.sh'
        The status should be success
        The output should equal ''
      End
    End

    It 'Then: [Edge] T-LIB-FLLS-09: ファイルの無い root は何も出力せず成功する'
      When call file_list_by_globs "$_FLLS_ROOT" '*.spec.sh'
      The status should be success
      The output should equal ''
    End

    # 1 列目はテストケース ID の分岐、2 列目は pipefail の指定
    Describe 'set -e の呼び出し元で、一致するファイルが無い (rg の終了コード 1)'
      Parameters
        '01' '-o'
        '02' '+o'
      End

      It "Then: [Edge] T-LIB-FLLS-12-${1}: set ${2} pipefail では空行も出力せず、続行する"
        When call _flls_run_errexit "$2"
        The status should be success
        The entire output should equal 'continued'$'
'
      End
    End

    It 'Then: [Edge] T-LIB-FLLS-16: .gitignore が無くても rg 経路は直下と入れ子の node_modules 配下を出力しない'
      Skip if 'rg is not installed' _flls_rg_missing
      _flls_add 'alpha/a.spec.sh' 'node_modules/d.spec.sh' 'alpha/node_modules/p/e.spec.sh'
      When call file_list_by_globs "$_FLLS_ROOT" '*.spec.sh'
      The status should be success
      The output should equal 'alpha/a.spec.sh'
    End

    It 'Then: [Edge] T-LIB-FLLS-10: glob をカレントディレクトリのファイル名に展開しない'
      _flls_add 'tree/alpha/a.spec.sh' 'cwd/cwd.spec.sh'
      cd "${_FLLS_ROOT}/cwd"
      When call file_list_by_globs "${_FLLS_ROOT}/tree" '*.spec.sh'
      The status should be success
      The output should equal 'alpha/a.spec.sh'
    End
  End
End
