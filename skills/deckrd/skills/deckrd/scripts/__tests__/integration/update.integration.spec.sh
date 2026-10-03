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
  for label in claude-rules deckrd-rules-index docs local-deckrd; do
    mkdir -p "${INITS_DIR}/${label}"
  done
  mkdir -p "$CLAUDE_RULES_DIR" "$CLAUDE_RULES_INDEX_DIR" "$DECKRD_LOCAL_WORKSPACES"
  printf '{}\n' >"${DECKRD_LOCAL_DATA}/session.json"
}

# Helper: clean up the environment created by setup_update_env
teardown_update_env() {
  unset INITS_DIR
  teardown_deckrd_tmpdir
}

# Helper: place an asset source file and its deployed copy with fixed mtimes
# Parent directories are created on both sides, so $3 may contain subdirectories.
# Contents are written before touch so that the mtimes are not reset.
# @arg $1 Asset label (subdirectory of INITS_DIR)
# @arg $2 Destination directory
# @arg $3 Relative path of the file (e.g. a.md, rules/a.md, workspaces/README.md)
# @arg $4 Source content
# @arg $5 Destination content
# @arg $6 Source mtime
# @arg $7 Destination mtime
make_asset() {
  local src="${INITS_DIR}/${1}/${3}" dest="${2}/${3}"
  mkdir -p "$(dirname "$src")" "$(dirname "$dest")"
  printf '%s\n' "$4" >"$src"
  printf '%s\n' "$5" >"$dest"
  touch -d "$6" "$src"
  touch -d "$7" "$dest"
}

# Helper: print the mtime of a file in epoch seconds (GNU stat, as on Git Bash / WSL / Linux)
# @arg $1 Path to the file
file_mtime() {
  stat -c %Y "$1"
}

# Helper: print a date string (e.g. OLD_MTIME) in epoch seconds, as touch -d interprets it
# @arg $1 Date string
epoch_of() {
  date -d "$1" +%s
}

# Helper: remove session.json so that update.sh stops before touching any asset
remove_session() {
  rm "${DECKRD_LOCAL_DATA}/session.json"
}

# Helper: place a source rules/a.md and a deployed copy with the same content,
# the deployed one older (OLD_MTIME) than the source (NEW_MTIME)
make_same_content_older() {
  make_asset docs "$DECKRD_DOCS_DIR" rules/a.md same same "$NEW_MTIME" "$OLD_MTIME"
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

# Fixture: local gitignore template content (`*` followed by the workspaces rule block)
_local_gitignore_template() {
  printf '%s\n' '*'
  _workspaces_rule_block
}

# Helper: place the local gitignore template and a local gitignore read from stdin
_make_local_gitignore() {
  _local_gitignore_template >"${INITS_DIR}/local-deckrd/.gitignore.org"
  cat >"${DECKRD_LOCAL_DATA}/.gitignore"
}

# Helper: place the local gitignore template only, with no deployed local gitignore
make_gitignore_template_only() {
  _local_gitignore_template >"${INITS_DIR}/local-deckrd/.gitignore.org"
  rm -f "${DECKRD_LOCAL_DATA}/.gitignore"
}

# Helper: place a non-keep .org source (rules/x.md.org) newer than and differing from
# its deployed file (rules/x.md)
# Contents are written before touch so that the mtimes are not reset.
make_org_outdated() {
  mkdir -p "${INITS_DIR}/docs/rules" "${DECKRD_DOCS_DIR}/rules"
  printf '%s\n' new >"${INITS_DIR}/docs/rules/x.md.org"
  printf '%s\n' old >"${DECKRD_DOCS_DIR}/rules/x.md"
  touch -d "$NEW_MTIME" "${INITS_DIR}/docs/rules/x.md.org"
  touch -d "$OLD_MTIME" "${DECKRD_DOCS_DIR}/rules/x.md"
}

# Helper: place a .org source (rules/x.md.org) whose destination directory rules/ is
# occupied by a regular file, so that creating the directory fails
make_org_rules_path_file() {
  mkdir -p "${INITS_DIR}/docs/rules" "$DECKRD_DOCS_DIR"
  printf '%s\n' new >"${INITS_DIR}/docs/rules/x.md.org"
  : >"${DECKRD_DOCS_DIR}/rules"
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

# Helper: remove the workspaces directory and place a workspaces README source in local-deckrd
setup_workspaces_missing() {
  rm -rf "$DECKRD_LOCAL_WORKSPACES"
  mkdir -p "${INITS_DIR}/local-deckrd/workspaces"
  printf '%s\n' '# workspaces' >"${INITS_DIR}/local-deckrd/workspaces/README.md"
}

# Fixture: target path of the dangling README symlink (inside the test temp area, never created)
dangling_readme_target() {
  printf '%s\n' "${DECKRD_TMPDIR}/readme-target.md"
}

# Helper: occupy the workspaces README path with a symlink to a nonexistent target
# MSYS=winsymlinks:nativestrict lets Git Bash create a native dangling symlink; harmless elsewhere.
setup_workspaces_readme_dangling_symlink() {
  mkdir -p "${DECKRD_LOCAL_DATA}/workspaces"
  MSYS=winsymlinks:nativestrict ln -s "$(dangling_readme_target)" "${DECKRD_LOCAL_DATA}/workspaces/README.md"
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

# Helper: print the mtime of a file as epoch seconds
#
# Used to compare the deployed file's mtime with its source after `--update`.
#
# @arg $1 File path
# @stdout mtime in seconds since the epoch (`stat -c %Y`)
_mtime_of() {
  stat -c %Y "$1"
}

# ============================================================================
# update.sh: list outdated assets
# ============================================================================

Describe "T-CLI-UPDI: update.sh: list outdated assets"

  Describe "Given: one deployed file older than its differing source"
    Before "setup_update_env"
    After "teardown_update_env"

    setup_one_outdated() {
      make_asset docs "$DECKRD_DOCS_DIR" rules/deckrd-rule-workflow.md new old "$NEW_MTIME" "$OLD_MTIME"
    }
    Before "setup_one_outdated"

    It "[Normal] T-CLI-UPDI-01: Should: exit 0 and print the file as [label] dst_rel"
      When run bash "$SCRIPT"
      The status should equal 0
      The output should equal "[docs] rules/deckrd-rule-workflow.md"
    End

    It "[Normal] T-CLI-UPDI-03: Should: leave the deployed file unchanged"
      When run bash "$SCRIPT"
      The status should equal 0
      The output should be present
      The contents of file "${DECKRD_DOCS_DIR}/rules/deckrd-rule-workflow.md" should equal "old"
    End
  End

  Describe "Given: outdated deployed files in multiple targets"
    Before "setup_update_env"
    After "teardown_update_env"

    setup_multi_outdated() {
      make_asset claude-rules "$CLAUDE_RULES_DIR" a.md new old "$NEW_MTIME" "$OLD_MTIME"
      make_asset docs "$DECKRD_DOCS_DIR" rules/b.md new old "$NEW_MTIME" "$OLD_MTIME"
      make_asset local-deckrd "$DECKRD_LOCAL_DATA" c.md new old "$NEW_MTIME" "$OLD_MTIME"
      make_asset local-deckrd "$DECKRD_LOCAL_DATA" workspaces/README.md new old "$NEW_MTIME" "$OLD_MTIME"
    }
    Before "setup_multi_outdated"

    It "[Normal] T-CLI-UPDI-02: Should: exit 0 and print each file with its label in ASSET_TARGETS order"
      When run bash "$SCRIPT"
      The status should equal 0
      The line 1 of output should equal "[claude-rules] a.md"
      The line 2 of output should equal "[docs] rules/b.md"
      The line 3 of output should equal "[local-deckrd] c.md"
      The line 4 of output should equal "[local-deckrd] workspaces/README.md"
      The lines of output should equal 4
    End
  End

  Describe "Given: source is newer but has the same content as the deployed file"
    Before "setup_update_env" "make_same_content_older"
    After "teardown_update_env"

    It "[Normal] T-CLI-UPDI-04: Should: exit 0 and print that assets are up to date"
      When run bash "$SCRIPT"
      The status should equal 0
      The output should equal "Assets are up to date."
    End

    # List mode never modifies deployed files, so the mtime is not synced either (see UPDA-25)
    It "[Normal] T-CLI-UPDI-17: Should: exit 0, print up to date, and leave the mtime of the same-content older file unchanged"
      When run bash "$SCRIPT"
      The status should equal 0
      The output should equal "Assets are up to date."
      The value "$(file_mtime "${DECKRD_DOCS_DIR}/rules/a.md")" should equal "$(epoch_of "$OLD_MTIME")"
    End
  End

  Describe "Given: deployed file edited by the user (newer than a differing source)"
    Before "setup_update_env"
    After "teardown_update_env"

    setup_user_edited() {
      make_asset docs "$DECKRD_DOCS_DIR" rules/a.md new edited "$OLD_MTIME" "$NEW_MTIME"
    }
    Before "setup_user_edited"

    It "[Edge] T-CLI-UPDI-05: Should: exit 0, print up to date, and keep the edited file"
      When run bash "$SCRIPT"
      The status should equal 0
      The output should equal "Assets are up to date."
      The contents of file "${DECKRD_DOCS_DIR}/rules/a.md" should equal "edited"
    End
  End

  Describe "Given: source file that has not been deployed"
    Before "setup_update_env"
    After "teardown_update_env"

    setup_undeployed() {
      mkdir -p "${INITS_DIR}/docs/rules"
      printf '%s\n' new >"${INITS_DIR}/docs/rules/new-rule.md"
    }
    Before "setup_undeployed"

    It "[Edge] T-CLI-UPDI-06: Should: exit 0, list the file as [label] dst_rel, and not deploy it"
      When run bash "$SCRIPT"
      The status should equal 0
      The output should equal "[docs] rules/new-rule.md"
      The path "${DECKRD_DOCS_DIR}/rules/new-rule.md" should not be exist
    End
  End

  Describe "Given: session.json does not exist"
    Before "setup_update_env"
    After "teardown_update_env"

    setup_no_session() {
      remove_session
      make_asset docs "$DECKRD_DOCS_DIR" rules/a.md new old "$NEW_MTIME" "$OLD_MTIME"
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

    Before "remove_session"

    Parameters
      "-h"
      "--help"
    End

    It "[Normal] T-CLI-UPDI-09: Should: exit 0, stderr includes Usage and the mtime sync, stdout is blank ($1)"
      When run bash "$SCRIPT" "$1"
      The status should equal 0
      The output should be blank
      The stderr should include "Usage:"
      The stderr should include "workspaces/README.md"
      The stderr should include "rules/"
      The stderr should include "never overwritten"
      The stderr should include "mtime"
      The stderr should include "same content"
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

  Describe "Given: outdated workspaces README in the local-deckrd target"
    Before "setup_update_env"
    After "teardown_update_env"

    setup_workspaces_outdated() {
      make_asset local-deckrd "$DECKRD_LOCAL_DATA" workspaces/README.md new old "$NEW_MTIME" "$OLD_MTIME"
    }
    Before "setup_workspaces_outdated"

    It "[Normal] T-CLI-UPDI-11: Should: exit 0, print [local-deckrd] workspaces/README.md, and leave the file unchanged"
      When run bash "$SCRIPT"
      The status should equal 0
      The output should equal "[local-deckrd] workspaces/README.md"
      The contents of file "${DECKRD_LOCAL_WORKSPACES}/README.md" should equal "old"
    End
  End

  Describe "Given: workspaces directory missing and a workspaces README source in local-deckrd"
    Before "setup_update_env" "setup_workspaces_missing"
    After "teardown_update_env"

    It "[Normal] T-CLI-UPDI-12: Should: exit 0, print [local-deckrd] workspaces/README.md, and not create the directory"
      When run bash "$SCRIPT"
      The status should equal 0
      The output should equal "[local-deckrd] workspaces/README.md"
      The path "$DECKRD_LOCAL_WORKSPACES" should not be exist
    End
  End

  Describe "Given: workspaces directory missing and no workspaces README source in local-deckrd"
    Before "setup_update_env"
    After "teardown_update_env"

    setup_workspaces_missing_no_source() {
      rm -rf "${DECKRD_LOCAL_DATA}/workspaces"
    }
    Before "setup_workspaces_missing_no_source"

    It "[Edge] T-CLI-UPDI-13: Should: exit 0, print that assets are up to date, and not create the directory"
      When run bash "$SCRIPT"
      The status should equal 0
      The output should equal "Assets are up to date."
      The path "${DECKRD_LOCAL_DATA}/workspaces" should not be exist
    End
  End

  Describe "Given: workspaces README path occupied by a dangling symlink and a workspaces README source in local-deckrd"
    Skip if "dangling symlinks are not supported on this host" dangling_symlink_unsupported
    Before "setup_update_env" "setup_workspaces_missing" "setup_workspaces_readme_dangling_symlink"
    After "teardown_update_env"

    # A dangling symlink at the README path counts as deployed, so list_asset_files skips it
    It "[Edge] T-CLI-UPDI-14: Should: exit 0, print up to date, and keep the symlink without creating its target"
      When run bash "$SCRIPT"
      The status should equal 0
      The output should equal "Assets are up to date."
      The path "${DECKRD_LOCAL_DATA}/workspaces/README.md" should be symlink
      The path "$(dangling_readme_target)" should not be exist
    End
  End

  Describe "Given: non-keep .org source newer than its differing deployed file"
    Before "setup_update_env" "make_org_outdated"
    After "teardown_update_env"

    # rules/x.md matches no keep pattern, so it is listed by its destination path (.org dropped)
    It "[Normal] T-CLI-UPDI-15: Should: exit 0, print [docs] rules/x.md without .org, and leave the deployed file unchanged"
      When run bash "$SCRIPT"
      The status should equal 0
      The output should equal "[docs] rules/x.md"
      The contents of file "${DECKRD_DOCS_DIR}/rules/x.md" should equal "old"
      The path "${DECKRD_DOCS_DIR}/rules/x.md.org" should not be exist
    End
  End

  Describe "Given: no local gitignore and a .gitignore.org template with the workspaces rule"
    Before "setup_update_env" "make_gitignore_template_only"
    After "teardown_update_env"

    # Keep patterns protect only an existing .gitignore, so a missing one is listed
    It "[Edge] T-CLI-UPDI-16: Should: exit 0, print [local-deckrd] .gitignore without the workspaces rule label, and create no file"
      When run bash "$SCRIPT"
      The status should equal 0
      The output should equal "[local-deckrd] .gitignore"
      The output should not include "(workspaces rule)"
      The path "${DECKRD_LOCAL_DATA}/.gitignore" should not be exist
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
      make_asset docs "$DECKRD_DOCS_DIR" rules/a.md new old "$NEW_MTIME" "$OLD_MTIME"
    }
    Before "setup_one_outdated_for_update"

    It "[Normal] T-CLI-UPDA-01: Should: exit 0, print Updated: [label] dst_rel, and overwrite with the source"
      When run bash "$SCRIPT" --update
      The status should equal 0
      The output should equal "Updated: [docs] rules/a.md"
      The contents of file "${DECKRD_DOCS_DIR}/rules/a.md" should equal "new"
    End
  End

  Describe "Given: nested .gitignore.org source newer than its differing deployed .gitignore"
    Before "setup_update_env"
    After "teardown_update_env"

    # rules/.gitignore matches the keep pattern */.gitignore, so it is never overwritten
    setup_org_outdated() {
      mkdir -p "${INITS_DIR}/docs/rules" "${DECKRD_DOCS_DIR}/rules"
      printf '%s\n' new >"${INITS_DIR}/docs/rules/.gitignore.org"
      printf '%s\n' old >"${DECKRD_DOCS_DIR}/rules/.gitignore"
      touch -d "$NEW_MTIME" "${INITS_DIR}/docs/rules/.gitignore.org"
      touch -d "$OLD_MTIME" "${DECKRD_DOCS_DIR}/rules/.gitignore"
    }
    Before "setup_org_outdated"

    It "[Edge] T-CLI-UPDA-02: Should: exit 0, print up to date, and keep the deployed .gitignore"
      When run bash "$SCRIPT" --update
      The status should equal 0
      The output should equal "Assets are up to date."
      The contents of file "${DECKRD_DOCS_DIR}/rules/.gitignore" should equal "old"
    End
  End

  Describe "Given: deployed file edited by the user (newer than a differing source)"
    Before "setup_update_env"
    After "teardown_update_env"

    setup_user_edited_for_update() {
      make_asset docs "$DECKRD_DOCS_DIR" rules/a.md new edited "$OLD_MTIME" "$NEW_MTIME"
    }
    Before "setup_user_edited_for_update"

    It "[Edge] T-CLI-UPDA-03: Should: exit 0, print up to date, and keep the edited file"
      When run bash "$SCRIPT" --update
      The status should equal 0
      The output should equal "Assets are up to date."
      The contents of file "${DECKRD_DOCS_DIR}/rules/a.md" should equal "edited"
    End
  End

  Describe "Given: source file that has not been deployed"
    Before "setup_update_env"
    After "teardown_update_env"

    setup_undeployed_for_update() {
      mkdir -p "${INITS_DIR}/docs/rules"
      printf '%s\n' new >"${INITS_DIR}/docs/rules/new-rule.md"
    }
    Before "setup_undeployed_for_update"

    It "[Edge] T-CLI-UPDA-04: Should: exit 0, print Updated: [label] dst_rel, and deploy the file"
      When run bash "$SCRIPT" --update
      The status should equal 0
      The output should equal "Updated: [docs] rules/new-rule.md"
      The contents of file "${DECKRD_DOCS_DIR}/rules/new-rule.md" should equal "new"
    End
  End

  Describe "Given: session.json does not exist"
    Before "setup_update_env"
    After "teardown_update_env"

    setup_no_session_for_update() {
      remove_session
      make_asset docs "$DECKRD_DOCS_DIR" rules/a.md new old "$NEW_MTIME" "$OLD_MTIME"
    }
    Before "setup_no_session_for_update"

    It "[Error] T-CLI-UPDA-05: Should: exit 1, stderr prompts init, and leave the deployed file unchanged"
      When run bash "$SCRIPT" --update
      The status should equal 1
      The output should be blank
      The stderr should include "init"
      The contents of file "${DECKRD_DOCS_DIR}/rules/a.md" should equal "old"
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

  Describe "Given: outdated workspaces README in the local-deckrd target"
    Before "setup_update_env"
    After "teardown_update_env"

    setup_workspaces_outdated_for_update() {
      make_asset local-deckrd "$DECKRD_LOCAL_DATA" workspaces/README.md new old "$NEW_MTIME" "$OLD_MTIME"
    }
    Before "setup_workspaces_outdated_for_update"

    It "[Normal] T-CLI-UPDA-15: Should: exit 0, print Updated: [local-deckrd] workspaces/README.md, and overwrite with the source"
      When run bash "$SCRIPT" --update
      The status should equal 0
      The output should equal "Updated: [local-deckrd] workspaces/README.md"
      The contents of file "${DECKRD_LOCAL_WORKSPACES}/README.md" should equal "new"
    End
  End

  Describe "Given: workspaces directory missing and a workspaces README source in local-deckrd"
    Before "setup_update_env" "setup_workspaces_missing"
    After "teardown_update_env"

    It "[Normal] T-CLI-UPDA-16: Should: exit 0, print Updated: [local-deckrd] workspaces/README.md, and create the directory with the source copy"
      When run bash "$SCRIPT" --update
      The status should equal 0
      The output should equal "Updated: [local-deckrd] workspaces/README.md"
      The contents of file "${DECKRD_LOCAL_WORKSPACES}/README.md" should equal "$(cat "${INITS_DIR}/local-deckrd/workspaces/README.md")"
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
      The contents of file "${DECKRD_LOCAL_WORKSPACES}/README.md" should equal "$(cat "${INITS_DIR}/local-deckrd/workspaces/README.md")"
    End
  End

  Describe "Given: workspaces README path occupied by a directory and a workspaces README source in local-deckrd"
    Before "setup_update_env" "setup_workspaces_missing"
    After "teardown_update_env"

    # Any existing entry at the README path counts as deployed
    setup_workspaces_readme_dir() {
      mkdir -p "${DECKRD_LOCAL_DATA}/workspaces/README.md"
    }
    Before "setup_workspaces_readme_dir"

    It "[Edge] T-CLI-UPDA-18: Should: exit 0, print up to date, and copy nothing into the README directory"
      When run bash "$SCRIPT" --update
      The status should equal 0
      The output should equal "Assets are up to date."
      The path "${DECKRD_LOCAL_DATA}/workspaces/README.md" should be directory
      The path "${DECKRD_LOCAL_DATA}/workspaces/README.md/README.md" should not be exist
    End
  End

  Describe "Given: workspaces path occupied by a regular file, a workspaces README source, and another outdated local-deckrd file"
    Before "setup_update_env" "setup_workspaces_missing"
    After "teardown_update_env"

    # A regular file at the workspaces path makes mkdir -p fail. a.md sorts before
    # workspaces/README.md, so it is copied first, yet its Updated: line must not be printed.
    setup_workspaces_path_file() {
      : >"$DECKRD_LOCAL_WORKSPACES"
      make_asset local-deckrd "$DECKRD_LOCAL_DATA" a.md new old "$NEW_MTIME" "$OLD_MTIME"
    }
    Before "setup_workspaces_path_file"

    It "[Error] T-CLI-UPDA-19: Should: exit 1, stderr reports the failed copy, print no Updated: line, and leave the workspaces path a regular file"
      When run bash "$SCRIPT" --update
      The status should equal 1
      The stderr should include "Error:"
      The stderr should include "${DECKRD_LOCAL_WORKSPACES}/README.md"
      The output should not include "Updated:"
      The path "${DECKRD_LOCAL_DATA}/workspaces" should be file
    End
  End

  Describe "Given: workspaces directory with another file but no README and a workspaces README source in local-deckrd"
    Before "setup_update_env"
    After "teardown_update_env"

    # Keeps the workspaces directory (unlike setup_workspaces_missing) so that only the README is missing
    setup_workspaces_readme_only_missing() {
      mkdir -p "${INITS_DIR}/local-deckrd/workspaces"
      printf '%s\n' '# workspaces' >"${INITS_DIR}/local-deckrd/workspaces/README.md"
      printf '%s\n' 'keep' >"${DECKRD_LOCAL_WORKSPACES}/notes.md"
    }
    Before "setup_workspaces_readme_only_missing"

    It "[Edge] T-CLI-UPDA-20: Should: exit 0, print Updated: [local-deckrd] workspaces/README.md, copy the source, and keep other files"
      When run bash "$SCRIPT" --update
      The status should equal 0
      The output should equal "Updated: [local-deckrd] workspaces/README.md"
      The contents of file "${DECKRD_LOCAL_WORKSPACES}/README.md" should equal "$(cat "${INITS_DIR}/local-deckrd/workspaces/README.md")"
      The contents of file "${DECKRD_LOCAL_WORKSPACES}/notes.md" should equal "keep"
    End
  End

  Describe "Given: workspaces README path occupied by a dangling symlink and a workspaces README source in local-deckrd"
    Skip if "dangling symlinks are not supported on this host" dangling_symlink_unsupported
    Before "setup_update_env" "setup_workspaces_missing" "setup_workspaces_readme_dangling_symlink"
    After "teardown_update_env"

    # A dangling symlink at the README path counts as deployed, so nothing is copied over it
    It "[Edge] T-CLI-UPDA-21: Should: exit 0, print up to date, and keep the symlink without creating its target"
      When run bash "$SCRIPT" --update
      The status should equal 0
      The output should equal "Assets are up to date."
      The path "${DECKRD_LOCAL_DATA}/workspaces/README.md" should be symlink
      The path "$(dangling_readme_target)" should not be exist
    End
  End

  Describe "Given: non-keep .org source newer than its differing deployed file"
    Before "setup_update_env" "make_org_outdated"
    After "teardown_update_env"

    # Counterpart of UPDA-02: rules/x.md matches no keep pattern, so it is copied to the
    # destination path with .org dropped
    It "[Normal] T-CLI-UPDA-22: Should: exit 0, print Updated: [docs] rules/x.md, overwrite x.md with the source, and create no x.md.org"
      When run bash "$SCRIPT" --update
      The status should equal 0
      The output should equal "Updated: [docs] rules/x.md"
      The contents of file "${DECKRD_DOCS_DIR}/rules/x.md" should equal "new"
      The path "${DECKRD_DOCS_DIR}/rules/x.md.org" should not be exist
    End
  End

  Describe "Given: .org source whose destination directory path is occupied by a regular file"
    Before "setup_update_env" "make_org_rules_path_file"
    After "teardown_update_env"

    # A regular file at the rules path makes mkdir -p fail; the error names the destination
    # path (.org dropped), not the source path
    It "[Error] T-CLI-UPDA-23: Should: exit 1, report the destination path without .org, and print no Updated: line"
      When run bash "$SCRIPT" --update
      The status should equal 1
      The stderr should include "Error: failed to copy file: ${DECKRD_DOCS_DIR}/rules/x.md"
      The stderr should not include "x.md.org"
      The output should not include "Updated:"
      The path "${DECKRD_DOCS_DIR}/rules" should be file
    End
  End

  Describe "Given: no local gitignore and a .gitignore.org template with the workspaces rule"
    Before "setup_update_env" "make_gitignore_template_only"
    After "teardown_update_env"

    # The copied template already has the workspaces rule, so the rule label is not printed
    It "[Edge] T-CLI-UPDA-24: Should: exit 0, print Updated: [local-deckrd] .gitignore without the workspaces rule label, and create it from the template"
      When run bash "$SCRIPT" --update
      The status should equal 0
      The output should equal "Updated: [local-deckrd] .gitignore"
      The output should not include "(workspaces rule)"
      The contents of file "${DECKRD_LOCAL_DATA}/.gitignore" should equal "$(_local_gitignore_template)"
    End
  End

  # UPDA-25 / UPDA-27 form the older / newer boundary pair of the mtime sync:
  # only a same-content deployed file older than its source gets the source's mtime.
  Describe "Given: deployed file with the same content as its source but an older mtime"
    Before "setup_update_env" "make_same_content_older"
    After "teardown_update_env"

    It "[Normal] T-CLI-UPDA-25: Should: exit 0, print up to date, and set the mtime of the same-content older file to the source's"
      When run bash "$SCRIPT" --update
      The status should equal 0
      The output should equal "Assets are up to date."
      The value "$(file_mtime "${DECKRD_DOCS_DIR}/rules/a.md")" should equal "$(file_mtime "${INITS_DIR}/docs/rules/a.md")"
      The contents of file "${DECKRD_DOCS_DIR}/rules/a.md" should equal "same"
    End
  End

  Describe "Given: deployed file with the same content as its source but an older mtime, without session.json"
    Before "setup_update_env" "make_same_content_older" "remove_session"
    After "teardown_update_env"

    It "[Error] T-CLI-UPDA-26: Should: exit 1, stderr prompts init, and leave the mtime of the same-content older file unchanged"
      When run bash "$SCRIPT" --update
      The status should equal 1
      The output should be blank
      The stderr should include "init"
      The value "$(file_mtime "${DECKRD_DOCS_DIR}/rules/a.md")" should equal "$(epoch_of "$OLD_MTIME")"
    End
  End

  Describe "Given: deployed file with the same content as its source but a newer mtime"
    Before "setup_update_env"
    After "teardown_update_env"

    setup_same_content_newer() {
      make_asset docs "$DECKRD_DOCS_DIR" rules/a.md same same "$OLD_MTIME" "$NEW_MTIME"
    }
    Before "setup_same_content_newer"

    # Boundary of UPDA-25: a newer deployed file is not touched back to the source's mtime
    It "[Edge] T-CLI-UPDA-27: Should: exit 0, print up to date, and keep the newer mtime of the same-content file"
      When run bash "$SCRIPT" --update
      The status should equal 0
      The output should equal "Assets are up to date."
      The value "$(file_mtime "${DECKRD_DOCS_DIR}/rules/a.md")" should equal "$(epoch_of "$NEW_MTIME")"
    End
  End

End
