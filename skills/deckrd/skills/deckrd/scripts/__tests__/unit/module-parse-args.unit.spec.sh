#!/usr/bin/env bash
# skills/deckrd/skills/deckrd/scripts/__tests__/unit/module-parse-args.unit.spec.sh
# @(#) : BDD unit tests for module.sh - init_vars / parse_args functions
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

SCRIPT="${DECKRD_SCRIPTS_DIR}/module.sh"

# ============================================================================
# Internal helpers
# ============================================================================

##
# @description Source module.sh with validate_env mocked to succeed
# @description Loads the functions only; the top-level execution block is skipped when sourced
load_script_with_mocks() {
  # Mock: validate_env を常に成功させる
  # shellcheck disable=SC2329
  validate_env() { return 0; }
  export -f validate_env

  # module.sh を source して関数をロード
  # shellcheck disable=SC1090
  . "$SCRIPT"
}

# ============================================================================
# module.sh: init_vars
# ============================================================================

##
# init_vars sets the script configuration variables.
# SESSION_FILE honors a non-empty preset value (mock / override); the other
# variables are reset to their defaults on every call.
Describe "T-CLI-MIV: module.sh: init_vars"
  Before "load_script_with_mocks"

  Describe "Given: SESSION_FILE is unset"
    It "[Normal] T-CLI-MIV-01: Should: set default configuration variables"
      unset SESSION_FILE
      When call init_vars
      The status should equal 0
      The value "$SESSION_FILE" should equal "${DECKRD_LOCAL_DATA}/session.json"
      The value "${SUBDIRS[*]}" should equal "requirements specifications implementation tasks workspaces"
      The value "$MODULE_META_SUBPATH" should equal "workspaces/module/module.md"
      The value "$SUBCOMMAND" should equal ""
      The value "$(declare -p OPTIONS 2>&1)" should start with "declare -A OPTIONS"
    End
  End

  Describe "Given: SESSION_FILE is an empty string"
    It "[Error] T-CLI-MIV-02: Should: fall back to the default SESSION_FILE"
      SESSION_FILE=""
      When call init_vars
      The value "$SESSION_FILE" should equal "${DECKRD_LOCAL_DATA}/session.json"
    End
  End

  Describe "Given: SESSION_FILE is preset to a custom path"
    It "[Edge] T-CLI-MIV-03: Should: keep the preset SESSION_FILE"
      SESSION_FILE="/tmp/custom/session.json"
      When call init_vars
      The value "$SESSION_FILE" should equal "/tmp/custom/session.json"
    End
  End

  Describe "Given: SUBCOMMAND is left over from a previous run"
    It "[Edge] T-CLI-MIV-04: Should: reset SUBCOMMAND to empty"
      SUBCOMMAND="create"
      When call init_vars
      The value "$SUBCOMMAND" should equal ""
    End
  End
End

# ============================================================================
# module.sh: parse_args
# ============================================================================

##
# parse_args stores the arguments in OPTIONS / SUBCOMMAND and reports errors
# through PARSE_ARGS_ERROR + return 1. It never exits and never prints usage;
# the caller decides how to report.
Describe "T-CLI-MPA: module.sh: parse_args"
  Before "load_script_with_mocks"
  Before "init_vars"

  Describe "Given: valid arguments"
    Describe "When: parse_args is called"
      It "[Normal] T-CLI-MPA-01: Should: reset OPTIONS to defaults with no arguments"
        When call parse_args
        The status should equal 0
        The output should equal ""
        The value "${OPTIONS[module_path]}" should equal ""
        The value "${OPTIONS[force]}" should equal false
        The value "${OPTIONS[test_scope]}" should equal ""
        The value "${OPTIONS[help]}" should equal false
        The value "$SUBCOMMAND" should equal ""
      End

      It "[Normal] T-CLI-MPA-02: Should: store the module path in OPTIONS[module_path]"
        When call parse_args myns/mymod
        The status should equal 0
        The output should equal ""
        The value "${OPTIONS[module_path]}" should equal "myns/mymod"
        The value "$SUBCOMMAND" should equal ""
      End

      It "[Normal] T-CLI-MPA-03: Should: set SUBCOMMAND=create for a leading create"
        When call parse_args create myns/mymod
        The status should equal 0
        The output should equal ""
        The value "$SUBCOMMAND" should equal "create"
        The value "${OPTIONS[module_path]}" should equal "myns/mymod"
      End

      It "[Normal] T-CLI-MPA-04: Should: set OPTIONS[force]=true for --force"
        When call parse_args myns/mymod --force
        The status should equal 0
        The output should equal ""
        The value "${OPTIONS[force]}" should equal true
      End

      It "[Normal] T-CLI-MPA-05: Should: set OPTIONS[test_scope] for --test-scope"
        When call parse_args myns/mymod --test-scope XY
        The status should equal 0
        The output should equal ""
        The value "${OPTIONS[test_scope]}" should equal "XY"
      End

      It "[Normal] T-CLI-MPA-06: Should: set OPTIONS[help]=true without printing usage"
        When call parse_args --help
        The status should equal 0
        The output should equal ""
        The value "${OPTIONS[help]}" should equal true
      End
    End
  End

  Describe "Given: invalid arguments"
    Describe "When: parse_args is called"
      It "[Error] T-CLI-MPA-07: Should: report a missing --test-scope value"
        When call parse_args myns/mymod --test-scope
        The status should equal 1
        The output should equal ""
        The error should equal ""
        The value "$PARSE_ARGS_ERROR" should equal "--test-scope requires a value"
      End

      It "[Error] T-CLI-MPA-08: Should: report an unknown option"
        When call parse_args myns/mymod --bogus
        The status should equal 1
        The output should equal ""
        The error should equal ""
        The value "$PARSE_ARGS_ERROR" should equal "Unknown option: --bogus"
      End

      It "[Error] T-CLI-MPA-09: Should: report multiple module paths"
        When call parse_args a/b c/d
        The status should equal 1
        The output should equal ""
        The error should equal ""
        The value "$PARSE_ARGS_ERROR" should equal "Multiple module paths specified"
      End
    End
  End

  Describe "Given: edge-case arguments"
    Describe "When: parse_args is called"
      It "[Edge] T-CLI-MPA-10: Should: reject an empty --test-scope value"
        When call parse_args myns/mymod --test-scope ""
        The status should equal 1
        The output should equal ""
        The value "$PARSE_ARGS_ERROR" should equal "--test-scope requires a value"
      End

      It "[Edge] T-CLI-MPA-11: Should: accept create alone with an empty module path"
        When call parse_args create
        The status should equal 0
        The output should equal ""
        The value "$SUBCOMMAND" should equal "create"
        The value "${OPTIONS[module_path]}" should equal ""
        The value "${OPTIONS[force]}" should equal false
      End

      It "[Edge] T-CLI-MPA-12: Should: stop at --help before a later invalid option"
        When call parse_args --help --bogus
        The status should equal 0
        The output should equal ""
        The value "${OPTIONS[help]}" should equal true
        The value "$PARSE_ARGS_ERROR" should equal ""
      End

      It "[Edge] T-CLI-MPA-13: Should: treat a non-leading create as a second module path"
        When call parse_args myns/mymod create
        The status should equal 1
        The output should equal ""
        The value "$PARSE_ARGS_ERROR" should equal "Multiple module paths specified"
      End
    End
  End

  Describe "Given: values left over from a previous call"
    ##
    # @description Parse a full argument set, then parse again with no arguments
    parse_args_twice() {
      parse_args create myns/mymod --force --test-scope XY
      parse_args
    }

    Describe "When: parse_args is called again with no arguments"
      It "[Edge] T-CLI-MPA-14: Should: reset OPTIONS and SUBCOMMAND"
        When call parse_args_twice
        The status should equal 0
        The output should equal ""
        The value "${OPTIONS[module_path]}" should equal ""
        The value "${OPTIONS[force]}" should equal false
        The value "${OPTIONS[test_scope]}" should equal ""
        The value "$SUBCOMMAND" should equal ""
      End
    End
  End
End
