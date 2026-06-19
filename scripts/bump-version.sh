#!/usr/bin/env bash
# scripts/bump-version.sh - Update deckrd plugin versions across all config files
#
# Usage:
#   bash scripts/bump-version.sh <new-version>
#   bash scripts/bump-version.sh 0.5.0
#
# Updates version in:
#   - skills/*/.claude-plugin/plugin.json
#   - skills/*/skills/*/SKILL.md (metadata.version)
#   - .claude-plugin/marketplace*.json (metadata.version)

set -euo pipefail

PROJECT_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || (cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd))"

# ── helpers ──────────────────────────────────────────────────────────────────

_usage() {
  cat >&2 <<EOF
Usage: bash scripts/bump-version.sh <new-version>
  <new-version>  Semantic version string (e.g. 0.5.0)
EOF
  exit 1
}

_info()    { printf '  %-12s %s\n' "$1" "$2"; }
_updated() { printf '  \033[32m✓\033[0m %-10s %s\n' "$1" "$2"; }
_skipped() { printf '  \033[33m–\033[0m %-10s %s\n' "$1" "$2"; }

# Replace version in JSON: "version": "OLD" → "version": "NEW"
_bump_json() {
  local file="$1" new="$2"
  sed -i "s/\"version\": \"[0-9]*\.[0-9]*\.[0-9]*\"/\"version\": \"${new}\"/" "$file"
}

# Replace version in SKILL.md frontmatter: "  version: OLD" → "  version: NEW"
_bump_skill() {
  local file="$1" new="$2"
  sed -i "s/^  version: [0-9]*\.[0-9]*\.[0-9]*/  version: ${new}/" "$file"
}

# ── main ─────────────────────────────────────────────────────────────────────

_NEW_VERSION="${1:-}"
[[ -z "$_NEW_VERSION" ]] && _usage

# Validate semver format
if ! echo "$_NEW_VERSION" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+$'; then
  printf 'Error: "%s" is not a valid semver (expected X.Y.Z)\n' "$_NEW_VERSION" >&2
  exit 1
fi

cd "$PROJECT_ROOT"

printf '\nBumping version to \033[1m%s\033[0m\n\n' "$_NEW_VERSION"

# 1. plugin.json in each plugin directory
for _f in skills/*/.claude-plugin/plugin.json; do
  [[ -f "$_f" ]] || continue
  _OLD=$(grep '"version"' "$_f" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' || true)
  if [[ "$_OLD" == "$_NEW_VERSION" ]]; then
    _skipped "plugin.json" "$_f"
  else
    _bump_json "$_f" "$_NEW_VERSION"
    _updated "$_OLD → $_NEW_VERSION" "$_f"
  fi
done

# 2. SKILL.md metadata.version in each skill directory
for _f in skills/*/skills/*/SKILL.md; do
  [[ -f "$_f" ]] || continue
  _OLD=$(grep -m1 '^ *version: ' "$_f" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' || true)
  [[ -z "$_OLD" ]] && continue
  if [[ "$_OLD" == "$_NEW_VERSION" ]]; then
    _skipped "SKILL.md" "$_f"
  else
    _bump_skill "$_f" "$_NEW_VERSION"
    _updated "$_OLD → $_NEW_VERSION" "$_f"
  fi
done

# 3. marketplace*.json metadata.version
for _f in .claude-plugin/marketplace*.json; do
  [[ -f "$_f" ]] || continue
  _OLD=$(grep '"version"' "$_f" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' || true)
  if [[ "$_OLD" == "$_NEW_VERSION" ]]; then
    _skipped "marketplace" "$_f"
  else
    _bump_json "$_f" "$_NEW_VERSION"
    _updated "$_OLD → $_NEW_VERSION" "$_f"
  fi
done

printf '\nDone.\n'
