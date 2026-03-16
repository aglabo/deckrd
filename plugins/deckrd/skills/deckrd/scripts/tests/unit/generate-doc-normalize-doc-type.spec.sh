#!/usr/bin/env bash
# generate-doc-normalize-doc-type.spec.sh - ShellSpec tests for normalize_doc_type function in generate-doc.sh
#
# Copyright (c) 2025 atsushifx <https://github.com/atsushifx>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

Include spec_helper.sh

# shellcheck source=../generate-doc.sh
. "${SCRIPTS_DIR}/generate-doc.sh"

Describe "normalize_doc_type"

Before "setup_deckrd_tmpdir"
After "teardown_deckrd_tmpdir"

Describe "short形式 → long形式"
It "req → requirements"
When run normalize_doc_type req
The status should equal 0
The output should equal "requirements"
End

It "spec → specifications"
When run normalize_doc_type spec
The status should equal 0
The output should equal "specifications"
End

It "impl → implementation"
When run normalize_doc_type impl
The status should equal 0
The output should equal "implementation"
End

It "task → tasks"
When run normalize_doc_type task
The status should equal 0
The output should equal "tasks"
End
End

Describe "long形式はそのまま返す"
It "requirements → requirements"
When run normalize_doc_type requirements
The status should equal 0
The output should equal "requirements"
End

It "review → review"
When run normalize_doc_type review
The status should equal 0
The output should equal "review"
End
End

Describe "phase short形式 → review-<phase>"
It "explore → review-explore"
When run normalize_doc_type explore
The status should equal 0
The output should equal "review-explore"
End

It "harden → review-harden"
When run normalize_doc_type harden
The status should equal 0
The output should equal "review-harden"
End

It "fix → review-fix"
When run normalize_doc_type fix
The status should equal 0
The output should equal "review-fix"
End
End

Describe "phase long形式はそのまま返す"
It "review-explore → review-explore"
When run normalize_doc_type review-explore
The status should equal 0
The output should equal "review-explore"
End
End

Describe "不明なキーワード"
It "exit 1でエラーメッセージを返す"
When run normalize_doc_type invalid
The status should equal 1
The stderr should include "Unknown doc-type"
End
End

End
