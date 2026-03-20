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
. "${DECKRD_LIB_DIR}/kv-store.sh"

# Config schema
readonly _CONFIG_SCHEMA="
ai_model|sonnet
lang|system
doc_type|
prompt_mode|0
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

# config_init - Initialize CONFIG with defaults and optionally load from session file
#
# @arg $1 string Session file path (optional)
# @return 0 always
config_init() {
  local session_file="${1:-}"

  # Re-initialize config store with defaults
  kv_init "config" "$_CONFIG_SCHEMA"

  # Load from session file if provided
  if [[ -n "$session_file" ]]; then
    local _config_session_schema="
active|
ai_model|
lang|
"
    kv_init "_config_session" "$_config_session_schema"
    kv_load "_config_session" "${session_file%.*}" || true

    local ai_model
    ai_model=$(kv_get "_config_session" "ai_model")
    if [[ -n "$ai_model" ]]; then
      kv_set "config" "ai_model" "$ai_model"
    fi

    local lang
    lang=$(kv_get "_config_session" "lang")
    if [[ -n "$lang" ]]; then
      kv_set "config" "lang" "$lang"
    fi

    local active
    active=$(kv_get "_config_session" "active")
    if [[ -n "$active" ]]; then
      local deckrd_docs="${DECKRD_DOCS:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)/docs/.deckrd}"
      kv_set "config" "deckrd_base" "${deckrd_docs}/${active}"
    fi
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
