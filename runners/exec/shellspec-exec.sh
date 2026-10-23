#!/usr/bin/env bash
# src: ./runners/exec/shellspec-exec.sh
# @(#) : shellspec runner
#
# Copyright (c) 2026- atsushifx <https://github.com/atsushifx>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

# shellcheck disable=SC1091

set -euo pipefail

# shellcheck source=runners/libs/init-vars.lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/../libs/init-vars.lib.sh"

SHELLSPEC="${SHELLSPEC:-${PROJECT_ROOT}/.tools/shellspec/shellspec}"

# Valid test type identifiers
readonly TEST_TYPES=("all" "unit" "functional" "integration" "system" "e2e")

# Test type used when the caller names no target (`pnpm run test:sh`)
readonly DEFAULT_TEST_TYPE='all'

# Directory name that roots every spec tree (runners/__tests__/unit/... etc.)
readonly TESTS_DIR='__tests__'

# Marks the login shell's PATH report: at the start of a line, the rest of that
# line is the reported PATH. Startup files write progress lines to stdout, so the
# report cannot be read wholesale
readonly LOGIN_PATH_MARKER='__DECKRD_LOGIN_PATH__'

# Spec file paths produced by resolve_spec_files()
RESOLVED_SPEC_FILES=()

# Test mode: set SKIP_INTEGRATION_TESTS=1 by default (development mode)
# Override with INTEGRATION_TEST=1 env var or --integration flag to run real-machine tests
SKIP_INTEGRATION_TESTS="${SKIP_INTEGRATION_TESTS:-1}"

# Search root for spec file discovery (override in tests to point at a temp dir)
SPEC_SEARCH_ROOT="${SPEC_SEARCH_ROOT:-${PROJECT_ROOT}}"

# shellcheck source=runners/libs/get-filelist.lib.sh
. "${SCRIPT_ROOT}/../libs/get-filelist.lib.sh"

#
# @description Check if argument is a valid test type
# @arg $1 string Argument to check
# @exitcode 0 if valid test type, 1 otherwise
#
is_test_type() {
  local arg="$1"
  local type
  for type in "${TEST_TYPES[@]}"; do
    [[ "$arg" == "$type" ]] && return 0
  done
  return 1
}

#
# @description Check if argument is a spec file path
# @arg $1 string Argument to check
# @exitcode 0 if spec file path, 1 otherwise
#
is_spec_file() {
  local arg="$1"
  [[ "$arg" == *.spec.sh ]]
}

#
# @description Check if argument is a glob path pattern targeting spec files
# @arg $1 string Argument to check
# @exitcode 0 if glob path containing *.spec.sh pattern, 1 otherwise
#
is_spec_glob() {
  local arg="$1"
  is_glob_pattern "$arg" && [[ "$arg" == *".spec.sh"* ]]
}

#
# @description Expand a glob path pattern to matching spec file paths
# @arg $1 string Glob path pattern (e.g. runners/libs/tests/unit/*.spec.sh)
# @stdout List of matching spec file paths
# @exitcode 0 always (warns if no match)
#
expand_spec_glob() {
  local pattern="$1"
  local norm_pattern
  norm_pattern=$(normalize_path "$pattern")

  local -a matches
  # Use compgen -G for glob expansion (handles no-match gracefully)
  mapfile -t matches < <(
    cd "$SPEC_SEARCH_ROOT" && compgen -G "$norm_pattern" 2>/dev/null || true
  )

  if [[ ${#matches[@]} -eq 0 ]]; then
    echo "Warning: No spec files found matching glob '${pattern}'" >&2
    return 0
  fi

  local f
  for f in "${matches[@]}"; do
    normalize_path "$f"
  done
}

#
# @description Get spec files for a given test type
# @arg $1 string Test type (all, unit, functional, etc.)
# @arg $@ Additional file patterns to filter by
# @stdout List of spec file paths relative to project root
#
get_spec_files() {
  local test_type="$1"
  shift
  # The leading separator anchors the filter to a whole path component: without it
  # a directory merely ending in the name (not__tests__/unit/) would match too.
  # It is written as the class [/] rather than a bare slash because MSYS2 rewrites
  # a slash-led token inside an argument into a Windows path before rg sees it
  local type_filter
  if [[ "$test_type" == "all" ]]; then
    type_filter="[/]${TESTS_DIR}/"
  else
    type_filter="[/]${TESTS_DIR}/${test_type}/"
  fi
  get_filelist "$SPEC_SEARCH_ROOT" "*.spec.sh" "$type_filter" "$@"
}

#
# @description Split the command line into targets and ShellSpec options, consuming
#              the --integration flag this script owns wherever it appears. Targets
#              come first, so every argument from the first one starting with `-` is an
#              option (the value of a value-taking option must not be mistaken for a
#              target). Must be called in the caller's own shell, never through a pipe
#              or $(): the SKIP_INTEGRATION_TESTS assignment would be lost with the
#              subshell, which is why the results go to the caller's arrays by name
# @arg $1 string Name of the caller's array that receives the targets
# @arg $2 string Name of the caller's array that receives the ShellSpec options
# @arg $@ Command line arguments (those after the two names)
# @sideeffect Replaces the array named by $1 with the targets; DEFAULT_TEST_TYPE alone
#             when none is named
# @sideeffect Replaces the array named by $2 with the options; empty when none is given
# @sideeffect Sets SKIP_INTEGRATION_TESTS=0 if --integration found
#
parse_options() {
  # The `__` prefix keeps the namerefs from shadowing the caller's array names
  local -n __targets="$1" __options="$2"
  shift 2
  __targets=()
  __options=()
  local arg
  for arg in "$@"; do
    if [[ "$arg" == "--integration" ]]; then
      SKIP_INTEGRATION_TESTS=0
    elif [[ ${#__options[@]} -gt 0 || "$arg" == -* ]]; then
      __options+=("$arg")
    else
      __targets+=("$arg")
    fi
  done
  # No target named (`pnpm run test:sh` passes none, and so does an options-only
  # invocation): run the whole suite
  [[ ${#__targets[@]} -gt 0 ]] || __targets=("$DEFAULT_TEST_TYPE")
}

#
# @description Resolve spec files from arguments (handles test types, globs, single files).
#              Must be called in the caller's own shell: the result is a global, never
#              stdout, because the `system` type also has to set SKIP_INTEGRATION_TESTS
#              and a subshell would discard that assignment. The first argument picks
#              the mode: a spec file or glob means every argument is a spec target,
#              anything else must be a test type
# @arg $@ Command line arguments (test type, spec file, or glob pattern)
# @stderr Error and warning messages
# @sideeffect Sets RESOLVED_SPEC_FILES to the resolved spec file paths (empty on no match)
# @sideeffect Sets SKIP_INTEGRATION_TESTS=0 for the `system` test type
# @exitcode 0 on success, 1 on error
#
resolve_spec_files() {
  RESOLVED_SPEC_FILES=()

  [[ $# -eq 0 ]] && {
    printf 'Error: No arguments given.\n' >&2
    return 1
  }

  # All targets are validated before any is stored, so a bad one leaves no
  # partial result behind
  if _is_spec_target "$1"; then
    _validate_spec_targets "$@" || return 1
    _store_spec_targets "$@"
    return 0
  fi

  _resolve_test_type "$@"
}

#
# @description Report an argument that is neither a test type, spec file, nor glob
# @arg $1 string The rejected argument
# @stderr Error message naming the argument
#
_report_unknown_argument() {
  printf "Error: Unknown argument '%s'. Expected a test type, spec file, or glob pattern.\n" "$1" >&2
}

#
# @description Check if argument is a spec target: a spec glob or a spec file path
# @arg $1 string Argument to check
# @exitcode 0 if spec glob or spec file path, 1 otherwise
#
_is_spec_target() {
  is_spec_glob "$1" || is_spec_file "$1"
}

#
# @description Check that every target is a spec file or a spec glob. Runs before
#              anything is stored, so a bad target leaves no partial result behind
# @arg $@ Targets to check
# @stderr Error message naming the first invalid target
# @exitcode 0 if all targets are valid, 1 on the first invalid one
#
_validate_spec_targets() {
  local target
  for target in "$@"; do
    if ! _is_spec_target "$target"; then
      _report_unknown_argument "$target"
      return 1
    fi
  done
}

#
# @description Append spec targets to RESOLVED_SPEC_FILES in argument order: spec
#              files as given, globs expanded in place. Targets must be validated
#              beforehand. The glob test comes first because a glob also ends in
#              .spec.sh. A glob that matches nothing contributes no element (not an
#              empty one): expand_spec_glob prints nothing, so mapfile reads nothing
# @arg $@ Spec file paths and/or spec glob patterns
# @stderr Warning for a glob that matches nothing (from expand_spec_glob)
# @sideeffect Appends to RESOLVED_SPEC_FILES
#
_store_spec_targets() {
  local target
  local -a expanded
  for target in "$@"; do
    if is_spec_glob "$target"; then
      mapfile -t expanded < <(expand_spec_glob "$target")
      RESOLVED_SPEC_FILES+=(${expanded[@]+"${expanded[@]}"})
    else
      RESOLVED_SPEC_FILES+=("$target")
    fi
  done
}

#
# @description Resolve spec files for a test type via get_spec_files. Must be called
#              in the caller's own shell, for the same reason as resolve_spec_files
# @arg $1 string Test type (all, unit, functional, etc.)
# @arg $@ Additional file patterns to filter by
# @stderr Error for an unknown test type; warning when nothing matches
# @sideeffect Sets RESOLVED_SPEC_FILES to the matching spec file paths
# @sideeffect Sets SKIP_INTEGRATION_TESTS=0 for the `system` test type
# @exitcode 0 on success (including no match), 1 if $1 is not a test type
#
_resolve_test_type() {
  local test_type="$1"
  if ! is_test_type "$test_type"; then
    _report_unknown_argument "$test_type"
    return 1
  fi
  shift

  [[ "$test_type" == "system" ]] && SKIP_INTEGRATION_TESTS=0
  mapfile -t RESOLVED_SPEC_FILES < <(get_spec_files "$test_type" "$@")
  _drop_empty_resolved
  if [[ ${#RESOLVED_SPEC_FILES[@]} -eq 0 ]]; then
    echo "Warning: No spec files found for test type '${test_type}'" >&2
  fi
  return 0
}

#
# @description Normalize RESOLVED_SPEC_FILES: a producer emitting a bare newline
#              leaves mapfile with a single empty element, which is not a spec file
# @sideeffect Empties RESOLVED_SPEC_FILES when it holds one empty element
#
_drop_empty_resolved() {
  if [[ ${#RESOLVED_SPEC_FILES[@]} -eq 1 && -z "${RESOLVED_SPEC_FILES[0]}" ]]; then
    RESOLVED_SPEC_FILES=()
  fi
}

#
# @description Pick the PATH a probe reported out of the probe's whole stdout. The
#              startup files a login shell reads write their own lines to stdout, so
#              the report cannot be taken wholesale; only the line the probe introduced
#              with the marker carries the PATH. The marker counts at the start of a
#              line only, and the last such line wins, so a startup file that prints the
#              marker's spelling cannot shadow what the probe appended last.
#              Pure function: reads only its arguments
# @arg $1 string Marker the probe printed in front of the PATH
# @arg $2 string Whole stdout of the probe
# @stdout The rest of the marked line, i.e. the reported PATH; empty when the marked
#         line carries none
# @exitcode 0 when the output holds a marked line, 1 when it holds none
#
extract_marked_path() {
  local __marker="$1"
  # The leading newline lets a marked first line obey the same start-of-line rule
  # as every later line
  local __haystack=$'\n'"$2"
  # Fail rather than return something: without a marked line, the caller would
  # take a progress line for the PATH
  [[ "$__haystack" == *$'\n'"$__marker"* ]] || return 1
  # Longest-prefix removal keeps what follows the last marked line only
  local __tail="${__haystack##*$'\n'"$__marker"}"
  printf '%s\n' "${__tail%%$'\n'*}"
}

#
# @description Drop the empty entries of a colon separated PATH. An empty entry names
#              the current directory, so one left in a reported PATH puts whatever
#              directory ShellSpec runs from on the command search path.
#              Pure function: reads only its argument
# @arg $1 string Colon separated PATH
# @stdout The same PATH without its empty entries; empty when every entry was empty
# @exitcode 0 always
#
drop_empty_path_entries() {
  local -a __entries=()
  # The here-string appends a newline, so read always consumes one line and returns 0.
  # The split loses a trailing empty entry, which is one of those to drop anyway
  IFS=':' read -ra __entries <<<"$1"
  local __entry __kept=''
  # The guarded expansion keeps an empty array safe under `set -u`
  for __entry in ${__entries[@]+"${__entries[@]}"}; do
    [[ -n "$__entry" ]] || continue
    __kept="${__kept:+${__kept}:}${__entry}"
  done
  printf '%s\n' "$__kept"
}

#
# @description Replace PATH with the one a login and interactive shell reports, so that
#              tools installed by the user's startup files (volta, linuxbrew, nix) become
#              reachable. Real-machine tests need them; the non-login, non-interactive
#              shell that runs this script reads no startup file and has none of them.
#              `-lic` rather than `-lc`: a startup chain may add its entries from the
#              interactive rc, and only a shell that is both login and interactive reads
#              both halves, the same shell the user gets when opening a terminal.
#              The report replaces PATH instead of extending it: it is a superset of the
#              inherited PATH, so nothing is lost, and the inherited entries no longer
#              shadow the copy of a tool the startup files installed
# @sideeffect Replaces PATH when the login shell reports one
# @exitcode 0 always; a login shell that fails, reports no marked line, or reports
#           nothing but empty entries leaves PATH untouched
#
ensure_integration_path() {
  local _raw _marked _cleaned
  # The marker travels as a positional parameter, which keeps the probe body in plain
  # single quotes ('bash' is $0, the name used in error messages).
  # stdin is closed: an interactive shell may read it, and a startup file that calls
  # read would hang the whole test run instead of failing it
  # shellcheck disable=SC2016 # probe body; the login shell expands $1 and $PATH
  _raw="$(bash -lic 'printf "\n%s%s\n" "$1" "$PATH"' bash "$LOGIN_PATH_MARKER" 2>/dev/null </dev/null)" || return 0
  _marked="$(extract_marked_path "$LOGIN_PATH_MARKER" "$_raw")" || return 0
  _cleaned="$(drop_empty_path_entries "$_marked")"
  [[ -n "$_cleaned" ]] && PATH="$_cleaned"
  return 0
}

#
# @description Run ShellSpec with normalized path arguments
# @arg $@ Spec file paths followed by ShellSpec options (options pass through
#         normalize_path unchanged unless they contain backslashes)
# @exitcode Exit code from ShellSpec
#
run_shellspec() {
  local -a normalized_args=()
  local arg
  for arg in "$@"; do
    normalized_args+=("$(normalize_path "$arg")")
  done

  # Run ShellSpec from project root using subshell
  # Subshell ensures caller's directory remains unchanged
  (cd "$PROJECT_ROOT" && export SKIP_INTEGRATION_TESTS && bash "$SHELLSPEC" "${normalized_args[@]}")
}

#
# @description Main entry point for running ShellSpec tests. When integration mode is
#              on (--integration, the `system` type, or an inherited
#              SKIP_INTEGRATION_TESTS=0) and spec files were resolved, PATH is replaced
#              with the login shell's (ensure_integration_path) before ShellSpec runs, so
#              that real-machine tests reach the tools the user's startup files install.
#              Leaves with return, never exit, so a caller running it in its own shell
#              keeps going; the entry point turns the return value into the exit code
# @arg $@ Command line arguments (test type, paths and options)
# @sideeffect Replaces PATH in integration mode (ensure_integration_path)
# @exitcode Return value: ShellSpec's exit code; 1 when a target cannot be resolved,
#           0 when no spec file is resolved (the login shell is not started in either
#           case)
#
# @example
#   main unit                         # Run unit tests (auto-resolved)
#   main integration                  # Run integration tests (auto-resolved)
#   main all                          # Run all tests
#   main runners/libs/tests/unit/*.spec.sh  # Run spec glob
#   main test.spec.sh --repair        # Run with ShellSpec options
#
main() {
  # Called in this shell, not through a pipe or $(): parse_options() fills the
  # arrays through namerefs precisely so that SKIP_INTEGRATION_TESTS survives
  local -a targets options
  parse_options targets options "$@"

  # Likewise called directly: the `system` type sets SKIP_INTEGRATION_TESTS.
  # A bad target is reported to the caller as return value 1
  resolve_spec_files "${targets[@]}" || return 1

  # Nothing resolved means nothing to run, and so no login shell to start either
  [[ ${#RESOLVED_SPEC_FILES[@]} -eq 0 ]] && return 0

  # Integration mode is settled only after target resolution: --integration, the
  # `system` type and an inherited SKIP_INTEGRATION_TESTS=0 all end up in this one
  # flag, so a single check covers them and starts the login shell at most once,
  # and only when there are spec files to run.
  # A string comparison, not `-eq`: an inherited value would otherwise be
  # arithmetic-evaluated (`true` aborts under set -u, and the subscript in
  # `BASH_VERSINFO[$(cmd)]` runs cmd), so only the exact string 0 turns
  # integration mode on
  [[ "$SKIP_INTEGRATION_TESTS" == 0 ]] && ensure_integration_path

  run_shellspec "${RESOLVED_SPEC_FILES[@]}" ${options[@]+"${options[@]}"}
}

# Execute main only if script is run directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
