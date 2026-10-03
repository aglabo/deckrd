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

# normalize_dir_path - Normalize a directory path to `/` separators
#
# Replaces every `\` with `/`, collapses repeated `/` into one (except a leading
# UNC `//`), then strips a single trailing `/` (e.g. `C:\Users\x\` -> `C:/Users/x`,
# `/a//b/` -> `/a/b`).
# The path is not resolved: it need not exist, and `.`/`..` are kept as-is.
#
# @note The root `/` is kept as `/`. A drive root such as `C:\` or `C:/` becomes
#       `C:`; callers append `/<rel>`, so `C:` + `/x` gives `C:/x`.
# @note A leading `//` (UNC, e.g. `\\server\share` or `//server/share`) is kept:
#       collapsing it would name a different local path under Git Bash/MSYS.
#       Three or more leading `/` collapse to one (POSIX), and a bare `//` gives `/`.
# @note Implemented as one sed call (one expression per rule, applied in order);
#       the trailing-`/` rule needs a character before the `/`, which keeps the root.
#       The path is treated as a single line: it must not contain a newline.
# @arg $1 Directory path, optional (a missing argument is treated as empty)
# @stdout Normalized path followed by a newline (an empty line for empty input)
# @return 0 always
normalize_dir_path() {
  printf '%s\n' "${1:-}" | sed -E 's#\\#/#g; s#^/{3,}#/#; s#([^/])/+#\1/#g; s#(.)/$#\1#'
}

# strip_suffix - Remove one trailing occurrence of a literal suffix from a string
#
# Prints the string with the suffix removed once from its end
# (e.g. `rules/.gitignore.org` `.org` -> `rules/.gitignore`, `a.org.org` -> `a.org`).
# A string that does not end with the suffix is printed unchanged.
#
# @note Only a suffix of the whole string is removed, so a `.org` inside a
#       directory name is kept (`rules.org/a.md` is unchanged).
# @note The suffix is quoted in the expansion, so it is literal: glob characters
#       such as `*` or `?` are not treated as patterns.
# @note Pure parameter expansion; no external command is run.
# @arg $1 String (typically a relative path)
# @arg $2 Suffix to remove (an empty suffix removes nothing)
# @stdout The resulting string followed by a newline (an empty line for empty input)
# @return 0 always
strip_suffix() {
  printf '%s\n' "${1%"$2"}"
}
