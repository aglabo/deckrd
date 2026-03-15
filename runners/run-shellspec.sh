#!/usr/bin/env bash
# src: ./scripts/run-specs.sh
# @(#) : shellspec runner
#
# Copyright (c) 2026- atsushifx <https://github.com/atsushifx>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

set -euo pipefail

# Project root and constants
PROJECT_ROOT="${PROJECT_ROOT:-$(git rev-parse --show-toplevel 2>/dev/null || (cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd))}"
SHELLSPEC="${SHELLSPEC:-${PROJECT_ROOT}/.tools/shellspec/shellspec}"

# Valid test type identifiers
readonly TEST_TYPES=("all" "unit" "functional" "integration" "system" "e2e")

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
# @description Get spec files for a given test type
# @arg $1 string Test type (all, unit, functional, etc.)
# @arg $@ Additional file patterns or directories to pass to rg
# @stdout List of spec file paths relative to project root
#
get_spec_files() {
  local test_type="$1"
  shift
  local filter
  if [[ "$test_type" == "all" ]]; then
    filter="tests"
  else
    filter="tests/${test_type}"
  fi
  local project_root_unix="${PROJECT_ROOT//\\//}"
  rg --files -g "*.spec.sh" "$@" \
    | tr '\\' '/' \
    | rg "${filter}"
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
#   main scripts/__tests__            # Run tests in specific directory
#   main test.spec.sh --focus         # Run with options
#
main() {
  if [[ $# -eq 0 ]]; then
    echo "Usage: run-shellspec.sh <test-type|spec-file> [shellspec-options]" >&2
    exit 1
  fi

  # 第1引数が .spec.sh ファイルなら展開せずそのまま実行
  if is_spec_file "$1"; then
    : # テスト種別展開をスキップ（そのまま下の ShellSpec 実行へ）
  elif is_test_type "$1"; then
    local test_type="$1"
    shift
    local -a spec_files
    mapfile -t spec_files < <(get_spec_files "$test_type" "$@")
    if [[ ${#spec_files[@]} -eq 0 ]]; then
      echo "Warning: No spec files found for test type '${test_type}'" >&2
      exit 0
    fi
    set -- "${spec_files[@]}"
  fi

  # Normalize path separators (\ → /) for Windows compatibility
  # Windows paths with backslashes need conversion for bash/Unix tools
  local -a args=("$@")
  local -a normalized_args=("${args[@]//\\//}")

  # Run ShellSpec from project root using subshell
  # Subshell ensures caller's directory remains unchanged
  # ShellSpec automatically loads .shellspec and resolves paths
  (cd "$PROJECT_ROOT" && bash "$SHELLSPEC" "${normalized_args[@]}")
}

# Execute main only if script is run directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
