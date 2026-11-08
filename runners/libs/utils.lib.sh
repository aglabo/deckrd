#!/usr/bin/env bash
# src: runners/libs/utils.lib.sh
# @(#): utils.lib.sh: common utility library
#
# Copyright (c) 2026- atsushifx <https://github.com/atsushifx>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

# Guard against double sourcing
[[ -n "${_UTILS_LIB_SH:-}" ]] && return 0
readonly _UTILS_LIB_SH=1

# Exit code returned by runners when no config file is found (EX_CONFIG, the BSD configuration error code)
# shellcheck disable=SC2034 # read by the runner scripts that source this file
readonly EXIT_CONFIG_NOT_FOUND=78

# Directory under the user config directory holding the user-shared config repository
readonly GLOBAL_CONFIGS_DIRNAME='global-configs'

#
# @description List the global (user-shared) config directory candidates in lookup order:
#              ${XDG_CONFIG_HOME}/global-configs when XDG_CONFIG_HOME is set,
#              then ${HOME}/.config/global-configs when HOME is set
# @stdout Candidate directories, one per line; nothing when neither variable is set
# @exitcode 0 Always
#
_global_configdir_candidates() {
  if [[ -n "${XDG_CONFIG_HOME:-}" ]]; then
    echo "${XDG_CONFIG_HOME}/${GLOBAL_CONFIGS_DIRNAME}"
  fi
  if [[ -n "${HOME:-}" ]]; then
    echo "${HOME}/.config/${GLOBAL_CONFIGS_DIRNAME}"
  fi
}

#
# @description Resolve the global (user-shared) config directory.
#              Use ${XDG_CONFIG_HOME}/global-configs when it exists,
#              otherwise fall back to ${HOME}/.config/global-configs when it exists
# @stdout Path to the config directory; nothing when no directory exists
# @exitcode 0 Config directory found
# @exitcode 1 Config directory not found
#
resolve_global_configdir() {
  local __candidate

  while IFS= read -r __candidate; do
    if [[ -d "$__candidate" ]]; then
      echo "$__candidate"
      return 0
    fi
  done < <(_global_configdir_candidates)
  return 1
}

#
# @description Resolve a tool config file.
#              Use the local config file in the project when it exists,
#              otherwise use the file under the first global config directory candidate holding it.
#              Prints nothing when no file is found
# @arg $1 string Config file path relative to the global config directory
# @arg $2 string Local config file path relative to PROJECT_ROOT
# @stdout Path to the config file; nothing when no file is found
# @exitcode 0 Config file found
# @exitcode 1 No global config directory exists (and no local config)
# @exitcode 2 Global config directories exist but none holds the config file
#
resolve_config_file() {
  local __global_relpath="$1"
  local __local_config="${PROJECT_ROOT}/$2"
  local __candidate
  local __status=1

  if [[ -f "$__local_config" ]]; then
    echo "$__local_config"
    return 0
  fi

  while IFS= read -r __candidate; do
    [[ -d "$__candidate" ]] || continue
    if [[ -f "${__candidate}/${__global_relpath}" ]]; then
      echo "${__candidate}/${__global_relpath}"
      return 0
    fi
    __status=2
  done < <(_global_configdir_candidates)
  return "$__status"
}

#
# @description Format the not-found message for a config file resolved by resolve_config_file().
#              Lists the local config path and, depending on the status, the global config file
#              candidates or the global-configs directory candidates
# @arg $1 int Exit status of resolve_config_file (1: no global config directory, 2: directories lack the file)
# @arg $2 string Config file path relative to the global config directory
# @arg $3 string Local config file path relative to PROJECT_ROOT
# @stdout The not-found message
# @exitcode 0 Always
#
format_config_not_found() {
  local __status="$1"
  local __global_relpath="$2"
  local __local_config="${PROJECT_ROOT:-}/$3"
  local __candidates=''
  local __candidate
  local __global_desc

  while IFS= read -r __candidate; do
    [[ "$__status" == 1 ]] || __candidate="${__candidate}/${__global_relpath}"
    __candidates="${__candidates:+${__candidates}, }${__candidate}"
  done < <(_global_configdir_candidates)

  if [[ "$__status" == 1 ]]; then
    __global_desc="no global-configs directory${__candidates:+: ${__candidates}}"
  else
    __global_desc="${__candidates:-no global-configs directory}"
  fi

  echo "config file not found: ${__local_config} (local), ${__global_desc} (global)"
}
