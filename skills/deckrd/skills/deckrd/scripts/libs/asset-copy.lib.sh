#!/usr/bin/env bash
# skills/deckrd/skills/deckrd/scripts/libs/asset-copy.lib.sh - Copy asset files into a deployment directory
#
# Copyright (c) 2026- atsushifx <https://github.com/atsushifx>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT
#
# @version 0.1.3
# USAGE: source this file, do NOT execute directly.
#   . "$(dirname "${BASH_SOURCE[0]}")/asset-copy.lib.sh"
#
# Sections:
#   1. Asset copy  - copy_assets and the per-file copy
#   2. Mtime sync  - sync_asset_mtimes

# Guard: prevent re-sourcing
if [[ -n "${_ASSET_COPY_LOADED:-}" ]]; then
  return 0
fi
readonly _ASSET_COPY_LOADED=1

# shellcheck disable=SC1091
. "$(dirname "${BASH_SOURCE[0]}")/asset-diff.lib.sh"

# ============================================================================
# 1. Asset copy
# ============================================================================

# copy_assets - Copy the assets that list_asset_files reports from src_dir into dest_dir
#
# `<src_rel>` is copied to `<dest_dir>/<src_rel without .org>`. The list is taken before
# copying starts. Which files are listed is decided by list_asset_files:
#
#   (none)          missing or outdated files; keep patterns apply
#   --missing-only  missing files only; keep patterns apply
#   --force         every file; keep patterns are ignored
#
# A destination symlink is never written through: it is not listed except in `--force`
# mode, where copy_asset_file replaces it with a regular file. Except in `--force` mode,
# sync_asset_mtimes runs afterwards (a `--force` copy already has the source's mtime).
#
# Usage: copy_assets [--force | --missing-only] <src_dir> <dest_dir> [keep...]
#
# @option --force Force mode; recognized only as the first argument
# @option --missing-only Missing-only mode; recognized only as the first argument
# @arg <src_dir> Source asset directory
# @arg <dest_dir> Destination directory, created if missing
# @arg [keep...] Keep patterns for list_asset_files and sync_asset_mtimes, optional
# @stdout Each copied destination relative path, one per line
# @stderr `Error:` line on failure
# @return 0 on success, including a missing src_dir
# @return 1 when dest_dir cannot be created, a copy fails, or sync_asset_mtimes fails
copy_assets() {
  local src_dir dest_dir list
  local -a mode_opt=()
  case "$1" in
  --force | --missing-only)
    mode_opt=("$1")
    shift
    ;;
  esac
  src_dir="$(normalize_dir_path "$1")"
  dest_dir="$(normalize_dir_path "$2")"
  if ! mkdir -p "$dest_dir"; then
    printf 'Error: failed to create directory: %s\n' "$dest_dir" >&2
    return 1
  fi
  [[ -d "$src_dir" ]] || return 0
  list="$(list_asset_files "${mode_opt[@]}" "$src_dir" "$dest_dir" "${@:3}")"
  _copy_listed_assets "$src_dir" "$dest_dir" "$list" || return 1
  [[ "${mode_opt[0]:-}" == --force ]] || sync_asset_mtimes "$src_dir" "$dest_dir" "${@:3}" || return 1
}

# --- Per-file copy (internal) -----------------------------------------------

# _copy_listed_assets - Copy each listed source file into dest_dir (internal)
#
# Stops at the first failure; the remaining entries are not copied.
#
# @arg $1 Source asset directory (normalized)
# @arg $2 Destination directory (normalized)
# @arg $3 Source relative paths, one per line; empty lines are skipped
# @stdout Each copied destination relative path (without `.org`), one per line
# @stderr `Error: failed to copy file: <dest>` on failure
# @return 0 on success, 1 on failure
_copy_listed_assets() {
  local src_dir="$1" dest_dir="$2" src_rel dst_rel dest
  while IFS= read -r src_rel; do
    # an empty list yields one empty line
    [[ -n "$src_rel" ]] || continue
    dst_rel="${src_rel%.org}"
    dest="${dest_dir}/${dst_rel}"
    if ! copy_asset_file "${src_dir}/${src_rel}" "$dest"; then
      printf 'Error: failed to copy file: %s\n' "$dest" >&2
      return 1
    fi
    printf '%s\n' "$dst_rel"
  done <<<"$3"
  return 0
}

# copy_asset_file - Copy one file with its mtime, creating parent directories
#
# A destination symlink is removed first, so it is replaced by a regular file and its
# link target is left untouched.
#
# @arg $1 Source file path
# @arg $2 Destination file path, overwritten if it exists
# @return 0 on success, non-zero on failure (no message)
copy_asset_file() {
  mkdir -p "$(dirname "$2")" || return
  if [[ -L "$2" ]]; then
    rm -f -- "$2" || return
  fi
  cp -p "$1" "$2"
}

# ============================================================================
# 2. Mtime sync
# ============================================================================

# sync_asset_mtimes - Give deployed files that are older but identical the source's mtime
#
# Candidates come from _list_candidate_files, so a kept destination is never touched.
# Only the mtime changes (`touch -r`), never the content. A destination symlink is skipped.
#
# @arg $1 Source asset directory
# @arg $2 Destination directory
# @arg $3+ Keep patterns for _list_candidate_files, optional
# @stderr `Error: failed to update timestamp: <dest>` on failure
# @return 0 on success, including a missing source directory
# @return 1 when a timestamp update fails
sync_asset_mtimes() {
  local src_dir dest_dir src_rel dst_rel src dest
  src_dir="$(normalize_dir_path "$1")"
  dest_dir="$(normalize_dir_path "$2")"
  while IFS= read -r src_rel; do
    dst_rel="${src_rel%.org}"
    src="${src_dir}/${src_rel}"
    dest="${dest_dir}/${dst_rel}"
    _asset_needs_mtime_sync "$src" "$dest" || continue
    if ! touch -r "$src" "$dest"; then
      printf 'Error: failed to update timestamp: %s\n' "$dest" >&2
      return 1
    fi
  done < <(_list_candidate_files "$src_dir" "$dest_dir" "${@:3}")
  return 0
}

# --- Checker (internal) -----------------------------------------------------

# _asset_needs_mtime_sync - Check whether dest should get the mtime of src (internal)
#
# @arg $1 Source file path
# @arg $2 Destination file path
# @return 0 when dest is a regular file (not a symlink), older than src, and identical to it
# @return 1 otherwise
_asset_needs_mtime_sync() {
  [[ ! -L "$2" && -f "$2" && "$1" -nt "$2" ]] && cmp -s "$1" "$2"
}
