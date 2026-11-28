#!/usr/bin/env bash
# src: ./skills/bdd-coder/skills/bdd-coder/scripts/check-ids/plugins/tsjs-id-checker.plugin.sh
# @(#) : ts and js plugin of the test case ID checker
#
# Copyright (c) 2026- atsushifx <https://github.com/atsushifx>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT
# SC2154: the checker declares the tables, and declaration.lib.sh sets _QUOTE
# shellcheck shell=bash disable=SC2034,SC2154

# shellcheck source=../libs/report.lib.sh disable=SC1091
. "${BASH_SOURCE[0]%/*}/../libs/report.lib.sh" || return 1
# shellcheck source=../libs/test-id.lib.sh disable=SC1091
. "${BASH_SOURCE[0]%/*}/../libs/test-id.lib.sh" || return 1
# shellcheck source=../libs/declaration.lib.sh disable=SC1091
. "${BASH_SOURCE[0]%/*}/../libs/declaration.lib.sh" || return 1

declare -g _TSJS_GROUP_PATTERN="^[[:blank:]]*(describe)[(]${_QUOTE}(.*)"
declare -g _TSJS_CASE_PATTERN="^[[:blank:]]*(it|test)[(]${_QUOTE}(.*)"
declare -g _TSJS_CASE_START_PATTERN='^[[:blank:]]*(it|test)[(]'

#
# @description Count the declaration of a line, if it is one, and check its ID.
#   Only spaces and tabs may precede a keyword, and "(" stands between a keyword
#   and the quote of its title. Without a title literal, a case keyword declares a
#   case only before "(".
#   When a line ends with "it(" or "test(" and the next line starts, after spaces
#   and tabs, with a string literal, that literal is the title, and errors point at
#   the line of the keyword. A wrapped describe( is not read.
#   Every line, a declaration or not, first goes to track_loop_block with the line
#   comment marker '//', so call it with each line of a file in order. In a for
#   block, a case ID of ts and js needs a variable branch: the ID must be written
#   with a trailing '-', as `T-A-B-01-${name}`. Which lines make a for block, and
#   the known limits, are those of track_loop_block
# @arg $1 string The file and line number of an error
# @arg $2 string The line
# @arg $3 string The next line (optional)
# @set _COUNTS The counts of group IDs, case IDs and errors (global)
# @set _GROUP_ID, _DECLARED The ID, from check_declared_id (global)
# @set _IN_LOOP, _LOOP_PENDING, _LOOP_LINE The loop state and the line as judged,
#   from track_loop_block (global)
# @stderr The errors of count_line_declaration, including a case ID without a
#   variable branch in a loop
# @exitcode 0 always
#
check_tsjs_line() {
  track_loop_block "$2" '//'
  count_line_declaration "$1" "$2" "$_TSJS_GROUP_PATTERN" "$_TSJS_CASE_PATTERN" "$_TSJS_CASE_START_PATTERN" "${3-}"
}

LANG_FILES[ts]='*.spec.ts *.spec.tsx'
LANG_HANDLER[ts]=check_tsjs_line
LANG_FILES[js]='*.spec.js *.spec.jsx *.spec.mjs *.spec.cjs'
LANG_HANDLER[js]=check_tsjs_line
