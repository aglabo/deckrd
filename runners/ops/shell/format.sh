#!/usr/bin/env bash
# src: runners/ops/shell/format
# @(#) : shfmt runner
#
# Copyright (c) 2026- atsushifx <https://github.com/atsushifx>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

set -euo pipefail

# @description Run shfmt with given paths or default to current directory
# @arg $@ string Paths to format (defaults to "." if not specified)
# @option --list,-l List files that differ from shfmt's formatting (no write)
# @exitcode 0 Success
# @exitcode 1 shfmt error
main() {
  local mode="write"
  local -a paths=()

  for arg in "$@"; do
    case "$arg" in
    --list | -l) mode="list" ;;
    *) paths+=("$arg") ;;
    esac
  done

  if [[ ${#paths[@]} -eq 0 ]]; then
    paths=(".")
  fi

  case "$mode" in
  list) shfmt -l -ln bash -i 2 -- "${paths[@]}" ;;
  write) shfmt -w -ln bash -i 2 -- "${paths[@]}" ;;
  esac
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
