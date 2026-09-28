#!/usr/bin/env bash
# generate-doc-validate-env.unit.spec.sh - ShellSpec tests for the validate_env guard in generate-doc.sh
#
# Unit test design:
#   - generate-doc.sh は他の 5 本の入口スクリプトと同じく、ライブラリ読み込みの直後に
#     トップレベルで `validate_env || exit 1` を呼ばなければならない。
#     validate_env だけが jqexe を export するので、呼ばないと jq_read が
#     リテラル jq へフォールバックし、jaq しか無い環境で全コマンドが落ちる。
#   - 静的検査はソーステキストを見る。source 行と呼び出し行のどちらが欠けても
#     配線は成立しないので、2 つを別ケースで検査する。
#   - 存在検査だけではガードが機能ライブラリの後ろへ動いたことを見逃す。
#     行番号を比べるケースを別に置き、5 入口と同じ「ガードが先」の形を機械的に守る。
#   - 機能検査は generate-doc.sh を source せずサブプロセスで起動する。
#     source すると spec 自身のシェルでトップレベルの validate_env が走り、
#     スタブの戻り値で spec ごと終了してしまう。
#   - サブプロセスは引数なしで起動する。doc_type チェックで止まるため
#     AI CLI (claude) を絶対に起動しない。
#   - 読み書きはすべて tmpdir に閉じ込める。隔離しないとサブプロセスが
#     SESSION_FILE を開発者の実 .local/deckrd/session.json へ解決し、
#     そのファイルの状態でしか再現しない flake になる。
#
# Copyright (c) 2026- atsushifx <https://github.com/atsushifx>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

# shellcheck disable=SC1090,SC1091

# ============================================================================
# テスト基盤
# ============================================================================

_RUNTIME_BOOTSTRAP="${SHELLSPEC_PROJECT_ROOT}/skills/deckrd/skills/deckrd/scripts/libs/bootstrap.lib.sh"
. "$_RUNTIME_BOOTSTRAP" --no-finalize
unset _RUNTIME_BOOTSTRAP

Include ../spec_helper.sh

# ============================================================================
# テスト対象
# ============================================================================

# generate-doc.sh は source しない。検査対象はソーステキストと、
# サブプロセスとして起動したときの振る舞いである (冒頭の Unit test design 参照)。

# ============================================================================
# 内部ヘルパー
# ============================================================================

# 定数

# _STUB_MARKER - validate_env スタブが呼ばれた印。実装のどのメッセージとも衝突しない固有値
_STUB_MARKER='STUB-VALIDATE-ENV-CALLED'

# _PROCEEDED_MESSAGE - validate_env より後 (doc_type チェック) へ進んだ印となる実装のメッセージ
_PROCEEDED_MESSAGE='prompt or @keyword is required'

# _GUARD_PATTERN - トップレベルのガード行に一致する正規表現。存在検査と順序検査で共有する
_GUARD_PATTERN='^validate_env \|\| exit 1$'

# _FEATURE_LIB_PATTERNS - ガードより後に読み込まれなければならない機能ライブラリの source 行
#
# validate_env だけが jqexe を export するので、これらのライブラリが
# トップレベルで jq_read を呼ぶようになった時点でガードが先に無いと壊れる。
_FEATURE_LIB_PATTERNS=(
  '^\. .*session\.lib\.sh'
  '^\. .*config\.lib\.sh'
  '^\. .*ai-runner\.lib\.sh'
  '^\. .*normalize-doc-type\.lib\.sh'
)

# _ORDER_OK - 順序検査が通ったときの出力。理由つきの失敗メッセージと区別できる固有値
_ORDER_OK='guard-before-feature-libs'

# 関数

# _setup_isolated_env - サブプロセスの読み書き先を tmpdir へ隔離する
#
# setup_deckrd_tmpdir が DECKRD_LOCAL_DATA / DECKRD_DOCS_DIR を tmpdir へ向けるので、
# SESSION_FILE は tmpdir 内の不在パスへ解決され、config_init は静かに 0 を返す。
# DECKRD_DOCS もピン留めする。main() のフォールバックが
# git rev-parse --show-toplevel に落ちて実リポジトリの docs/.deckrd へ書くのを防ぐ。
#
# @return 0 always
_setup_isolated_env() {
  setup_deckrd_tmpdir
  export DECKRD_DOCS="${DECKRD_DOCS_DIR}"
}

# _teardown_isolated_env - tmpdir と export した validate_env スタブを片付ける
#
# スタブを残すと以後のサブプロセスが頼んでいない validate_env を継承するので、
# tmpdir の削除とあわせて必ず消す。未定義でも unset -f は 0 を返す。
#
# @return 0 always
_teardown_isolated_env() {
  unset -f validate_env
  unset DECKRD_DOCS
  teardown_deckrd_tmpdir
}

# _source_has_pattern - generate-doc.sh のソースに正規表現が現れるかを判定する
#
# 存在だけを見る静的検査でファイル読み出しを共通化する。
# パスは SUBCOMMANDS_DIR 基準に統一する。
#
# @arg $1 string pattern  grep -E に渡す正規表現
# @stdout 見つかれば "found"、見つからなければ "absent"
# @return 0 always
_source_has_pattern() {
  local _pattern="$1"
  if grep -qE "$_pattern" "${SUBCOMMANDS_DIR}/generate-doc.sh"; then
    printf 'found\n'
  else
    printf 'absent\n'
  fi
}

# _first_line_matching - generate-doc.sh のソースで正規表現に最初に一致する行番号を返す
#
# パスは _source_has_pattern と同じく SUBCOMMANDS_DIR 基準に統一する。
#
# @arg $1 string pattern  grep -E に渡す正規表現
# @stdout 一致した最初の行番号。一致が無ければ 0
# @return 0 always
_first_line_matching() {
  local _pattern="$1" _line
  _line="$(grep -nE "$_pattern" "${SUBCOMMANDS_DIR}/generate-doc.sh" | head -n 1 | cut -d: -f1)"
  printf '%s\n' "${_line:-0}"
}

# _guard_order_report - validate_env ガードが機能ライブラリ 4 本より前にあるかを 1 行で報告する
#
# _first_line_matching は不在を 0 で返す。0 は「最も早い行」ではなく「不在」なので、
# 行番号を比べる前に各パターンが 1 件以上一致したことを確かめる。
# そうしないと source 行やガード行を消した変更が「順序 OK」として素通りする。
#
# @stdout 順序が正しければ $_ORDER_OK、崩れていれば理由を含む 1 行
# @return 0 always
_guard_order_report() {
  local _guard_line
  _guard_line="$(_first_line_matching "$_GUARD_PATTERN")"
  if [[ "$_guard_line" == '0' ]]; then
    printf 'absent: %s\n' "$_GUARD_PATTERN"
    return 0
  fi

  local _pattern _lib_line
  for _pattern in "${_FEATURE_LIB_PATTERNS[@]}"; do
    _lib_line="$(_first_line_matching "$_pattern")"
    if [[ "$_lib_line" == '0' ]]; then
      printf 'absent: %s\n' "$_pattern"
      return 0
    fi
    if ((_guard_line > _lib_line)); then
      printf 'guard at line %s is after %s at line %s\n' "$_guard_line" "$_pattern" "$_lib_line"
      return 0
    fi
  done

  printf '%s\n' "$_ORDER_OK"
}

# _run_generate_doc_with_stubbed_validate_env - validate_env を差し替えて generate-doc.sh を実行する
#
# validate-env.lib.sh は validate_env が定義済みなら上書きしないガードを持つので、
# export -f したスタブが実装より優先される。generate-doc.sh は引数なしで起動し、
# doc_type チェックで止めることで AI CLI を起動させない。
# stdin は /dev/null から与え、将来 `cat` へ到達する順序になってもハングさせない。
#
# @arg $1 int rc  スタブが返す終了ステータス (0 = 検証成功、1 = 検証失敗)
# @stdout generate-doc.sh の stdout (usage 等)
# @stderr スタブのマーカーと generate-doc.sh の stderr
# @return generate-doc.sh の終了ステータス
_run_generate_doc_with_stubbed_validate_env() {
  local _rc="$1"
  # rc とマーカーをスタブ本体に埋め込む。export -f は関数の定義テキストだけを子へ渡すので、
  # 呼び出し側のローカル変数を参照する形では値が届かない
  eval "validate_env() { printf '%s\\n' '${_STUB_MARKER}' >&2; return ${_rc}; }"
  export -f validate_env
  bash "${SUBCOMMANDS_DIR}/generate-doc.sh" </dev/null
}

# ============================================================================
# テスト本体
# ============================================================================

# generate-doc.sh の validate_env 呼び出し配線。
# 他 5 入口と同じ位置・同じ形でガードが入っており、
# かつ validate_env の失敗で後続処理へ進まないことを担保する。
Describe "T-SUB-VE: generate-doc.sh の validate_env 呼び出し配線"

  Before "_setup_isolated_env"
  After "_teardown_isolated_env"

  Describe "Given: 修正後の generate-doc.sh のソーステキスト"
    # 配線が静的に存在し、かつ 5 入口と同じ順序で並んでいることの検査
    Describe "When: 正常系"
      It "Then: [Normal] T-SUB-VE-01: validate-env.lib.sh を source している"
        When call _source_has_pattern '^\. .*validate-env\.lib\.sh'
        The output should equal "found"
        The stderr should be blank
      End

      It "Then: [Normal] T-SUB-VE-02: トップレベルに validate_env || exit 1 を持つ"
        When call _source_has_pattern "$_GUARD_PATTERN"
        The output should equal "found"
        The stderr should be blank
      End

      It "Then: [Normal] T-SUB-VE-05: ガードが機能ライブラリ 4 本の source より前にある"
        When call _guard_order_report
        The output should equal "$_ORDER_OK"
        The stderr should be blank
      End

      It "Then: [Normal] T-SUB-VE-06: utils.lib.sh を明示的に source している"
        When call _source_has_pattern '^\. .*utils\.lib\.sh'
        The output should equal "found"
        The stderr should be blank
      End
    End
  End

  Describe "Given: validate_env をスタブに差し替えた generate-doc.sh のサブプロセス実行"
    # 配線が実行時に効いていることの検査
    Describe "When: 正常系"
      It "Then: [Normal] T-SUB-VE-03: スタブが 0 を返す → 呼ばれた上で後続処理へ進む"
        When run _run_generate_doc_with_stubbed_validate_env 0
        The status should equal 1
        The stderr should include "$_STUB_MARKER"
        The stderr should include "$_PROCEEDED_MESSAGE"
        The output should include 'Usage: generate-doc.sh'
      End
    End

    Describe "When: 異常系"
      It "Then: [Error] T-SUB-VE-04: スタブが 1 を返す → 非ゼロで終了し後続処理へ進まない"
        When run _run_generate_doc_with_stubbed_validate_env 1
        The status should not equal 0
        The stderr should include "$_STUB_MARKER"
        The stderr should not include "$_PROCEEDED_MESSAGE"
        The output should be blank
      End
    End
  End
End
