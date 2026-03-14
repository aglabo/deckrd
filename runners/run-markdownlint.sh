#!/usr/bin/env bash
# src: runners/docs/lint
# @(#) : docs linter runner (markdownlint + textlint)
#
# Copyright (c) 2026- atsushifx <https://github.com/atsushifx>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

set -euo pipefail

# @description Run markdownlint and textlint against docs
# @arg $@ string Paths to lint (passed to both linters)
# @exitcode 0 All checks passed
# @exitcode 1 Lint error
main() {
  local -a targets=("$@")

  markdownlint-cli2 --config "${XDG_CONFIG_HOME}/linters/markdownlint/.markdownlint-cli2.yaml" "${targets[@]+"${targets[@]}"}"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
