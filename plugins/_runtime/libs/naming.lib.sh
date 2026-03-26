#!/usr/bin/env bash
# src: ./plugins/_runtime/libs/naming.lib.sh
# @(#) : Naming library - pick a random hacker name from hackers.dic
#
# Copyright (c) 2026- aglabo <https://github.com/aglabo>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

# shellcheck shell=bash
# cspell:words shuf

# Guard: prevent re-sourcing
if [[ -n "${_NAMING_LIB_LOADED:-}" ]]; then
  return 0
fi
readonly _NAMING_LIB_LOADED=1

# hacker_random - Pick a random hacker name from hackers.dic
#
# @arg $1 string (optional) Path to .dic file
#                           Default: ${PROJECT_ROOT}/plugins/_generated/hackers.dic
# @stdout One hacker short name (e.g. "knuth")
# @return 0 on success, 1 on error (file not found or empty)
hacker_random() {
  local dic="${1:-${PROJECT_ROOT}/plugins/_generated/hackers.dic}"

  if [[ ! -f "$dic" ]]; then
    echo "Error: hacker_random: file not found: ${dic}"
    return 1
  fi

  local name
  name=$(grep -v '^\s*#' "$dic" | grep -v '^\s*$' | shuf -n 1)

  if [[ -z "$name" ]]; then
    echo "Error: hacker_random: no entries found in: ${dic}"
    return 1
  fi

  printf '%s' "$name"
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
  local max_retries="${_GENERATE_FILENAME_MAX_RETRIES:-5}"

  local i=0
  local candidate
  while [[ $i -lt $max_retries ]]; do
    candidate=$(_generate_filename "$slug" "$postfix") || return 1

    if [[ ! -e "$candidate" ]]; then
      printf '%s' "$candidate"
      return 0
    fi

    i=$(( i + 1 ))
  done

  printf 'Error: generate_filename: max retries (%d) exceeded for slug "%s"\n' \
    "$max_retries" "$slug" >&2
  return 1
}
