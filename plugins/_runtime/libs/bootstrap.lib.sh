#!/usr/bin/env bash
# plugins/_runtime/libs/bootstrap.lib.sh - Shared runtime bootstrap for deckrd plugins
#
# Copyright (c) 2026- aglabo <https://github.com/aglabo>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT
#
# @version 0.4.0
# USAGE: source this file, then call bootstrap_finalize to lock variables.
#   . "$(dirname "${BASH_SOURCE[0]}")/bootstrap.lib.sh"
#   bootstrap_finalize

# Guard: prevent re-sourcing
if [[ -n "${_BOOTSTRAP_LOADED:-}" ]]; then
  return 0
fi
readonly _BOOTSTRAP_LOADED=1

# _resolve_project_root - Resolve PROJECT_ROOT via git or BASH_SOURCE fallback
#
# Priority: env var (already set) > git rev-parse > BASH_SOURCE 3-levels-up
# BASH_SOURCE[0] is this file: plugins/_runtime/libs/bootstrap.lib.sh
# 3 levels up: libs/ -> _runtime/ -> plugins/ -> project root
#
# @stdout Resolved PROJECT_ROOT path
# @return 0 always
_resolve_project_root() {
  if [[ -n "${PROJECT_ROOT:-}" ]]; then
    printf '%s' "${PROJECT_ROOT}"
    return 0
  fi
  git rev-parse --show-toplevel 2>/dev/null ||
    (cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)
}

# _resolve_deckrd_root - Resolve DECKRD_ROOT from caller path
#
# Detects whether bootstrap was sourced from a deckrd-coder context.
# Falls back to deckrd plugin root otherwise.
#
# @arg $1 string caller_path  Path of the script that sourced bootstrap.lib.sh.
#                             Defaults to BASH_SOURCE[1] (the direct caller).
#                             Pass an explicit path in tests to isolate from runtime context.
# @arg $2 string project_root Resolved PROJECT_ROOT.
#                             Defaults to PROJECT_ROOT env var.
# @stdout Resolved DECKRD_ROOT path
# @return 0 always
_resolve_deckrd_root() {
  local caller_path="${1:-${BASH_SOURCE[1]:-}}"
  local project_root="${2:-${PROJECT_ROOT:-}}"

  if [[ "$caller_path" == */deckrd-coder/* ]]; then
    printf '%s' "${project_root}/plugins/deckrd-coder/skills/deckrd-coder"
  else
    printf '%s' "${project_root}/plugins/deckrd/skills/deckrd"
  fi
}

# bootstrap_init - Set all runtime variables (no readonly yet)
#
# Sets: PROJECT_ROOT, RUNTIME_LIB_DIR, DECKRD_ROOT, DECKRD_SCRIPTS_DIR,
#       DECKRD_LIB_DIR, DECKRD_DATA_DIR, DECKRD_LOCAL_DATA, DECKRD_DOCS_DIR, SYMBOL
# All variables respect pre-existing values (env var > computed default).
# Does NOT call readonly — call bootstrap_finalize() after to lock variables.
#
# @arg $1 string caller_path  Path of the script that sourced bootstrap.lib.sh.
#                             Captured at the call site (top-level BASH_SOURCE[1])
#                             and passed explicitly so tests can inject any path.
# @return 0 always
bootstrap_init() {
  local _caller_path="${1:-}"
  # PROJECT_ROOT: env var > git > BASH_SOURCE fallback
  if [[ -z "${PROJECT_ROOT:-}" ]]; then
    PROJECT_ROOT="$(_resolve_project_root)"
  fi
  export PROJECT_ROOT

  # RUNTIME_LIB_DIR: shared runtime libraries directory
  RUNTIME_LIB_DIR="${RUNTIME_LIB_DIR:-${PROJECT_ROOT}/plugins/_runtime/libs}"
  export RUNTIME_LIB_DIR

  # DECKRD_ROOT: root of the plugin skill — detected from caller path
  # _caller_path was captured at the top-level call site (BASH_SOURCE[1] there
  # correctly points to the script that sourced bootstrap.lib.sh).
  if [[ -z "${DECKRD_ROOT:-}" ]]; then
    DECKRD_ROOT="$(_resolve_deckrd_root "${_caller_path}" "${PROJECT_ROOT}")"
  fi
  export DECKRD_ROOT

  # DECKRD_SCRIPTS_DIR: deckrd scripts directory
  DECKRD_SCRIPTS_DIR="${DECKRD_SCRIPTS_DIR:-${DECKRD_ROOT}/scripts}"
  export DECKRD_SCRIPTS_DIR

  # DECKRD_LIB_DIR: deckrd library directory
  DECKRD_LIB_DIR="${DECKRD_LIB_DIR:-${DECKRD_ROOT}/scripts/libs}"
  export DECKRD_LIB_DIR

  # DECKRD_DATA_DIR: user-level deckrd data directory
  DECKRD_DATA_DIR="${DECKRD_DATA_DIR:-${XDG_DATA_HOME:-${HOME}/.local/share}/deckrd}"
  export DECKRD_DATA_DIR

  # DECKRD_LOCAL_DATA: project-local deckrd data directory
  DECKRD_LOCAL_DATA="${DECKRD_LOCAL_DATA:-${PROJECT_ROOT}/.local/deckrd}"
  export DECKRD_LOCAL_DATA

  # DECKRD_DOCS_DIR: deckrd docs directory
  DECKRD_DOCS_DIR="${DECKRD_DOCS_DIR:-${PROJECT_ROOT}/docs/.deckrd}"
  export DECKRD_DOCS_DIR

  # SYMBOL: valid character pattern for project names, namespaces, and domains
  # Allowed: lowercase letter start (a-z), followed by lowercase letters, hyphens (-), underscores (_)
  # Usage: [[ "$value" =~ ^${SYMBOL}$ ]]  or  [[ "$path" =~ ^${SYMBOL}/${SYMBOL}$ ]]
  # Mock support: define SYMBOL before sourcing this file to override.
  if [[ -z "${SYMBOL:-}" ]]; then
    SYMBOL='[a-z][a-z_-]*'
  fi
  export SYMBOL
}

# bootstrap_finalize - Lock all runtime variables as readonly
#
# Must be called after bootstrap_init().
# SYMBOL is locked unconditionally: if pre-set by the caller, it was already
# exported and will be made readonly here. If the caller needs a mutable SYMBOL,
# they must not pre-set it (use bootstrap_init's default) or override after
# sourcing. This makes the readonly contract consistent across all variables.
#
# @return 0 always
bootstrap_finalize() {
  readonly PROJECT_ROOT
  readonly RUNTIME_LIB_DIR
  readonly DECKRD_ROOT
  readonly DECKRD_SCRIPTS_DIR
  readonly DECKRD_LIB_DIR
  readonly DECKRD_DATA_DIR
  readonly DECKRD_LOCAL_DATA
  readonly DECKRD_DOCS_DIR
  readonly SYMBOL
}

# Auto-invocation: sourcing this file calls bootstrap_init and, by default,
# bootstrap_finalize to lock all variables.
#
# Pass "no-finalize" as an argument to skip finalize:
#   . bootstrap.lib.sh no-finalize   # init only — variables remain writable
#   . bootstrap.lib.sh               # init + finalize — variables locked
#
# BASH_SOURCE[1] is captured here at the top level of bootstrap.lib.sh, where
# it correctly points to the script that sourced this file.
_bootstrap_caller="${BASH_SOURCE[1]:-}"
bootstrap_init "${_bootstrap_caller}"
if [[ "${1:-}" != "no-finalize" ]]; then
  bootstrap_finalize
fi
unset _bootstrap_caller
