#!/usr/bin/env bash
# runners/libs/__tests__/unit/init-vars.lib.spec.sh
# @(#) : BDD unit tests for init-vars.lib.sh
#
# Copyright (c) 2026- atsushifx <https://github.com/atsushifx>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT
# shellcheck shell=bash
# init-vars.lib.spec.sh — BDD spec for init-vars.lib.sh

# --- テスト基盤 -------------------------------------------------------------

Include "${SHELLSPEC_PROJECT_ROOT}/runners/libs/__tests__/spec_helper.sh"

# --- テスト対象 -------------------------------------------------------------

# init-vars.lib.sh は `Include` しない。`Include` は spec 読み込み時に 1 回だけ
# source するため、lib の二重 source ガード `readonly _INIT_VARS_LIB_SH=1` により
# 2 回目以降が無効化され、git スタブを仕込んだ状態で評価し直せない。
# 代わりに疑似ツリーへ複製した lib を、例ごとに別プロセスのプローブから source する
_IVPR_LIB="${SHELLSPEC_PROJECT_ROOT}/runners/libs/init-vars.lib.sh"

# --- 内部ヘルパー -----------------------------------------------------------

# 定数

# 疑似ツリーの根。ShellSpec が実行終了時にまとめて消す一時領域に置く
_IVPR_FIXTURE_ROOT="${SHELLSPEC_TMPBASE:-${TMPDIR:-/tmp}}/init-vars-fixture"

# 疑似ツリーの組み立て完了マーカー。`--jobs 4` 下で作りかけのツリーを掴まないようにする
_IVPR_FIXTURE_READY="${_IVPR_FIXTURE_ROOT}/.fixture-ready"

# 疑似プロジェクト根。git が使えないとき PROJECT_ROOT が解決すべき値
# （T-RUN-IVPR-03/04/05 の期待値）
_IVPR_FAKE_ROOT="${_IVPR_FIXTURE_ROOT}/root"

# 疑似ツリー側の lib。プローブはこちらを source する
_IVPR_FIXTURE_LIB="${_IVPR_FAKE_ROOT}/runners/libs/init-vars.lib.sh"

# `runners/` 直下（深さ 1）の呼び出し元を模したプローブ（T-RUN-IVPR-03 の入力）
_IVPR_SHALLOW_PROBE="${_IVPR_FAKE_ROOT}/runners/probe-shallow.sh"

# `runners/exec/` 配下（深さ 2）の呼び出し元を模したプローブ
# （T-RUN-IVPR-01/02/04/05 の入力）
_IVPR_DEEP_PROBE="${_IVPR_FAKE_ROOT}/runners/exec/probe-deep.sh"

# git 成功スタブを選ぶプローブの引数。これ以外の語は失敗スタブを選ぶ
_IVPR_GIT_OK='git-ok'

# git 失敗スタブを選ぶプローブの引数
_IVPR_GIT_NG='git-ng'

# git 成功スタブが `rev-parse --show-toplevel` として返すパス（T-RUN-IVPR-01 の期待値）
_IVPR_GIT_TOPLEVEL='/fake/git/toplevel'

# git 失敗スタブの終了コード。128 は実機の git がリポジトリ外で返す値
_IVPR_GIT_FAILURE_CODE=128

# 呼び出し元があらかじめ与える PROJECT_ROOT（T-RUN-IVPR-02 の入力かつ期待値）
_IVPR_PRESET_ROOT='/preset/root'

# プローブの出力行数。PROJECT_ROOT と SCRIPT_ROOT でちょうど 2 行になる。
# フォールバックをサブシェルで囲み忘れると PROJECT_ROOT が 2 行になり、この値が崩れる
_IVPR_PROBE_LINE_COUNT=2

# `runners/` 直下（深さ 1）の呼び出し元が指すべき SCRIPT_ROOT。
# プローブと疑似ツリーは PROJECT_ROOT のテストと共有する（T-RUN-IVSR-01/02 の期待値）
_IVSR_SHALLOW_SCRIPT_ROOT="${_IVPR_FAKE_ROOT}/runners"

# `runners/exec/`（深さ 2）の呼び出し元が指すべき SCRIPT_ROOT。
# PROJECT_ROOT の `_IVPR_FAKE_ROOT` とは別物になる（T-RUN-IVSR-03 の期待値）
_IVSR_DEEP_SCRIPT_ROOT="${_IVPR_FAKE_ROOT}/runners/exec"

# 関数

#
# @description init-vars.lib.sh のプローブスクリプトを書き出す。
#              プローブは第 1 引数で git のスタブを選び（_IVPR_GIT_OK なら成功、
#              それ以外なら失敗）、疑似ツリー側の lib を source して
#              1 行目に PROJECT_ROOT、2 行目に SCRIPT_ROOT を出力する。
#              深さの違うディレクトリに同じ内容のプローブを置くのは、PROJECT_ROOT が
#              呼び出し元の位置に左右されないこと（どちらの深さでも疑似プロジェクト根に
#              なること）を観測するため。一方 SCRIPT_ROOT は呼び出し元のディレクトリの
#              ままなので、同じ 2 行の出力で両方の性質を確かめられる
# @arg $1 string 書き出すプローブのパス
# @return 0 when the probe was written
# @sideeffect Creates the probe script at $1
#
_write_init_vars_probe() {
  cat >"$1" <<EOF
#!/usr/bin/env bash
# init-vars.lib.sh のプローブ（spec が生成）。\$1 で git のスタブを選ぶ
if [[ "\${1:-}" == '${_IVPR_GIT_OK}' ]]; then
  git() { printf '%s\n' '${_IVPR_GIT_TOPLEVEL}'; }
else
  git() { return ${_IVPR_GIT_FAILURE_CODE}; }
fi
. '${_IVPR_FIXTURE_LIB}'
printf '%s\n' "\${PROJECT_ROOT}" "\${SCRIPT_ROOT}"
EOF
}

#
# @description 疑似プロジェクトツリーを組み立てる。`<fake-root>/runners/libs/` へ
#              テスト対象の lib を複製し、深さ 1 と深さ 2 のプローブを置く。
#              `.shellspec` は `--jobs 4` で spec ファイルを並行実行するため、
#              組み立て完了を最後に立てるマーカーで表し、作りかけのツリーを
#              後続の例が掴まないようにする。途中で失敗したときはマーカーを
#              残さず非 0 で返し、次の呼び出しが組み立て直す
# @arg none
# @return 0 when the fixture tree is ready; 1 when it could not be built
# @sideeffect Creates _IVPR_FIXTURE_ROOT and its contents on disk
#
_setup_init_vars_fixture() {
  [[ -f "$_IVPR_FIXTURE_READY" ]] && return 0

  mkdir -p "${_IVPR_FAKE_ROOT}/runners/libs" "${_IVPR_FAKE_ROOT}/runners/exec" || return 1
  cp "$_IVPR_LIB" "$_IVPR_FIXTURE_LIB" || return 1
  _write_init_vars_probe "$_IVPR_SHALLOW_PROBE" || return 1
  _write_init_vars_probe "$_IVPR_DEEP_PROBE" || return 1

  # 完了マーカーは全ての書き出しが成功した後にだけ立てる
  : >"$_IVPR_FIXTURE_READY" || return 1
}

# --- テスト本体 -------------------------------------------------------------

#
# 全ての runner スクリプトが source する共通変数の初期化 lib。
#
Describe 'init-vars.lib.sh'
  #
  # プロジェクト根の決定。git が使えるならその出力を、使えないなら
  # lib 自身の位置から導く。呼び出し元の階層の深さに依存してはならない
  #
  Describe 'T-RUN-IVPR: PROJECT_ROOT'
    Before '_setup_init_vars_fixture'

    # git リポジトリの中では git の答えが正であり、呼び出し元の指定はそれより優先される
    Describe 'When: 正常系'
      It 'Then: [Normal] T-RUN-IVPR-01: git が使えるときは git の出力をそのまま採る'
        When run bash "$_IVPR_DEEP_PROBE" "$_IVPR_GIT_OK"
        The line 1 of output should equal "$_IVPR_GIT_TOPLEVEL"
        The lines of output should equal "$_IVPR_PROBE_LINE_COUNT"
        The status should be success
      End

      It 'Then: [Normal] T-RUN-IVPR-02: 呼び出し元が与えた PROJECT_ROOT を上書きしない'
        When run env "PROJECT_ROOT=${_IVPR_PRESET_ROOT}" bash "$_IVPR_DEEP_PROBE" "$_IVPR_GIT_OK"
        The line 1 of output should equal "$_IVPR_PRESET_ROOT"
        The lines of output should equal "$_IVPR_PROBE_LINE_COUNT"
        The status should be success
      End
    End

    # git が使えないときは lib 自身の位置からプロジェクト根を導く。
    # 呼び出し元がどの階層にいても同じ根に解決しなければならない
    Describe 'When: 異常系'
      It 'Then: [Error] T-RUN-IVPR-03: git が失敗しても runners/ 直下の呼び出し元からプロジェクト根を導く'
        When run bash "$_IVPR_SHALLOW_PROBE" "$_IVPR_GIT_NG"
        The line 1 of output should equal "$_IVPR_FAKE_ROOT"
        The lines of output should equal "$_IVPR_PROBE_LINE_COUNT"
        The status should be success
      End

      It 'Then: [Error] T-RUN-IVPR-04: git が失敗しても runners/exec/ の呼び出し元からプロジェクト根を導く'
        When run bash "$_IVPR_DEEP_PROBE" "$_IVPR_GIT_NG"
        The line 1 of output should equal "$_IVPR_FAKE_ROOT"
        The lines of output should equal "$_IVPR_PROBE_LINE_COUNT"
        The status should be success
      End
    End

    # 呼び出し元が変数を空文字のまま export している場合も、値が無いことに変わりはない
    Describe 'When: エッジケース'
      It 'Then: [Edge] T-RUN-IVPR-05: 空文字の PROJECT_ROOT は未設定として扱いフォールバックする'
        When run env 'PROJECT_ROOT=' bash "$_IVPR_DEEP_PROBE" "$_IVPR_GIT_NG"
        The line 1 of output should equal "$_IVPR_FAKE_ROOT"
        The lines of output should equal "$_IVPR_PROBE_LINE_COUNT"
        The status should be success
      End
    End
  End

  #
  # 呼び出し元スクリプトのディレクトリの決定。lib 自身ではなく lib を source した
  # スクリプトの位置を指し続けなければならない。PROJECT_ROOT のフォールバックが
  # lib 自身の位置を基準にしても、SCRIPT_ROOT の意味は変えてはならない
  #
  Describe 'T-RUN-IVSR: SCRIPT_ROOT'
    Before '_setup_init_vars_fixture'

    # git が使えるときも SCRIPT_ROOT は git の答えに引きずられてはならない
    Describe 'When: 正常系'
      It 'Then: [Normal] T-RUN-IVSR-01: git が使えるときも runners/ 直下の呼び出し元のディレクトリを指す'
        When run bash "$_IVPR_SHALLOW_PROBE" "$_IVPR_GIT_OK"
        The line 2 of output should equal "$_IVSR_SHALLOW_SCRIPT_ROOT"
        The lines of output should equal "$_IVPR_PROBE_LINE_COUNT"
        The status should be success
      End
    End

    # git フォールバックは PROJECT_ROOT の行だけの話であり、SCRIPT_ROOT には波及しない
    Describe 'When: 異常系'
      It 'Then: [Error] T-RUN-IVSR-02: git が失敗しても runners/ 直下の呼び出し元のディレクトリのまま'
        When run bash "$_IVPR_SHALLOW_PROBE" "$_IVPR_GIT_NG"
        The line 2 of output should equal "$_IVSR_SHALLOW_SCRIPT_ROOT"
        The lines of output should equal "$_IVPR_PROBE_LINE_COUNT"
        The status should be success
      End
    End

    # 呼び出し元が 1 階層深いとき、SCRIPT_ROOT と PROJECT_ROOT は別のディレクトリになる
    Describe 'When: エッジケース'
      It 'Then: [Edge] T-RUN-IVSR-03: runners/exec/ の呼び出し元では runners/exec を指す'
        When run bash "$_IVPR_DEEP_PROBE" "$_IVPR_GIT_NG"
        The line 2 of output should equal "$_IVSR_DEEP_SCRIPT_ROOT"
        The lines of output should equal "$_IVPR_PROBE_LINE_COUNT"
        The status should be success
      End
    End
  End
End
