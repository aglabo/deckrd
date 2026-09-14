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

# Guard: prevent re-sourcing
if [[ -n "${_ASSET_DIFF_LOADED:-}" ]]; then
  return 0
fi
readonly _ASSET_DIFF_LOADED=1

# asset_dest_name - Derive the deployed file name of an asset source file
#
# Takes the basename of the source path and removes a trailing `.org` suffix,
# which marks assets whose real name cannot be shipped as-is (e.g. `.gitignore`).
#
# @arg $1 Source file path
# @stdout Destination file name
# @return 0 always
asset_dest_name() {
  local name
  name="$(basename "$1")"
  printf '%s\n' "${name%.org}"
}

# list_updated_assets - List deployed assets that are older than and differ from the source
#
# For each regular file directly under src_dir (dotfiles included, subdirectories
# excluded), resolves its destination name with asset_dest_name. The name is
# printed only when that file exists in dest_dir, the source is newer than it
# (`-nt`), and its content differs (compared with `cmp -s`).
# Files missing from dest_dir, and deployed files newer than the source
# (i.e. edited by the user), are not reported.
#
# @arg $1 Source asset directory
# @arg $2 Destination directory
# @stdout Destination file names that are outdated, one per line
# @return 0 always (including when src_dir does not exist)
list_updated_assets() {
  local src_dir="$1" dest_dir="$2" src_file name dest_file
  [[ -d "$src_dir" ]] || return 0
  while IFS= read -r src_file; do
    name="$(asset_dest_name "$src_file")"
    dest_file="${dest_dir}/${name}"
    [[ -f "$dest_file" && "$src_file" -nt "$dest_file" ]] || continue
    cmp -s "$src_file" "$dest_file" || printf '%s\n' "$name"
  done < <(find "$src_dir" -maxdepth 1 -type f)
  return 0
}
