#!/usr/bin/env bash
# skills/deckrd/skills/deckrd/scripts/libs/validate-env.lib.sh - Environment validation
#
# Copyright (c) 2026- atsushifx <https://github.com/atsushifx>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT
#
# @version 0.1.0
# USAGE: source this file, do NOT execute directly.
#   . "$(dirname "${BASH_SOURCE[0]}")/libs/validate-env.lib.sh"

if [[ -n "${_VALIDATE_ENV_LOADED:-}" ]]; then
  return 0
fi
readonly _VALIDATE_ENV_LOADED=1

# validate_env - Validate that required environment tools are available
#
# @note Exports jqexe into the caller's shell: "jq" if available, otherwise "jaq".
#       jqexe is overwritten unconditionally, even if it was set before the call.
#       Call it as `validate_env || exit 1`; a command substitution such as
#       `$(validate_env)` runs it in a subshell and discards the export.
# @stderr Error message if validation fails
# @return 0 if all requirements are met, 1 if neither jq nor jaq is installed
#
# Mock support: define validate_env before sourcing this file to override.
if ! declare -f validate_env >/dev/null 2>&1; then
  validate_env() {
    if command -v jq >/dev/null 2>&1; then
      export jqexe="jq"
    elif command -v jaq >/dev/null 2>&1; then
      export jqexe="jaq"
    else
      echo "Error: jq or jaq is required but not installed." >&2
      return 1
    fi
    return 0
  }
fi
