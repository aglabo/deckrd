#!/usr/bin/env bash
# skills/deckrd/skills/deckrd/scripts/libs/utils.lib.sh - Shared utility functions for deckrd runtime
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
# @note The pipeline runs in a subshell with pipefail enabled, so a jq failure
#       is reported regardless of the caller's shell options, and the caller's
#       own pipefail setting is left untouched.
# @note tr -d '\r' removes every CR byte, including a legitimate CR inside a
#       JSON string value. This project only reads paths, names and timestamps,
#       so no such value is expected, but the stripping is unconditional.
# @arg ... All arguments are passed through to jq
# @stdin  Passed through to jq if no file argument is given
# @stdout jq output with CRLF normalized to LF
# @stderr Passed through from jq. Callers that want it silenced write
#         `jq_read ... 2>/dev/null`
# @return jq exit code
jq_read() {
  (
    set -o pipefail
    "${jqexe:-jq}" "$@" | tr -d '\r'
  )
}
