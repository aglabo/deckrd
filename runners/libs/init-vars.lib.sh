#!/usr/bin/env bash
# init-vars.lib.sh — common runner variable initialization library
# Provides SCRIPT_ROOT and PROJECT_ROOT for all runner scripts
#
# Copyright (c) 2026- atsushifx <https://github.com/atsushifx>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

# Guard against double sourcing
[[ -n "${_INIT_VARS_LIB_SH:-}" ]] && return 0
readonly _INIT_VARS_LIB_SH=1

# SCRIPT_ROOT: directory of the runner script that sourced this file
# BASH_SOURCE[1] refers to the caller's script path when this file is sourced
# shellcheck disable=SC2034 # read by the runner scripts that source this file
SCRIPT_ROOT="$(cd "$(dirname "${BASH_SOURCE[1]}")" && pwd)"

# PROJECT_ROOT: git repository root, or this file's own grandparent as fallback
# This lib lives in <project>/runners/libs/, so two levels up is the project root.
# Deriving it from SCRIPT_ROOT instead would assume every caller sits directly
# under <project>/runners/, which breaks for callers such as runners/exec/.
# The subshell is required: without it `||` would bind to `cd` alone and `pwd`
# would always run, appending a second line when git succeeds.
PROJECT_ROOT="${PROJECT_ROOT:-$(git rev-parse --show-toplevel 2>/dev/null || (cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd) )}"
