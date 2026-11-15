#!/usr/bin/env bash
# skills/deckrd/skills/deckrd/scripts/__tests__/unit/init-write-project.unit.spec.sh
# @(#) : BDD unit tests for init.sh - write_project function
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

# ISO 8601 UTC timestamp pattern written by write_project (created_at / updated_at)
_ISO_UTC_PATTERN='^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$'

# The exact key set of .project.json, as printed by `jq -c keys` (sorted)
_PROJECT_KEYS='["ai_model","created_at","prog","project","project_type","updated_at"]'

# Existing new-format file: programming language in prog (WPJ-02)
_PROJECT_NEW_FORMAT='{"project":"old","project_type":"lib","prog":"rust","ai_model":"opus","created_at":"2026-01-01T00:00:00Z","updated_at":"2026-01-01T00:00:00Z"}'

# Existing old-format file: programming language in language, no prog key (WPJ-03)
_PROJECT_OLD_LANGUAGE='{"project":"old","project_type":"lib","language":"go","ai_model":"sonnet","created_at":"2026-01-01T00:00:00Z","updated_at":"2026-01-01T00:00:00Z"}'

# Existing valid JSON without created_at or updated_at (WPJ-05)
_PROJECT_NO_CREATED_AT='{"project":"old","project_type":"lib","prog":"rust","ai_model":"opus"}'

# Existing valid JSON whose created_at is an empty string (WPJ-11)
_PROJECT_EMPTY_CREATED_AT='{"project":"old","project_type":"lib","prog":"rust","ai_model":"opus","created_at":"","updated_at":"2026-01-01T00:00:00Z"}'

# Existing file that is not valid JSON (WPJ-06)
_PROJECT_INVALID_JSON='not json'

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
# @description Create a per-example temp dir and point PROJECT_FILE into it.
#   Sets the default OPTIONS used by every case (project=myapp,
#   project_type=webapp, prog=go, ai_model=sonnet); examples override what they need.
# @set _PROJECT_TMPDIR, PROJECT_FILE, OPTIONS[project|project_type|prog|ai_model]
# @return 0
_setup_project() {
  _PROJECT_TMPDIR="$(mktemp -d)"
  PROJECT_FILE="${_PROJECT_TMPDIR}/.project.json"
  OPTIONS[project]="myapp"
  OPTIONS[project_type]="webapp"
  OPTIONS[prog]="go"
  OPTIONS[ai_model]="sonnet"
}

##
# @description Remove the per-example temp dir created by _setup_project.
# @return 0
_teardown_project() {
  [[ -n "${_PROJECT_TMPDIR:-}" && -d "$_PROJECT_TMPDIR" ]] && rm -rf "$_PROJECT_TMPDIR"
  unset _PROJECT_TMPDIR
  return 0
}

##
# @description Write a fixture to PROJECT_FILE verbatim (no trailing newline).
# @arg $1 string fixture contents (one of the _PROJECT_* constants)
# @return 0
_write_project_fixture() {
  printf '%s' "$1" >"$PROJECT_FILE"
}

##
# @description List temporary files (.project.json.tmp*) left in a directory
#   tree. Searches the directory of PROJECT_FILE by default; pass another
#   directory when that one may not exist (e.g. a missing parent directory).
#   Blank output means no leftover tmp file.
# @arg $1 string directory to search (optional, default: dirname of PROJECT_FILE)
# @stdout one path per leftover tmp file
# @return 0
_list_project_tmp() {
  find "${1:-${PROJECT_FILE%/*}}" -name '.project.json.tmp*' 2>/dev/null
}

##
# @description Replace jq_read with a stub that fails only for one kind of call.
#   A call whose arguments contain the given token returns 1 without output;
#   every other call runs the real jq, so reading created_at still works and
#   only the targeted write fails.
# @arg $1 string argument token that selects the failing call (e.g. "-n")
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
# @description Query PROJECT_FILE with jq (compact output, CR stripped).
# @arg ... jq options and filter (the filter last)
# @stdout jq result
# @return jq exit code
_project_query() {
  jq_read -c "$@" "$PROJECT_FILE"
}

##
# @description Check that created_at was freshly set: it equals updated_at and
#   is an ISO 8601 UTC timestamp (a new file, or an existing one with no usable
#   created_at).
# @stdout "true" or "false"
# @return jq exit code
_project_created_at_fresh() {
  # shellcheck disable=SC2016
  _project_query --arg re "$_ISO_UTC_PATTERN" '.created_at == .updated_at and (.created_at | test($re))'
}

# ============================================================================
# Tests
# ============================================================================

# write_project regenerates .project.json from OPTIONS with exactly six keys
# (project, project_type, prog, ai_model, created_at, updated_at); created_at
# is kept from an existing file. Scenarios: new and existing files, unusual
# existing files and values, and write failures (jq / mv / missing directory)
# that must return 1 with an `Error:` line and leave no tmp file.
Describe "T-CLI-WPJ: init.sh: write_project"
  Before "_load_script_with_mocks" "init_vars" "_setup_project"
  After "_teardown_project"

  # Successful creation and regeneration of .project.json
  Describe "When: 正常系"
    It "[Normal] T-CLI-WPJ-01: new file -> exact keys, option values, created_at == updated_at (ISO), no tmp left"
      When call write_project
      The status should equal 0
      The stderr should include "Project written: ${PROJECT_FILE}"
      The value "$(_project_query 'keys')" should equal "$_PROJECT_KEYS"
      The value "$(_project_query '[.project, .project_type, .prog, .ai_model]')" should equal '["myapp","webapp","go","sonnet"]'
      The value "$(_project_created_at_fresh)" should equal "true"
      The value "$(_list_project_tmp)" should be blank
    End

    It "[Normal] T-CLI-WPJ-02: existing new-format file -> created_at kept, other values replaced from OPTIONS"
      _write_project_fixture "$_PROJECT_NEW_FORMAT"
      When call write_project
      The status should equal 0
      The stderr should include "Project written: ${PROJECT_FILE}"
      The value "$(_project_query 'keys')" should equal "$_PROJECT_KEYS"
      The value "$(_project_query '[.project, .project_type, .prog, .ai_model, .created_at]')" should equal '["myapp","webapp","go","sonnet","2026-01-01T00:00:00Z"]'
      # shellcheck disable=SC2016
      The value "$(_project_query --arg re "$_ISO_UTC_PATTERN" '.updated_at | test($re) and . != "2026-01-01T00:00:00Z"')" should equal "true"
    End

    It "[Normal] T-CLI-WPJ-03: existing old-format file with language -> language dropped, exact keys, created_at kept"
      _write_project_fixture "$_PROJECT_OLD_LANGUAGE"
      When call write_project
      The status should equal 0
      The stderr should include "Project written: ${PROJECT_FILE}"
      The value "$(_project_query 'has("language")')" should equal "false"
      The value "$(_project_query 'keys')" should equal "$_PROJECT_KEYS"
      The value "$(_project_query '[.prog, .created_at]')" should equal '["go","2026-01-01T00:00:00Z"]'
    End

    It "[Normal] T-CLI-WPJ-04: new file -> stderr summary lists path and every value, stdout blank"
      When call write_project
      The status should equal 0
      The stdout should be blank
      The stderr should include "Project written: ${PROJECT_FILE}"
      The stderr should include "  project:      myapp"
      The stderr should include "  project_type: webapp"
      The stderr should include "  prog:         go"
      The stderr should include "  ai_model:     sonnet"
    End
  End

  # Unusual existing files and values
  Describe "When: エッジケース"
    It "[Edge] T-CLI-WPJ-05: existing JSON without created_at -> created_at set to updated_at (not empty)"
      _write_project_fixture "$_PROJECT_NO_CREATED_AT"
      When call write_project
      The status should equal 0
      The stderr should include "Project written: ${PROJECT_FILE}"
      The value "$(_project_query 'keys')" should equal "$_PROJECT_KEYS"
      The value "$(_project_created_at_fresh)" should equal "true"
    End

    It "[Edge] T-CLI-WPJ-06: existing file not valid JSON -> regenerated, exact keys, created_at == updated_at (ISO)"
      _write_project_fixture "$_PROJECT_INVALID_JSON"
      When call write_project
      The status should equal 0
      The stderr should include "Project written: ${PROJECT_FILE}"
      The value "$(_project_query 'keys')" should equal "$_PROJECT_KEYS"
      The value "$(_project_created_at_fresh)" should equal "true"
    End

    It "[Edge] T-CLI-WPJ-07: project value with a space and double quotes -> stored verbatim as valid JSON"
      OPTIONS[project]='my "app" x'
      When call write_project
      The status should equal 0
      The stderr should include "Project written: ${PROJECT_FILE}"
      The value "$(jq_read -r '.project' "$PROJECT_FILE")" should equal 'my "app" x'
    End

    It "[Edge] T-CLI-WPJ-11: existing JSON with an empty created_at -> created_at set to updated_at (not empty)"
      _write_project_fixture "$_PROJECT_EMPTY_CREATED_AT"
      When call write_project
      The status should equal 0
      The stderr should include "Project written: ${PROJECT_FILE}"
      The value "$(_project_query 'keys')" should equal "$_PROJECT_KEYS"
      The value "$(_project_created_at_fresh)" should equal "true"
    End
  End

  # Write failures (new and existing .project.json)
  Describe "When: 異常系"
    It "[Error] T-CLI-WPJ-08: new file, jq fails on the write -> 1, Error:, no 'Project written', no file, no tmp left"
      _mock_jq_read_fail_on "-n"
      When call write_project
      The status should equal 1
      The stderr should include "Error: write_project: failed to write: ${PROJECT_FILE}"
      The stderr should not include "Project written"
      The path "$PROJECT_FILE" should not be exist
      The value "$(_list_project_tmp)" should be blank
    End

    It "[Error] T-CLI-WPJ-09: existing file, mv fails -> 1, Error:, no 'Project written', file unchanged, no tmp left"
      _write_project_fixture "$_PROJECT_NEW_FORMAT"
      _mock_mv_fail
      When call write_project
      The status should equal 1
      The stderr should include "Error: write_project: failed to write: ${PROJECT_FILE}"
      The stderr should not include "Project written"
      The contents of file "$PROJECT_FILE" should equal "$_PROJECT_NEW_FORMAT"
      The value "$(_list_project_tmp)" should be blank
    End

    It "[Error] T-CLI-WPJ-10: parent directory missing -> 1, Error:, no 'Project written', directory not created, no tmp left"
      PROJECT_FILE="${_PROJECT_TMPDIR}/missing-dir/.project.json"
      When call write_project
      The status should equal 1
      The stderr should include "Error: write_project: failed to write: ${PROJECT_FILE}"
      The stderr should not include "Project written"
      The path "${_PROJECT_TMPDIR}/missing-dir" should not be exist
      The value "$(_list_project_tmp "$_PROJECT_TMPDIR")" should be blank
    End
  End
End
