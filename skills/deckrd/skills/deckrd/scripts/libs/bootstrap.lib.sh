#!/usr/bin/env bash
# skills/deckrd/skills/deckrd/scripts/libs/bootstrap.lib.sh - Shared runtime bootstrap for deckrd plugins
#
# Copyright (c) 2026- aglabo <https://github.com/aglabo>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT
#
# @version 0.5.1
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
# Priority: env var (already set) > git rev-parse > BASH_SOURCE 6-levels-up
# BASH_SOURCE[0] is this file: skills/deckrd/skills/deckrd/scripts/libs/bootstrap.lib.sh
# 6 levels up: libs/ -> scripts/ -> deckrd/ -> skills/ -> deckrd/ -> skills/ -> project root
#
# @stdout Resolved PROJECT_ROOT path
# @return 0 always
_resolve_project_root() {
  if [[ -n "${PROJECT_ROOT:-}" ]]; then
    printf '%s' "${PROJECT_ROOT}"
    return 0
  fi
  git rev-parse --show-toplevel 2>/dev/null ||
    (CDPATH='' cd -- "$(dirname "${BASH_SOURCE[0]}")/../../../../../.." && pwd)
}

# _resolve_deckrd_root - Resolve the deckrd skill root relative to this file's location
#
# Always resolves to the deckrd skill root, regardless of the caller's path.
# Resolution is relative to BASH_SOURCE[0] (this file), independent of PROJECT_ROOT.
#
# BASH_SOURCE[0] path: .../skills/deckrd/skills/deckrd/scripts/libs/bootstrap.lib.sh
# dirname -> .../skills/deckrd/skills/deckrd/scripts/libs/
# ../..   -> .../skills/deckrd/skills/deckrd/ (= SKILL_ROOT)
#
# @stdout Resolved skill root path (used for SKILL_ROOT and DECKRD_ROOT)
# @return 0 always
_resolve_deckrd_root() {
  local _skills_dir
  # CDPATH is cleared so cd prints nothing into the captured path
  _skills_dir="$(CDPATH='' cd -- "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

  printf '%s' "${_skills_dir}"
}

# bootstrap_init - Set all runtime variables (no readonly yet)
#
# Sets: PROJECT_ROOT, SKILL_ROOT, DECKRD_ROOT, DECKRD_SCRIPTS_DIR,
#       DECKRD_ASSETS_DIR, DECKRD_LIB_DIR, DECKRD_DATA_DIR, DECKRD_LOCAL_DATA,
#       DECKRD_LOCAL_WORKSPACES, DECKRD_LOCAL_TEMP, DECKRD_DOCS_DIR, SYMBOL
# All variables except SKILL_ROOT respect pre-existing values
# (env var > computed default); SKILL_ROOT is always computed.
# Exported: PROJECT_ROOT, DECKRD_DATA_DIR, DECKRD_LOCAL_DATA,
#   DECKRD_LOCAL_WORKSPACES, DECKRD_LOCAL_TEMP, DECKRD_DOCS_DIR, SYMBOL
#   (project-dependent).
# Not exported: SKILL_ROOT, and computed values of DECKRD_ROOT,
#   DECKRD_SCRIPTS_DIR, DECKRD_ASSETS_DIR, DECKRD_LIB_DIR (skill-dependent);
#   a non-empty value of these four exported by the caller keeps its export.
# Does NOT call readonly; call bootstrap_finalize() after to lock variables.
#
# @return 0 on success, 1 if a readonly SKILL_ROOT differs from the computed value
bootstrap_init() {
  # PROJECT_ROOT: env var > git > BASH_SOURCE fallback
  if [[ -z "${PROJECT_ROOT:-}" ]]; then
    PROJECT_ROOT="$(_resolve_project_root)"
  fi
  export PROJECT_ROOT

  # SKILL_ROOT: root of the skill that sourced this library - always computed
  # Computed from BASH_SOURCE of this file (independent of PROJECT_ROOT and the
  # caller path); relies on the layout <SKILL_ROOT>/scripts/libs/*.lib.sh.
  # Skills share this library through links, so a value inherited from a parent
  # process may belong to another skill: any pre-set value is ignored, and the
  # variable is not exported (export -n also drops an inherited export, and
  # works on readonly variables).
  # A readonly SKILL_ROOT is accepted only when it equals the computed value;
  # a mismatch fails fast (a readonly assignment error would abort the caller's
  # whole command without a usable status, so it is checked up front).
  # Resolved before DECKRD_ROOT.
  local _skill_root
  _skill_root="$(_resolve_deckrd_root)"
  if [[ "${SKILL_ROOT:-}" != "${_skill_root}" ]]; then
    if [[ "$(declare -p SKILL_ROOT 2>/dev/null)" =~ ^declare\ -[a-zA-Z]*r ]]; then
      printf 'bootstrap.lib.sh: SKILL_ROOT: readonly variable (%s, expected %s)\n' \
        "${SKILL_ROOT}" "${_skill_root}" >&2
      return 1
    fi
    SKILL_ROOT="${_skill_root}"
  fi
  export -n SKILL_ROOT

  # DECKRD_ROOT: root of the deckrd skill - env var > SKILL_ROOT
  # Kept for compatibility: when unset (or empty) it takes the computed
  # SKILL_ROOT; a pre-set DECKRD_ROOT flows into the DECKRD_* skill directories
  # below. Setting DECKRD_ROOT never changes SKILL_ROOT.
  # DECKRD_ROOT, DECKRD_SCRIPTS_DIR, DECKRD_ASSETS_DIR and DECKRD_LIB_DIR are
  # skill-dependent: computed values are not exported, so a child process that
  # sources another skill's linked copy of this library computes its own.
  # Explicit env overrides are honored and keep their export (no export -n).
  # An empty value is not an override: it is replaced by the default and unexported.
  if [[ -z "${DECKRD_ROOT:-}" ]]; then
    DECKRD_ROOT="${SKILL_ROOT}"
    export -n DECKRD_ROOT
  fi

  # DECKRD_SCRIPTS_DIR: deckrd scripts directory
  if [[ -z "${DECKRD_SCRIPTS_DIR:-}" ]]; then
    DECKRD_SCRIPTS_DIR="${DECKRD_ROOT}/scripts"
    export -n DECKRD_SCRIPTS_DIR
  fi

  # DECKRD_ASSETS_DIR: deckrd assets directory
  if [[ -z "${DECKRD_ASSETS_DIR:-}" ]]; then
    DECKRD_ASSETS_DIR="${DECKRD_ROOT}/assets"
    export -n DECKRD_ASSETS_DIR
  fi

  # DECKRD_LIB_DIR: deckrd library directory
  if [[ -z "${DECKRD_LIB_DIR:-}" ]]; then
    DECKRD_LIB_DIR="${DECKRD_ROOT}/scripts/libs"
    export -n DECKRD_LIB_DIR
  fi

  # DECKRD_DATA_DIR: user-level deckrd data directory
  DECKRD_DATA_DIR="${DECKRD_DATA_DIR:-${XDG_DATA_HOME:-${HOME}/.local/share}/deckrd}"
  export DECKRD_DATA_DIR

  # DECKRD_LOCAL_DATA: project-local deckrd data directory
  DECKRD_LOCAL_DATA="${DECKRD_LOCAL_DATA:-${PROJECT_ROOT}/.local/deckrd}"
  export DECKRD_LOCAL_DATA

  # DECKRD_LOCAL_WORKSPACES: project-local deckrd shared working directory
  DECKRD_LOCAL_WORKSPACES="${DECKRD_LOCAL_WORKSPACES:-${DECKRD_LOCAL_DATA}/workspaces}"
  export DECKRD_LOCAL_WORKSPACES

  # DECKRD_LOCAL_TEMP: project-local deckrd temporary working directory
  DECKRD_LOCAL_TEMP="${DECKRD_LOCAL_TEMP:-${DECKRD_LOCAL_DATA}/temp}"
  export DECKRD_LOCAL_TEMP

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
  readonly SKILL_ROOT
  readonly DECKRD_ROOT
  readonly DECKRD_SCRIPTS_DIR
  readonly DECKRD_ASSETS_DIR
  readonly DECKRD_LIB_DIR
  readonly DECKRD_DATA_DIR
  readonly DECKRD_LOCAL_DATA
  readonly DECKRD_LOCAL_WORKSPACES
  readonly DECKRD_LOCAL_TEMP
  readonly DECKRD_DOCS_DIR
  readonly SYMBOL
}

# Auto-invocation: sourcing this file calls bootstrap_init and, by default,
# bootstrap_finalize to lock all variables.
#
# Pass "no-finalize" as an argument to skip finalize:
#   . bootstrap.lib.sh no-finalize   # init only - variables remain writable
#   . bootstrap.lib.sh               # init + finalize - variables locked
bootstrap_init || return 1
if [[ "${1:-}" != "--no-finalize" ]]; then
  bootstrap_finalize
fi
