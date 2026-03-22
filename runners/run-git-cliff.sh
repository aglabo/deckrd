#!/usr/bin/env bash
# src: runners/run-git-cliff.sh
# @(#) : git-cliff runner (changelog / release notes generation)
#
# Copyright (c) 2026- atsushifx <https://github.com/atsushifx>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

set -euo pipefail

CLIFF_CONFIG="configs/cliff.toml"
OUTPUT_FILE="temp/temp.md"

# @description Return git-cliff options for the given mode
# @arg $1 string Mode (changelog|release-notes)
get_cliff_opts() {
  case "${1}" in
  changelog) echo "--unreleased" ;;
  release-notes) echo "--latest --strip header" ;;
  esac
}

# @description Run git-cliff with mode-specific options
# @arg $1 string Mode (changelog|release-notes)
# @arg $2 string Write flag (true|false)
# @exitcode 0 Success
# @exitcode 1 Error
run_cliff() {
  local mode="${1}"
  local write="${2:-false}"
  local opts
  opts=$(get_cliff_opts "${mode}")

  if [[ "${write}" == "true" ]]; then
    # shellcheck disable=SC2086
    git cliff --config "${CLIFF_CONFIG}" ${opts} --output "${OUTPUT_FILE}"
  else
    # shellcheck disable=SC2086
    git cliff --config "${CLIFF_CONFIG}" ${opts}
  fi
}

main() {
  local mode="changelog"
  local write="false"

  while [[ $# -gt 0 ]]; do
    case "${1}" in
    changelog | release-notes) mode="${1}" ;;
    --write) write="true" ;;
    *)
      echo "Usage: $0 [changelog|release-notes] [--write]" >&2
      exit 1
      ;;
    esac
    shift
  done

  run_cliff "${mode}" "${write}"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
