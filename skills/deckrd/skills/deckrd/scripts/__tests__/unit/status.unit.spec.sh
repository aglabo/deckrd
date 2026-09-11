#!/usr/bin/env bash
# status.spec.sh - ShellSpec tests for status.sh
#
# Copyright (c) 2025 atsushifx <https://github.com/atsushifx>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

# shellcheck disable=SC1090

_RUNTIME_BOOTSTRAP="${SHELLSPEC_PROJECT_ROOT}/skills/deckrd/skills/deckrd/scripts/libs/bootstrap.lib.sh"
. "$_RUNTIME_BOOTSTRAP" "--no-finalize"
unset _RUNTIME_BOOTSTRAP

Include ../spec_helper.sh

SCRIPT="${DECKRD_SCRIPTS_DIR}/status.sh"

Describe "status.sh"
  Describe "Given: session.json does not exist"
    Before "setup_deckrd_tmpdir"
    After "teardown_deckrd_tmpdir"

    Describe "When: run status"
      It "[Error] T-CLI-ST-01: Should: exit with status 1 and output 'No session file' message"
        When run bash "$SCRIPT"
        The status should equal 1
        The stderr should include "No session file"
        The output should not include "Error:"
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
      It "[Error] T-CLI-ST-02: Should: exit with status 1 and output 'No active module' message"
        When run bash "$SCRIPT"
        The status should equal 1
        The stderr should include "No active module"
        The output should not include "Error:"
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
      It "[Normal] T-CLI-ST-03: Should: exit with status 0, output 'DECKRD Status' header, and display active module name"
        When run bash "$SCRIPT"
        The status should equal 0
        The output should include "DECKRD Status"
        The output should include "myns/mymod"
      End
    End
  End

  Describe "Given: validate_env fails"
    Before "setup_deckrd_tmpdir"
    After "teardown_deckrd_tmpdir"

    mock_validate_env_failure() {
      # shellcheck disable=SC2329
      validate_env() { echo "Error: jq or jaq is required but not installed." >&2; return 1; }
      export -f validate_env
    }
    unmock_validate_env_failure() {
      unset -f validate_env
    }
    Before "mock_validate_env_failure"
    After "unmock_validate_env_failure"

    Describe "When: run status"
      It "[Error] T-CLI-ST-04: Should: exit with status 1, output the library message to stderr, and keep stdout blank"
        When run bash "$SCRIPT"
        The status should equal 1
        The stderr should include "jq or jaq is required"
        The output should be blank
      End
    End
  End
End
