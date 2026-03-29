#!/usr/bin/env bash
# status.spec.sh - ShellSpec tests for status.sh
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

SCRIPT="${DECKRD_SCRIPTS_DIR}/status.sh"

Describe "status.sh"
  Describe "Given: session.json does not exist"
    Before "setup_deckrd_tmpdir"
    After "teardown_deckrd_tmpdir"

    Describe "When: run status"
      It "[Error] Should: exit with status 1 and output 'No session file' message"
        When run bash "$SCRIPT"
        The status should equal 1
        The output should include "No session file"
      End
    End
  End

  Describe "Given: session.json exists without active module"
    Before "setup_deckrd_tmpdir"
    After "teardown_deckrd_tmpdir"

    Before "setup_no_active_session"
    setup_no_active_session() {
      mkdir -p "$DECKRD_LOCAL"
      cat >"${DECKRD_LOCAL}/session.json" <<'JSON'
{
  "current_step": "module",
  "completed": ["module"],
  "documents": {},
  "created_at": "2025-01-01T00:00:00Z",
  "updated_at": "2025-01-01T00:00:00Z"
}
JSON
    }

    Describe "When: run status"
      It "[Error] Should: exit with status 1 and output 'No active module' message"
        When run bash "$SCRIPT"
        The status should equal 1
        The output should include "No active module"
      End
    End
  End

  Describe "Given: session.json with active module"
    Before "setup_deckrd_tmpdir"
    After "teardown_deckrd_tmpdir"

    Before "setup_valid_session"
    setup_valid_session() {
      mkdir -p "$DECKRD_LOCAL"
      cat >"${DECKRD_LOCAL}/session.json" <<'JSON'
{
  "active": "myns/mymod",
  "modules": {
    "myns/mymod": {
      "current_step": "req",
      "completed": ["module", "req"]
    }
  },
  "created_at": "2025-01-01T00:00:00Z",
  "updated_at": "2026-06-01T00:00:00Z"
}
JSON
    }

    Describe "When: run status"
      It "[Normal] Should: exit with status 0, output 'DECKRD Status' header, and display active module name"
        When run bash "$SCRIPT"
        The status should equal 0
        The output should include "DECKRD Status"
        The output should include "myns/mymod"
      End
    End
  End
End
