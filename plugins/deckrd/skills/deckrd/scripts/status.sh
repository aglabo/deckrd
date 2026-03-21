#!/usr/bin/env bash
# src: ./skills/deckrd/scripts/status.sh
# @(#) : deckrd ステータス表示スクリプト
#
# Copyright (c) 2025 atsushifx <https://github.com/atsushifx>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT
#
# @file status.sh
# @brief Display DECKRD session status
# @description
#   Displays the current status of the active module and workflow progress.
#   Reads from .local/deckrd/session.json
#
# @example
#   status.sh
#
# @exitcode 0 Success
# @exitcode 1 Error (no session, no jq, etc.)
#
# @author atsushifx
# @version 0.1.0
# @license MIT

set -eo pipefail

# Load bootstrap (defines SYMBOL, PROJECT_ROOT, DECKRD_LOCAL_DATA, DECKRD_LIB_DIR, etc.)
_BOOTSTRAP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
. "${_BOOTSTRAP_DIR}/libs/bootstrap.sh"
unset _BOOTSTRAP_DIR

# ============================================================================
# Functions
# ============================================================================

# Initialize configuration variables (mock-friendly)
init_vars() {
  SESSION_FILE="${SESSION_FILE:-${DECKRD_LOCAL_DATA}/session.json}"
  DECKRD_DOCS="${DECKRD_DOCS:-${PROJECT_ROOT}/docs/.deckrd}"
  WORKFLOW_STEPS=(module req spec impl tasks)
}

# Check if session file exists
check_session() {
  if [[ ! -f "$SESSION_FILE" ]]; then
    echo "Error: No session file found."
    echo "  Expected: ${SESSION_FILE}"
    echo ""
    echo "Run 'deckrd init <project> <project-type>' and 'deckrd module <namespace>/<module>' to initialize."
    return 1
  fi
}

# Display workflow progress
display_progress() {
  local completed="$1"
  local current_step="$2"

  echo "Workflow Progress:"
  for step in "${WORKFLOW_STEPS[@]}"; do
    if echo "$completed" | grep -qE "(^|, )${step}(,|$)"; then
      echo "  [✓] $step"
    elif [[ "$step" == "$current_step" ]]; then
      echo "  [•] $step"
    else
      echo "  [ ] $step"
    fi
  done
}

# Main function
main() {
  init_vars
  check_session || exit 1

  # Extract fields from session
  local active lang ai_model created updated current_step completed

  active=$(jq -r '.active // empty' "$SESSION_FILE")
  if [[ -z "$active" ]]; then
    echo "Error: No active module set in session."
    echo ""
    echo "Run 'deckrd module <namespace>/<module>' to set active module."
    exit 1
  fi

  lang=$(jq -r '.lang // "system"' "$SESSION_FILE")
  ai_model=$(jq -r '.ai_model // "unknown"' "$SESSION_FILE")
  created=$(jq -r '.created_at // "unknown"' "$SESSION_FILE")
  updated=$(jq -r '.updated_at // "unknown"' "$SESSION_FILE")
  current_step=$(jq -r ".modules[\"$active\"].current_step // empty" "$SESSION_FILE")
  completed=$(jq -r ".modules[\"$active\"].completed | join(\", \") // \"none\"" "$SESSION_FILE")

  # Display status
  echo "DECKRD Status"
  echo "============="
  echo ""
  echo "Active Module: $active"
  echo "Current Step:  $current_step"
  echo "Completed:     $completed"
  echo ""
  echo "Module Path:   ${DECKRD_DOCS}/$active"
  echo ""
  echo "Configuration:"
  echo "  Language:    $lang"
  echo "  AI Model:    $ai_model"
  echo ""
  echo "Session Info:"
  echo "  Created:     $created"
  echo "  Updated:     $updated"
  echo ""

  display_progress "$completed" "$current_step"
}

# ============================================================================
# Entry Point
# ============================================================================

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then main "$@"; fi
