#!/usr/bin/env bash
# src: ./skills/deckrd/skills/deckrd/scripts/libs/naming.lib.sh
# @(#) : Naming library - pick a random hacker name from hackers.dic
#
# Copyright (c) 2026- aglabo <https://github.com/aglabo>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

# shellcheck shell=bash
# cspell:words shuf TOCTOU

# Guard: prevent re-sourcing
if [[ -n "${_NAMING_LIB_LOADED:-}" ]]; then
  return 0
fi
readonly _NAMING_LIB_LOADED=1

# Cache directory for generated filenames
# Override _FILENAME_CACHE_DIR directly in tests to isolate from DECKRD_LOCAL_DATA
_FILENAME_CACHE_DIR="${_FILENAME_CACHE_DIR:-${DECKRD_LOCAL_DATA:-$HOME/.local/share/deckrd}/cache/filenames}"

# Max retry count for generate_filename collision avoidance
# Override NAMING_MAX_RETRIES to change the limit
NAMING_MAX_RETRIES="${NAMING_MAX_RETRIES:-5}"

# _init_filename_cache - Ensure the filename cache directory exists
#
# @return 0 on success, 1 if _FILENAME_CACHE_DIR is unset or mkdir fails
_init_filename_cache() {
  local cache_dir="${_FILENAME_CACHE_DIR}"
  if [[ -z "$cache_dir" ]]; then
    echo "Error: _init_filename_cache: _FILENAME_CACHE_DIR is not set" >&2
    return 1
  fi
  mkdir -p "$cache_dir"
}

# _try_create_cache_file - Atomically create a cache entry for a filename
#
# Uses noclobber to prevent TOCTOU races: if the file already exists,
# the creation fails and returns 1.
#
# @arg $1 string filename  The filename to register in the cache
# @return 0 if newly created (filename is unique and now registered)
# @return 1 if file already exists or cache directory setup fails
_try_create_cache_file() {
  local filename="${1}"

  _init_filename_cache || return 1
  (
    set -o noclobber
    : >"${_FILENAME_CACHE_DIR}/${filename}"
  ) 2>/dev/null
}

_ADJECTIVES=(
  ancient bold brave calm clear cool dark deep dire dusty
  early fair fast firm free full good grand great grim hard
  high keen kind late lazy lean light lone lost mild neat
  nice noble odd pale plain proud pure quiet rare rich rough
  round safe sharp short shy slim slow smart soft solid stark
  stern still stone swift tall tame thin tiny tidy tough true
  vast warm wide wild wise young
)

# hacker_random - Pick a random hacker name from hackers.dic
#
# @arg $1 string (optional) Path to .dic file
#                           Default: ${PROJECT_ROOT}/skills/deckrd/_generated/hackers.dic
# @stdout One hacker short name (e.g. "knuth")
# @return 0 on success, 1 on error (file not found or empty)
hacker_random() {
  local dic="${1:-${PROJECT_ROOT}/skills/deckrd/_generated/hackers.dic}"

  if [[ ! -f "$dic" ]]; then
    echo "Error: hacker_random: file not found: ${dic}" >&2
    return 1
  fi

  local name
  name=$(grep -v '^\s*#' "$dic" | grep -v '^\s*$' | shuf -n 1)

  if [[ -z "$name" ]]; then
    echo "Error: hacker_random: no entries found in: ${dic}" >&2
    return 1
  fi

  printf '%s' "$name"
}

# adjective_random - Pick a random adjective from _ADJECTIVES
#
# @stdout One adjective word (e.g. "bold")
# @return 0 on success, 1 on error (empty array)
adjective_random() {
  if [[ ${#_ADJECTIVES[@]} -eq 0 ]]; then
    echo "Error: adjective_random: _ADJECTIVES array is empty" >&2
    return 1
  fi

  printf '%s\n' "${_ADJECTIVES[$RANDOM % ${#_ADJECTIVES[@]}]}"
}

# _generate_filename - Internal: generate a filename candidate (no collision check)
#
# @arg $1 string slug    Base identifier for the filename
# @arg $2 string postfix File type/category suffix (e.g. "doc", "spec")
# @stdout Filename in format: <slug>-<token>-<timestamp>-<hash>-<postfix>
# @return 0 on success, 1 if hacker_random fails
_generate_filename() {
  local slug="${1}"
  local postfix="${2}"

  local token
  token=$(hacker_random) || return 1

  local timestamp
  timestamp=$(date +%y%m%d-%H%M%S)

  local base="${slug}-${token}-${timestamp}"

  local hash
  hash=$(printf '%s' "$base" | sha256sum | cut -c1-4)

  printf '%s' "${slug}-${token}-${timestamp}-${hash}-${postfix}"
}

# generate_filename - Generate a unique filename with collision check
#
# @arg $1 string slug    Base identifier for the filename
# @arg $2 string postfix File type/category suffix (e.g. "doc", "spec")
# @stdout Filename in format: <slug>-<token>-<timestamp>-<hash>-<postfix>
# @return 0 on success, 1 if max retries exceeded or _generate_filename fails
generate_filename() {
  local slug="${1}"
  local postfix="${2}"
  local max_retries="${NAMING_MAX_RETRIES}"

  local i=0
  local candidate
  while [[ $i -lt $max_retries ]]; do
    candidate=$(_generate_filename "$slug" "$postfix") || return 1

    if _try_create_cache_file "$candidate"; then
      break
    fi

    i=$((i + 1))
  done

  if [[ $i -ge $max_retries ]]; then
    printf 'Error: generate_filename: max retries (%d) exceeded for slug "%s"\n' \
      "$max_retries" "$slug" >&2
    return 1
  fi

  printf '%s' "$candidate"
}
