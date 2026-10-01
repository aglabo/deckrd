#!/usr/bin/env bash
# plugins/deckrd/skills/deckrd/scripts/tests/integration/init.spec.sh
# @(#) : Integration tests for init.sh - main() full execution (no mocks)
#
# Copyright (c) 2026- atsushifx <https://github.com/atsushifx>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

# cspell:words MAINI

# shellcheck disable=SC1090

_RUNTIME_BOOTSTRAP="${SHELLSPEC_PROJECT_ROOT}/skills/deckrd/skills/deckrd/scripts/libs/bootstrap.lib.sh"
. "$_RUNTIME_BOOTSTRAP" "--no-finalize"
unset _RUNTIME_BOOTSTRAP

Include ../spec_helper.sh

SCRIPT="${DECKRD_SCRIPTS_DIR}/init.sh"

# ============================================================================
# init.sh: main() integration
# ============================================================================

Describe "T-CLI-MAINI: init.sh: main() integration"

  Describe "Given: no arguments provided"
    Before "setup_deckrd_tmpdir"
    After "teardown_deckrd_tmpdir"

    It "[Error] T-CLI-MAINI-01: Should: exit 1, stderr includes Usage and 'required', stdout is blank"
      When run bash "$SCRIPT"
      The status should equal 1
      # @note: revisit this assertion when --json mode is added
      The output should be blank
      The stderr should include "Usage:"
      The stderr should include "required"
    End
  End

  Describe "Given: project name only"
    Before "setup_deckrd_tmpdir"
    After "teardown_deckrd_tmpdir"

    It "[Error] T-CLI-MAINI-02: Should: exit 1, stderr includes Usage and 'required', stdout is blank"
      When run bash "$SCRIPT" myapp
      The status should equal 1
      # @note: revisit this assertion when --json mode is added
      The output should be blank
      The stderr should include "Usage:"
      The stderr should include "required"
    End
  End

  Describe "Given: --help option"
    Before "setup_deckrd_tmpdir"
    After "teardown_deckrd_tmpdir"

    It "[Normal] T-CLI-MAINI-03: Should: exit 0, stderr includes Usage, stdout is blank"
      When run bash "$SCRIPT" --help
      The status should equal 0
      # @note: revisit this assertion when --json mode is added
      The output should be blank
      The stderr should include "Usage:"
    End
  End

  Describe "Given: unknown option"
    Before "setup_deckrd_tmpdir"
    After "teardown_deckrd_tmpdir"

    It "[Error] T-CLI-MAINI-04: Should: exit 1, stderr includes Usage and 'Unknown option', stdout is blank"
      When run bash "$SCRIPT" myapp webapp --unknown
      The status should equal 1
      # @note: revisit this assertion when --json mode is added
      The output should be blank
      The stderr should include "Usage:"
      The stderr should include "Unknown option"
    End
  End

  Describe "Given: valid 'myapp webapp'"
    Before "setup_deckrd_tmpdir"
    After "teardown_deckrd_tmpdir"

    It "[Normal] T-CLI-MAINI-05: stderr includes project name/type/Init complete/Session, stdout is blank"
      When run bash "$SCRIPT" myapp webapp
      The status should equal 0
      # @note: revisit this assertion when --json mode is added
      The output should be blank
      The stderr should include "myapp"
      The stderr should include "webapp"
      The stderr should include "Init complete"
      The stderr should include "Session"
    End

    It "[Normal] T-CLI-MAINI-06: Should: create DECKRD_DOCS, notes/, temp/ directories"
      When run bash "$SCRIPT" myapp webapp
      The status should equal 0
      The stderr should include "Init complete"
      The path "${DECKRD_DOCS_DIR}" should be directory
      The path "${DECKRD_DOCS_DIR}/notes" should be directory
      The path "${DECKRD_DOCS_DIR}/temp" should be directory
    End

    It "[Normal] T-CLI-MAINI-07: Should: create DECKRD_LOCAL_DATA directory"
      When run bash "$SCRIPT" myapp webapp
      The status should equal 0
      The stderr should include "Init complete"
      The path "${DECKRD_LOCAL_DATA}" should be directory
    End

    It "[Normal] T-CLI-MAINI-46: Should: create the temporary working directory under DECKRD_LOCAL_DATA"
      When run bash "$SCRIPT" myapp webapp
      The status should equal 0
      The stderr should include "Init complete"
      The path "${DECKRD_LOCAL_DATA}/temp" should be directory
    End

    It "[Normal] T-CLI-MAINI-47: Should: create the shared workspaces directory under DECKRD_LOCAL_DATA"
      When run bash "$SCRIPT" myapp webapp
      The status should equal 0
      The stderr should include "Init complete"
      The path "${DECKRD_LOCAL_DATA}/workspaces" should be directory
    End

    It "[Normal] T-CLI-MAINI-55: Should: create every ASSET_TARGETS destination directory"
      # Runs init.sh, then checks each dest of the shared asset target list.
      # Prints the first missing dest so a failure names it.
      _init_and_check_asset_dests() {
        bash "$SCRIPT" myapp webapp 2>/dev/null || return 1
        # shellcheck disable=SC1091
        . "${DECKRD_LIB_DIR}/asset-diff.lib.sh"
        init_asset_dirs
        local entry dest
        for entry in "${ASSET_TARGETS[@]}"; do
          IFS='|' read -r _ _ dest <<<"$entry"
          [[ -d "$dest" ]] || {
            echo "missing: ${dest}"
            return 1
          }
        done
      }
      When call _init_and_check_asset_dests
      The status should be success
      The output should be blank
    End

    It "[Normal] T-CLI-MAINI-48: Should: install README.md into the workspaces directory"
      When run bash "$SCRIPT" myapp webapp
      The status should equal 0
      The stderr should include "[init/local-workspaces] copied: README.md"
      The path "${DECKRD_LOCAL_DATA}/workspaces/README.md" should be file
    End

    It "[Normal] T-CLI-MAINI-08: Should: create .project.json with project, project-type, language"
      When run bash "$SCRIPT" myapp webapp
      The status should equal 0
      The stderr should include "Project written"
      The path "${DECKRD_LOCAL_DATA}/.project.json" should be exist
      The contents of file "${DECKRD_LOCAL_DATA}/.project.json" should include "myapp"
      The contents of file "${DECKRD_LOCAL_DATA}/.project.json" should include "webapp"
      The contents of file "${DECKRD_LOCAL_DATA}/.project.json" should include "typescript"
    End

    It "[Normal] T-CLI-MAINI-09: Should: create session.json with v0.1.0 schema (active, lang, modules)"
      When run bash "$SCRIPT" myapp webapp
      The status should equal 0
      The stderr should include "Session"
      The path "${DECKRD_LOCAL_DATA}/session.json" should be exist
      The contents of file "${DECKRD_LOCAL_DATA}/session.json" should include "active"
      The contents of file "${DECKRD_LOCAL_DATA}/session.json" should include "typescript"
      The contents of file "${DECKRD_LOCAL_DATA}/session.json" should include "modules"
    End

    It "[Normal] T-CLI-MAINI-10: Should: create .gitignore in DECKRD_LOCAL_DATA containing '*kv'"
      When run bash "$SCRIPT" myapp webapp
      The status should equal 0
      The stderr should include "[init/local-deckrd] copied: .gitignore"
      The path "${DECKRD_LOCAL_DATA}/.gitignore" should be exist
      The contents of file "${DECKRD_LOCAL_DATA}/.gitignore" should include "*kv"
    End

    It "[Normal] T-CLI-MAINI-11: .gitignore が fixture と一致"
      When run bash "$SCRIPT" myapp webapp
      The status should equal 0
      The stderr should include "Init complete"
      The contents of file "${DECKRD_LOCAL_DATA}/.gitignore" \
        should equal "$(load_asset "inits/local-deckrd/.gitignore.org")"
    End
  End

  Describe "Given: deckrd-rules assets are installed"
    After "teardown_deckrd_tmpdir"

    Describe "When: both rules directories are empty"
      Before "setup_deckrd_tmpdir"

      It "[Normal] T-CLI-MAINI-12: Should: install rule bodies into DECKRD_RULES_DIR, renaming .gitignore.org"
        When run bash "$SCRIPT" myapp webapp
        The status should equal 0
        The stderr should include "[init/deckrd-rules] copied: .gitignore"
        The path "${DECKRD_RULES_DIR}/deckrd-rule-bdd-cycle.md" should be exist
        The path "${DECKRD_RULES_DIR}/.gitignore" should be exist
        The path "${DECKRD_RULES_DIR}/.gitignore.org" should not be exist
      End

      It "[Normal] T-CLI-MAINI-13: Should: install injected rules into CLAUDE_RULES_DIR"
        When run bash "$SCRIPT" myapp webapp
        The status should equal 0
        The stderr should include "[init/claude-rules] copied: claude-rule-command-execute.md"
        The path "${CLAUDE_RULES_DIR}/claude-rule-command-execute.md" should be exist
        The path "${CLAUDE_RULES_DIR}/deckrd-rule-bdd-cycle.md" should not be exist
      End

      It "[Normal] T-CLI-MAINI-14: Should: install only the index into CLAUDE_RULES_INDEX_DIR, not the rule bodies"
        When run bash "$SCRIPT" myapp webapp
        The status should equal 0
        The stderr should include "[init/deckrd-rules-index] copied: deckrd-rules-index.md"
        The path "${CLAUDE_RULES_INDEX_DIR}/deckrd-rules-index.md" should be exist
        The path "${CLAUDE_RULES_INDEX_DIR}/deckrd-rule-bdd-cycle.md" should not be exist
      End

      It "[Edge] T-CLI-MAINI-39: Should: first run does not notify rules updates"
        When run bash "$SCRIPT" myapp webapp
        The status should equal 0
        The stderr should include "Session created"
        The stderr should not include "Rules update available"
      End
    End

    Describe "When: DECKRD_RULES_DIR/.gitignore already exists"
      setup_with_existing_rules_gitignore() {
        setup_deckrd_tmpdir
        mkdir -p "$DECKRD_RULES_DIR"
        touch "${DECKRD_RULES_DIR}/.gitignore"
      }
      Before "setup_with_existing_rules_gitignore"

      It "[Edge] T-CLI-MAINI-15: Should: skip with stripped filename 'skip (exists): .gitignore'"
        When run bash "$SCRIPT" myapp webapp
        The status should equal 0
        The stderr should include "[init/deckrd-rules] skip (exists): .gitignore"
        The stderr should not include "skip (exists): .gitignore.org"
      End

      It "[Edge] T-CLI-MAINI-40: Should: not notify a differing file when session.json does not exist"
        When run bash "$SCRIPT" myapp webapp
        The status should equal 0
        The stderr should include "[init/deckrd-rules] skip (exists): .gitignore"
        The stderr should not include "Rules update available"
      End
    End
  End

  Describe "Given: session.json already exists"
    After "teardown_deckrd_tmpdir"

    setup_session() {
      setup_deckrd_tmpdir
      bash "$SCRIPT" myapp webapp >/dev/null 2>&1
    }
    Before "setup_session"

    It "[Normal] T-CLI-MAINI-16: Should: exit 0 and stderr includes 'Session preserved'"
      When run bash "$SCRIPT" myapp webapp
      The status should equal 0
      The stderr should include "Session preserved"
    End

    It "[Normal] T-CLI-MAINI-37: Should: not notify rules updates when no installed asset differs"
      When run bash "$SCRIPT" myapp webapp
      The status should equal 0
      The stderr should include "Session preserved"
      The stderr should not include "Rules update available"
    End

    It "[Edge] T-CLI-MAINI-45: Should: exit 0 without notifying rules updates and keep an outdated installed file"
      printf '\n# local change\n' >>"${DECKRD_RULES_DIR}/deckrd-rule-workflow.md"
      touch -d '2000-01-01 00:00:00' "${DECKRD_RULES_DIR}/deckrd-rule-workflow.md"
      EXPECTED_WORKFLOW="$(cat "${DECKRD_RULES_DIR}/deckrd-rule-workflow.md")"
      When run bash "$SCRIPT" myapp webapp
      The status should equal 0
      The stderr should include "Session preserved"
      The stderr should not include "Rules update available"
      The contents of file "${DECKRD_RULES_DIR}/deckrd-rule-workflow.md" should equal "$EXPECTED_WORKFLOW"
    End
  End

  Describe "Given: .gitignore already exists"
    After "teardown_deckrd_tmpdir"

    setup_with_existing_gitignore() {
      setup_deckrd_tmpdir
      bash "$SCRIPT" myapp webapp >/dev/null 2>&1
    }
    Before "setup_with_existing_gitignore"

    It "[Normal] T-CLI-MAINI-17: Should: exit 0 and stderr includes 'skip (exists): .gitignore'"
      When run bash "$SCRIPT" myapp webapp
      The status should equal 0
      The stderr should include "skip (exists): .gitignore"
      The path "${DECKRD_LOCAL_DATA}/.gitignore" should be exist
    End
  End

  Describe "Given: --language option"
    Before "setup_deckrd_tmpdir"
    After "teardown_deckrd_tmpdir"

    It "[Normal] T-CLI-MAINI-18: --language go"
      When run bash "$SCRIPT" myapp webapp --language go
      The status should equal 0
      The stderr should include "go"
    End

    It "[Normal] T-CLI-MAINI-19: --language python"
      When run bash "$SCRIPT" myapp webapp --language python
      The status should equal 0
      The stderr should include "python"
    End

    It "[Normal] T-CLI-MAINI-20: --lang rust (alias)"
      When run bash "$SCRIPT" myapp webapp --lang rust
      The status should equal 0
      The stderr should include "rust"
    End

    It "[Normal] T-CLI-MAINI-21: --language=python (= syntax)"
      When run bash "$SCRIPT" myapp webapp --language=python
      The status should equal 0
      The stderr should include "python"
    End

    It "[Error] T-CLI-MAINI-22: --language cobol (unsupported)"
      When run bash "$SCRIPT" myapp webapp --language cobol
      The status should equal 1
      # @note: revisit this assertion when --json mode is added
      The output should be blank
      The stderr should include "Unsupported language"
    End
  End

  Describe "Given: --ai-model option"
    Before "setup_deckrd_tmpdir"
    After "teardown_deckrd_tmpdir"

    It "[Normal] T-CLI-MAINI-23: --ai-model claude-sonnet-4-5"
      When run bash "$SCRIPT" myapp webapp --ai-model claude-sonnet-4-5
      The status should equal 0
      The stderr should include "claude-sonnet-4-5"
    End

    It "[Error] T-CLI-MAINI-24: --ai-model org/model-name (unknown provider)"
      When run bash "$SCRIPT" myapp webapp --ai-model org/model-name
      The status should equal 1
      # @note: revisit this assertion when --json mode is added
      The output should be blank
      The stderr should include "unknown AI model"
    End

    It "[Error] T-CLI-MAINI-25: --ai-model 'bad model!' (invalid characters)"
      When run bash "$SCRIPT" myapp webapp --ai-model "bad model!"
      The status should equal 1
      # @note: revisit this assertion when --json mode is added
      The output should be blank
      The stderr should include "AI model"
    End
  End

  Describe "Given: default variable values"
    Before "setup_deckrd_tmpdir"
    After "teardown_deckrd_tmpdir"

    It "[Normal] T-CLI-MAINI-26: default language is typescript"
      When run bash "$SCRIPT" myapp webapp
      The status should equal 0
      The stderr should include "Init complete"
      The contents of file "${DECKRD_LOCAL_DATA}/.project.json" should include "typescript"
    End

    It "[Normal] T-CLI-MAINI-27: default ai_model is sonnet"
      When run bash "$SCRIPT" myapp webapp
      The status should equal 0
      The stderr should include "Init complete"
      The contents of file "${DECKRD_LOCAL_DATA}/.project.json" should include "sonnet"
    End
  End

  Describe "Given: .project.json already exists"
    After "teardown_deckrd_tmpdir"

    setup_with_initial_run() {
      setup_deckrd_tmpdir
      bash "$SCRIPT" myapp webapp >/dev/null 2>&1
      CREATED_AT_BEFORE=$(jq -r '.created_at' "${DECKRD_LOCAL_DATA}/.project.json")
      export CREATED_AT_BEFORE
    }
    Before "setup_with_initial_run"

    It "[Edge] T-CLI-MAINI-28: Should: preserve created_at on re-run"
      When run bash "$SCRIPT" myapp lib
      The status should equal 0
      The stderr should include "Project written"
      The contents of file "${DECKRD_LOCAL_DATA}/.project.json" should include "$CREATED_AT_BEFORE"
    End
  End

  Describe "Given: stdout/stderr separation"
    Before "setup_deckrd_tmpdir"
    After "teardown_deckrd_tmpdir"

    It "[Normal] T-CLI-MAINI-29: successful run: stdout is blank"
      When run bash "$SCRIPT" myapp webapp
      The status should equal 0
      # @note: revisit this assertion when --json mode is added
      The output should be blank
      The stderr should include "Init complete"
    End

    It "[Error] T-CLI-MAINI-30: no arguments: stdout is blank"
      When run bash "$SCRIPT"
      The status should equal 1
      # @note: revisit this assertion when --json mode is added
      The output should be blank
      The stderr should include "Error:"
    End

    It "[Error] T-CLI-MAINI-31: invalid language: stdout is blank"
      When run bash "$SCRIPT" myapp webapp --language cobol
      The status should equal 1
      # @note: revisit this assertion when --json mode is added
      The output should be blank
      The stderr should include "Error:"
    End

    It "[Error] T-CLI-MAINI-32: invalid ai-model: stdout is blank"
      When run bash "$SCRIPT" myapp webapp --ai-model "bad model!"
      The status should equal 1
      # @note: revisit this assertion when --json mode is added
      The output should be blank
      The stderr should include "Error:"
    End

    Describe "When: validate_env fails"
      mock_validate_env_failure() {
        # shellcheck disable=SC2329
        validate_env() { echo "Error: jq or jaq is required but not installed." >&2; return 1; }
        export -f validate_env
      }
      unmock_validate_env_failure() {
        unset -f validate_env
      }
      Before "mock_validate_env_failure"
      After "unmock_validate_env_failure"

      It "[Error] T-CLI-MAINI-33: validate_env failure: stderr is the library message only"
        When run bash "$SCRIPT" myapp webapp
        The status should equal 1
        The lines of entire stderr should eq 1
        The stderr should include "jq or jaq is required"
      End
    End
  End

  Describe "Given: project is already initialized"
    After "teardown_deckrd_tmpdir"

    setup_initialized() {
      setup_deckrd_tmpdir
      bash "$SCRIPT" myapp webapp >/dev/null 2>&1
    }
    Before "setup_initialized"

    # Simulate an outdated install: upstream source updated after installation
    # (installed content differs and is older than the source)
    make_outdated_install() {
      local file
      for file in "$@"; do
        printf '\n# local change\n' >>"$file"
        touch -d '2000-01-01 00:00:00' "$file"
      done
    }

    Describe "When: an installed asset was edited by the user"
      It "[Edge] T-CLI-MAINI-44: Should: exit 0 without notifying rules updates and keep the edited file"
        printf '\n# user edit\n' >>"${DECKRD_RULES_DIR}/deckrd-rule-workflow.md"
        EXPECTED_WORKFLOW="$(cat "${DECKRD_RULES_DIR}/deckrd-rule-workflow.md")"
        When run bash "$SCRIPT" myapp webapp
        The status should equal 0
        The stderr should not include "Rules update available"
        The contents of file "${DECKRD_RULES_DIR}/deckrd-rule-workflow.md" should equal "$EXPECTED_WORKFLOW"
      End
    End

    Describe "When: an installed asset was deleted"
      It "[Edge] T-CLI-MAINI-42: Should: copy the missing file again without notifying rules updates"
        rm "${DECKRD_RULES_DIR}/deckrd-rule-workflow.md"
        When run bash "$SCRIPT" myapp webapp
        The status should equal 0
        The stderr should include "[init/deckrd-rules] copied: deckrd-rule-workflow.md"
        The stderr should not include "Rules update available"
      End
    End

    Describe "When: arguments are invalid"
      It "[Error] T-CLI-MAINI-38: Should: exit 1 without notifying rules updates for --language cobol"
        make_outdated_install "${DECKRD_RULES_DIR}/deckrd-rule-workflow.md"
        When run bash "$SCRIPT" myapp webapp --language cobol
        The status should equal 1
        # @note: revisit this assertion when --json mode is added
        The output should be blank
        The stderr should include "Unsupported language"
        The stderr should not include "Rules update available"
      End
    End
  End

  Describe "Given: a local directory path is overridden"
    Before "setup_deckrd_tmpdir"
    After "teardown_deckrd_tmpdir"

    Describe "When: the path can be created"
      It "[Normal] T-CLI-MAINI-49: Should: exit 0 and create the overridden DECKRD_LOCAL_TEMP directory"
        export DECKRD_LOCAL_TEMP="${DECKRD_TMPDIR}/custom/temp"
        When run bash "$SCRIPT" myapp webapp
        The status should equal 0
        # @note: --json モード追加時はこのアサーションを見直すこと
        The output should be blank
        The stderr should include "Init complete."
        The stderr should not include "Error:"
        The path "${DECKRD_TMPDIR}/custom/temp" should be directory
      End
    End

    Describe "When: the path is under a regular file"
      _create_blocker() { : >"${DECKRD_TMPDIR}/blocker"; }
      Before "_create_blocker"

      It "[Error] T-CLI-MAINI-50: Should: exit 1 and report DECKRD_LOCAL_TEMP when it cannot be created"
        export DECKRD_LOCAL_TEMP="${DECKRD_TMPDIR}/blocker/temp"
        When run bash "$SCRIPT" myapp webapp
        The status should equal 1
        # @note: --json モード追加時はこのアサーションを見直すこと
        The output should be blank
        The stderr should include "Error:"
        The stderr should include "${DECKRD_TMPDIR}/blocker/temp"
        The stderr should not include "Init complete"
      End

      It "[Error] T-CLI-MAINI-51: Should: exit 1 and report DECKRD_LOCAL_WORKSPACES when it cannot be created"
        export DECKRD_LOCAL_WORKSPACES="${DECKRD_TMPDIR}/blocker/workspaces"
        When run bash "$SCRIPT" myapp webapp
        The status should equal 1
        # @note: --json モード追加時はこのアサーションを見直すこと
        The output should be blank
        The stderr should include "Error:"
        The stderr should include "${DECKRD_TMPDIR}/blocker/workspaces"
        The stderr should not include "[init/local-workspaces] copied:"
        The stderr should not include "Init complete"
      End

      It "[Error] T-CLI-MAINI-54: Should: not create workspaces, .project.json, or session.json after DECKRD_LOCAL_TEMP fails"
        export DECKRD_LOCAL_TEMP="${DECKRD_TMPDIR}/blocker/temp"
        When run bash "$SCRIPT" myapp webapp
        The status should equal 1
        # @note: --json モード追加時はこのアサーションを見直すこと
        The output should be blank
        The stderr should include "Error:"
        The path "${DECKRD_LOCAL_WORKSPACES}" should not be exist
        The path "${DECKRD_LOCAL_DATA}/.project.json" should not be exist
        The path "${DECKRD_LOCAL_DATA}/session.json" should not be exist
      End
    End

    Describe "When: the path itself is an existing regular file"
      It "[Edge] T-CLI-MAINI-53: Should: exit 1 and report DECKRD_LOCAL_TEMP when it is a regular file"
        : >"${DECKRD_TMPDIR}/tempfile"
        export DECKRD_LOCAL_TEMP="${DECKRD_TMPDIR}/tempfile"
        When run bash "$SCRIPT" myapp webapp
        The status should equal 1
        # @note: --json モード追加時はこのアサーションを見直すこと
        The output should be blank
        The stderr should include "Error:"
        The stderr should include "${DECKRD_TMPDIR}/tempfile"
        The stderr should not include "Init complete"
      End
    End

    Describe "When: copying an asset into the path fails"
      # Fake cp: fails only for workspaces/README.md, delegates everything else to the real cp
      _create_fake_cp() {
        local real_cp
        real_cp="$(command -v cp)"
        mkdir -p "${DECKRD_TMPDIR}/fakebin"
        cat >"${DECKRD_TMPDIR}/fakebin/cp" <<EOF
#!/usr/bin/env bash
case "\${!#}" in
*/workspaces/README.md) exit 1 ;;
esac
exec "${real_cp}" "\$@"
EOF
        chmod +x "${DECKRD_TMPDIR}/fakebin/cp"
      }
      Before "_create_fake_cp"

      It "[Error] T-CLI-MAINI-52: Should: exit 1 and report the destination file when cp fails"
        When run env PATH="${DECKRD_TMPDIR}/fakebin:${PATH}" bash "$SCRIPT" myapp webapp
        The status should equal 1
        # @note: --json モード追加時はこのアサーションを見直すこと
        The output should be blank
        The stderr should include "Error:"
        The stderr should include "${DECKRD_LOCAL_WORKSPACES}/README.md"
        The stderr should not include "[init/local-workspaces] copied: README.md"
        The stderr should not include "Init complete"
      End
    End
  End

End
