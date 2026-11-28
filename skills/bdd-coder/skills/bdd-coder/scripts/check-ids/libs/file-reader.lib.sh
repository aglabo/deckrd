#!/usr/bin/env bash
# skills/bdd-coder/skills/bdd-coder/scripts/check-ids/libs/file-reader.lib.sh - Line-by-line file reading
#
# Copyright (c) 2026- atsushifx <https://github.com/atsushifx>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT
#
# @version 0.1.0
# USAGE: source this file, do NOT execute directly.
#   . "$(dirname "${BASH_SOURCE[0]}")/file-reader.lib.sh"

if [[ -n ${_LIB_FILE_READER_LOADED:-}   ]]; then
  return 0
fi
readonly _LIB_FILE_READER_LOADED=1

# UTF-8 byte order mark
declare -g _BOM=$'\xEF\xBB\xBF'

#
# @description Pass each line of a file to a handler, in order, with the line that
#   follows it. The next line of the last line is an empty string. A byte order mark at
#   the start of the file is ignored. A group ID does not reach the next file.
#   Source report.lib.sh and test-id.lib.sh before the call, for report_error and
#   group_id_reset.
#   The handler must return 0, otherwise the checker stops with no message (set -e)
# @arg $1 string The root directory
# @arg $2 string The file, relative to the root
# @arg $3 string The handler, called as:
#   handler <file>:<line number> <line> [args...] <next line>
# @arg $@ string The extra arguments of the handler, from the fourth argument on.
#   The next line is always passed after them, as the last argument
# @set _GROUP_ID Empty before the first line, unless the file cannot be read (global)
# @set _COUNTS The count of errors, when the file cannot be read (global)
# @stderr That the file cannot be read
# @exitcode 0 The file cannot be read, and the handler is not called
# @exitcode 0 The file is empty, or every handler call returns 0
# @exitcode * A handler call fails: set -e exits there. Without it, the last call's status
#
read_file_lines() {
  local line number=0
  local -a lines
  if ! mapfile -t lines < "${1}/${2}"; then
    report_error "${2}: cannot read"
    return 0
  fi
  group_id_reset
  # bash 4.3 treats an empty array as unbound
  for line in ${lines[@]+"${lines[@]}"}; do
    number=$((number + 1))
    [[ $number -ne 1 ]] || line="${line#"$_BOM"}"
    # lines[number] is the next line, unset after the last one
    "$3" "${2}:${number}" "$line" "${@:4}" "${lines[number]-}"
  done
}
