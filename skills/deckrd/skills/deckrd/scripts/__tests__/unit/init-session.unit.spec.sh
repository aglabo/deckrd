#!/usr/bin/env bash
# skills/deckrd/skills/deckrd/scripts/__tests__/unit/init-session.unit.spec.sh
# @(#) : BDD unit tests for init.sh - init_session function
#
# Copyright (c) 2026- atsushifx <https://github.com/atsushifx>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

# OPTIONS is the associative array declared by init.sh (init_vars); shellcheck
# cannot see that declaration, so it misreads the keys and the assignments.
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

SCRIPT="${DECKRD_SCRIPTS_DIR}/init.sh"

# ============================================================================
# Internal helpers
# ============================================================================

# --- Constants ---

# ISO 8601 UTC timestamp pattern written by init_session (created_at / updated_at)
_ISO_UTC_PATTERN='^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$'

# New-format session: programming language in prog, document language in lang (INS-03/06/12/13)
_SESSION_PROG_LANG_EN='{"active":"core/auth","prog":"go","lang":"en","ai_model":"sonnet","modules":{"core/auth":{}},"created_at":"2026-01-01T00:00:00Z","updated_at":"2026-01-01T00:00:00Z"}'

# Old-format session: programming language stored in lang, no prog key (INS-04/07/14)
_SESSION_OLD_LANG_TS='{"active":"core/auth","lang":"typescript","ai_model":"sonnet","modules":{"core/auth":{}},"created_at":"2026-01-01T00:00:00Z","updated_at":"2026-01-01T00:00:00Z"}'

# New-format session without a lang key (INS-05)
_SESSION_PROG_NO_LANG='{"active":null,"prog":"go","ai_model":"sonnet","modules":{},"created_at":"2026-01-01T00:00:00Z","updated_at":"2026-01-01T00:00:00Z"}'

# Session whose lang is a document language and has no prog key: not migrated (INS-10)
_SESSION_DOC_LANG_ONLY='{"active":null,"lang":"ja","ai_model":"sonnet","modules":{},"created_at":"2026-01-01T00:00:00Z","updated_at":"2026-01-01T00:00:00Z"}'

# --- Functions ---

##
# @description Source init.sh with environment validators stubbed out.
#   init.sh guards main() with BASH_SOURCE, so sourcing only defines functions.
# @return 0
_load_script_with_mocks() {
  # shellcheck disable=SC2329
  validate_env() { return 0; }
  export -f validate_env

  # shellcheck disable=SC2329
  validate_ai_model() { return 0; }
  export -f validate_ai_model

  . "$SCRIPT"
}

##
# @description Create a per-example temp dir and point SESSION_FILE into it.
#   Sets the default OPTIONS used by every case (prog=typescript, ai_model=sonnet,
#   lang=system, lang_set=false); examples override what they need.
# @set _SESSION_TMPDIR, SESSION_FILE, OPTIONS[prog|lang|lang_set|ai_model]
# @return 0
_setup_session() {
  _SESSION_TMPDIR="$(mktemp -d)"
  SESSION_FILE="${_SESSION_TMPDIR}/session.json"
  OPTIONS[prog]="typescript"
  OPTIONS[lang]="system"
  OPTIONS[lang_set]=false
  OPTIONS[ai_model]="sonnet"
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
# @arg $1 string fixture contents (one of the _SESSION_* constants, or "" for an empty file)
# @return 0
_write_session_fixture() {
  printf '%s' "$1" >"$SESSION_FILE"
}

##
# @description List temporary files (session.json.tmp*) left in a directory
#   tree. Searches the directory of SESSION_FILE by default; pass another
#   directory when that one may not exist (e.g. a missing parent directory).
#   Blank output means no leftover tmp file.
# @arg $1 string directory to search (optional, default: dirname of SESSION_FILE)
# @stdout one path per leftover tmp file
# @return 0
_list_session_tmp() {
  find "${1:-${SESSION_FILE%/*}}" -name 'session.json.tmp*' 2>/dev/null
}

##
# @description Replace jq_read with a stub that fails only for one kind of call.
#   A call whose arguments contain the given token returns 1 without output;
#   every other call runs the real jq, so the migration predicate in
#   libs/session.lib.sh still works and only the targeted write fails.
# @arg $1 string argument token that selects the failing call (e.g. "-n", "lang")
# @return 0
_mock_jq_read_fail_on() {
  _JQ_READ_FAIL_TOKEN="$1"
  # shellcheck disable=SC2329
  jq_read() {
    local arg
    for arg in "$@"; do
      [[ "$arg" == "$_JQ_READ_FAIL_TOKEN" ]] && return 1
    done
    (
      set -o pipefail
      "${jqexe:-jq}" "$@" | tr -d '\r'
    )
  }
}

##
# @description Replace mv with a stub that always fails (a shell function
#   shadows the external command for the rest of the example).
# @return 0
_mock_mv_fail() {
  # shellcheck disable=SC2329
  mv() { return 1; }
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

# init_session creates session.json (prog, optional lang, ai_model, timestamps)
# or keeps an existing one: an old `lang` holding a programming language is
# moved to `prog`, and --lang (OPTIONS[lang_set]) overwrites `lang`.
# Scenarios: new file, existing file with/without --lang, edge values, and
# write failures (jq / mv / missing directory) that must return 1 with an
# `Error:` line and leave neither a partial session.json nor a tmp file.
Describe "T-CLI-INS: init.sh: init_session"
  Before "_load_script_with_mocks" "init_vars" "_setup_session"
  After "_teardown_session"

  # Successful creation and update of session.json
  Describe "When: 正常系"
    It "[Normal] T-CLI-INS-01: new file with --lang -> all keys incl. lang, 'Session created', 0"
      OPTIONS[lang]="ja"
      OPTIONS[lang_set]=true
      When call init_session
      The status should equal 0
      The stderr should include "Session created"
      The value "$(_session_query 'keys')" should equal '["active","ai_model","created_at","lang","modules","prog","updated_at"]'
      The value "$(_session_query '[.active, .prog, .lang, .ai_model, .modules]')" should equal '[null,"typescript","ja","sonnet",{}]'
      The value "$(_session_query '.created_at == .updated_at')" should equal "true"
      # shellcheck disable=SC2016
      The value "$(_session_query --arg re "$_ISO_UTC_PATTERN" '.created_at | test($re)')" should equal "true"
    End

    It "[Normal] T-CLI-INS-02: new file without --lang -> no lang key, prog from OPTIONS"
      OPTIONS[prog]="go"
      When call init_session
      The status should equal 0
      The stderr should include "Session created"
      The value "$(_session_query 'has("lang")')" should equal "false"
      The value "$(_session_query '.prog')" should equal '"go"'
    End

    It "[Normal] T-CLI-INS-03: existing new-format file with --lang -> lang overwritten, other keys kept, no tmp left"
      _write_session_fixture "$_SESSION_PROG_LANG_EN"
      OPTIONS[lang]="ja"
      OPTIONS[lang_set]=true
      When call init_session
      The status should equal 0
      The stderr should include "Session preserved"
      The value "$(_session_query '[.lang, .prog, .active, (.modules | has("core/auth")), .created_at]')" should equal '["ja","go","core/auth",true,"2026-01-01T00:00:00Z"]'
      The value "$(_list_session_tmp)" should be blank
    End

    It "[Normal] T-CLI-INS-04: existing old-format file with --lang -> lang moved to prog, then lang set"
      _write_session_fixture "$_SESSION_OLD_LANG_TS"
      OPTIONS[lang]="ja"
      OPTIONS[lang_set]=true
      When call init_session
      The status should equal 0
      The stderr should include "migrated programming language from 'lang' to 'prog'"
      The stderr should include "Session preserved"
      The value "$(_session_query '[.prog, .lang, .active, .created_at]')" should equal '["typescript","ja","core/auth","2026-01-01T00:00:00Z"]'
    End

    It "[Normal] T-CLI-INS-05: existing file without lang key, with --lang -> lang added"
      _write_session_fixture "$_SESSION_PROG_NO_LANG"
      OPTIONS[lang]="en"
      OPTIONS[lang_set]=true
      When call init_session
      The status should equal 0
      The stderr should include "Session preserved"
      The value "$(_session_query '[.lang, .prog, .ai_model, .created_at]')" should equal '["en","go","sonnet","2026-01-01T00:00:00Z"]'
    End

    It "[Normal] T-CLI-INS-06: existing new-format file without --lang -> file byte-identical, 'Session preserved'"
      _write_session_fixture "$_SESSION_PROG_LANG_EN"
      OPTIONS[prog]="rust"
      When call init_session
      The status should equal 0
      The stderr should include "Session preserved"
      The contents of file "$SESSION_FILE" should equal "$_SESSION_PROG_LANG_EN"
    End

    It "[Normal] T-CLI-INS-07: existing old-format file without --lang -> lang moved to prog only"
      _write_session_fixture "$_SESSION_OLD_LANG_TS"
      When call init_session
      The status should equal 0
      The stderr should include "Session preserved"
      The value "$(_session_query '[.prog, has("lang")]')" should equal '["typescript",false]'
      The value "$(_session_query 'del(.prog)')" should equal "$(printf '%s' "$_SESSION_OLD_LANG_TS" | jq_read -c 'del(.lang)')"
    End
  End

  # Boundary and special values
  Describe "When: エッジケース"
    It "[Edge] T-CLI-INS-08: new file with explicit --lang system (the default value) -> lang \"system\" written"
      OPTIONS[lang]="system"
      OPTIONS[lang_set]=true
      When call init_session
      The status should equal 0
      The stderr should include "Session created"
      The value "$(_session_query '.lang')" should equal '"system"'
    End

    It "[Edge] T-CLI-INS-09: new file with --lang bash -> lang kept as \"bash\" (not normalized), prog unchanged"
      OPTIONS[lang]="bash"
      OPTIONS[lang_set]=true
      When call init_session
      The status should equal 0
      The stderr should include "Session created"
      The value "$(_session_query '[.lang, .prog]')" should equal '["bash","typescript"]'
    End

    It "[Edge] T-CLI-INS-10: existing file whose lang is a document language, without --lang -> not migrated, unchanged"
      _write_session_fixture "$_SESSION_DOC_LANG_ONLY"
      When call init_session
      The status should equal 0
      The stderr should not include "migrated"
      The contents of file "$SESSION_FILE" should equal "$_SESSION_DOC_LANG_ONLY"
    End
  End

  # Write failures (existing and new session.json)
  Describe "When: 異常系"
    It "[Error] T-CLI-INS-11: existing empty file with --lang -> migration fails, 1, lang not written"
      _write_session_fixture ""
      OPTIONS[lang]="ja"
      OPTIONS[lang_set]=true
      When call init_session
      The status should equal 1
      The stderr should include "Error: session_lang_migration_needed: not a JSON object"
      The stderr should not include "Session preserved"
      The contents of file "$SESSION_FILE" should equal ""
      The value "$(_list_session_tmp)" should be blank
    End

    It "[Error] T-CLI-INS-12: existing file, jq fails on the lang write -> 1, Error:, file unchanged, no tmp left"
      _write_session_fixture "$_SESSION_PROG_LANG_EN"
      OPTIONS[lang]="ja"
      OPTIONS[lang_set]=true
      _mock_jq_read_fail_on "lang"
      When call init_session
      The status should equal 1
      The stderr should include "Error: init_session:"
      The stderr should not include "Session preserved"
      The contents of file "$SESSION_FILE" should equal "$_SESSION_PROG_LANG_EN"
      The value "$(_list_session_tmp)" should be blank
    End

    It "[Error] T-CLI-INS-13: existing file, mv fails on the lang write -> 1, Error:, file unchanged, no tmp left"
      _write_session_fixture "$_SESSION_PROG_LANG_EN"
      OPTIONS[lang]="ja"
      OPTIONS[lang_set]=true
      _mock_mv_fail
      When call init_session
      The status should equal 1
      The stderr should include "Error: init_session:"
      The stderr should not include "Session preserved"
      The contents of file "$SESSION_FILE" should equal "$_SESSION_PROG_LANG_EN"
      The value "$(_list_session_tmp)" should be blank
    End

    It "[Error] T-CLI-INS-14: existing old-format file, mv fails on the migration -> 1, Error:, neither prog nor lang written, no tmp left"
      _write_session_fixture "$_SESSION_OLD_LANG_TS"
      OPTIONS[lang]="ja"
      OPTIONS[lang_set]=true
      _mock_mv_fail
      When call init_session
      The status should equal 1
      The stderr should include "Error:"
      The contents of file "$SESSION_FILE" should equal "$_SESSION_OLD_LANG_TS"
      The value "$(_list_session_tmp)" should be blank
    End

    It "[Error] T-CLI-INS-15: new file, jq fails on the create -> 1, Error:, no 'Session created', no file, no tmp left"
      OPTIONS[lang]="ja"
      OPTIONS[lang_set]=true
      _mock_jq_read_fail_on "-n"
      When call init_session
      The status should equal 1
      The stderr should include "Error: init_session: failed to write: ${SESSION_FILE}"
      The stderr should not include "Session created"
      The path "$SESSION_FILE" should not be exist
      The value "$(_list_session_tmp)" should be blank
    End

    It "[Error] T-CLI-INS-16: new file, mv fails -> 1, Error:, no 'Session created', no file, no tmp left"
      OPTIONS[lang]="ja"
      OPTIONS[lang_set]=true
      _mock_mv_fail
      When call init_session
      The status should equal 1
      The stderr should include "Error: init_session: failed to write: ${SESSION_FILE}"
      The stderr should not include "Session created"
      The path "$SESSION_FILE" should not be exist
      The value "$(_list_session_tmp)" should be blank
    End

    It "[Error] T-CLI-INS-17: new file, parent directory missing -> 1, Error:, no 'Session created', no tmp left"
      SESSION_FILE="${_SESSION_TMPDIR}/missing-dir/session.json"
      When call init_session
      The status should equal 1
      The stderr should include "Error: init_session: failed to write: ${SESSION_FILE}"
      The stderr should not include "Session created"
      The path "${_SESSION_TMPDIR}/missing-dir" should not be exist
      The value "$(_list_session_tmp "$_SESSION_TMPDIR")" should be blank
    End
  End
End
