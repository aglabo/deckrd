#!/usr/bin/env bash
# runners/__tests__/unit/run-shellcheck.spec.sh
# @(#) : BDD unit tests for run-shellcheck.sh
#
# Copyright (c) 2026- atsushifx <https://github.com/atsushifx>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT
# shellcheck shell=bash

# --- テスト対象 ---
# run-shellcheck.sh はファイルスコープで `cd` するため、取り込み後の cwd はリポジトリルートになる。
# この spec では相対パスを使わず、フィクスチャも対象もすべて絶対パスで渡す
Include "${SHELLSPEC_PROJECT_ROOT}/runners/run-shellcheck.sh"

# --- 内部ヘルパー ---

# 定数

# 除外名と無関係なディレクトリに置く、列挙されるべき通常のファイル (T-RUN-FSF-01)
_NORMAL_FILE='src/a.sh'

# 除外リストの名前を持つディレクトリ配下に置く、列挙されてはならないファイル (T-RUN-FSF-02 の入力表)。
# 語の順に、既存の振る舞いである .tools / 最上位の node_modules / 入れ子の node_modules を守る
%const _FSF_EXCLUDED_FILES: .tools/t.sh node_modules/p/y.sh pkg/node_modules/p/z.sh

# ディレクトリ名が除外名を含むだけで一致はしない場所に置く、列挙されるべきファイル (T-RUN-FSF-03)
_LOOKALIKE_FILE='my_node_modules_backup/w.sh'

# 除外名そのものを名前に持つ、走査の起点にするディレクトリ (T-RUN-FSF-04)
_EXCLUDED_START_DIR='.tools'

# 起点 _EXCLUDED_START_DIR の直下にあり、列挙されるべきファイル (T-RUN-FSF-04)
_START_DIR_FILE="${_EXCLUDED_START_DIR}/t.sh"

# 起点 _EXCLUDED_START_DIR より下の除外ディレクトリ配下にあり、列挙されてはならないファイル (T-RUN-FSF-05)
_START_DIR_NESTED_FILE="${_EXCLUDED_START_DIR}/node_modules/p/y.sh"

# main のテストで node_modules 配下に置くファイル (T-RUN-MSC-01 のツリー、T-RUN-MSC-02 の対象)
_NODE_MODULES_FILE='node_modules/p/y.sh'

# 関数

#
# @description 一時ディレクトリに空の .sh ファイルからなるツリーを作る。
#              実リポジトリのツリーには触れない
# @arg $@ string ツリーのルートからの相対パス (1 個以上)。親ディレクトリも作る
# @return 0 when the tree is ready
# @sideeffect Sets _TREE_ROOT to the absolute path of the temporary root
#
_setup_shell_tree() {
  _TREE_ROOT="$(mktemp -d)"
  local rel
  for rel in "$@"; do
    mkdir -p "${_TREE_ROOT}/$(dirname "$rel")"
    touch "${_TREE_ROOT}/${rel}"
  done
}

#
# @description T-RUN-FSF の全ケースが共有するツリーを作る。
#              走査の起点を変えるケースも同じツリーを使い、
#              各ケースはこのうち 1 個のパスだけを照合する
# @arg none
# @return 0 when the tree is ready
# @sideeffect Sets _TREE_ROOT (via _setup_shell_tree)
#
_setup_fsf_tree() {
  # shellcheck disable=SC2086 # %const の語リストを 1 ファイルずつに単語分割する
  _setup_shell_tree "$_NORMAL_FILE" $_FSF_EXCLUDED_FILES "$_LOOKALIKE_FILE" \
    "$_START_DIR_FILE" "$_START_DIR_NESTED_FILE"
}

#
# @description _setup_shell_tree() が作った一時ツリーを削除する
# @arg none
# @return 0 always
# @sideeffect Deletes _TREE_ROOT (only when it is under /tmp) and unsets it
#
_teardown_shell_tree() {
  [[ -n "${_TREE_ROOT:-}" && "$_TREE_ROOT" == /tmp/* ]] && rm -rf "$_TREE_ROOT"
  unset _TREE_ROOT
}

#
# @description find_shell_files の NUL 終端の出力を、1 行 1 パス・安定した順序に直す。
#              pipefail の下で呼ばれるので、find_shell_files の失敗は終了コードに現れる
# @arg $1 string 走査するディレクトリ (絶対パス)
# @stdout 見つかったファイルのパス (1 行 1 件、ソート済み)
# @return 0 when find_shell_files succeeded
#
_list_shell_files() {
  find_shell_files "$1" | tr '\0' '\n' | sort
}

#
# @description 実物の shellcheck をシェル関数のモックに差し替える。
#              main のサブシェルにも引き継がれるので、main の標準出力が
#              モックの受け取った引数列そのものになる
# @arg none
# @stdout (モック呼び出し時) 受け取った全引数を [引数] の形で連結したもの。改行なし
# @return 0 always (モックも常に 0 を返す)
# @sideeffect Defines the shell function shellcheck
#
_setup_shellcheck_mock() {
  # shellcheck disable=SC2329 # main() から間接的に呼ばれる
  shellcheck() {
    printf '[%s]' "$@"
  }
}

#
# @description _setup_shellcheck_mock() が定義したモックを取り除く
# @arg none
# @return 0 always
# @sideeffect Unsets the shell function shellcheck
#
_teardown_shellcheck_mock() {
  unset -f shellcheck
}

# --- テスト本体 ---

#
# run-shellcheck.sh: shellcheck に渡す .sh ファイルを集めて実行するランナー
#
Describe 'run-shellcheck.sh'
  #
  # find_shell_files: ディレクトリ配下の .sh を NUL 終端で列挙する。
  # 名前が除外リストに一致するディレクトリは、起点より下なら深さを問わず走査しない。
  # 起点そのものは、名前が一致しても走査する
  #
  Describe 'T-RUN-FSF: find_shell_files()'
    Before '_setup_fsf_tree'
    After '_teardown_shell_tree'

    Describe 'When: 正常系'
      It 'Then: [Normal] T-RUN-FSF-01: 除外名を持たないディレクトリ配下の .sh を列挙する'
        When call _list_shell_files "$_TREE_ROOT"
        The output should include "${_TREE_ROOT}/${_NORMAL_FILE}"
        The status should be success
      End

      # shellcheck disable=SC2086 # %const の表を 1 ケースずつに単語分割する
      Parameters:value $_FSF_EXCLUDED_FILES

      It "Then: [Normal] T-RUN-FSF-02: 除外ディレクトリ配下の $1 を列挙しない"
        When call _list_shell_files "$_TREE_ROOT"
        The output should not include "${_TREE_ROOT}/$1"
        The status should be success
      End
    End

    # 除外の境界。除外名に似ているだけの名前と、走査の起点そのものには除外が効かない
    Describe 'When: エッジケース'
      # 対照ケース。除外名の部分一致で prune すると RED になる
      It 'Then: [Edge] T-RUN-FSF-03: 名前が除外名を含むだけのディレクトリ配下は列挙する'
        When call _list_shell_files "$_TREE_ROOT"
        The output should include "${_TREE_ROOT}/${_LOOKALIKE_FILE}"
        The status should be success
      End

      # 起点にも -name が適用されると、起点ごと prune されて RED になる
      It 'Then: [Edge] T-RUN-FSF-04: 起点が除外名のディレクトリでも、その直下の .sh を列挙する'
        When call _list_shell_files "${_TREE_ROOT}/${_EXCLUDED_START_DIR}"
        The output should include "${_TREE_ROOT}/${_START_DIR_FILE}"
        The status should be success
      End

      # 起点が除外名のときに除外そのものをやめると RED になる
      It 'Then: [Edge] T-RUN-FSF-05: 起点が除外名のディレクトリでも、配下の除外ディレクトリは列挙しない'
        When call _list_shell_files "${_TREE_ROOT}/${_EXCLUDED_START_DIR}"
        The output should not include "${_TREE_ROOT}/${_START_DIR_NESTED_FILE}"
        The status should be success
      End
    End
  End

  #
  # main: 対象を shellcheck に渡すファイル列へ展開して 1 回だけ実行する。
  # ディレクトリ対象は find_shell_files で列挙し、ファイル対象はそのまま渡す。
  # 実物の shellcheck はモックに差し替え、受け取った引数列を標準出力で観測する
  #
  Describe 'T-RUN-MSC: main()'
    Before '_setup_shellcheck_mock'
    After '_teardown_shellcheck_mock' '_teardown_shell_tree'

    Describe 'When: 正常系'
      It 'Then: [Normal] T-RUN-MSC-01: ディレクトリ対象では node_modules 配下を除いたファイルだけを渡す'
        _setup_shell_tree "$_NORMAL_FILE" "$_NODE_MODULES_FILE"
        When call main "$_TREE_ROOT"
        The output should equal "[--rcfile=${SHELLCHECKRC}][${_TREE_ROOT}/${_NORMAL_FILE}]"
        The status should be success
      End
    End

    # 除外リストはディレクトリ走査にだけ効き、明示したファイルには効かない
    Describe 'When: エッジケース'
      It 'Then: [Edge] T-RUN-MSC-02: ファイル対象は node_modules 配下でもそのまま渡す'
        _setup_shell_tree "$_NODE_MODULES_FILE"
        When call main "${_TREE_ROOT}/${_NODE_MODULES_FILE}"
        The output should equal "[--rcfile=${SHELLCHECKRC}][${_TREE_ROOT}/${_NODE_MODULES_FILE}]"
        The status should be success
      End
    End
  End
End
