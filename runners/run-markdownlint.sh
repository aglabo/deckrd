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
# shellcheck source=runners/libs/init-vars.lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/libs/init-vars.lib.sh"

# load utility library
# shellcheck source=runners/libs/utils.lib.sh
. "${SCRIPT_ROOT}/libs/utils.lib.sh"

# Config file path relative to the global config directory
readonly CONFIG_GLOBAL_RELPATH='.markdownlint-cli2.yaml'

# Config file path relative to PROJECT_ROOT
readonly CONFIG_LOCAL_RELPATH='configs/.markdownlint-cli2.yaml'

# @description Run markdownlint with the checked-in config,
#              or with the global config when the checked-in one is absent
# @arg $@ string Paths to lint
# @stderr "Error: <not-found message>" when no config file is found
# @exitcode 0 All checks passed
# @exitcode 1 Lint error
# @exitcode 78 (EXIT_CONFIG_NOT_FOUND) Config file not found
main() {
  local -a targets=("$@")
  local configFile status=0
  configFile="$(resolve_config_file "$CONFIG_GLOBAL_RELPATH" "$CONFIG_LOCAL_RELPATH")" || status=$?
  if [[ $status -ne 0 ]]; then
    echo "Error: $(format_config_not_found "$status" "$CONFIG_GLOBAL_RELPATH" "$CONFIG_LOCAL_RELPATH")" >&2
    return "$EXIT_CONFIG_NOT_FOUND"
  fi

  markdownlint --config "${configFile}" "${targets[@]+"${targets[@]}"}"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
  exit $?
fi
