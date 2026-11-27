#!/usr/bin/env bash
# src: ./skills/bdd-coder/skills/bdd-coder/scripts/check-ids/plugins/go-id-checker.plugin.sh
# @(#) : go plugin of the test case ID checker
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

declare -g _GO_GROUP_PATTERN="^[[:blank:]]*(t[.]Run)[(]${_QUOTE}(.*)"
declare -g _GO_CASE_PATTERN="^[[:blank:]]*(t[.]Run)[(]${_QUOTE}(.*)"
declare -g _GO_CASE_START_PATTERN='^[[:blank:]]*(t[.]Run)[(]'

#
# @description Count the declaration of a line, if it is one, and check its ID.
#   "t.Run(" declares groups and cases alike, so the form of the ID tells them apart.
#   Only spaces and tabs may precede it, and the quote of the title follows "(".
#   Without a title literal there, it declares a case with an empty title
# @arg $1 string The file and line number of an error
# @arg $2 string The line
# @set _KIND, _TITLE The declaration, from read_declaration (global)
# @set _ID, _ID_KIND The ID of the title, from parse_title_id (global)
# @set _COUNTS The counts of group IDs, case IDs and errors (global)
# @set _GROUP_ID, _DECLARED The ID, from check_declared_id (global)
# @stderr The errors of count_group_declaration or count_case_declaration
# @exitcode 0 always
#
check_go_line() {
  read_declaration "$2" "$_GO_GROUP_PATTERN" "$_GO_CASE_PATTERN" "$_GO_CASE_START_PATTERN" || return 0
  parse_title_id "$_TITLE"
  if [[ $_ID_KIND == group ]]; then
    count_group_declaration "$1" "$_TITLE"
  else
    count_case_declaration "$1" "$_TITLE"
  fi
}

LANG_FILES[go]='*_test.go'
LANG_HANDLER[go]=check_go_line
