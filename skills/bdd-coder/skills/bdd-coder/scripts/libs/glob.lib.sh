#!/usr/bin/env bash
# skills/deckrd/skills/deckrd/scripts/libs/glob.lib.sh - Glob matching and file listing
#
# Copyright (c) 2026- atsushifx <https://github.com/atsushifx>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT
#
# @version 0.1.0
# USAGE: source this file, do NOT execute directly.
#   . "$(dirname "${BASH_SOURCE[0]}")/glob.lib.sh"
#
# "glob" means two different things here:
#   file_list_by_globs                 takes file name patterns, handed to `rg -g` or
#                                      `find -name` (e.g. '*.spec.sh')
#   glob_to_regex, path_matches_glob   match a whole relative path: `**` spans
#                                      directory separators, a single `*` does not

if [[ -n ${_LIB_GLOB_LOADED:-}   ]]; then
  return 0
fi
readonly _LIB_GLOB_LOADED=1

# Compiled globs, keyed by the glob (-g: global even when sourced inside a function)
declare -gA _GLOB_REGEX_CACHE=()

#
# @description Convert a glob into a fully anchored ERE.
#   `**` spans directory separators, a single `*` does not.
# @arg $1 string Glob pattern
# @stdout Anchored ERE
# @exitcode 0 always
#
glob_to_regex() {
  local glob="$1"
  glob="${glob//./[.]}"
  glob="${glob//\*\*/$'\001'}"
  glob="${glob//\*/[^\/]*}"
  glob="${glob//$'\001'/.*}"
  printf '^%s$\n' "$glob"
}

#
# @description Test whether a repository-relative path matches a glob.
#   Callers test every file against every glob, so this runs hundreds of times over a
#   handful of distinct globs; without the cache each call forks a subshell for the
#   command substitution. The conversion depends on nothing but the glob, so a cache
#   entry never goes stale. A caller drops the cache by assigning ().
# @arg $1 string Repository-relative path
# @arg $2 string Glob pattern
# @exitcode 0 when the path matches, 1 otherwise
#
path_matches_glob() {
  local path="$1" glob="$2" regex
  if [[ -n ${_GLOB_REGEX_CACHE[$glob]+x} ]]; then
    regex="${_GLOB_REGEX_CACHE[$glob]}"
  else
    regex="$(glob_to_regex "$glob")"
    _GLOB_REGEX_CACHE[$glob]="$regex"
  fi
  [[ $path =~ $regex   ]]
}

# file_list_by_globs - List the files under a root whose name matches any glob, unsorted
#
# A caller that depends on the order pipes the output to `sort`. Without a glob
# nothing is listed. The caller's shell options are not changed.
#
# A failed listing is reported as a failure, so that it is never read as an empty
# tree; none of the paths collected before the failure are printed. The listing is
# captured before it is converted, so the result does not depend on the caller's
# `pipefail` or `set -e`.
#
# rg skips hidden directories and the directories that ignore files name; a file that
# matches a glob is listed even when it is hidden or ignored. node_modules is excluded
# on both the rg and the find path, without relying on .gitignore; rg gives precedence
# to the later glob, so the exclusion follows the positive ones. rg is optional for
# plugin users, and the find fallback prunes only hidden directories and node_modules.
# Paths come out relative to the root with forward slashes either way.
#
# @note The globs are never expanded against the current directory; the caller only
#       has to quote them.
# @arg $1 Root directory to scan
# @arg ... File name globs (e.g. '*.spec.sh')
# @stdout One root-relative path per line with `/` separators; nothing, not even an
#         empty line, when none match or the listing fails
# @stderr The messages of cd, rg or find, naming the cause of a failure
# @return 0 Listed, including when no file matched (rg exit 1) or no glob was given
# @return non-zero The root cannot be entered, rg exited 2 or higher, or find exited
#         non-zero (an unreadable directory included)
file_list_by_globs() {
  local root="$1"
  shift
  [[ $# -gt 0 ]] || return 0
  local glob
  local -a rg_args=() find_args=()
  for glob in "$@"; do
    rg_args+=(-g "$glob")
    find_args+=(-o -name "$glob")
  done
  # must follow the positive globs
  rg_args+=(-g '!node_modules')
  local listing
  listing="$(
    cd "$root" || exit
    if command -v rg > /dev/null 2>&1; then
      # exit 1: no match
      rg --files "${rg_args[@]}" || {
        status=$?
        [[ $status -eq 1 ]] || exit "$status"
      }
    else
      # :1 drops the leading -o
      find . \( -type d \( -name 'node_modules' -o -name '.?*' \) -prune \) -o -type f \( "${find_args[@]:1}" \) -print
    fi
  )" || return
  # avoid printing an empty line
  [[ -n $listing ]] || return 0
  sed 's|\\|/|g; s|^\./||' <<< "$listing"
}
