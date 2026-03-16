#!/usr/bin/env bash
# spec_helper.sh - ShellSpec helper for deckrd scripts/lib
#
# Copyright (c) 2026- atsushifx <https://github.com/atsushifx>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

# ============================================================================
# Common setup for all deckrd scripts/lib spec files
# ============================================================================
# Usage in spec files:
#   Include spec_helper.sh   (shellspec DSL)
# ============================================================================

# bootstrap.sh を source して DECKRD_LIB_DIR などの変数を設定
_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck disable=SC1091
. "${_LIB_DIR}/bootstrap.sh"
unset _LIB_DIR

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
