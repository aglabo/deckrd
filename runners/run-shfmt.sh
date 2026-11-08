#!/usr/bin/env bash
# src: ./runners/run-shfmt.sh
# @(#) : shfmt runner
#
# Copyright (c) 2026- atsushifx <https://github.com/atsushifx>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

# shellcheck disable=SC1091

set -euo pipefail

# Initialize directory variables
. "$(dirname "${BASH_SOURCE[0]}")/libs/init-vars.lib.sh"

main() {
  local mode="list"
  while [[ $# -gt 0 ]]; do
    case "$1" in
    --list | -l)
      mode="list"
      shift
      ;;
    --format)
      mode="format"
      shift
      ;;
    --)
      shift
      break
      ;;
    -*)
      echo "Unknown option: $1" >&2
      return 1
      ;;
    *) break ;;
    esac
  done
  # --apply-ignore applies the .editorconfig ignore rules (spec files, node_modules, .tools, ...)
  # to explicitly given files as well as to directory walks
  local -a targets=("${@//\\//}")
  if [[ $# -eq 0 ]]; then
    targets=(".")
  fi
  case "$mode" in
  list) (cd "$PROJECT_ROOT" && shfmt -ln bash -i 2 -l --apply-ignore -- "${targets[@]}") ;;
  format) (cd "$PROJECT_ROOT" && shfmt -ln bash -i 2 -w --apply-ignore -- "${targets[@]}") ;;
  esac
}
if [[ ${BASH_SOURCE[0]} == "$0" ]]; then
  main "$@"
fi
