#!/usr/bin/env bash
# plugins/deckrd/skills/deckrd/scripts/tests/unit/init-parse-args.spec.sh
# @(#) : BDD unit tests for init.sh - parse_args function
#
# Copyright (c) 2026- atsushifx <https://github.com/atsushifx>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

# shellcheck disable=SC1091

_LIB_DIR="$(cd "${SHELLSPEC_PROJECT_ROOT}/plugins/deckrd/skills/deckrd/scripts/libs" && pwd)"
. "${_LIB_DIR}/bootstrap.sh"
unset _LIB_DIR

Include ../spec_helper.sh

SCRIPT="${SCRIPTS_DIR}/init.sh"

# ============================================================================
# init.sh: parse_args
# ============================================================================

Describe "init.sh: parse_args"
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
    It "[Normal] Should: return 0, PROJECT_NAME and PROJECT_TYPE are empty"
      When call parse_args
      The status should equal 0
      The variable PROJECT_NAME should equal ""
      The variable PROJECT_TYPE should equal ""
    End
  End

  Describe "Given: two positional arguments"
    It "[Normal] Should: set PROJECT_NAME and PROJECT_TYPE"
      When call parse_args myapp webapp
      The status should equal 0
      The variable PROJECT_NAME should equal "myapp"
      The variable PROJECT_TYPE should equal "webapp"
    End
  End

  Describe "Given: --language option"
    It "[Normal] Should: set LANGUAGE"
      When call parse_args myapp webapp --language go
      The status should equal 0
      The variable LANGUAGE should equal "go"
    End
  End

  Describe "Given: --lang alias"
    It "[Normal] Should: set LANGUAGE"
      When call parse_args myapp webapp --lang rust
      The status should equal 0
      The variable LANGUAGE should equal "rust"
    End
  End

  Describe "Given: --language= syntax"
    It "[Normal] Should: set LANGUAGE"
      When call parse_args myapp webapp --language=python
      The status should equal 0
      The variable LANGUAGE should equal "python"
    End
  End

  Describe "Given: --language bash (alias)"
    It "[Normal] Should: normalize bash to shell"
      When call parse_args myapp webapp --language bash
      The status should equal 0
      The variable LANGUAGE should equal "shell"
    End
  End

  Describe "Given: --language=bash (alias, = syntax)"
    It "[Normal] Should: normalize bash to shell"
      When call parse_args myapp webapp --language=bash
      The status should equal 0
      The variable LANGUAGE should equal "shell"
    End
  End

  Describe "Given: --ai-model option"
    It "[Normal] Should: set AI_MODEL"
      When call parse_args myapp webapp --ai-model claude-sonnet-4-5
      The status should equal 0
      The variable AI_MODEL should equal "claude-sonnet-4-5"
    End
  End

  Describe "Given: --ai-model= syntax"
    It "[Normal] Should: set AI_MODEL"
      When call parse_args myapp webapp --ai-model=claude-sonnet-4-5
      The status should equal 0
      The variable AI_MODEL should equal "claude-sonnet-4-5"
    End
  End

  Describe "Given: unknown option"
    It "[Error] Should: return 1 and set PARSE_ARGS_ERROR"
      When call parse_args myapp webapp --unknown
      The status should equal 1
      The variable PARSE_ARGS_ERROR should include "Unknown option"
    End
  End

  Describe "Given: --language without value"
    It "[Error] Should: return 1 and set PARSE_ARGS_ERROR"
      When call parse_args myapp webapp --language
      The status should equal 1
      The variable PARSE_ARGS_ERROR should include "requires a value"
    End
  End

  Describe "Given: --ai-model without value"
    It "[Error] Should: return 1 and set PARSE_ARGS_ERROR"
      When call parse_args myapp webapp --ai-model
      The status should equal 1
      The variable PARSE_ARGS_ERROR should include "requires a value"
    End
  End

End
