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
#   Reads from docs/.deckrd/.session.json
#
# @example
#   status.sh
#
# @exitcode 0 Success
# @exitcode 1 Error (no session, no jq, etc.)
#
# @author atsushifx
# @version 1.0.0
# @license MIT

set -eo pipefail

# ============================================================================
# Configuration
# ============================================================================

readonly SESSION_FILE="docs/.deckrd/.session.json"
readonly WORKFLOW_STEPS=(init req spec impl tasks)

# ============================================================================
# Functions
# ============================================================================

# Check if session file exists
check_session() {
  if [[ ! -f "$SESSION_FILE" ]]; then
    echo "Error: No session file found."
    echo "  Expected: $SESSION_FILE"
    echo ""
    echo "Run 'deckrd init <namespace>/<module>' to initialize."
    exit 1
  fi
}

# Check if jq is available
check_jq() {
  if ! command -v jq >/dev/null 2>&1; then
    echo "Error: jq is not installed."
    exit 1
  fi
}

# Display workflow progress
display_progress() {
  local completed="$1"
  local current_step="$2"

  echo "Workflow Progress:"
  for step in "${WORKFLOW_STEPS[@]}"; do
    if echo "$completed" | grep -q "$step"; then
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
  check_session
  check_jq

  # Extract fields from session
  local active lang ai_model created updated current_step completed

  active=$(jq -r '.active // empty' "$SESSION_FILE")
  if [[ -z "$active" ]]; then
    echo "Error: No active module set in session."
    echo ""
    echo "Run 'deckrd init <namespace>/<module>' to set active module."
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
  echo "Module Path:   docs/.deckrd/$active"
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

main "$@"
