#!/usr/bin/env bash
# generate-doc-resolve-deckrd-base.unit.spec.sh - ShellSpec tests for resolve_deckrd_base in generate-doc.sh
#
# Unit test design:
#   - bootstrap.lib.sh は --no-finalize 付きで source する。finalize は DECKRD_DOCS_DIR を
#     readonly にするため、ケースが前提の環境を作れなくなる。
#   - setup_deckrd_tmpdir はグループレベルで使わない。spec_helper が DECKRD_DOCS_DIR を
#     export するので、「両方未設定」の前提が最初から成立しなくなる。
#     環境変数の設定・解除は各ケースの Before / After に閉じ込める。
#   - 期待値は検査対象と独立したオラクルから組む。両方未設定のケースだけは
#     リポジトリルートを git へ問い直して組み、実装の式を写さない。
#   - センチネルは実在しないパスにする。検証対象は返る文字列の優先順位であり、
#     パスの実在ではないので、実在を前提にしたアサーションは置かない。
#   - 異常系のケースは無い。resolve_deckrd_base は引数を取らず、失敗パスも持たない
#     (git rev-parse の失敗は pwd へフォールバックする設計) ため、
#     無効入力の同値クラスが存在しない。
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

# shellcheck source=../generate-doc.sh
. "${SUBCOMMANDS_DIR}/generate-doc.sh"

# ============================================================================
# 内部ヘルパー
# ============================================================================

# 定数

# _UNSET - _apply_env に「その変数を unset する」と伝える印。実パスと衝突しない固有値
_UNSET='<unset>'

# _SENTINEL_DOCS - DECKRD_DOCS に入れるセンチネル。最優先で返ることの確認に使う
_SENTINEL_DOCS='/deckrd-sentinel/docs-override'

# _SENTINEL_DOCS_DIR - DECKRD_DOCS_DIR に入れるセンチネル。_SENTINEL_DOCS と必ず異なる値にする
_SENTINEL_DOCS_DIR='/deckrd-sentinel/docs-dir'

# _EXPECTED_REPO_BASE - 両方未設定のときの期待値。実装の式とは独立に git へ問い直して組む
#
# --execdir @specfile なので実装が見る cwd はこの spec のディレクトリであり、
# 同じリポジトリのルートが返る。Windows / WSL で pwd と git の綴りが食い違うため、
# SHELLSPEC_PROJECT_ROOT の連結ではなく git の綴りへ揃える。
_EXPECTED_REPO_BASE="$(git -C "${SHELLSPEC_PROJECT_ROOT}" rev-parse --show-toplevel)/docs/.deckrd"

# _BOOTSTRAP_DOCS_DIR - bootstrap が解決した DECKRD_DOCS_DIR。After で元の値へ戻すために退避する
_BOOTSTRAP_DOCS_DIR="${DECKRD_DOCS_DIR:-}"

# 関数

# _apply_env - DECKRD_DOCS / DECKRD_DOCS_DIR をケースの前提状態へ整える
#
# 「未設定」と「空文字」は resolve_deckrd_base にとって別の入力ではないことを
# 確かめるケースがあるため、両者を引数で撃ち分けられるようにする。
# $_UNSET を渡した変数だけを unset し、それ以外は空文字も含めてそのまま export する。
#
# @arg $1 string  DECKRD_DOCS に入れる値。$_UNSET なら unset する
# @arg $2 string  DECKRD_DOCS_DIR に入れる値。$_UNSET なら unset する
# @return 0 always
_apply_env() {
  local _docs="$1" _docs_dir="$2"

  if [[ "$_docs" == "$_UNSET" ]]; then
    unset DECKRD_DOCS
  else
    export DECKRD_DOCS="$_docs"
  fi

  if [[ "$_docs_dir" == "$_UNSET" ]]; then
    unset DECKRD_DOCS_DIR
  else
    export DECKRD_DOCS_DIR="$_docs_dir"
  fi
}

# _restore_env - ケースが触った環境変数を bootstrap 直後の状態へ戻す
#
# DECKRD_DOCS は誰も設定しない変数なので unset が元の状態である。
# DECKRD_DOCS_DIR は bootstrap が export したものなので、退避した値へ戻す。
#
# @return 0 always
_restore_env() {
  unset DECKRD_DOCS
  export DECKRD_DOCS_DIR="$_BOOTSTRAP_DOCS_DIR"
}

# ============================================================================
# テスト本体
# ============================================================================

# generate-doc.sh の DECKRD_BASE 解決。
# DECKRD_DOCS (後方互換の上書き枠) → DECKRD_DOCS_DIR (bootstrap が export) →
# リポジトリルート配下の docs/.deckrd の 3 段で解決し、config.lib.sh と同じ優先順位になる。
# 各ケースは環境変数の状態だけを変え、返る文字列がどの段から来たかを確かめる。
Describe "T-SUB-RDB: generate-doc.sh resolve_deckrd_base"

  After "_restore_env"

  Describe "Given: DECKRD_DOCS と DECKRD_DOCS_DIR が相異なる値で設定されている"
    Before "_apply_env '$_SENTINEL_DOCS' '$_SENTINEL_DOCS_DIR'"

    Describe "When: 正常系"
      It "Then: [Normal] T-SUB-RDB-01: DECKRD_DOCS を最優先で返す"
        When call resolve_deckrd_base
        The status should equal 0
        The output should equal "$_SENTINEL_DOCS"
        The stderr should be blank
      End
    End
  End

  Describe "Given: DECKRD_DOCS が未設定で DECKRD_DOCS_DIR だけが設定されている"
    Before "_apply_env '$_UNSET' '$_SENTINEL_DOCS_DIR'"

    Describe "When: 正常系"
      It "Then: [Normal] T-SUB-RDB-02: DECKRD_DOCS_DIR を返す"
        When call resolve_deckrd_base
        The status should equal 0
        The output should equal "$_SENTINEL_DOCS_DIR"
        The stderr should be blank
      End
    End
  End

  Describe "Given: DECKRD_DOCS と DECKRD_DOCS_DIR がどちらも未設定"
    Before "_apply_env '$_UNSET' '$_UNSET'"

    Describe "When: 正常系"
      It "Then: [Normal] T-SUB-RDB-03: リポジトリルート配下の docs/.deckrd を返す"
        When call resolve_deckrd_base
        The status should equal 0
        The output should equal "$_EXPECTED_REPO_BASE"
        The stderr should be blank
      End
    End
  End

  Describe "Given: DECKRD_DOCS が空文字で DECKRD_DOCS_DIR が設定されている"
    Before "_apply_env '' '$_SENTINEL_DOCS_DIR'"

    Describe "When: エッジケース"
      It "Then: [Edge] T-SUB-RDB-04: 空文字を未設定として扱い DECKRD_DOCS_DIR を返す"
        When call resolve_deckrd_base
        The status should equal 0
        The output should equal "$_SENTINEL_DOCS_DIR"
        The stderr should be blank
      End
    End
  End
End
