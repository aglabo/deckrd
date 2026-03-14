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

#
# @description Main entry point for running ShellSpec tests
# @arg $@ Command line arguments (paths and options)
# @exitcode Exit code from ShellSpec
#
# @example
#   main                              # Run all tests
#   main scripts/__tests__            # Run tests in specific directory
#   main test.spec.sh --focus         # Run with options
#
main() {
  # Default to current directory if no arguments provided
  if [[ $# -eq 0 ]]; then
    set -- "."
  fi

  # Normalize path separators (\ → /) for Windows compatibility
  # Windows paths with backslashes need conversion for bash/Unix tools
  # Bash の配列展開で全引数を一括変換（ﾙ恐[ﾌﾟv不要）
  local -a args=("$@")
  normalized_args=("${args[@]//\\//}")

  # Run ShellSpec from project root using subshell
  # Subshell ensures caller's directory remains unchanged
  # ShellSpec automatically loads .shellspec and resolves paths
  (cd "$PROJECT_ROOT" && bash "$SHELLSPEC" "${normalized_args[@]}")
}

# Execute main only if script is run directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
