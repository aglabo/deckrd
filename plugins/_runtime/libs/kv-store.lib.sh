#!/usr/bin/env bash
# plugins/_runtime/libs/kv-store.lib.sh - Generic key-value store
#
# Copyright (c) 2026- atsushifx <https://github.com/atsushifx>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT
#
# @version 0.1.0
# USAGE: source this file, do NOT execute directly.
#   . "$(dirname "${BASH_SOURCE[0]}")/kv-store.lib.sh"
# shellcheck disable=SC2178  # nameref false positive: local -n correctly references arrays
# shellcheck disable=SC2016  # jq filter strings intentionally use single quotes; $k/$v are jq variables, not shell

# Guard: prevent re-sourcing
if [[ -n "${_KV_STORE_LOADED:-}" ]]; then
  return 0
fi
readonly _KV_STORE_LOADED=1

# shellcheck source=plugins/_runtime/libs/utils.lib.sh
# shellcheck disable=SC1091
. "$(dirname "${BASH_SOURCE[0]}")/utils.lib.sh"

# Global associative array: store_name → schema array name ("_KV_SCHEMA_<store>")
declare -Ag _KV_SCHEMA

# _kv_schema_iter - Iterate over schema entries, calling callback for each key/default pair
#
# @arg $1 string Store name (used to look up schema array)
# @arg $2 string Callback function name; called as: callback key default
_kv_schema_iter() {
  local store="$1"
  local callback="$2"

  local -n _kv_schema_ref="_KV_SCHEMA_${store}"
  local key

  for key in "${!_kv_schema_ref[@]}"; do
    "$callback" "$key" "${_kv_schema_ref[$key]}"
  done
}

# _kv_normalize_key - Normalize and validate a key name
#
# Trims leading/trailing whitespace, then validates against identifier naming rules.
# Valid pattern: ^[a-zA-Z_][a-zA-Z0-9_]*$
#   - First character: letter or underscore
#   - Subsequent characters: letters, digits, or underscores
#
# @arg $1 string Key name to normalize and validate
# @stdout Normalized key on success; error message on failure
# @return 0 if valid, 1 if invalid
_kv_normalize_key() {
  local key="$1"

  # Trim leading and trailing whitespace
  key="${key#"${key%%[![:space:]]*}"}"
  key="${key%"${key##*[![:space:]]}"}"

  if [[ -z "$key" ]]; then
    echo "Error: _kv_normalize_key: key must not be empty" >&2
    return 1
  fi

  if [[ ! "$key" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]]; then
    echo "Error: _kv_normalize_key: invalid key: '${key}'" >&2
    return 1
  fi

  echo "$key"
}

# kv_init - Register schema for a store and initialize with default values
#
# @arg $1 string Store name
# @arg $2 string Schema string (newline-separated "key|default" entries)
kv_init() {
  local store="$1"
  local schema="$2"

  # Guard: empty schema is an error
  if [[ -z "$schema" ]]; then
    echo "Error: kv_init: schema must not be empty" >&2
    return 1
  fi

  # Validate and normalize all keys first (fail fast before mutating state)
  local _kv_init_line _kv_init_key _kv_init_default _key _rc
  local -a _validated_keys=()
  local -a _validated_defaults=()
  while IFS= read -r _kv_init_line; do
    [[ -z "$_kv_init_line" ]] && continue
    _kv_init_key="${_kv_init_line%%|*}"
    _kv_init_default="${_kv_init_line#*|}"
    [[ "$_kv_init_key" == "$_kv_init_line" ]] && _kv_init_default=""

    local _normalized_key
    _normalized_key="$(_kv_normalize_key "$_kv_init_key")" || return 1
    _validated_keys+=("$_normalized_key")
    _validated_defaults+=("$_kv_init_default")
  done <<<"$schema"

  # Register schema array: _KV_SCHEMA_<store>[key]=default
  declare -Ag "_KV_SCHEMA_${store}"
  local -n _kv_schema_ref="_KV_SCHEMA_${store}"
  # Clear previous schema entries
  for _key in "${!_kv_schema_ref[@]}"; do
    unset "_kv_schema_ref[$_key]"
  done
  local i
  for i in "${!_validated_keys[@]}"; do
    _kv_schema_ref["${_validated_keys[$i]}"]="${_validated_defaults[$i]}"
  done

  # Register schema (mark store as initialized)
  _KV_SCHEMA["$store"]="$store"

  # Declare the store associative array if not already declared
  declare -Ag "_KV_${store}"

  # Initialize with default values using nameref

  local -n _kv_buf="_KV_${store}"
  local _kv_set_default
  # shellcheck disable=SC2329
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
  key="$(_kv_normalize_key "$key")" || return $?

  if [[ -n "${_KV_SCHEMA[$store]+set}" ]]; then
    local -n _kv_schema_ref="_KV_SCHEMA_${store}"
    if [[ -z "${_kv_schema_ref[$key]+set}" ]]; then
      echo "Error: kv_get: key '${key}' is not in schema for store '${store}'" >&2
      return 1
    fi
  fi

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
  key="$(_kv_normalize_key "$key")" || return $?

  if [[ -n "${_KV_SCHEMA[$store]+set}" ]]; then
    local -n _kv_schema_ref="_KV_SCHEMA_${store}"
    if [[ -z "${_kv_schema_ref[$key]+set}" ]]; then
      echo "Error: kv_set: key '${key}' is not in schema for store '${store}'" >&2
      return 1
    fi
  fi

  local -n _kv_buf="_KV_${store}"
  _kv_buf["$key"]="$value"
}

# _kv_normalize_filename - Derive stem from a basename for .kv file naming
#
# @arg $1 string Basename of a file (no directory component)
#               e.g. "kv.json"       → "kv"
#                    "session"       → "session"
#                    ".project"      → ".project"
#                    ".project.json" → ".project"
# @stdout Stem (basename without extension, dot-files preserve leading dot)
_kv_normalize_filename() {
  local base="$1"
  local stem

  # Reject empty basename first
  if [[ -z "$base" ]]; then
    printf 'Error: _kv_normalize_filename: basename must not be empty\n' >&2
    return 1
  fi

  # Normalize consecutive dots to a single dot (e.g. "a..b..c" → "a.b.c")
  # shellcheck disable=SC2001
  base="$(sed 's/\.\.*/./g' <<<"$base")"

  # Valid pattern: optional prefix of [._-], then at least one [A-Za-z],
  # then any sequence of [A-Za-z0-9_.-]
  if [[ ! "$base" =~ ^[._-]*[A-Za-z][A-Za-z0-9_.-]*$ ]]; then
    printf "Error: _kv_normalize_filename: invalid basename: '%s'\n" "$base" >&2
    return 1
  fi

  if [[ "$base" == .* ]]; then
    stem="${base%.*}"                # dot-file: strip last extension only
    [[ -z "$stem" ]] && stem="$base" # no extension (e.g. ".project"): keep as-is
  else
    stem="${base%.*}" # regular file: strip last extension only
  fi
  printf '%s' "$stem"
}

# _kv_file_path - Derive .kv file path from a given path
# @arg $1 string Path (directory/basename; basename's extension is replaced with .kv)
#               e.g. "/foo/bar/kv.json"   → "/foo/bar/kv.kv"
#                    "/foo/bar/session"   → "/foo/bar/session.kv"
#                    "/foo/bar/.project" → "/foo/bar/.project.kv"
# @stdout Resolved path with .kv extension

_kv_file_path() {
  local path="$1"
  local dir base stem

  # Normalize Windows backslashes to forward slashes
  path="${path//\\/\/}"

  # Reject paths ending with "/" (no filename component)
  if [[ "$path" == */ ]]; then
    echo "Error: _kv_file_path: path must not end with '/': '${path}'" >&2
    return 1
  fi

  # Extract basename and derive stem (validate once here)
  base="${path##*/}"
  stem="$(_kv_normalize_filename "$base")" || return 1

  # Reconstruct path: preserve dir if present, else filename only
  if [[ "$path" == */* ]]; then
    dir="${path%/*}"
    printf '%s/%s.kv' "$dir" "$stem"
  else
    printf '%s.kv' "$stem"
  fi
}

# kv_store_path - Resolve .kv file path (public API wrapping _kv_file_path)
#
# If path contains a directory component, delegates directly to _kv_file_path.
# If path is a filename only (no "/"), prepends DECKRD_LOCAL_DATA as the directory.
#
# @arg $1 string Path or filename
# @stdout Resolved .kv file path
# @return 0 on success, 1 on error
kv_store_path() {
  local path="$1"
  local stem

  # Normalize Windows backslashes to forward slashes
  path="${path//\\/\/}"

  # Reject paths ending with "/" (no filename component)
  if [[ "$path" == */ ]]; then
    echo "Error: kv_store_path: path must not end with '/': '${path}'" >&2
    return 1
  fi

  # Extract basename and derive stem (validate once here)
  local base="${path##*/}"
  stem="$(_kv_normalize_filename "$base")" || return 1

  # Reconstruct path: preserve dir if present, else prepend DECKRD_LOCAL_DATA
  if [[ "$path" == */* ]]; then
    local dir="${path%/*}"
    printf '%s/%s.kv' "$dir" "$stem"
  else
    if [[ -z "${DECKRD_LOCAL_DATA:-}" ]]; then
      echo "Error: kv_store_path: DECKRD_LOCAL_DATA is not set" >&2
      return 1
    fi
    printf '%s/%s.kv' "$DECKRD_LOCAL_DATA" "$stem"
  fi
}

# _kv_json_to_buff - Load a JSON string into a KV buffer
#
# Validates JSON keys against schema, then populates _KV_<store> from the JSON string.
# Empty-string values fall back to schema defaults (${value:-${default}}).
# Caller is responsible for ensuring the string is valid JSON.
#
# @arg $1 string Store name
# @arg $2 string JSON string (must be valid JSON)
# @return 0 on success, 1 on schema error or unknown key
_kv_json_to_buff() {
  local store="$1"
  local json="$2"

  if [[ -z "${_KV_SCHEMA[$store]+set}" ]]; then
    echo "Error: _kv_json_to_buff: schema not registered for store '${store}'" >&2
    return 1
  fi

  local -n _kv_schema_chk="_KV_SCHEMA_${store}"
  local -n _kv_buf="_KV_${store}"

  # Build schema key list as JSON array for unknown-key detection
  local schema_keys_json
  schema_keys_json=$(printf '%s\n' "${!_kv_schema_chk[@]}" |
    jq_read -Rcs '[split("\n")[] | select(. != "")]')

  # Validate keys and load values in a single jq invocation.
  # Unknown keys produce a sentinel "ERROR\t<key>" line.
  # Output: "key\tvalue" per entry (TSV via @tsv).
  local k v
  while IFS=$'\t' read -r k v; do
    if [[ "$k" == "ERROR" ]]; then
      echo "Error: _kv_json_to_buff: unknown key '${v}'" >&2
      return 1
    fi
    _kv_buf["$k"]="${v:-${_kv_schema_chk[$k]}}"
  done < <(jq_read -r --argjson schema "$schema_keys_json" '
    to_entries[] |
    if (.key as $k | $schema | index($k) | not) then ["ERROR", .key]
    else [.key, .value]
    end | @tsv
  ' <<<"$json")
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
    echo "Error: kv_load: schema not registered for store '${store}'" >&2
    return 1
  fi

  if [[ ! -f "$file" ]]; then
    # File not found: initialize with defaults
    local -n _kv_buf="_KV_${store}"
    local _kv_set_default
    # shellcheck disable=SC2329
    _kv_set_default() { _kv_buf["$1"]="${2}"; }
    _kv_schema_iter "$store" _kv_set_default
    unset -f _kv_set_default
    return 0
  fi

  # Validate JSON before loading
  if ! "${jqexe:-jq}" empty "$file" 2>/dev/null; then
    echo "Error: kv_load: invalid JSON file '${file}'" >&2
    return 1
  fi

  local json
  json="$(<"$file")"
  _kv_json_to_buff "$store" "$json"
}

# _kv_buff_to_json - Serialize an associative array to compact JSON
#
# @arg $1 string Store name (nameref target "_KV_<store>")
# @stdout Compact JSON object (no trailing newline issues, CRLF-safe)
_kv_buff_to_json() {
  local store="$1"
  local -n _kv_buf="_KV_${store}"

  # Build "key\tvalue" TSV lines from the buffer and convert to compact JSON
  # in a single jq invocation.
  local json='{}'
  local key
  for key in "${!_kv_buf[@]}"; do
    json=$(printf '%s' "$json" | jq_read --arg k "$key" --arg v "${_kv_buf[$key]}" '. + {($k): $v}')
  done
  printf '%s' "$json" | jq_read -c .
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
    echo "Error: kv_save: schema not registered for store '${store}'" >&2
    return 1
  fi

  mkdir -p "$(dirname "$file")"
  _kv_buff_to_json "$store" >"$file"
}

# kv_all - Output all store entries as "key=value" lines
#
# @arg $1 string Store name
# @stdout All entries in "key=value" format
kv_all() {
  local store="$1"

  local -n _kv_buf="_KV_${store}"
  local key
  for key in "${!_kv_buf[@]}"; do
    echo "${key}=${_kv_buf[$key]}"
  done
}
