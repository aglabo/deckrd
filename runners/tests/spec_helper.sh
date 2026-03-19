#!/usr/bin/env bash
# runners/libs/tests/spec_helper.sh
# @(#) : shared test helper for runners/libs tests
#
# Copyright (c) 2026- atsushifx <https://github.com/atsushifx>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT
# spec_helper.sh — shared test helper for runners/libs tests

# Load the library under test
_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
unset _LIB_DIR

#
# @description Create a temporary directory tree of fake spec files for testing get_filelist()
# @sideeffect Sets TEMP_DIR to the path of the created temporary directory
#
setup_temp_specs() {
  TEMP_DIR="$(mktemp -d)"
  # Create fake spec files under runners/ and plugins/ subtrees
  mkdir -p "${TEMP_DIR}/runners/libs/tests/unit"
  mkdir -p "${TEMP_DIR}/runners/libs/tests/integration"
  mkdir -p "${TEMP_DIR}/plugins/deckrd/tests/unit"

  touch "${TEMP_DIR}/runners/libs/tests/unit/args-normalize.spec.sh"
  touch "${TEMP_DIR}/runners/libs/tests/unit/kv-store.spec.sh"
  touch "${TEMP_DIR}/runners/libs/tests/unit/init.spec.sh"
  touch "${TEMP_DIR}/runners/libs/tests/integration/args-normalize.spec.sh"
  touch "${TEMP_DIR}/plugins/deckrd/tests/unit/deckrd-init.spec.sh"

  # shellcheck disable=SC2034
  SPEC_SEARCH_ROOT="$TEMP_DIR"
}

#
# @description Remove the temporary directory created by setup_temp_specs()
# @sideeffect Deletes TEMP_DIR and unset the variable
#
teardown_temp_specs() {
  [[ -n "${TEMP_DIR:-}" ]] && rm -rf "$TEMP_DIR"
  unset TEMP_DIR
  # shellcheck disable=SC2034
  SPEC_SEARCH_ROOT="${ORIG_SPEC_SEARCH_ROOT:-}"
}
