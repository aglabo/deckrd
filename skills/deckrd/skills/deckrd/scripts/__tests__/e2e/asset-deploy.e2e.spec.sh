#!/usr/bin/env bash
# skills/deckrd/skills/deckrd/scripts/__tests__/e2e/asset-deploy.e2e.spec.sh
# @(#) : E2E tests for init.sh / update.sh - deploy the real assets into a non-git PROJECT_ROOT
#
# Copyright (c) 2026- atsushifx <https://github.com/atsushifx>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

# cspell:words Unsets cksum

# shellcheck disable=SC1090

# ---- test base ----
_RUNTIME_BOOTSTRAP="${SHELLSPEC_PROJECT_ROOT}/skills/deckrd/skills/deckrd/scripts/libs/bootstrap.lib.sh"
. "$_RUNTIME_BOOTSTRAP" "--no-finalize"
unset _RUNTIME_BOOTSTRAP

# ---- test target ----
INIT_SCRIPT="${DECKRD_SCRIPTS_DIR}/init.sh"
UPDATE_SCRIPT="${DECKRD_SCRIPTS_DIR}/update.sh"

# ---- helpers ----
Include ../spec_helper.sh

# ---- internal helpers ----

# 定数

# _E2E_OVERRIDE_VARS - Path overrides that would redirect the scripts away from PROJECT_ROOT
#
# bootstrap.lib.sh (`--no-finalize`) exported repository paths for some of them; any one left
# set makes init.sh / update.sh write into the real repository instead of the e2e project.
# GIT_DIR / GIT_WORK_TREE are listed so that the non-git precondition holds.
# PROJECT_FILE / SESSION_FILE / DECKRD_* roots are listed because the scripts honor an inherited
# value (`${VAR:-default}`); unsetting DECKRD_SCRIPTS_DIR is safe because INIT_SCRIPT and
# UPDATE_SCRIPT are computed at file top level, before any hook runs.
_E2E_OVERRIDE_VARS=(
  PROJECT_FILE SESSION_FILE
  DECKRD_ROOT DECKRD_ASSETS_DIR DECKRD_SCRIPTS_DIR
  DECKRD_DOCS_DIR DECKRD_LOCAL DECKRD_LOCAL_DATA DECKRD_LOCAL_TEMP DECKRD_LOCAL_WORKSPACES
  CLAUDE_RULES_DIR CLAUDE_RULES_INDEX_DIR
  INITS_DIR RULES_INDEX_SRC_DIR CLAUDE_RULES_SRC_DIR DOCS_SRC_DIR LOCAL_SRC_DIR
  GIT_DIR GIT_WORK_TREE
)

# _WORKFLOW_REL - Representative asset: the workflow rule, relative to the docs target
# (source `inits/docs/<rel>`, deployed `docs/.deckrd/<rel>`)
_WORKFLOW_REL='rules/deckrd-rule-workflow.md'

# _UPDATE_WORKFLOW_MSG - stdout line of update.sh --update for a (re)deployed workflow rule
_UPDATE_WORKFLOW_MSG="Updated: [docs] ${_WORKFLOW_REL}"

# _INIT_WORKFLOW_MSG - stderr line of init.sh for a copied workflow rule (re-copied only with --force)
_INIT_WORKFLOW_MSG="[init/docs] copied: ${_WORKFLOW_REL}"

# _USER_EDIT - Content a user writes over a deployed file
_USER_EDIT='user-edit'

# _GITIGNORE_PAIRS - Table data: each deployed .gitignore and the .org source it is deployed from
#
# One row per space-separated `<deployed path relative to PROJECT_ROOT>:<source path relative to inits/>`.
# A `%const` because Parameters:dynamic is also evaluated at translation time, where functions
# and plain variables of this file do not exist yet.
%const _GITIGNORE_PAIRS: docs/.deckrd/.gitignore:docs/.gitignore.org docs/.deckrd/rules/.gitignore:docs/rules/.gitignore.org .local/deckrd/.gitignore:local-deckrd/.gitignore.org

# _E2E_SKILL_DIR - The deckrd skill root that holds the scripts under test
# (DECKRD_ROOT is unset by _setup_e2e_project, so it is derived from INIT_SCRIPT here)
_E2E_SKILL_DIR="$(dirname "$(dirname "$INIT_SCRIPT")")"

# _DECOY_OVERRIDES - Test data: `<name>=<value>` decoys for the path overrides that
# _setup_e2e_project must unset (a value that leaks shows up as a write to /nonexistent)
_DECOY_OVERRIDES=(
  PROJECT_FILE=/nonexistent/decoy/.project.json
  SESSION_FILE=/nonexistent/decoy/session.json
  DECKRD_ROOT=/nonexistent/decoy
  DECKRD_ASSETS_DIR=/nonexistent/decoy/assets
  DECKRD_SCRIPTS_DIR=/nonexistent/decoy/scripts
)

# 関数

# _setup_e2e_project - Create an empty non-git project directory and point PROJECT_ROOT at it
#
# Unsets every _E2E_OVERRIDE_VARS entry so that the scripts derive all paths from PROJECT_ROOT.
# The previous PROJECT_ROOT is saved for _teardown_e2e_project.
#
# @set E2E_PROJECT_DIR The created project directory
# @set PROJECT_ROOT Exported as E2E_PROJECT_DIR
# @set _E2E_SAVED_PROJECT_ROOT The PROJECT_ROOT value before the call
_setup_e2e_project() {
  E2E_PROJECT_DIR="$(mktemp -d)"
  unset "${_E2E_OVERRIDE_VARS[@]}"
  _E2E_SAVED_PROJECT_ROOT="${PROJECT_ROOT:-}"
  export PROJECT_ROOT="$E2E_PROJECT_DIR"
}

# _teardown_e2e_project - Remove the project directory and undo _setup_e2e_project
#
# Restores the saved PROJECT_ROOT (or unsets it when there was none) and unsets every
# _E2E_OVERRIDE_VARS entry again, so no e2e path leaks into later examples.
_teardown_e2e_project() {
  [[ -n "${E2E_PROJECT_DIR:-}" && -d "$E2E_PROJECT_DIR" ]] && rm -rf "$E2E_PROJECT_DIR"
  if [[ -n "${_E2E_SAVED_PROJECT_ROOT:-}" ]]; then
    export PROJECT_ROOT="$_E2E_SAVED_PROJECT_ROOT"
  else
    unset PROJECT_ROOT
  fi
  unset "${_E2E_OVERRIDE_VARS[@]}"
  unset E2E_PROJECT_DIR _E2E_SAVED_PROJECT_ROOT
}

# _overrides_left_after_setup - Report which decoy path overrides survive _setup_e2e_project
#
# Exports every _DECOY_OVERRIDES entry, calls _setup_e2e_project again, and removes the extra
# project directory that this second setup created. Run it with `When run` (subshell).
#
# @stdout Name of every decoy variable that is still set, one per line (blank when none)
_overrides_left_after_setup() {
  local entry
  for entry in "${_DECOY_OVERRIDES[@]}"; do
    export "${entry?}"
  done
  _setup_e2e_project
  rm -rf "$E2E_PROJECT_DIR"
  for entry in "${_DECOY_OVERRIDES[@]}"; do
    [[ -v "${entry%%=*}" ]] && printf '%s\n' "${entry%%=*}"
  done
  return 0
}

# _cwd_kept_after_run_in_project - Check that _run_in_project does not move the caller
#
# @return 0 if PWD is the same before and after `_run_in_project "$INIT_SCRIPT" --help` and is
#   not PROJECT_ROOT, 1 otherwise
_cwd_kept_after_run_in_project() {
  local before="$PWD"
  _run_in_project "$INIT_SCRIPT" --help >/dev/null 2>&1
  [[ "$PWD" == "$before" && "$PWD" != "$PROJECT_ROOT" ]]
}

# _run_in_project - Run a script with bash from inside PROJECT_ROOT
#
# Runs in a subshell so the caller's cwd never changes: a Before hook that entered
# PROJECT_ROOT would otherwise leave the shell inside the directory its After hook removes.
#
# @arg $1 Script path
# @arg $@ Script arguments
# @stdout / @stderr Whatever the script prints
# @return Exit status of the script (1 when PROJECT_ROOT cannot be entered)
_run_in_project() {
  (cd "$PROJECT_ROOT" && bash "$@")
}

# _run_in_cwd_without_project_root - Run a script with bash from E2E_PROJECT_DIR, PROJECT_ROOT unset
#
# Runs in a subshell. GIT_CEILING_DIRECTORIES stops git at the parent of E2E_PROJECT_DIR, so the
# cwd stays a non-git directory and the script has to resolve PROJECT_ROOT by itself.
#
# @arg $1 Script path
# @arg $@ Script arguments
# @stdout / @stderr Whatever the script prints
# @return Exit status of the script (1 when E2E_PROJECT_DIR cannot be entered)
_run_in_cwd_without_project_root() {
  (
    cd "$E2E_PROJECT_DIR" || exit 1
    unset PROJECT_ROOT
    export GIT_CEILING_DIRECTORIES="${E2E_PROJECT_DIR%/*}"
    bash "$@"
  )
}

# _fingerprint_skill_copy - Print a content-aware fingerprint of the whole private copy tree
#
# Covers everything under _E2E_SKILL_COPY_ROOT, so the levels above the skill are watched too
# (the old bootstrap fallback resolved PROJECT_ROOT 6 levels above bootstrap.lib.sh, which is
# that root). Non-regular entries are listed by type, path and link target; regular files by
# cksum, so a rewritten file is caught whatever its mtime and no mtime makes a false change.
#
# @stdout One line per entry, sorted with LC_ALL=C
# @return 0 on success, non-zero when the root cannot be entered or find / cksum fails
_fingerprint_skill_copy() {
  (
    set -o pipefail
    cd "$_E2E_SKILL_COPY_ROOT" &&
      {
        # Portable to BSD find (no -printf): `<type> <path> [link target]` per entry
        find . ! -type f -exec sh -c '
          for p do
            if [ -L "$p" ]; then printf "l %s %s\n" "$p" "$(readlink "$p")"
            elif [ -d "$p" ]; then printf "d %s\n" "$p"
            else printf "o %s\n" "$p"
            fi
          done' sh {} + &&
          find . -type f -exec cksum {} +
      } | LC_ALL=C sort
  )
}

# _create_skill_copy - Copy the skill into a temp root and snapshot its fingerprint (Before hook)
#
# The copy sits at the repository-equivalent depth `<root>/skills/deckrd/skills/deckrd`, so the
# copy's bootstrap.lib.sh sees the same layout as in the repository and its 6-levels-up fallback
# lands on <root>, inside the watched tree. The snapshot is kept beside <root>, outside of it.
#
# @set _E2E_SKILL_COPY_TMP The temp directory holding <root> and the snapshot
# @set _E2E_SKILL_COPY_ROOT The watched root (`${_E2E_SKILL_COPY_TMP}/root`)
# @set _E2E_SKILL_COPY The skill copy (`${_E2E_SKILL_COPY_ROOT}/skills/deckrd/skills/deckrd`)
# @set _E2E_SKILL_COPY_SNAPSHOT The file holding the _fingerprint_skill_copy output
# @return 0 on success, non-zero when the copy or the snapshot cannot be made
_create_skill_copy() {
  _E2E_SKILL_COPY_TMP="$(mktemp -d)" &&
    _E2E_SKILL_COPY_ROOT="${_E2E_SKILL_COPY_TMP}/root" &&
    _E2E_SKILL_COPY="${_E2E_SKILL_COPY_ROOT}/skills/deckrd/skills/deckrd" &&
    _E2E_SKILL_COPY_SNAPSHOT="${_E2E_SKILL_COPY_TMP}/snapshot" &&
    mkdir -p "${_E2E_SKILL_COPY%/*}" &&
    cp -R "$_E2E_SKILL_DIR" "$_E2E_SKILL_COPY" &&
    _fingerprint_skill_copy >"$_E2E_SKILL_COPY_SNAPSHOT"
}

# _remove_skill_copy - Remove the temp directory made by _create_skill_copy (After hook)
_remove_skill_copy() {
  [[ -n "${_E2E_SKILL_COPY_TMP:-}" && -d "$_E2E_SKILL_COPY_TMP" ]] && rm -rf "$_E2E_SKILL_COPY_TMP"
  unset _E2E_SKILL_COPY_TMP _E2E_SKILL_COPY_ROOT _E2E_SKILL_COPY _E2E_SKILL_COPY_SNAPSHOT
}

# _skill_copy_unchanged - Check that the private copy tree still matches the snapshot
#
# Requires _create_skill_copy to have run first.
#
# @stdout diff of the snapshot against the current fingerprint (nothing when the check passes)
# @return 0 if the fingerprint succeeds and equals the snapshot, non-zero otherwise
_skill_copy_unchanged() {
  local current
  current="$(_fingerprint_skill_copy)" || return 1
  diff "$_E2E_SKILL_COPY_SNAPSHOT" - <<<"$current"
}

# _skill_copy_unchanged_after_rewrite - Rewrite the copy's workflow rule asset, then run _skill_copy_unchanged
#
# Changes the content of an existing file only (no path is added or removed), to check that
# _skill_copy_unchanged catches a content change. Run it with `When run` (subshell).
#
# @stdout / @return Those of _skill_copy_unchanged
_skill_copy_unchanged_after_rewrite() {
  printf 'changed\n' >"${_E2E_SKILL_COPY}/assets/inits/docs/${_WORKFLOW_REL}"
  _skill_copy_unchanged
}

# _e2e_symlink_unsupported - Report whether this host cannot create a symlink to a directory
#
# Keeps the negation inside the function so that `Skip if` works.
#
# @return 0 if a directory symlink cannot be created, 1 if it can
_e2e_symlink_unsupported() {
  local probe_dir rc=1
  probe_dir="$(mktemp -d)" || return 0
  { mkdir "${probe_dir}/target" &&
    MSYS=winsymlinks:nativestrict ln -s "${probe_dir}/target" "${probe_dir}/link" 2>/dev/null &&
    [[ -L "${probe_dir}/link" ]]; } || rc=0
  rm -rf "$probe_dir"
  return "$rc"
}

# _link_rules_to_asset_copy - Point docs/.deckrd/rules at the rules source of a temp asset copy
#
# Copies the real inits/ into a new temp directory, exports INITS_DIR at the copy, and links
# `docs/.deckrd/rules` to the copy's `docs/rules`, so a self-deploy can only damage the copy
# (never the repository's asset tree). Fails instead of falling back to a copy when no link
# is created. Runs after _setup_e2e_project, which unsets INITS_DIR.
#
# @set _E2E_ASSET_COPY_DIR The temp directory holding the asset copy
# @set INITS_DIR Exported as `${_E2E_ASSET_COPY_DIR}/inits`
# @return 0 on success, non-zero when the copy or the link cannot be created
_link_rules_to_asset_copy() {
  local link="${PROJECT_ROOT}/docs/.deckrd/rules"
  _E2E_ASSET_COPY_DIR="$(mktemp -d)" &&
    cp -R "${ASSETS_DIR}/inits" "${_E2E_ASSET_COPY_DIR}/" &&
    export INITS_DIR="${_E2E_ASSET_COPY_DIR}/inits" &&
    mkdir -p "${link%/*}" &&
    MSYS=winsymlinks:nativestrict ln -s "${INITS_DIR}/docs/rules" "$link" &&
    [[ -L "$link" ]]
}

# _remove_asset_copy - Remove the temp asset copy made by _link_rules_to_asset_copy (After hook)
_remove_asset_copy() {
  [[ -n "${_E2E_ASSET_COPY_DIR:-}" && -d "$_E2E_ASSET_COPY_DIR" ]] && rm -rf "$_E2E_ASSET_COPY_DIR"
  unset _E2E_ASSET_COPY_DIR
}

# _init_project - Run init.sh in PROJECT_ROOT silently (Before hook for an initialized project)
#
# @return Exit status of init.sh
_init_project() {
  _run_in_project "$INIT_SCRIPT" myapp webapp >/dev/null 2>&1
}

# _same_as_source - Report whether a deployed file is byte-identical to its asset source
#
# @arg $1 Deployed path relative to PROJECT_ROOT (e.g. `docs/.deckrd/rules/a.md`)
# @arg $2 Source path relative to inits/ (e.g. `docs/rules/a.md`)
# @return 0 if both files exist and are identical, 1 otherwise
_same_as_source() {
  cmp -s "${PROJECT_ROOT}/$1" "${ASSETS_DIR}/inits/$2"
}

# _write_deployed - Overwrite a file deployed under docs/.deckrd and set its mtime
#
# The content is written before touch so that the given mtime is not reset.
#
# @arg $1 Path relative to docs/.deckrd (e.g. `rules/.gitignore`)
# @arg $2 Content to write (one line)
# @arg $3 mtime passed to `touch -d`
_write_deployed() {
  local dest="${PROJECT_ROOT}/docs/.deckrd/$1"
  printf '%s\n' "$2" >"$dest"
  touch -d "$3" "$dest"
}

# _make_workflow_outdated - Make the deployed workflow rule older than (2000-01-01) and different from its source
_make_workflow_outdated() {
  _write_deployed "$_WORKFLOW_REL" old '2000-01-01'
}

# _delete_workflow - Remove the deployed workflow rule
_delete_workflow() {
  rm -f "${PROJECT_ROOT}/docs/.deckrd/${_WORKFLOW_REL}"
}

# _edit_rules_gitignore_old - Replace the deployed rules/.gitignore with a user edit older than its source (2000-01-01)
_edit_rules_gitignore_old() {
  _write_deployed rules/.gitignore "$_USER_EDIT" '2000-01-01'
}

# _edit_workflow_newer - Replace the deployed workflow rule with a user edit newer than its source (2099-01-01)
_edit_workflow_newer() {
  _write_deployed "$_WORKFLOW_REL" "$_USER_EDIT" '2099-01-01'
}

# ---- test body ----

Describe "init.sh / update.sh asset deploy (e2e)"
  Describe "T-CLI-DEPE: asset deploy into a non-git PROJECT_ROOT"
    Before "_setup_e2e_project"
    After "_teardown_e2e_project"

    Describe "When: 正常系"
      It "[Normal] T-CLI-DEPE-01: Should: fail git rev-parse inside PROJECT_ROOT (not a git repository)"
        When run git -C "$PROJECT_ROOT" rev-parse --show-toplevel
        The status should be failure
        The stderr should be present
      End

      It "[Normal] T-CLI-DEPE-02: Should: exit 0 and deploy the workflow rule, rules index and session.json"
        When run _run_in_project "$INIT_SCRIPT" myapp webapp
        The status should equal 0
        The stderr should include "Init complete."
        The path "${PROJECT_ROOT}/docs/.deckrd/${_WORKFLOW_REL}" should be file
        The path "${PROJECT_ROOT}/.claude/rules/deckrd-rules/deckrd-rules-index.md" should be file
        The path "${PROJECT_ROOT}/.local/deckrd/session.json" should be file
      End

      It "[Normal] T-CLI-DEPE-11: Should: unset PROJECT_FILE, SESSION_FILE, DECKRD_ROOT, DECKRD_ASSETS_DIR and DECKRD_SCRIPTS_DIR in _setup_e2e_project"
        When run _overrides_left_after_setup
        The status should equal 0
        The output should be blank
      End

      It "[Normal] T-CLI-DEPE-12: Should: keep the caller's working directory after _run_in_project"
        When run _cwd_kept_after_run_in_project
        The status should be success
      End

      Describe "Given: a private copy of the skill and its snapshot"
        Before "_create_skill_copy"
        After "_remove_skill_copy"

        # DEPE-13 runs the copy's init.sh, not INIT_SCRIPT: the real skill directory is shared with
        # the specs running concurrently under `--jobs 4`, so a snapshot of it can change for
        # reasons unrelated to this example. The copy's watched root also spans the levels above
        # the skill, where the old bootstrap fallback (6 levels above bootstrap.lib.sh) deployed.
        Describe "Given: PROJECT_ROOT is unset and the current directory is a non-git project"
          It "[Normal] T-CLI-DEPE-13: Should: deploy into the current directory, not the skill, when PROJECT_ROOT is unset"
            When run _run_in_cwd_without_project_root "${_E2E_SKILL_COPY}/scripts/init.sh" myapp webapp
            The status should equal 0
            The stderr should include "Init complete."
            The path "${E2E_PROJECT_DIR}/docs/.deckrd/${_WORKFLOW_REL}" should be file
            The path "${E2E_PROJECT_DIR}/.claude/rules/deckrd-rules/deckrd-rules-index.md" should be file
            The path "${E2E_PROJECT_DIR}/.local/deckrd/session.json" should be file
            Assert _skill_copy_unchanged
          End
        End

        It "[Normal] T-CLI-DEPE-16: Should: detect a changed file content in the private skill copy"
          When run _skill_copy_unchanged_after_rewrite
          The status should equal 1
          The output should include "assets/inits/docs/${_WORKFLOW_REL}"
        End
      End

      Describe "Given: a project initialized by init.sh"
        Before "_init_project"

        Describe "Then: each .gitignore.org source lands as .gitignore"
          Parameters:dynamic
            for pair in $_GITIGNORE_PAIRS; do
              %data "${pair%%:*}" "${pair#*:}"
            done
          End

          It "[Normal] T-CLI-DEPE-03: Should: deploy $2 as $1 with identical content"
            When run cmp "${PROJECT_ROOT}/$1" "${ASSETS_DIR}/inits/$2"
            The status should equal 0
            The output should be blank
          End
        End

        It "[Normal] T-CLI-DEPE-04: Should: leave no *.org file anywhere under PROJECT_ROOT"
          When run find "$PROJECT_ROOT" -name '*.org'
          The status should equal 0
          The output should be blank
        End

        Describe "Given: the deployed workflow rule is outdated"
          Before "_make_workflow_outdated"

          It "[Normal] T-CLI-DEPE-05: Should: overwrite the outdated workflow rule with update.sh --update"
            When run _run_in_project "$UPDATE_SCRIPT" --update
            The status should equal 0
            The output should include "$_UPDATE_WORKFLOW_MSG"
            Assert _same_as_source "docs/.deckrd/${_WORKFLOW_REL}" "docs/${_WORKFLOW_REL}"
          End
        End

        Describe "Given: the deployed workflow rule is deleted"
          Before "_delete_workflow"

          It "[Normal] T-CLI-DEPE-06: Should: recreate the deleted workflow rule with update.sh --update"
            When run _run_in_project "$UPDATE_SCRIPT" --update
            The status should equal 0
            The output should include "$_UPDATE_WORKFLOW_MSG"
            Assert _same_as_source "docs/.deckrd/${_WORKFLOW_REL}" "docs/${_WORKFLOW_REL}"
          End
        End

        Describe "Given: the deployed workflow rule is outdated when init.sh runs again with --force"
          Before "_make_workflow_outdated"

          It "[Normal] T-CLI-DEPE-07: Should: overwrite the outdated workflow rule by re-running init.sh --force"
            When run _run_in_project "$INIT_SCRIPT" myapp webapp --force
            The status should equal 0
            The stderr should include "$_INIT_WORKFLOW_MSG"
            Assert _same_as_source "docs/.deckrd/${_WORKFLOW_REL}" "docs/${_WORKFLOW_REL}"
          End
        End
      End
    End

    Describe "When: エッジケース"
      Describe "Given: a project initialized by init.sh"
        Before "_init_project"

        Describe "Given: the deployed rules/.gitignore is edited by the user and older than its source"
          Before "_edit_rules_gitignore_old"

          It "[Edge] T-CLI-DEPE-08: Should: keep the edited rules/.gitignore and not report it with update.sh --update"
            When run _run_in_project "$UPDATE_SCRIPT" --update
            The status should equal 0
            The output should not include "rules/.gitignore"
            The contents of file "${PROJECT_ROOT}/docs/.deckrd/rules/.gitignore" should equal "$_USER_EDIT"
          End
        End

        Describe "Given: the deployed workflow rule is edited by the user and newer than its source"
          Before "_edit_workflow_newer"

          It "[Edge] T-CLI-DEPE-09: Should: keep the edited workflow rule and not report it with update.sh --update"
            When run _run_in_project "$UPDATE_SCRIPT" --update
            The status should equal 0
            The output should not include "$_WORKFLOW_REL"
            The contents of file "${PROJECT_ROOT}/docs/.deckrd/${_WORKFLOW_REL}" should equal "$_USER_EDIT"
          End
        End
      End

      Describe "Given: docs/.deckrd/rules is a symlink to a temp copy of its asset source"
        Skip if "symlinks are unsupported" _e2e_symlink_unsupported
        Before "_link_rules_to_asset_copy"
        After "_remove_asset_copy"

        It "[Edge] T-CLI-DEPE-14: Should: exit 0 and write no .gitignore into the source tree with init.sh --force"
          When run _run_in_project "$INIT_SCRIPT" myapp webapp --force
          The status should equal 0
          The stderr should include "Init complete."
          The path "${_E2E_ASSET_COPY_DIR}/inits/docs/rules/.gitignore" should not be exist
          The path "${PROJECT_ROOT}/docs/.deckrd/rules" should be symlink
        End
      End
    End

    Describe "When: 異常系"
      It "[Error] T-CLI-DEPE-10: Should: exit 1 with session not found when update.sh runs before init"
        When run _run_in_project "$UPDATE_SCRIPT" --update
        The status should equal 1
        The output should be blank
        The stderr should include "session not found: ${PROJECT_ROOT}/.local/deckrd/session.json"
        The path "${PROJECT_ROOT}/docs/.deckrd" should not be exist
      End

      It "[Error] T-CLI-DEPE-15: Should: exit 1 with session not found under the current directory when PROJECT_ROOT is unset"
        When run _run_in_cwd_without_project_root "$UPDATE_SCRIPT" --update
        The status should equal 1
        The output should be blank
        The stderr should include "session not found: ${E2E_PROJECT_DIR}/.local/deckrd/session.json"
        The path "${E2E_PROJECT_DIR}/docs/.deckrd" should not be exist
      End
    End
  End
End
