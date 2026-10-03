#!/usr/bin/env bash
# skills/deckrd/skills/deckrd/scripts/libs/asset-diff.lib.sh - Detect assets whose deployed copy differs from the source
#
# Copyright (c) 2026- atsushifx <https://github.com/atsushifx>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT
#
# @version 0.1.3
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
# In every mode, including `--force`, a source file is never listed when its
# destination path is a real directory (not a symlink), or when its
# destination resolves into the source tree at any level (self-deploy, e.g.
# dest_dir or one of its subdirectories is a symlink to src_dir or to any
# directory under it), or when it is a hard link to its own source file.
#
# With `--force` as the first argument, list every other source file instead,
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
    _list_deployable_files "$1" "$2"
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
    dst_rel="${src_rel%.org}"
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

# _list_deployable_files - List the source files whose destination may be written (internal)
#
# `_list_all_files` filtered by `_asset_dest_is_blocked` on
# `<dest_dir>/<src_rel without .org>`, and without a destination that is the
# same file as its source (a hard link). The directories of the source tree are
# listed once per call, not per file. Feeds every list_asset_files mode:
# `--force` directly, the other modes through `_list_candidate_files`.
#
# @arg $1 Source asset directory
# @arg $2 Destination directory
# @stdout Source relative paths, byte-sorted, one per line
_list_deployable_files() {
  local src_dir dest_dir src_rel dest REPLY
  local -a src_dirs
  src_dir="$(normalize_dir_path "$1")"
  dest_dir="$(normalize_dir_path "$2")"
  # Rooted, so a src_dir starting with `-` is not taken as a find option
  _asset_rooted_path "$src_dir"
  # -H follows src_dir itself when it is a symlink; a missing src_dir leaves the list empty
  mapfile -t src_dirs < <(find -H "$REPLY" -type d 2>/dev/null)
  while IFS= read -r src_rel; do
    dest="${dest_dir}/${src_rel%.org}"
    _asset_dest_is_blocked "$dest" "${src_dirs[@]}" && continue
    # A hard link to its own source (not a symlink, which copy_asset_file replaces)
    # would be copied onto itself
    [[ ! -L "$dest" && "$dest" -ef "${src_dir}/${src_rel}" ]] && continue
    printf '%s\n' "$src_rel"
  done < <(_list_all_files "$src_dir")
  return 0
}

# _asset_dest_is_blocked - Check whether a destination must never be written (internal)
#
# Blocked when dest is a real directory (a symlink to a directory is not
# blocked here), or when dest resolves into the source tree at any level: the
# nearest existing ancestor of dest (`_asset_nearest_dir`; it starts at the
# parent of dest, so a dest that is itself a symlink to a directory is judged
# by where it sits, not where it points, and missing intermediate directories
# are skipped) is the same directory (`-ef`) as one of the source tree
# directories. Comparing file identity, not path strings,
# catches a symlink anywhere above dest, a case-variant spelling, and
# drive-letter paths, and never walks `..` (Git Bash folds `..` in a
# drive-letter path textually, before any symlink is followed). In-process.
#
# A dest containing `..` behind a missing directory may be blocked
# conservatively: the strip-based walk drops the `..` together with the missing
# part, so the judged ancestor can be deeper than the real one. This false
# positive only skips a write, which is the safe side.
#
# @arg $1 Destination file path
# @arg $2+ Source tree directories: src_dir and every directory under it (none never blocks by location)
# @return 0 blocked, 1 not blocked
_asset_dest_is_blocked() {
  local REPLY dir
  [[ -d "$1" && ! -L "$1" ]] && return 0
  _asset_nearest_dir "$1"
  for dir in "${@:2}"; do
    [[ "$REPLY" -ef "$dir" ]] && return 0
  done
  return 1
}

# _asset_nearest_dir - Find the nearest existing ancestor directory of a path (internal)
#
# Starts at the parent of the path (the path itself is never returned, even
# when it is a directory or a symlink to one), then strips one `/component` at
# a time (pure string operation, no `..` resolution) until it names a
# directory. A `..` component is stripped like any other name, so for a path
# with `..` behind a missing directory the result can be deeper than the real
# ancestor (see `_asset_dest_is_blocked`). It never strips past the first
# component:
# a relative path is walked as `./<path>`, so it stops at `./`; an absolute
# path stops at `/` or at a drive root such as `C:/`. Every iteration shortens
# the path, so the walk always ends. Runs in-process, no subshell.
#
# @arg $1 Path (need not exist)
# @set REPLY The nearest existing ancestor directory, with a trailing `/`
#   (the root of a missing drive is returned as is)
_asset_nearest_dir() {
  _asset_rooted_path "$1"
  REPLY="${REPLY%/*}"
  while [[ "$REPLY" == */* && ! -d "${REPLY}/" ]]; do
    REPLY="${REPLY%/*}"
  done
  REPLY="${REPLY}/"
}

# _asset_rooted_path - Root a path so that it never starts with a bare name (internal)
#
# A relative path gets a `./` prefix; an absolute path (`/...`) or a
# drive-letter path (`C:/...`) is kept. The result never starts with `-`, so a
# command never parses it as an option. Runs in-process, no subshell.
#
# @arg $1 Path
# @set REPLY The rooted path
_asset_rooted_path() {
  REPLY="$1"
  [[ "$REPLY" == /* || "$REPLY" == [A-Za-z]:/* ]] || REPLY="./${REPLY}"
}

# _list_candidate_files - List source files not shielded by a keep pattern (internal)
#
# Starts from `_list_deployable_files`, so self-deploy and real-directory
# destinations are already excluded.
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
    dst_rel="${src_rel%.org}"
    if [[ -e "${dest_dir}/${dst_rel}" || -L "${dest_dir}/${dst_rel}" ]] &&
      _asset_is_kept "$dst_rel" "${@:3}"; then
      continue
    fi
    printf '%s\n' "$src_rel"
  done < <(_list_deployable_files "$src_dir" "$dest_dir")
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
# Regex (sed BRE) matching the banner lines that frame a gitignore template section
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
# The block runs from the `## ---` banner directly above the WORKSPACES_RULE_MARKER line
# to the end of the content.
#
# @arg $1 Gitignore template content
# @stdout The block
# @return 0 found, 1 not found
workspaces_rule_block() {
  # Slide a 2-line window; on a banner+marker pair print through EOF, else exit 1 at the last line
  sed -n "\$!N; /${WORKSPACES_RULE_BANNER}[^\n]*\n[^\n]*${WORKSPACES_RULE_MARKER}/{:a;p;n;ba}; \$q1; D" <<<"$1"
}
