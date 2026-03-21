#!/usr/bin/env bash
# spec_helper.sh - ShellSpec helper for deckrd scripts/lib
#
# Copyright (c) 2026- atsushifx <https://github.com/atsushifx>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

# ============================================================================
# Delegate to the canonical spec_helper in scripts/tests/
# ============================================================================

_HELPER_DIR="$(cd "${SHELLSPEC_PROJECT_ROOT}/plugins/deckrd/skills/deckrd/scripts/tests" && pwd)"
# shellcheck disable=SC1091
. "${_HELPER_DIR}/spec_helper.sh"
unset _HELPER_DIR

SUBCOMMANDS_DIR="${DECKRD_SCRIPTS_DIR}/subcommands"
export SUBCOMMANDS_DIR
