#!/usr/bin/env bash
# skills/deckrd/skills/deckrd/scripts/__tests__/integration/update.integration.spec.sh
# @(#) : Integration tests for update.sh - list outdated rules assets (no mocks)
#
# Copyright (c) 2026- atsushifx <https://github.com/atsushifx>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

# cspell:words UPDI

# shellcheck disable=SC1090

_RUNTIME_BOOTSTRAP="${SHELLSPEC_PROJECT_ROOT}/skills/deckrd/skills/deckrd/scripts/libs/bootstrap.lib.sh"
. "$_RUNTIME_BOOTSTRAP" "--no-finalize"
unset _RUNTIME_BOOTSTRAP

Include ../spec_helper.sh

SCRIPT="${DECKRD_SCRIPTS_DIR}/update.sh"

OLD_MTIME='2026-01-01 00:00:00'
NEW_MTIME='2026-01-02 00:00:00'

# Helper: create an isolated asset source tree and deployment directories
setup_update_env() {
  setup_deckrd_tmpdir
  export INITS_DIR="${DECKRD_TMPDIR}/inits"
  local label
  for label in deckrd-rules claude-rules deckrd-rules-index docs local-deckrd; do
    mkdir -p "${INITS_DIR}/${label}"
  done
  mkdir -p "$DECKRD_RULES_DIR" "$CLAUDE_RULES_DIR" "$CLAUDE_RULES_INDEX_DIR"
  printf '{}\n' >"${DECKRD_LOCAL_DATA}/session.json"
}

# Helper: clean up the environment created by setup_update_env
teardown_update_env() {
  unset INITS_DIR
  teardown_deckrd_tmpdir
}

# Helper: place an asset source file and its deployed copy with fixed mtimes
# Contents are written before touch so that the mtimes are not reset.
# @arg $1 Asset label (subdirectory of INITS_DIR)
# @arg $2 Destination directory
# @arg $3 File name
# @arg $4 Source content
# @arg $5 Destination content
# @arg $6 Source mtime
# @arg $7 Destination mtime
make_asset() {
  local src="${INITS_DIR}/${1}/${3}" dest="${2}/${3}"
  printf '%s\n' "$4" >"$src"
  printf '%s\n' "$5" >"$dest"
  touch -d "$6" "$src"
  touch -d "$7" "$dest"
}

# ============================================================================
# update.sh: list outdated assets
# ============================================================================

Describe "update.sh: list outdated assets"

  Describe "Given: one deployed file older than its differing source"
    Before "setup_update_env"
    After "teardown_update_env"

    setup_one_outdated() {
      make_asset deckrd-rules "$DECKRD_RULES_DIR" deckrd-rule-workflow.md new old "$NEW_MTIME" "$OLD_MTIME"
    }
    Before "setup_one_outdated"

    It "[Normal] T-CLI-UPDI-01: Should: exit 0 and print the file as [label] name"
      When run bash "$SCRIPT"
      The status should equal 0
      The output should equal "[deckrd-rules] deckrd-rule-workflow.md"
    End

    It "[Normal] T-CLI-UPDI-03: Should: leave the deployed file unchanged"
      When run bash "$SCRIPT"
      The status should equal 0
      The output should be present
      The contents of file "${DECKRD_RULES_DIR}/deckrd-rule-workflow.md" should equal "old"
    End
  End

  Describe "Given: outdated deployed files in multiple targets"
    Before "setup_update_env"
    After "teardown_update_env"

    setup_multi_outdated() {
      make_asset deckrd-rules "$DECKRD_RULES_DIR" a.md new old "$NEW_MTIME" "$OLD_MTIME"
      make_asset docs "$DECKRD_DOCS_DIR" b.md new old "$NEW_MTIME" "$OLD_MTIME"
    }
    Before "setup_multi_outdated"

    It "[Normal] T-CLI-UPDI-02: Should: exit 0 and print each file with its label in ASSET_TARGETS order"
      When run bash "$SCRIPT"
      The status should equal 0
      The line 1 of output should equal "[deckrd-rules] a.md"
      The line 2 of output should equal "[docs] b.md"
      The lines of output should equal 2
    End
  End

  Describe "Given: source is newer but has the same content as the deployed file"
    Before "setup_update_env"
    After "teardown_update_env"

    setup_same_content() {
      make_asset deckrd-rules "$DECKRD_RULES_DIR" a.md same same "$NEW_MTIME" "$OLD_MTIME"
    }
    Before "setup_same_content"

    It "[Normal] T-CLI-UPDI-04: Should: exit 0 and print that rules are up to date"
      When run bash "$SCRIPT"
      The status should equal 0
      The output should equal "Rules are up to date."
    End
  End

  Describe "Given: deployed file edited by the user (newer than a differing source)"
    Before "setup_update_env"
    After "teardown_update_env"

    setup_user_edited() {
      make_asset deckrd-rules "$DECKRD_RULES_DIR" a.md new edited "$OLD_MTIME" "$NEW_MTIME"
    }
    Before "setup_user_edited"

    It "[Edge] T-CLI-UPDI-05: Should: exit 0, print up to date, and keep the edited file"
      When run bash "$SCRIPT"
      The status should equal 0
      The output should equal "Rules are up to date."
      The contents of file "${DECKRD_RULES_DIR}/a.md" should equal "edited"
    End
  End

  Describe "Given: source file that has not been deployed"
    Before "setup_update_env"
    After "teardown_update_env"

    setup_undeployed() {
      printf '%s\n' new >"${INITS_DIR}/deckrd-rules/new-rule.md"
    }
    Before "setup_undeployed"

    It "[Edge] T-CLI-UPDI-06: Should: exit 0, print up to date, and not deploy the file"
      When run bash "$SCRIPT"
      The status should equal 0
      The output should equal "Rules are up to date."
      The path "${DECKRD_RULES_DIR}/new-rule.md" should not be exist
    End
  End

  Describe "Given: session.json does not exist"
    Before "setup_update_env"
    After "teardown_update_env"

    setup_no_session() {
      rm "${DECKRD_LOCAL_DATA}/session.json"
      make_asset deckrd-rules "$DECKRD_RULES_DIR" a.md new old "$NEW_MTIME" "$OLD_MTIME"
    }
    Before "setup_no_session"

    It "[Error] T-CLI-UPDI-07: Should: exit 1, stderr prompts init, stdout is blank"
      When run bash "$SCRIPT"
      The status should equal 1
      The output should be blank
      The stderr should include "init"
    End
  End

  Describe "Given: unknown option"
    Before "setup_update_env"
    After "teardown_update_env"

    It "[Error] T-CLI-UPDI-08: Should: exit 1, stderr includes Unknown option and Usage, stdout is blank"
      When run bash "$SCRIPT" --unknown
      The status should equal 1
      The output should be blank
      The stderr should include "Unknown option"
      The stderr should include "Usage:"
    End
  End

  Describe "Given: help option without session.json"
    Before "setup_update_env"
    After "teardown_update_env"

    remove_session() {
      rm "${DECKRD_LOCAL_DATA}/session.json"
    }
    Before "remove_session"

    Parameters
      "-h"
      "--help"
    End

    It "[Normal] T-CLI-UPDI-09: Should: exit 0, stderr includes Usage, stdout is blank ($1)"
      When run bash "$SCRIPT" "$1"
      The status should equal 0
      The output should be blank
      The stderr should include "Usage:"
    End
  End

End

# ============================================================================
# update.sh --update: apply outdated assets
# ============================================================================

Describe "update.sh --update: apply outdated assets"

  Describe "Given: one deployed file older than its differing source"
    Before "setup_update_env"
    After "teardown_update_env"

    setup_one_outdated_for_update() {
      make_asset deckrd-rules "$DECKRD_RULES_DIR" a.md new old "$NEW_MTIME" "$OLD_MTIME"
    }
    Before "setup_one_outdated_for_update"

    It "[Normal] T-CLI-UPDI-10: Should: exit 0, print Updated: [label] name, and overwrite with the source"
      When run bash "$SCRIPT" --update
      The status should equal 0
      The output should equal "Updated: [deckrd-rules] a.md"
      The contents of file "${DECKRD_RULES_DIR}/a.md" should equal "new"
    End
  End

  Describe "Given: .org source newer than its differing deployed file"
    Before "setup_update_env"
    After "teardown_update_env"

    setup_org_outdated() {
      printf '%s\n' new >"${INITS_DIR}/deckrd-rules/.gitignore.org"
      printf '%s\n' old >"${DECKRD_RULES_DIR}/.gitignore"
      touch -d "$NEW_MTIME" "${INITS_DIR}/deckrd-rules/.gitignore.org"
      touch -d "$OLD_MTIME" "${DECKRD_RULES_DIR}/.gitignore"
    }
    Before "setup_org_outdated"

    It "[Edge] T-CLI-UPDI-11: Should: exit 0, print up to date, and keep the deployed .gitignore"
      When run bash "$SCRIPT" --update
      The status should equal 0
      The output should equal "Rules are up to date."
      The contents of file "${DECKRD_RULES_DIR}/.gitignore" should equal "old"
    End
  End

  Describe "Given: deployed file edited by the user (newer than a differing source)"
    Before "setup_update_env"
    After "teardown_update_env"

    setup_user_edited_for_update() {
      make_asset deckrd-rules "$DECKRD_RULES_DIR" a.md new edited "$OLD_MTIME" "$NEW_MTIME"
    }
    Before "setup_user_edited_for_update"

    It "[Edge] T-CLI-UPDI-12: Should: exit 0, print up to date, and keep the edited file"
      When run bash "$SCRIPT" --update
      The status should equal 0
      The output should equal "Rules are up to date."
      The contents of file "${DECKRD_RULES_DIR}/a.md" should equal "edited"
    End
  End

  Describe "Given: source file that has not been deployed"
    Before "setup_update_env"
    After "teardown_update_env"

    setup_undeployed_for_update() {
      printf '%s\n' new >"${INITS_DIR}/deckrd-rules/new-rule.md"
    }
    Before "setup_undeployed_for_update"

    It "[Edge] T-CLI-UPDI-13: Should: exit 0, print up to date, and not deploy the file"
      When run bash "$SCRIPT" --update
      The status should equal 0
      The output should equal "Rules are up to date."
      The path "${DECKRD_RULES_DIR}/new-rule.md" should not be exist
    End
  End

  Describe "Given: session.json does not exist"
    Before "setup_update_env"
    After "teardown_update_env"

    setup_no_session_for_update() {
      rm "${DECKRD_LOCAL_DATA}/session.json"
      make_asset deckrd-rules "$DECKRD_RULES_DIR" a.md new old "$NEW_MTIME" "$OLD_MTIME"
    }
    Before "setup_no_session_for_update"

    It "[Error] T-CLI-UPDI-14: Should: exit 1, stderr prompts init, and leave the deployed file unchanged"
      When run bash "$SCRIPT" --update
      The status should equal 1
      The output should be blank
      The stderr should include "init"
      The contents of file "${DECKRD_RULES_DIR}/a.md" should equal "old"
    End
  End

End
