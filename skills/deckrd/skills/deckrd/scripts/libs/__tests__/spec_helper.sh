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
# DECKRD_LOCAL_* の差し替えは export_sandbox_local_dirs に任せる。ここで 1 変数ずつ
# 並べ直すと、変数が増えたときに片方のヘルパーだけが取り残される。
#
# DECKRD_LOCAL_DATA は NAMING_TMPDIR そのものを指す。naming.lib.sh はここから
# _FILENAME_CACHE_DIR を導くので、間に階層を挟んではならない。
setup_naming_cache() {
  NAMING_TMPDIR="$(mktemp -d)"
  export NAMING_TMPDIR
  export_sandbox_local_dirs "$NAMING_TMPDIR"
  export _FILENAME_CACHE_DIR="${NAMING_TMPDIR}/cache/filenames"
}

# Helper: clean up naming cache temp directory
#
# setup_naming_cache が差し替えた変数と対を成す。差し替えた変数は全部 unset する。
teardown_naming_cache() {
  [[ -n "${NAMING_TMPDIR:-}" && -d "$NAMING_TMPDIR" ]] && rm -rf "$NAMING_TMPDIR"
  unset_sandbox_local_dirs
  unset NAMING_TMPDIR _FILENAME_CACHE_DIR
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

# ---- bdd-coder path detection helpers ----

# Before: create a temp script file under a bdd-coder path
#
# 親は example ごとに mktemp -d で取る。固定パスを共有しないので、`--jobs 4` の
# 並列実行でジョブ同士が衝突せず、共有ホストで他ユーザーとも衝突しない。
#
# `plugins/bdd-coder` はパスの 1 セグメントとして保つ。bdd-coder のパスから
# bootstrap を source する状況を作るのがこのヘルパーの役目であり、
# T-LIB-BSRC-02 / T-LIB-BSRCF-02 の意図がパス名に表れている。
# `bdd-coder-XXXXXX` のようにサフィックスを付けてセグメントを崩してはならない。
setup_coder_tmpscript() {
  _CODER_TMPROOT="$(mktemp -d)"
  _CODER_TMPDIR="${_CODER_TMPROOT}/plugins/bdd-coder"
  mkdir -p "$_CODER_TMPDIR"
  _CODER_TMPSCRIPT="$(mktemp "${_CODER_TMPDIR}/XXXXXX.sh")"
  export _CODER_TMPSCRIPT
}

# After: remove the temp script file along with the directory tree that held it
#
# 後始末は親ごと消す。ファイルだけ消すと作ったディレクトリが残り続ける。
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

# _SPEC_AI_PROMPT - run_ai の stdin ガードを通すためのダミープロンプト。内容は検証しない
_SPEC_AI_PROMPT='spec prompt'

# run_ai_piped - 固定プロンプトを stdin で与えて run_ai を呼ぶ
#
# stdin の内容自体を検証しないケース（タイムアウト・argv・stderr 分離）から、
# ガードを通すためだけの stdin 供給を消す。
#
# @arg $@  run_ai へそのまま渡す引数
run_ai_piped() {
  run_ai "$@" <<<"$_SPEC_AI_PROMPT"
}
