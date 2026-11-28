#!/usr/bin/env bash
# skills/bdd-coder/skills/bdd-coder/scripts/__tests__/integration/shared-copies.integration.spec.sh
# @(#) : BDD integration tests for the shared copies bdd-coder takes from deckrd
#
# Copyright (c) 2026- atsushifx <https://github.com/atsushifx>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

# shellcheck shell=bash
# shellcheck disable=SC2016

# --- 内部ヘルパー ---

# 定数
# テスト対象の bdd-coder スキル
_SKILL_DIR="${SHELLSPEC_PROJECT_ROOT}/skills/bdd-coder/skills/bdd-coder"
# コピー元 (正本) の deckrd スキル。T-SHR-SCL の比較で使う
_SOURCE_SKILL_DIR="${SHELLSPEC_PROJECT_ROOT}/skills/deckrd/skills/deckrd"

# 関数
# 空のフィクスチャディレクトリを作り、比較する 2 つのパスを決める。ディレクトリ自体は作らない
_setup_fixture() {
  _FIXTURE="$(mktemp -d)"
  _SRC="${_FIXTURE}/src"
  _DST="${_FIXTURE}/dst"
}

# フィクスチャディレクトリを削除する
_teardown_fixture() {
  rm -rf "$_FIXTURE"
}

# フィクスチャ内にファイルを作る。$1: ルート相対のパス、$2: ファイルの内容
_write_file() {
  local path="${_FIXTURE}/$1"
  mkdir -p "${path%/*}"
  printf '%s\n' "$2" >"$path"
}

# @description 指定したディレクトリすべてに、同じ内容の a.lib.sh を作る
# @arg $@ string フィクスチャのルート相対のディレクトリ
_write_a_lib() {
  local dir
  for dir in "$@"; do
    _write_file "${dir}/a.lib.sh" a
  done
}

# @description コピーが正本と一致するかを調べる。正本側の __tests__ は比較しない。
#   コピーは symlink でない実ディレクトリで、直下に __tests__ を持たないことを前提とする
# @arg $1 string 正本ディレクトリ
# @arg $2 string コピーのディレクトリ (末尾スラッシュなし。付けると symlink を判別できない)
# @stdout 不一致の理由と差分のパス
# @stderr 正本が無いときの diff のエラー
# @exitcode 0 一致
# @exitcode >0 不一致、または比較できない
_compare_copy() {
  local src="$1" dst="$2"
  [[ ! -L $dst ]] || { echo "symlink: ${dst}"; return 1; }
  [[ -d $dst ]] || { echo "not a directory: ${dst}"; return 1; }
  [[ ! -e ${dst}/__tests__ ]] || { echo "unexpected: ${dst}/__tests__"; return 1; }
  diff -r -x __tests__ "$src" "$dst"
}

# @description 実ツリーの共有コピーを、deckrd の同じ位置の正本と比較する
# @arg $1 string スキルディレクトリからの相対パス
# @stdout 不一致の理由と差分のパス
# @stderr 正本が無いときの diff のエラー
# @exitcode 0 一致
# @exitcode >0 不一致、または比較できない
_compare_shared() {
  _compare_copy "${_SOURCE_SKILL_DIR}/$1" "${_SKILL_DIR}/$1"
}

# @description 指定したディレクトリ配下の symlink を列挙する。リンク切れも含む
# @arg $1 string 走査するディレクトリ
# @stdout symlink のパス (1 行 1 件)
# @stderr ディレクトリが無いときの find のエラー
# @exitcode 0 走査できた
# @exitcode >0 走査できない
_list_symlinks() {
  find "$1" -type l
}

# @description bdd-coder だけをフィクスチャ内にコピーする。symlink はたどらずにそのまま写す
_copy_skill() {
  _COPY="${_FIXTURE}/bdd-coder"
  cp -R "$_SKILL_DIR" "$_COPY"
}

# @description コピーした bdd-coder のスクリプトを実行する
# @arg $1 string scripts ディレクトリ直下のスクリプト名
# @arg $@ string スクリプトに渡す引数
_run_copy_script() {
  local script="$1"
  shift
  bash "${_COPY}/scripts/${script}" "$@"
}

# --- テスト本体 ---

# bdd-coder が deckrd からコピーして持つ共有ライブラリと辞書
Describe 'bdd-coder の共有コピー'
  Before '_setup_fixture'
  After '_teardown_fixture'

  # コピーが正本と一致するかを判定する
  Describe 'T-SHR-SCT: _compare_copy'
    Describe 'When: 正常系'
      It '[Normal] T-SHR-SCT-01: 内容が同じ 2 ディレクトリ -> status 0、出力なし'
        _write_a_lib src dst
        When call _compare_copy "$_SRC" "$_DST"
        The status should equal 0
        The output should equal ''
      End

      It '[Normal] T-SHR-SCT-02: 正本側だけの __tests__ -> 無視して status 0、出力なし'
        _write_a_lib src dst
        _write_file src/__tests__/x.spec.sh x
        When call _compare_copy "$_SRC" "$_DST"
        The status should equal 0
        The output should equal ''
      End
    End

    Describe 'When: 異常系'
      Before '_write_a_lib src'

      It '[Error] T-SHR-SCT-03: 内容が違うファイル -> 非 0 で a.lib.sh を出力する'
        _write_file dst/a.lib.sh b
        When call _compare_copy "$_SRC" "$_DST"
        The status should not equal 0
        The output should include 'a.lib.sh'
      End

      It '[Error] T-SHR-SCT-04: コピー側の欠落 -> 非 0 で b.lib.sh を出力する'
        _write_file src/b.lib.sh b
        _write_a_lib dst
        When call _compare_copy "$_SRC" "$_DST"
        The status should not equal 0
        The output should include 'b.lib.sh'
      End

      It '[Error] T-SHR-SCT-05: コピー側の余分なファイル -> 非 0 で c.lib.sh を出力する'
        _write_a_lib dst
        _write_file dst/c.lib.sh c
        When call _compare_copy "$_SRC" "$_DST"
        The status should not equal 0
        The output should include 'c.lib.sh'
      End

      It '[Error] T-SHR-SCT-06: コピー側に __tests__ がある -> 非 0 で __tests__ を出力する'
        _write_a_lib dst
        _write_file src/__tests__/x.spec.sh x
        _write_file dst/__tests__/x.spec.sh x
        When call _compare_copy "$_SRC" "$_DST"
        The status should not equal 0
        The output should include '__tests__'
      End

      It '[Error] T-SHR-SCT-07: コピー先が正本への symlink -> 非 0 でコピー先を出力する'
        ln -s "$_SRC" "$_DST"
        When call _compare_copy "$_SRC" "$_DST"
        The status should not equal 0
        The output should include "$_DST"
      End
    End

    Describe 'When: エッジケース'
      It '[Edge] T-SHR-SCT-08: 正本ディレクトリが無い -> 非 0 で正本のパスを出力する'
        mkdir "$_DST"
        When call _compare_copy "$_SRC" "$_DST"
        The status should not equal 0
        The stderr should include "$_SRC"
      End

      It '[Edge] T-SHR-SCT-09: コピー先がテキストファイル -> 非 0 でコピー先を出力する'
        _write_a_lib src
        _write_file dst ../src/
        When call _compare_copy "$_SRC" "$_DST"
        The status should not equal 0
        The output should include "$_DST"
      End
    End
  End

  # bdd-coder の共有コピーが symlink でない実体として置かれているかを確認する
  Describe 'T-SHR-SCL: bdd-coder の共有コピーの配置'
    Describe 'When: 正常系'
      It '[Normal] T-SHR-SCL-03: bdd-coder の実ツリー -> symlink が無く status 0、出力なし'
        When call _list_symlinks "$_SKILL_DIR"
        The status should equal 0
        The output should equal ''
      End

      It '[Normal] T-SHR-SCL-04: scripts/libs -> 正本と一致し status 0、出力なし'
        When call _compare_shared scripts/libs
        The status should equal 0
        The output should equal ''
      End

      It '[Normal] T-SHR-SCL-05: assets/dic -> 正本と一致し status 0、出力なし'
        When call _compare_shared assets/dic
        The status should equal 0
        The output should equal ''
      End

      It '[Normal] T-SHR-SCL-06: scripts/libs/__tests__ -> コピーされておらず存在しない'
        The path "${_SKILL_DIR}/scripts/libs/__tests__" should not be exist
      End
    End

    Describe 'When: 異常系'
      It '[Error] T-SHR-SCL-01: ディレクトリへの symlink を含む -> symlink のパスを出力する'
        mkdir "${_FIXTURE}/real"
        ln -s real "${_FIXTURE}/link"
        When call _list_symlinks "$_FIXTURE"
        The status should equal 0
        The output should equal "${_FIXTURE}/link"
      End
    End

    Describe 'When: エッジケース'
      It '[Edge] T-SHR-SCL-02: リンク先の無い symlink -> symlink のパスを出力する'
        ln -s ../nowhere "${_FIXTURE}/dangling"
        When call _list_symlinks "$_FIXTURE"
        The status should equal 0
        The output should equal "${_FIXTURE}/dangling"
      End
    End
  End

  # bdd-coder だけを配置した状態で、同梱のスクリプトが動くかを確認する
  Describe 'T-SHR-SCS: bdd-coder 単体コピーの起動'
    Before '_copy_skill'

    Describe 'When: 正常系'
      It '[Normal] T-SHR-SCS-01: check-test-ids.sh --help -> status 0、Usage を出力する'
        When run _run_copy_script check-test-ids.sh --help
        The status should equal 0
        The output should equal 'Usage: check-test-ids.sh [--lang <lang>[,<lang>...]]'
      End

      It '[Normal] T-SHR-SCS-02: check-test-abbrs.sh --help -> status 0、Usage を出力する'
        When run _run_copy_script check-test-abbrs.sh --help
        The status should equal 0
        The output should equal 'Usage: check-test-abbrs.sh [-h|--help]'
      End
    End

    Describe 'When: 異常系'
      It '[Error] T-SHR-SCS-03: check-test-ids.sh --unknown -> status 1、検査の引数エラーを出力する'
        When run _run_copy_script check-test-ids.sh --unknown
        The status should equal 1
        The stderr should equal 'Error: Unknown option: --unknown'
      End
    End

    Describe 'When: エッジケース'
      It '[Edge] T-SHR-SCS-04: hacker_random -> 同梱辞書を読み、status 0 で名前を出力する'
        When run command bash -c '. "$1" && hacker_random' bash "${_COPY}/scripts/libs/naming.lib.sh"
        The status should equal 0
        The output should be present
        The stderr should equal ''
      End
    End
  End
End
