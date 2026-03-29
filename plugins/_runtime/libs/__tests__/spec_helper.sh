#!/usr/bin/env bash
# src: ./plugins/_runtime/libs/__tests__/spec_helper.sh
# @(#) : ShellSpec helper for _runtime/libs tests
#
# Copyright (c) 2026- aglabo <https://github.com/aglabo>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

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
setup_naming_cache() {
  NAMING_TMPDIR="$(mktemp -d)"
  export NAMING_TMPDIR
  export DECKRD_LOCAL_DATA="${NAMING_TMPDIR}"
  export _FILENAME_CACHE_DIR="${NAMING_TMPDIR}/cache/filenames"
}

# Helper: clean up naming cache temp directory
teardown_naming_cache() {
  [[ -n "${NAMING_TMPDIR:-}" && -d "$NAMING_TMPDIR" ]] && rm -rf "$NAMING_TMPDIR"
  unset NAMING_TMPDIR DECKRD_LOCAL_DATA _FILENAME_CACHE_DIR
}

# ---- deckrd-coder path detection helpers ----

# Before: create a temp script file under a deckrd-coder path
setup_coder_tmpscript() {
  mkdir -p /tmp/plugins/deckrd-coder
  _CODER_TMPSCRIPT="$(mktemp /tmp/plugins/deckrd-coder/XXXXXX.sh)"
  export _CODER_TMPSCRIPT
}

# After: remove the temp script file
teardown_coder_tmpscript() {
  [[ -n "${_CODER_TMPSCRIPT:-}" ]] && rm -f "$_CODER_TMPSCRIPT"
  unset _CODER_TMPSCRIPT
}

# Run bootstrap.lib.sh from deckrd-coder path and print the value of VAR_NAME.
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
  } > "$_CODER_TMPSCRIPT"

  bash "$_CODER_TMPSCRIPT"
}

# ---- integration test helpers ----

# Helper: PATH から git を除外する
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

# Helper: git リポジトリ外の一時ディレクトリを作成
setup_nongit_tmpdir() {
  _NONGIT_TMPDIR="$(mktemp -d)"
  export _NONGIT_TMPDIR
}

teardown_nongit_tmpdir() {
  [[ -n "${_NONGIT_TMPDIR:-}" && -d "$_NONGIT_TMPDIR" ]] && rm -rf "$_NONGIT_TMPDIR"
  unset _NONGIT_TMPDIR
}

