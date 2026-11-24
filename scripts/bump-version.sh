#!/usr/bin/env bash
# src: ./scripts/bump-version.sh
# @(#) : Unify the ci-platform version across package.json, workflow refs and action/workflow headers
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
#   - package.json                                   ("version")
#   - .github/workflows/*.yml                        (uses: aglabo/ci-platform/...@vX.Y.Z)
#   - .github/actions/*/action.yml                   (header comment "# @version : X.Y.Z")
#   - .github/workflows/ru-*.yml                     (header comment "# @version : X.Y.Z")
#
# Not updated (regenerate separately):
#   - .github/workflows/actions.lock  -> run `gh actions-lock` after the tag exists

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
_warned() { printf '  \033[31m!\033[0m %-14s %s\n' "$1" "$2"; }

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

# package.json: replace only the first top-level "version" (not dependency entries)
# shellcheck disable=SC2329 # invoked indirectly via _apply
_bump_json() {
  sed -i -E "0,/\"version\": \"${_SEMVER_RE}\"/s//\"version\": \"$2\"/" "$1"
}

# Header comment: replace "# @version : OLD", or insert it right after the "# @(#)" line
# shellcheck disable=SC2329 # invoked indirectly via _apply
_bump_header() {
  local file="$1" new="$2"
  if grep -q '^# @version' "$file"; then
    sed -i -E "s/^# @version.*/# @version : ${new}/" "$file"
  else
    sed -i "/^# @(#)/a # @version : ${new}" "$file"
  fi
}

# Self references: "uses: aglabo/ci-platform/<path>@vOLD" -> "@v<new>" (uses: lines only)
# shellcheck disable=SC2329 # invoked indirectly via _apply
_bump_uses_ref() {
  sed -i -E "s#(uses: *aglabo/ci-platform/[^@ ]+)@v${_SEMVER_RE}#\1@v$2#" "$1"
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

  printf '\n[package.json]\n'
  if [[ -f package.json ]]; then
    old=$({ grep -m1 '"version"' package.json || true; } | _first_semver)
    _apply "package.json" "package.json" "$old" _bump_json
  fi

  printf '\n[header @version]\n'
  for f in .github/actions/*/action.yml .github/workflows/ru-*.yml; do
    [[ -f $f ]] || continue
    if ! grep -q '^# @(#)' "$f"; then
      _warned "no @(#) line" "$f"
      continue
    fi
    old=$({ grep -m1 '^# @version' "$f" || true; } | _first_semver)
    _apply "header" "$f" "$old" _bump_header
  done

  printf '\n[uses: aglabo/ci-platform/...@v]\n'
  for f in .github/workflows/*.yml; do
    [[ -f $f ]] || continue
    grep -qE "uses: *aglabo/ci-platform/" "$f" || continue
    # First ref that differs from the new version (a file may mix versions)
    old=$(grep -E "uses: *aglabo/ci-platform/" "$f" | grep -oE "@v${_SEMVER_RE}" | { grep -oE "$_SEMVER_RE" || true; } | { grep -vxF "$_NEW_VERSION" || true; } | head -n1)
    old="${old:-$_NEW_VERSION}"
    _apply "uses ref" "$f" "$old" _bump_uses_ref
  done

  printf '\nDone.\n'
  printf 'NOTE: .github/workflows/actions.lock is not updated. Run "gh actions-lock" after tag v%s exists.\n' "$_NEW_VERSION"
}

main "$@"
exit $?
