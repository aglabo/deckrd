#!/usr/bin/env bash
# src: runners/ops/shell/test
# @(#) : shellspec runner
#
# Copyright (c) 2026- atsushifx <https://github.com/atsushifx>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

set -euo pipefail

PROJECT_ROOT="${PROJECT_ROOT:-$(git rev-parse --show-toplevel 2>/dev/null || echo "$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)")}"
SHELLSPEC="${SHELLSPEC:-${PROJECT_ROOT}/.tools/shellspec/shellspec}"

# @description Main entry point for running ShellSpec tests
# @arg $@ Command line arguments (paths and options)
# @exitcode Exit code from ShellSpec
main() {
  if [[ $# -eq 0 ]]; then
    set -- "."
  fi

  local -a args=("$@")
  local -a normalized_args=("${args[@]//\\//}")

  (cd "$PROJECT_ROOT" && bash "$SHELLSPEC" "${normalized_args[@]}")
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
