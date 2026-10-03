#!/usr/bin/env bash
# skills/deckrd/skills/deckrd/scripts/libs/asset-copy.lib.sh - Copy asset files into a deployment directory
#
# Copyright (c) 2026- atsushifx <https://github.com/atsushifx>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT
#
# @version 0.1.0
# USAGE: source this file, do NOT execute directly.
#   . "$(dirname "${BASH_SOURCE[0]}")/asset-copy.lib.sh"

# Guard: prevent re-sourcing
if [[ -n "${_ASSET_COPY_LOADED:-}" ]]; then
  return 0
fi
readonly _ASSET_COPY_LOADED=1

# shellcheck disable=SC1091
. "$(dirname "${BASH_SOURCE[0]}")/asset-diff.lib.sh"

# copy_asset_file - Copy one file, creating the destination's parent directories
#
# The copy keeps the source file's mtime (`cp -p`), so the deployed file
# carries the asset's own timestamp rather than the deployment time.
# A destination that is a symbolic link (to a file or a directory, or
# dangling) is removed first, so the link is replaced by a regular file and
# its link target (which may live outside the destination tree) is untouched.
#
# @arg $1 Source file path
# @arg $2 Destination file path (overwritten if it exists; a symlink is removed
#   and replaced by a regular file, leaving its link target unchanged)
# @return 0 on success, non-zero on failure (no message)
copy_asset_file() {
  mkdir -p "$(dirname "$2")" || return
  if [[ -L "$2" ]]; then
    rm -f -- "$2" || return
  fi
  cp -p "$1" "$2"
}

# _asset_needs_mtime_sync - Report whether <dest> should get the mtime of <src>
#
# @arg $1 Source file path
# @arg $2 Destination file path
# @return 0 when dest is a regular file (not a symlink), older than src, and has
#   the same content; 1 otherwise
_asset_needs_mtime_sync() {
  [[ ! -L "$2" && -f "$2" && "$1" -nt "$2" ]] && cmp -s "$1" "$2"
}

# sync_asset_mtimes - Align the mtime of deployed files that are older but identical
#
# Candidates come from _list_candidate_files, so an existing destination that
# matches a keep pattern is excluded when the list is built and never touched.
# The destination of `<src_rel>` is `<dest_dir>/<src_rel without .org>`.
# Its mtime is set to the source's (`touch -r`) only when it is an existing
# regular file, is older than the source, and has the same content.
# A destination that is a symbolic link is skipped, so the mtime of the link
# target (which may live outside dest_dir) is never changed.
# Content is never changed.
#
# @arg $1 Source asset directory
# @arg $2 Destination directory
# @arg $3+ Keep patterns passed to _list_candidate_files, optional
# @stderr `Error:` line on failure
# @return 0 on success (including a missing source directory)
# @return 1 when a timestamp update fails
sync_asset_mtimes() {
  local src_dir dest_dir src_rel dst_rel src dest
  src_dir="$(normalize_dir_path "$1")"
  dest_dir="$(normalize_dir_path "$2")"
  while IFS= read -r src_rel; do
    dst_rel="$(strip_suffix "$src_rel" .org)"
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

# copy_assets - Copy the assets that list_asset_files reports into dest_dir
#
# Each source `<src_rel>` is copied to `<dest_dir>/<src_rel without .org>`.
# The list is taken before copying starts. After copying, sync_asset_mtimes
# aligns the mtime of deployed files that are older but identical to the source.
# Keep patterns are only passed on: list_asset_files and sync_asset_mtimes drop
# protected files when they build their lists, so copying never checks them.
# In normal mode a destination that is a symbolic link (valid or dangling) is
# not listed, so it is never copied over and its link target (which may live
# outside dest_dir) is neither overwritten nor created. Other files are still
# copied as usual.
#
# With `--force` as the first argument, list_asset_files runs in force mode, so
# every source file is copied regardless of whether dest exists, its mtime and
# content, and the keep patterns. sync_asset_mtimes is still called without it.
# A destination that is a symbolic link is replaced by a regular file (see
# copy_asset_file); the link target is neither overwritten nor copied into.
# `--force` in any other position does not enable force mode.
#
# With `--missing-only` as the first argument, list_asset_files runs in
# missing-only mode, so only source files whose destination does not exist are
# copied; an existing destination (file or symlink) is never overwritten, even
# when it is older than and differs from the source. Keep patterns still apply,
# and sync_asset_mtimes is still called without it.
# `--missing-only` in any other position does not enable missing-only mode.
#
# Usage: copy_assets [--force | --missing-only] <src_dir> <dest_dir> [keep...]
#
# @option --force Force mode, only as the first argument; the arguments below follow it
# @option --missing-only Missing-only mode, only as the first argument; the arguments below follow it
# @arg <src_dir> Source asset directory
# @arg <dest_dir> Destination directory (created if missing)
# @arg [keep...] Keep patterns passed to list_asset_files and sync_asset_mtimes, optional
# @stdout Each copied destination relative path, one per line
# @stderr `Error:` line on failure
# @return 0 on success (including a missing source directory)
# @return 1 when dest_dir cannot be created or a copy fails
copy_assets() {
  local src_dir dest_dir list src_rel dst_rel dest
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
  while IFS= read -r src_rel; do
    # an empty list yields one empty line
    [[ -n "$src_rel" ]] || continue
    dst_rel="$(strip_suffix "$src_rel" .org)"
    dest="${dest_dir}/${dst_rel}"
    if ! copy_asset_file "${src_dir}/${src_rel}" "$dest"; then
      printf 'Error: failed to copy file: %s\n' "$dest" >&2
      return 1
    fi
    printf '%s\n' "$dst_rel"
  done <<<"$list"
  sync_asset_mtimes "$src_dir" "$dest_dir" "${@:3}" || return 1
}
