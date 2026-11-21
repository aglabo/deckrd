#!/usr/bin/env bash
# src: runners/run-betterleaks.sh
# @(#) : betterleaks runner
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
readonly CONFIG_GLOBAL_RELPATH='betterleaks.toml'

# Config file path relative to PROJECT_ROOT
readonly CONFIG_LOCAL_RELPATH='configs/betterleaks.toml'

# @description Run betterleaks with the checked-in config,
#              or with the global config when the checked-in one is absent.
#              With --staged, scan the staged changes (pre-commit);
#              otherwise scan each given path (default: the current directory).
#              Findings are printed with the secret redacted
# @arg $1 string Optional "--staged" to scan the staged changes
# @arg $@ string Paths to scan (ignored with --staged)
# @stderr "Error: <not-found message>" when no config file is found
# @exitcode 0 No leaks found
# @exitcode 1 Leaks found
# @exitcode 78 (EXIT_CONFIG_NOT_FOUND) Config file not found
main() {
  local staged=0
  if [[ ${1:-} == '--staged'   ]]; then
    staged=1
    shift
  fi
  local -a targets=("$@")
  local configFile status=0
  configFile="$(resolve_config_file "$CONFIG_GLOBAL_RELPATH" "$CONFIG_LOCAL_RELPATH")" || status=$?
  if [[ $status -ne 0 ]]; then
    echo "Error: $(format_config_not_found "$status" "$CONFIG_GLOBAL_RELPATH" "$CONFIG_LOCAL_RELPATH")" >&2
    return "$EXIT_CONFIG_NOT_FOUND"
  fi

  local -a commonOpts=(--config "${configFile}" --no-banner --redact --verbose)
  if [[ $staged -eq 1 ]]; then
    betterleaks git --pre-commit --staged "${commonOpts[@]}"
  elif [[ ${#targets[@]} -eq 0 ]]; then
    betterleaks dir "${commonOpts[@]}" .
  else
    # BetterLeaks v1.0.0 `dir` scans only one path and falls back to "."
    # when given more, so scan each target separately and keep the first failure
    local target rc
    for target in "${targets[@]}"; do
      rc=0
      betterleaks dir "${commonOpts[@]}" "${target}" || rc=$?
      if [[ $status -eq 0 ]]; then
        status=$rc
      fi
    done
    return "$status"
  fi
}

if [[ ${BASH_SOURCE[0]} == "${0}"   ]]; then
  main "$@"
  exit $?
fi
