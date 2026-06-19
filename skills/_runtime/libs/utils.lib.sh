#!/usr/bin/env bash
# skills/_runtime/libs/utils.lib.sh - Shared utility functions for deckrd runtime
#
# Copyright (c) 2026- atsushifx <https://github.com/atsushifx>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT
#
# @version 0.1.0
# USAGE: source this file, do NOT execute directly.
#   . "$(dirname "${BASH_SOURCE[0]}")/utils.lib.sh"

# Guard: prevent re-sourcing
if [[ -n "${_UTILS_LOADED:-}" ]]; then
  return 0
fi
readonly _UTILS_LOADED=1

# jq_read - Run jq and normalize output line endings to LF
#
# Wrapper around jq that strips CR characters from output, ensuring
# consistent LF-only line endings on all platforms (including Windows).
#
# @arg ... All arguments are passed through to jq
# @stdin  Passed through to jq if no file argument is given
# @stdout jq output with CRLF normalized to LF
# @return jq exit code
jq_read() {
  "${jqexe:-jq}" "$@" | tr -d '\r'
}
