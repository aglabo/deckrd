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

# export_sandbox_local_dirs - Export all DECKRD_LOCAL_* variables under the sandbox at once
#
# Override every DECKRD_LOCAL_* exported by bootstrap.lib.sh.
# Missing one lets scripts reading that variable write into the real repository.
# The override is defined only here, and isolation helpers call it.
#
# Callers must be specs that sourced bootstrap.lib.sh with `--no-finalize`.
# Once finalized, readonly makes the assignments fail.
#
# @arg $1 string Directory to use as the sandbox DECKRD_LOCAL_DATA
export_sandbox_local_dirs() {
  export DECKRD_LOCAL_DATA="$1"
  export DECKRD_LOCAL_TEMP="${1}/temp"
  export DECKRD_LOCAL_WORKSPACES="${1}/workspaces"
}

# unset_sandbox_local_dirs - Unset every variable overridden by export_sandbox_local_dirs
unset_sandbox_local_dirs() {
  unset DECKRD_LOCAL_DATA DECKRD_LOCAL_TEMP DECKRD_LOCAL_WORKSPACES
}

# Helper: create an isolated temp directory and set DECKRD_TMPDIR / DECKRD_DOCS_DIR / DECKRD_LOCAL /
#         DECKRD_LOCAL_DATA / DECKRD_LOCAL_TEMP / DECKRD_LOCAL_WORKSPACES / DECKRD_RULES_DIR /
#         CLAUDE_RULES_DIR / CLAUDE_RULES_INDEX_DIR
#
# Override every DECKRD_LOCAL_* exported by bootstrap.lib.sh.
# Missing one lets scripts reading that variable write into the real repository.
#
# Call this helper only from specs that sourced bootstrap.lib.sh with `--no-finalize`.
# Once finalized, readonly makes the assignments fail.
setup_deckrd_tmpdir() {
  DECKRD_TMPDIR="$(mktemp -d)"
  export DECKRD_DOCS_DIR="${DECKRD_TMPDIR}/docs/.deckrd"
  export DECKRD_LOCAL="${DECKRD_TMPDIR}/.local/deckrd"
  export_sandbox_local_dirs "${DECKRD_TMPDIR}/.local/deckrd"
  export DECKRD_RULES_DIR="${DECKRD_DOCS_DIR}/rules"
  export CLAUDE_RULES_DIR="${DECKRD_TMPDIR}/.claude/rules/claude-rules"
  export CLAUDE_RULES_INDEX_DIR="${DECKRD_TMPDIR}/.claude/rules/deckrd-rules"
  mkdir -p "$DECKRD_DOCS_DIR" "$DECKRD_LOCAL"
}

# Helper: clean up temp directory
#
# Pairs with setup_deckrd_tmpdir. Unsets every variable it overrode.
teardown_deckrd_tmpdir() {
  [[ -n "${DECKRD_TMPDIR:-}" && -d "$DECKRD_TMPDIR" ]] && rm -rf "$DECKRD_TMPDIR"
  unset_sandbox_local_dirs
  unset DECKRD_TMPDIR DECKRD_DOCS_DIR DECKRD_LOCAL DECKRD_RULES_DIR \
    CLAUDE_RULES_DIR CLAUDE_RULES_INDEX_DIR
}

# Helper: report whether a command is absent from PATH
#
# Do NOT write `! command -v foo >/dev/null 2>&1` directly in a `Skip if` condition.
# ShellSpec does not treat a leading `!` as negation, so the guard never fires.
# Live tests then run instead of skipping and report a missing CLI as a failure.
# Keep the negation inside this function and write `Skip if "..." command_missing foo`.
#
# @arg $1 string Command name
# @return 0 if the command is not on PATH, 1 if it is
command_missing() {
  ! command -v "$1" >/dev/null 2>&1
}

# path_outside_repo - Report whether the given path points outside the repository tree
#
# For the same reason as `Skip if`, keep the negation in this function, not in the ShellSpec condition.
#
# Empty strings and relative paths are false. Checking only `!= "$ROOT"/*` would let both
# unset variables (`${VAR:-}` becomes empty) and relative paths pass as "outside",
# so assertions would miss an implementation that forgot to override a variable.
#
# @arg $1 string Path to check
# @return 0 if the path is absolute and outside SHELLSPEC_PROJECT_ROOT, 1 otherwise
path_outside_repo() {
  [[ "$1" == /* && "$1" != "${SHELLSPEC_PROJECT_ROOT}"/* ]]
}

# Assets directory (source of truth for generated files)
ASSETS_DIR="${SHELLSPEC_PROJECT_ROOT}/skills/deckrd/skills/deckrd/assets"
export ASSETS_DIR

# Helper: return the path to an asset file
asset_path() { echo "${ASSETS_DIR}/${1}"; }

# Helper: return the contents of an asset file
load_asset() { cat "${ASSETS_DIR}/${1}"; }

# ---- Model names for live tests ----

# SPEC_CODEX_MODEL - OpenAI model name passed to codex in live tests
#
# OpenAI model names become unusable as generations change (`gpt-5` is already unavailable).
# Scattering literals across spec files means every missed update makes live tests fail
# because the model name is stale, not because the CLI is broken.
# Update only this line when the model changes.
SPEC_CODEX_MODEL='gpt-5.6-luna'
export SPEC_CODEX_MODEL

# SPEC_OPENCODE_MODEL - Model name passed to opencode in live tests
#
# opencode resolves models from its own list, so OpenAI names cannot be reused as-is.
# Sharing SPEC_CODEX_MODEL would make opencode live tests fail because opencode lacks
# that model, not because the CLI is broken, so it is kept separate from codex.
# Callers add the `opencode/` prefix.
SPEC_OPENCODE_MODEL='big-pickle'
export SPEC_OPENCODE_MODEL
