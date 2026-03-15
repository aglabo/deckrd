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

# Global associative array for session data
declare -Ag SESSION

# _session_extract_json_fallback - Extract JSON value using grep/sed fallback
#
# @arg $1 string JSON file path
# @arg $2 string JSON key name
# @stdout Extracted value (empty if not found)
_session_extract_json_fallback() {
  local file="$1"
  local key="$2"

  grep -o "\"${key}\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" "$file" 2>/dev/null |
    sed -E 's/[^:]*:[[:space:]]*"([^"]*)".*/\1/' || echo ""
}

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

  if command -v jq >/dev/null 2>&1; then
    for key in "${keys[@]}"; do
      value=$(jq -r ".${key} // empty" "$file" 2>/dev/null || true)
      SESSION["$key"]="$value"
    done
  else
    echo "Warning: session.json loaded via fallback; values may be incomplete" >&2
    for key in "${keys[@]}"; do
      value=$(_session_extract_json_fallback "$file" "$key")
      SESSION["$key"]="$value"
    done
  fi

  return 0
}

# session_save - Save SESSION array to JSON file
#
# @arg $1 string JSON file path
# @return 0 on success
session_save() {
  local file="$1"

  mkdir -p "$(dirname "$file")"

  if command -v jq >/dev/null 2>&1; then
    local json_obj="{}"
    local key value
    for key in "${!SESSION[@]}"; do
      value="${SESSION[$key]}"
      json_obj=$(echo "$json_obj" | jq --arg k "$key" --arg v "$value" '. + {($k): $v}')
    done
    echo "$json_obj" >"$file"
  else
    {
      echo "{"
      local first=1
      local key value
      for key in "${!SESSION[@]}"; do
        value="${SESSION[$key]}"
        if [[ $first -eq 0 ]]; then
          printf ',\n'
        fi
        printf '  "%s": "%s"' "$key" "$value"
        first=0
      done
      printf '\n}\n'
    } >"$file"
  fi

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
