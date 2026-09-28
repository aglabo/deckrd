#!/usr/bin/env bash
# generate-doc-resolve-doc-paths.unit.spec.sh - ShellSpec tests for resolve_doc_paths in generate-doc.sh
#
# Unit test design:
#   - DECKRD_ASSETS_DIR は bootstrap.lib.sh が解決した実値をそのまま使う。
#     スペック側で設定してはならない。フィクスチャで上書きすると、
#     generate-doc.sh 側の解決不良を素通りさせてしまう。
#   - 期待値は検査対象と独立したオラクルから組む。ヘルパの ASSETS_DIR は
#     SHELLSPEC_PROJECT_ROOT から導出され bootstrap を経由しないため、
#     これを期待値に使う。DECKRD_ASSETS_DIR から期待値を組むと、
#     「存在するが誤ったパス」を検出できない自己参照になる。
#   - T-SUB-GDAV は generate-doc.sh のソーステキストを静的に検査し、
#     削除済みの自前定義と抑止ディレクティブが復活したら失敗させる。
#
# Copyright (c) 2026- atsushifx <https://github.com/atsushifx>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

# shellcheck disable=SC1090,SC1091,SC2287

_RUNTIME_BOOTSTRAP="${SHELLSPEC_PROJECT_ROOT}/skills/deckrd/skills/deckrd/scripts/libs/bootstrap.lib.sh"
. "$_RUNTIME_BOOTSTRAP" --no-finalize
unset _RUNTIME_BOOTSTRAP

Include ../spec_helper.sh

# shellcheck source=../generate-doc.sh
. "${SUBCOMMANDS_DIR}/generate-doc.sh"

# ============================================================================
# 内部ヘルパー
# ============================================================================

# 関数

# _all_lines_are_existing_files - stdin の各行が実在するファイルかを検査する
#
# resolve_doc_paths の出力 (1 行 1 パス) を受け取り、各行に -f を掛ける。
# 1 行も無い場合は失敗とする (空出力を「全行が実在」と誤判定させない)。
# 末尾に改行が無い最終行も取りこぼさない。
#
# @stdin  1 行 1 パスのテキスト
# @return 0 全行が実在するファイル、1 欠けている行がある / 1 行も無い
_all_lines_are_existing_files() {
  local _path
  local _count=0
  while IFS= read -r _path || [[ -n "$_path" ]]; do
    [[ -f "$_path" ]] || return 1
    _count=$((_count + 1))
  done
  [[ "$_count" -gt 0 ]]
}

# _source_has_pattern - generate-doc.sh のソースに正規表現が現れるかを判定する
#
# 2 つの静的検査でファイル読み出しを共通化する。
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

# ============================================================================
# テスト本体
# ============================================================================

Describe "T-SUB-RDP: generate-doc.sh resolve_doc_paths"

  Before "setup_deckrd_tmpdir"
  After "teardown_deckrd_tmpdir"

  Describe "Given: bootstrap が解決した実アセットツリー"
    Describe "When: 正常系"
      It "Then: [Normal] T-SUB-RDP-01: requirements → exit 0、実在する prompt/template パスを返す"
        When call resolve_doc_paths "requirements"
        The status should equal 0
        The lines of output should equal 2
        The line 1 of output should equal "${ASSETS_DIR}/prompts/requirements.prompt.md"
        The line 2 of output should equal "${ASSETS_DIR}/templates/requirements.template.md"
        The output should satisfy _all_lines_are_existing_files
        The stderr should be blank
      End
    End

    Describe "When: 異常系"
      It "Then: [Error] T-SUB-RDP-02: bogus → exit 1、stderr に Prompt file not found を出し stdout は空"
        When call resolve_doc_paths "bogus"
        The status should equal 1
        The output should be blank
        The stderr should include 'Error: Prompt file not found:'
      End
    End

    Describe "When: エッジケース"
      It "Then: [Edge] T-SUB-RDP-03: 空文字 → exit 1、stderr に Prompt file not found を出し stdout は空"
        When call resolve_doc_paths ""
        The status should equal 1
        The output should be blank
        The stderr should include 'Error: Prompt file not found:'
      End
    End
  End
End

Describe "T-SUB-GDAV: generate-doc.sh の DECKRD_ASSETS_DIR 自前定義の除去"

  Describe "Given: 修正後の generate-doc.sh のソーステキスト"
    Describe "When: 静的検査する"
      It "Then: [Normal] T-SUB-GDAV-01: generate-doc.sh は DECKRD_ASSETS_DIR を自前定義しない"
        When call _source_has_pattern '^DECKRD_ASSETS_DIR='
        The output should equal "absent"
      End

      It "Then: [Normal] T-SUB-GDAV-02: generate-doc.sh は SC2153 の抑止を持たない"
        When call _source_has_pattern 'disable=SC2153'
        The output should equal "absent"
      End
    End
  End
End
