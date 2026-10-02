#!/usr/bin/env bash
# skills/deckrd/skills/deckrd/scripts/libs/asset-diff.lib.sh - Detect assets whose deployed copy differs from the source
#
# Copyright (c) 2026- atsushifx <https://github.com/atsushifx>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT
#
# @version 0.1.0
# USAGE: source this file, do NOT execute directly.
#   . "$(dirname "${BASH_SOURCE[0]}")/asset-diff.lib.sh"
#
# Sections:
#   1. Asset directories  - init_asset_dirs
#   2. Asset listing      - list_asset_files and its file enumeration / checkers
#   3. Workspaces rule    - gitignore `!/workspaces/` rule detection and extraction

# Guard: prevent re-sourcing
if [[ -n "${_ASSET_DIFF_LOADED:-}" ]]; then
  return 0
fi
readonly _ASSET_DIFF_LOADED=1

# shellcheck disable=SC1091
. "$(dirname "${BASH_SOURCE[0]}")/utils.lib.sh"

# ============================================================================
# 1. Asset directories
# ============================================================================

# init_asset_dirs - Set the asset source/destination directories and ASSET_TARGETS
#
# Directory variables already set are kept.
#
# @set ASSET_TARGETS Array of `<label>|<src_dir>|<dest_dir>`
init_asset_dirs() {
  INITS_DIR="${INITS_DIR:-${DECKRD_ROOT}/assets/inits}"
  RULES_INDEX_SRC_DIR="${RULES_INDEX_SRC_DIR:-${INITS_DIR}/deckrd-rules-index}"
  CLAUDE_RULES_SRC_DIR="${CLAUDE_RULES_SRC_DIR:-${INITS_DIR}/claude-rules}"
  DOCS_SRC_DIR="${DOCS_SRC_DIR:-${INITS_DIR}/docs}"
  LOCAL_SRC_DIR="${LOCAL_SRC_DIR:-${INITS_DIR}/local-deckrd}"
  CLAUDE_RULES_DIR="${CLAUDE_RULES_DIR:-${PROJECT_ROOT}/.claude/rules/claude-rules}"
  CLAUDE_RULES_INDEX_DIR="${CLAUDE_RULES_INDEX_DIR:-${PROJECT_ROOT}/.claude/rules/deckrd-rules}"
  # shellcheck disable=SC2034 # consumed by callers
  ASSET_TARGETS=(
    "claude-rules|${CLAUDE_RULES_SRC_DIR}|${CLAUDE_RULES_DIR}"
    "deckrd-rules-index|${RULES_INDEX_SRC_DIR}|${CLAUDE_RULES_INDEX_DIR}"
    "docs|${DOCS_SRC_DIR}|${DECKRD_DOCS_DIR}"
    "local-deckrd|${LOCAL_SRC_DIR}|${DECKRD_LOCAL_DATA}"
  )
  return 0
}

# ============================================================================
# 2. Asset listing
# ============================================================================

# ASSET_KEEP_PATTERNS - Globs for deployed paths that are never overwritten (`.gitignore` at any depth)
# shellcheck disable=SC2034 # consumed by callers
ASSET_KEEP_PATTERNS=('.gitignore' '*/.gitignore')

# list_asset_files - List the assets that are missing from or outdated in dest_dir
#
# The destination of `<src_rel>` is `<dest_dir>/<src_rel without .org>`.
# Protected files (matching a keep pattern) missing from dest are included;
# protected files already present in dest are excluded. A destination that is
# a symlink is treated as deployed and is not listed. Read-only.
#
# With `--force` as the first argument, list every source file instead,
# ignoring whether dest exists or is a symlink, its mtime and content, and the
# keep patterns.
# `--force` in any other position does not enable force mode.
#
# With `--missing-only` as the first argument, list only the source files whose
# destination does not exist; a destination that exists (file or symlink) is
# excluded regardless of its mtime and content. Keep patterns still apply.
#
# Usage: list_asset_files [--force | --missing-only] <src_dir> <dest_dir> [keep...]
#
# @option --force Force mode, only as the first argument; the arguments below follow it
# @option --missing-only Missing-only mode, only as the first argument; the arguments below follow it
# @arg <src_dir> Source asset directory
# @arg <dest_dir> Destination directory
# @arg [keep...] Keep patterns (bash globs on the destination relative path), optional
# @stdout Source relative paths to copy, byte-sorted, one per line
list_asset_files() {
  local src_dir dest_dir src_rel dst_rel checker=_asset_can_update
  case "$1" in
    --force)
      shift
      _list_all_files "$1"
      return 0
      ;;
    --missing-only)
      shift
      checker=_asset_is_missing
      ;;
  esac
  src_dir="$(normalize_dir_path "$1")"
  dest_dir="$(normalize_dir_path "$2")"
  while IFS= read -r src_rel; do
    dst_rel="$(strip_suffix "$src_rel" .org)"
    if "$checker" "${src_dir}/${src_rel}" "${dest_dir}/${dst_rel}"; then
      printf '%s\n' "$src_rel"
    fi
  done < <(_list_candidate_files "$src_dir" "$dest_dir" "${@:3}")
  return 0
}

# --- File enumeration (internal) --------------------------------------------

# _list_all_files - List every file under a directory (internal)
#
# @arg $1 Directory
# @stdout Relative paths with `/` separators, byte-sorted, one per line
_list_all_files() {
  local src_dir
  src_dir="$(normalize_dir_path "$1")"
  [[ -d "$src_dir" ]] || return 0
  (cd -- "$src_dir" && find . -type f) | sed -e 's|^\./||' -e 's#\\#/#g' | LC_ALL=C sort
  return 0
}

# _list_candidate_files - List source files not shielded by a keep pattern (internal)
#
# Drop `<src_rel>` when its destination `<dest_dir>/<src_rel without .org>`
# exists (file or symlink) and matches a keep pattern. Protected files missing
# from dest are kept as candidates. This is the only place keep patterns apply.
#
# @arg $1 Source asset directory
# @arg $2 Destination directory
# @arg $3+ Keep patterns (bash globs on the destination relative path), optional
# @stdout Source relative paths, byte-sorted, one per line
_list_candidate_files() {
  local src_dir dest_dir src_rel dst_rel
  src_dir="$(normalize_dir_path "$1")"
  dest_dir="$(normalize_dir_path "$2")"
  while IFS= read -r src_rel; do
    dst_rel="$(strip_suffix "$src_rel" .org)"
    if [[ -e "${dest_dir}/${dst_rel}" || -L "${dest_dir}/${dst_rel}" ]] &&
      _asset_is_kept "$dst_rel" "${@:3}"; then
      continue
    fi
    printf '%s\n' "$src_rel"
  done < <(_list_all_files "$src_dir")
  return 0
}

# _asset_is_kept - Check whether a destination path matches a keep pattern (internal)
#
# The keep patterns are joined into one extglob alternation `@(p1|p2|...)`.
#
# @arg $1 Destination relative path
# @arg $2+ Keep patterns (bash globs, without `|` or `)`), optional
# @return 0 kept, 1 not kept
_asset_is_kept() {
  local IFS='|'
  # shellcheck disable=SC2053 # the patterns are globs on purpose
  [[ $1 == @(${*:2}) ]]
}

# --- Checkers (internal) ----------------------------------------------------
# Decide whether a source file is listed by list_asset_files.
# Every checker takes `<src_path> <dest_path>` and returns 0 to list, 1 to skip.

# _asset_can_update - Default checker: dest is missing or outdated (internal)
#
# List when dest does not exist, or when dest is a regular file older than and
# different from src. Skip when dest is newer (user edited) or has the same
# content. Never list when dest is a symlink (valid, dangling, or looping), so
# the link target is not overwritten.
#
# @arg $1 Source file path
# @arg $2 Destination file path
# @return 0 list, 1 skip
_asset_can_update() {
  local src="$1" dest="$2"
  # Check -L first: -e follows the link, so it is false for dangling or looping links
  [[ -L "$dest" ]] && return 1
  [[ -e "$dest" ]] || return 0
  [[ -f "$dest" && "$src" -nt "$dest" ]] && ! cmp -s "$src" "$dest"
}

# _asset_is_missing - `--missing-only` checker: dest is missing (internal)
#
# List only when dest neither exists nor is a symlink (valid, dangling, or
# looping). Never looks at mtime or content.
#
# @arg $1 Source file path (unused)
# @arg $2 Destination file path
# @return 0 list (missing), 1 skip (deployed)
_asset_is_missing() {
  [[ ! -e "$2" && ! -L "$2" ]]
}

# ============================================================================
# 3. Workspaces rule
# ============================================================================

# Marker text identifying the workspaces rule block in the local gitignore template
readonly WORKSPACES_RULE_MARKER='Shared notes layer'
# Regex (awk ERE) matching the banner lines that frame a gitignore template section
readonly WORKSPACES_RULE_BANNER='^## ---'

# workspaces_rule_missing - Check whether gitignore content lacks the `!/workspaces/` line
#
# @arg $1 Gitignore content (CRLF allowed)
# @return 0 missing, 1 present
workspaces_rule_missing() {
  ! grep -qxF '!/workspaces/' <<<"${1//$'\r'/}"
}

# workspaces_rule_block - Extract the workspaces rule block from the gitignore template
#
# The block runs from the `## ---` banner above the WORKSPACES_RULE_MARKER line
# to the end of the content.
#
# @arg $1 Gitignore template content
# @stdout The block
# @return 0 found, 1 not found
workspaces_rule_block() {
  awk -v marker="$WORKSPACES_RULE_MARKER" -v banner_re="$WORKSPACES_RULE_BANNER" '
    $0 ~ banner_re { banner = NR }
    !start && banner && index($0, marker) { start = banner }
    { lines[NR] = $0 }
    END {
      if (!start) exit 1
      for (i = start; i <= NR; i++) print lines[i]
    }
  ' <<<"$1"
}
