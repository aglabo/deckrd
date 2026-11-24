#!/usr/bin/env bash
# skills/deckrd/skills/deckrd/scripts/__tests__/unit/module-update-session.unit.spec.sh
# @(#) : BDD unit tests for module.sh - update_session function
#
# Copyright (c) 2026- atsushifx <https://github.com/atsushifx>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

# shellcheck disable=SC1090,SC2034,SC2154

# ============================================================================
# Test infrastructure
# ============================================================================

_RUNTIME_BOOTSTRAP="${SHELLSPEC_PROJECT_ROOT}/skills/deckrd/skills/deckrd/scripts/libs/bootstrap.lib.sh"
. "$_RUNTIME_BOOTSTRAP" --no-finalize
unset _RUNTIME_BOOTSTRAP

Include "${SHELLSPEC_SPECFILE%/*}/../spec_helper.sh"

# ============================================================================
# Target
# ============================================================================

SCRIPT="${DECKRD_SCRIPTS_DIR}/module.sh"

# ============================================================================
# Internal helpers
# ============================================================================

# --- Constants ---

# ISO 8601 UTC timestamp pattern written by update_session (created_at / updated_at)
_ISO_UTC_PATTERN='^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$'

# modules entry written for myns/mymod with scope MM
_SESSION_MODULE_ENTRY='{"current_step":"module","completed":["module"],"documents":{},"test_scope":"MM"}'

# Existing session.json with another module and an extra top-level key (MUS-02)
_SESSION_EXISTING='{"active":"old/mod","lang":"ja","modules":{"old/mod":{"current_step":"spec"}},"created_at":"2026-01-01T00:00:00Z","updated_at":"2026-01-01T00:00:00Z"}'

# Two-module session for switch_session: ns/a is active with req progress, ns/b is untouched
_SESSION_SWITCH_MODULES='{"ns/a":{"current_step":"req","completed":["module","req"],"documents":{"req":"x.md"},"test_scope":"AAA"},"ns/b":{"current_step":"module","completed":["module"],"documents":{},"test_scope":"BBB"}}'
_SESSION_SWITCH="{\"active\":\"ns/a\",\"modules\":${_SESSION_SWITCH_MODULES},\"created_at\":\"2026-01-01T00:00:00Z\",\"updated_at\":\"2026-01-01T00:00:00Z\"}"

# --- Functions ---

##
# @description Source module.sh with validate_env stubbed out.
#   module.sh guards main() with BASH_SOURCE, so sourcing only defines functions.
# @return 0
_load_script_with_mocks() {
  # shellcheck disable=SC2329
  validate_env() { return 0; }
  export -f validate_env

  . "$SCRIPT"
}

##
# @description Create a per-example temp dir and point DECKRD_LOCAL_DATA and
#   SESSION_FILE into it.
# @set _SESSION_TMPDIR, DECKRD_LOCAL_DATA, SESSION_FILE
# @return 0
_setup_session() {
  _SESSION_TMPDIR="$(mktemp -d)"
  DECKRD_LOCAL_DATA="$_SESSION_TMPDIR"
  SESSION_FILE="${_SESSION_TMPDIR}/session.json"
}

##
# @description Remove the per-example temp dir created by _setup_session.
# @return 0
_teardown_session() {
  [[ -n "${_SESSION_TMPDIR:-}" && -d "$_SESSION_TMPDIR" ]] && rm -rf "$_SESSION_TMPDIR"
  unset _SESSION_TMPDIR
  return 0
}

##
# @description Write a fixture to SESSION_FILE verbatim (no trailing newline).
# @arg $1 string fixture contents (one of the _SESSION_* constants)
# @return 0
_write_session_fixture() {
  printf '%s' "$1" >"$SESSION_FILE"
}

##
# @description List temporary files (session.json.tmp*) left in DECKRD_LOCAL_DATA.
#   Blank output means no leftover tmp file.
# @stdout one path per leftover tmp file
# @return 0
_list_session_tmp() {
  find "$DECKRD_LOCAL_DATA" -name 'session.json.tmp*' 2>/dev/null
}

##
# @description Stub write_json_file to fail without touching the filesystem.
#   Call inside the example body, after module.sh is sourced (Before hook), so
#   this definition overrides the real one from utils.lib.sh.
# @return 0
_mock_write_json_file_fail() {
  # shellcheck disable=SC2329
  write_json_file() { return 1; }
}

##
# @description Stub the steps main runs before update_session, so main reaches
#   update_session without touching the file system.
#   Call inside the example body, after module.sh is sourced (Before hook).
# @return 0
_stub_main_steps_before_session() {
  # shellcheck disable=SC2329
  validate_and_normalize_with_fallback() { printf '%s\n' "$1"; }
  # shellcheck disable=SC2329
  create_module_dirs() { :; }
  # shellcheck disable=SC2329
  read_declared_scope() { :; }
  # shellcheck disable=SC2329
  resolve_test_scope() { echo "MM"; }
  # shellcheck disable=SC2329
  create_module_meta() { :; }
}

##
# @description Write the two-module session fixture used by switch_session tests
#   (active ns/a with req progress, ns/b at module step).
# @return 0
_write_switch_fixture() {
  _write_session_fixture "$_SESSION_SWITCH"
}

##
# @description Query SESSION_FILE with jq (compact output, CR stripped).
# @arg ... jq options and filter (the filter last)
# @stdout jq result
# @return jq exit code
_session_query() {
  jq_read -c "$@" "$SESSION_FILE"
}

# ============================================================================
# Tests
# ============================================================================

# update_session writes session.json through write_json_file: a new file is
# created, an existing one is merged (other modules and keys kept).
Describe "T-CLI-MUS: module.sh: update_session"
  Before "_load_script_with_mocks" "_setup_session" "init_vars"
  After "_teardown_session"

  Describe "When: 正常系"
    It "[Normal] T-CLI-MUS-01: no session.json -> created with active/modules, created_at == updated_at (ISO), summary on stdout, no tmp left"
      When call update_session myns/mymod MM
      The status should equal 0
      The stdout should include "Session updated: ${SESSION_FILE}"
      The stdout should include "  active module: myns/mymod"
      The stderr should be blank
      The value "$(_session_query '{active, modules}')" should equal "{\"active\":\"myns/mymod\",\"modules\":{\"myns/mymod\":${_SESSION_MODULE_ENTRY}}}"
      # shellcheck disable=SC2016
      The value "$(_session_query --arg re "$_ISO_UTC_PATTERN" '.created_at == .updated_at and (.created_at | test($re))')" should equal "true"
      The value "$(_list_session_tmp)" should be blank
    End

    It "[Normal] T-CLI-MUS-02: existing session.json -> merged: active/module entry set, other module, lang and created_at kept, updated_at refreshed, no tmp left"
      _write_session_fixture "$_SESSION_EXISTING"
      When call update_session myns/mymod MM
      The status should equal 0
      The stdout should include "Session updated: ${SESSION_FILE}"
      The value "$(_session_query '.active')" should equal '"myns/mymod"'
      The value "$(_session_query '.modules["myns/mymod"]')" should equal "$_SESSION_MODULE_ENTRY"
      The value "$(_session_query '.modules["old/mod"]')" should equal '{"current_step":"spec"}'
      The value "$(_session_query '[.lang, .created_at]')" should equal '["ja","2026-01-01T00:00:00Z"]'
      # shellcheck disable=SC2016
      The value "$(_session_query --arg re "$_ISO_UTC_PATTERN" '.updated_at | test($re) and . != "2026-01-01T00:00:00Z"')" should equal "true"
      The value "$(_list_session_tmp)" should be blank
    End
  End

  Describe "When: 異常系 (write_json_file fails)"
    It "[Error] T-CLI-MUS-03: existing session.json + write_json_file fails -> Error on stderr, status 1, no summary, content unchanged, no tmp left"
      _write_session_fixture "$_SESSION_EXISTING"
      _mock_write_json_file_fail
      When call update_session myns/mymod MM
      The status should equal 1
      The stderr should include "Error: update_session: failed to write: ${SESSION_FILE}"
      The stdout should not include "Session updated"
      The contents of file "$SESSION_FILE" should equal "$_SESSION_EXISTING"
      The value "$(_list_session_tmp)" should be blank
    End

    It "[Error] T-CLI-MUS-04: no session.json + write_json_file fails -> Error on stderr, status 1, no summary, no file created, no tmp left"
      _mock_write_json_file_fail
      When call update_session myns/mymod MM
      The status should equal 1
      The stderr should include "Error: update_session: failed to write: ${SESSION_FILE}"
      The stdout should not include "Session updated"
      The path "$SESSION_FILE" should not be exist
      The value "$(_list_session_tmp)" should be blank
    End
  End

  Describe "When: エッジケース (real write failure / boundary input)"
    It "[Edge] T-CLI-MUS-05: session.json is not valid JSON -> Error on stderr, status 1, no summary, content unchanged, no tmp left"
      _write_session_fixture "not json"
      When call update_session myns/mymod MM
      The status should equal 1
      The stderr should include "Error: update_session: failed to write: ${SESSION_FILE}"
      The stdout should not include "Session updated"
      The contents of file "$SESSION_FILE" should equal "not json"
      The value "$(_list_session_tmp)" should be blank
    End

    It "[Edge] T-CLI-MUS-06: SESSION_FILE is a directory -> Error on stderr, status 1, no summary, directory kept empty, no tmp left"
      mkdir "$SESSION_FILE"
      When call update_session myns/mymod MM
      The status should equal 1
      The stderr should include "Error: update_session: failed to write: ${SESSION_FILE}"
      The stdout should not include "Session updated"
      The path "$SESSION_FILE" should be directory
      The value "$(ls -A "$SESSION_FILE")" should be blank
      The value "$(_list_session_tmp)" should be blank
    End

    It "[Edge] T-CLI-MUS-07: session.json is {} -> status 0, active/modules created, updated_at ISO UTC, no tmp left"
      _write_session_fixture '{}'
      When call update_session myns/mymod MM
      The status should equal 0
      The stdout should include "Session updated: ${SESSION_FILE}"
      The value "$(_session_query '{active, modules}')" should equal "{\"active\":\"myns/mymod\",\"modules\":{\"myns/mymod\":${_SESSION_MODULE_ENTRY}}}"
      # shellcheck disable=SC2016
      The value "$(_session_query --arg re "$_ISO_UTC_PATTERN" '.updated_at | test($re)')" should equal "true"
      The value "$(_list_session_tmp)" should be blank
    End
  End
End

# main stops with exit 1 when update_session fails to write session.json.
Describe "T-CLI-MUM: module.sh: main (update_session failure)"
  Before "_load_script_with_mocks" "_setup_session"
  After "_teardown_session"

  Describe "When: 異常系 (update_session fails)"
    # update_session is the last step of main today, so this passes with or
    # without `|| exit 1`; it guards against steps added after update_session.
    It "[Error] T-CLI-MUM-01: update_session returns 1 -> main exits with status 1"
      _stub_main_steps_before_session
      # shellcheck disable=SC2329
      update_session() { return 1; }
      When run main myns/mymod
      The status should equal 1
    End
  End
End

# switch_session switches the active module of an existing session.json and
# keeps every module entry (progress) as it is.
Describe "T-CLI-MSS: module.sh: switch_session"
  Before "_load_script_with_mocks" "_setup_session" "init_vars"
  After "_teardown_session"

  Describe "When: 正常系"
    It "[Normal] T-CLI-MSS-01: switch ns/a -> ns/b -> active is ns/b, both module entries unchanged"
      _write_switch_fixture
      When call switch_session ns/b
      The status should equal 0
      The stdout should be present
      The value "$(_session_query '.active')" should equal '"ns/b"'
      The value "$(_session_query '.modules')" should equal "$_SESSION_SWITCH_MODULES"
    End

    It "[Normal] T-CLI-MSS-02: switch -> updated_at refreshed (ISO UTC), created_at kept"
      _write_switch_fixture
      When call switch_session ns/b
      The status should equal 0
      The stdout should be present
      # shellcheck disable=SC2016
      The value "$(_session_query --arg re "$_ISO_UTC_PATTERN" '.updated_at | test($re) and . != "2026-01-01T00:00:00Z"')" should equal "true"
      The value "$(_session_query '.created_at')" should equal '"2026-01-01T00:00:00Z"'
    End

    It "[Normal] T-CLI-MSS-03: switch -> 'Switched active module: ns/b' on stdout, stderr empty"
      _write_switch_fixture
      When call switch_session ns/b
      The status should equal 0
      The stdout should include "Switched active module: ns/b"
      The stderr should be blank
    End
  End

  Describe "When: 異常系"
    It "[Error] T-CLI-MSS-04: no session.json -> status 1, stderr names --force, no session.json created"
      When call switch_session ns/b
      The status should equal 1
      The stderr should include "--force"
      The stdout should not include "Switched"
      The path "$SESSION_FILE" should not be exist
    End

    It "[Error] T-CLI-MSS-05: no entry for ns/c -> status 1, stderr names ns/c and --force, session.json byte-identical"
      _write_switch_fixture
      When call switch_session ns/c
      The status should equal 1
      The stderr should include "ns/c"
      The stderr should include "--force"
      The stdout should not include "Switched"
      The contents of file "$SESSION_FILE" should equal "$_SESSION_SWITCH"
    End

    It "[Error] T-CLI-MSS-07: write_json_file fails -> Error on stderr, status 1, no summary, content unchanged, no tmp left"
      _write_switch_fixture
      _mock_write_json_file_fail
      When call switch_session ns/b
      The status should equal 1
      The stderr should include "Error: switch_session: failed to write: ${SESSION_FILE}"
      The stdout should not include "Switched active module"
      The contents of file "$SESSION_FILE" should equal "$_SESSION_SWITCH"
      The value "$(_list_session_tmp)" should be blank
    End
  End

  Describe "When: エッジケース"
    It "[Edge] T-CLI-MSS-06: switch to the already-active ns/a -> status 0, active stays ns/a, modules unchanged"
      _write_switch_fixture
      When call switch_session ns/a
      The status should equal 0
      The stdout should include "Switched active module: ns/a"
      The value "$(_session_query '.active')" should equal '"ns/a"'
      The value "$(_session_query '.modules')" should equal "$_SESSION_SWITCH_MODULES"
    End
  End
End
