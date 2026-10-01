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

# export_sandbox_local_dirs - DECKRD_LOCAL_* を sandbox 配下へ一括で export する
#
# bootstrap.lib.sh が export する DECKRD_LOCAL_* は全部差し替える。
# 1 つ漏らすと、その変数を読むスクリプトが実リポジトリへ書く。
# 差し替えの定義をここ 1 箇所に置き、隔離ヘルパーはこれを呼ぶ。
#
# 呼び出し元は bootstrap.lib.sh を `--no-finalize` で source した spec に限る。
# finalize 済みでは readonly により代入が失敗する。
#
# @arg $1 string sandbox 側の DECKRD_LOCAL_DATA に据えるディレクトリ
export_sandbox_local_dirs() {
  export DECKRD_LOCAL_DATA="$1"
  export DECKRD_LOCAL_TEMP="${1}/temp"
  export DECKRD_LOCAL_WORKSPACES="${1}/workspaces"
}

# unset_sandbox_local_dirs - export_sandbox_local_dirs が差し替えた変数を全部 unset する
unset_sandbox_local_dirs() {
  unset DECKRD_LOCAL_DATA DECKRD_LOCAL_TEMP DECKRD_LOCAL_WORKSPACES
}

# Helper: create an isolated temp directory and set DECKRD_TMPDIR / DECKRD_DOCS_DIR / DECKRD_LOCAL /
#         DECKRD_LOCAL_DATA / DECKRD_LOCAL_TEMP / DECKRD_LOCAL_WORKSPACES / DECKRD_RULES_DIR /
#         CLAUDE_RULES_DIR / CLAUDE_RULES_INDEX_DIR
#
# bootstrap.lib.sh が export する DECKRD_LOCAL_* は全部差し替える。
# 1 つ漏らすと、その変数を読むスクリプトが実リポジトリへ書く。
#
# このヘルパーは bootstrap.lib.sh を `--no-finalize` で source した spec から呼ぶこと。
# finalize 済みでは readonly により代入が失敗する。
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
# setup_deckrd_tmpdir が差し替えた変数と対を成す。差し替えた変数は全部 unset する。
teardown_deckrd_tmpdir() {
  [[ -n "${DECKRD_TMPDIR:-}" && -d "$DECKRD_TMPDIR" ]] && rm -rf "$DECKRD_TMPDIR"
  unset_sandbox_local_dirs
  unset DECKRD_TMPDIR DECKRD_DOCS_DIR DECKRD_LOCAL DECKRD_RULES_DIR \
    CLAUDE_RULES_DIR CLAUDE_RULES_INDEX_DIR
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

# path_outside_repo - 与えたパスがリポジトリツリーの外を指すかを報告する
#
# `Skip if` と同じ理由で、否定を ShellSpec の条件式へ直接書かずこの関数へ閉じ込める。
#
# 空文字列と相対パスは偽とする。素朴に `!= "$ROOT"/*` だけを見ると、
# 未設定の変数（`${VAR:-}` が空になる）と相対パスがどちらも「外」として通り、
# 変数を差し替え忘れた実装をアサーションが見逃す。
#
# @arg $1 string 検査するパス
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
