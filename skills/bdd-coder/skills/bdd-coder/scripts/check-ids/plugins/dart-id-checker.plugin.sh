#!/usr/bin/env bash
# src: ./skills/bdd-coder/skills/bdd-coder/scripts/check-ids/plugins/dart-id-checker.plugin.sh
# @(#) : dart plugin of the test case ID checker
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

declare -g _DART_GROUP_PATTERN="^[[:blank:]]*group[(]${_QUOTE}(.*)"
declare -g _DART_CASE_PATTERN="^[[:blank:]]*(test|testWidgets)[(]${_QUOTE}(.*)"
declare -g _DART_CASE_START_PATTERN='^[[:blank:]]*(test|testWidgets)[(]'

#
# @description Count the declaration of a line, if it is one, and check its ID.
#   Only spaces and tabs may precede a keyword, and '(' follows it at once. The
#   quote of a title follows the '(' at once. Without a title literal there, a
#   test or testWidgets call declares a case with an empty title, unless it is
#   wrapped.
#   When a line ends with "test(" or "testWidgets(" and the next line starts, after
#   spaces and tabs, with a string literal, that literal is the title, and errors
#   point at the line of the keyword. A wrapped group( is not read
# @arg $1 string The file and line number of an error
# @arg $2 string The line
# @arg $3 string The next line (optional)
# @set _COUNTS The counts of group IDs, case IDs and errors (global)
# @set _GROUP_ID, _DECLARED The ID, from check_declared_id (global)
# @stderr The errors of count_line_declaration
# @exitcode 0 always
#
check_dart_line() {
  count_line_declaration "$1" "$2" "$_DART_GROUP_PATTERN" "$_DART_CASE_PATTERN" "$_DART_CASE_START_PATTERN" "${3-}"
}

LANG_FILES[dart]='*.spec.dart'
LANG_HANDLER[dart]=check_dart_line
