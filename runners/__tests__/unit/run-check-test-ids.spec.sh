#!/usr/bin/env bash
# runners/__tests__/unit/run-check-test-ids.spec.sh
# @(#) : BDD unit tests for run-check-test-ids.sh
#
# Copyright (c) 2026- atsushifx <https://github.com/atsushifx>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT
# shellcheck shell=bash

# --- テスト対象 ---
Include "${SHELLSPEC_PROJECT_ROOT}/runners/run-check-test-ids.sh"

# --- 内部ヘルパー ---

# 擬似リポジトリのモジュール宣言を置くディレクトリ (走査ルートからの相対パス)
_FIXTURE_DOCS_SUBDIR="docs/.deckrd"

# モジュールディレクトリから見た、モジュール宣言ファイルの相対ディレクトリ
# (実装側の MODULE_META_SUBDIR と同じ値)
_FIXTURE_META_SUBDIR="workspaces/modules"

# find_unidentified_cases が使うフィールド区切り。期待値の中で TAB を明示するために使う
_TAB=$'\t'

#
# @description 空の擬似リポジトリを作り、走査ルートをそこへ向ける
# @sideeffect TEST_ID_CHECK_ROOT を一時ディレクトリに設定する
# @exitcode 0 always
#
_setup_fixture_repo() {
  TEST_ID_CHECK_ROOT="$(mktemp -d)"
  # 走査対象のスクリプトが読む変数なので、この spec 内では参照されない
  # shellcheck disable=SC2034
  MODULE_DOCS_SUBDIR="$_FIXTURE_DOCS_SUBDIR"
  # 前の例のフィクスチャから読み取った値を引き継がせない
  reset_check_caches
}

#
# @description _setup_fixture_repo が作った一時ディレクトリを削除する
# @exitcode 0 always
#
_teardown_fixture_repo() {
  [[ -n "${TEST_ID_CHECK_ROOT:-}" && "$TEST_ID_CHECK_ROOT" == /tmp/* ]] && rm -rf "$TEST_ID_CHECK_ROOT"
  unset TEST_ID_CHECK_ROOT
}

#
# @description 擬似リポジトリに <ns>/<mod>/workspaces/modules/module.md を書き出す
# @arg $1 string モジュール参照 (<ns>/<mod>)
# @arg $2 string 宣言する test_scope
# @arg $@ string owns の glob (1 個以上)
# @exitcode 0 always
#
_add_module() {
  local ref="$1" scope="$2"
  shift 2
  local dir="${TEST_ID_CHECK_ROOT}/${_FIXTURE_DOCS_SUBDIR}/${ref}/${_FIXTURE_META_SUBDIR}"
  mkdir -p "$dir"
  {
    printf -- '---\n'
    printf 'title: %s\n' "${ref##*/}"
    printf 'test_scope: %s\n' "$scope"
    printf 'owns:\n'
    printf -- '  - %s\n' "$@"
    printf -- '---\n'
    printf '\n## %s\n' "${ref##*/}"
  } >"${dir}/module.md"
}

#
# @description グループ宣言行とケース宣言行だけからなる spec ファイルを擬似リポジトリに
#   書き出す。1 行目にグループ宣言、2 行目以降にケース宣言を 1 行ずつ置く
# @arg $1 string 走査ルートからの相対パス
# @arg $2 string グループ宣言に割り当てるグループ ID。空文字ならグループ宣言を書かず、
#   グループ宣言より前にケースが現れる状態を作れる
# @arg $@ string 各ケース宣言に割り当てるテストケース ID (0 個でもよい)
# @exitcode 0 always
#
_add_spec_file() {
  local rel="$1" group="$2"
  shift 2
  local path="${TEST_ID_CHECK_ROOT}/${rel}"
  mkdir -p "$(dirname "$path")"
  : >"$path"
  # 'Describe' / 'It' を引数として渡し、このファイル自身が宣言に見えないようにする
  [[ -z "$group" ]] || printf '  %s "%s: sample"\n' 'Describe' "$group" >>"$path"
  local id
  for id in "$@"; do
    printf '  %s "Then: [Normal] %s: sample"\n' 'It' "$id" >>"$path"
  done
}

#
# @description 宣言キーワードを差し替えられる 1 行だけの spec ファイルを書き出す。
#   ShellSpec の宣言 DSL は綴りが 19 個あり、どの綴りが走査対象かを綴りごとに
#   検証するために、キーワードを引数で受け取る
# @arg $1 string 走査ルートからの相対パス
# @arg $2 string 宣言キーワード (Describe / xIt / ExampleGroup / Todo など)
# @arg $3 string 宣言に割り当てる ID
# @exitcode 0 always
#
_add_declaration_file() {
  local path="${TEST_ID_CHECK_ROOT}/$1"
  mkdir -p "$(dirname "$path")"
  # キーワードを引数として渡し、この spec 自身の行が宣言に見えないようにする
  printf '  %s "%s: sample"\n' "$2" "$3" >"$path"
}

#
# @description 任意の行を spec ファイルへ追記する
# @arg $1 string 走査ルートからの相対パス
# @arg $2 string 追記する行
# @exitcode 0 always
#
_append_line() {
  printf '%s\n' "$2" >>"${TEST_ID_CHECK_ROOT}/$1"
}

#
# @description 擬似リポジトリの <ns>/<mod>/workspaces/modules/module.md に略語表 (§5.2) を追記する
# @arg $1 string モジュール参照 (<ns>/<mod>)
# @arg $@ string 表に載せる略語 (0 個以上)
# @exitcode 0 always
#
_add_targets_table() {
  local ref="$1"
  shift
  local target
  {
    printf '\n## テスト対象の略語\n\n'
    printf '| 略語 | 対象 |\n'
    printf '| ---- | ---- |\n'
    for target in "$@"; do
      # markdown のバッククォート記法であり、コマンド置換ではない
      # shellcheck disable=SC2016
      printf '| `%s` | `sample_%s` |\n' "$target" "$target"
    done
  } >>"${TEST_ID_CHECK_ROOT}/${_FIXTURE_DOCS_SUBDIR}/${ref}/${_FIXTURE_META_SUBDIR}/module.md"
}

# --- テスト本体 ---

#
# 全ラッパーが共有する唯一の走査 (§6.1) が出す生レコードの書式を固定する。
# G / I / U の 3 種を常に 5 欄で出し、TAB を含みうる宣言行の内容を必ず最後の欄に置く。
# I レコードは直前に現れたグループ ID を 5 欄目に載せ、グループの入れ子は追わない
#
Describe 'T-RUN-SCD: scan_spec_declarations()'
  BeforeEach '_setup_fixture_repo'
  AfterEach '_teardown_fixture_repo'

  Describe 'When: 正常系'
    It 'Then: [Normal] T-RUN-SCD-01: 採番された ID を採番元の file/line と直前のグループ付きで出力する'
      _add_spec_file 'a.spec.sh' 'T-AAA-BB' 'T-AAA-BB-01'
      When call scan_spec_declarations "${TEST_ID_CHECK_ROOT}/a.spec.sh"
      The status should be success
      The line 1 of output should equal "G${_TAB}T-AAA-BB${_TAB}${TEST_ID_CHECK_ROOT}/a.spec.sh${_TAB}1${_TAB}"
      The line 2 of output should equal "I${_TAB}T-AAA-BB-01${_TAB}${TEST_ID_CHECK_ROOT}/a.spec.sh${_TAB}2${_TAB}T-AAA-BB"
      The lines of output should equal 2
    End

    # グループ宣言だけの spec。ケース ID を 1 つも渡さない _add_spec_file の呼び出しと、
    # G レコードが 5 欄目を空にすることの両方をここで固定する
    It 'Then: [Normal] T-RUN-SCD-05: グループ宣言を 5 欄目が空の G レコードで出力する'
      _add_spec_file 'a.spec.sh' 'T-AAA-BB'
      When call scan_spec_declarations "${TEST_ID_CHECK_ROOT}/a.spec.sh"
      The status should be success
      The output should equal "G${_TAB}T-AAA-BB${_TAB}${TEST_ID_CHECK_ROOT}/a.spec.sh${_TAB}1${_TAB}"
    End

    It 'Then: [Normal] T-RUN-SCD-03: ID を採番しない宣言は U レコードの書式のまま出力する'
      _add_spec_file 'a.spec.sh' ''
      _append_line 'a.spec.sh' '  It "Then: [Normal] sample without id"'
      When call scan_spec_declarations "${TEST_ID_CHECK_ROOT}/a.spec.sh"
      The status should be success
      The output should equal "U${_TAB}${TEST_ID_CHECK_ROOT}/a.spec.sh${_TAB}1${_TAB}${_TAB}  It \"Then: [Normal] sample without id\""
    End

    # FNR と FILENAME の番人。1 ファイルだけを渡すテストでは FNR は NR と、FILENAME は
    # 固定パスと見分けが付かない。U 側は T-RUN-FUC-06 が同じことを守っている
    It 'Then: [Normal] T-RUN-SCD-04: 複数ファイルでも各レコードは自分のファイル名とファイル内行番号を持つ'
      _add_spec_file 'a.spec.sh' 'T-AAA-BB' 'T-AAA-BB-01'
      _add_spec_file 'b.spec.sh' 'T-AAA-CC' 'T-AAA-CC-01' 'T-AAA-CC-02'
      When call scan_spec_declarations "${TEST_ID_CHECK_ROOT}/a.spec.sh" "${TEST_ID_CHECK_ROOT}/b.spec.sh"
      The status should be success
      The line 1 of output should equal "G${_TAB}T-AAA-BB${_TAB}${TEST_ID_CHECK_ROOT}/a.spec.sh${_TAB}1${_TAB}"
      The line 2 of output should equal "I${_TAB}T-AAA-BB-01${_TAB}${TEST_ID_CHECK_ROOT}/a.spec.sh${_TAB}2${_TAB}T-AAA-BB"
      The line 3 of output should equal "G${_TAB}T-AAA-CC${_TAB}${TEST_ID_CHECK_ROOT}/b.spec.sh${_TAB}1${_TAB}"
      The line 4 of output should equal "I${_TAB}T-AAA-CC-01${_TAB}${TEST_ID_CHECK_ROOT}/b.spec.sh${_TAB}2${_TAB}T-AAA-CC"
      The line 5 of output should equal "I${_TAB}T-AAA-CC-02${_TAB}${TEST_ID_CHECK_ROOT}/b.spec.sh${_TAB}3${_TAB}T-AAA-CC"
      The lines of output should equal 5
    End

    # グループ宣言に当たるたびに直前グループを上書きすることの番人。
    # 最初のグループを覚えたままにする実装だと 4 行目が T-AAA-BB になって RED
    It 'Then: [Normal] T-RUN-SCD-09: 2 つ目のグループ宣言より後のケースは 2 つ目のグループに属する'
      _add_spec_file 'a.spec.sh' 'T-AAA-BB' 'T-AAA-BB-01'
      _append_line 'a.spec.sh' '  Describe "T-AAA-CC: sample"'
      _append_line 'a.spec.sh' '  It "Then: [Normal] T-AAA-CC-01: sample"'
      When call scan_spec_declarations "${TEST_ID_CHECK_ROOT}/a.spec.sh"
      The status should be success
      The line 2 of output should equal "I${_TAB}T-AAA-BB-01${_TAB}${TEST_ID_CHECK_ROOT}/a.spec.sh${_TAB}2${_TAB}T-AAA-BB"
      The line 4 of output should equal "I${_TAB}T-AAA-CC-01${_TAB}${TEST_ID_CHECK_ROOT}/a.spec.sh${_TAB}4${_TAB}T-AAA-CC"
      The lines of output should equal 4
    End
  End

  Describe 'When: 異常系'
    # 読めないファイルで走査が止まらないことの番人。欠落ファイルを実在ファイルで挟むので、
    # そこで打ち切る実装だと b.spec.sh の G レコードが消えて RED
    It 'Then: [Error] T-RUN-SCD-06: 読めない引数を落として警告し、残りのファイルを走査する'
      _add_spec_file 'a.spec.sh' 'T-AAA-BB'
      _add_spec_file 'b.spec.sh' 'T-AAA-CC'
      When call scan_spec_declarations \
        "${TEST_ID_CHECK_ROOT}/a.spec.sh" "${TEST_ID_CHECK_ROOT}/missing.spec.sh" "${TEST_ID_CHECK_ROOT}/b.spec.sh"
      The status should be success
      The line 1 of output should equal "G${_TAB}T-AAA-BB${_TAB}${TEST_ID_CHECK_ROOT}/a.spec.sh${_TAB}1${_TAB}"
      The line 2 of output should equal "G${_TAB}T-AAA-CC${_TAB}${TEST_ID_CHECK_ROOT}/b.spec.sh${_TAB}1${_TAB}"
      The lines of output should equal 2
      The stderr should include 'missing.spec.sh'
    End
  End

  Describe 'When: エッジケース'
    # 5 欄目が空であることが「所属グループ無し」を表す。所属違反 (§5.4) はここから報告される
    It 'Then: [Edge] T-RUN-SCD-07: グループ宣言より前のケースは 5 欄目を空にする'
      _add_spec_file 'a.spec.sh' '' 'T-AAA-BB-01'
      _append_line 'a.spec.sh' '  Describe "T-AAA-BB: sample"'
      When call scan_spec_declarations "${TEST_ID_CHECK_ROOT}/a.spec.sh"
      The status should be success
      The line 1 of output should equal "I${_TAB}T-AAA-BB-01${_TAB}${TEST_ID_CHECK_ROOT}/a.spec.sh${_TAB}1${_TAB}"
      The line 2 of output should equal "G${_TAB}T-AAA-BB${_TAB}${TEST_ID_CHECK_ROOT}/a.spec.sh${_TAB}2${_TAB}"
      The lines of output should equal 2
    End

    # FNR == 1 のリセットの番人。ファイル先頭で直前グループを捨てないと
    # a.spec.sh の T-AAA-BB が b.spec.sh のケースに漏れて RED
    It 'Then: [Edge] T-RUN-SCD-08: 直前のグループはファイル境界を越えない'
      _add_spec_file 'a.spec.sh' 'T-AAA-BB' 'T-AAA-BB-01'
      _add_spec_file 'b.spec.sh' '' 'T-AAA-CC-01'
      When call scan_spec_declarations "${TEST_ID_CHECK_ROOT}/a.spec.sh" "${TEST_ID_CHECK_ROOT}/b.spec.sh"
      The status should be success
      The line 3 of output should equal "I${_TAB}T-AAA-CC-01${_TAB}${TEST_ID_CHECK_ROOT}/b.spec.sh${_TAB}1${_TAB}"
      The lines of output should equal 3
    End

    # 1 宣言が複数 ID を採番しても採番元は 1 つしかないことの番人。
    # ID ごとに 1 レコード出しつつ、file/line は全レコードで同一でなければならない
    It 'Then: [Edge] T-RUN-SCD-02: 1 行にある 2 つの ID を同じ file/line の I レコード 2 本で出力する'
      _add_spec_file 'a.spec.sh' ''
      _append_line 'a.spec.sh' '  It "Then: T-AAA-BB-01 and T-AAA-BB-02 in one"'
      When call scan_spec_declarations "${TEST_ID_CHECK_ROOT}/a.spec.sh"
      The status should be success
      The line 1 of output should equal "I${_TAB}T-AAA-BB-01${_TAB}${TEST_ID_CHECK_ROOT}/a.spec.sh${_TAB}1${_TAB}"
      The line 2 of output should equal "I${_TAB}T-AAA-BB-02${_TAB}${TEST_ID_CHECK_ROOT}/a.spec.sh${_TAB}1${_TAB}"
      The lines of output should equal 2
    End
  End
End

#
# グループ宣言行に割り当てられたグループ ID を抽出する (§6.1)
# ケース ID と同じパターンで両方を拾わないこと、採番の出現回数を全ファイル横断で
# 数えられることを、extract_case_ids と同じ規約 (ソートは 1 回、sort -u は使わない) で守る
#
Describe 'T-RUN-EGI: extract_group_ids()'
  BeforeEach '_setup_fixture_repo'
  AfterEach '_teardown_fixture_repo'

  Describe 'When: 正常系'
    # 走査の後段で 1 回だけソートすることの番人。ファイルごとにソートして emit すると RED
    It 'Then: [Normal] T-RUN-EGI-02: 複数ファイルを横断してグローバルにソートする'
      _add_spec_file 'b.spec.sh' 'T-AAA-CC'
      _add_spec_file 'a.spec.sh' 'T-AAA-BB'
      When call extract_group_ids "${TEST_ID_CHECK_ROOT}/b.spec.sh" "${TEST_ID_CHECK_ROOT}/a.spec.sh"
      The line 1 of output should equal 'T-AAA-BB'
      The line 2 of output should equal 'T-AAA-CC'
    End

    # ShellSpec が block_example_group に割り当てている綴りの全件。1 つでも
    # 走査対象から漏れると、その綴りで宣言されたグループ ID が検査 C から丸ごと消える。
    # 行頭が宣言そのものに見えないよう、綴りは引用符で始めて書く。
    # 以降の例は Parameters を共有するため、この表の下にはこの 1 例だけを置く
    # 最小の正常系 (宣言 1 行だけのファイル) は、この表の 'Describe' 行と T-RUN-EGI-03 が兼ねている
    Parameters
      'ExampleGroup'
      'Describe'
      'Context'
      'xExampleGroup'
      'xDescribe'
      'xContext'
      'fExampleGroup'
      'fDescribe'
      'fContext'
    End

    It "Then: [Normal] T-RUN-EGI-09: $1 で宣言されたグループ ID を出力する"
      _add_declaration_file 'a.spec.sh' "$1" 'T-AAA-BB'
      When call extract_group_ids "${TEST_ID_CHECK_ROOT}/a.spec.sh"
      The status should be success
      The output should equal 'T-AAA-BB'
    End
  End

  Describe 'When: 異常系'
    # 欠落ファイルを実在ファイルで挟むので、そこで打ち切る実装だと b.spec.sh の ID が消えて RED
    It 'Then: [Error] T-RUN-EGI-03: 読めないファイルを飛ばして残りのファイルを走査する'
      _add_spec_file 'a.spec.sh' 'T-AAA-BB'
      _add_spec_file 'b.spec.sh' 'T-AAA-CC'
      When call extract_group_ids \
        "${TEST_ID_CHECK_ROOT}/a.spec.sh" "${TEST_ID_CHECK_ROOT}/missing.spec.sh" "${TEST_ID_CHECK_ROOT}/b.spec.sh"
      The status should be success
      The line 1 of output should equal 'T-AAA-BB'
      The line 2 of output should equal 'T-AAA-CC'
      # 読めなかったことを黙って飲み込まない
      The stderr should include 'missing.spec.sh'
    End
  End

  Describe 'When: エッジケース'
    # 採番の出現回数を全ファイル横断で数えるため、一意化しない。sort -u を挟むと RED
    It 'Then: [Edge] T-RUN-EGI-04: 2 ファイルが同じグループ ID を名乗っても一意化しない'
      _add_spec_file 'a.spec.sh' 'T-DUP-XX'
      _add_spec_file 'b.spec.sh' 'T-DUP-XX'
      When call extract_group_ids "${TEST_ID_CHECK_ROOT}/a.spec.sh" "${TEST_ID_CHECK_ROOT}/b.spec.sh"
      The lines of output should equal 2
    End

    It 'Then: [Edge] T-RUN-EGI-05: ファイルを 1 つも渡されなければ何も出力しない'
      When call extract_group_ids
      The status should be success
      The output should equal ''
    End

    # ケース宣言しか無いファイルからはグループ ID を 1 件も出さないことの番人。
    # このフィクスチャは It 行なのでグループ分岐に到達せず、かつ T-RUN-IWH-01 は
    # ケース ID の書式なのでトークン完全一致でも落ちる。つまり抽出行の限定と
    # 完全一致の両方がこの例を通しており、この 1 例ではどちらの機構も固定できない。
    # 完全一致を固定しているのは T-RUN-EGI-07 / T-RUN-EGI-08 の方である
    It 'Then: [Edge] T-RUN-EGI-06: ケース宣言行の ID をグループ ID として拾わない'
      _add_spec_file 'a.spec.sh' '' 'T-RUN-IWH-01'
      When call extract_group_ids "${TEST_ID_CHECK_ROOT}/a.spec.sh"
      The status should be success
      The output should equal ''
    End

    # トークン完全一致の先頭側の番人。アンカーを外すと XT-AAA-BB の中の T-AAA-BB が
    # 部分一致し、トークン丸ごとの XT-AAA-BB がグループ ID として出て RED
    It 'Then: [Edge] T-RUN-EGI-07: ID の前に文字が付いたトークンをグループ ID として拾わない'
      _add_spec_file 'a.spec.sh' 'XT-AAA-BB'
      When call extract_group_ids "${TEST_ID_CHECK_ROOT}/a.spec.sh"
      The status should be success
      The output should equal ''
    End

    # トークン完全一致の末尾側の番人。アンカーを外すと T-AAA-BB-01 の中の T-AAA-BB が
    # 部分一致し、グループ宣言がケース ID を名乗ったまま通って RED
    It 'Then: [Edge] T-RUN-EGI-08: グループ宣言行にケース ID の書式で書かれたトークンを拾わない'
      _add_spec_file 'a.spec.sh' 'T-AAA-BB-01'
      When call extract_group_ids "${TEST_ID_CHECK_ROOT}/a.spec.sh"
      The status should be success
      The output should equal ''
    End
  End
End

#
# ケース宣言行に割り当てられたテストケース ID を抽出する (§6.1)
#
Describe 'T-RUN-ECI: extract_case_ids()'
  BeforeEach '_setup_fixture_repo'
  AfterEach '_teardown_fixture_repo'

  Describe 'When: 正常系'
    It 'Then: [Normal] T-RUN-ECI-01: ケース宣言行に書かれた ID をすべて出力する'
      _add_spec_file 'a.spec.sh' 'T-AAA-BB' 'T-AAA-BB-01' 'T-AAA-BB-02'
      When call extract_case_ids "${TEST_ID_CHECK_ROOT}/a.spec.sh"
      The status should be success
      The line 1 of output should equal 'T-AAA-BB-01'
      The line 2 of output should equal 'T-AAA-BB-02'
    End

    It 'Then: [Normal] T-RUN-ECI-02: 枝番付きの ID も抽出する'
      _add_spec_file 'a.spec.sh' 'T-AAA-BB' 'T-AAA-BB-03-01'
      When call extract_case_ids "${TEST_ID_CHECK_ROOT}/a.spec.sh"
      The output should equal 'T-AAA-BB-03-01'
    End

    # 走査の後段で 1 回だけソートすることの番人。ファイルごとにソートして emit すると RED
    It 'Then: [Normal] T-RUN-ECI-09: 複数ファイルを横断してグローバルにソートする'
      _add_spec_file 'b.spec.sh' 'T-AAA-BB' 'T-AAA-BB-02'
      _add_spec_file 'a.spec.sh' 'T-AAA-BB' 'T-AAA-BB-01'
      When call extract_case_ids "${TEST_ID_CHECK_ROOT}/b.spec.sh" "${TEST_ID_CHECK_ROOT}/a.spec.sh"
      The line 1 of output should equal 'T-AAA-BB-01'
      The line 2 of output should equal 'T-AAA-BB-02'
    End

    # 行内の全トークンを走査することの番人。最初の 1 件で打ち切る実装だと RED
    It 'Then: [Normal] T-RUN-ECI-10: 1 つのケース宣言行にある 2 つの ID を両方抽出する'
      _add_spec_file 'a.spec.sh' ''
      _append_line 'a.spec.sh' '  It "Then: T-AAA-BB-01 and T-AAA-BB-02 in one"'
      When call extract_case_ids "${TEST_ID_CHECK_ROOT}/a.spec.sh"
      The line 1 of output should equal 'T-AAA-BB-01'
      The line 2 of output should equal 'T-AAA-BB-02'
    End

    # ShellSpec が block_example に割り当てている綴りの全件。T-RUN-EGI-09 と対になる。
    # 1 つでも走査対象から漏れると、その綴りのケースが検査 B の付与網羅性から消える。
    # 行頭が宣言そのものに見えないよう、綴りは引用符で始めて書く。
    # 以降の例は Parameters を共有するため、この表の下にはこの 1 例だけを置く
    Parameters
      'Example'
      'Specify'
      'It'
      'xExample'
      'xSpecify'
      'xIt'
      'fExample'
      'fSpecify'
      'fIt'
    End

    It "Then: [Normal] T-RUN-ECI-15: $1 で宣言されたケース ID を出力する"
      _add_declaration_file 'a.spec.sh' "$1" 'T-AAA-BB-01'
      When call extract_case_ids "${TEST_ID_CHECK_ROOT}/a.spec.sh"
      The status should be success
      The output should equal 'T-AAA-BB-01'
    End
  End

  Describe 'When: 異常系'
    It 'Then: [Error] T-RUN-ECI-07: scope が 5 文字の ID は抽出しない'
      _add_spec_file 'a.spec.sh' 'T-TOOLONG-FOO' 'T-TOOLONG-FOO-01'
      When call extract_case_ids "${TEST_ID_CHECK_ROOT}/a.spec.sh"
      The status should be success
      The output should equal ''
    End

    # target セグメントは 1 個に固定されている (§5.1)。`(-[A-Z0-9]+)+` に戻すと
    # T-AAA-BB-CC-01 が拾われて RED
    It 'Then: [Error] T-RUN-ECI-12: target セグメントが 2 個の ID は抽出しない'
      _add_spec_file 'a.spec.sh' '' 'T-AAA-BB-CC-01'
      When call extract_case_ids "${TEST_ID_CHECK_ROOT}/a.spec.sh"
      The status should be success
      The output should equal ''
    End

    It 'Then: [Error] T-RUN-ECI-08: target セグメントの無い ID は抽出しない'
      _add_spec_file 'a.spec.sh' 'T-AB' 'T-AB-01'
      When call extract_case_ids "${TEST_ID_CHECK_ROOT}/a.spec.sh"
      The status should be success
      The output should equal ''
    End

    # 読めないファイルで走査が止まらないことの番人。旧 grep は警告を出して後続も読み続けた。
    # 欠落ファイルを実在ファイルで挟むので、そこで打ち切る実装だと b.spec.sh の ID が消えて RED
    It 'Then: [Error] T-RUN-ECI-11: 読めないファイルを飛ばして残りのファイルを走査する'
      _add_spec_file 'a.spec.sh' 'T-AAA-BB' 'T-AAA-BB-01'
      _add_spec_file 'b.spec.sh' 'T-AAA-BB' 'T-AAA-BB-02'
      When call extract_case_ids \
        "${TEST_ID_CHECK_ROOT}/a.spec.sh" "${TEST_ID_CHECK_ROOT}/missing.spec.sh" "${TEST_ID_CHECK_ROOT}/b.spec.sh"
      The status should be success
      The line 1 of output should equal 'T-AAA-BB-01'
      The line 2 of output should equal 'T-AAA-BB-02'
      # 読めなかったことを黙って飲み込まない
      The stderr should include 'missing.spec.sh'
    End
  End

  Describe 'When: エッジケース'
    It 'Then: [Edge] T-RUN-ECI-03: コメント行の ID は割り当てとして扱わない'
      _add_spec_file 'a.spec.sh' 'T-AAA-BB' 'T-AAA-BB-01'
      _append_line 'a.spec.sh' '  # cross reference to T-AAA-BB-99'
      When call extract_case_ids "${TEST_ID_CHECK_ROOT}/a.spec.sh"
      The output should equal 'T-AAA-BB-01'
    End

    It 'Then: [Edge] T-RUN-ECI-04: 同一ファイル内の重複を一意化せずに残す'
      _add_spec_file 'a.spec.sh' 'T-AAA-BB' 'T-AAA-BB-01' 'T-AAA-BB-01'
      When call extract_case_ids "${TEST_ID_CHECK_ROOT}/a.spec.sh"
      The lines of output should equal 2
    End

    It 'Then: [Edge] T-RUN-ECI-05: prefix の付いたトークンを ID と誤認しない'
      _add_spec_file 'a.spec.sh' 'XT-AAA-BB' 'XT-AAA-BB-01'
      When call extract_case_ids "${TEST_ID_CHECK_ROOT}/a.spec.sh"
      The output should equal ''
    End

    It 'Then: [Edge] T-RUN-ECI-06: ファイルを 1 つも渡されなければ何も出力しない'
      When call extract_case_ids
      The status should be success
      The output should equal ''
    End

    # T-RUN-EGI-06 と対になる取り違え防止。グループ ID はケース ID の prefix なので、
    # 抽出をケース宣言行に限定しないとグループ宣言の ID が採番として数えられる。
    # G レコードを通すフィルタに変えると T-AAA-BB が混ざって 2 行になり RED
    It 'Then: [Edge] T-RUN-ECI-14: グループ宣言とケース宣言が並ぶファイルからケース ID だけを拾う'
      _add_spec_file 'a.spec.sh' 'T-AAA-BB' 'T-AAA-BB-01'
      When call extract_case_ids "${TEST_ID_CHECK_ROOT}/a.spec.sh"
      The status should be success
      The output should equal 'T-AAA-BB-01'
    End

    # ケース宣言の綴りに似ているが block_example ではない 2 語。
    # Example は ExampleGroup の prefix であり、両者を分けているのは綴りの後ろに
    # 空白を要求することだけ。Todo は ID を持たない placeholder なので、
    # ケース宣言に数えると未採番の山を生む。
    # 以降の例は Parameters を共有するため、この表の下にはこの 1 例だけを置く
    Parameters
      'ExampleGroup'
      'Todo'
    End

    It "Then: [Edge] T-RUN-ECI-16: $1 の宣言行をケース宣言として扱わない"
      _add_declaration_file 'a.spec.sh' "$1" 'T-AAA-BB-01'
      When call extract_case_ids "${TEST_ID_CHECK_ROOT}/a.spec.sh"
      The status should be success
      The output should equal ''
    End
  End
End

#
# ID を割り当てられていないケース宣言行を洗い出す (§6.1)
# 抽出できる ID を 1 つも含まないケース宣言を、検査 B が見落とさないようにする
#
Describe 'T-RUN-FUC: find_unidentified_cases()'
  BeforeEach '_setup_fixture_repo'
  AfterEach '_teardown_fixture_repo'

  Describe 'When: 正常系'
    It 'Then: [Normal] T-RUN-FUC-01: 全ケース宣言に ID があれば何も出力しない'
      _add_spec_file 'a.spec.sh' 'T-AAA-BB' 'T-AAA-BB-01' 'T-AAA-BB-02'
      _add_spec_file 'b.spec.sh' 'T-AAA-CC' 'T-AAA-CC-01'
      When call find_unidentified_cases "${TEST_ID_CHECK_ROOT}/a.spec.sh" "${TEST_ID_CHECK_ROOT}/b.spec.sh"
      The status should be success
      The output should equal ''
    End

    # 未採番レコードをソートしないことの番人。行番号を 2 ファイルでずらし、
    # 大きい行番号のファイルを先に渡すので、行番号ソートが混入すると RED
    It 'Then: [Normal] T-RUN-FUC-06: 未採番レコードをファイル引数順に出力する'
      _add_spec_file 'b.spec.sh' 'T-AAA-BB' 'T-AAA-BB-01' 'T-AAA-BB-02'
      _append_line 'b.spec.sh' '  It "Then: [Normal] b without id"'
      _add_spec_file 'a.spec.sh' 'T-AAA-CC' 'T-AAA-CC-01'
      _append_line 'a.spec.sh' '  It "Then: [Normal] a without id"'
      When call find_unidentified_cases "${TEST_ID_CHECK_ROOT}/b.spec.sh" "${TEST_ID_CHECK_ROOT}/a.spec.sh"
      The line 1 of output should equal "${TEST_ID_CHECK_ROOT}/b.spec.sh${_TAB}4${_TAB}  It \"Then: [Normal] b without id\""
      The line 2 of output should equal "${TEST_ID_CHECK_ROOT}/a.spec.sh${_TAB}3${_TAB}  It \"Then: [Normal] a without id\""
    End
  End

  Describe 'When: 異常系'
    It 'Then: [Error] T-RUN-FUC-02: ID の無いケース宣言行を file/line/content の TAB 区切りで出力する'
      _add_spec_file 'a.spec.sh' 'T-AAA-BB' 'T-AAA-BB-01'
      _add_spec_file 'b.spec.sh' 'T-AAA-CC' 'T-AAA-CC-01'
      _append_line 'b.spec.sh' '  It "Then: [Normal] sample without id"'
      When call find_unidentified_cases "${TEST_ID_CHECK_ROOT}/a.spec.sh" "${TEST_ID_CHECK_ROOT}/b.spec.sh"
      The status should be success
      The output should equal "${TEST_ID_CHECK_ROOT}/b.spec.sh${_TAB}3${_TAB}  It \"Then: [Normal] sample without id\""
    End

    It 'Then: [Error] T-RUN-FUC-03: 書式違反の ID を持つケース宣言行を出力する'
      _add_spec_file 'a.spec.sh' 'T-TOOLONG-FOO' 'T-TOOLONG-FOO-01'
      When call find_unidentified_cases "${TEST_ID_CHECK_ROOT}/a.spec.sh"
      The status should be success
      The output should include 'T-TOOLONG-FOO-01'
    End
  End

  Describe 'When: エッジケース'
    It 'Then: [Edge] T-RUN-FUC-04: ファイルを 1 つも渡されなければ何も出力しない'
      When call find_unidentified_cases
      The status should be success
      The output should equal ''
    End

    It 'Then: [Edge] T-RUN-FUC-05: ケース宣言でない行は ID が無くても出力しない'
      _add_spec_file 'a.spec.sh' 'T-AAA-BB' 'T-AAA-BB-01'
      _append_line 'a.spec.sh' '  # a comment carrying no test ID'
      When call find_unidentified_cases "${TEST_ID_CHECK_ROOT}/a.spec.sh"
      The status should be success
      The output should equal ''
    End

    # 本文を substr で切り出している設計根拠の固定。フィールド分割で組み直す実装だと
    # 本文中の TAB が区切りと解釈されて崩れる
    It 'Then: [Edge] T-RUN-FUC-07: ケース宣言の本文に含まれる TAB を保持する'
      _add_spec_file 'a.spec.sh' ''
      _append_line 'a.spec.sh' "  It \"Then: [Normal] tabbed${_TAB}content\""
      When call find_unidentified_cases "${TEST_ID_CHECK_ROOT}/a.spec.sh"
      The status should be success
      The output should equal "${TEST_ID_CHECK_ROOT}/a.spec.sh${_TAB}1${_TAB}  It \"Then: [Normal] tabbed${_TAB}content\""
    End
  End
End

#
# module.md の frontmatter からモジュール宣言を読み出す (§5.2)
#
Describe 'T-RUN-FMR: module.md frontmatter reader'
  BeforeEach '_setup_fixture_repo'
  AfterEach '_teardown_fixture_repo'

  Describe 'When: 正常系'
    It 'Then: [Normal] T-RUN-FMR-01: read_module_scalar が宣言された test_scope を返す'
      _add_module 'ns/alpha' 'ALP' 'src/alpha/**'
      When call read_module_scalar "${TEST_ID_CHECK_ROOT}/${_FIXTURE_DOCS_SUBDIR}/ns/alpha/${_FIXTURE_META_SUBDIR}/module.md" 'test_scope'
      The output should equal 'ALP'
    End

    It 'Then: [Normal] T-RUN-FMR-02: read_module_owns が owns の glob をすべて返す'
      _add_module 'ns/alpha' 'ALP' 'src/alpha/**' 'src/shared/*.sh'
      When call read_module_owns "${TEST_ID_CHECK_ROOT}/${_FIXTURE_DOCS_SUBDIR}/ns/alpha/${_FIXTURE_META_SUBDIR}/module.md"
      The line 1 of output should equal 'src/alpha/**'
      The line 2 of output should equal 'src/shared/*.sh'
    End

    It 'Then: [Normal] T-RUN-FMR-04: 対になったダブルクォートを剥がす'
      _add_module 'ns/alpha' '"DQT"' 'src/alpha/**'
      When call read_module_scalar "${TEST_ID_CHECK_ROOT}/${_FIXTURE_DOCS_SUBDIR}/ns/alpha/${_FIXTURE_META_SUBDIR}/module.md" 'test_scope'
      The output should equal 'DQT'
    End

    It 'Then: [Normal] T-RUN-FMR-05: 対になったシングルクォートを剥がす'
      _add_module 'ns/alpha' "'SQT'" 'src/alpha/**'
      When call read_module_scalar "${TEST_ID_CHECK_ROOT}/${_FIXTURE_DOCS_SUBDIR}/ns/alpha/${_FIXTURE_META_SUBDIR}/module.md" 'test_scope'
      The output should equal 'SQT'
    End
  End

  Describe 'When: 異常系'
    It 'Then: [Error] T-RUN-FMR-03: 宣言されていないフィールドには空を返す'
      _add_module 'ns/alpha' 'ALP' 'src/alpha/**'
      When call read_module_scalar "${TEST_ID_CHECK_ROOT}/${_FIXTURE_DOCS_SUBDIR}/ns/alpha/${_FIXTURE_META_SUBDIR}/module.md" 'nonexistent'
      The output should equal ''
    End

    It 'Then: [Error] T-RUN-FMR-06: 末尾だけの引用符は剥がさない'
      _add_module 'ns/alpha' 'TRL"' 'src/alpha/**'
      When call read_module_scalar "${TEST_ID_CHECK_ROOT}/${_FIXTURE_DOCS_SUBDIR}/ns/alpha/${_FIXTURE_META_SUBDIR}/module.md" 'test_scope'
      The output should equal 'TRL"'
    End

    It 'Then: [Error] T-RUN-FMR-07: 先頭だけの引用符は剥がさない'
      _add_module 'ns/alpha' '"LED' 'src/alpha/**'
      When call read_module_scalar "${TEST_ID_CHECK_ROOT}/${_FIXTURE_DOCS_SUBDIR}/ns/alpha/${_FIXTURE_META_SUBDIR}/module.md" 'test_scope'
      The output should equal '"LED'
    End

    It 'Then: [Error] T-RUN-FMR-08: 種類の違う引用符の組は剥がさない'
      _add_module 'ns/alpha' "'MIX\"" 'src/alpha/**'
      When call read_module_scalar "${TEST_ID_CHECK_ROOT}/${_FIXTURE_DOCS_SUBDIR}/ns/alpha/${_FIXTURE_META_SUBDIR}/module.md" 'test_scope'
      The output should equal "'MIX\""
    End
  End

  Describe 'When: エッジケース'
    It 'Then: [Edge] T-RUN-FMR-09: 空のダブルクォートペアは剥がさずそのまま返す'
      _add_module 'ns/alpha' '""' 'src/alpha/**'
      When call read_module_scalar "${TEST_ID_CHECK_ROOT}/${_FIXTURE_DOCS_SUBDIR}/ns/alpha/${_FIXTURE_META_SUBDIR}/module.md" 'test_scope'
      The output should equal '""'
    End

    It 'Then: [Edge] T-RUN-FMR-11: 空のシングルクォートペアは剥がさずそのまま返す'
      _add_module 'ns/alpha' "''" 'src/alpha/**'
      When call read_module_scalar "${TEST_ID_CHECK_ROOT}/${_FIXTURE_DOCS_SUBDIR}/ns/alpha/${_FIXTURE_META_SUBDIR}/module.md" 'test_scope'
      The output should equal "''"
    End

    It 'Then: [Edge] T-RUN-FMR-12: 末尾の CR を空白として除去し module.sh のリーダーと同じ値を返す'
      # T-CLI-CDS-15 と対になるケース。CR を行末に置くと Windows の gawk が落とすため、
      # CR の後ろに半角スペースを 1 つ置いて行末を避ける。
      _add_module 'ns/alpha' "$(printf '"ALP"\r ')" 'src/alpha/**'
      When call read_module_scalar "${TEST_ID_CHECK_ROOT}/${_FIXTURE_DOCS_SUBDIR}/ns/alpha/${_FIXTURE_META_SUBDIR}/module.md" 'test_scope'
      The output should equal 'ALP'
    End

    It 'Then: [Edge] T-RUN-FMR-10: 引用符 1 文字はペアではないので剥がさない'
      _add_module 'ns/alpha' '"' 'src/alpha/**'
      When call read_module_scalar "${TEST_ID_CHECK_ROOT}/${_FIXTURE_DOCS_SUBDIR}/ns/alpha/${_FIXTURE_META_SUBDIR}/module.md" 'test_scope'
      The output should equal '"'
    End
  End
End

#
# module.md の略語表から略語を読み出す (§5.2)
# 検査 D が実体と突き合わせる台帳側の入力を作る
#
Describe 'T-RUN-RMT: read_module_targets()'
  BeforeEach '_setup_fixture_repo'
  AfterEach '_teardown_fixture_repo'

  Describe 'When: 正常系'
    It 'Then: [Normal] T-RUN-RMT-01: 略語表の各行から略語を宣言順に取り出す'
      _add_module 'ns/alpha' 'ALP' 'alpha/**'
      _add_targets_table 'ns/alpha' 'AA' 'BB'
      When call read_module_targets "${TEST_ID_CHECK_ROOT}/${_FIXTURE_DOCS_SUBDIR}/ns/alpha/${_FIXTURE_META_SUBDIR}/module.md"
      The line 1 of output should equal 'AA'
      The line 2 of output should equal 'BB'
    End

    It 'Then: [Normal] T-RUN-RMT-02: 見出し行と区切り行は略語として扱わない'
      _add_module 'ns/alpha' 'ALP' 'alpha/**'
      _add_targets_table 'ns/alpha' 'AA'
      When call read_module_targets "${TEST_ID_CHECK_ROOT}/${_FIXTURE_DOCS_SUBDIR}/ns/alpha/${_FIXTURE_META_SUBDIR}/module.md"
      The lines of output should equal 1
    End
  End

  Describe 'When: エッジケース'
    It 'Then: [Edge] T-RUN-RMT-03: 略語表の見出しが無ければ何も読み出さない'
      _add_module 'ns/alpha' 'ALP' 'alpha/**'
      When call read_module_targets "${TEST_ID_CHECK_ROOT}/${_FIXTURE_DOCS_SUBDIR}/ns/alpha/${_FIXTURE_META_SUBDIR}/module.md"
      The status should be success
      The output should equal ''
    End

    It 'Then: [Edge] T-RUN-RMT-04: 別の見出しの下に置かれた表は読み出さない'
      _add_module 'ns/alpha' 'ALP' 'alpha/**'
      _add_targets_table 'ns/alpha' 'AA'
      _append_line "${_FIXTURE_DOCS_SUBDIR}/ns/alpha/${_FIXTURE_META_SUBDIR}/module.md" '## 別の見出し'
      _append_line "${_FIXTURE_DOCS_SUBDIR}/ns/alpha/${_FIXTURE_META_SUBDIR}/module.md" '| 略語 | 対象 |'
      # shellcheck disable=SC2016
      _append_line "${_FIXTURE_DOCS_SUBDIR}/ns/alpha/${_FIXTURE_META_SUBDIR}/module.md" '| `ZZ` | `other` |'
      When call read_module_targets "${TEST_ID_CHECK_ROOT}/${_FIXTURE_DOCS_SUBDIR}/ns/alpha/${_FIXTURE_META_SUBDIR}/module.md"
      The output should equal 'AA'
    End
  End
End

#
# owns の glob とテストファイルパスの照合 (§5.2)
#
Describe 'T-RUN-PMG: path_matches_glob()'
  Describe 'When: 正常系'
    Parameters
      'runners/__tests__/unit/a.spec.sh' 'runners/**' success
      'runners/a.spec.sh' 'runners/**' success
      'scripts/a.sh' 'scripts/*.sh' success
    End

    It "Then: [Normal] T-RUN-PMG-01: $1 は $2 に所有される"
      When call path_matches_glob "$1" "$2"
      The status should be "$3"
    End
  End

  Describe 'When: エッジケース'
    Parameters
      'scripts/libs/a.sh' 'scripts/*.sh' failure
      'other/runners/a.spec.sh' 'runners/**' failure
      'runners/a.sh.bak' 'runners/*.sh' failure
      'runnersX/a.spec.sh' 'runners/**' failure
      'runners/aXsh' 'runners/a.sh' failure
    End

    It "Then: [Edge] T-RUN-PMG-02: $1 は $2 に所有されない"
      When call path_matches_glob "$1" "$2"
      The status should be "$3"
    End
  End
End

#
# メモ化した読み取り結果とスクラッチ配列を破棄し、次の例に前回の値を持ち越させない
#
Describe 'T-RUN-RCC: reset_check_caches()'
  #
  # @description 前のフィクスチャから値を持ち越した状態を、破棄対象の全変数に作る
  # @sideeffect メモ化キャッシュ 4 本・インデックス 6 本・有効性フラグ付きキャッシュ 5 本・
  #   スクラッチ配列 9 本・スクラッチスカラー 2 本、reset_check_caches が破棄する全 26 本を上書きする。
  #   値は「空でない」ことだけを満たす簡略形で、本番が積むレコード書式とは別物
  # @exitcode 0 always
  #
  _seed_stale_caches() {
    _MODULE_SCALAR_CACHE=(['scope'$'\037''/stale/module.md']='STA')
    _MODULE_OWNS_CACHE=(['/stale/module.md']='stale/**')
    _MODULE_TARGETS_CACHE=(['/stale/module.md']='AA')
    _GLOB_REGEX_CACHE=(['stale/**']='^stale/.*$')
    _GROUP_IDS_BY_FILE=(['/stale/a.spec.sh']='T-STA-AA')
    _GROUP_FILES_BY_ID=(['T-STA-AA']='/stale/a.spec.sh')
    _CASE_IDS_BY_FILE=(['/stale/a.spec.sh']='T-STA-AA-01')
    _CASE_FILES_BY_ID=(['T-STA-AA-01']='/stale/a.spec.sh')
    _CASE_GROUP_BY_RECORD=(['/stale/a.spec.sh']='x')
    _UNIDENT_BY_FILE=(['/stale/a.spec.sh']='x')
    _SPEC_FILES_CACHE='stale/a.spec.sh'
    _SPEC_FILES_CACHE_ROOT='/stale'
    _SPEC_FILES_CACHE_VALID=1
    _SPEC_RECORDS_ROOT='/stale'
    _SPEC_RECORDS_VALID=1
    _MODULE_OWNS_GLOBS=('stale/**')
    _SPEC_FILES=('stale/a.spec.sh')
    _OWNERS=('stale/module.md')
    _GROUP_IDS=('T-STA-AA')
    _CASE_IDS=('T-STA-AA-01')
    _CASE_GROUP_RECORDS=('stale')
    _UNIDENT_RECORDS=('stale')
    _DISTINCT_IDS=('T-STA-AA-01')
    _DUPLICATE_IDS=('T-STA-AA-01')
    _MODULE_REF='stale/ref'
    _MODULE_FILE='/stale/ref/module.md'
  }

  Describe 'When: 正常系'
    It 'Then: [Normal] T-RUN-RCC-01: スクラッチ配列とインデックスをすべて空にする'
      # フィクスチャを作り直す例の間で前回の読み取り結果が残るのを防ぐ
      _seed_stale_caches
      When call reset_check_caches
      The status should be success
      The value "${#_MODULE_SCALAR_CACHE[@]}" should equal 0
      The value "${#_MODULE_OWNS_CACHE[@]}" should equal 0
      The value "${#_MODULE_TARGETS_CACHE[@]}" should equal 0
      The value "${#_GLOB_REGEX_CACHE[@]}" should equal 0
      The value "${#_GROUP_IDS_BY_FILE[@]}" should equal 0
      The value "${#_GROUP_FILES_BY_ID[@]}" should equal 0
      The value "${#_CASE_IDS_BY_FILE[@]}" should equal 0
      The value "${#_CASE_FILES_BY_ID[@]}" should equal 0
      The value "${#_CASE_GROUP_BY_RECORD[@]}" should equal 0
      The value "${#_UNIDENT_BY_FILE[@]}" should equal 0
      The value "$_SPEC_FILES_CACHE" should equal ''
      The value "$_SPEC_FILES_CACHE_ROOT" should equal ''
      The value "$_SPEC_FILES_CACHE_VALID" should equal 0
      The value "$_SPEC_RECORDS_ROOT" should equal ''
      The value "$_SPEC_RECORDS_VALID" should equal 0
      The value "${#_MODULE_OWNS_GLOBS[@]}" should equal 0
      The value "${#_SPEC_FILES[@]}" should equal 0
      The value "${#_OWNERS[@]}" should equal 0
      The value "${#_GROUP_IDS[@]}" should equal 0
      The value "${#_CASE_IDS[@]}" should equal 0
      The value "${#_CASE_GROUP_RECORDS[@]}" should equal 0
      The value "${#_UNIDENT_RECORDS[@]}" should equal 0
      The value "${#_DISTINCT_IDS[@]}" should equal 0
      The value "${#_DUPLICATE_IDS[@]}" should equal 0
      The value "$_MODULE_REF" should equal ''
      The value "$_MODULE_FILE" should equal ''
    End

    # T-RUN-RCC-01 と対の同値類。あちらの入力は前のフィクスチャの値が残った
    # 汚れた状態で、こちらは変数がまだ一度も定義されていない状態。
    # reset は既存の値を読まずに代入するだけなので、set -u 下でも unbound に当たらない
    It 'Then: [Normal] T-RUN-RCC-02: 未定義のスクラッチ変数も set -u の下で空に定義し直す'
      unset _MODULE_REF _MODULE_FILE
      When call reset_check_caches
      The status should be success
      The value "$_MODULE_REF" should equal ''
      The value "$_MODULE_FILE" should equal ''
    End
  End
End

#
# spec ファイルを所有するモジュール宣言を subshell なしで _OWNERS に積む (§6.2)
#
Describe 'T-RUN-LOO: load_owners_of()'
  BeforeEach '_setup_fixture_repo'
  AfterEach '_teardown_fixture_repo'

  Describe 'When: 正常系'
    It 'Then: [Normal] T-RUN-LOO-01: owns に一致する spec の所有モジュールを _OWNERS に載せる'
      _add_module 'ns/alpha' 'ALP' 'alpha/**'
      _add_module 'ns/beta' 'BET' 'beta/**'
      When call load_owners_of 'alpha/a.spec.sh' \
        "${TEST_ID_CHECK_ROOT}/${_FIXTURE_DOCS_SUBDIR}/ns/alpha/${_FIXTURE_META_SUBDIR}/module.md" \
        "${TEST_ID_CHECK_ROOT}/${_FIXTURE_DOCS_SUBDIR}/ns/beta/${_FIXTURE_META_SUBDIR}/module.md"
      The status should be success
      The value "${#_OWNERS[@]}" should equal 1
      The variable '_OWNERS[0]' should equal "${TEST_ID_CHECK_ROOT}/${_FIXTURE_DOCS_SUBDIR}/ns/alpha/${_FIXTURE_META_SUBDIR}/module.md"
    End
  End

  Describe 'When: エッジケース'
    It 'Then: [Edge] T-RUN-LOO-02: どのモジュールにも一致しない spec では _OWNERS を空にする'
      _add_module 'ns/alpha' 'ALP' 'alpha/**'
      # 前回の呼び出しの結果が残った状態を再現する
      _OWNERS=('stale/module.md')
      When call load_owners_of 'gamma/c.spec.sh' \
        "${TEST_ID_CHECK_ROOT}/${_FIXTURE_DOCS_SUBDIR}/ns/alpha/${_FIXTURE_META_SUBDIR}/module.md"
      The status should be success
      The value "${#_OWNERS[@]}" should equal 0
    End
  End
End

#
# 全 spec を 1 回だけ走査し、その生レコードを 6 本のインデックスに振り分ける (§6.1)
#
Describe 'T-RUN-LCR: load_spec_records()'
  BeforeEach '_setup_fixture_repo'
  AfterEach '_teardown_fixture_repo'

  Describe 'When: 正常系'
    It 'Then: [Normal] T-RUN-LCR-01: 2 ファイルの ID をファイル別・出現順で _CASE_IDS_BY_FILE に積む'
      # ID をわざと降順に置く。実装が sort を挟んだ瞬間にこの例が落ちる
      _add_spec_file 'alpha/a.spec.sh' 'T-ALP-AA' 'T-ALP-AA-02' 'T-ALP-AA-01'
      _add_spec_file 'beta/b.spec.sh' 'T-BET-BB' 'T-BET-BB-01'
      When call load_spec_records
      The status should be success
      The value "${#_CASE_IDS_BY_FILE[@]}" should equal 2
      The value "${_CASE_IDS_BY_FILE["${TEST_ID_CHECK_ROOT}/alpha/a.spec.sh"]}" should equal $'T-ALP-AA-02\nT-ALP-AA-01\n'
      The value "${_CASE_IDS_BY_FILE["${TEST_ID_CHECK_ROOT}/beta/b.spec.sh"]}" should equal $'T-BET-BB-01\n'
    End

    It 'Then: [Normal] T-RUN-LCR-02: 同じ ID を採番した全ファイルを走査順・ファイル単位で重複なく _CASE_FILES_BY_ID に積む'
      # 同一ファイル内の 2 回目は逆引きには積まれず、ファイル別索引には残る
      _add_spec_file 'alpha/a.spec.sh' 'T-DUP-XX' 'T-DUP-XX-01' 'T-DUP-XX-01'
      _add_spec_file 'beta/b.spec.sh' 'T-DUP-XX' 'T-DUP-XX-01'
      When call load_spec_records
      The status should be success
      The value "${_CASE_FILES_BY_ID['T-DUP-XX-01']}" should equal "${TEST_ID_CHECK_ROOT}/alpha/a.spec.sh"$'\n'"${TEST_ID_CHECK_ROOT}/beta/b.spec.sh"$'\n'
      The value "${_CASE_IDS_BY_FILE["${TEST_ID_CHECK_ROOT}/alpha/a.spec.sh"]}" should equal $'T-DUP-XX-01\nT-DUP-XX-01\n'
    End

    It 'Then: [Normal] T-RUN-LCR-03: ID を採番しない宣言を file/line/content のまま _UNIDENT_BY_FILE に積む'
      # 1 行目がグループ宣言、2 行目が ID 付きなので、ID なし宣言の行番号は 3 になる。
      # 内容に TAB を埋めるのは、5 欄の先頭 4 欄をパラメータ展開で剥がす経路が
      # 最後の欄を丸ごと残すことの番人。d を最初の TAB で切り捨てると RED
      _add_spec_file 'alpha/a.spec.sh' 'T-ALP-AA' 'T-ALP-AA-01'
      _append_line 'alpha/a.spec.sh' "  It \"Then: [Normal] ID なし${_TAB}のケース\""
      When call load_spec_records
      The status should be success
      The value "${#_UNIDENT_BY_FILE[@]}" should equal 1
      The value "${_UNIDENT_BY_FILE["${TEST_ID_CHECK_ROOT}/alpha/a.spec.sh"]}" should equal "${TEST_ID_CHECK_ROOT}/alpha/a.spec.sh${_TAB}3${_TAB}  It \"Then: [Normal] ID なし${_TAB}のケース\""$'\n'
    End

    It 'Then: [Normal] T-RUN-LCR-08: グループ ID をファイル別・出現順で _GROUP_IDS_BY_FILE に積む'
      # 1 ファイルが 2 グループを降順に宣言する。実装が sort を挟んだ瞬間にこの例が落ちる
      _add_spec_file 'alpha/a.spec.sh' 'T-ALP-BB'
      _append_line 'alpha/a.spec.sh' '  Describe "T-ALP-AA: sample"'
      When call load_spec_records
      The status should be success
      The value "${#_GROUP_IDS_BY_FILE[@]}" should equal 1
      The value "${_GROUP_IDS_BY_FILE["${TEST_ID_CHECK_ROOT}/alpha/a.spec.sh"]}" should equal $'T-ALP-BB\nT-ALP-AA\n'
    End

    It 'Then: [Normal] T-RUN-LCR-09: 同じグループ ID を名乗る全ファイルを走査順・ファイル単位で重複なく _GROUP_FILES_BY_ID に積む'
      # 同一ファイル内の 2 回目は逆引きには積まれず、ファイル別索引には残る
      _add_spec_file 'alpha/a.spec.sh' 'T-DUP-XX'
      _append_line 'alpha/a.spec.sh' '  Describe "T-DUP-XX: sample"'
      _add_spec_file 'beta/b.spec.sh' 'T-DUP-XX'
      When call load_spec_records
      The status should be success
      The value "${_GROUP_FILES_BY_ID['T-DUP-XX']}" should equal "${TEST_ID_CHECK_ROOT}/alpha/a.spec.sh"$'\n'"${TEST_ID_CHECK_ROOT}/beta/b.spec.sh"$'\n'
      The value "${_GROUP_IDS_BY_FILE["${TEST_ID_CHECK_ROOT}/alpha/a.spec.sh"]}" should equal $'T-DUP-XX\nT-DUP-XX\n'
    End

    # ケース所属の違反 (§5.4) は file/line 付きで報告する必要があるため、
    # ケース ID と所属グループだけでなく採番元もレコードに残す
    It 'Then: [Normal] T-RUN-LCR-10: ケース ID・所属グループ・file・line を _CASE_GROUP_BY_RECORD に積む'
      _add_spec_file 'alpha/a.spec.sh' 'T-ALP-AA' 'T-ALP-AA-01'
      When call load_spec_records
      The status should be success
      The value "${#_CASE_GROUP_BY_RECORD[@]}" should equal 1
      The value "${_CASE_GROUP_BY_RECORD["${TEST_ID_CHECK_ROOT}/alpha/a.spec.sh"]}" should equal "T-ALP-AA-01${_TAB}T-ALP-AA${_TAB}${TEST_ID_CHECK_ROOT}/alpha/a.spec.sh${_TAB}2"$'\n'
    End

    It 'Then: [Normal] T-RUN-LCR-05: 同一ルートでの 2 回目の呼び出しはインデックスを再構築しない'
      _add_spec_file 'alpha/a.spec.sh' 'T-ALP-AA' 'T-ALP-AA-01'
      load_spec_records
      # 再構築されれば消える番人。ケース ID を名前に含め、他の例と衝突させない
      _CASE_IDS_BY_FILE['sentinel-T-RUN-LCR-05']='kept'
      _GROUP_IDS_BY_FILE['sentinel-T-RUN-LCR-05-group']='kept'
      When call load_spec_records
      The status should be success
      The value "${_CASE_IDS_BY_FILE['sentinel-T-RUN-LCR-05']}" should equal 'kept'
      # 有効性フラグは 6 本すべてを覆う。新インデックスだけ作り直す実装だと RED
      The value "${_GROUP_IDS_BY_FILE['sentinel-T-RUN-LCR-05-group']}" should equal 'kept'
      The value "${_CASE_IDS_BY_FILE["${TEST_ID_CHECK_ROOT}/alpha/a.spec.sh"]}" should equal $'T-ALP-AA-01\n'
    End
  End

  Describe 'When: 異常系'
    It 'Then: [Error] T-RUN-LCR-06: 列挙後に読めなくなった spec は警告だけ出して索引に載せない'
      _add_spec_file 'alpha/a.spec.sh' 'T-ALP-AA' 'T-ALP-AA-01'
      _add_spec_file 'beta/b.spec.sh' 'T-BET-BB' 'T-BET-BB-01'
      # 先に一覧をキャッシュさせ、reset せずに実体だけ消す。こうすると
      # 一覧に載っているのに読めないファイルという状態を作れる
      load_spec_files
      rm "${TEST_ID_CHECK_ROOT}/beta/b.spec.sh"
      When call load_spec_records
      The status should be success
      The stderr should include 'cannot read'
      The value "${#_CASE_IDS_BY_FILE[@]}" should equal 1
      The value "${_CASE_IDS_BY_FILE["${TEST_ID_CHECK_ROOT}/alpha/a.spec.sh"]}" should equal $'T-ALP-AA-01\n'
      The value "${_CASE_IDS_BY_FILE["${TEST_ID_CHECK_ROOT}/beta/b.spec.sh"]+set}" should equal ''
      The value "${#_GROUP_IDS_BY_FILE[@]}" should equal 1
      The value "${_GROUP_IDS_BY_FILE["${TEST_ID_CHECK_ROOT}/beta/b.spec.sh"]+set}" should equal ''
    End
  End

  Describe 'When: エッジケース'
    It 'Then: [Edge] T-RUN-LCR-04: 走査ルートを張り替えると前フィクスチャの内容が残らない'
      _add_spec_file 'alpha/a.spec.sh' 'T-OLD-AA' 'T-OLD-AA-01'
      load_spec_records
      # _setup_fixture_repo は mktemp -d で別のルートを作って TEST_ID_CHECK_ROOT を
      # そちらへ向けるため、AfterEach は新ルートしか消せない。旧ルートを残さないよう
      # 張り替えの前にここで片付ける
      _teardown_fixture_repo
      _setup_fixture_repo
      _add_spec_file 'gamma/c.spec.sh' 'T-NEW-CC' 'T-NEW-CC-01'
      When call load_spec_records
      The status should be success
      The value "${#_CASE_IDS_BY_FILE[@]}" should equal 1
      The value "${_CASE_IDS_BY_FILE["${TEST_ID_CHECK_ROOT}/gamma/c.spec.sh"]}" should equal $'T-NEW-CC-01\n'
      The value "${_CASE_FILES_BY_ID['T-OLD-AA-01']+set}" should equal ''
      The value "${#_GROUP_IDS_BY_FILE[@]}" should equal 1
      The value "${_GROUP_FILES_BY_ID['T-OLD-AA']+set}" should equal ''
    End

    # グループ宣言より前のケースは所属グループを持たない。レコードを捨てずに
    # group 欄を空のまま積むことで、所属違反 (§5.4) の報告元がここに残る
    It 'Then: [Edge] T-RUN-LCR-11: グループ外のケースは group 欄を空にして _CASE_GROUP_BY_RECORD に積む'
      _add_spec_file 'alpha/a.spec.sh' '' 'T-ALP-AA-01'
      When call load_spec_records
      The status should be success
      The value "${_CASE_GROUP_BY_RECORD["${TEST_ID_CHECK_ROOT}/alpha/a.spec.sh"]}" should equal "T-ALP-AA-01${_TAB}${_TAB}${TEST_ID_CHECK_ROOT}/alpha/a.spec.sh${_TAB}1"$'\n'
    End
  End
End

#
# 指定 ID を採番した spec ファイルの所在を逆引きインデックスから引く (§6.3)
#
Describe 'T-RUN-LCI: locate_case_id()'
  BeforeEach '_setup_fixture_repo'
  AfterEach '_teardown_fixture_repo'

  Describe 'When: 正常系'
    It 'Then: [Normal] T-RUN-LCI-01: 採番したファイルだけを走査順ではなく引数順に出す'
      _add_spec_file 'alpha/a.spec.sh' 'T-ALP-AA' 'T-ALP-AA-01'
      _add_spec_file 'alpha/b.spec.sh' 'T-ALP-BB' 'T-ALP-BB-01'
      _add_spec_file 'alpha/c.spec.sh' 'T-ALP-AA' 'T-ALP-AA-01'
      # 走査順は a→b→c。引数を c→b→a で渡し、出力が引数順に並ぶことを固定する。
      # 呼び出し元 (検査 B / C) は所有ファイルの並び順で所在を読ませている
      When call locate_case_id 'T-ALP-AA-01' \
        "${TEST_ID_CHECK_ROOT}/alpha/c.spec.sh" \
        "${TEST_ID_CHECK_ROOT}/alpha/b.spec.sh" \
        "${TEST_ID_CHECK_ROOT}/alpha/a.spec.sh"
      The status should be success
      The output should equal "${TEST_ID_CHECK_ROOT}/alpha/c.spec.sh"$'\n'"${TEST_ID_CHECK_ROOT}/alpha/a.spec.sh"
    End

    It 'Then: [Normal] T-RUN-LCI-02: 同じ ID を 2 回採番したファイルも 1 行だけ出す'
      _add_spec_file 'alpha/a.spec.sh' 'T-ALP-AA' 'T-ALP-AA-01' 'T-ALP-AA-01'
      # should include では 2 行出ても通るため、行数ごと固定する
      When call locate_case_id 'T-ALP-AA-01' "${TEST_ID_CHECK_ROOT}/alpha/a.spec.sh"
      The status should be success
      The output should equal "${TEST_ID_CHECK_ROOT}/alpha/a.spec.sh"
    End
  End

  Describe 'When: エッジケース'
    It 'Then: [Edge] T-RUN-LCI-03: ID を前置トークンの一部に含むだけのファイルは所在にしない'
      _add_spec_file 'alpha/a.spec.sh' 'T-AAA-BB' 'T-AAA-BB-01'
      _add_spec_file 'alpha/b.spec.sh' 'XT-AAA-BB' 'XT-AAA-BB-01'
      # 採番側 (T-RUN-ECI-05) は XT-AAA-BB-01 を T-AAA-BB-01 の採番として扱わない。
      # 所在報告も同じトークナイザの判定に揃え、grep 版が前置トークンに一致していた
      # 差をここで閉じる
      When call locate_case_id 'T-AAA-BB-01' \
        "${TEST_ID_CHECK_ROOT}/alpha/a.spec.sh" \
        "${TEST_ID_CHECK_ROOT}/alpha/b.spec.sh"
      The status should be success
      The output should equal "${TEST_ID_CHECK_ROOT}/alpha/a.spec.sh"
    End
  End
End

#
# 検査 A: scope 一意性と所有網羅性 (§6.2)
#
Describe 'T-RUN-CS: check_scopes()'
  BeforeEach '_setup_fixture_repo'
  AfterEach '_teardown_fixture_repo'

  #
  # @description 2 モジュールがそれぞれ 1 ファイルを所有する健全な擬似リポジトリを作る
  # @exitcode 0 always
  #
  _setup_well_formed_repo() {
    _add_module 'ns/alpha' 'ALP' 'alpha/**'
    _add_module 'ns/beta' 'BET' 'beta/**'
    _add_spec_file 'alpha/a.spec.sh' 'T-ALP-AA' 'T-ALP-AA-01'
    _add_spec_file 'beta/b.spec.sh' 'T-BET-BB' 'T-BET-BB-01'
  }

  Describe 'When: 正常系'
    It 'Then: [Normal] T-RUN-CS-01: 健全な擬似リポジトリは通り、検査した件数を出力する'
      _setup_well_formed_repo
      When call check_scopes
      The status should be success
      The output should include '2'
      The stderr should equal ''
    End

    It 'Then: [Normal] T-RUN-CS-09: 長さの下限 2 文字と上限 4 文字の test_scope を通す'
      _add_module 'ns/alpha' 'AB' 'alpha/**'
      _add_module 'ns/beta' 'ABCD' 'beta/**'
      _add_spec_file 'alpha/a.spec.sh' 'T-AB-AA' 'T-AB-AA-01'
      _add_spec_file 'beta/b.spec.sh' 'T-ABCD-BB' 'T-ABCD-BB-01'
      When call check_scopes
      The status should be success
      The output should include '2'
      The stderr should equal ''
    End
  End

  Describe 'When: 異常系'
    It 'Then: [Error] T-RUN-CS-02: test_scope の重複を報告する'
      _add_module 'ns/alpha' 'DUP' 'alpha/**'
      _add_module 'ns/beta' 'DUP' 'beta/**'
      _add_spec_file 'alpha/a.spec.sh' 'T-DUP-AA' 'T-DUP-AA-01'
      _add_spec_file 'beta/b.spec.sh' 'T-DUP-BB' 'T-DUP-BB-01'
      When call check_scopes
      The status should be failure
      The stderr should include 'DUP'
      The stderr should include "ns/alpha/${_FIXTURE_META_SUBDIR}/module.md"
      The stderr should include "ns/beta/${_FIXTURE_META_SUBDIR}/module.md"
      The output should equal ''
    End

    It 'Then: [Error] T-RUN-CS-03: どのモジュールにも所有されないテストファイルを報告する'
      _setup_well_formed_repo
      _add_spec_file 'orphan/x.spec.sh' 'T-ALP-XX' 'T-ALP-XX-01'
      When call check_scopes
      The status should be failure
      The stderr should include 'orphan/x.spec.sh'
      The output should equal ''
    End

    It 'Then: [Error] T-RUN-CS-04: 2 つのモジュールに所有されるテストファイルを報告する'
      _add_module 'ns/alpha' 'ALP' 'shared/**'
      _add_module 'ns/beta' 'BET' 'shared/*.spec.sh'
      _add_spec_file 'shared/a.spec.sh' 'T-ALP-AA' 'T-ALP-AA-01'
      When call check_scopes
      The status should be failure
      The stderr should include 'shared/a.spec.sh'
      The stderr should include "ns/alpha/${_FIXTURE_META_SUBDIR}/module.md"
      The stderr should include "ns/beta/${_FIXTURE_META_SUBDIR}/module.md"
      The output should equal ''
    End

    It 'Then: [Error] T-RUN-CS-05: 5 文字の test_scope を宣言したモジュールを報告する'
      _add_module 'ns/alpha' 'TOOLONG' 'alpha/**'
      _add_spec_file 'alpha/a.spec.sh' 'T-ALP-AA' 'T-ALP-AA-01'
      When call check_scopes
      The status should be failure
      The stderr should include "ns/alpha/${_FIXTURE_META_SUBDIR}/module.md"
      The stderr should include 'TOOLONG'
      The output should equal ''
    End

    It 'Then: [Error] T-RUN-CS-06: 1 文字の test_scope を宣言したモジュールを報告する'
      # 引用符付きで宣言しても read_module_scalar が外すので、値は 1 文字の A になる
      _add_module 'ns/alpha' '"A"' 'alpha/**'
      _add_spec_file 'alpha/a.spec.sh' 'T-ALP-AA' 'T-ALP-AA-01'
      When call check_scopes
      The status should be failure
      The stderr should include "ns/alpha/${_FIXTURE_META_SUBDIR}/module.md"
      The stderr should include "test_scope 'A'"
      The output should equal ''
    End

    It 'Then: [Error] T-RUN-CS-07: 空の引用符ペアを宣言したモジュールを報告する'
      # read_module_scalar は空の引用符ペアを未宣言と区別するため引用符を残す
      _add_module 'ns/alpha' '""' 'alpha/**'
      _add_spec_file 'alpha/a.spec.sh' 'T-ALP-AA' 'T-ALP-AA-01'
      When call check_scopes
      The status should be failure
      The stderr should include "ns/alpha/${_FIXTURE_META_SUBDIR}/module.md"
      The stderr should include 'test_scope'
      The output should equal ''
    End

    It 'Then: [Error] T-RUN-CS-08: 書式違反の test_scope は重複としては報告しない'
      _add_module 'ns/alpha' 'TOOLONG' 'alpha/**'
      _add_module 'ns/beta' 'TOOLONG' 'beta/**'
      _add_spec_file 'alpha/a.spec.sh' 'T-ALP-AA' 'T-ALP-AA-01'
      _add_spec_file 'beta/b.spec.sh' 'T-BET-BB' 'T-BET-BB-01'
      When call check_scopes
      The status should be failure
      The stderr should include "ns/alpha/${_FIXTURE_META_SUBDIR}/module.md"
      The stderr should include "ns/beta/${_FIXTURE_META_SUBDIR}/module.md"
      The stderr should not include 'more than one module'
      The output should equal ''
    End

    # 宣言の正典パスはモジュールの workspaces/modules/ 配下であり、モジュール直下に
    # 残った module.md は移行し損ねた残骸である。list_module_files が拾わなくなった分、
    # 検査 A が名指ししないと、実体と食い違った test_scope や owns が黙って残り続ける。
    # 期待値は絶対パスで書く。相対の 'ns/alpha/module.md' は正典パスの部分文字列ではなく、
    # 逆に正典パスを含む文字列で照合すると残骸を報告しない実装でも通ってしまう
    It 'Then: [Error] T-RUN-CS-10: モジュール直下の旧位置に残った module.md を報告する'
      _setup_well_formed_repo
      _append_line "${_FIXTURE_DOCS_SUBDIR}/ns/alpha/module.md" '---'
      When call check_scopes
      The status should be failure
      The stderr should include "${TEST_ID_CHECK_ROOT}/${_FIXTURE_DOCS_SUBDIR}/ns/alpha/module.md"
      The output should equal ''
    End
  End
End

#
# 検査 B: ID 付与網羅性・ケース所属・連番・scope 整合性 (§6.3)
# 走査範囲はそのモジュールの owns 配下だけ
#
Describe 'T-RUN-CM: check_module()'
  BeforeEach '_setup_fixture_repo'
  AfterEach '_teardown_fixture_repo'

  Describe 'When: 正常系'
    It 'Then: [Normal] T-RUN-CM-01: 重複も scope 違反も無いモジュールは通り、件数を出力する'
      _add_module 'ns/alpha' 'ALP' 'alpha/**'
      _add_spec_file 'alpha/a.spec.sh' 'T-ALP-AA' 'T-ALP-AA-01' 'T-ALP-AA-02'
      _add_spec_file 'alpha/b.spec.sh' 'T-ALP-BB' 'T-ALP-BB-01'
      When call check_module 'ns/alpha'
      The status should be success
      The output should include '3'
      The stderr should equal ''
    End

    It 'Then: [Normal] T-RUN-CM-02: 他モジュールが所有する ID は検査対象に含めない'
      _add_module 'ns/alpha' 'ALP' 'alpha/**'
      _add_module 'ns/beta' 'BET' 'beta/**'
      _add_spec_file 'alpha/a.spec.sh' 'T-ALP-AA' 'T-ALP-AA-01'
      _add_spec_file 'beta/b.spec.sh' 'T-BET-BB' 'T-BET-BB-01'
      When call check_module 'ns/alpha'
      The status should be success
      The output should include '1'
      The stderr should equal ''
    End
  End

  Describe 'When: 異常系'
    It 'Then: [Error] T-RUN-CM-03: モジュール内の ID 重複を報告する'
      _add_module 'ns/alpha' 'ALP' 'alpha/**'
      _add_spec_file 'alpha/a.spec.sh' 'T-ALP-AA' 'T-ALP-AA-01'
      _add_spec_file 'alpha/b.spec.sh' 'T-ALP-AA' 'T-ALP-AA-01'
      When call check_module 'ns/alpha'
      The status should be failure
      The stderr should include 'T-ALP-AA-01'
      The stderr should include 'alpha/a.spec.sh'
      The stderr should include 'alpha/b.spec.sh'
    End

    It 'Then: [Error] T-RUN-CM-04: 同一ファイル内の ID 重複を報告する'
      _add_module 'ns/alpha' 'ALP' 'alpha/**'
      _add_spec_file 'alpha/a.spec.sh' 'T-ALP-AA' 'T-ALP-AA-01' 'T-ALP-AA-01'
      When call check_module 'ns/alpha'
      The status should be failure
      The stderr should include 'T-ALP-AA-01'
    End

    It 'Then: [Error] T-RUN-CM-05: 他モジュールの scope を騙る ID を報告する'
      _add_module 'ns/alpha' 'ALP' 'alpha/**'
      _add_module 'ns/beta' 'BET' 'beta/**'
      _add_spec_file 'alpha/a.spec.sh' 'T-BET-AA' 'T-BET-AA-01'
      When call check_module 'ns/alpha'
      The status should be failure
      The stderr should include "group ID 'T-BET-AA'"
      The stderr should include 'ALP'
      The stderr should include 'alpha/a.spec.sh'
    End

    It 'Then: [Error] T-RUN-CM-06: 宣言の無いモジュール参照は失敗する'
      _add_module 'ns/alpha' 'ALP' 'alpha/**'
      When call check_module 'ns/missing'
      The status should be failure
      The stderr should include 'ns/missing'
    End

    # T-RUN-CM-06 と分担する。あちらは参照が報告に現れることだけを見るので、
    # 解決先パスの綴りを素通しする。その綴りを完全一致で固定するのがここで、
    # 末尾の改行は chomp されて見えないので T-RUN-CT-11 が行数で受け持つ
    It 'Then: [Error] T-RUN-CM-15: 宣言の無い参照の報告に解決先パスを完全一致で載せる'
      _add_module 'ns/alpha' 'ALP' 'alpha/**'
      When call check_module 'ns/missing'
      The status should be failure
      The stderr should equal "Error: module 'ns/missing': declaration not found at ${TEST_ID_CHECK_ROOT}/${_FIXTURE_DOCS_SUBDIR}/ns/missing/${_FIXTURE_META_SUBDIR}/module.md"
    End

    # T-RUN-CT-10 が見るのは略語の集合が呼び出しをまたいで残らないこと。
    # ここが見るのは解決先パスのスクラッチ変数で、未設定のときだけ書くような
    # 条件付きの更新にすると、2 回目の報告が 1 回目の ns/alpha のパスを名乗る
    It 'Then: [Error] T-RUN-CM-16: 続けて呼んでも前回のモジュールの解決先パスを引き継がない'
      _add_module 'ns/alpha' 'ALP' 'alpha/**'
      _add_spec_file 'alpha/a.spec.sh' 'T-ALP-AA' 'T-ALP-AA-01'
      # 1 回目の呼び出しは前提条件の一部であり、検証するのは 2 回目だけ (T-RUN-CT-10 と同じ形)
      check_module 'ns/alpha' >/dev/null 2>&1 || true
      When call check_module 'ns/missing'
      The status should be failure
      The stderr should include "ns/missing/${_FIXTURE_META_SUBDIR}/module.md"
      The stderr should not include 'ns/alpha'
    End

    It 'Then: [Error] T-RUN-CM-08: ID の無いケース宣言を報告する'
      _add_module 'ns/alpha' 'ALP' 'alpha/**'
      _add_spec_file 'alpha/a.spec.sh' 'T-ALP-AA' 'T-ALP-AA-01'
      _append_line 'alpha/a.spec.sh' '  It "Then: [Normal] sample without id"'
      When call check_module 'ns/alpha'
      The status should be failure
      # ID 無しのケース宣言は _append_line が書いた 3 行目にある
      The stderr should include 'alpha/a.spec.sh:3'
    End

    It 'Then: [Error] T-RUN-CM-09: 書式違反の ID しか無い spec を報告する'
      _add_module 'ns/alpha' 'ALP' 'alpha/**'
      _add_spec_file 'alpha/a.spec.sh' 'T-TOOLONG-FOO' 'T-TOOLONG-FOO-01'
      When call check_module 'ns/alpha'
      The status should be failure
      The stderr should include 'alpha/a.spec.sh'
    End

    # 件数比較は抽出の並び順に依存しない (§6.1)。a の ID 列に BB-01 を挟むので、
    # 連結した並びでは AA-01 / BB-01 / AA-01 となり重複が隣接しない。重複の判定を
    # 隣接に頼る実装 (sort してから uniq -d) は、並べ方を 1 つ間違えるだけで
    # ここを黙って成功させる。T-RUN-CM-03 は 2 ファイルとも ID が 1 個ずつなので、
    # 連結順に関わらず重複が隣接し、この壊れ方を検出できない。
    # BB-01 は自分の Describe の下に置く。1 個目のグループの下に置くのは
    # 所属違反 (§5.4) であり、重複とは別の理由で失敗してしまう
    It 'Then: [Error] T-RUN-CM-10: 並びの上で隣接しない ID の重複も検出する'
      _add_module 'ns/alpha' 'ALP' 'alpha/**'
      _add_spec_file 'alpha/a.spec.sh' 'T-ALP-AA' 'T-ALP-AA-01'
      _append_line 'alpha/a.spec.sh' '  Describe "T-ALP-BB: sample"'
      _append_line 'alpha/a.spec.sh' '  It "Then: [Normal] T-ALP-BB-01: sample"'
      _add_spec_file 'alpha/b.spec.sh' 'T-ALP-AA' 'T-ALP-AA-01'
      When call check_module 'ns/alpha'
      The status should be failure
      # グループ ID の重複も同時に報告されるため、ケース ID の側の文言ごと固定する
      The stderr should include "test ID 'T-ALP-AA-01' is assigned more than once"
      The stderr should include 'alpha/a.spec.sh'
      The stderr should include 'alpha/b.spec.sh'
    End

    # ケース所属 (§5.4)。グループ ID もケース ID も 1 回ずつしか現れないので、
    # 重複と scope だけを見る実装はこのフィクスチャを黙って通す
    It 'Then: [Error] T-RUN-CM-11: 直前のグループ ID と一致しないケース ID を報告する'
      _add_module 'ns/alpha' 'ALP' 'alpha/**'
      _add_spec_file 'alpha/a.spec.sh' 'T-ALP-AA' 'T-ALP-BB-01'
      When call check_module 'ns/alpha'
      The status should be failure
      The stderr should include "test ID 'T-ALP-BB-01'"
      The stderr should include "group ID 'T-ALP-AA'"
      # ケース宣言は _add_spec_file が書いた 2 行目にある
      The stderr should include 'alpha/a.spec.sh:2'
    End

    # どのグループにも属さないケースも所属違反 (§5.4)。所属先が空のときに
    # 検査を素通りさせる実装だと、グループ ID を 1 つも持たない spec が丸ごと無検査になる
    It 'Then: [Error] T-RUN-CM-12: グループ宣言より前に置かれたケース ID を報告する'
      _add_module 'ns/alpha' 'ALP' 'alpha/**'
      _add_spec_file 'alpha/a.spec.sh' '' 'T-ALP-AA-01'
      When call check_module 'ns/alpha'
      The status should be failure
      The stderr should include "test ID 'T-ALP-AA-01'"
      The stderr should include 'no group ID'
      # グループ宣言を書かないので、ケース宣言は 1 行目にある
      The stderr should include 'alpha/a.spec.sh:1'
    End

    # scope 整合性 (§5.4) はグループ ID で見る。ケースを 1 つも持たないグループは
    # ケース ID から scope を読む実装からは見えず、「ID が 0 件」の警告で素通りする
    It 'Then: [Error] T-RUN-CM-14: ケースを持たないグループの scope 違反も報告する'
      _add_module 'ns/alpha' 'ALP' 'alpha/**'
      _add_module 'ns/beta' 'BET' 'beta/**'
      _add_spec_file 'alpha/a.spec.sh' 'T-BET-AA'
      When call check_module 'ns/alpha'
      The status should be failure
      The stderr should include "group ID 'T-BET-AA'"
      The stderr should include 'ALP'
      The stderr should include 'alpha/a.spec.sh'
    End

    # 採番の単位はグループ ID なので、グループの一意性 (§5.4) は独立に検査する。
    # ケース ID は 2 つとも異なるため、ケース ID しか数えない実装はこれを黙って通す
    It 'Then: [Error] T-RUN-CM-13: モジュール内のグループ ID 重複を報告する'
      _add_module 'ns/alpha' 'ALP' 'alpha/**'
      _add_spec_file 'alpha/a.spec.sh' 'T-ALP-AA' 'T-ALP-AA-01'
      _add_spec_file 'alpha/b.spec.sh' 'T-ALP-AA' 'T-ALP-AA-02'
      When call check_module 'ns/alpha'
      The status should be failure
      The stderr should include "group ID 'T-ALP-AA'"
      The stderr should include 'alpha/a.spec.sh'
      The stderr should include 'alpha/b.spec.sh'
    End
  End

  Describe 'When: エッジケース'
    It 'Then: [Edge] T-RUN-CM-07: ID が 0 件なら走査件数付きの警告を出して成功する'
      _add_module 'ns/alpha' 'ALP' 'alpha/**'
      _add_spec_file 'alpha/a.spec.sh' ''
      _add_spec_file 'alpha/b.spec.sh' ''
      When call check_module 'ns/alpha'
      The status should be success
      The stderr should include '2'
      The stderr should include '0'
      The output should equal ''
    End
  End
End

#
# 検査 C: リポジトリ全体のグループ ID 重複 (§6.4)
# ケース ID の全件照合はしない。グループ ID の一意性と検査 B からそれが従う
#
Describe 'T-RUN-CD: check_duplicates()'
  BeforeEach '_setup_fixture_repo'
  AfterEach '_teardown_fixture_repo'

  Describe 'When: 正常系'
    It 'Then: [Normal] T-RUN-CD-01: 重複が無ければ通り、走査件数と ID 件数を出力する'
      _add_module 'ns/alpha' 'ALP' 'alpha/**'
      _add_module 'ns/beta' 'BET' 'beta/**'
      _add_spec_file 'alpha/a.spec.sh' 'T-ALP-AA' 'T-ALP-AA-01'
      _add_spec_file 'beta/b.spec.sh' 'T-BET-BB' 'T-BET-BB-01'
      When call check_duplicates
      The status should be success
      The output should include '2'
      The stderr should equal ''
    End
  End

  Describe 'When: 異常系'
    # 照合するのは採番の単位であるグループ ID だけ (§6.4)。連番は 2 ファイルで
    # 食い違っているので、ケース ID を全件照合する実装はこの衝突を見落とす
    It 'Then: [Error] T-RUN-CD-02: モジュールをまたぐグループ ID の重複を報告する'
      _add_module 'ns/alpha' 'ALP' 'alpha/**'
      _add_module 'ns/beta' 'BET' 'beta/**'
      _add_spec_file 'alpha/a.spec.sh' 'T-ALP-AA' 'T-ALP-AA-01'
      _add_spec_file 'beta/b.spec.sh' 'T-ALP-AA' 'T-ALP-AA-02'
      When call check_duplicates
      The status should be failure
      The stderr should include "group ID 'T-ALP-AA'"
      The stderr should include 'alpha/a.spec.sh'
      The stderr should include 'beta/b.spec.sh'
    End
  End

  Describe 'When: エッジケース'
    # 走査対象が 1 本も無いのは抽出の破損ではない。T-RUN-CD-03 と対になり、
    # 「グループ ID が 0 件」だけを失格条件にした実装をここが落とす
    It 'Then: [Edge] T-RUN-CD-05: spec が 1 本も無ければ 0 件のまま成功する'
      _add_module 'ns/alpha' 'ALP' 'alpha/**'
      When call check_duplicates
      The status should be success
      The output should include '0 spec files'
      The output should include '0 group IDs'
      The stderr should equal ''
    End

    # spec があるのにグループ ID が 1 つも取れないのは抽出が壊れた状態であり、
    # 合格にすると重複が 0 件という報告と区別が付かなくなる (§6.1)
    It 'Then: [Edge] T-RUN-CD-03: spec があるのにグループ ID が 0 件なら失敗する'
      _add_module 'ns/alpha' 'ALP' 'alpha/**'
      _add_spec_file 'alpha/a.spec.sh' ''
      _add_spec_file 'alpha/b.spec.sh' ''
      When call check_duplicates
      The status should be failure
      The stderr should include '2 spec files'
      The stderr should include '0 group IDs'
      The output should equal ''
    End
  End
End
#
# 宣言済みのグループ ID から略語の集合を導く (§6.5)
# 略語は綴りのまま数え、配置ディレクトリから推測したレイヤ文字を切り離さない (§5.1)
#
Describe 'T-RUN-BT: base_targets()'
  BeforeEach '_setup_fixture_repo'
  AfterEach '_teardown_fixture_repo'

  Describe 'When: 正常系'
    # 略語を数える単位はグループ (§6.5)。ケースを 1 つも持たないグループも
    # 略語を使っているので、ケース ID から取り出す実装はこれを取りこぼす
    It 'Then: [Normal] T-RUN-BT-01: グループ宣言の第 2 セグメントを略語として出す'
      _add_spec_file 'alpha/__tests__/unit/a.spec.sh' 'T-ALP-AA'
      _append_line 'alpha/__tests__/unit/a.spec.sh' '  Describe "T-ALP-BB: sample"'
      When call base_targets "${TEST_ID_CHECK_ROOT}/alpha/__tests__/unit/a.spec.sh"
      The status should be success
      The line 1 of output should equal 'AA'
      The line 2 of output should equal 'BB'
    End

    # T-RUN-BT-01 と対。グループ宣言を持たない spec のケース ID は、
    # どのグループにも属さない採番であり、略語の実体としては数えない
    It 'Then: [Normal] T-RUN-BT-06: ケース ID の第 2 セグメントは略語として数えない'
      _add_spec_file 'alpha/__tests__/unit/a.spec.sh' '' 'T-ALP-ZZ-01'
      When call base_targets "${TEST_ID_CHECK_ROOT}/alpha/__tests__/unit/a.spec.sh"
      The status should be success
      The output should equal ''
    End

    # レイヤは略語の綴りの一部であり、切り離さない (§5.1)。配置ディレクトリから
    # 推測した 1 文字を落とす実装だと 'AA' になって RED
    It 'Then: [Normal] T-RUN-BT-02: 非 unit の spec でもグループ ID の綴りをそのまま使う'
      _add_spec_file 'alpha/__tests__/integration/a.spec.sh' 'T-ALP-AAI' 'T-ALP-AAI-01'
      When call base_targets "${TEST_ID_CHECK_ROOT}/alpha/__tests__/integration/a.spec.sh"
      The output should equal 'AAI'
    End

    # 同一対象をレイヤごとに別の略語で検証する (§5.1) ので、略語表の行も 2 行になる
    It 'Then: [Normal] T-RUN-BT-03: レイヤをまたいで検証された対象はレイヤごとの略語で数える'
      _add_spec_file 'alpha/__tests__/unit/a.spec.sh' 'T-ALP-AA' 'T-ALP-AA-01'
      _add_spec_file 'alpha/__tests__/integration/a.spec.sh' 'T-ALP-AAI' 'T-ALP-AAI-01'
      When call base_targets \
        "${TEST_ID_CHECK_ROOT}/alpha/__tests__/unit/a.spec.sh" \
        "${TEST_ID_CHECK_ROOT}/alpha/__tests__/integration/a.spec.sh"
      The line 1 of output should equal 'AA'
      The line 2 of output should equal 'AAI'
      The lines of output should equal 2
    End
  End

  Describe 'When: エッジケース'
    # §5.1 の例そのもの。CINI は CIN + I ではなく 1 語であり、integration の階層に
    # 置かれていても綴りは変わらない
    It 'Then: [Edge] T-RUN-BT-04: レイヤ文字で終わる略語を 1 語として扱う'
      _add_spec_file 'alpha/__tests__/integration/a.spec.sh' 'T-ALP-CINI' 'T-ALP-CINI-01'
      When call base_targets "${TEST_ID_CHECK_ROOT}/alpha/__tests__/integration/a.spec.sh"
      The output should equal 'CINI'
    End

    It 'Then: [Edge] T-RUN-BT-05: 走査ルート外のファイルは略語を 1 つも寄与しない'
      # インデックス由来になったことによる契約の縮小を固定する。実運用では
      # check_targets が list_module_spec_files 由来の引数しか渡さないため差は出ない
      _outside_spec="$(mktemp)"
      printf '  %s "%s: sample"\n' 'Describe' 'T-OUT-ZZ' >"$_outside_spec"
      When call base_targets "$_outside_spec"
      The status should be success
      The output should equal ''
      # _teardown_fixture_repo は TEST_ID_CHECK_ROOT 配下しか消さない
      rm -f "$_outside_spec"
    End
  End
End

#
# 検査 D: 略語表と実体の一致 (§6.5)
#
Describe 'T-RUN-CT: check_targets()'
  BeforeEach '_setup_fixture_repo'
  AfterEach '_teardown_fixture_repo'

  Describe 'When: 正常系'
    It 'Then: [Normal] T-RUN-CT-01: 表と実体が一致するモジュールは通り、件数を出力する'
      _add_module 'ns/alpha' 'ALP' 'alpha/**'
      # レイヤごとに別の略語を割り当てる (§5.1) ので、表は AA と BBI の 2 行になる
      _add_targets_table 'ns/alpha' 'AA' 'BBI'
      _add_spec_file 'alpha/__tests__/unit/a.spec.sh' 'T-ALP-AA' 'T-ALP-AA-01'
      _add_spec_file 'alpha/__tests__/integration/b.spec.sh' 'T-ALP-BBI' 'T-ALP-BBI-01'
      When call check_targets 'ns/alpha'
      The status should be success
      The output should include '2'
      The stderr should equal ''
    End
  End

  Describe 'When: 異常系'
    It 'Then: [Error] T-RUN-CT-02: テストが使っているのに表に無い略語を報告する'
      _add_module 'ns/alpha' 'ALP' 'alpha/**'
      _add_targets_table 'ns/alpha' 'AA'
      # 2 個目のグループが自分の Describe を持つ形にする。1 個目のグループの下に
      # T-ALP-BB-01 を置くのは所属違反 (§5.4) であり、検査 B が別途落とす
      _add_spec_file 'alpha/__tests__/unit/a.spec.sh' 'T-ALP-AA' 'T-ALP-AA-01'
      _append_line 'alpha/__tests__/unit/a.spec.sh' '  Describe "T-ALP-BB: sample"'
      _append_line 'alpha/__tests__/unit/a.spec.sh' '  It "Then: [Normal] T-ALP-BB-01: sample"'
      When call check_targets 'ns/alpha'
      The status should be failure
      The stderr should include 'BB'
      The stderr should include 'ns/alpha'
      The output should equal ''
    End

    It 'Then: [Error] T-RUN-CT-03: 表にあるがどのテストも使っていない略語を報告する'
      _add_module 'ns/alpha' 'ALP' 'alpha/**'
      _add_targets_table 'ns/alpha' 'AA' 'ZZ'
      _add_spec_file 'alpha/__tests__/unit/a.spec.sh' 'T-ALP-AA' 'T-ALP-AA-01'
      When call check_targets 'ns/alpha'
      The status should be failure
      The stderr should include 'ZZ'
      The stderr should include 'ns/alpha'
      The output should equal ''
    End

    # 報告順は comm の昇順出力を引き継いだ外部仕様である。未記載が 2 件以上でも
    # 昇順 (AA -> ZZ) で並ぶことを固定し、集合演算の実装を差し替えても順序が
    # 入力順や連想配列の走査順に引きずられないようにする
    It 'Then: [Error] T-RUN-CT-06: 表に無い略語が複数あるとき昇順で報告する'
      _add_module 'ns/alpha' 'ALP' 'alpha/**'
      _add_targets_table 'ns/alpha' 'MM'
      _add_spec_file 'alpha/__tests__/unit/a.spec.sh' 'T-ALP-ZZ' 'T-ALP-ZZ-01'
      # 表に載っている MM は報告されず、AA と ZZ だけが未記載として残る
      _append_line 'alpha/__tests__/unit/a.spec.sh' '  Describe "T-ALP-AA: sample"'
      _append_line 'alpha/__tests__/unit/a.spec.sh' '  Describe "T-ALP-MM: sample"'
      When call check_targets 'ns/alpha'
      The status should be failure
      The line 1 of stderr should include 'AA'
      The line 2 of stderr should include 'ZZ'
      The lines of stderr should equal 2
    End

    # T-RUN-CT-06 と対。表の宣言順をわざと降順 (ZZ MM AA) にしてあるので、
    # declared 側の sort が外れると MM -> ZZ の順に並ばず落ちる
    It 'Then: [Error] T-RUN-CT-07: どのテストも使っていない略語が複数あるとき昇順で報告する'
      _add_module 'ns/alpha' 'ALP' 'alpha/**'
      _add_targets_table 'ns/alpha' 'ZZ' 'MM' 'AA'
      _add_spec_file 'alpha/__tests__/unit/a.spec.sh' 'T-ALP-AA' 'T-ALP-AA-01'
      When call check_targets 'ns/alpha'
      The status should be failure
      The line 1 of stderr should include 'MM'
      The line 2 of stderr should include 'ZZ'
      The lines of stderr should equal 2
    End

    # 未記載と未使用が同時に出るとき、群の順序は未記載が先で未使用が後になる。
    # 略語の昇順とは**逆向き**のフィクスチャにしてある (未記載 ZZ / 未使用 AA) ので、
    # 2 つの群を 1 本の昇順リストに混ぜる実装だと AA が先に出て落ちる。
    # 判別も略語ではなく文言で行う。略語だけでは群の境目を示せない
    It 'Then: [Error] T-RUN-CT-08: 未記載と未使用が同時にあるとき未記載を先に報告する'
      _add_module 'ns/alpha' 'ALP' 'alpha/**'
      _add_targets_table 'ns/alpha' 'AA'
      _add_spec_file 'alpha/__tests__/unit/a.spec.sh' 'T-ALP-ZZ' 'T-ALP-ZZ-01'
      When call check_targets 'ns/alpha'
      The status should be failure
      The line 1 of stderr should include 'is used by a test but is missing'
      The line 1 of stderr should include 'ZZ'
      The line 2 of stderr should include 'but no test uses it'
      The line 2 of stderr should include 'AA'
      The lines of stderr should equal 2
    End

    # 判定に使う集合が呼び出しをまたいで残ると、前のモジュールの宣言が次の判定を汚す。
    # ns/beta が使う AA は ns/alpha だけが宣言している略語なので、alpha の宣言が残ると
    # 「表に無い AA」が握りつぶされて報告は unused の 1 行に減る。2 行出ることが
    # 集合が呼び出しごとにリセットされている証拠であり、同時に群の順序も固定する
    It 'Then: [Error] T-RUN-CT-10: 続けて呼んでも前回のモジュールが宣言した略語を引き継がない'
      _add_module 'ns/alpha' 'ALP' 'alpha/**'
      _add_targets_table 'ns/alpha' 'AA'
      _add_spec_file 'alpha/__tests__/unit/a.spec.sh' 'T-ALP-AA' 'T-ALP-AA-01'
      _append_line 'alpha/__tests__/unit/a.spec.sh' '  Describe "T-ALP-BB: sample"'
      # ns/beta は宣言の無い AA を使い、宣言した XX はどのテストも使わない
      _add_module 'ns/beta' 'BET' 'beta/**'
      _add_targets_table 'ns/beta' 'XX'
      _add_spec_file 'beta/__tests__/unit/b.spec.sh' 'T-BET-AA' 'T-BET-AA-01'
      # 1 回目の呼び出しは前提条件の一部であり、検証するのは 2 回目だけ (T-RUN-BT-05 と同じ形)
      check_targets 'ns/alpha' 2>/dev/null || true
      When call check_targets 'ns/beta'
      The status should be failure
      The line 1 of stderr should include 'AA'
      The line 2 of stderr should include 'XX'
      The stderr should include 'ns/beta'
      The lines of stderr should equal 2
    End

    It 'Then: [Error] T-RUN-CT-05: 宣言の無いモジュール参照は失敗する'
      _add_module 'ns/alpha' 'ALP' 'alpha/**'
      When call check_targets 'ns/missing'
      The status should be failure
      The stderr should include 'ns/missing'
      The output should equal ''
    End

    # module_file_of は `$( )` の改行剥がしを失ったので、解決先パスに改行が
    # 残ると報告が 2 行になる。`The stderr` は末尾の改行をすべて落としてから
    # 比べるので、T-RUN-CT-05 も T-RUN-CM-15 の完全一致もこれを見られない。
    # chomp しない `entire stderr` の行数だけがそれを固定できる
    It 'Then: [Error] T-RUN-CT-11: 宣言の無い参照の報告を改行の無い 1 行で出す'
      _add_module 'ns/alpha' 'ALP' 'alpha/**'
      When call check_targets 'ns/missing'
      The status should be failure
      The lines of entire stderr should equal 1
      The stderr should equal "Error: module 'ns/missing': declaration not found at ${TEST_ID_CHECK_ROOT}/${_FIXTURE_DOCS_SUBDIR}/ns/missing/${_FIXTURE_META_SUBDIR}/module.md"
      The output should equal ''
    End
  End

  Describe 'When: エッジケース'
    It 'Then: [Edge] T-RUN-CT-04: 空の略語表はテストが使う略語をすべて未記載として報告する'
      _add_module 'ns/alpha' 'ALP' 'alpha/**'
      _add_targets_table 'ns/alpha'
      _add_spec_file 'alpha/__tests__/unit/a.spec.sh' 'T-ALP-AA' 'T-ALP-AA-01'
      When call check_targets 'ns/alpha'
      The status should be failure
      The stderr should include 'AA'
      # 空の表が空文字の略語として報告されないことも確かめる
      The lines of stderr should equal 1
    End

    # T-RUN-CT-04 と対の同値クラス。使う側も表も空なら報告は 1 行も出ず、
    # 0 要素の配列を展開しても set -u 下で落ちないことを固定する
    It 'Then: [Edge] T-RUN-CT-09: 空の略語表と spec ファイル 0 本は 0 件で通る'
      _add_module 'ns/alpha' 'ALP' 'alpha/**'
      _add_targets_table 'ns/alpha'
      When call check_targets 'ns/alpha'
      The status should be success
      The output should include '0 target abbreviations'
      The stderr should equal ''
    End
  End
End

#
# コマンドラインのモード振り分け
#
Describe 'T-RUN-MN: main()'
  BeforeEach '_setup_fixture_repo'
  AfterEach '_teardown_fixture_repo'

  Describe 'When: 正常系'
    It 'Then: [Normal] T-RUN-MN-01: --all は健全な擬似リポジトリで A・B・C・D をすべて通す'
      _add_module 'ns/alpha' 'ALP' 'alpha/**'
      _add_module 'ns/beta' 'BET' 'beta/**'
      _add_targets_table 'ns/alpha' 'AA'
      _add_targets_table 'ns/beta' 'BB'
      _add_spec_file 'alpha/a.spec.sh' 'T-ALP-AA' 'T-ALP-AA-01'
      _add_spec_file 'beta/b.spec.sh' 'T-BET-BB' 'T-BET-BB-01'
      When call main --all
      The status should be success
      The output should include 'check A'
      The output should include 'check B'
      The output should include 'check C'
      The output should include 'check D'
      The stderr should equal ''
    End

    It 'Then: [Normal] T-RUN-MN-07: --targets は指定したモジュールの検査 D を実行する'
      _add_module 'ns/alpha' 'ALP' 'alpha/**'
      _add_targets_table 'ns/alpha' 'AA'
      _add_spec_file 'alpha/a.spec.sh' 'T-ALP-AA' 'T-ALP-AA-01'
      When call main --targets 'ns/alpha'
      The status should be success
      The output should include 'check D'
      The stderr should equal ''
    End

    # 名前空間がスラッシュを含む宣言。module_ref_of は docs ルートを前から、
    # workspaces/modules/module.md を後ろから剥がすだけなので、間が何段でも参照は復元できる。
    # 末尾 2 段を <ns>/<mod> とみなす実装だと参照が 'sub/alpha' になり、
    # その参照から戻したパスに宣言が無くなって落ちる
    It 'Then: [Normal] T-RUN-MN-10: --all は多階層の名前空間を持つモジュールも検査する'
      _add_module 'ns/sub/alpha' 'ALP' 'alpha/**'
      _add_targets_table 'ns/sub/alpha' 'AA'
      _add_spec_file 'alpha/a.spec.sh' 'T-ALP-AA' 'T-ALP-AA-01'
      When call main --all
      The status should be success
      The output should include 'check D'
      The stderr should equal ''
    End
  End

  Describe 'When: 異常系'
    It 'Then: [Error] T-RUN-MN-02: --all は検査 A の失敗 (scope 重複) を報告する'
      _add_module 'ns/alpha' 'DUP' 'alpha/**'
      _add_module 'ns/beta' 'DUP' 'beta/**'
      _add_targets_table 'ns/alpha' 'AA'
      _add_spec_file 'alpha/a.spec.sh' 'T-DUP-AA' 'T-DUP-AA-01'
      When call main --all
      The status should be failure
      The stderr should include "test_scope 'DUP'"
      The stdout should be defined
    End

    It 'Then: [Error] T-RUN-MN-03: --all は検査 B の失敗 (他モジュールの scope を騙る ID) を報告する'
      _add_module 'ns/alpha' 'ALP' 'alpha/**'
      _add_module 'ns/beta' 'BET' 'beta/**'
      _add_targets_table 'ns/alpha' 'AA'
      _add_targets_table 'ns/beta' 'BB'
      _add_spec_file 'alpha/a.spec.sh' 'T-BET-AA' 'T-BET-AA-01'
      _add_spec_file 'beta/b.spec.sh' 'T-BET-BB' 'T-BET-BB-01'
      When call main --all
      The status should be failure
      The stderr should include "group ID 'T-BET-AA'"
      The stdout should be defined
    End

    It 'Then: [Error] T-RUN-MN-09: --all は検査 D の失敗 (表に無い略語) を報告する'
      _add_module 'ns/alpha' 'ALP' 'alpha/**'
      _add_targets_table 'ns/alpha'
      _add_spec_file 'alpha/a.spec.sh' 'T-ALP-AA' 'T-ALP-AA-01'
      When call main --all
      The status should be failure
      The stderr should include 'AA'
      The stdout should be defined
    End

    # T-RUN-MN-09 を 2 モジュールに広げた対。固定するのは check_repository のループの
    # 完全性で、--all が最初のモジュールで打ち切らず、全モジュールについて検査 D を
    # 報告すること。ループを 1 周目で break する変異を当てると、この example だけが落ちる。
    # T-RUN-MN-03 も 2 モジュールを作るが assert するのは 1 本目の指摘だけなのでその変異を通す
    It 'Then: [Error] T-RUN-MN-11: --all は 2 モジュール双方の検査 D の失敗を報告する'
      _add_module 'ns/alpha' 'ALP' 'alpha/**'
      _add_module 'ns/beta' 'BET' 'beta/**'
      # どちらも略語表が空なので、使っている略語がそのまま未記載として報告される
      _add_targets_table 'ns/alpha'
      _add_targets_table 'ns/beta'
      _add_spec_file 'alpha/a.spec.sh' 'T-ALP-AA' 'T-ALP-AA-01'
      _add_spec_file 'beta/b.spec.sh' 'T-BET-BB' 'T-BET-BB-01'
      When call main --all
      The status should be failure
      The stderr should include 'AA'
      The stderr should include 'BB'
      The stdout should be defined
    End

    It 'Then: [Error] T-RUN-MN-04: --module は引数が無ければ失敗する'
      When call main --module
      The status should be failure
      The stderr should include '--module'
    End

    It 'Then: [Error] T-RUN-MN-08: --targets は引数が無ければ失敗する'
      When call main --targets
      The status should be failure
      The stderr should include '--targets'
    End

    It 'Then: [Error] T-RUN-MN-05: 未知のモードは使い方を表示して失敗する'
      When call main --bogus
      The status should be failure
      The stderr should include 'Usage'
      The stderr should include '--targets'
    End

    It 'Then: [Error] T-RUN-MN-06: モードが無ければ使い方を表示して失敗する'
      When call main
      The status should be failure
      The stderr should include 'Usage'
    End
  End
End
