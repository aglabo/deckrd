#!/usr/bin/env bash
# src: runners/run-shfmt.sh
# @(#) : shfmt runner (formatting rules come from .editorconfig)
#
# Copyright (c) 2026- atsushifx <https://github.com/atsushifx>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

set -euo pipefail

# shellcheck source=runners/libs/init-vars.lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/libs/init-vars.lib.sh"

# @description Run shfmt with the formatting rules from .editorconfig
# @arg $1 string Optional mode: "--list"/"-l" (default, list files that need formatting) or "--format" (rewrite in place)
# @arg $@ string Paths to check (default: the project root)
# @stderr "Unknown option: <opt>" for an unrecognized option
# @exitcode 0 Success
# @exitcode 1 Unknown option, or shfmt failed
main()
       {
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
  local -a targets=("$@")
  if [[ ${#targets[@]} -eq 0 ]]; then
    targets=(".")
  fi
  targets=("${targets[@]//\\//}")
  case "$mode" in
    # --apply-ignore: apply the .editorconfig ignore rules (e.g. *.spec.sh) to explicitly given files too
    list) (cd "$PROJECT_ROOT" && shfmt -l --apply-ignore -- "${targets[@]}") ;;
    format) (cd "$PROJECT_ROOT" && shfmt -w --apply-ignore -- "${targets[@]}") ;;
  esac
}
if [[ ${BASH_SOURCE[0]} == "$0" ]]; then
  # exit so bash never re-reads this file after shfmt rewrites it in place
  main "$@"
  exit $?
fi
