#!/usr/bin/env bash
# skills/bdd-coder/skills/bdd-coder/scripts/__tests__/unit/check-test-abbrs.unit.spec.sh
# @(#) : BDD unit tests for check-test-abbrs.sh
#
# Copyright (c) 2026- atsushifx <https://github.com/atsushifx>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

# shellcheck shell=bash
# shellcheck disable=SC2016

# --- 内部ヘルパー ---

# 定数
# テスト対象。サブプロセスとして実行する
_SCRIPT="${SHELLSPEC_PROJECT_ROOT}/skills/bdd-coder/skills/bdd-coder/scripts/check-test-abbrs.sh"
# usage の出力
_USAGE='Usage: check-test-abbrs.sh [-h|--help]'
# module 宣言の fixture のパス
_P1='docs/.deckrd/a/m/workspaces/module/module.md'
_P2='docs/.deckrd/b/n/workspaces/module/module.md'
_P3='docs/.deckrd/c/o/workspaces/module/module.md'
# 略語表の見出し
_HEADING='## テスト対象の略語'
# 略語 AA の行
_AA_ROW='| `AA` | x |'
# 略語 AA だけの表を持つ宣言の内容
_AA_TABLE="${_HEADING}"$'\n'"${_AA_ROW}"
# 略語 1 件、宣言 1 件の成功出力
_ONE_EACH='OK: 1 abbreviations, 1 declarations'
# 重複エラーの行の先頭
_DUP='Error: duplicate abbreviation'
# P1 の AA が P1 の中で重複するときのエラー出力
_DUP_P1="${_DUP} AA: ${_P1}"
# P1, P2 の閉じていないコードフェンスのエラーの行
_UNCLOSED_P1="Error: ${_P1}: unclosed code fence"
_UNCLOSED_P2="Error: ${_P2}: unclosed code fence"
# 略語が 1 件も無いときのエラー出力
_NONE='Error: no abbreviation found'
# 存在しない宣言の読込エラーの行
_UNREADABLE='Error: docs/.deckrd/a/gone/workspaces/module/module.md: cannot read'
# 存在しない宣言と P2 を一覧する偽の find の行。$1 は find が受け取る docs ディレクトリ
_FIND_WITH_GONE='printf "%s\n" "$1/a/gone/workspaces/module/module.md" "$1/b/n/workspaces/module/module.md"'
# 所有者の違うリポジトリを拒む git のメッセージの 1 行目
_DUBIOUS="fatal: detected dubious ownership in repository at '/r'"
# 壊れたリポジトリを読んだ git のメッセージ
_BROKEN_REPO='fatal: not a git repository: /r/.git/worktrees/w'
# LC_ALL=C のときだけ英語で「リポジトリの外」を返す偽の git の各行
_OUTSIDE_GIT=(
  '[[ ${LC_ALL-} == C ]] && echo "fatal: not a git repository (or any of the parent directories): .git" >&2'
  '[[ ${LC_ALL-} == C ]] || echo "fatal: translated message" >&2'
  'exit 128'
)

# 関数
# git 管理外の空のフィクスチャディレクトリを作り、走査ルートと宣言の場所の上書きを解除する。
# 呼び出し元が指すリポジトリを読まないように git の環境変数も解除する
_setup_fixture() {
  _FIXTURE="$(mktemp -d)"
  unset TEST_ID_CHECK_ROOT MODULE_DOCS_SUBDIR GIT_DIR GIT_WORK_TREE
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

# 内容が空でない宣言だけを P1 から順に作る。$@: P1, P2, P3 の内容
_write_texts() {
  local -a paths=("$_P1" "$_P2" "$_P3")
  local i=0 text
  for text in "$@"; do
    [[ -z $text ]] || _write_file "${paths[i]}" "$text"
    i=$((i + 1))
  done
}

# 略語表を持つ宣言を作る。$1: ルート相対のパス、$2 以降: 略語
_write_decl() {
  local path="$1" abbr
  local -a lines=("$_HEADING")
  shift
  for abbr in "$@"; do
    lines+=("| \`${abbr}\` | x |")
  done
  _write_file "$path" "${lines[@]}"
}

# 引数 1 個につき宣言を 1 つ、P1 から順に作る。$@: 空白区切りの略語
_write_decls() {
  local -a paths=("$_P1" "$_P2" "$_P3") abbrs
  local i=0 arg
  for arg in "$@"; do
    read -r -a abbrs <<<"$arg"
    _write_decl "${paths[i]}" "${abbrs[@]}"
    i=$((i + 1))
  done
}

# AA の表を持つ P1 を作り、末尾に文字列を改行を足さずに続ける。$1: 続ける文字列
_write_aa_followed_by() {
  _write_texts "$_AA_TABLE"
  printf '%s' "$1" >>"${_FIXTURE}/${_P1}"
}

# フィクスチャのルートを cwd にしてチェッカーを実行する。$@: チェッカーの引数
# 引数を渡すのは When run の行だけで、shellcheck は呼び出しと認識しない
# shellcheck disable=SC2120
_run_check() {
  cd "$_FIXTURE" && bash "$_SCRIPT" "$@"
}

# フィクスチャ内に空のサブディレクトリを作り、そこを cwd にしてチェッカーを実行する
_run_check_in_subdir() {
  mkdir -p "${_FIXTURE}/sub" && cd "${_FIXTURE}/sub" && bash "$_SCRIPT"
}

# フィクスチャを git リポジトリにし、サブディレクトリからチェッカーを実行する。
# 所有者を記録しないファイルシステムでは git が dubious ownership で止まるので、
# 利用者の git 設定は変えず、このプロセスにだけ safe.directory を渡す
_run_check_in_git_subdir() {
  git init -q "$_FIXTURE" &&
    GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=safe.directory GIT_CONFIG_VALUE_0='*' _run_check_in_subdir
}

# TEST_ID_CHECK_ROOT にフィクスチャを指定し、サブディレクトリからチェッカーを実行する
_run_check_with_root() {
  TEST_ID_CHECK_ROOT="$_FIXTURE" _run_check_in_subdir
}

# MODULE_DOCS_SUBDIR を meta にしてチェッカーを実行する
_run_check_with_docs_subdir() {
  MODULE_DOCS_SUBDIR=meta _run_check
}

# フィクスチャの .bin/ にコマンドを作る。$1: コマンド名、$2 以降: bash スクリプトの各行
_write_command() {
  local name="$1"
  shift
  _write_file ".bin/${name}" "#!${BASH}" "$@"
  chmod +x "${_FIXTURE}/.bin/${name}"
}

# 偽の git を PATH の先頭に置いてサブディレクトリからチェッカーを実行する。
# $@: 偽の git の bash スクリプトの各行
_run_check_in_subdir_with_git() {
  _write_command git "$@"
  PATH="${_FIXTURE}/.bin:${PATH}" _run_check_in_subdir
}

# git が終了コード 128 で失敗する状態でチェッカーを実行する。$1: git の stderr
_run_check_with_failing_git() {
  _FAKE_GIT_STDERR="$1" _run_check_in_subdir_with_git 'printf "%s\n" "$_FAKE_GIT_STDERR" >&2' 'exit 128'
}

# LC_ALL を解除し、git がリポジトリの外と答える状態でチェッカーを実行する
_run_check_outside_git() {
  unset LC_ALL
  _run_check_in_subdir_with_git "${_OUTSIDE_GIT[@]}"
}

# git が無い PATH でサブディレクトリからチェッカーを実行する。
# .bin/ にはチェッカーが使うコマンドを呼ぶスクリプトだけを置く
_run_check_without_git() {
  local name
  for name in find sort; do
    _write_command "$name" "exec '$(command -v "$name")' \"\$@\""
  done
  cd "${_FIXTURE}/sub" && PATH="${_FIXTURE}/.bin" "$BASH" "$_SCRIPT"
}

# 偽の find を PATH の先頭に置いてチェッカーを実行する。$1: 偽の find の本体
_run_check_with_find() {
  _write_command find "$1"
  PATH="${_FIXTURE}/.bin:${PATH}" _run_check
}

# --- テスト本体 ---

# 略語の重複検査。表の読み取り、コードフェンス、重複と読み取り失敗の報告
Describe 'T-ABR-ABCK: check_abbrs()'
  BeforeEach '_setup_fixture'
  AfterEach '_teardown_fixture'

  Describe 'When: 正常系'
    Describe 'the table of a declaration'
      # 枝番、説明、略語の件数、宣言の件数、P1 の内容、P2 の内容
      Parameters
        '01' 'a declaration without a table' 1 2 "$_AA_TABLE" '## 概要'
        '02' 'only the first column' 2 1 "${_HEADING}"$'\n| `AA` | `main` |\n| `BB` | `main` |'
        '03' 'a heading with a trailing tab' 1 1 "${_HEADING}"$'\t\n'"$_AA_ROW"
        '04' 'a CRLF declaration' 1 1 "${_HEADING}"$'\r\n'"${_AA_ROW}"$'\r'
        '05' 'no heading with trailing text' 1 2 "${_HEADING} (旧)"$'\n'"$_AA_ROW" "$_AA_TABLE"
      End

      It "Then: [Normal] T-ABR-ABCK-01-$1: reads $2"
        _write_texts "${@:5}"
        When run _run_check
        The status should be success
        The output should equal "OK: $3 abbreviations, $4 declarations"
      End
    End

    Describe 'lines after the table that are not read'
      # 枝番、説明、AA の表に続ける行。続く AA の行を読むと重複エラーになる
      Parameters
        '01' 'a row after a heading with a tab' $'\n##\t別の表\n| `AA` | x |'
        '02' 'a row in a fence with a language name' $'```markdown\n| `AA` | x |\n```'
        '03' 'a row in an indented fence' $'  ```\n| `AA` | x |\n  ```'
        '04' 'a row after a tilde line in a backtick fence' $'```\n~~~\n| `AA` | x |\n```'
        '05' 'a row in a tilde fence opened with backquotes' $'~~~ `x`\n| `AA` | x |\n~~~'
        '06' 'a row after a level one heading' $'# 別の章\n| `AA` | x |'
        '07' 'backquotes outside the first column' '| x | `AA` |'
      End

      It "Then: [Normal] T-ABR-ABCK-02-$1: ignores $2"
        _write_aa_followed_by "$3"
        When run _run_check
        The status should be success
        The output should equal "$_ONE_EACH"
      End
    End

    It 'Then: [Normal] T-ABR-ABCK-11: ignores a markdown file that is not a declaration'
      _write_decls AA
      _write_decl docs/.deckrd/a/m/module.md AA
      When run _run_check
      The status should be success
      The output should equal "$_ONE_EACH"
    End
  End

  Describe 'When: 異常系'
    Describe 'a duplicate'
      # 枝番、説明、期待するエラー出力、宣言ごとの略語
      Parameters
        '01' 'in one table' "$_DUP_P1" 'AA AA'
        '02' 'in three declarations, in one line' "${_DUP} AA: ${_P1}, ${_P2}, ${_P3}" AA AA AA
      End

      It "Then: [Error] T-ABR-ABCK-03-$1: reports a duplicate $2"
        _write_decls "${@:4}"
        When run _run_check
        The status should be failure
        The output should equal ''
        The stderr should equal "$3"
      End
    End

    It 'Then: [Error] T-ABR-ABCK-04: reports every duplicate'
      _write_decls 'AA BB' 'AA BB'
      When run _run_check
      The status should be failure
      The output should equal ''
      The lines of stderr should equal 2
      The stderr should include "${_DUP} AA: ${_P1}, ${_P2}"
      The stderr should include "${_DUP} BB: ${_P1}, ${_P2}"
    End

    Describe 'an unclosed code fence'
      # 枝番、説明、期待するエラー出力 (全行)、宣言ごとの内容
      Parameters
        '01' 'that hides the table, and nothing else' "$_UNCLOSED_P1" "${_HEADING}"$'\n```\n'"$_AA_ROW"
        '02' 'in every declaration' "${_UNCLOSED_P1}"$'\n'"${_UNCLOSED_P2}" "${_AA_TABLE}"$'\n```' $'~~~'
      End

      It "Then: [Error] T-ABR-ABCK-05-$1: reports an unclosed fence $2"
        _write_texts "${@:4}"
        When run _run_check
        The status should be failure
        The output should equal ''
        The stderr should equal "$3"
      End
    End

    It 'Then: [Error] T-ABR-ABCK-06: fails without the docs directory'
      When run _run_check
      The status should be failure
      The output should equal ''
      The stderr should equal "$_NONE"
    End

    It 'Then: [Error] T-ABR-ABCK-07: reports a failed listing'
      _write_decls AA
      When run _run_check_with_find 'exit 2'
      The status should be failure
      The output should equal ''
      The stderr should equal 'Error: cannot list the module declarations under docs/.deckrd'
    End

    It 'Then: [Error] T-ABR-ABCK-08: fails for an unreadable declaration'
      _write_texts '' "$_AA_TABLE"
      When run _run_check_with_find "$_FIND_WITH_GONE"
      The status should be failure
      The output should equal ''
      The stderr should include "$_UNREADABLE"
    End

    It 'Then: [Error] T-ABR-ABCK-09: reports the duplicates after an unreadable declaration'
      _write_texts '' "${_AA_TABLE}"$'\n'"$_AA_ROW"
      When run _run_check_with_find "$_FIND_WITH_GONE"
      The status should be failure
      The output should equal ''
      The stderr should include "$_UNREADABLE"
      The stderr should include "${_DUP} AA: ${_P2}"
    End
  End

  Describe 'When: エッジケース'
    # 枝番、説明、AA の表に続ける文字列。続く AA の行を読んで重複エラーになる
    Parameters
      '01' 'after a line starting with # without a blank' $'#123 note\n| `AA` | x |'
      '02' 'after a # comment in a fence' $'```\n# comment\n```\n| `AA` | x |'
      '03' 'after a line of inline code' $'```x```\n| `AA` | x |'
      '04' 'after a block closed by a line of inline code' $'```\n```x```\n| `AA` | x |'
      '05' 'after a backquote apart from the fence' $'``` a`b\n| `AA` | x |'
    End

    It "Then: [Edge] T-ABR-ABCK-10-$1: reads a row $2"
      _write_aa_followed_by "$3"
      When run _run_check
      The status should be failure
      The output should equal ''
      The stderr should equal "$_DUP_P1"
    End
  End
End

# コマンドラインと走査ルート
Describe 'T-ABR-ABMN: main()'
  BeforeEach '_setup_fixture'
  AfterEach '_teardown_fixture'

  Describe 'When: 正常系'
    Describe 'usage'
      Parameters
        '01' -h
        '02' --help
      End

      It "Then: [Normal] T-ABR-ABMN-01-$1: $2 prints the usage"
        When run _run_check "$2"
        The status should be success
        The output should equal "$_USAGE"
        The stderr should equal ''
      End
    End

    Describe 'the current directory as the scan root'
      # 枝番、説明、実行する関数
      Parameters
        '01' 'outside git, whatever the locale' _run_check_outside_git
        '02' 'without git' _run_check_without_git
      End

      It "Then: [Normal] T-ABR-ABMN-05-$1: scans it $2"
        _write_decl "sub/${_P1}" AA
        When run "$3"
        The status should be success
        The output should equal "$_ONE_EACH"
        The stderr should equal ''
      End
    End

    Describe 'the scan root'
      # 枝番、説明、実行する関数、宣言のパス
      Parameters
        '01' 'the git toplevel from a subdirectory' _run_check_in_git_subdir "$_P1"
        '02' 'TEST_ID_CHECK_ROOT' _run_check_with_root "$_P1"
        '03' 'MODULE_DOCS_SUBDIR' _run_check_with_docs_subdir meta/a/m/workspaces/module/module.md
      End

      It "Then: [Normal] T-ABR-ABMN-02-$1: reads the declarations under $2"
        _write_decl "$4" AA
        When run "$3"
        The status should be success
        The output should equal "$_ONE_EACH"
      End
    End
  End

  Describe 'When: 異常系'
    It 'Then: [Error] T-ABR-ABMN-03: rejects an argument and runs no check'
      _write_decls 'AA AA'
      When run _run_check extra
      The status should be failure
      The output should equal ''
      The stderr should equal 'Error: Unexpected argument: extra'
    End

    Describe 'a git failure'
      # sub の宣言は検査に通るので、sub を走査すると成功する
      BeforeEach '_write_decl "sub/${_P1}" AA'

      # 枝番、説明、git の stderr、その 1 行目
      Parameters
        '01' 'dubious ownership, with its first line only' "${_DUBIOUS}"$'\nTo add an exception, call:' "$_DUBIOUS"
        '02' 'a broken repository' "$_BROKEN_REPO" "$_BROKEN_REPO"
      End

      It "Then: [Error] T-ABR-ABMN-04-$1: runs no check and reports $2"
        When run _run_check_with_failing_git "$3"
        The status should equal 1
        The output should equal ''
        The stderr should equal "Error: cannot find the git toplevel: $4"
      End
    End
  End
End
