#!/usr/bin/env bash
# plugins/deckrd/skills/deckrd/scripts/tests/unit/init-validate.spec.sh
# @(#) : BDD unit tests for init.sh - validate_args + validate_language functions
#
# Copyright (c) 2026- atsushifx <https://github.com/atsushifx>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

# shellcheck disable=SC1090

_RUNTIME_BOOTSTRAP="${SHELLSPEC_PROJECT_ROOT}/plugins/_runtime/libs/bootstrap.lib.sh"
. "$_RUNTIME_BOOTSTRAP" --no-finalize
unset _RUNTIME_BOOTSTRAP

Include ../spec_helper.sh

SCRIPT="${DECKRD_SCRIPTS_DIR}/init.sh"

# ============================================================================
# init.sh: validate_args + validate_language
# ============================================================================

Describe "init.sh: validate_args"
  # shellcheck disable=SC2329
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

  Describe "Given: valid PROJECT_NAME and PROJECT_TYPE"
    It "[Normal] Should: return 0"
      PROJECT_NAME="myapp"
      PROJECT_TYPE="webapp"
      When call validate_args
      The status should equal 0
    End
  End

  Describe "Given: PROJECT_NAME is empty"
    It "[Error] Should: return 1 and set VALIDATE_ARGS_ERROR"
      PROJECT_NAME=""
      PROJECT_TYPE="webapp"
      When call validate_args
      The status should equal 1
      The variable VALIDATE_ARGS_ERROR should include "required"
    End
  End

  Describe "Given: PROJECT_TYPE is empty"
    It "[Error] Should: return 1 and set VALIDATE_ARGS_ERROR"
      PROJECT_NAME="myapp"
      PROJECT_TYPE=""
      When call validate_args
      The status should equal 1
      The variable VALIDATE_ARGS_ERROR should include "required"
    End
  End

  Describe "Given: PROJECT_NAME has uppercase"
    It "[Error] Should: return 1 and set VALIDATE_ARGS_ERROR with 'invalid characters'"
      PROJECT_NAME="MyApp"
      PROJECT_TYPE="webapp"
      When call validate_args
      The status should equal 1
      The variable VALIDATE_ARGS_ERROR should include "invalid characters"
    End
  End

  Describe "Given: PROJECT_TYPE has uppercase"
    It "[Error] Should: return 1 and set VALIDATE_ARGS_ERROR with 'invalid characters'"
      PROJECT_NAME="myapp"
      PROJECT_TYPE="WebApp"
      When call validate_args
      The status should equal 1
      The variable VALIDATE_ARGS_ERROR should include "invalid characters"
    End
  End

  Describe "Given: PROJECT_NAME has space"
    It "[Edge] Should: return 1 and set VALIDATE_ARGS_ERROR with 'invalid characters'"
      # shellcheck disable=SC2034
      PROJECT_NAME="my app"
      # shellcheck disable=SC2034
      PROJECT_TYPE="webapp"
      When call validate_args
      The status should equal 1
      The variable VALIDATE_ARGS_ERROR should include "invalid characters"
    End
  End

End

Describe "init.sh: validate_language"
  load_script_with_mocks() {
    # shellcheck disable=SC2329
    validate_env() { return 0; }
    export -f validate_env

    # shellcheck disable=SC2329
    validate_ai_model() { return 0; }
    export -f validate_ai_model

    # shellcheck disable=SC1090
    . "$SCRIPT"
  }
  Before "load_script_with_mocks"
  Before "init_vars"

  Describe "Given: supported languages"
    It "[Normal] typescript is valid"
      When call validate_language typescript
      The status should equal 0
    End
    It "[Normal] go is valid"
      When call validate_language go
      The status should equal 0
    End
    It "[Normal] python is valid"
      When call validate_language python
      The status should equal 0
    End
    It "[Normal] rust is valid"
      When call validate_language rust
      The status should equal 0
    End
  End

  Describe "Given: unsupported language"
    It "[Error] cobol returns 1"
      When call validate_language cobol
      The status should equal 1
    End
    It "[Error] empty string returns 1"
      When call validate_language ""
      The status should equal 1
    End
  End

End
