#!/usr/bin/env bash
# src: ./runners/run-shellcheck.sh
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

SHELLCHECKRC="${SHELLCHECKRC:-${SCRIPT_ROOT}/../configs/shellcheckrc}"

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
find_shell_files() {
  local -a prune=()
  local name
  for name in "${SHELLCHECK_EXCLUDE_DIRS[@]}"; do
    prune+=(-o -name "$name")
  done
  # ${prune[@]:1} drops the leading -o, giving
  #   find <dir> -mindepth 1 \( -name .tools -o -name node_modules \) -prune -o -name '*.sh' -print0
  # -mindepth 1 keeps the tests off <dir> itself, so a start point named like an excluded directory is still walked
  find "$1" -mindepth 1 \( "${prune[@]:1}" \) -prune -o -name '*.sh' -print0
}

main() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
    --rcfile | -r)
      SHELLCHECKRC="$2"
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
      done < <(find "$target" -mindepth 1 \( -name node_modules -o -name .tools \) -prune -o -name "*.sh" ! -name "*.spec.sh" -print0)
    elif [[ $target != *.spec.sh ]]; then
      files+=("$target")
    fi
  done
  if [[ ${#files[@]} -eq 0 ]]; then
    echo "No .sh files found." >&2
    return 0
  fi
  (shellcheck --rcfile="$SHELLCHECKRC" "${files[@]}")
}
if [[ ${BASH_SOURCE[0]} == "$0" ]]; then
  main "$@"
fi
