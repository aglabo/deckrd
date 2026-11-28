#!/usr/bin/env bash
# skills/deckrd/skills/deckrd/scripts/libs/frontmatter.lib.sh - Markdown YAML frontmatter reader
#
# Copyright (c) 2026- atsushifx <https://github.com/atsushifx>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT
#
# @version 0.1.0
# USAGE: source this file, do NOT execute directly.
#   . "$(dirname "${BASH_SOURCE[0]}")/frontmatter.lib.sh"
# shellcheck disable=SC2016  # awk programs are single-quoted on purpose
#
# Reader results are memoized per field and file, because a caller reads the same few
# files many times and on Windows every re-read costs a fork plus an awk exec. The
# caches live in this process only. A caller drops them by assigning an empty array.
# The cache key joins field and file with a unit separator: neither can carry it, so the
# key cannot collide the way a `:` or `/` joined one could.

if [[ -n ${_LIB_FRONTMATTER_LOADED:-}   ]]; then
  return 0
fi
readonly _LIB_FRONTMATTER_LOADED=1

# Reader caches
declare -gA _FM_SCALAR_CACHE=()
declare -gA _FM_LIST_CACHE=()

# Result of fm_load_list
declare -ga _FM_LIST=()

# fm_read_scalar - Read a scalar field from a YAML frontmatter block
#
# jq cannot read frontmatter, so the block is parsed with awk (`$AWK` when set).
# Only a matching pair of surrounding quotes is removed; an unbalanced quote stays in
# the value. Empty quotes are a declared-but-invalid value, not an undeclared field, so
# they are kept for the caller's format check to reject.
#
# awk output is followed by a sentinel `x`, which survives the newline stripping of
# `$(...)`, so the cache replays exactly what awk wrote, trailing newline included. The
# sentinel is chained with `&&` so that printf does not replace the status of a failed
# awk, and a failed read returns before it can reach the cache.
#
# @arg $1 string Path to the Markdown file
# @arg $2 string Field name
# @stdout Field value with surrounding quotes stripped; empty when undeclared, the file
#   is absent, or the read fails
# @return 0 on success or when the file is absent, 1 when awk fails (not found, or
#   unable to open or read the file); a failed read is not cached
fm_read_scalar() {
  local file="$1" field="$2"
  local key="${field}"$'\037'"${file}"
  if [[ -n ${_FM_SCALAR_CACHE[$key]+x} ]]; then
    printf '%s' "${_FM_SCALAR_CACHE[$key]}"
    return 0
  fi
  local value=''
  if [[ -f $file   ]]; then
    # `x` keeps the trailing newline
    value="$(
      "${AWK:-awk}" -v key="$field" '
    NR == 1 && $0 == "---" { in_fm = 1; next }
    in_fm && $0 == "---" { exit }
    in_fm && index($0, key ":") == 1 {
      value = substr($0, length(key) + 2)
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", value)
      if (length(value) >= 2 && substr(value, 1, 1) == substr(value, length(value), 1) && (substr(value, 1, 1) == "\"" || substr(value, 1, 1) == "\047")) {
        unwrapped = substr(value, 2, length(value) - 2)
        # empty quotes are kept
        if (unwrapped != "") { value = unwrapped }
      }
      print value
      exit
    }
  ' "$file" \
            && printf 'x'
    )" || return 1
    value="${value%x}"
  fi
  _FM_SCALAR_CACHE[$key]="$value"
  printf '%s' "$value"
}

# fm_read_list - Read a block-style list field from a YAML frontmatter block
#
# @arg $1 string Path to the Markdown file
# @arg $2 string Field name
# @stdout One item per line, in declaration order; empty when undeclared, the file is
#   absent, or the read fails
# @return 0 on success or when the file is absent, 1 when awk fails (not found, or
#   unable to open or read the file); a failed read is not cached
fm_read_list() {
  local file="$1" field="$2"
  local cache_key="${field}"$'\037'"${file}"
  if [[ -n ${_FM_LIST_CACHE[$cache_key]+x} ]]; then
    printf '%s' "${_FM_LIST_CACHE[$cache_key]}"
    return 0
  fi
  local value=''
  if [[ -f $file   ]]; then
    value="$(
      "${AWK:-awk}" -v key="$field" '
    NR == 1 && $0 == "---" { in_fm = 1; next }
    in_fm && $0 == "---" { exit }
    in_fm && index($0, key ":") == 1 && substr($0, length(key) + 2) ~ /^[[:space:]]*$/ { in_list = 1; next }
    in_list && /^[[:space:]]*-[[:space:]]+/ {
      value = $0
      sub(/^[[:space:]]*-[[:space:]]+/, "", value)
      gsub(/^[ \t]+|[ \t]+$/, "", value)
      gsub(/^[\047"]|[\047"]$/, "", value)
      print value
      next
    }
    in_list { in_list = 0 }
  ' "$file" \
            && printf 'x'
    )" || return 1
    value="${value%x}"
  fi
  _FM_LIST_CACHE[$cache_key]="$value"
  printf '%s' "$value"
}

# fm_load_list - Load a frontmatter list field into _FM_LIST
#
# Equivalent to reading fm_read_list through `< <(...)`, minus the subshell:
# hot loops call this once per file, and a fork there dominates the run.
# The array is emptied first, so that a failed read never leaves the previous answer
# behind. fm_read_list only fills the cache; the value is read from the cache. The
# here-string appends a newline of its own, so the recorded one is dropped first.
# The caller copies _FM_LIST into a local before calling anything that could fill it
# again.
#
# @arg $1 string Path to the Markdown file
# @arg $2 string Field name
# @set _FM_LIST Items in declaration order; replaced on every call, empty on failure
# @return 0 on success or when the file is absent, 1 when the read fails
fm_load_list() {
  local file="$1" field="$2"
  local cache_key="${field}"$'\037'"${file}"
  _FM_LIST=()
  # fills the cache
  fm_read_list "$file" "$field" > /dev/null || return 1
  local value="${_FM_LIST_CACHE[$cache_key]}"
  [[ -n $value   ]] || return 0
  mapfile -t _FM_LIST <<< "${value%$'\n'}"
  return 0
}
