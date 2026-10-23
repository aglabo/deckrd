#!/usr/bin/env bash
# src: runners/run-markdownlint.sh
# @(#) : markdownlint runner
#
# Copyright (c) 2026- atsushifx <https://github.com/atsushifx>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

# shellcheck disable=SC1091

set -euo pipefail

# Init variables
. "$(dirname "${BASH_SOURCE[0]}")/libs/init-vars.lib.sh"

# load utilty library
. "${SCRIPT_ROOT}/libs/utils.lib.sh"

# @description Run markdownlint with the global config
# @arg $@ string Paths to lint
# @exitcode 0 All checks passed
# @exitcode 1 Lint error
main() {
  local -a targets=("$@")
  local configFile
  configFile="$(resolve_global_configdir)/linters/markdownlint/.markdownlint-cli2.yaml"

  markdownlint --config "${configFile}" "${targets[@]+"${targets[@]}"}"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
  exit $?
fi
