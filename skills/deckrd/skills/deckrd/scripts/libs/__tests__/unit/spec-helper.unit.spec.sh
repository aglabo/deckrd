#!/usr/bin/env bash
# src: ./skills/deckrd/skills/deckrd/scripts/libs/__tests__/unit/spec-helper.unit.spec.sh
# @(#) : ShellSpec unit tests for spec_helper.sh - setup_coder_tmpscript / setup_naming_cache
#
# Unit test design:
#   - 対象はテストハーネスそのものなので、観測できるのは公開契約である
#     `_CODER_TMPSCRIPT` のパスと、ファイルシステムに残る痕跡だけである。
#     内部変数 (`_CODER_TMPROOT` 等) は読まない。
#   - 「固定パスでない」「teardown 後に残っていない」は否定の判定になる。
#     ShellSpec の条件式へ否定を直接書かず、内部ヘルパー関数へ閉じ込める。
#   - teardown を挟まずに setup を 2 回呼ぶとテスト自身が親ディレクトリをリークする。
#     2 回目の setup を呼ぶケースは、必ず先に teardown を呼ぶ。
#   - export したかどうかは子プロセスから確かめる。bash の export 属性は素の代入を
#     またいで残るので、同じシェルで変数の値を読むだけでは判定できない。
#
# Copyright (c) 2026- atsushifx <https://github.com/atsushifx>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

# ============================================================================
# テスト対象
# ============================================================================

Include ../spec_helper.sh

# ============================================================================
# 内部ヘルパー
# ============================================================================

# 定数

# _CODER_PATH_SEGMENT - bdd-coder パス検出が依存するパスの並び。
# setup_coder_tmpscript はこれを 1 セグメントとして保たなければならない
_CODER_PATH_SEGMENT='/plugins/bdd-coder/'

# _FIXED_PLUGINS_DIR - 使ってはならない固定の一時ディレクトリの親。
# `--jobs 4` の並列実行で全ジョブが共有し、共有ホストでは他ユーザーとも衝突する
_FIXED_PLUGINS_DIR='/tmp/plugins'

# _FIXED_CODER_DIR - 使ってはならない固定の一時ディレクトリ
_FIXED_CODER_DIR="${_FIXED_PLUGINS_DIR}/bdd-coder"

# _INLINE_TMP_WRITE_COMMANDS - 固定の一時ディレクトリを自前で作るコマンド。
# 検査の正規表現はこれと _FIXED_PLUGINS_DIR を実行時に連結して組む。
# 連結済みの文字列をソースに置くと、この spec 自身が違反として数えられてしまう
_INLINE_TMP_WRITE_COMMANDS=('mkdir -p' 'mktemp')

# _LIBS_SPEC_DIR - 静的検査の対象。libs モジュールの spec を収めたディレクトリ
_LIBS_SPEC_DIR="${SHELLSPEC_PROJECT_ROOT}/skills/deckrd/skills/deckrd/scripts/libs/__tests__"

# _SPEC_FILE_GLOB - 静的検査が拾う spec ファイルの glob。
# 違反件数を数える側と走査件数を数える側で共有する。別々に書くと片方だけ直され、
# 対照としての意味が失われる
_SPEC_FILE_GLOB='*.spec.sh'

# _REAL_LOCAL_DATA_DIR - 実行時に bootstrap.lib.sh が導く実リポジトリ側の DECKRD_LOCAL_DATA。
# 差し替え前の初期状態をエッジケースで自前に作るために使う
_REAL_LOCAL_DATA_DIR="${SHELLSPEC_PROJECT_ROOT}/.local/deckrd"

# 関数

# _coder_tmpscript_dir - setup_coder_tmpscript が一時スクリプトを置いたディレクトリを返す
#
# 作成先は公開契約である _CODER_TMPSCRIPT からしか辿れない。teardown は
# _CODER_TMPSCRIPT を unset するので、teardown を呼ぶケースは必ず先にこれを呼ぶ。
# 未設定なら `:?` で即座に落とす。空文字列から dirname を求めても意味がない。
#
# @stdout 一時スクリプトを収めたディレクトリの絶対パス
# shellcheck disable=SC2329
_coder_tmpscript_dir() {
  dirname "${_CODER_TMPSCRIPT:?}"
}

# _tmpscript_keeps_coder_segment - _CODER_TMPSCRIPT のパスが
#     plugins/bdd-coder を 1 セグメントとして含むかを報告する
#
# サフィックス付きのディレクトリ名 (`bdd-coder-XXXXXX` 等) はセグメントを崩すので
# 一致しない。T-LIB-BSRC / T-LIB-BSRCF の意図はこのパス名に表れている。
#
# @return 0 if the path contains the segment, 1 otherwise
# shellcheck disable=SC2329
_tmpscript_keeps_coder_segment() {
  [[ "${_CODER_TMPSCRIPT:-}" == *"${_CODER_PATH_SEGMENT}"* ]]
}

# _tmpscript_outside_fixed_dir - _CODER_TMPSCRIPT が固定ディレクトリの外にあるかを報告する
#
# @return 0 if the path is outside _FIXED_CODER_DIR, 1 if inside
# shellcheck disable=SC2329
_tmpscript_outside_fixed_dir() {
  [[ "${_CODER_TMPSCRIPT:-}" != "${_FIXED_CODER_DIR}"/* ]]
}

# _teardown_leaves_no_dir - teardown_coder_tmpscript が作成先ディレクトリを
#     残さないかを報告する
#
# teardown を呼ぶ前に作成先パスを控える。teardown は _CODER_TMPSCRIPT を unset するので、
# 呼んだ後では何を確かめるべきか分からなくなる。
#
# 3 階層すべてを見る。setup が作るのは mktemp -d が取った root・その下の `plugins`・
# さらに下の `bdd-coder` であり、どれ 1 つ残っても example ごとに 1 個ずつ
# /tmp にディレクトリが溜まる。root は `bdd-coder` から 2 つ上に当たり、
# 公開契約である _CODER_TMPSCRIPT から辿れる。内部変数は読まない。
#
# @return 0 if none of the three created directories remains, 1 otherwise
# shellcheck disable=SC2329
_teardown_leaves_no_dir() {
  local coder_dir plugins_dir root_dir
  coder_dir="$(_coder_tmpscript_dir)"
  plugins_dir="$(dirname "$coder_dir")"
  root_dir="$(dirname "$plugins_dir")"

  teardown_coder_tmpscript

  [[ ! -d "$coder_dir" && ! -d "$plugins_dir" && ! -d "$root_dir" ]]
}

# _second_setup_uses_new_dir - teardown を挟んだ 2 回目の setup が
#     1 回目と異なるディレクトリを作るかを報告する
#
# 1 回目は呼び出し側の Before が済ませている。2 回目を呼ぶ前に teardown を呼ぶので、
# このヘルパーが親ディレクトリを追跡不能にすることはない。
#
# @return 0 if the two setups created different directories, 1 if they shared one
# shellcheck disable=SC2329
_second_setup_uses_new_dir() {
  local first_dir second_dir
  first_dir="$(_coder_tmpscript_dir)"

  teardown_coder_tmpscript
  setup_coder_tmpscript

  second_dir="$(_coder_tmpscript_dir)"

  [[ "$first_dir" != "$second_dir" ]]
}

# _count_inline_tmp_writes - libs モジュールの spec が固定の一時ディレクトリへ
#     直接書き込んでいる箇所の件数を報告する
#
# ヘルパー (setup_coder_tmpscript / run_coder_tmpscript) を使わずに固定パスを
# 直書きすると、後始末がファイル単位になりディレクトリが /tmp に残り続ける。
#
# grep の終了コードをそのまま合否にしない。ヒット 0 件で 1 を返すので、
# 「違反なし」と「検査そのものの失敗」が区別できなくなる。件数を数えて呼び出し側で比べる。
#
# @stdout 違反箇所の件数
# @return 0 always
# shellcheck disable=SC2329
_count_inline_tmp_writes() {
  local -a patterns=("${_INLINE_TMP_WRITE_COMMANDS[@]/%/ ${_FIXED_PLUGINS_DIR}}")
  local IFS='|'

  grep -rhoE "${patterns[*]}" --include="$_SPEC_FILE_GLOB" "$_LIBS_SPEC_DIR" | wc -l
}

# _scans_at_least_one_spec_file - 静的検査が spec ファイルを 1 件以上走査するかを報告する
#
# _count_inline_tmp_writes の正の対照である。grep は --include のパターンが
# 1 件も一致しないとき、標準エラー出力に何も書かずに 0 件を返す。走査が空振りしても
# 「違反なし」として通るので、違反件数の判定だけでは検査が生きていることを示せない。
#
# 走査の範囲を決める _LIBS_SPEC_DIR と _SPEC_FILE_GLOB を対照側と共有する。
# `^` はどの行にも一致するので、grep が拾ったファイルがそのまま走査対象の件数になる。
#
# @return 0 if the scan covers one or more spec files, 1 if it covers none
# shellcheck disable=SC2329
_scans_at_least_one_spec_file() {
  local scanned
  scanned="$(grep -rlE '^' --include="$_SPEC_FILE_GLOB" "$_LIBS_SPEC_DIR" | wc -l)"

  ((scanned >= 1))
}

# _naming_local_dirs_exported - setup_naming_cache が DECKRD_LOCAL_TEMP と
#     DECKRD_LOCAL_WORKSPACES を子プロセスへ export するかを報告する
#
# 判定の前に teardown_naming_cache を呼び、2 変数を属性ごと消してから setup をやり直す。
# この作り直しを省くと、先に走った example が付けた export 属性を setup の手柄として
# 数えてしまい、setup から export を落とした実装が通ってしまう。
#
# 子 bash の `export -p` は export された変数だけを挙げる。子プロセスとして起動される
# スクリプトが読むのはこの一覧なので、代入だけで export を忘れた実装はこの形でしか捕まらない。
#
# @return 0 if both variables are exported, 1 otherwise
# shellcheck disable=SC2329
_naming_local_dirs_exported() {
  teardown_naming_cache
  setup_naming_cache

  bash -c 'export -p | grep -q "^declare -x DECKRD_LOCAL_TEMP=" &&
    export -p | grep -q "^declare -x DECKRD_LOCAL_WORKSPACES="'
}

# _naming_overrides_real_local_dirs - 実リポジトリのパスが先に export されていても
#     setup_naming_cache が DECKRD_LOCAL_TEMP / DECKRD_LOCAL_WORKSPACES を
#     sandbox 側へ差し替えるかを報告する
#
# この spec は bootstrap.lib.sh を source しない。実行時の初期状態 (bootstrap が
# 実リポジトリのパスを export した状態) はこの関数の中で自前に作る。
#
# 初期状態を仕込む前に teardown_naming_cache を呼び、呼び出し側の Before が作った
# 一時ディレクトリを畳んでから setup をやり直す。
#
# bootstrap.lib.sh の `${VAR:-default}` は値のある変数を導出し直さない。setup が
# DECKRD_LOCAL_DATA だけを差し替える実装では、この 2 変数は実リポジトリを指したまま
# 残り、読んだスクリプトが実リポジトリへ書き込む。
#
# @return 0 if both variables point outside the repository tree, 1 otherwise
# shellcheck disable=SC2329
_naming_overrides_real_local_dirs() {
  teardown_naming_cache

  export DECKRD_LOCAL_TEMP="${_REAL_LOCAL_DATA_DIR}/temp"
  export DECKRD_LOCAL_WORKSPACES="${_REAL_LOCAL_DATA_DIR}/workspaces"

  setup_naming_cache

  path_outside_repo "$DECKRD_LOCAL_TEMP" && path_outside_repo "$DECKRD_LOCAL_WORKSPACES"
}

# ============================================================================
# テスト本体
# ============================================================================

# libs モジュールの spec が共有するテストハーネス。
#
# spec ごとの一時ディレクトリを用意し、その中だけで実行が完結する状態を作るのが
# 責務である。固定パスを使ったり、環境変数を実リポジトリのまま残したりすると、
# spec が sandbox の外へ書き込む。
Describe "spec_helper.sh"

  # setup_coder_tmpscript / teardown_coder_tmpscript の対。
  #
  # bootstrap.lib.sh を bdd-coder のパスから source する状況を作るのが役目であり、
  # パスに plugins/bdd-coder を含めることがその契約である。
  #
  # setup は example ごとに専用の一時ディレクトリを作り、teardown はそれを跡形なく消す。
  # 固定パスを使うと `--jobs 4` の並列実行でジョブ同士が同じディレクトリを共有し、
  # 後始末がファイルだけなら空のディレクトリが /tmp に溜まり続ける。
  Describe "T-LIB-SHCT: setup_coder_tmpscript"
    Before "setup_coder_tmpscript"
    After "teardown_coder_tmpscript"

    Describe "When: 正常系"

      It '[Normal] T-LIB-SHCT-01: plugins/bdd-coder を 1 セグメントとして含むパスを作る'
        When call _tmpscript_keeps_coder_segment
        The status should be success
      End

      It '[Normal] T-LIB-SHCT-02: 固定パス /tmp/plugins/bdd-coder 配下を使わない'
        When call _tmpscript_outside_fixed_dir
        The status should be success
      End

      # After の 2 度目の teardown は teardown 側のガードにより無害である
      It '[Normal] T-LIB-SHCT-03: teardown 後に作成先ディレクトリを残さない'
        When call _teardown_leaves_no_dir
        The status should be success
      End

      It '[Normal] T-LIB-SHCT-05: libs モジュールの spec は固定の一時ディレクトリへ直接書き込まない'
        When call _count_inline_tmp_writes
        The output should equal "0"
        # 検査対象のディレクトリを読めないと grep は 0 件を返す。
        # パスの壊れた検査が「違反なし」として通るのを防ぐ
        The stderr should be blank
      End

      It '[Normal] T-LIB-SHCT-06: 静的検査が libs モジュールの spec ファイルを 1 件以上走査する'
        When call _scans_at_least_one_spec_file
        The status should be success
      End
    End

    Describe "When: エッジケース"

      It '[Edge] T-LIB-SHCT-04: teardown を挟んだ 2 回目の setup は別のディレクトリを作る'
        When call _second_setup_uses_new_dir
        The status should be success
      End
    End
  End

  # setup_naming_cache / teardown_naming_cache の対。
  #
  # naming キャッシュのテストのために DECKRD_LOCAL_* を sandbox 側へ差し替え、
  # teardown でそれを元へ戻す。1 変数でも実リポジトリを指したまま残ると、
  # その変数を読むスクリプトが実リポジトリへ書き込む。
  Describe "T-LIB-SHNC: setup_naming_cache"
    Before "setup_naming_cache"
    After "teardown_naming_cache"

    Describe "When: 正常系"

      It '[Normal] T-LIB-SHNC-01: DECKRD_LOCAL_TEMP を sandbox の temp ディレクトリへ向ける'
        The variable DECKRD_LOCAL_TEMP should equal "${DECKRD_LOCAL_DATA}/temp"
      End

      It '[Normal] T-LIB-SHNC-02: DECKRD_LOCAL_WORKSPACES を sandbox の workspaces ディレクトリへ向ける'
        The variable DECKRD_LOCAL_WORKSPACES should equal "${DECKRD_LOCAL_DATA}/workspaces"
      End

      It '[Normal] T-LIB-SHNC-03: 2 変数を子プロセスへ export する'
        When call _naming_local_dirs_exported
        The status should be success
      End

      It '[Normal] T-LIB-SHNC-04: DECKRD_LOCAL_TEMP をリポジトリツリーの外に保つ'
        When call path_outside_repo "${DECKRD_LOCAL_TEMP:-}"
        The status should be success
      End

      It '[Normal] T-LIB-SHNC-05: DECKRD_LOCAL_WORKSPACES をリポジトリツリーの外に保つ'
        When call path_outside_repo "${DECKRD_LOCAL_WORKSPACES:-}"
        The status should be success
      End

      # After の 2 度目の teardown は teardown 側のガードにより無害である
      It '[Normal] T-LIB-SHNC-06: teardown で 3 変数すべてを undefined にする'
        When call teardown_naming_cache
        The variable DECKRD_LOCAL_DATA should be undefined
        The variable DECKRD_LOCAL_TEMP should be undefined
        The variable DECKRD_LOCAL_WORKSPACES should be undefined
      End
    End

    Describe "When: エッジケース"

      It '[Edge] T-LIB-SHNC-07: 実リポジトリのパスが先に export されていても差し替える'
        When call _naming_overrides_real_local_dirs
        The status should be success
      End
    End
  End
End
