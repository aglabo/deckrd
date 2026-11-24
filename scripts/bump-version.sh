#!/usr/bin/env bash
# src: ./scripts/bump-version.sh
# @(#) : Unify the plugin version across package.json, marketplace, plugin.json and SKILL.md
#
# Copyright (c) 2026- atsushifx <https://github.com/atsushifx>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT
#
# Usage:
#   bash scripts/bump-version.sh [--dry-run] <new-version>
#   bash scripts/bump-version.sh 0.7.0
#   bash scripts/bump-version.sh --dry-run 0.7.0
#
# Updates:
#   - package.json, deckrd.json                      ("version")
#   - .claude-plugin/marketplace*.json               ("metadata.version")
#   - skills/*/.claude-plugin/plugin.json            ("version")
#   - skills/*/skills/*/SKILL.md                     (frontmatter "  version: X.Y.Z")

set -euo pipefail

PROJECT_ROOT="$(git rev-parse --show-toplevel 2> /dev/null || { cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd; })"

_SEMVER_RE='[0-9]+\.[0-9]+\.[0-9]+'
_DRY_RUN=false

# ── helpers ──────────────────────────────────────────────────────────────────

_usage() {
  cat >&2 << EOF
Usage: bash scripts/bump-version.sh [--dry-run] <new-version>
  <new-version>  Semantic version string without "v" (e.g. 0.7.0)
  --dry-run      Show what would change without modifying files
EOF
  return 1
}

_updated() { printf '  \033[32m✓\033[0m %-14s %s\n' "$1" "$2"; }
_skipped() { printf '  \033[33m–\033[0m %-14s %s\n' "$1" "$2"; }

# Report a change (or skip) for one file; apply it via the given function unless --dry-run.
# _apply <label> <file> <old> <apply-func>
_apply() {
  local label="$1" file="$2" old="$3" func="$4"
  if [[ $old == "$_NEW_VERSION"   ]]; then
    _skipped "$label" "$file"
    return 0
  fi
  [[ $_DRY_RUN == true   ]] || "$func" "$file" "$_NEW_VERSION"
  _updated "${old:-none} → $_NEW_VERSION" "$file"
}

# JSON files: replace only the first "version" (not dependency entries)
# shellcheck disable=SC2329 # invoked indirectly via _apply
_bump_json() {
  sed -i -E "0,/\"version\": \"${_SEMVER_RE}\"/s//\"version\": \"$2\"/" "$1"
}

# SKILL.md: replace only the frontmatter metadata line "  version: X.Y.Z"
# shellcheck disable=SC2329 # invoked indirectly via _apply
_bump_skill_md() {
  sed -i -E "s/^(  version: )${_SEMVER_RE}\$/\1$2/" "$1"
}

_first_semver() { grep -oE "$_SEMVER_RE" | head -n1 || true; }

# ── args ─────────────────────────────────────────────────────────────────────

_parse_args() {
  _NEW_VERSION=""
  local arg
  for arg in "$@"; do
    case "$arg" in
      --dry-run) _DRY_RUN=true ;;
      -h | --help)
        _usage
        return 1
        ;;
      -*)
        printf 'Error: unknown option "%s"\n' "$arg" >&2
        _usage
        return 1
        ;;
      *)
        if [[ -n $_NEW_VERSION ]]; then
          _usage
          return 1
        fi
        _NEW_VERSION="$arg"
        ;;
    esac
  done

  if [[ -z $_NEW_VERSION ]]; then
    _usage
    return 1
  fi

  if ! printf '%s' "$_NEW_VERSION" | grep -qE "^${_SEMVER_RE}$"; then
    printf 'Error: "%s" is not a valid semver (expected X.Y.Z, no "v" prefix)\n' "$_NEW_VERSION" >&2
    return 1
  fi
}

# ── main ─────────────────────────────────────────────────────────────────────

main() {
  _parse_args "$@" || return 1

  cd "$PROJECT_ROOT" || return 1

  local mode="" f old
  [[ $_DRY_RUN == true ]] && mode=" (dry-run)"
  printf '\nBumping version to \033[1m%s\033[0m%s\n' "$_NEW_VERSION" "$mode"

  printf '\n[json "version"]\n'
  for f in package.json deckrd.json .claude-plugin/marketplace*.json skills/*/.claude-plugin/plugin.json; do
    [[ -f $f ]] || continue
    old=$({ grep -m1 '"version"' "$f" || true; } | _first_semver)
    _apply "json" "$f" "$old" _bump_json
  done

  printf '\n[SKILL.md metadata.version]\n'
  for f in skills/*/skills/*/SKILL.md; do
    [[ -f $f ]] || continue
    old=$({ grep -m1 '^  version:' "$f" || true; } | _first_semver)
    _apply "skill" "$f" "$old" _bump_skill_md
  done

  printf '\nDone.\n'
}

main "$@"
exit $?
