#!/usr/bin/env bash
# spec_helper.sh - ShellSpec helper for deckrd scripts
#
# Copyright (c) 2025 atsushifx <https://github.com/atsushifx>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

# ============================================================================
# Common setup for all deckrd spec files
# ============================================================================
# Usage in spec files:
#   Include spec_helper.sh   (shellspec DSL)
# ============================================================================

# Helper: create an isolated temp directory and set DECKRD_DOCS / DECKRD_LOCAL / DECKRD_LOCAL_DATA
setup_deckrd_tmpdir() {
  DECKRD_TMPDIR="$(mktemp -d)"
  export DECKRD_DOCS_DIR="${DECKRD_TMPDIR}/docs/.deckrd"
  export DECKRD_LOCAL="${DECKRD_TMPDIR}/.local/deckrd"
  export DECKRD_LOCAL_DATA="${DECKRD_TMPDIR}/.local/deckrd"
  mkdir -p "$DECKRD_DOCS_DIR" "$DECKRD_LOCAL"
}

# Helper: clean up temp directory
teardown_deckrd_tmpdir() {
  [[ -n "${DECKRD_TMPDIR:-}" && -d "$DECKRD_TMPDIR" ]] && rm -rf "$DECKRD_TMPDIR"
  unset DECKRD_TMPDIR DECKRD_DOCS_DIR DECKRD_LOCAL DECKRD_LOCAL_DATA
}

# Fixtures directory
FIXTURES_DIR="${SHELLSPEC_PROJECT_ROOT}/plugins/deckrd/skills/deckrd/scripts/tests/fixtures"
export FIXTURES_DIR

# Helper: return the path to a fixture file
fixture_path() { echo "${FIXTURES_DIR}/${1}"; }

# Helper: return the contents of a fixture file
load_fixture() { cat "${FIXTURES_DIR}/${1}"; }
