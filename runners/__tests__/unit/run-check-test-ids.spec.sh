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
# @description 擬似リポジトリに module.md を書き出す
# @arg $1 string モジュール参照 (<ns>/<mod>)
# @arg $2 string 宣言する test_scope
# @arg $@ string owns の glob (1 個以上)
# @exitcode 0 always
#
_add_module() {
  local ref="$1" scope="$2"
  shift 2
  local dir="${TEST_ID_CHECK_ROOT}/${_FIXTURE_DOCS_SUBDIR}/${ref}"
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
# @description ケース宣言行だけからなる spec ファイルを擬似リポジトリに書き出す
# @arg $1 string 走査ルートからの相対パス
# @arg $@ string 各ケースに割り当てるテストケース ID
# @exitcode 0 always
#
_add_spec_file() {
  local rel="$1"
  shift
  local path="${TEST_ID_CHECK_ROOT}/${rel}"
  mkdir -p "$(dirname "$path")"
  : >"$path"
  local id
  for id in "$@"; do
    # 'It' を引数として渡し、このファイル自身がケース宣言に見えないようにする
    printf '  %s "Then: [Normal] %s: sample"\n' 'It' "$id" >>"$path"
  done
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
# @description 擬似リポジトリの module.md に略語表 (§5.2) を追記する
# @arg $1 string モジュール参照 (<ns>/<mod>)
# @arg $@ string 表に載せるベース略語 (0 個以上)
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
  } >>"${TEST_ID_CHECK_ROOT}/${_FIXTURE_DOCS_SUBDIR}/${ref}/module.md"
}

# --- テスト本体 ---

#
# ケース宣言行に割り当てられたテストケース ID を抽出する (§6.1)
#
Describe 'extract_case_ids()'
  BeforeEach '_setup_fixture_repo'
  AfterEach '_teardown_fixture_repo'

  Describe 'When: 正常系'
    It 'Then: [Normal] T-RUN-ECI-01: ケース宣言行に書かれた ID をすべて出力する'
      _add_spec_file 'a.spec.sh' 'T-AAA-BB-01' 'T-AAA-BB-02'
      When call extract_case_ids "${TEST_ID_CHECK_ROOT}/a.spec.sh"
      The status should be success
      The line 1 of output should equal 'T-AAA-BB-01'
      The line 2 of output should equal 'T-AAA-BB-02'
    End

    It 'Then: [Normal] T-RUN-ECI-02: 枝番付きの ID も抽出する'
      _add_spec_file 'a.spec.sh' 'T-AAA-BB-03-01'
      When call extract_case_ids "${TEST_ID_CHECK_ROOT}/a.spec.sh"
      The output should equal 'T-AAA-BB-03-01'
    End
  End

  Describe 'When: エッジケース'
    It 'Then: [Edge] T-RUN-ECI-03: コメント行の ID は割り当てとして扱わない'
      _add_spec_file 'a.spec.sh' 'T-AAA-BB-01'
      _append_line 'a.spec.sh' '  # cross reference to T-AAA-BB-99'
      When call extract_case_ids "${TEST_ID_CHECK_ROOT}/a.spec.sh"
      The output should equal 'T-AAA-BB-01'
    End

    It 'Then: [Edge] T-RUN-ECI-04: 同一ファイル内の重複を一意化せずに残す'
      _add_spec_file 'a.spec.sh' 'T-AAA-BB-01' 'T-AAA-BB-01'
      When call extract_case_ids "${TEST_ID_CHECK_ROOT}/a.spec.sh"
      The lines of output should equal 2
    End

    It 'Then: [Edge] T-RUN-ECI-05: prefix の付いたトークンを ID と誤認しない'
      _add_spec_file 'a.spec.sh' 'XT-AAA-BB-01'
      When call extract_case_ids "${TEST_ID_CHECK_ROOT}/a.spec.sh"
      The output should equal ''
    End

    It 'Then: [Edge] T-RUN-ECI-06: ファイルを 1 つも渡されなければ何も出力しない'
      When call extract_case_ids
      The status should be success
      The output should equal ''
    End
  End
End

#
# module.md の frontmatter からモジュール宣言を読み出す (§5.2)
#
Describe 'module.md frontmatter reader'
  BeforeEach '_setup_fixture_repo'
  AfterEach '_teardown_fixture_repo'

  Describe 'When: 正常系'
    It 'Then: [Normal] T-RUN-FMR-01: read_module_scalar が宣言された test_scope を返す'
      _add_module 'ns/alpha' 'ALP' 'src/alpha/**'
      When call read_module_scalar "${TEST_ID_CHECK_ROOT}/${_FIXTURE_DOCS_SUBDIR}/ns/alpha/module.md" 'test_scope'
      The output should equal 'ALP'
    End

    It 'Then: [Normal] T-RUN-FMR-02: read_module_owns が owns の glob をすべて返す'
      _add_module 'ns/alpha' 'ALP' 'src/alpha/**' 'src/shared/*.sh'
      When call read_module_owns "${TEST_ID_CHECK_ROOT}/${_FIXTURE_DOCS_SUBDIR}/ns/alpha/module.md"
      The line 1 of output should equal 'src/alpha/**'
      The line 2 of output should equal 'src/shared/*.sh'
    End
  End

  Describe 'When: 異常系'
    It 'Then: [Error] T-RUN-FMR-03: 宣言されていないフィールドには空を返す'
      _add_module 'ns/alpha' 'ALP' 'src/alpha/**'
      When call read_module_scalar "${TEST_ID_CHECK_ROOT}/${_FIXTURE_DOCS_SUBDIR}/ns/alpha/module.md" 'nonexistent'
      The output should equal ''
    End
  End
End

#
# module.md の略語表からベース略語を読み出す (§5.2)
# 検査 D が実体と突き合わせる台帳側の入力を作る
#
Describe 'read_module_targets()'
  BeforeEach '_setup_fixture_repo'
  AfterEach '_teardown_fixture_repo'

  Describe 'When: 正常系'
    It 'Then: [Normal] T-RUN-RMT-01: 略語表の各行から略語を宣言順に取り出す'
      _add_module 'ns/alpha' 'ALP' 'alpha/**'
      _add_targets_table 'ns/alpha' 'AA' 'BB'
      When call read_module_targets "${TEST_ID_CHECK_ROOT}/${_FIXTURE_DOCS_SUBDIR}/ns/alpha/module.md"
      The line 1 of output should equal 'AA'
      The line 2 of output should equal 'BB'
    End

    It 'Then: [Normal] T-RUN-RMT-02: 見出し行と区切り行は略語として扱わない'
      _add_module 'ns/alpha' 'ALP' 'alpha/**'
      _add_targets_table 'ns/alpha' 'AA'
      When call read_module_targets "${TEST_ID_CHECK_ROOT}/${_FIXTURE_DOCS_SUBDIR}/ns/alpha/module.md"
      The lines of output should equal 1
    End
  End

  Describe 'When: エッジケース'
    It 'Then: [Edge] T-RUN-RMT-03: 略語表の見出しが無ければ何も読み出さない'
      _add_module 'ns/alpha' 'ALP' 'alpha/**'
      When call read_module_targets "${TEST_ID_CHECK_ROOT}/${_FIXTURE_DOCS_SUBDIR}/ns/alpha/module.md"
      The status should be success
      The output should equal ''
    End

    It 'Then: [Edge] T-RUN-RMT-04: 別の見出しの下に置かれた表は読み出さない'
      _add_module 'ns/alpha' 'ALP' 'alpha/**'
      _add_targets_table 'ns/alpha' 'AA'
      _append_line "${_FIXTURE_DOCS_SUBDIR}/ns/alpha/module.md" '## 別の見出し'
      _append_line "${_FIXTURE_DOCS_SUBDIR}/ns/alpha/module.md" '| 略語 | 対象 |'
      # shellcheck disable=SC2016
      _append_line "${_FIXTURE_DOCS_SUBDIR}/ns/alpha/module.md" '| `ZZ` | `other` |'
      When call read_module_targets "${TEST_ID_CHECK_ROOT}/${_FIXTURE_DOCS_SUBDIR}/ns/alpha/module.md"
      The output should equal 'AA'
    End
  End
End

#
# owns の glob とテストファイルパスの照合 (§5.2)
#
Describe 'path_matches_glob()'
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
# 検査 A: scope 一意性と所有網羅性 (§6.2)
#
Describe 'check_scopes()'
  BeforeEach '_setup_fixture_repo'
  AfterEach '_teardown_fixture_repo'

  #
  # @description 2 モジュールがそれぞれ 1 ファイルを所有する健全な擬似リポジトリを作る
  # @exitcode 0 always
  #
  _setup_well_formed_repo() {
    _add_module 'ns/alpha' 'ALP' 'alpha/**'
    _add_module 'ns/beta' 'BET' 'beta/**'
    _add_spec_file 'alpha/a.spec.sh' 'T-ALP-AA-01'
    _add_spec_file 'beta/b.spec.sh' 'T-BET-BB-01'
  }

  Describe 'When: 正常系'
    It 'Then: [Normal] T-RUN-CS-01: 健全な擬似リポジトリは通り、検査した件数を出力する'
      _setup_well_formed_repo
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
      _add_spec_file 'alpha/a.spec.sh' 'T-DUP-AA-01'
      _add_spec_file 'beta/b.spec.sh' 'T-DUP-BB-01'
      When call check_scopes
      The status should be failure
      The stderr should include 'DUP'
      The stderr should include 'ns/alpha/module.md'
      The stderr should include 'ns/beta/module.md'
      The output should equal ''
    End

    It 'Then: [Error] T-RUN-CS-03: どのモジュールにも所有されないテストファイルを報告する'
      _setup_well_formed_repo
      _add_spec_file 'orphan/x.spec.sh' 'T-ALP-XX-01'
      When call check_scopes
      The status should be failure
      The stderr should include 'orphan/x.spec.sh'
      The output should equal ''
    End

    It 'Then: [Error] T-RUN-CS-04: 2 つのモジュールに所有されるテストファイルを報告する'
      _add_module 'ns/alpha' 'ALP' 'shared/**'
      _add_module 'ns/beta' 'BET' 'shared/*.spec.sh'
      _add_spec_file 'shared/a.spec.sh' 'T-ALP-AA-01'
      When call check_scopes
      The status should be failure
      The stderr should include 'shared/a.spec.sh'
      The stderr should include 'ns/alpha/module.md'
      The stderr should include 'ns/beta/module.md'
      The output should equal ''
    End
  End
End

#
# 検査 B: モジュール内の重複と scope 整合性 (§6.3)
#
Describe 'check_module()'
  BeforeEach '_setup_fixture_repo'
  AfterEach '_teardown_fixture_repo'

  Describe 'When: 正常系'
    It 'Then: [Normal] T-RUN-CM-01: 重複も scope 違反も無いモジュールは通り、件数を出力する'
      _add_module 'ns/alpha' 'ALP' 'alpha/**'
      _add_spec_file 'alpha/a.spec.sh' 'T-ALP-AA-01' 'T-ALP-AA-02'
      _add_spec_file 'alpha/b.spec.sh' 'T-ALP-BB-01'
      When call check_module 'ns/alpha'
      The status should be success
      The output should include '3'
      The stderr should equal ''
    End

    It 'Then: [Normal] T-RUN-CM-02: 他モジュールが所有する ID は検査対象に含めない'
      _add_module 'ns/alpha' 'ALP' 'alpha/**'
      _add_module 'ns/beta' 'BET' 'beta/**'
      _add_spec_file 'alpha/a.spec.sh' 'T-ALP-AA-01'
      _add_spec_file 'beta/b.spec.sh' 'T-BET-BB-01'
      When call check_module 'ns/alpha'
      The status should be success
      The output should include '1'
      The stderr should equal ''
    End
  End

  Describe 'When: 異常系'
    It 'Then: [Error] T-RUN-CM-03: モジュール内の ID 重複を報告する'
      _add_module 'ns/alpha' 'ALP' 'alpha/**'
      _add_spec_file 'alpha/a.spec.sh' 'T-ALP-AA-01'
      _add_spec_file 'alpha/b.spec.sh' 'T-ALP-AA-01'
      When call check_module 'ns/alpha'
      The status should be failure
      The stderr should include 'T-ALP-AA-01'
      The stderr should include 'alpha/a.spec.sh'
      The stderr should include 'alpha/b.spec.sh'
    End

    It 'Then: [Error] T-RUN-CM-04: 同一ファイル内の ID 重複を報告する'
      _add_module 'ns/alpha' 'ALP' 'alpha/**'
      _add_spec_file 'alpha/a.spec.sh' 'T-ALP-AA-01' 'T-ALP-AA-01'
      When call check_module 'ns/alpha'
      The status should be failure
      The stderr should include 'T-ALP-AA-01'
    End

    It 'Then: [Error] T-RUN-CM-05: 他モジュールの scope を騙る ID を報告する'
      _add_module 'ns/alpha' 'ALP' 'alpha/**'
      _add_module 'ns/beta' 'BET' 'beta/**'
      _add_spec_file 'alpha/a.spec.sh' 'T-BET-AA-01'
      When call check_module 'ns/alpha'
      The status should be failure
      The stderr should include 'T-BET-AA-01'
      The stderr should include 'ALP'
      The stderr should include 'alpha/a.spec.sh'
    End

    It 'Then: [Error] T-RUN-CM-06: 宣言の無いモジュール参照は失敗する'
      _add_module 'ns/alpha' 'ALP' 'alpha/**'
      When call check_module 'ns/missing'
      The status should be failure
      The stderr should include 'ns/missing'
    End
  End

  Describe 'When: エッジケース'
    It 'Then: [Edge] T-RUN-CM-07: ID が 0 件なら走査件数付きの警告を出して成功する'
      _add_module 'ns/alpha' 'ALP' 'alpha/**'
      _add_spec_file 'alpha/a.spec.sh'
      _add_spec_file 'alpha/b.spec.sh'
      When call check_module 'ns/alpha'
      The status should be success
      The stderr should include '2'
      The stderr should include '0'
      The output should equal ''
    End
  End
End

#
# 検査 C: リポジトリ全体の重複 (§6.4)
#
Describe 'check_duplicates()'
  BeforeEach '_setup_fixture_repo'
  AfterEach '_teardown_fixture_repo'

  Describe 'When: 正常系'
    It 'Then: [Normal] T-RUN-CD-01: 重複が無ければ通り、走査件数と ID 件数を出力する'
      _add_module 'ns/alpha' 'ALP' 'alpha/**'
      _add_module 'ns/beta' 'BET' 'beta/**'
      _add_spec_file 'alpha/a.spec.sh' 'T-ALP-AA-01'
      _add_spec_file 'beta/b.spec.sh' 'T-BET-BB-01'
      When call check_duplicates
      The status should be success
      The output should include '2'
      The stderr should equal ''
    End
  End

  Describe 'When: 異常系'
    It 'Then: [Error] T-RUN-CD-02: モジュールをまたぐ ID の重複を報告する'
      _add_module 'ns/alpha' 'ALP' 'alpha/**'
      _add_module 'ns/beta' 'BET' 'beta/**'
      _add_spec_file 'alpha/a.spec.sh' 'T-ALP-AA-01'
      _add_spec_file 'beta/b.spec.sh' 'T-ALP-AA-01'
      When call check_duplicates
      The status should be failure
      The stderr should include 'T-ALP-AA-01'
      The stderr should include 'alpha/a.spec.sh'
      The stderr should include 'beta/b.spec.sh'
    End
  End

  Describe 'When: エッジケース'
    It 'Then: [Edge] T-RUN-CD-03: ID が 0 件なら走査件数付きの警告を出して成功する'
      _add_module 'ns/alpha' 'ALP' 'alpha/**'
      _add_spec_file 'alpha/a.spec.sh'
      _add_spec_file 'alpha/b.spec.sh'
      When call check_duplicates
      The status should be success
      The stderr should include '2'
      The stderr should include '0'
      The output should equal ''
    End
  End
End

#
# spec ファイルの配置ディレクトリからレイヤサフィックスを決める (§6.5)
# トークンの綴りからは推測せず、__tests__/<レイヤ>/ の階層だけを見る
#
Describe 'layer_suffix()'
  Describe 'When: 正常系'
    Parameters
      'alpha/__tests__/unit/a.spec.sh' ''
      'alpha/__tests__/integration/a.spec.sh' 'I'
      'alpha/__tests__/functional/a.spec.sh' 'F'
      'alpha/__tests__/system/a.spec.sh' 'S'
      'alpha/__tests__/e2e/a.spec.sh' 'E'
    End

    It "Then: [Normal] T-RUN-LS-01: $1 のサフィックスは '$2' になる"
      When call layer_suffix "$1"
      The status should be success
      The output should equal "$2"
    End
  End

  Describe 'When: エッジケース'
    Parameters
      'alpha/integration/a.spec.sh' ''
      'a.spec.sh' ''
    End

    It "Then: [Edge] T-RUN-LS-02: レイヤ階層に無い $1 のサフィックスは '$2' になる"
      When call layer_suffix "$1"
      The status should be success
      The output should equal "$2"
    End
  End
End

#
# 割り当て済み ID からベース略語の集合を導く (§6.5)
# レイヤサフィックスは配置ディレクトリから決まり、綴りからは決まらない
#
Describe 'base_targets()'
  BeforeEach '_setup_fixture_repo'
  AfterEach '_teardown_fixture_repo'

  Describe 'When: 正常系'
    It 'Then: [Normal] T-RUN-BT-01: unit の spec では ID の第 2 セグメントをそのまま使う'
      _add_spec_file 'alpha/__tests__/unit/a.spec.sh' 'T-ALP-AA-01' 'T-ALP-BB-01'
      When call base_targets "${TEST_ID_CHECK_ROOT}/alpha/__tests__/unit/a.spec.sh"
      The status should be success
      The line 1 of output should equal 'AA'
      The line 2 of output should equal 'BB'
    End

    It 'Then: [Normal] T-RUN-BT-02: 非 unit の spec ではレイヤサフィックスを 1 文字だけ落とす'
      _add_spec_file 'alpha/__tests__/integration/a.spec.sh' 'T-ALP-AAI-01'
      When call base_targets "${TEST_ID_CHECK_ROOT}/alpha/__tests__/integration/a.spec.sh"
      The output should equal 'AA'
    End

    It 'Then: [Normal] T-RUN-BT-03: レイヤをまたいで検証された対象は 1 個のベース略語にまとまる'
      _add_spec_file 'alpha/__tests__/unit/a.spec.sh' 'T-ALP-AA-01'
      _add_spec_file 'alpha/__tests__/integration/a.spec.sh' 'T-ALP-AAI-01'
      When call base_targets \
        "${TEST_ID_CHECK_ROOT}/alpha/__tests__/unit/a.spec.sh" \
        "${TEST_ID_CHECK_ROOT}/alpha/__tests__/integration/a.spec.sh"
      The output should equal 'AA'
    End
  End

  Describe 'When: エッジケース'
    It 'Then: [Edge] T-RUN-BT-04: unit の spec ではレイヤ文字で終わる略語も削らない'
      _add_spec_file 'alpha/__tests__/unit/a.spec.sh' 'T-ALP-CINI-01'
      When call base_targets "${TEST_ID_CHECK_ROOT}/alpha/__tests__/unit/a.spec.sh"
      The output should equal 'CINI'
    End
  End
End

#
# 検査 D: 略語表と実体の一致 (§6.5)
#
Describe 'check_targets()'
  BeforeEach '_setup_fixture_repo'
  AfterEach '_teardown_fixture_repo'

  Describe 'When: 正常系'
    It 'Then: [Normal] T-RUN-CT-01: 表と実体が一致するモジュールは通り、件数を出力する'
      _add_module 'ns/alpha' 'ALP' 'alpha/**'
      _add_targets_table 'ns/alpha' 'AA' 'BB'
      _add_spec_file 'alpha/__tests__/unit/a.spec.sh' 'T-ALP-AA-01'
      _add_spec_file 'alpha/__tests__/integration/b.spec.sh' 'T-ALP-BBI-01'
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
      _add_spec_file 'alpha/__tests__/unit/a.spec.sh' 'T-ALP-AA-01' 'T-ALP-BB-01'
      When call check_targets 'ns/alpha'
      The status should be failure
      The stderr should include 'BB'
      The stderr should include 'ns/alpha'
      The output should equal ''
    End

    It 'Then: [Error] T-RUN-CT-03: 表にあるがどのテストも使っていない略語を報告する'
      _add_module 'ns/alpha' 'ALP' 'alpha/**'
      _add_targets_table 'ns/alpha' 'AA' 'ZZ'
      _add_spec_file 'alpha/__tests__/unit/a.spec.sh' 'T-ALP-AA-01'
      When call check_targets 'ns/alpha'
      The status should be failure
      The stderr should include 'ZZ'
      The stderr should include 'ns/alpha'
      The output should equal ''
    End

    It 'Then: [Error] T-RUN-CT-05: 宣言の無いモジュール参照は失敗する'
      _add_module 'ns/alpha' 'ALP' 'alpha/**'
      When call check_targets 'ns/missing'
      The status should be failure
      The stderr should include 'ns/missing'
      The output should equal ''
    End
  End

  Describe 'When: エッジケース'
    It 'Then: [Edge] T-RUN-CT-04: 空の略語表はテストが使う略語をすべて未記載として報告する'
      _add_module 'ns/alpha' 'ALP' 'alpha/**'
      _add_targets_table 'ns/alpha'
      _add_spec_file 'alpha/__tests__/unit/a.spec.sh' 'T-ALP-AA-01'
      When call check_targets 'ns/alpha'
      The status should be failure
      The stderr should include 'AA'
      # 空の表が空文字の略語として報告されないことも確かめる
      The lines of stderr should equal 1
    End
  End
End

#
# コマンドラインのモード振り分け
#
Describe 'main()'
  BeforeEach '_setup_fixture_repo'
  AfterEach '_teardown_fixture_repo'

  Describe 'When: 正常系'
    It 'Then: [Normal] T-RUN-MN-01: --all は健全な擬似リポジトリで A・B・C・D をすべて通す'
      _add_module 'ns/alpha' 'ALP' 'alpha/**'
      _add_module 'ns/beta' 'BET' 'beta/**'
      _add_targets_table 'ns/alpha' 'AA'
      _add_targets_table 'ns/beta' 'BB'
      _add_spec_file 'alpha/a.spec.sh' 'T-ALP-AA-01'
      _add_spec_file 'beta/b.spec.sh' 'T-BET-BB-01'
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
      _add_spec_file 'alpha/a.spec.sh' 'T-ALP-AA-01'
      When call main --targets 'ns/alpha'
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
      _add_spec_file 'alpha/a.spec.sh' 'T-DUP-AA-01'
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
      _add_spec_file 'alpha/a.spec.sh' 'T-BET-AA-01'
      _add_spec_file 'beta/b.spec.sh' 'T-BET-BB-01'
      When call main --all
      The status should be failure
      The stderr should include 'T-BET-AA-01'
      The stdout should be defined
    End

    It 'Then: [Error] T-RUN-MN-09: --all は検査 D の失敗 (表に無い略語) を報告する'
      _add_module 'ns/alpha' 'ALP' 'alpha/**'
      _add_targets_table 'ns/alpha'
      _add_spec_file 'alpha/a.spec.sh' 'T-ALP-AA-01'
      When call main --all
      The status should be failure
      The stderr should include 'AA'
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
