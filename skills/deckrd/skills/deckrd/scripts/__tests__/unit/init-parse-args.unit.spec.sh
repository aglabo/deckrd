#!/usr/bin/env bash
# plugins/deckrd/skills/deckrd/scripts/tests/unit/init-parse-args.spec.sh
# @(#) : BDD unit tests for init.sh - parse_args function
#
# Copyright (c) 2026- atsushifx <https://github.com/atsushifx>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

# shellcheck disable=SC1090

_RUNTIME_BOOTSTRAP="${SHELLSPEC_PROJECT_ROOT}/skills/deckrd/skills/deckrd/scripts/libs/bootstrap.lib.sh"
. "$_RUNTIME_BOOTSTRAP" --no-finalize
unset _RUNTIME_BOOTSTRAP

Include ../spec_helper.sh

SCRIPT="${DECKRD_SCRIPTS_DIR}/init.sh"

# ============================================================================
# init.sh: parse_args
# ============================================================================

Describe "T-CLI-PA: init.sh: parse_args"
  load_script_with_mocks() {
    # Mock: validate_env を常に成功させる
    # shellcheck disable=SC2329
    validate_env() { return 0; }
    export -f validate_env

    # Mock: validate_ai_model を常に成功させる（stdout は空）
    # shellcheck disable=SC2329
    validate_ai_model() { return 0; }
    export -f validate_ai_model

    # init.sh を source して関数をロード
    # shellcheck disable=SC1090
    . "$SCRIPT"
  }
  Before "load_script_with_mocks"
  Before "init_vars"

  Describe "Given: no arguments"
    It "[Normal] T-CLI-PA-01: Should: return 0 and reset OPTIONS to defaults"
      When call parse_args
      The status should equal 0
      The value "${OPTIONS[project]}" should equal ""
      The value "${OPTIONS[project_type]}" should equal ""
      The value "${OPTIONS[language]}" should equal "typescript"
      The value "${OPTIONS[ai_model]}" should equal "sonnet"
      The value "${OPTIONS[help]}" should equal false
    End
  End

  Describe "Given: two positional arguments"
    It "[Normal] T-CLI-PA-02: Should: set OPTIONS[project] and OPTIONS[project_type]"
      When call parse_args myapp webapp
      The status should equal 0
      The value "${OPTIONS[project]}" should equal "myapp"
      The value "${OPTIONS[project_type]}" should equal "webapp"
    End

    It "[Normal] T-CLI-PA-15: Should: keep OPTIONS[help]=false without help flag"
      When call parse_args myapp webapp
      The status should equal 0
      The value "${OPTIONS[help]}" should equal false
    End
  End

  Describe "Given: --language option"
    It "[Normal] T-CLI-PA-03: Should: set OPTIONS[language]"
      When call parse_args myapp webapp --language go
      The status should equal 0
      The value "${OPTIONS[language]}" should equal "go"
    End
  End

  Describe "Given: --lang alias"
    It "[Normal] T-CLI-PA-04: Should: set OPTIONS[language]"
      When call parse_args myapp webapp --lang rust
      The status should equal 0
      The value "${OPTIONS[language]}" should equal "rust"
    End
  End

  Describe "Given: --language= syntax"
    It "[Normal] T-CLI-PA-05: Should: set OPTIONS[language]"
      When call parse_args myapp webapp --language=python
      The status should equal 0
      The value "${OPTIONS[language]}" should equal "python"
    End
  End

  Describe "Given: --language bash (alias)"
    It "[Normal] T-CLI-PA-06: Should: normalize bash to shell"
      When call parse_args myapp webapp --language bash
      The status should equal 0
      The value "${OPTIONS[language]}" should equal "shell"
    End
  End

  Describe "Given: --language=bash (alias, = syntax)"
    It "[Normal] T-CLI-PA-07: Should: normalize bash to shell"
      When call parse_args myapp webapp --language=bash
      The status should equal 0
      The value "${OPTIONS[language]}" should equal "shell"
    End
  End

  Describe "Given: --ai-model option"
    It "[Normal] T-CLI-PA-08: Should: set OPTIONS[ai_model]"
      When call parse_args myapp webapp --ai-model claude-sonnet-4-5
      The status should equal 0
      The value "${OPTIONS[ai_model]}" should equal "claude-sonnet-4-5"
    End
  End

  Describe "Given: --ai-model= syntax"
    It "[Normal] T-CLI-PA-09: Should: set OPTIONS[ai_model]"
      When call parse_args myapp webapp --ai-model=claude-sonnet-4-5
      The status should equal 0
      The value "${OPTIONS[ai_model]}" should equal "claude-sonnet-4-5"
    End
  End

  Describe "Given: unknown option"
    It "[Error] T-CLI-PA-10: Should: return 1 and set PARSE_ARGS_ERROR"
      When call parse_args myapp webapp --unknown
      The status should equal 1
      The variable PARSE_ARGS_ERROR should include "Unknown option"
    End
  End

  Describe "Given: --language without value"
    It "[Error] T-CLI-PA-11: Should: return 1 and set PARSE_ARGS_ERROR"
      When call parse_args myapp webapp --language
      The status should equal 1
      The variable PARSE_ARGS_ERROR should include "requires a value"
    End
  End

  Describe "Given: --ai-model without value"
    It "[Error] T-CLI-PA-12: Should: return 1 and set PARSE_ARGS_ERROR"
      When call parse_args myapp webapp --ai-model
      The status should equal 1
      The variable PARSE_ARGS_ERROR should include "requires a value"
    End
  End

  Describe "Given: --help option"
    It "[Normal] T-CLI-PA-13: Should: set OPTIONS[help]=true and return 0 for --help"
      When call parse_args --help
      The status should equal 0
      The value "${OPTIONS[help]}" should equal true
      The stderr should equal ""
    End
  End

  Describe "Given: -h option"
    It "[Normal] T-CLI-PA-14: Should: set OPTIONS[help]=true and return 0 for -h"
      When call parse_args -h
      The status should equal 0
      The value "${OPTIONS[help]}" should equal true
      The stderr should equal ""
    End
  End

  Describe "Given: repeated calls"
    # shellcheck disable=SC2329
    _parse_help_then_positional() {
      parse_args -h
      parse_args myapp webapp
    }

    It "[Normal] T-CLI-PA-16: Should: reset OPTIONS[help] to false on next call"
      When call _parse_help_then_positional
      The status should equal 0
      The value "${OPTIONS[help]}" should equal false
    End
  End

End
