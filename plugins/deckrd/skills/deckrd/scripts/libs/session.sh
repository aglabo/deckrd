#!/usr/bin/env bash
# plugins/deckrd/skills/deckrd/scripts/libs/session.sh - Session data management
#
# Copyright (c) 2026- atsushifx <https://github.com/atsushifx>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT
#
# USAGE: source this file, do NOT execute directly.
#   . "$(dirname "${BASH_SOURCE[0]}")/libs/session.sh"

# Guard: prevent re-sourcing
if [[ -n "${_SESSION_LOADED:-}" ]]; then
  return 0
fi
readonly _SESSION_LOADED=1

# Load kv-store as the backing implementation
# shellcheck disable=SC1091
. "${DECKRD_LIB_DIR}/kv-store.sh"

# SESSION_SCHEMA - compatibility shim: exposes _KV_SCHEMA as SESSION_SCHEMA
# This allows existing code that checks SESSION_SCHEMA[$buffer] to work.
# We use a nameref alias to the same underlying array.
declare -n SESSION_SCHEMA="_KV_SCHEMA"

# session_init - Register schema for a buffer and initialize with defaults
#
# @arg $1 string Buffer name (store name)
# @arg $2 string Schema string
session_init() {
  local buffer="$1"
  local schema="$2"
  kv_init "$buffer" "$schema"
}

# session_load - Load session from JSON file into buffer
#
# @arg $1 string JSON file path
# @arg $2 string Buffer name (store name)
# @return 0 on success (including file-not-found with default init), 1 on schema error
session_load() {
  local file="$1"
  local buffer="$2"

  if [[ -z "${_KV_SCHEMA[$buffer]+set}" ]]; then
    echo "Error: session_load: schema not registered for buffer '${buffer}'" >&2
    return 1
  fi

  kv_load "$buffer" "$file"
}

# session_save - Save buffer contents to JSON file
#
# @arg $1 string JSON file path
# @arg $2 string Buffer name (store name)
# @return 0 on success
session_save() {
  local file="$1"
  local buffer="$2"
  kv_save "$buffer" "$file"
}

# session_get - Get value from buffer
#
# @arg $1 string Buffer name (store name)
# @arg $2 string Key name
# @stdout Value (empty string if key not found)
session_get() {
  local buffer="$1"
  local key="$2"
  kv_get "$buffer" "$key"
}

# session_set - Set value in buffer
#
# @arg $1 string Buffer name (store name)
# @arg $2 string Key name
# @arg $3 string Value
session_set() {
  local buffer="$1"
  local key="$2"
  local value="${3:-}"
  kv_set "$buffer" "$key" "$value"
}
