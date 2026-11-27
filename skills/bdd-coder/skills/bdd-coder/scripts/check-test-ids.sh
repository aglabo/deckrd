#!/usr/bin/env bash
# src: ./skills/bdd-coder/skills/bdd-coder/scripts/check-test-ids.sh
# @(#) : test case ID checker
#
# Copyright (c) 2026- atsushifx <https://github.com/atsushifx>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

set -euo pipefail

# The libraries and the plugins are located relative to this script
_SCRIPT_DIR="${BASH_SOURCE[0]%/*}"
[[ $_SCRIPT_DIR != "${BASH_SOURCE[0]}" ]] || _SCRIPT_DIR='.'

# shellcheck source=libs/args.lib.sh disable=SC1091
. "${_SCRIPT_DIR}/libs/args.lib.sh"
# shellcheck source=libs/glob.lib.sh disable=SC1091
. "${_SCRIPT_DIR}/libs/glob.lib.sh"
# shellcheck source=check-ids/libs/report.lib.sh disable=SC1091
. "${_SCRIPT_DIR}/check-ids/libs/report.lib.sh"
# shellcheck source=check-ids/libs/test-id.lib.sh disable=SC1091
. "${_SCRIPT_DIR}/check-ids/libs/test-id.lib.sh"
# shellcheck source=check-ids/libs/file-reader.lib.sh disable=SC1091
. "${_SCRIPT_DIR}/check-ids/libs/file-reader.lib.sh"
# shellcheck source=check-ids/languages.sh disable=SC1091
. "${_SCRIPT_DIR}/check-ids/languages.sh"

# LANG_PLUGIN of languages.sh names the plugin of a language:
# check-ids/plugins/<id>-id-checker.plugin.sh
_PLUGIN_DIR="${_SCRIPT_DIR}/check-ids/plugins"
_PLUGIN_SUFFIX='-id-checker.plugin.sh'

# Set by the plugins per language: space-separated file name globs, and the function
# that read_file_lines calls for each line
declare -gA LANG_FILES=() LANG_HANDLER=()

#
# @description Print the command usage
# @stdout Usage text
#
usage() {
  echo 'Usage: check-test-ids.sh [--lang <lang>[,<lang>...]]'
}

#
# @description Print the languages of a --lang list, each of them once. A language is
#   known when LANG_PLUGIN has it. An empty element, such as the one after a trailing
#   comma, is an unknown language
# @arg $1 string The languages, separated by commas
# @stdout One language per line
# @stderr The unknown language
# @exitcode 0 Every language is known
# @exitcode 1 A language is unknown
#
select_languages() {
  local lang
  local -a langs
  local -A seen=()
  # NUL keeps a newline in its language; the added comma keeps an empty last one
  IFS=, read -r -d '' -a langs < <(printf '%s,\0' "$1")
  for lang in "${langs[@]}"; do
    # An empty key is a bash error
    if [[ -z $lang || -z ${LANG_PLUGIN[$lang]:-} ]]; then
      echo "Error: Unknown language: ${lang}" >&2
      return 1
    fi
    [[ -n ${seen[$lang]:-} ]] || echo "$lang"
    seen[$lang]=1
  done
}

#
# @description Load the plugins that LANG_PLUGIN names for the languages into the
#   current shell
# @arg $@ string The languages, each of them in LANG_PLUGIN
# @set LANG_FILES, LANG_HANDLER The values of the languages
# @stderr The language whose plugin fails to load, or leaves LANG_FILES empty or
#   LANG_HANDLER without the name of a defined function
# @exitcode 0 Every plugin is loaded
# @exitcode 1 A plugin fails to load or leaves a value empty. A LANG_HANDLER that
#   names no function counts as empty
#
load_plugins() {
  local lang
  for lang in "$@"; do
    # shellcheck source=/dev/null
    if ! . "${_PLUGIN_DIR}/${LANG_PLUGIN[$lang]}${_PLUGIN_SUFFIX}"; then
      echo "Error: ${lang}: cannot load the plugin" >&2
      return 1
    fi
    if [[ -z ${LANG_FILES[$lang]:-} ]]; then
      echo "Error: ${lang}: empty value: LANG_FILES" >&2
      return 1
    fi
    # An empty name is not a function either
    if ! declare -F -- "${LANG_HANDLER[$lang]:-}" > /dev/null; then
      echo "Error: ${lang}: empty value: LANG_HANDLER" >&2
      return 1
    fi
  done
}

#
# @description Print the root to scan: TEST_ID_CHECK_ROOT when set, otherwise the git
#   toplevel, or the current directory outside git (or without git). git is not
#   called when TEST_ID_CHECK_ROOT is set. Any other git failure, such as a
#   repository that git rejects, is an error and not a reason to scan the current
#   directory. LC_ALL=C keeps the message of git untranslated, so that "outside git"
#   can be told apart. The caller must propagate the failure, as set -e does not stop in
#   every context
# @stdout The scan root
# @stderr The first line of the message of the failing git
# @exitcode 0 The scan root is printed
# @exitcode 1 git fails inside what may be a repository
#
scan_root() {
  if [[ -n ${TEST_ID_CHECK_ROOT:-} ]]; then
    echo "$TEST_ID_CHECK_ROOT"
    return 0
  fi
  if ! command -v git > /dev/null; then
    echo .
    return 0
  fi
  local root message
  if root="$(LC_ALL=C git rev-parse --show-toplevel 2> /dev/null)"; then
    echo "$root"
    return 0
  fi
  # A second run keeps the warnings of a successful git out of the root
  message="$(LC_ALL=C git rev-parse --show-toplevel 2>&1 > /dev/null)" || true
  if [[ $message == *'not a git repository (or any'* ]]; then
    echo .
    return 0
  fi
  echo "Error: cannot find the git toplevel: ${message%%$'\n'*}" >&2
  return 1
}

#
# @description Check the test files of a language, in path order, which decides the
#   declaration that is reported as the duplicate. The handler of the language
#   reads each line. A language with no test file is not also reported as having no
#   group ID
# @arg $1 string The scan root
# @arg $2 string The language
# @set _COUNTS The counts of files, group IDs, case IDs and errors
# @stderr The errors of the listing, of the files and of the language
#
check_language() {
  local listing file
  local -a globs
  # read splits the globs without expanding them
  read -r -a globs <<< "${LANG_FILES[$2]}"
  local files_before=${_COUNTS[files]} groups_before=${_COUNTS[group]}

  # pipefail: this fails when the listing or sort fails
  if ! listing="$(file_list_by_globs "$1" ${globs[@]+"${globs[@]}"} | LC_ALL=C sort)"; then
    report_error "$2: cannot list the test files under $1"
    return 0
  fi

  while IFS= read -r file; do
    # An empty listing is one empty line in a here-string
    [[ -n $file ]] || continue
    counts_add files
    read_file_lines "$1" "$file" "${LANG_HANDLER[$2]}"
  done <<< "$listing"

  if [[ ${_COUNTS[files]} -eq $files_before ]]; then
    report_error "$2: no test file"
  elif [[ ${_COUNTS[group]} -eq $groups_before ]]; then
    report_error "$2: no group ID"
  fi
}

#
# @description Check every declaration under the scan root. An ID must be declared
#   only once among the files of all the languages. Every error is reported before
#   the check fails
# @arg $@ string The languages to check
# @set _COUNTS The counts of files, group IDs, case IDs and errors
# @set _DECLARED The declared IDs
# @stdout The counts of files, group IDs and case IDs, when there is no error
# @stderr The errors
# @exitcode 0 No error
# @exitcode 1 The check has an error
#
check_ids() {
  # Letters and digits are ASCII only
  local LC_ALL=C
  local root lang
  counts_init
  declared_ids_init
  root="$(scan_root)" || return 1

  for lang in "$@"; do
    check_language "$root" "$lang"
  done

  counts_summary
}

#
# @description Main entry point
# @arg $@ string The command line arguments
# @stdout The usage for -h or --help, otherwise the counts
# @stderr The rejected argument, or the errors of the check
# @exitcode 0 The check passed, or help was requested
# @exitcode 1 An argument is rejected, a plugin fails to load, or the check has an error
#
main() {
  args_init
  args_value lang sh --lang
  if ! parse_args "$@"; then
    echo "Error: ${ARGS_ERROR}" >&2
    return 1
  fi
  if [[ ${OPTIONS[SHOW_HELP]} == true ]]; then
    usage
    return 0
  fi
  local selected
  local -a langs
  selected="$(select_languages "${OPTIONS[lang]}")" || return 1
  mapfile -t langs <<< "$selected"
  load_plugins "${langs[@]}" || return 1
  check_ids "${langs[@]}"
}

if [[ ${BASH_SOURCE[0]} == "${0}" ]]; then
  main "$@"
fi
