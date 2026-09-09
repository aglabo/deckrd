#!/usr/bin/env bash
# normalize-doc-type.spec.sh - ShellSpec tests for normalize-doc-type.sh
#
# Copyright (c) 2026- atsushifx <https://github.com/atsushifx>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

# shellcheck disable=SC1090,SC1091

_RUNTIME_BOOTSTRAP="${SHELLSPEC_PROJECT_ROOT}/skills/deckrd/skills/deckrd/scripts/libs/bootstrap.lib.sh"
. "$_RUNTIME_BOOTSTRAP" "--no-finalize"
unset _RUNTIME_BOOTSTRAP

Include ../spec_helper.sh

SCRIPT="${DECKRD_LIB_DIR}/normalize-doc-type.lib.sh"
. "${SCRIPT}"

Describe "normalize_doc_type"

  Before "setup_deckrd_tmpdir"
  After "teardown_deckrd_tmpdir"

  Describe "short形式 → long形式"
    It "T-LIB-NDT-01: req → requirements"
      When run normalize_doc_type req
      The status should equal 0
      The output should equal "requirements"
    End

    It "T-LIB-NDT-02: spec → specifications"
      When run normalize_doc_type spec
      The status should equal 0
      The output should equal "specifications"
    End

    It "T-LIB-NDT-03: impl → implementation"
      When run normalize_doc_type impl
      The status should equal 0
      The output should equal "implementation"
    End

    It "T-LIB-NDT-04: task → tasks"
      When run normalize_doc_type task
      The status should equal 0
      The output should equal "tasks"
    End
  End

  Describe "long形式はそのまま返す"
    It "T-LIB-NDT-05: requirements → requirements"
      When run normalize_doc_type requirements
      The status should equal 0
      The output should equal "requirements"
    End

    It "T-LIB-NDT-06: review → review"
      When run normalize_doc_type review
      The status should equal 0
      The output should equal "review"
    End
  End

  Describe "phase short形式 → review-<phase>"
    It "T-LIB-NDT-07: explore → review-explore"
      When run normalize_doc_type explore
      The status should equal 0
      The output should equal "review-explore"
    End

    It "T-LIB-NDT-08: harden → review-harden"
      When run normalize_doc_type harden
      The status should equal 0
      The output should equal "review-harden"
    End

    It "T-LIB-NDT-09: fix → review-fix"
      When run normalize_doc_type fix
      The status should equal 0
      The output should equal "review-fix"
    End
  End

  Describe "phase long形式はそのまま返す"
    It "T-LIB-NDT-10: review-explore → review-explore"
      When run normalize_doc_type review-explore
      The status should equal 0
      The output should equal "review-explore"
    End
  End

  Describe "不明なキーワード"
    It "T-LIB-NDT-11: exit 1でエラーメッセージを返す"
      When run normalize_doc_type invalid
      The status should equal 1
      The stderr should include "Error: unknown doc-type"
    End
  End

  Describe "空パラメータ"
    It "T-LIB-NDT-12: exit 1でエラーメッセージを返す"
      When run normalize_doc_type ""
      The status should equal 1
      The stderr should include "Error: doc-type is required"
    End
  End

  Describe "不正フォーマット"
    It "T-LIB-NDT-13: 大文字を含む場合はexit 1でエラーメッセージを返す"
      When run normalize_doc_type "Req"
      The status should equal 1
      The stderr should include "Error: doc-type must match"
    End

    It "T-LIB-NDT-14: 数字を含む場合はexit 1でエラーメッセージを返す"
      When run normalize_doc_type "req1"
      The status should equal 1
      The stderr should include "Error: doc-type must match"
    End
  End

End
