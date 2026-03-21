#!/usr/bin/env bash
# plugins/deckrd/skills/deckrd/scripts/libs/bootstrap.sh - Global directory variables for agent skills
#
# Copyright (c) 2026- atsushifx <https://github.com/atsushifx>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT
#
# @version 0.1.0
# USAGE: source this file, do NOT execute directly.
#   . "$(dirname "${BASH_SOURCE[0]}")/scripts/libs/bootstrap.sh"

# Guard: prevent re-sourcing
if [[ -n "${_BOOTSTRAP_LOADED:-}" ]]; then
  return 0
fi
readonly _BOOTSTRAP_LOADED=1

# PROJECT_ROOT: env var > git > BASH_SOURCE fallback
if [[ -z "${PROJECT_ROOT:-}" ]]; then
  PROJECT_ROOT="$(git rev-parse --show-toplevel 2>/dev/null ||
    (cd "$(dirname "${BASH_SOURCE[0]}")/../../../../.." && pwd))"
fi
export PROJECT_ROOT
readonly PROJECT_ROOT

# DECKRD_ROOT: root of the deckrd plugin skill
DECKRD_ROOT="${DECKRD_ROOT:-${PROJECT_ROOT}/plugins/deckrd/skills/deckrd}"
export DECKRD_ROOT
readonly DECKRD_ROOT

# DECKRD_SCRIPTS_DIR: deckrd scripts directory
DECKRD_SCRIPTS_DIR="${DECKRD_SCRIPTS_DIR:-${DECKRD_ROOT}/scripts}"
export DECKRD_SCRIPTS_DIR
readonly DECKRD_SCRIPTS_DIR

# DECKRD_LIB_DIR: deckrd library directory
DECKRD_LIB_DIR="${DECKRD_LIB_DIR:-${DECKRD_ROOT}/scripts/libs}"
export DECKRD_LIB_DIR
readonly DECKRD_LIB_DIR

# DECKRD_DATA_DIR: user-level deckrd data directory
DECKRD_DATA_DIR="${DECKRD_DATA_DIR:-${XDG_DATA_HOME:-${HOME}/.local/share}/deckrd}"
export DECKRD_DATA_DIR
readonly DECKRD_DATA_DIR

# DECKRD_LOCAL_DATA: project-local deckrd data directory
DECKRD_LOCAL_DATA="${DECKRD_LOCAL_DATA:-${PROJECT_ROOT}/.local/deckrd}"
export DECKRD_LOCAL_DATA

# DECKRD_DOCS_DIR: deckrd docs directory
DECKRD_DOCS_DIR="${DECKRD_DOCS_DIR:-${PROJECT_ROOT}/docs/.deckrd}"
export DECKRD_DOCS_DIR

# SYMBOL: valid character pattern for project names, namespaces, and domains
# Allowed: lowercase letters (a-z), hyphens (-), underscores (_)
# Usage: [[ "$value" =~ ^${SYMBOL}$ ]]  or  [[ "$path" =~ ^${SYMBOL}/${SYMBOL}$ ]]
# Mock support: define SYMBOL before sourcing this file to override.
if [[ -z "${SYMBOL:-}" ]]; then
  readonly SYMBOL='[a-z_-]+'
fi
export SYMBOL
