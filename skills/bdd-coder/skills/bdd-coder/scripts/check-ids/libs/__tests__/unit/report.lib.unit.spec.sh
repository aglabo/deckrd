#!/usr/bin/env bash
# skills/bdd-coder/skills/bdd-coder/scripts/check-ids/libs/__tests__/unit/report.lib.unit.spec.sh
# @(#) : BDD unit tests for report.lib.sh
#
# Copyright (c) 2026- atsushifx <https://github.com/atsushifx>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

# shellcheck shell=bash

# --- テスト対象 ---
_LIBRARY="${SHELLSPEC_PROJECT_ROOT}/skills/bdd-coder/skills/bdd-coder/scripts/check-ids/libs/report.lib.sh"
Include "$_LIBRARY"

# --- 内部ヘルパー ---

# 関数
# 引数の種類を順に 1 件ずつ数える。counts_init 済みであること。$@: counts_add に渡す種類
_add_counts() {
  local kind
  for kind in "$@"; do
    counts_add "$kind"
  done
}

# --- テスト本体 ---

# report.lib.sh の counts_add。種類ごとの計数と、その件数の出力
Describe 'T-RUN-CNA: counts_add'
  BeforeEach 'counts_init'

  It 'Then: [Normal] T-RUN-CNA-01: counts each kind for the summary'
    _add_counts files group group case case case
    When call counts_summary
    The status should be success
    The output should equal 'OK: 1 files, 2 group IDs, 3 case IDs'
  End
End

# report.lib.sh の counts_init。呼び直しによる全件数の初期化
Describe 'T-RUN-CNI: counts_init'
  BeforeEach 'counts_init'

  It 'Then: [Normal] T-RUN-CNI-01: resets every count'
    _add_counts files group case errors
    counts_init
    When call counts_summary
    The status should be success
    The output should equal 'OK: 0 files, 0 group IDs, 0 case IDs'
  End
End

# report.lib.sh の report_error。エラーの標準エラー出力
Describe 'T-RUN-RER: report_error'
  BeforeEach 'counts_init'

  It 'Then: [Normal] T-RUN-RER-01: prints the error to stderr'
    When call report_error 'a.spec.sh:2: no case ID'
    The status should be success
    The output should equal ''
    The stderr should equal 'Error: a.spec.sh:2: no case ID'
  End
End

# report.lib.sh の counts_summary。エラーがあるときは出力せずに失敗する
Describe 'T-RUN-CNS: counts_summary'
  BeforeEach 'counts_init'

  It 'Then: [Error] T-RUN-CNS-01: prints nothing and fails after an error'
    report_error 'x' 2>/dev/null
    When call counts_summary
    The status should equal 1
    The output should equal ''
  End
End
