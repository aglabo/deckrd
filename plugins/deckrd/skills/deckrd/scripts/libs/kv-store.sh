#!/usr/bin/env bash
# plugins/deckrd/skills/deckrd/scripts/libs/kv-store.sh - Generic key-value store
#
# Copyright (c) 2026- atsushifx <https://github.com/atsushifx>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT
#
# USAGE: source this file, do NOT execute directly.
#   . "$(dirname "${BASH_SOURCE[0]}")/libs/kv-store.sh"

# Guard: prevent re-sourcing
if [[ -n "${_KV_STORE_LOADED:-}" ]]; then
  return 0
fi
readonly _KV_STORE_LOADED=1

# Global associative array: store_name → schema string
declare -Ag _KV_SCHEMA

# _kv_schema_iter - Iterate over schema entries, calling callback for each key/default pair
#
# @arg $1 string Store name (used to look up schema)
# @arg $2 string Callback function name; called as: callback key default
_kv_schema_iter() {
  local store="$1"
  local callback="$2"
  local schema="${_KV_SCHEMA[$store]}"
  local line key default

  while IFS= read -r line; do
    # skip empty lines
    [[ -z "$line" ]] && continue
    key="${line%%|*}"
    default="${line#*|}"
    "$callback" "$key" "$default"
  done <<<"$schema"
}

# kv_init - Register schema for a store and initialize with default values
#
# @arg $1 string Store name
# @arg $2 string Schema string (newline-separated "key|default" entries)
kv_init() {
  local store="$1"
  local schema="$2"

  # Register schema
  _KV_SCHEMA["$store"]="$schema"

  # Declare the store associative array if not already declared
  declare -Ag "_KV_${store}"

  # Initialize with default values using nameref
  local -n _kv_buf="_KV_${store}"
  local _kv_set_default
  _kv_set_default() { _kv_buf["$1"]="${2}"; }
  _kv_schema_iter "$store" _kv_set_default
  unset -f _kv_set_default
}

# kv_get - Get value from store
#
# @arg $1 string Store name
# @arg $2 string Key name
# @stdout Value (empty string if key not found)
kv_get() {
  local store="$1"
  local key="$2"

  local -n _kv_buf="_KV_${store}"
  printf '%s' "${_kv_buf[$key]:-}"
}

# kv_set - Set value in store
#
# @arg $1 string Store name
# @arg $2 string Key name
# @arg $3 string Value
kv_set() {
  local store="$1"
  local key="$2"
  local value="${3:-}"

  local -n _kv_buf="_KV_${store}"
  _kv_buf["$key"]="$value"
}

# _kv_file_path - Derive .kv file path from a given path
# @arg $1 string Path (directory/basename; basename's extension is replaced with .kv)
#               e.g. "/foo/bar/kv.json" → "/foo/bar/kv.kv"
#                    "/foo/bar/session"  → "/foo/bar/session.kv"
# @stdout Resolved path with .kv extension
_kv_file_path() {
  local path="$1"
  local dir base
  dir="$(dirname "$path")"
  base="$(basename "$path")"
  base="${base%%.*}" # strip extension (first dot onward)
  printf '%s/%s.kv' "$dir" "$base"
}

# kv_load - Load store from file
#
# @arg $1 string Store name
# @arg $2 string Path (directory + basename; .kv extension applied automatically)
# @return 0 on success (including file-not-found with default init), 1 on schema error
kv_load() {
  local store="$1"
  local path="$2"
  local file
  file="$(_kv_file_path "$path")"

  if [[ -z "${_KV_SCHEMA[$store]+set}" ]]; then
    echo "Error: kv_load: schema not registered for store '${store}'"
    return 1
  fi

  local -n _kv_buf="_KV_${store}"

  if [[ ! -f "$file" ]]; then
    # File not found: initialize with defaults
    local _kv_set_default
    _kv_set_default() { _kv_buf["$1"]="${2}"; }
    _kv_schema_iter "$store" _kv_set_default
    unset -f _kv_set_default
    return 0
  fi

  # Validate JSON before loading
  if ! jq empty "$file" 2>/dev/null; then
    echo "Error: kv_load: invalid JSON file '${file}'"
    return 1
  fi

  # Load from JSON
  local _kv_load_key
  _kv_load_key() {
    local key="$1"
    local default="$2"
    local value
    value=$(jq -r ".${key} // empty" "$file" 2>/dev/null)
    _kv_buf["$key"]="${value:-${default}}"
  }
  _kv_schema_iter "$store" _kv_load_key
  unset -f _kv_load_key
}

# _kv_buf_to_json - Serialize an associative array to compact JSON
#
# @arg $1 string Store name (nameref target "_KV_<store>")
# @stdout Compact JSON object (no trailing newline issues, CRLF-safe)
_kv_buf_to_json() {
  local store="$1"
  # shellcheck disable=SC2178
  local -n _kv_buf="_KV_${store}"

  local json="{}"
  local key
  for key in "${!_kv_buf[@]}"; do
    json=$(printf '%s' "$json" | jq --arg k "$key" --arg v "${_kv_buf[$key]}" '. + {($k): $v}')
  done
  printf '%s' "$json" | jq -c . | tr -d '\r'
}

# kv_save - Save store contents to file
#
# @arg $1 string Store name
# @arg $2 string Path (directory + basename; .kv extension applied automatically)
# @return 0 on success, 1 on schema error
kv_save() {
  local store="$1"
  local path="$2"
  local file
  file="$(_kv_file_path "$path")"

  if [[ -z "${_KV_SCHEMA[$store]+set}" ]]; then
    echo "Error: kv_save: schema not registered for store '${store}'"
    return 1
  fi

  mkdir -p "$(dirname "$file")"
  _kv_buf_to_json "$store" >"$file"
}

# kv_all - Output all store entries as "key=value" lines
#
# @arg $1 string Store name
# @stdout All entries in "key=value" format
kv_all() {
  local store="$1"

  # shellcheck disable=SC2178
  local -n _kv_buf="_KV_${store}"
  local key
  for key in "${!_kv_buf[@]}"; do
    echo "${key}=${_kv_buf[$key]}"
  done
}
