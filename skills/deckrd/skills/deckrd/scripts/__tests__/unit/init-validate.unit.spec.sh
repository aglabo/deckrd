#!/usr/bin/env bash
# plugins/deckrd/skills/deckrd/scripts/tests/unit/init-validate.spec.sh
# @(#) : BDD unit tests for init.sh - validate_args + validate_language functions
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
# init.sh: validate_args + validate_language
# ============================================================================

Describe "T-CLI-VA: init.sh: validate_args"
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

  Describe "Given: valid OPTIONS[project] and OPTIONS[project_type]"
    It "[Normal] T-CLI-VA-01: Should: return 0"
      OPTIONS["project"]="myapp"
      OPTIONS["project_type"]="webapp"
      When call validate_args
      The status should equal 0
    End
  End

  Describe "Given: OPTIONS[project] is empty"
    It "[Error] T-CLI-VA-02: Should: return 1 and set VALIDATE_ARGS_ERROR"
      OPTIONS["project"]=""
      OPTIONS["project_type"]="webapp"
      When call validate_args
      The status should equal 1
      The variable VALIDATE_ARGS_ERROR should include "required"
    End
  End

  Describe "Given: OPTIONS[project_type] is empty"
    It "[Error] T-CLI-VA-03: Should: return 1 and set VALIDATE_ARGS_ERROR"
      OPTIONS["project"]="myapp"
      OPTIONS["project_type"]=""
      When call validate_args
      The status should equal 1
      The variable VALIDATE_ARGS_ERROR should include "required"
    End
  End

  Describe "Given: OPTIONS[project] has uppercase"
    It "[Error] T-CLI-VA-04: Should: return 1 and set VALIDATE_ARGS_ERROR with 'invalid characters'"
      OPTIONS["project"]="MyApp"
      OPTIONS["project_type"]="webapp"
      When call validate_args
      The status should equal 1
      The variable VALIDATE_ARGS_ERROR should include "invalid characters"
    End
  End

  Describe "Given: OPTIONS[project_type] has uppercase"
    It "[Error] T-CLI-VA-05: Should: return 1 and set VALIDATE_ARGS_ERROR with 'invalid characters'"
      OPTIONS["project"]="myapp"
      OPTIONS["project_type"]="WebApp"
      When call validate_args
      The status should equal 1
      The variable VALIDATE_ARGS_ERROR should include "invalid characters"
    End
  End

  Describe "Given: OPTIONS[project] has space"
    It "[Edge] T-CLI-VA-06: Should: return 1 and set VALIDATE_ARGS_ERROR with 'invalid characters'"
      # shellcheck disable=SC2034
      OPTIONS["project"]="my app"
      # shellcheck disable=SC2034
      OPTIONS["project_type"]="webapp"
      When call validate_args
      The status should equal 1
      The variable VALIDATE_ARGS_ERROR should include "invalid characters"
    End
  End

End

Describe "T-CLI-VL: init.sh: validate_language"
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
    It "[Normal] T-CLI-VL-01: typescript is valid"
      When call validate_language typescript
      The status should equal 0
    End
    It "[Normal] T-CLI-VL-02: go is valid"
      When call validate_language go
      The status should equal 0
    End
    It "[Normal] T-CLI-VL-03: python is valid"
      When call validate_language python
      The status should equal 0
    End
    It "[Normal] T-CLI-VL-04: rust is valid"
      When call validate_language rust
      The status should equal 0
    End
  End

  Describe "Given: unsupported language"
    It "[Error] T-CLI-VL-05: cobol returns 1"
      When call validate_language cobol
      The status should equal 1
    End
    It "[Error] T-CLI-VL-06: empty string returns 1"
      When call validate_language ""
      The status should equal 1
    End
  End

End
