#!/usr/bin/env bash
# plugins/deckrd/skills/deckrd/scripts/libs/config.sh - Configuration management
#
# Copyright (c) 2026- atsushifx <https://github.com/atsushifx>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT
#
# USAGE: source this file, do NOT execute directly.
#   . "$(dirname "${BASH_SOURCE[0]}")/libs/config.sh"

# Guard: prevent re-sourcing
if [[ -n "${_CONFIG_LOADED:-}" ]]; then
  return 0
fi
readonly _CONFIG_LOADED=1

# Global associative array for configuration data
declare -Ag CONFIG

# config_init - Initialize CONFIG with defaults and optionally load from session file
#
# @arg $1 string Session file path (optional)
# @return 0 always
config_init() {
  local session_file="${1:-}"

  # Set default values
  CONFIG[ai_model]="sonnet"
  CONFIG[lang]="system"
  CONFIG[doc_type]=""
  CONFIG[prompt_mode]="0"
  CONFIG[review_phase]=""
  CONFIG[output_file]=""
  CONFIG[deckrd_base]=""
  CONFIG[context_input]=""
  CONFIG[prompt_path]=""
  CONFIG[template_path]=""

  # Load from session file if provided and session_load is available
  if [[ -n "$session_file" ]] && declare -f session_load >/dev/null 2>&1; then
    session_load "$session_file" || return 0

    local ai_model
    ai_model=$(session_get "ai_model")
    if [[ -n "$ai_model" ]]; then
      CONFIG[ai_model]="$ai_model"
    fi

    local lang
    lang=$(session_get "lang")
    if [[ -n "$lang" ]]; then
      CONFIG[lang]="$lang"
    fi

    local active
    active=$(session_get "active")
    if [[ -n "$active" ]]; then
      local deckrd_docs="${DECKRD_DOCS:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)/docs/.deckrd}"
      CONFIG[deckrd_base]="${deckrd_docs}/${active}"
    fi
  fi

  return 0
}

# config_get - Get value from CONFIG array
#
# @arg $1 string Key name
# @stdout Value (empty if key not found)
config_get() {
  local key="$1"
  echo "${CONFIG[$key]:-}"
}

# config_set - Set value in CONFIG array
#
# @arg $1 string Key name
# @arg $2 string Value
config_set() {
  local key="$1"
  local value="${2:-}"
  CONFIG["$key"]="$value"
}

# config_all - Output all CONFIG entries as key=value lines
#
# @stdout All entries in "key=value" format
config_all() {
  local key
  for key in "${!CONFIG[@]}"; do
    echo "${key}=${CONFIG[$key]}"
  done
}
