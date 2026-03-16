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

# shellcheck disable=SC1091
. "$(dirname "${BASH_SOURCE[0]}")/validate-env.sh"
_validate_env_errmsg=$(validate_env) || { echo "$_validate_env_errmsg" >&2; exit 1; }
unset _validate_env_errmsg

# Global associative array for session data
declare -Ag SESSION

# session_load - Load session data from JSON file into SESSION array
#
# @arg $1 string JSON file path
# @return 0 on success, 1 if file not found
session_load() {
  local file="$1"

  if [[ ! -f "$file" ]]; then
    return 1
  fi

  local keys=("active" "ai_model" "lang")
  local key value

  for key in "${keys[@]}"; do
    value=$(jq -r ".${key} // empty" "$file" 2>/dev/null || true)
    SESSION["$key"]="$value"
  done

  return 0
}

# session_save - Save SESSION array to JSON file
#
# @arg $1 string JSON file path
# @return 0 on success
session_save() {
  local file="$1"

  mkdir -p "$(dirname "$file")"

  local json_obj="{}"
  local key value
  for key in "${!SESSION[@]}"; do
    value="${SESSION[$key]}"
    json_obj=$(echo "$json_obj" | jq --arg k "$key" --arg v "$value" '. + {($k): $v}')
  done
  echo "$json_obj" >"$file"

  return 0
}

# session_get - Get value from SESSION array
#
# @arg $1 string Key name
# @stdout Value (empty if key not found)
session_get() {
  local key="$1"
  echo "${SESSION[$key]:-}"
}

# session_set - Set value in SESSION array
#
# @arg $1 string Key name
# @arg $2 string Value
session_set() {
  local key="$1"
  local value="${2:-}"
  SESSION["$key"]="$value"
}
