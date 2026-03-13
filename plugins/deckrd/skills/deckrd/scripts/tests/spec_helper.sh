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

# Path to the scripts directory (relative to this spec_helper)
# SHELLSPEC_PROJECT_ROOT is the project root set by shellspec
_SPEC_DIR="$(cd "${SHELLSPEC_PROJECT_ROOT}/plugins/deckrd/skills/deckrd/scripts/tests" && pwd)"
SCRIPTS_DIR="${_SPEC_DIR}/.."
unset _SPEC_DIR

# Helper: create an isolated temp directory and set DECKRD_DOCS / DECKRD_LOCAL
setup_deckrd_tmpdir() {
  DECKRD_TMPDIR="$(mktemp -d)"
  export DECKRD_DOCS="${DECKRD_TMPDIR}/docs/.deckrd"
  export DECKRD_LOCAL="${DECKRD_TMPDIR}/.local/deckrd"
  mkdir -p "$DECKRD_DOCS" "$DECKRD_LOCAL"
}

# Helper: clean up temp directory
teardown_deckrd_tmpdir() {
  [[ -n "${DECKRD_TMPDIR:-}" && -d "$DECKRD_TMPDIR" ]] && rm -rf "$DECKRD_TMPDIR"
  unset DECKRD_TMPDIR DECKRD_DOCS DECKRD_LOCAL
}
