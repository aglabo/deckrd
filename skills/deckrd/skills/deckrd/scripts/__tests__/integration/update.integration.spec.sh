#!/usr/bin/env bash
# skills/deckrd/skills/deckrd/scripts/__tests__/integration/update.integration.spec.sh
# @(#) : Integration tests for update.sh - list outdated assets (no mocks)
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
  for label in deckrd-rules claude-rules deckrd-rules-index docs local-deckrd local-workspaces; do
    mkdir -p "${INITS_DIR}/${label}"
  done
  mkdir -p "$DECKRD_RULES_DIR" "$CLAUDE_RULES_DIR" "$CLAUDE_RULES_INDEX_DIR" "$DECKRD_LOCAL_WORKSPACES"
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

# Fixture: workspaces rule block of the local gitignore template (banner to EOF)
_workspaces_rule_block() {
  printf '%s\n' '## ---- ##' '##  Shared notes layer: track workspaces/ only ##' '## ---- ##' \
    '!/workspaces/' '!/workspaces/**'
}

# Fixture: old local gitignore content without the workspaces rule
_old_local_gitignore() {
  printf '%s\n' '*' '!README*' '!.gitignore'
}

# Fixture: local gitignore content that already has the workspaces rule
_ruled_local_gitignore() {
  printf '%s\n' '*' '!/workspaces/'
}

# Helper: place the local gitignore template and a local gitignore read from stdin
_make_local_gitignore() {
  { printf '%s\n' '*'; _workspaces_rule_block; } >"${INITS_DIR}/local-deckrd/.gitignore.org"
  cat >"${DECKRD_LOCAL_DATA}/.gitignore"
}

# Helper: place the template and an old local gitignore without the workspaces rule
make_old_local_gitignore() {
  _old_local_gitignore | _make_local_gitignore
}

# Helper: place the template and a local gitignore that already has the workspaces rule
make_ruled_local_gitignore() {
  _ruled_local_gitignore | _make_local_gitignore
}

# Helper: convert LF line endings from stdin to CRLF
_to_crlf() {
  sed 's/$/\r/'
}

# Helper: place the template and an old CRLF local gitignore without the workspaces rule
make_old_crlf_local_gitignore() {
  _old_local_gitignore | _to_crlf | _make_local_gitignore
}

# Helper: place the template and a CRLF local gitignore that already has the workspaces rule
make_ruled_crlf_local_gitignore() {
  _ruled_local_gitignore | _to_crlf | _make_local_gitignore
}

# Helper: place a template without the workspaces rule marker and an old local gitignore
make_markerless_template_local_gitignore() {
  make_old_local_gitignore
  printf '%s\n' '*' '!README*' >"${INITS_DIR}/local-deckrd/.gitignore.org"
}

# Helper: place the template and an old local gitignore whose last line has no trailing newline
make_unterminated_local_gitignore() {
  printf '*\n!README*\n!.gitignore' | _make_local_gitignore
}

# Helper: place the template and an old local gitignore that cannot be read
make_unreadable_local_gitignore() {
  make_old_local_gitignore
  chmod 000 "${DECKRD_LOCAL_DATA}/.gitignore"
}

# Helper: place the template and an old local gitignore that can be read but not written
make_readonly_local_gitignore() {
  make_old_local_gitignore
  chmod 444 "${DECKRD_LOCAL_DATA}/.gitignore"
}

# Helper: give the local gitignore its normal mode back so that teardown can remove it
restore_local_gitignore_mode() {
  [[ ! -f "${DECKRD_LOCAL_DATA:-}/.gitignore" ]] || chmod 644 "${DECKRD_LOCAL_DATA}/.gitignore"
}

# Helper: remove the workspaces directory and place a local-workspaces README source
setup_workspaces_missing() {
  rm -rf "$DECKRD_LOCAL_WORKSPACES"
  printf '%s\n' '# workspaces' >"${INITS_DIR}/local-workspaces/README.md"
}

# Fixture: target path of the dangling README symlink (inside the test temp area, never created)
dangling_readme_target() {
  printf '%s\n' "${DECKRD_TMPDIR}/readme-target.md"
}

# Helper: occupy the workspaces README path with a symlink to a nonexistent target
# MSYS=winsymlinks:nativestrict lets Git Bash create a native dangling symlink; harmless elsewhere.
setup_workspaces_readme_dangling_symlink() {
  mkdir -p "$DECKRD_LOCAL_WORKSPACES"
  MSYS=winsymlinks:nativestrict ln -s "$(dangling_readme_target)" "${DECKRD_LOCAL_WORKSPACES}/README.md"
}

# Helper: report whether this host cannot create a dangling symlink
#
# Keeps the negation inside the function so that `Skip if` works (see command_missing in spec_helper.sh).
#
# @return 0 if a dangling symlink cannot be created, 1 if it can
dangling_symlink_unsupported() {
  local probe_dir rc=1
  probe_dir="$(mktemp -d)" || return 0
  { MSYS=winsymlinks:nativestrict ln -s "${probe_dir}/missing" "${probe_dir}/link" 2>/dev/null &&
    [[ -L "${probe_dir}/link" ]]; } || rc=0
  rm -rf "$probe_dir"
  return "$rc"
}

# ============================================================================
# update.sh: list outdated assets
# ============================================================================

Describe "T-CLI-UPDI: update.sh: list outdated assets"

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
      make_asset local-deckrd "$DECKRD_LOCAL_DATA" c.md new old "$NEW_MTIME" "$OLD_MTIME"
      make_asset local-workspaces "$DECKRD_LOCAL_WORKSPACES" README.md new old "$NEW_MTIME" "$OLD_MTIME"
    }
    Before "setup_multi_outdated"

    It "[Normal] T-CLI-UPDI-02: Should: exit 0 and print each file with its label in ASSET_TARGETS order"
      When run bash "$SCRIPT"
      The status should equal 0
      The line 1 of output should equal "[deckrd-rules] a.md"
      The line 2 of output should equal "[docs] b.md"
      The line 3 of output should equal "[local-deckrd] c.md"
      The line 4 of output should equal "[local-workspaces] README.md"
      The lines of output should equal 4
    End
  End

  Describe "Given: source is newer but has the same content as the deployed file"
    Before "setup_update_env"
    After "teardown_update_env"

    setup_same_content() {
      make_asset deckrd-rules "$DECKRD_RULES_DIR" a.md same same "$NEW_MTIME" "$OLD_MTIME"
    }
    Before "setup_same_content"

    It "[Normal] T-CLI-UPDI-04: Should: exit 0 and print that assets are up to date"
      When run bash "$SCRIPT"
      The status should equal 0
      The output should equal "Assets are up to date."
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
      The output should equal "Assets are up to date."
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
      The output should equal "Assets are up to date."
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
      The stderr should include "workspaces/README.md"
    End
  End

  Describe "Given: old local gitignore without the workspaces rule"
    Before "setup_update_env"
    After "teardown_update_env"
    Before "make_old_local_gitignore"

    It "[Normal] T-CLI-UPDI-10: Should: exit 0, print the workspaces rule label, and leave the gitignore unchanged"
      When run bash "$SCRIPT"
      The status should equal 0
      The output should equal "[local-deckrd] .gitignore (workspaces rule)"
      The contents of file "${DECKRD_LOCAL_DATA}/.gitignore" should equal "$(_old_local_gitignore)"
    End
  End

  Describe "Given: outdated README in the local-workspaces target"
    Before "setup_update_env"
    After "teardown_update_env"

    setup_workspaces_outdated() {
      make_asset local-workspaces "$DECKRD_LOCAL_WORKSPACES" README.md new old "$NEW_MTIME" "$OLD_MTIME"
    }
    Before "setup_workspaces_outdated"

    It "[Normal] T-CLI-UPDI-11: Should: exit 0, print [local-workspaces] README.md, and leave the file unchanged"
      When run bash "$SCRIPT"
      The status should equal 0
      The output should equal "[local-workspaces] README.md"
      The contents of file "${DECKRD_LOCAL_WORKSPACES}/README.md" should equal "old"
    End
  End

  Describe "Given: workspaces directory missing and a local-workspaces README source"
    Before "setup_update_env" "setup_workspaces_missing"
    After "teardown_update_env"

    It "[Normal] T-CLI-UPDI-12: Should: exit 0, print the missing workspaces README label, and not create the directory"
      When run bash "$SCRIPT"
      The status should equal 0
      The output should equal "[local-workspaces] README.md (missing)"
      The path "$DECKRD_LOCAL_WORKSPACES" should not be exist
    End
  End

  Describe "Given: workspaces directory missing and no local-workspaces README source"
    Before "setup_update_env"
    After "teardown_update_env"

    setup_workspaces_missing_no_source() {
      rm -rf "$DECKRD_LOCAL_WORKSPACES"
    }
    Before "setup_workspaces_missing_no_source"

    It "[Edge] T-CLI-UPDI-13: Should: exit 0, print that assets are up to date, and not create the directory"
      When run bash "$SCRIPT"
      The status should equal 0
      The output should equal "Assets are up to date."
      The path "$DECKRD_LOCAL_WORKSPACES" should not be exist
    End
  End

  Describe "Given: workspaces README path occupied by a dangling symlink and a local-workspaces README source"
    Skip if "dangling symlinks are not supported on this host" dangling_symlink_unsupported
    Before "setup_update_env" "setup_workspaces_missing" "setup_workspaces_readme_dangling_symlink"
    After "teardown_update_env"

    # A dangling symlink at the README path counts as deployed
    It "[Edge] T-CLI-UPDI-14: Should: exit 0, print up to date, and keep the symlink without creating its target"
      When run bash "$SCRIPT"
      The status should equal 0
      The output should equal "Assets are up to date."
      The path "${DECKRD_LOCAL_WORKSPACES}/README.md" should be symlink
      The path "$(dangling_readme_target)" should not be exist
    End
  End

End

# ============================================================================
# update.sh --update: apply outdated assets
# ============================================================================

Describe "T-CLI-UPDA: update.sh --update: apply outdated assets"

  Describe "Given: one deployed file older than its differing source"
    Before "setup_update_env"
    After "teardown_update_env"

    setup_one_outdated_for_update() {
      make_asset deckrd-rules "$DECKRD_RULES_DIR" a.md new old "$NEW_MTIME" "$OLD_MTIME"
    }
    Before "setup_one_outdated_for_update"

    It "[Normal] T-CLI-UPDA-01: Should: exit 0, print Updated: [label] name, and overwrite with the source"
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

    It "[Edge] T-CLI-UPDA-02: Should: exit 0, print up to date, and keep the deployed .gitignore"
      When run bash "$SCRIPT" --update
      The status should equal 0
      The output should equal "Assets are up to date."
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

    It "[Edge] T-CLI-UPDA-03: Should: exit 0, print up to date, and keep the edited file"
      When run bash "$SCRIPT" --update
      The status should equal 0
      The output should equal "Assets are up to date."
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

    It "[Edge] T-CLI-UPDA-04: Should: exit 0, print up to date, and not deploy the file"
      When run bash "$SCRIPT" --update
      The status should equal 0
      The output should equal "Assets are up to date."
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

    It "[Error] T-CLI-UPDA-05: Should: exit 1, stderr prompts init, and leave the deployed file unchanged"
      When run bash "$SCRIPT" --update
      The status should equal 1
      The output should be blank
      The stderr should include "init"
      The contents of file "${DECKRD_RULES_DIR}/a.md" should equal "old"
    End
  End

  Describe "Given: old local gitignore without the workspaces rule"
    Before "setup_update_env"
    After "teardown_update_env"
    Before "make_old_local_gitignore"

    It "[Normal] T-CLI-UPDA-06: Should: exit 0, print Updated: with the workspaces rule label, and append the block"
      When run bash "$SCRIPT" --update
      The status should equal 0
      The output should equal "Updated: [local-deckrd] .gitignore (workspaces rule)"
      # original lines kept at the top, then one blank line, then the template block
      The contents of file "${DECKRD_LOCAL_DATA}/.gitignore" should equal "$(
        _old_local_gitignore
        echo
        _workspaces_rule_block
      )"
    End
  End

  Describe "Given: old local gitignore already migrated by a previous --update run"
    Before "setup_update_env"
    After "teardown_update_env"

    # Runs the first --update and keeps its result as the snapshot to compare with
    setup_migrated_gitignore() {
      make_old_local_gitignore
      bash "$SCRIPT" --update >/dev/null
      MIGRATED_GITIGNORE="$(cat "${DECKRD_LOCAL_DATA}/.gitignore")"
    }
    Before "setup_migrated_gitignore"

    It "[Normal] T-CLI-UPDA-07: Should: exit 0, print up to date, and leave the migrated gitignore unchanged"
      When run bash "$SCRIPT" --update
      The status should equal 0
      The output should equal "Assets are up to date."
      The contents of file "${DECKRD_LOCAL_DATA}/.gitignore" should equal "$MIGRATED_GITIGNORE"
    End
  End

  Describe "Given: local gitignore that already has the workspaces rule"
    Before "setup_update_env"
    After "teardown_update_env"
    Before "make_ruled_local_gitignore"

    It "[Edge] T-CLI-UPDA-08: Should: exit 0, print up to date, and leave the gitignore unchanged"
      When run bash "$SCRIPT" --update
      The status should equal 0
      The output should equal "Assets are up to date."
      The contents of file "${DECKRD_LOCAL_DATA}/.gitignore" should equal "$(_ruled_local_gitignore)"
    End
  End

  Describe "Given: old CRLF local gitignore without the workspaces rule"
    Before "setup_update_env"
    After "teardown_update_env"
    Before "make_old_crlf_local_gitignore"

    It "[Normal] T-CLI-UPDA-09: Should: exit 0, print Updated: with the workspaces rule label, and rewrite as LF with the block"
      When run bash "$SCRIPT" --update
      The status should equal 0
      The output should equal "Updated: [local-deckrd] .gitignore (workspaces rule)"
      The contents of file "${DECKRD_LOCAL_DATA}/.gitignore" should not include "$(printf '\r')"
      # original lines converted to LF, then one blank line, then the template block
      The contents of file "${DECKRD_LOCAL_DATA}/.gitignore" should equal "$(
        _old_local_gitignore
        echo
        _workspaces_rule_block
      )"
    End
  End

  Describe "Given: CRLF local gitignore that already has the workspaces rule"
    Before "setup_update_env"
    After "teardown_update_env"
    Before "make_ruled_crlf_local_gitignore"

    It "[Edge] T-CLI-UPDA-10: Should: exit 0, print up to date, and leave the CRLF gitignore unchanged"
      When run bash "$SCRIPT" --update
      The status should equal 0
      The output should equal "Assets are up to date."
      # no migration needed, so the file keeps its CRLF line endings
      The contents of file "${DECKRD_LOCAL_DATA}/.gitignore" should equal "$(_ruled_local_gitignore | _to_crlf)"
    End
  End

  Describe "Given: old local gitignore that cannot be read"
    # chmod 000 does not stop root from reading, so the case cannot be set up as root
    Skip if "running as root" [ "$(id -u)" -eq 0 ]
    Before "setup_update_env"
    After "teardown_update_env"
    Before "make_unreadable_local_gitignore"
    After "restore_local_gitignore_mode"

    It "[Error] T-CLI-UPDA-11: Should: exit 1, stderr reports the read error, and print no Updated: line"
      When run bash "$SCRIPT" --update
      The status should equal 1
      The output should not include "Updated:"
      The stderr should include "Error: cannot read: ${DECKRD_LOCAL_DATA}/.gitignore"
    End
  End

  Describe "Given: old local gitignore and a template without the workspaces rule marker"
    Before "setup_update_env"
    After "teardown_update_env"
    Before "make_markerless_template_local_gitignore"

    It "[Error] T-CLI-UPDA-12: Should: exit 1, stderr reports the missing block, and leave the gitignore unchanged"
      When run bash "$SCRIPT" --update
      The status should equal 1
      The output should not include "Updated:"
      The stderr should include "Error: workspaces rule block not found"
      The contents of file "${DECKRD_LOCAL_DATA}/.gitignore" should equal "$(_old_local_gitignore)"
    End
  End

  Describe "Given: old local gitignore that can be read but not written"
    # chmod 444 does not stop root from writing, so the case cannot be set up as root
    Skip if "running as root" [ "$(id -u)" -eq 0 ]
    Before "setup_update_env"
    After "teardown_update_env"
    Before "make_readonly_local_gitignore"
    After "restore_local_gitignore_mode"

    It "[Error] T-CLI-UPDA-13: Should: exit 1, stderr reports the failed update, and leave the gitignore unchanged"
      When run bash "$SCRIPT" --update
      The status should equal 1
      The output should not include "Updated:"
      The stderr should include "Error: failed to update: ${DECKRD_LOCAL_DATA}/.gitignore"
      The contents of file "${DECKRD_LOCAL_DATA}/.gitignore" should equal "$(_old_local_gitignore)"
    End
  End

  Describe "Given: old local gitignore whose last line has no trailing newline"
    Before "setup_update_env"
    After "teardown_update_env"
    Before "make_unterminated_local_gitignore"

    It "[Edge] T-CLI-UPDA-14: Should: exit 0, print Updated: with the workspaces rule label, and append the block after one blank line"
      When run bash "$SCRIPT" --update
      The status should equal 0
      The output should equal "Updated: [local-deckrd] .gitignore (workspaces rule)"
      # the unterminated last line is completed, then exactly one blank line, then the block
      The contents of file "${DECKRD_LOCAL_DATA}/.gitignore" should equal "$(
        _old_local_gitignore
        echo
        _workspaces_rule_block
      )"
    End
  End

  Describe "Given: outdated README in the local-workspaces target"
    Before "setup_update_env"
    After "teardown_update_env"

    setup_workspaces_outdated_for_update() {
      make_asset local-workspaces "$DECKRD_LOCAL_WORKSPACES" README.md new old "$NEW_MTIME" "$OLD_MTIME"
    }
    Before "setup_workspaces_outdated_for_update"

    It "[Normal] T-CLI-UPDA-15: Should: exit 0, print Updated: [local-workspaces] README.md, and overwrite with the source"
      When run bash "$SCRIPT" --update
      The status should equal 0
      The output should equal "Updated: [local-workspaces] README.md"
      The contents of file "${DECKRD_LOCAL_WORKSPACES}/README.md" should equal "new"
    End
  End

  Describe "Given: workspaces directory missing and a local-workspaces README source"
    Before "setup_update_env" "setup_workspaces_missing"
    After "teardown_update_env"

    It "[Normal] T-CLI-UPDA-16: Should: exit 0, print Updated: with the missing workspaces README label, and copy the source"
      When run bash "$SCRIPT" --update
      The status should equal 0
      The output should equal "Updated: [local-workspaces] README.md (missing)"
      The contents of file "${DECKRD_LOCAL_WORKSPACES}/README.md" should equal "$(cat "${INITS_DIR}/local-workspaces/README.md")"
    End
  End

  Describe "Given: missing workspaces README already copied by a previous --update run"
    Before "setup_update_env" "setup_workspaces_missing"
    After "teardown_update_env"

    # Runs the first --update so that the README is already deployed
    setup_workspaces_readme_copied() {
      bash "$SCRIPT" --update >/dev/null
    }
    Before "setup_workspaces_readme_copied"

    It "[Edge] T-CLI-UPDA-17: Should: exit 0, print up to date, and keep the copied README"
      When run bash "$SCRIPT" --update
      The status should equal 0
      The output should equal "Assets are up to date."
      The contents of file "${DECKRD_LOCAL_WORKSPACES}/README.md" should equal "$(cat "${INITS_DIR}/local-workspaces/README.md")"
    End
  End

  Describe "Given: workspaces README path occupied by a directory and a local-workspaces README source"
    Before "setup_update_env" "setup_workspaces_missing"
    After "teardown_update_env"

    # Any existing entry at the README path counts as deployed
    setup_workspaces_readme_dir() {
      mkdir -p "${DECKRD_LOCAL_WORKSPACES}/README.md"
    }
    Before "setup_workspaces_readme_dir"

    It "[Edge] T-CLI-UPDA-18: Should: exit 0, print up to date, and copy nothing into the README directory"
      When run bash "$SCRIPT" --update
      The status should equal 0
      The output should equal "Assets are up to date."
      The path "${DECKRD_LOCAL_WORKSPACES}/README.md" should be directory
      The path "${DECKRD_LOCAL_WORKSPACES}/README.md/README.md" should not be exist
    End
  End

  Describe "Given: workspaces path occupied by a regular file and a local-workspaces README source"
    Before "setup_update_env" "setup_workspaces_missing"
    After "teardown_update_env"

    # A regular file at the workspaces path makes mkdir -p fail
    setup_workspaces_path_file() {
      : >"$DECKRD_LOCAL_WORKSPACES"
    }
    Before "setup_workspaces_path_file"

    It "[Error] T-CLI-UPDA-19: Should: exit 1, stderr reports the failed update, and leave the workspaces path a regular file"
      When run bash "$SCRIPT" --update
      The status should equal 1
      The stderr should include "Error: failed to update: ${DECKRD_LOCAL_WORKSPACES}/README.md"
      The output should not include "Updated:"
      The path "$DECKRD_LOCAL_WORKSPACES" should be file
    End
  End

  Describe "Given: workspaces directory with another file but no README and a local-workspaces README source"
    Before "setup_update_env"
    After "teardown_update_env"

    # Keeps the workspaces directory (unlike setup_workspaces_missing) so that only the README is missing
    setup_workspaces_readme_only_missing() {
      printf '%s\n' '# workspaces' >"${INITS_DIR}/local-workspaces/README.md"
      printf '%s\n' 'keep' >"${DECKRD_LOCAL_WORKSPACES}/notes.md"
    }
    Before "setup_workspaces_readme_only_missing"

    It "[Edge] T-CLI-UPDA-20: Should: exit 0, print Updated: with the missing workspaces README label, copy the source, and keep other files"
      When run bash "$SCRIPT" --update
      The status should equal 0
      The output should equal "Updated: [local-workspaces] README.md (missing)"
      The contents of file "${DECKRD_LOCAL_WORKSPACES}/README.md" should equal "$(cat "${INITS_DIR}/local-workspaces/README.md")"
      The contents of file "${DECKRD_LOCAL_WORKSPACES}/notes.md" should equal "keep"
    End
  End

  Describe "Given: workspaces README path occupied by a dangling symlink and a local-workspaces README source"
    Skip if "dangling symlinks are not supported on this host" dangling_symlink_unsupported
    Before "setup_update_env" "setup_workspaces_missing" "setup_workspaces_readme_dangling_symlink"
    After "teardown_update_env"

    # A dangling symlink at the README path counts as deployed, so nothing is copied over it
    It "[Edge] T-CLI-UPDA-21: Should: exit 0, print up to date, and keep the symlink without creating its target"
      When run bash "$SCRIPT" --update
      The status should equal 0
      The output should equal "Assets are up to date."
      The path "${DECKRD_LOCAL_WORKSPACES}/README.md" should be symlink
      The path "$(dangling_readme_target)" should not be exist
    End
  End

End
