#!/usr/bin/env bash
# generate-doc-get-prompt-file.spec.sh - ShellSpec tests for get_prompt_file in generate-doc.sh
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

Describe "generate-doc.sh get_prompt_file"

  Before "setup_deckrd_tmpdir"
  After "teardown_deckrd_tmpdir"

  Describe "Given: @<keyword> 形式の引数"
    Describe "When: get_prompt_file を呼ぶ"
      Parameters
        "@req" "requirements"
        "@requirements" "requirements"
      End

      It "Then: [Normal] T-SUB-GPF-01: $1 → exit 0、stdout に $2 のみ返す"
        When call get_prompt_file "$1"
        The output should equal "$2"
        The stderr should be blank
        The status should equal 0
      End
    End
  End

  Describe "Given: @ で始まらない引数"
    Describe "When: get_prompt_file を呼ぶ"
      It "Then: [Error] T-SUB-GPF-02: requirements → exit 1、stderr にエラーを出し stdout は空"
        When call get_prompt_file 'requirements'
        The output should be blank
        The stderr should include 'Error: argument must start with @'
        The status should equal 1
      End
    End
  End

End
