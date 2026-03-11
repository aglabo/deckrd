#!/usr/bin/env bash
# plugins/deckrd/skills/deckrd/tests/profile.spec.sh
# @(#) : BDD unit tests for profile.sh (プロジェクトプロフィール管理)
#
# Copyright (c) 2025 atsushifx <https://github.com/atsushifx>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

Include spec_helper.sh

SCRIPT="${SCRIPTS_DIR}/profile.sh"

# ============================================================================
# profile.sh
# ============================================================================

Describe "profile.sh"

  # --------------------------------------------------------------------------
  # Given: no arguments provided
  # --------------------------------------------------------------------------

  Describe "Given: no arguments provided"

    Before "setup_deckrd_tmpdir"
    After  "teardown_deckrd_tmpdir"

    Describe "When: run without arguments"
      It "[Error] Should: exit with status 1 and output 'required' error"
        When run bash "$SCRIPT"
        The status should equal 1
        The stderr should include "required"
      End
    End

  End

  # --------------------------------------------------------------------------
  # Given: --help option provided
  # --------------------------------------------------------------------------

  Describe "Given: --help option provided"

    Before "setup_deckrd_tmpdir"
    After  "teardown_deckrd_tmpdir"

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
    After  "teardown_deckrd_tmpdir"

    Describe "When: run with unknown option"
      It "[Error] Should: exit with status 1 and output 'Unknown option' error"
        When run bash "$SCRIPT" --project myapp --unknown
        The status should equal 1
        The output should include "Usage:"
        The stderr should include "Unknown option"
      End
    End

  End

  # --------------------------------------------------------------------------
  # Given: unexpected positional argument provided
  # --------------------------------------------------------------------------

  Describe "Given: unexpected positional argument provided"

    Before "setup_deckrd_tmpdir"
    After  "teardown_deckrd_tmpdir"

    Describe "When: run with extra positional argument"
      It "[Error] Should: exit with status 1 and output 'Unexpected argument' error"
        When run bash "$SCRIPT" --project myapp unexpected
        The status should equal 1
        The output should include "Usage:"
        The stderr should include "Unexpected argument"
      End
    End

  End

  # --------------------------------------------------------------------------
  # Given: valid --project and --language options provided
  # --------------------------------------------------------------------------

  Describe "Given: valid --project and --language options provided"

    Before "setup_deckrd_tmpdir"
    After  "teardown_deckrd_tmpdir"

    Describe "When: run with '--project myapp --language go'"
      It "[Normal] Should: exit with status 0 and output project name and language 'go'"
        When run bash "$SCRIPT" --project myapp --language go
        The status should equal 0
        The output should include "myapp"
        The output should include "go"
      End
    End

    Describe "When: run with '--project myapp --language typescript'"
      It "[Normal] Should: include project and language in result summary"
        When run bash "$SCRIPT" --project myapp --language typescript
        The output should include "myapp"
        The output should include "typescript"
      End
    End

  End

  # --------------------------------------------------------------------------
  # Given: --language option provided
  # --------------------------------------------------------------------------

  Describe "Given: --language option provided"

    Before "setup_deckrd_tmpdir"
    After  "teardown_deckrd_tmpdir"

    Describe "When: run with supported language"
      It "[Normal] Should: include 'typescript' in output for --language typescript"
        When run bash "$SCRIPT" --project myapp --language typescript
        The status should equal 0
        The output should include "typescript"
      End

      It "[Normal] Should: include 'python' in output for --language python"
        When run bash "$SCRIPT" --project myapp --language python
        The status should equal 0
        The output should include "python"
      End

      It "[Normal] Should: include 'rust' in output for --language rust"
        When run bash "$SCRIPT" --project myapp --language rust
        The status should equal 0
        The output should include "rust"
      End

      It "[Normal] Should: include 'go' in output for --lang go (alias)"
        When run bash "$SCRIPT" --project myapp --lang go
        The status should equal 0
        The output should include "go"
      End
    End

    Describe "When: run with unsupported language"
      It "[Error] Should: exit with status 1 and output 'Unsupported language' error"
        When run bash "$SCRIPT" --project myapp --language cobol
        The status should equal 1
        The stderr should include "Unsupported language"
      End
    End

  End

  # --------------------------------------------------------------------------
  # Given: --project-type option provided
  # --------------------------------------------------------------------------

  Describe "Given: --project-type option provided"

    Before "setup_deckrd_tmpdir"
    After  "teardown_deckrd_tmpdir"

    Describe "When: run with project-type"
      It "[Normal] Should: include project_type value 'webapp' in output"
        When run bash "$SCRIPT" --project myapp --project-type webapp
        The output should include "webapp"
      End
    End

  End

  # --------------------------------------------------------------------------
  # Given: --ai-model option provided
  # --------------------------------------------------------------------------

  Describe "Given: --ai-model option provided"

    Before "setup_deckrd_tmpdir"
    After  "teardown_deckrd_tmpdir"

    Describe "When: run with valid model name"
      It "[Normal] Should: include specified model name in output"
        When run bash "$SCRIPT" --project myapp --ai-model claude-sonnet-4-5
        The output should include "claude-sonnet-4-5"
      End
    End

  End

  # --------------------------------------------------------------------------
  # Given: existing profile.json exists
  # --------------------------------------------------------------------------

  Describe "Given: existing profile.json exists"

    Before "setup_deckrd_tmpdir"
    After  "teardown_deckrd_tmpdir"

    Before "setup_existing_profile"
    setup_existing_profile() {
      mkdir -p "$DECKRD_LOCAL"
      cat > "${DECKRD_LOCAL}/profile.json" <<'JSON'
{
  "project": "oldapp",
  "language": "go",
  "created_at": "2025-01-01T00:00:00Z",
  "updated_at": "2025-01-01T00:00:00Z"
}
JSON
    }

    Describe "When: run with new project name and language"
      It "[Normal] Should: exit with status 0 and output new project name"
        When run bash "$SCRIPT" --project newapp --language typescript
        The status should equal 0
        The output should include "newapp"
      End
    End

  End

End
