#!/usr/bin/env bash
# plugins/deckrd/skills/deckrd/scripts/tests/unit/init.spec.sh
# @(#) : BDD unit tests for init.sh (プロジェクト初期化スクリプト)
#
# Copyright (c) 2026- atsushifx <https://github.com/atsushifx>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

# shellcheck disable=SC1091

_LIB_DIR="$(cd "${SHELLSPEC_PROJECT_ROOT}/plugins/deckrd/skills/deckrd/scripts/libs" && pwd)"
# shellcheck disable=SC1091
. "${_LIB_DIR}/bootstrap.sh"
unset _LIB_DIR

Include ../spec_helper.sh

SCRIPT="${SCRIPTS_DIR}/init.sh"

# ============================================================================
# init.sh
# ============================================================================

Describe "init.sh"

  # --------------------------------------------------------------------------
  # Given: no arguments provided
  # --------------------------------------------------------------------------

  Describe "Given: no arguments provided"
    Before "setup_deckrd_tmpdir"
    After "teardown_deckrd_tmpdir"

    Describe "When: run without arguments"
      It "[Error] Should: exit with status 1 and output Usage and 'required' error"
        When run bash "$SCRIPT"
        The status should equal 1
        The output should include "Usage:"
        The stderr should include "required"
      End
    End
  End

  # --------------------------------------------------------------------------
  # Given: project name only (project-type omitted)
  # --------------------------------------------------------------------------

  Describe "Given: project name only (project-type omitted)"
    Before "setup_deckrd_tmpdir"
    After "teardown_deckrd_tmpdir"

    Describe "When: run with one argument 'myapp'"
      It "[Error] Should: exit with status 1 and output Usage and 'required' error"
        When run bash "$SCRIPT" myapp
        The status should equal 1
        The output should include "Usage:"
        The stderr should include "required"
      End
    End
  End

  # --------------------------------------------------------------------------
  # Given: --help option provided
  # --------------------------------------------------------------------------

  Describe "Given: --help option provided"
    Before "setup_deckrd_tmpdir"
    After "teardown_deckrd_tmpdir"

    Describe "When: run with --help"
      It "[Normal] Should: exit with status 0 and output Usage"
        When run bash "$SCRIPT" --help
        The status should equal 0
        The output should include "Usage:"
      End
    End
  End

  # --------------------------------------------------------------------------
  # Given: unknown option provided
  # --------------------------------------------------------------------------

  Describe "Given: unknown option provided"
    Before "setup_deckrd_tmpdir"
    After "teardown_deckrd_tmpdir"

    Describe "When: run with 'myapp webapp --unknown'"
      It "[Error] Should: exit with status 1 and output Usage and 'Unknown option' error"
        When run bash "$SCRIPT" myapp webapp --unknown
        The status should equal 1
        The output should include "Usage:"
        The stderr should include "Unknown option"
      End
    End
  End

  # --------------------------------------------------------------------------
  # Given: valid project name and project-type
  # --------------------------------------------------------------------------

  Describe "Given: valid project name and project-type 'myapp webapp'"
    Before "setup_deckrd_tmpdir"
    After "teardown_deckrd_tmpdir"

    Describe "When: run with 'myapp webapp' (output check)"
      It "[Normal] Should: exit with status 0 and output project name, type, Base directory, Session"
        When run bash "$SCRIPT" myapp webapp
        The status should equal 0
        The output should include "myapp"
        The output should include "webapp"
        The output should include "Base directory"
        The output should include "Session"
      End
    End

    Describe "When: run with 'myapp webapp' (directory check)"
      It "[Normal] Should: create DECKRD_DOCS, notes/, temp/ directories"
        When run bash "$SCRIPT" myapp webapp
        The status should equal 0
        The output should include "Base directory"
        The path "${DECKRD_DOCS}" should be directory
        The path "${DECKRD_DOCS}/notes" should be directory
        The path "${DECKRD_DOCS}/temp" should be directory
      End
    End

    Describe "When: run with 'myapp webapp' (DECKRD_LOCAL_DATA check)"
      It "[Normal] Should: create DECKRD_LOCAL_DATA directory"
        When run bash "$SCRIPT" myapp webapp
        The status should equal 0
        The output should include "Base directory"
        The path "${DECKRD_LOCAL_DATA}" should be directory
      End
    End

    Describe "When: run with 'myapp webapp' (.project.json check)"
      It "[Normal] Should: create .project.json containing project, project-type and language"
        When run bash "$SCRIPT" myapp webapp
        The status should equal 0
        The output should include "Project written"
        The path "${DECKRD_LOCAL_DATA}/.project.json" should be exist
        The contents of file "${DECKRD_LOCAL_DATA}/.project.json" should include "myapp"
        The contents of file "${DECKRD_LOCAL_DATA}/.project.json" should include "webapp"
        The contents of file "${DECKRD_LOCAL_DATA}/.project.json" should include "typescript"
      End
    End

    Describe "When: run with 'myapp webapp' (session.json check)"
      It "[Normal] Should: create session.json containing 'init'"
        When run bash "$SCRIPT" myapp webapp
        The status should equal 0
        The output should include "Session"
        The path "${DECKRD_LOCAL_DATA}/session.json" should be exist
        The contents of file "${DECKRD_LOCAL_DATA}/session.json" should include "init"
      End
    End
  End

  # --------------------------------------------------------------------------
  # Given: session.json already exists
  # --------------------------------------------------------------------------

  Describe "Given: session.json already exists (initial run completed)"
    After "teardown_deckrd_tmpdir"

    setup_session() {
      setup_deckrd_tmpdir
      bash "$SCRIPT" myapp webapp >/dev/null 2>&1
    }

    Before "setup_session"

    Describe "When: run again"
      It "[Normal] Should: exit with status 0 and output 'Session preserved'"
        When run bash "$SCRIPT" myapp webapp
        The status should equal 0
        The output should include "Session preserved"
      End
    End
  End

  # --------------------------------------------------------------------------
  # Given: --language option
  # --------------------------------------------------------------------------

  Describe "Given: --language option"
    Before "setup_deckrd_tmpdir"
    After "teardown_deckrd_tmpdir"

    Describe "When: run with '--language go'"
      It "[Normal] Should: exit with status 0 and output 'go'"
        When run bash "$SCRIPT" myapp webapp --language go
        The status should equal 0
        The output should include "go"
      End
    End

    Describe "When: run with '--language python'"
      It "[Normal] Should: exit with status 0 and output 'python'"
        When run bash "$SCRIPT" myapp webapp --language python
        The status should equal 0
        The output should include "python"
      End
    End

    Describe "When: run with '--lang rust' (alias)"
      It "[Normal] Should: exit with status 0 and output 'rust'"
        When run bash "$SCRIPT" myapp webapp --lang rust
        The status should equal 0
        The output should include "rust"
      End
    End

    Describe "When: run with '--language=python' (= syntax)"
      It "[Normal] Should: exit with status 0 and output 'python'"
        When run bash "$SCRIPT" myapp webapp --language=python
        The status should equal 0
        The output should include "python"
      End
    End

    Describe "When: run with '--lang=typescript' (default value)"
      It "[Edge] Should: exit with status 0 and output 'typescript'"
        When run bash "$SCRIPT" myapp webapp --lang=typescript
        The status should equal 0
        The output should include "typescript"
      End
    End

    Describe "When: run with '--language cobol' (unsupported)"
      It "[Error] Should: exit with status 1 and stderr 'Unsupported language'"
        When run bash "$SCRIPT" myapp webapp --language cobol
        The status should equal 1
        The stderr should include "Unsupported language"
      End
    End

    Describe "When: run with '--language' (no value)"
      It "[Error] Should: exit with status 1 and stderr 'requires a value'"
        When run bash "$SCRIPT" myapp webapp --language
        The status should equal 1
        The stderr should include "requires a value"
      End
    End
  End

  # --------------------------------------------------------------------------
  # Given: --ai-model option
  # --------------------------------------------------------------------------

  Describe "Given: --ai-model option"
    Before "setup_deckrd_tmpdir"
    After "teardown_deckrd_tmpdir"

    Describe "When: run with '--ai-model claude-sonnet-4-5'"
      It "[Normal] Should: exit with status 0 and output model name"
        When run bash "$SCRIPT" myapp webapp --ai-model claude-sonnet-4-5
        The status should equal 0
        The output should include "claude-sonnet-4-5"
      End
    End

    Describe "When: run with '--ai-model=claude-sonnet-4-5' (= syntax)"
      It "[Normal] Should: exit with status 0 and output model name"
        When run bash "$SCRIPT" myapp webapp --ai-model=claude-sonnet-4-5
        The status should equal 0
        The output should include "claude-sonnet-4-5"
      End
    End

    Describe "When: run with '--ai-model org/model-name' (slash format)"
      It "[Normal] Should: exit with status 0 and output model name"
        When run bash "$SCRIPT" myapp webapp --ai-model org/model-name
        The status should equal 0
        The output should include "org/model-name"
      End
    End

    Describe "When: run with '--ai-model bad model!' (invalid characters)"
      It "[Error] Should: exit with status 1 and stderr 'AI model'"
        When run bash "$SCRIPT" myapp webapp --ai-model "bad model!"
        The status should equal 1
        The stderr should include "AI model"
      End
    End

    Describe "When: run with '--ai-model' (no value)"
      It "[Error] Should: exit with status 1 and stderr 'requires a value'"
        When run bash "$SCRIPT" myapp webapp --ai-model
        The status should equal 1
        The stderr should include "requires a value"
      End
    End
  End

  # --------------------------------------------------------------------------
  # Given: invalid project name or project-type
  # --------------------------------------------------------------------------

  Describe "Given: invalid project name or project-type"
    Before "setup_deckrd_tmpdir"
    After "teardown_deckrd_tmpdir"

    Describe "When: project name has uppercase 'MyApp'"
      It "[Edge] Should: exit with status 1 and stderr 'invalid characters'"
        When run bash "$SCRIPT" MyApp webapp
        The status should equal 1
        The stderr should include "invalid characters"
      End
    End

    Describe "When: project-type has uppercase 'WebApp'"
      It "[Edge] Should: exit with status 1 and stderr 'invalid characters'"
        When run bash "$SCRIPT" myapp WebApp
        The status should equal 1
        The stderr should include "invalid characters"
      End
    End

    Describe "When: project name has space 'my app'"
      It "[Edge] Should: exit with status 1 and stderr 'invalid characters'"
        When run bash "$SCRIPT" "my app" webapp
        The status should equal 1
        The stderr should include "invalid characters"
      End
    End
  End

  # --------------------------------------------------------------------------
  # Given: .project.json already exists (re-run with different project-type)
  # --------------------------------------------------------------------------

  Describe "Given: .project.json already exists from initial run"
    After "teardown_deckrd_tmpdir"

    setup_with_initial_run() {
      setup_deckrd_tmpdir
      bash "$SCRIPT" myapp webapp >/dev/null 2>&1
      CREATED_AT_BEFORE=$(jq -r '.created_at' "${DECKRD_LOCAL_DATA}/.project.json")
      export CREATED_AT_BEFORE
    }

    Before "setup_with_initial_run"

    Describe "When: run again with different project-type"
      It "[Edge] Should: exit with status 0 and preserve created_at in .project.json"
        When run bash "$SCRIPT" myapp lib
        The status should equal 0
        The output should include "Project written"
        The contents of file "${DECKRD_LOCAL_DATA}/.project.json" should include "$CREATED_AT_BEFORE"
      End
    End
  End

End
