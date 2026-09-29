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

# Helper: create an isolated temp directory and set DECKRD_TMPDIR / DECKRD_DOCS_DIR / DECKRD_LOCAL /
#         DECKRD_LOCAL_DATA / DECKRD_RULES_DIR / CLAUDE_RULES_DIR / CLAUDE_RULES_INDEX_DIR
setup_deckrd_tmpdir() {
  DECKRD_TMPDIR="$(mktemp -d)"
  export DECKRD_DOCS_DIR="${DECKRD_TMPDIR}/docs/.deckrd"
  export DECKRD_LOCAL="${DECKRD_TMPDIR}/.local/deckrd"
  export DECKRD_LOCAL_DATA="${DECKRD_TMPDIR}/.local/deckrd"
  export DECKRD_RULES_DIR="${DECKRD_DOCS_DIR}/rules"
  export CLAUDE_RULES_DIR="${DECKRD_TMPDIR}/.claude/rules/claude-rules"
  export CLAUDE_RULES_INDEX_DIR="${DECKRD_TMPDIR}/.claude/rules/deckrd-rules"
  mkdir -p "$DECKRD_DOCS_DIR" "$DECKRD_LOCAL"
}

# Helper: clean up temp directory
teardown_deckrd_tmpdir() {
  [[ -n "${DECKRD_TMPDIR:-}" && -d "$DECKRD_TMPDIR" ]] && rm -rf "$DECKRD_TMPDIR"
  unset DECKRD_TMPDIR DECKRD_DOCS_DIR DECKRD_LOCAL DECKRD_LOCAL_DATA DECKRD_RULES_DIR CLAUDE_RULES_DIR CLAUDE_RULES_INDEX_DIR
}

# Helper: report whether a command is absent from PATH
#
# `Skip if` の条件に `! command -v foo >/dev/null 2>&1` と直接書いてはならない。
# ShellSpec は先頭の `!` を条件の否定として扱わず、ガードが一度も発火しない。
# 実機テストが skip されずに走り、CLI 不在を「失敗」として報告してしまう。
# 否定はこの関数の内側に閉じ込め、`Skip if "..." command_missing foo` と書く。
#
# @arg $1 string コマンド名
# @return 0 if the command is not on PATH, 1 if it is
command_missing() {
  ! command -v "$1" >/dev/null 2>&1
}

# Assets directory (source of truth for generated files)
ASSETS_DIR="${SHELLSPEC_PROJECT_ROOT}/skills/deckrd/skills/deckrd/assets"
export ASSETS_DIR

# Helper: return the path to an asset file
asset_path() { echo "${ASSETS_DIR}/${1}"; }

# Helper: return the contents of an asset file
load_asset() { cat "${ASSETS_DIR}/${1}"; }

# ---- 実機テスト用モデル名 ----

# SPEC_CODEX_MODEL - 実機テストで codex に渡す OpenAI 系モデル名
#
# OpenAI 系のモデル名は世代交代で使えなくなる（`gpt-5` は現時点で既に不可）。
# spec ファイルにリテラルで散らすと、更新漏れのぶんだけ実機テストが
# 「CLI が壊れた」ではなく「モデル名が古い」ことで落ちる。
# モデルが変わったらここだけを書き換える。
SPEC_CODEX_MODEL='gpt-5.6-luna'
export SPEC_CODEX_MODEL

# SPEC_OPENCODE_MODEL - 実機テストで opencode に渡すモデル名
#
# opencode が引けるモデルは独自の一覧であり、OpenAI 系の名前をそのまま流用できない。
# SPEC_CODEX_MODEL を共用すると opencode の実機テストが「CLI が壊れた」ではなく
# 「opencode にそのモデルがない」ことで落ちるため、codex とは別に持つ。
# `opencode/` プレフィックスは呼び出し側で付ける。
SPEC_OPENCODE_MODEL='big-pickle'
export SPEC_OPENCODE_MODEL
