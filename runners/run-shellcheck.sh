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

# Directory names that find_shell_files skips at any depth below its start point.
# Add a name here to exclude another directory; nothing else needs editing.
readonly -a SHELLCHECK_EXCLUDE_DIRS=(
  .tools
  node_modules
)

#
# @description List the *.sh files under a directory, skipping every directory
#              below it whose name is in SHELLCHECK_EXCLUDE_DIRS. The start
#              directory itself is never skipped, even when its name matches
# @arg $1 string Directory to walk (the start point)
# @stdout Paths of the files found, each terminated by NUL
# @exitcode 0 on success, find's exit code otherwise
#
find_shell_files()
                  {
  local -a prune=()
  local name
  for name in "${SHELLCHECK_EXCLUDE_DIRS[@]}"; do
    prune+=(-o -name "$name")
  done
  # ${prune[@]:1} drops the leading -o, giving
  #   find <dir> -mindepth 1 \( -name .tools -o -name node_modules \) -prune -o -name '*.sh' -print0
  # -mindepth 1 keeps the test off <dir> itself, so a start point named like an excluded directory is still walked
  find "$1" -mindepth 1 \( "${prune[@]:1}" \) -prune -o -name '*.sh' -print0
}

# @description Run shellcheck on .sh files (spec files and node_modules/.tools are skipped).
#              The rc file is taken from --rcfile, then $SHELLCHECKRC, then the checked-in config,
#              then the global config
# @arg $@ string Options (--rcfile|-r <file>) followed by paths to check
# @stderr "Error: <not-found message>" when no rc file is found
# @exitcode 0 All checks passed, or no .sh files found
# @exitcode 1 Lint error or unknown option
# @exitcode 78 (EXIT_CONFIG_NOT_FOUND) Config file not found
main()
       {
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
        [[ $f == *.spec.sh ]] && continue
        files+=("$f")
      done < <(find_shell_files "$target")
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
