#!/usr/bin/env bash
# plugins/deckrd/skills/deckrd/scripts/libs/config.sh - Configuration management
#
# Copyright (c) 2026- atsushifx <https://github.com/atsushifx>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT
#
# @version 0.1.0
# USAGE: source this file, do NOT execute directly.
#   . "$(dirname "${BASH_SOURCE[0]}")/libs/config.sh"

# Guard: prevent re-sourcing
if [[ -n "${_CONFIG_LOADED:-}" ]]; then
  return 0
fi
readonly _CONFIG_LOADED=1

# Load kv-store as the backing implementation
# shellcheck disable=SC1091
. "${DECKRD_LIB_DIR}/kv-store.lib.sh"

# Load utils for jq_read (session.json is read directly, not through kv-store)
# shellcheck source=skills/deckrd/skills/deckrd/scripts/libs/utils.lib.sh
# shellcheck disable=SC1091
. "${DECKRD_LIB_DIR}/utils.lib.sh"

# Config schema
readonly _CONFIG_SCHEMA="
ai_model|sonnet
lang|system
doc_type|
prompt_mode|0
verbose|0
review_phase|
output_file|
deckrd_base|
context_input|
prompt_path|
template_path|
"

# Initialize the config store
kv_init "config" "$_CONFIG_SCHEMA"

# CONFIG - compatibility shim: exposes _KV_config as CONFIG
# This allows existing code that accesses CONFIG[key] directly to work.
# shellcheck disable=SC2034
declare -n CONFIG="_KV_config"

# _config_copy_session_value - Copy one session.json field into CONFIG when present
#
# A missing key and a JSON null both yield an empty string ("// empty"), in which
# case the schema default already held by CONFIG is left untouched.
#
# @arg $1 string Session file path (must exist and hold a JSON object)
# @arg $2 string Key name, spelled identically in session.json and in the config schema
# @return 0 when the value was copied or there was nothing to copy, 1 when the read
#         failed or the key is not in the config schema
_config_copy_session_value() {
  local session_file="$1"
  local key="$2"

  # A read failure is propagated instead of being silently treated as "no value".
  local value
  value=$(jq_read -r ".${key} // empty" "$session_file") || return 1
  if [[ -n "$value" ]]; then
    kv_set "config" "$key" "$value"
  fi
}

# config_init - Initialize CONFIG with defaults and optionally load from session file
#
# Reads the session file directly with jq. It is NOT a kv-store file: a real
# session.json carries keys outside the config schema (modules, created_at,
# updated_at) and a nested modules object, neither of which kv-store can load.
#
# Four input states are distinguished. A missing interpreter and an unreadable file
# are reported separately: they look alike on stdout but call for different fixes.
#   - path omitted, or the file does not exist yet (first run):
#       keep the schema defaults, write nothing to stderr, return 0
#   - the file exists but neither jq nor jaq is callable:
#       report the missing interpreter by the name that was looked up, leaving the
#       session file unaccused, and return 1
#   - the file exists but no JSON object can be read out of it (empty file,
#     truncated JSON, a top-level array or scalar):
#       report "cannot read ... as a JSON object" on stderr and return 1
#   - the file holds a JSON object:
#       reflect ai_model / lang / active onto CONFIG and return 0
#
# @arg $1 string Session file path (optional; a missing file is not an error)
# @stderr Error message naming either the missing interpreter or the unreadable file
# @return 0 on defaults-only or successful load, 1 when the interpreter is missing or
#         no JSON object can be read
config_init() {
  local session_file="${1:-}"

  # Re-initialize config store with defaults
  kv_init "config" "$_CONFIG_SCHEMA"

  # No session file to read yet (argument omitted, or first run before the file
  # is created): keep the schema defaults and stay silent.
  if [[ -z "$session_file" || ! -f "$session_file" ]]; then
    return 0
  fi

  # A missing interpreter also produces no object line on stdout, so it has to be
  # ruled out before the shape guard below; otherwise a perfectly good session file
  # is blamed for an absent tool. Absence is read from command -v, not from jq's
  # exit code, which varies by version (see the shape guard's note).
  local jq_cmd="${jqexe:-jq}"
  if ! command -v "$jq_cmd" >/dev/null 2>&1; then
    echo "Error: config_init: '${jq_cmd}' is not installed, so '${session_file}' cannot be read. Call validate_env before config_init, or install jq or jaq." >&2
    return 1
  fi

  # Reject a file that does not hold a JSON object instead of falling back to
  # defaults. The reported type is compared as text because jq's exit code for an
  # empty file depends on its version (1.6 reports success, 1.8 reports failure),
  # while "no object line on stdout" is uniform across versions and also covers
  # a parse error. A missing interpreter is already ruled out above.
  if [[ "$(jq_read -r 'type' "$session_file" 2>/dev/null)" != "object" ]]; then
    echo "Error: config_init: cannot read '${session_file}' as a JSON object" >&2
    return 1
  fi

  # Reflect the session values onto CONFIG. Keys whose name matches the config
  # schema are copied as-is; active is mapped to the derived deckrd_base.
  _config_copy_session_value "$session_file" "ai_model" || return 1
  _config_copy_session_value "$session_file" "lang" || return 1

  # "// empty" maps a JSON null (and a missing key) to an empty string, so a
  # session without an active module leaves deckrd_base at its default.
  local active
  active=$(jq_read -r '.active // empty' "$session_file") || return 1
  if [[ -n "$active" ]]; then
    # DECKRD_DOCS is a backward-compatible override; bootstrap exports DECKRD_DOCS_DIR.
    local deckrd_docs="${DECKRD_DOCS:-${DECKRD_DOCS_DIR:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)/docs/.deckrd}}"
    kv_set "config" "deckrd_base" "${deckrd_docs}/${active}"
  fi

  return 0
}

# config_get - Get value from CONFIG
#
# @arg $1 string Key name
# @stdout Value (empty if key not found)
config_get() {
  local key="$1"
  kv_get "config" "$key"
}

# config_set - Set value in CONFIG
#
# @arg $1 string Key name
# @arg $2 string Value
# @note config_set updates the in-memory CONFIG store only.
#       Changes are NOT automatically written back to session.json.
#       Call session_save explicitly after config_set if persistence is needed.
config_set() {
  local key="$1"
  local value="${2:-}"
  kv_set "config" "$key" "$value"
}

# config_all - Output all CONFIG entries as key=value lines
#
# @stdout All entries in "key=value" format
config_all() {
  kv_all "config"
}
