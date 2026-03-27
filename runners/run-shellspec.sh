#!/usr/bin/env bash
# src: ./scripts/run-specs.sh
# @(#) : shellspec runner
#
# Copyright (c) 2026- atsushifx <https://github.com/atsushifx>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

# shellcheck disable=SC1091

set -euo pipefail

# Project root and constants
PROJECT_ROOT="${PROJECT_ROOT:-$(git rev-parse --show-toplevel 2>/dev/null || (cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd))}"
SHELLSPEC="${SHELLSPEC:-${PROJECT_ROOT}/.tools/shellspec/shellspec}"

# Valid test type identifiers
readonly TEST_TYPES=("all" "unit" "functional" "integration" "system" "e2e")

# Test mode: set SKIP_INTEGRATION_TESTS=1 by default (development mode)
# Override with INTEGRATION_TEST=1 env var or --integration flag to run real-machine tests
SKIP_INTEGRATION_TESTS="${SKIP_INTEGRATION_TESTS:-1}"

# Search root for spec file discovery (override in tests to point at a temp dir)
SPEC_SEARCH_ROOT="${SPEC_SEARCH_ROOT:-${PROJECT_ROOT}}"

# shellcheck source=runners/libs/get-filelist.sh
. "${PROJECT_ROOT}/runners/libs/get-filelist.sh"

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
  local type_filter
  if [[ "$test_type" == "all" ]]; then
    type_filter="tests"
  else
    type_filter="(tests|__tests__)/${test_type}"
  fi
  get_filelist "$SPEC_SEARCH_ROOT" "*.spec.sh" "$type_filter" "$@"
}

#
# @description Parse options, extracting --integration flag
# @arg $@ Command line arguments
# @stdout Remaining arguments (without --integration), newline-separated
# @sideeffect Sets SKIP_INTEGRATION_TESTS=0 if --integration found
#
parse_options() {
  local arg
  for arg in "$@"; do
    if [[ "$arg" == "--integration" ]]; then
      SKIP_INTEGRATION_TESTS=0
    else
      printf '%s\n' "$arg"
    fi
  done
}

#
# @description Resolve spec files from arguments (handles test types, globs, single files)
# @arg $@ Command line arguments (test type, spec file, or glob pattern)
# @stdout List of spec file paths; error message on failure
# @exitcode 0 on success, 1 on error
#
resolve_spec_files() {
  [[ $# -eq 0 ]] && {
    printf 'Error: No arguments given.\n'
    return 1
  }

  local first_arg="$1"

  # 単一 .spec.sh ファイル → そのまま出力
  if is_spec_file "$first_arg"; then
    printf '%s\n' "$first_arg"
    return 0
  fi

  # glob パス（*.spec.sh を含む glob）→ expand_spec_glob で展開
  if is_spec_glob "$first_arg"; then
    expand_spec_glob "$first_arg"
    return 0
  fi

  # テスト種別以外 → エラー (stdout)
  if ! is_test_type "$first_arg"; then
    printf "Error: Unknown argument '%s'. Expected a test type, spec file, or glob pattern.\n" "$first_arg"
    return 1
  fi

  # テスト種別 → get_spec_files で展開
  local test_type="$1"
  shift
  [[ "$test_type" == "system" ]] && SKIP_INTEGRATION_TESTS=0
  local -a spec_files
  mapfile -t spec_files < <(get_spec_files "$test_type" "$@")
  if [[ ${#spec_files[@]} -eq 0 || -z "${spec_files[0]}" ]]; then
    echo "Warning: No spec files found for test type '${test_type}'" >&2
    return 0
  fi
  printf '%s\n' "${spec_files[@]}"
}

#
# @description Run ShellSpec with normalized path arguments
# @arg $@ Spec file paths to pass to ShellSpec
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
# @description Main entry point for running ShellSpec tests
# @arg $@ Command line arguments (test type, paths and options)
# @exitcode Exit code from ShellSpec
#
# @example
#   main unit                         # Run unit tests (auto-resolved)
#   main integration                  # Run integration tests (auto-resolved)
#   main all                          # Run all tests
#   main runners/libs/tests/unit/*.spec.sh  # Run spec glob
#   main test.spec.sh --focus         # Run with options
#
main() {
  if [[ $# -eq 0 ]]; then
    echo "Usage: run-shellspec.sh <test-type|spec-file|spec-glob> [--integration] [shellspec-options]" >&2
    exit 1
  fi

  local -a filtered_args
  mapfile -t filtered_args < <(parse_options "$@")

  local resolved exit_code
  resolved=$(resolve_spec_files "${filtered_args[@]}") || exit_code=$?
  if [[ ${exit_code:-0} -ne 0 ]]; then
    echo "$resolved" >&2
    exit 1
  fi

  [[ -z "$resolved" ]] && exit 0

  local -a spec_files
  mapfile -t spec_files <<<"$resolved"
  run_shellspec "${spec_files[@]}"
}

# Execute main only if script is run directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
