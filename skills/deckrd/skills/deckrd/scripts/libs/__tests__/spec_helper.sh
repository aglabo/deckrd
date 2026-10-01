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

_HELPER_DIR="$(cd "${SHELLSPEC_PROJECT_ROOT}/skills/deckrd/skills/deckrd/scripts/__tests__" && pwd)"
# shellcheck disable=SC1091
. "${_HELPER_DIR}/spec_helper.sh"
unset _HELPER_DIR

# ---- tmp directory helpers ----

# Helper: create an isolated temp directory
setup_tmpdir() {
  NAMING_TMPDIR="$(mktemp -d)"
  export NAMING_TMPDIR
}

# Helper: clean up temp directory
teardown_tmpdir() {
  [[ -n "${NAMING_TMPDIR:-}" && -d "$NAMING_TMPDIR" ]] && rm -rf "$NAMING_TMPDIR"
  unset NAMING_TMPDIR
}

# Helper: create isolated cache directory for naming cache tests
#
# Delegates the DECKRD_LOCAL_* overrides to export_sandbox_local_dirs. Listing the
# variables one by one here would leave one helper behind when a variable is added.
#
# DECKRD_LOCAL_DATA points at NAMING_TMPDIR itself. naming.lib.sh derives
# _FILENAME_CACHE_DIR from it, so no intermediate level may be inserted.
setup_naming_cache() {
  NAMING_TMPDIR="$(mktemp -d)"
  export NAMING_TMPDIR
  export_sandbox_local_dirs "$NAMING_TMPDIR"
  export _FILENAME_CACHE_DIR="${NAMING_TMPDIR}/cache/filenames"
}

# Helper: clean up naming cache temp directory
#
# Mirrors the variables overridden by setup_naming_cache and unsets all of them.
teardown_naming_cache() {
  [[ -n "${NAMING_TMPDIR:-}" && -d "$NAMING_TMPDIR" ]] && rm -rf "$NAMING_TMPDIR"
  unset_sandbox_local_dirs
  unset NAMING_TMPDIR _FILENAME_CACHE_DIR
}

# ---- integration test helpers ----

# Helper: remove git from PATH
setup_no_git_path() {
  _SAVED_PATH="$PATH"
  local git_dir
  git_dir="$(dirname "$(command -v git 2>/dev/null)" 2>/dev/null || true)"
  if [[ -n "$git_dir" ]]; then
    PATH="$(printf '%s' "$PATH" | tr ':' '\n' | grep -v "^${git_dir}$" | tr '\n' ':')"
    PATH="${PATH%:}"
  fi
  export PATH
}

teardown_no_git_path() {
  [[ -n "${_SAVED_PATH:-}" ]] && export PATH="$_SAVED_PATH"
  unset _SAVED_PATH
}

# Helper: create a temp directory outside any git repository
setup_nongit_tmpdir() {
  _NONGIT_TMPDIR="$(mktemp -d)"
  export _NONGIT_TMPDIR
}

teardown_nongit_tmpdir() {
  [[ -n "${_NONGIT_TMPDIR:-}" && -d "$_NONGIT_TMPDIR" ]] && rm -rf "$_NONGIT_TMPDIR"
  unset _NONGIT_TMPDIR
}

# ---- bdd-coder path detection helpers ----

# Before: create a temp script file under a bdd-coder path
#
# The parent is created per example with mktemp -d. No fixed path is shared, so jobs
# under `--jobs 4` do not collide with each other or with other users on shared hosts.
#
# Keeps `plugins/bdd-coder` as a single path segment. This helper simulates sourcing
# bootstrap from a bdd-coder path, and the intent of
# T-LIB-BSRC-02 / T-LIB-BSRCF-02 is encoded in the path name.
# Do not break the segment with a suffix such as `bdd-coder-XXXXXX`.
setup_coder_tmpscript() {
  _CODER_TMPROOT="$(mktemp -d)"
  _CODER_TMPDIR="${_CODER_TMPROOT}/plugins/bdd-coder"
  mkdir -p "$_CODER_TMPDIR"
  _CODER_TMPSCRIPT="$(mktemp "${_CODER_TMPDIR}/XXXXXX.sh")"
  export _CODER_TMPSCRIPT
}

# After: remove the temp script file along with the directory tree that held it
#
# Removes the whole parent tree. Removing only the file leaves the created directories behind.
teardown_coder_tmpscript() {
  [[ -n "${_CODER_TMPROOT:-}" && -d "$_CODER_TMPROOT" ]] && rm -rf "$_CODER_TMPROOT"
  unset _CODER_TMPSCRIPT _CODER_TMPDIR _CODER_TMPROOT
}

# Run bootstrap.lib.sh from bdd-coder path and print the value of VAR_NAME.
# Usage: run_coder_tmpscript <VAR_NAME> [extra_export]
# Requires: _CODER_TMPSCRIPT and SCRIPT to be set
run_coder_tmpscript() {
  local var_name="$1"
  local extra_setup="${2:-}"

  {
    printf 'unset DECKRD_ROOT\n'
    printf 'unset %s\n' "$var_name"
    [[ -n "$extra_setup" ]] && printf 'export %s\n' "$extra_setup"
    printf '. "%s" && echo "$%s"\n' "$SCRIPT" "$var_name"
  } >"$_CODER_TMPSCRIPT"

  bash "$_CODER_TMPSCRIPT"
}

# ---- ai-runner helpers ----

# _SPEC_AI_PROMPT - Dummy prompt that passes the run_ai stdin guard; its content is not verified
_SPEC_AI_PROMPT='spec prompt'

# run_ai_piped - Call run_ai with a fixed prompt on stdin
#
# Spares cases that do not verify stdin content (timeout, argv, stderr separation)
# from supplying stdin just to pass the guard.
#
# @arg $@  Arguments passed through to run_ai
run_ai_piped() {
  run_ai "$@" <<<"$_SPEC_AI_PROMPT"
}
