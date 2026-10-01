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

# Marker text identifying the workspaces rule block in the local gitignore template
readonly WORKSPACES_RULE_MARKER='Shared notes layer'
# Regex (awk ERE) matching the banner lines that frame a gitignore template section
readonly WORKSPACES_RULE_BANNER='^## ---'

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

# workspaces_rule_missing - Report whether gitignore content lacks the workspaces rule
#
# The rule counts as present only when a line is exactly `!/workspaces/`,
# ignoring a trailing CR so that CRLF content is matched as well.
# Pure function: it reads no file and prints nothing. Checking that the gitignore
# exists and reading it are the caller's job.
#
# @arg $1 Content of a gitignore file (string)
# @return 0 No line equals `!/workspaces/` (including empty content)
# @return 1 A line equals `!/workspaces/`
workspaces_rule_missing() {
  ! grep -qxF '!/workspaces/' <<<"${1//$'\r'/}"
}

# workspaces_rule_block - Print the workspaces rule block of the local gitignore template content
#
# The block starts at the `## ---` banner line immediately above the line
# containing `Shared notes layer` and runs to the end of the content.
# Pure function: it reads no file. Locating and reading the template are the caller's job.
#
# @arg $1 Content of the local gitignore template (string)
# @stdout The block lines (nothing on failure)
# @return 0 The block was printed
# @return 1 The content has no marker line below a banner line
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
