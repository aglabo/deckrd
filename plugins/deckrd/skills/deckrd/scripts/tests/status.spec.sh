#!/usr/bin/env bash
# status.spec.sh - ShellSpec tests for status.sh
#
# Copyright (c) 2025 atsushifx <https://github.com/atsushifx>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

Include spec_helper.sh

SCRIPT="${SCRIPTS_DIR}/status.sh"

Describe "status.sh"

<<<<<<< HEAD
  Describe "Given: session.json does not exist"

    Before "setup_deckrd_tmpdir"
    After  "teardown_deckrd_tmpdir"

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
    After  "teardown_deckrd_tmpdir"

    Before "setup_no_active_session"
    setup_no_active_session() {
      mkdir -p "$DECKRD_LOCAL"
      cat > "${DECKRD_LOCAL}/session.json" <<'JSON'
{
  "current_step": "init",
  "completed": ["init"],
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
    After  "teardown_deckrd_tmpdir"

    Before "setup_valid_session"
    setup_valid_session() {
      mkdir -p "$DECKRD_LOCAL"
      cat > "${DECKRD_LOCAL}/session.json" <<'JSON'
{
  "active": "myns/mymod",
  "modules": {
    "myns/mymod": {
      "current_step": "req",
      "completed": ["init", "req"]
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

||||||| f6e572e
=======
  Before "setup_deckrd_tmpdir"
  After  "teardown_deckrd_tmpdir"

  Describe "session.json が存在しない場合"
    It "エラーメッセージを出力してexit 1する"
      When run bash "$SCRIPT"
      The status should equal 1
      The output should include "No session file"
    End
  End

  Describe "active が設定されていない session.json"
    Before "setup_no_active_session"
    setup_no_active_session() {
      mkdir -p "$DECKRD_LOCAL"
      cat > "${DECKRD_LOCAL}/session.json" <<'JSON'
{
  "current_step": "init",
  "completed": ["init"],
  "documents": {},
  "created_at": "2025-01-01T00:00:00Z",
  "updated_at": "2025-01-01T00:00:00Z"
}
JSON
    }

    It "エラーメッセージを出力してexit 1する"
      When run bash "$SCRIPT"
      The status should equal 1
      The output should include "No active module"
    End
  End

  Describe "正常系 (active モジュールあり)"
    Before "setup_valid_session"
    setup_valid_session() {
      mkdir -p "$DECKRD_LOCAL"
      cat > "${DECKRD_LOCAL}/session.json" <<'JSON'
{
  "active": "myns/mymod",
  "modules": {
    "myns/mymod": {
      "current_step": "req",
      "completed": ["init", "req"]
    }
  },
  "created_at": "2025-01-01T00:00:00Z",
  "updated_at": "2026-06-01T00:00:00Z"
}
JSON
    }

    It "exit 0する"
      When run bash "$SCRIPT"
      The status should equal 0
      The output should include "DECKRD Status"
    End

    It "DECKRD Status ヘッダーを出力する"
      When run bash "$SCRIPT"
      The output should include "DECKRD Status"
    End

    It "active モジュールを表示する"
      When run bash "$SCRIPT"
      The output should include "myns/mymod"
    End
>>>>>>> main
  End

End
