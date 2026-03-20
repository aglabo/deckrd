#!/usr/bin/env bash
# plugins/deckrd/skills/deckrd/scripts/libs/validate-env.sh - Environment validation
#
# Copyright (c) 2026- atsushifx <https://github.com/atsushifx>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT
#
# @version 0.1.0
# USAGE: source this file, do NOT execute directly.
#   . "$(dirname "${BASH_SOURCE[0]}")/libs/validate-env.sh"

# Guard: prevent re-sourcing
if [[ -n "${_VALIDATE_ENV_LOADED:-}" ]]; then
  return 0
fi
readonly _VALIDATE_ENV_LOADED=1

# validate_env - Validate that required environment tools are available
#
# @stdout Error message if validation fails
# @return 0 if all requirements are met, 1 if jq is not installed
#
# Mock support: define validate_env before sourcing this file to override.
if ! declare -f validate_env >/dev/null 2>&1; then
  validate_env() {
    if ! command -v jq >/dev/null 2>&1; then
      echo "Error: jq is required but not installed."
      return 1
    fi
    return 0
  }
fi
