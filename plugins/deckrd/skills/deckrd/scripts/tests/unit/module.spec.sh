#!/usr/bin/env bash
# plugins/deckrd/skills/deckrd/tests/module.spec.sh
# @(#) : BDD unit tests for module.sh (モジュールディレクトリ管理)
#
# Copyright (c) 2025 atsushifx <https://github.com/atsushifx>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

# shellcheck disable=SC1090

_RUNTIME_BOOTSTRAP="${SHELLSPEC_PROJECT_ROOT}/plugins/_runtime/libs/bootstrap.lib.sh"
. "$_RUNTIME_BOOTSTRAP" "--no-finalize"
unset _RUNTIME_BOOTSTRAP

Include ../spec_helper.sh

SCRIPT="${DECKRD_SCRIPTS_DIR}/module.sh"

# Helper: setup tmpdir and create .project.json with project name "myproject"
setup_deckrd_tmpdir_with_project() {
  setup_deckrd_tmpdir
  mkdir -p "$DECKRD_LOCAL_DATA"
  printf '{"project":"myproject","project_type":"feature","language":"shell","ai_model":"sonnet","created_at":"2026-01-01T00:00:00Z","updated_at":"2026-01-01T00:00:00Z"}\n' \
    >"${DECKRD_LOCAL_DATA}/.project.json"
}

# ============================================================================
# module.sh
# ============================================================================

Describe "module.sh"

  # --------------------------------------------------------------------------
  # Given: no arguments provided
  # --------------------------------------------------------------------------

  Describe "Given: no arguments provided"
    Before "setup_deckrd_tmpdir"
    After "teardown_deckrd_tmpdir"

    Describe "When: run without arguments"
      It "[Error] Should: exit with status 1 and output Usage and 'required' error"
        When run bash "$SCRIPT"
        The status should equal 1
        The output should include "Usage:"
        The stderr should include "required"
      End
    End
  End

  # --------------------------------------------------------------------------
  # Given: --help option provided
  # --------------------------------------------------------------------------

  Describe "Given: --help option provided"
    Before "setup_deckrd_tmpdir"
    After "teardown_deckrd_tmpdir"

    Describe "When: run with --help"
      It "[Normal] Should: exit with status 0 and output Usage"
        When run bash "$SCRIPT" --help
        The status should equal 0
        The output should include "Usage:"
      End
    End
  End

  # --------------------------------------------------------------------------
  # Given: unknown option provided
  # --------------------------------------------------------------------------

  Describe "Given: unknown option provided"
    Before "setup_deckrd_tmpdir"
    After "teardown_deckrd_tmpdir"

    Describe "When: run with unknown option"
      It "[Error] Should: exit with status 1 and output 'Unknown option' error"
        When run bash "$SCRIPT" --unknown
        The status should equal 1
        The output should include "Usage:"
        The stderr should include "Unknown option"
      End
    End
  End

  # --------------------------------------------------------------------------
  # Given: valid legacy format argument (<namespace>/<module>)
  # --------------------------------------------------------------------------

  Describe "Given: valid legacy format argument (<namespace>/<module>)"
    Before "setup_deckrd_tmpdir"
    After "teardown_deckrd_tmpdir"

    Describe "When: run with 'myns/mymod'"
      It "[Normal] Should: exit with status 0, create all module directories, skip .project.json, and output 'Session updated'"
        When run bash "$SCRIPT" myns/mymod
        The status should equal 0
        The output should include "myns/mymod"
        The output should include "requirements"
        The output should include "specifications"
        The output should include "implementation"
        The output should include "tasks"
        The output should include "Session updated"
        The path "${DECKRD_DOCS_DIR}/myns/mymod/requirements" should be directory
        The path "${DECKRD_DOCS_DIR}/myns/mymod/specifications" should be directory
        The path "${DECKRD_DOCS_DIR}/myns/mymod/implementation" should be directory
        The path "${DECKRD_DOCS_DIR}/myns/mymod/tasks" should be directory
        The path "${DECKRD_DOCS_DIR}/myns/mymod/.project.json" should not be exist
      End
    End

    Describe "When: run with uppercase 'MyNS/MyMod'"
      It "[Edge] Should: exit with status 1 and output 'invalid characters' error"
        When run bash "$SCRIPT" MyNS/MyMod
        The status should eq 1
        The stderr should include "invalid characters"
      End
    End
  End

# --------------------------------------------------------------------------
# Given: invalid legacy format argument
# --------------------------------------------------------------------------

  Describe "Given: invalid legacy format argument"
    Before "setup_deckrd_tmpdir"
    After "teardown_deckrd_tmpdir"

    Describe "When: run with '/mymod' (empty namespace)"
      It "[Error] Should: exit with status 1 and output 'empty' error"
        When run bash "$SCRIPT" "/mymod"
        The status should equal 1
        The stderr should include "empty"
      End
    End

    Describe "When: run with 'myns/' (empty module)"
      It "[Error] Should: exit with status 1 and output 'empty' error"
        When run bash "$SCRIPT" "myns/"
        The status should equal 1
        The stderr should include "empty"
      End
    End

    Describe "When: run with 'my ns/mymod' (space in namespace)"
      It "[Error] Should: exit with status 1 and output 'invalid characters' error"
        When run bash "$SCRIPT" "my ns/mymod"
        The status should equal 1
        The stderr should include "invalid characters"
      End
    End

    Describe "When: run with 'myns/mymod' on existing directory without --force"
      It "[Error] Should: exit with status 1 and output 'already exists' error"
        mkdir -p "${DECKRD_DOCS_DIR}/myns/mymod"
        When run bash "$SCRIPT" myns/mymod
        The status should equal 1
        The stderr should include "already exists"
      End
    End

    Describe "When: run with 'myns/mymod' on existing directory with --force"
      It "[Edge] Should: exit with status 0 and output 'myns/mymod'"
        mkdir -p "${DECKRD_DOCS_DIR}/myns/mymod"
        When run bash "$SCRIPT" myns/mymod --force
        The status should equal 0
        The output should include "myns/mymod"
      End
    End
  End

  # --------------------------------------------------------------------------
  # Given: create subcommand with <namespace>/<module> format
  # --------------------------------------------------------------------------

  Describe "Given: create subcommand with <namespace>/<module> format"
    Before "setup_deckrd_tmpdir"
    After "teardown_deckrd_tmpdir"

    Describe "When: run 'create myns/mymod'"
      It "[Normal] Should: exit with status 0, create module dirs, and output 'Session updated'"
        When run bash "$SCRIPT" create myns/mymod
        The status should equal 0
        The output should include "myns/mymod"
        The output should include "Session updated"
        The path "${DECKRD_DOCS_DIR}/myns/mymod/requirements" should be directory
        The path "${DECKRD_DOCS_DIR}/myns/mymod/specifications" should be directory
        The path "${DECKRD_DOCS_DIR}/myns/mymod/.project.json" should not be exist
      End
    End

    Describe "When: run create with invalid namespace 'my ns/mymod'"
      It "[Error] Should: exit with status 1 and output 'invalid characters' error"
        When run bash "$SCRIPT" create "my ns/mymod"
        The status should equal 1
        The stderr should include "invalid characters"
      End
    End
  End

  # --------------------------------------------------------------------------
  # Given: create subcommand with <module> format (git remote auto-completion)
  # --------------------------------------------------------------------------

  Describe "Given: create subcommand with <module> format"
    Before "setup_deckrd_tmpdir"
    After "teardown_deckrd_tmpdir"

    Describe "When: run 'create myfeature'"
      It "[Normal] Should: exit with status 0 and output 'myfeature'"
        When run bash "$SCRIPT" create myfeature
        The status should equal 0
        The output should include "myfeature"
      End
    End
  End

End
