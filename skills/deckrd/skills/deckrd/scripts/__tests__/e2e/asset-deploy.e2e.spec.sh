#!/usr/bin/env bash
# skills/deckrd/skills/deckrd/scripts/__tests__/e2e/asset-deploy.e2e.spec.sh
# @(#) : E2E tests for init.sh / update.sh - deploy the real assets into a non-git PROJECT_ROOT
#
# Copyright (c) 2026- atsushifx <https://github.com/atsushifx>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

# cspell:words DEPE

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
_E2E_OVERRIDE_VARS=(
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

# _INIT_WORKFLOW_MSG - stderr line of init.sh for a (re)copied workflow rule
_INIT_WORKFLOW_MSG="[init/docs] copied: ${_WORKFLOW_REL}"

# _USER_EDIT - Content a user writes over a deployed file
_USER_EDIT='user-edit'

# _GITIGNORE_PAIRS - Table data: each deployed .gitignore and the .org source it is deployed from
#
# One row per space-separated `<deployed path relative to PROJECT_ROOT>:<source path relative to inits/>`.
# A `%const` because Parameters:dynamic is also evaluated at translation time, where functions
# and plain variables of this file do not exist yet.
%const _GITIGNORE_PAIRS: docs/.deckrd/.gitignore:docs/.gitignore.org docs/.deckrd/rules/.gitignore:docs/rules/.gitignore.org .local/deckrd/.gitignore:local-deckrd/.gitignore.org

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

# _run_in_project - Run a script with bash from inside PROJECT_ROOT
#
# @arg $1 Script path
# @arg $@ Script arguments
# @stdout / @stderr Whatever the script prints
# @return Exit status of the script (1 when PROJECT_ROOT cannot be entered)
_run_in_project() {
  cd "$PROJECT_ROOT" && bash "$@"
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

        Describe "Given: the deployed workflow rule is outdated when init.sh runs again"
          Before "_make_workflow_outdated"

          It "[Normal] T-CLI-DEPE-07: Should: overwrite the outdated workflow rule by re-running init.sh"
            When run _run_in_project "$INIT_SCRIPT" myapp webapp
            The status should equal 0
            The stderr should include "$_INIT_WORKFLOW_MSG"
            Assert _same_as_source "docs/.deckrd/${_WORKFLOW_REL}" "docs/${_WORKFLOW_REL}"
          End
        End
      End
    End

    Describe "When: エッジケース"
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

    Describe "When: 異常系"
      It "[Error] T-CLI-DEPE-10: Should: exit 1 with session not found when update.sh runs before init"
        When run _run_in_project "$UPDATE_SCRIPT" --update
        The status should equal 1
        The output should be blank
        The stderr should include "session not found: ${PROJECT_ROOT}/.local/deckrd/session.json"
        The path "${PROJECT_ROOT}/docs/.deckrd" should not be exist
      End
    End
  End
End
