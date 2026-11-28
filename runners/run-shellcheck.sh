#!/usr/bin/env bash
# src: runners/run-shellcheck.sh
# @(#) : shellcheck runner
#
# Copyright (c) 2026- atsushifx <https://github.com/atsushifx>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

# shellcheck disable=SC1091

set -euo pipefail

# Initialize variables and change to the project root directory
. "$(dirname "${BASH_SOURCE[0]}")/libs/init-vars.lib.sh"
cd "${SCRIPT_ROOT}/.."

# load utility library
# shellcheck source=runners/libs/utils.lib.sh
. "${SCRIPT_ROOT}/libs/utils.lib.sh"

# Config file path relative to the global config directory
readonly CONFIG_GLOBAL_RELPATH='shellcheckrc'

# Config file path relative to PROJECT_ROOT
readonly CONFIG_LOCAL_RELPATH='configs/shellcheckrc'

# @description Run shellcheck on .sh files. Spec files are skipped. Directory scans also skip
#              node_modules, .tools, .local and temp directories at any depth.
#              The rc file is taken from --rcfile, then $SHELLCHECKRC, then the checked-in config,
#              then the global config
# @arg $@ string Options (--rcfile|-r <file>) followed by paths to check
# @stderr "Error: <not-found message>" when no rc file is found
# @exitcode 0 All checks passed, or no .sh files found
# @exitcode 1 Lint error or unknown option
# @exitcode 78 (EXIT_CONFIG_NOT_FOUND) Config file not found
main() {
  local rcfile="${SHELLCHECKRC:-}"
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --rcfile | -r)
        rcfile="$2"
        shift 2
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
  # Unit test spec files (*.spec.sh) are skipped, both in directory scans and when given explicitly
  local -a files=()
  for target in "${targets[@]}"; do
    if [[ -d $target ]]; then
      while IFS= read -r -d '' f; do
        files+=("$f")
      done < <(find "$target" -mindepth 1 -type d \( -name node_modules -o -name .tools -o -name .local -o -name temp \) -prune -o -name "*.sh" ! -name "*.spec.sh" -print0)
    elif [[ $target != *.spec.sh ]]; then
      files+=("$target")
    fi
  done
  if [[ ${#files[@]} -eq 0 ]]; then
    echo "No .sh files found." >&2
    return 0
  fi
  if [[ -z $rcfile   ]]; then
    local status=0
    rcfile="$(resolve_config_file "$CONFIG_GLOBAL_RELPATH" "$CONFIG_LOCAL_RELPATH")" || status=$?
    if [[ $status -ne 0 ]]; then
      echo "Error: $(format_config_not_found "$status" "$CONFIG_GLOBAL_RELPATH" "$CONFIG_LOCAL_RELPATH")" >&2
      return "$EXIT_CONFIG_NOT_FOUND"
    fi
  fi
  (shellcheck --rcfile="$rcfile" "${files[@]}")
}
if [[ ${BASH_SOURCE[0]} == "$0" ]]; then
  main "$@"
fi
