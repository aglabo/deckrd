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

# asset_src_path - Resolve the source file path of an asset from its deployed name
#
# Inverse of asset_dest_name: prints `<src_dir>/<dest_name>` when that path exists,
# otherwise the `.org`-suffixed path. The plain name wins when both exist.
# The fallback path is printed without checking that it exists.
#
# @arg $1 Source asset directory
# @arg $2 Destination file name
# @stdout Source file path
# @return 0 always (including when src_dir does not exist)
asset_src_path() {
  local src_dir="$1" dest_name="$2"
  if [[ -e "${src_dir}/${dest_name}" ]]; then
    printf '%s\n' "${src_dir}/${dest_name}"
  else
    printf '%s\n' "${src_dir}/${dest_name}.org"
  fi
  return 0
}

# list_updated_assets - List deployed assets that are older than and differ from the source
#
# For each regular file directly under src_dir (dotfiles included, subdirectories
# excluded), resolves its destination name with asset_dest_name. The name is
# printed only when that file exists in dest_dir, the source is newer than it
# (`-nt`), and its content differs (compared with `cmp -s`).
# Files missing from dest_dir, and deployed files newer than the source
# (i.e. edited by the user), are not reported.
# Assets whose destination name is `.gitignore` are always skipped: they are
# deployed only by init and are meant to be edited by the user.
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
    [[ "$name" != ".gitignore" ]] || continue
    dest_file="${dest_dir}/${name}"
    [[ -f "$dest_file" && "$src_file" -nt "$dest_file" ]] || continue
    cmp -s "$src_file" "$dest_file" || printf '%s\n' "$name"
  done < <(find "$src_dir" -maxdepth 1 -type f)
  return 0
}

# init_asset_dirs - Define the asset source/destination directories and ASSET_TARGETS
#
# Sets each directory variable with `${VAR:-default}`, so values set beforehand
# (non-empty) are kept. *_SRC_DIR defaults are derived from INITS_DIR.
# ASSET_TARGETS is overwritten (not appended) with `<name>|<src_dir>|<dest_dir>` entries.
# Requires DECKRD_ROOT, PROJECT_ROOT, DECKRD_DOCS_DIR and DECKRD_LOCAL_DATA (set by bootstrap).
#
# @set INITS_DIR RULES_SRC_DIR RULES_INDEX_SRC_DIR CLAUDE_RULES_SRC_DIR DOCS_SRC_DIR
# @set LOCAL_SRC_DIR DECKRD_RULES_DIR CLAUDE_RULES_DIR CLAUDE_RULES_INDEX_DIR
# @set ASSET_TARGETS Array of `<name>|<src_dir>|<dest_dir>`
# @return 0 always
init_asset_dirs() {
  INITS_DIR="${INITS_DIR:-${DECKRD_ROOT}/assets/inits}"
  RULES_SRC_DIR="${RULES_SRC_DIR:-${INITS_DIR}/deckrd-rules}"
  RULES_INDEX_SRC_DIR="${RULES_INDEX_SRC_DIR:-${INITS_DIR}/deckrd-rules-index}"
  CLAUDE_RULES_SRC_DIR="${CLAUDE_RULES_SRC_DIR:-${INITS_DIR}/claude-rules}"
  DOCS_SRC_DIR="${DOCS_SRC_DIR:-${INITS_DIR}/docs}"
  LOCAL_SRC_DIR="${LOCAL_SRC_DIR:-${INITS_DIR}/local-deckrd}"
  DECKRD_RULES_DIR="${DECKRD_RULES_DIR:-${DECKRD_DOCS_DIR}/rules}"
  CLAUDE_RULES_DIR="${CLAUDE_RULES_DIR:-${PROJECT_ROOT}/.claude/rules/claude-rules}"
  CLAUDE_RULES_INDEX_DIR="${CLAUDE_RULES_INDEX_DIR:-${PROJECT_ROOT}/.claude/rules/deckrd-rules}"
  # shellcheck disable=SC2034 # consumed by callers
  ASSET_TARGETS=(
    "deckrd-rules|${RULES_SRC_DIR}|${DECKRD_RULES_DIR}"
    "claude-rules|${CLAUDE_RULES_SRC_DIR}|${CLAUDE_RULES_DIR}"
    "deckrd-rules-index|${RULES_INDEX_SRC_DIR}|${CLAUDE_RULES_INDEX_DIR}"
    "docs|${DOCS_SRC_DIR}|${DECKRD_DOCS_DIR}"
    "local-deckrd|${LOCAL_SRC_DIR}|${DECKRD_LOCAL_DATA}"
  )
  return 0
}
