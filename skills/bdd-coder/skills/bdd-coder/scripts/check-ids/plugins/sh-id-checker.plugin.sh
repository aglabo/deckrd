#!/usr/bin/env bash
# src: ./skills/bdd-coder/skills/bdd-coder/scripts/check-ids/plugins/sh-id-checker.plugin.sh
# @(#) : sh plugin of the test case ID checker
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

declare -g _SH_GROUP_PATTERN="^[[:blank:]]*(Describe|Context|ExampleGroup)[[:blank:]]+${_QUOTE}(.*)"
declare -g _SH_CASE_PATTERN="^[[:blank:]]*(It|Example|Specify)[[:blank:]]+${_QUOTE}(.*)"
declare -g _SH_CASE_START_PATTERN=$'^[[:blank:]]*(It|Example|Specify)([ \t\r]|$)'

#
# @description Count the declaration of a line, if it is one, and check its ID.
#   Only spaces and tabs may precede a keyword, and at least one of them stands
#   between a keyword and the quote of its title. Without a title literal, a case
#   keyword declares a case only before a space, a tab, a CR or the line end
# @arg $1 string The file and line number of an error
# @arg $2 string The line
# @set _COUNTS The counts of group IDs, case IDs and errors (global)
# @set _GROUP_ID, _DECLARED The ID, from check_declared_id (global)
# @stderr The errors of count_line_declaration
# @exitcode 0 always
#
check_sh_line() {
  count_line_declaration "$1" "$2" "$_SH_GROUP_PATTERN" "$_SH_CASE_PATTERN" "$_SH_CASE_START_PATTERN"
}

LANG_FILES[sh]='*.spec.sh'
LANG_HANDLER[sh]=check_sh_line
