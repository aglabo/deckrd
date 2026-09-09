#!/usr/bin/env bash
# plugins/deckrd/skills/deckrd/scripts/tests/integration/init.spec.sh
# @(#) : Integration tests for init.sh - main() full execution (no mocks)
#
# Copyright (c) 2026- atsushifx <https://github.com/atsushifx>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

# shellcheck disable=SC1090

_RUNTIME_BOOTSTRAP="${SHELLSPEC_PROJECT_ROOT}/skills/deckrd/skills/deckrd/scripts/libs/bootstrap.lib.sh"
. "$_RUNTIME_BOOTSTRAP" "--no-finalize"
unset _RUNTIME_BOOTSTRAP

Include ../spec_helper.sh

SCRIPT="${DECKRD_SCRIPTS_DIR}/init.sh"

# ============================================================================
# init.sh: main() integration
# ============================================================================

Describe "init.sh: main() integration"

  Describe "Given: no arguments provided"
    Before "setup_deckrd_tmpdir"
    After "teardown_deckrd_tmpdir"

    It "[Error] T-CLI-MAINI-01: Should: exit 1, stderr includes Usage and 'required', stdout is blank"
      When run bash "$SCRIPT"
      The status should equal 1
      # @note: --json モード追加時はこのアサーションを見直すこと
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
      # @note: --json モード追加時はこのアサーションを見直すこと
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
      # @note: --json モード追加時はこのアサーションを見直すこと
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
      # @note: --json モード追加時はこのアサーションを見直すこと
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
      # @note: --json モード追加時はこのアサーションを見直すこと
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
      # @note: --json モード追加時はこのアサーションを見直すこと
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
      # @note: --json モード追加時はこのアサーションを見直すこと
      The output should be blank
      The stderr should include "unknown AI model"
    End

    It "[Error] T-CLI-MAINI-25: --ai-model 'bad model!' (invalid characters)"
      When run bash "$SCRIPT" myapp webapp --ai-model "bad model!"
      The status should equal 1
      # @note: --json モード追加時はこのアサーションを見直すこと
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
      # @note: --json モード追加時はこのアサーションを見直すこと
      The output should be blank
      The stderr should include "Init complete"
    End

    It "[Error] T-CLI-MAINI-30: no arguments: stdout is blank"
      When run bash "$SCRIPT"
      The status should equal 1
      # @note: --json モード追加時はこのアサーションを見直すこと
      The output should be blank
      The stderr should include "Error:"
    End

    It "[Error] T-CLI-MAINI-31: invalid language: stdout is blank"
      When run bash "$SCRIPT" myapp webapp --language cobol
      The status should equal 1
      # @note: --json モード追加時はこのアサーションを見直すこと
      The output should be blank
      The stderr should include "Error:"
    End

    It "[Error] T-CLI-MAINI-32: invalid ai-model: stdout is blank"
      When run bash "$SCRIPT" myapp webapp --ai-model "bad model!"
      The status should equal 1
      # @note: --json モード追加時はこのアサーションを見直すこと
      The output should be blank
      The stderr should include "Error:"
    End
  End

End
