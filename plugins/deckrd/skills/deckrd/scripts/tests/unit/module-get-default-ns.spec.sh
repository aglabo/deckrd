#!/usr/bin/env bash
# plugins/deckrd/skills/deckrd/scripts/tests/unit/module-get-default-ns.spec.sh
# @(#) : BDD unit tests for module.sh - _get_default_ns function
#
# Copyright (c) 2026- atsushifx <https://github.com/atsushifx>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

# shellcheck disable=SC1090
# cspell:words myrepo

_RUNTIME_BOOTSTRAP="${SHELLSPEC_PROJECT_ROOT}/plugins/_runtime/libs/bootstrap.lib.sh"
. "$_RUNTIME_BOOTSTRAP" "--no-finalize"
unset _RUNTIME_BOOTSTRAP

Include ../spec_helper.sh

SCRIPT="${DECKRD_SCRIPTS_DIR}/module.sh"

# ============================================================================
# module.sh: _get_default_ns
# ============================================================================

Describe "module.sh: _get_default_ns"

  load_script_with_mocks() {
    # Mock: validate_env を常に成功させる
    # shellcheck disable=SC2329
    validate_env() { return 0; }
    export -f validate_env

    # module.sh を source して関数をロード
    # shellcheck disable=SC1090
    . "$SCRIPT"
  }
  Before "load_script_with_mocks"

  # --------------------------------------------------------------------------
  # Given: .project.json exists with valid project name
  # --------------------------------------------------------------------------

  Describe "Given: .project.json exists with valid project name"
    Before "setup_deckrd_tmpdir"
    After "teardown_deckrd_tmpdir"

    setup_project_json() {
      mkdir -p "$DECKRD_LOCAL_DATA"
      printf '{"project":"myproject","project_type":"feature","language":"shell","ai_model":"sonnet","created_at":"2026-01-01T00:00:00Z","updated_at":"2026-01-01T00:00:00Z"}\n' \
        >"${DECKRD_LOCAL_DATA}/.project.json"
    }
    Before "setup_project_json"

    Describe "When: call _get_default_ns"
      It "[Normal] Should: return 0 and output the project name"
        When call _get_default_ns
        The status should equal 0
        The output should equal "myproject"
      End
    End
  End

  # --------------------------------------------------------------------------
  # Given: .project.json does not exist, inside a git repository
  # --------------------------------------------------------------------------

  Describe "Given: no .project.json, inside a git repository"
    Before "setup_deckrd_tmpdir"
    After "teardown_deckrd_tmpdir"

    setup_git_repo() {
      # Mock: git rev-parse --show-toplevel でローカルリポジトリルートを返す
      # shellcheck disable=SC2329
      git() {
        if [[ "$1" == "rev-parse" && "$2" == "--show-toplevel" ]]; then
          echo "/home/user/projects/myrepo"
          return 0
        fi
        command git "$@"
      }
      export -f git
    }
    Before "setup_git_repo"

    Describe "When: call _get_default_ns"
      It "[Normal] Should: return 0 and output the repository directory name"
        When call _get_default_ns
        The status should equal 0
        The output should equal "myrepo"
      End
    End
  End

  # --------------------------------------------------------------------------
  # Given: .project.json does not exist, not in a git repository
  # --------------------------------------------------------------------------

  Describe "Given: no .project.json, not in a git repository"
    Before "setup_deckrd_tmpdir"
    After "teardown_deckrd_tmpdir"

    setup_no_git_repo() {
      # Mock: git rev-parse --show-toplevel が失敗する
      # shellcheck disable=SC2329
      git() {
        if [[ "$1" == "rev-parse" && "$2" == "--show-toplevel" ]]; then
          return 1
        fi
        command git "$@"
      }
      export -f git
    }
    Before "setup_no_git_repo"

    Describe "When: call _get_default_ns"
      It "[Error] Should: return 1 and output error message to stderr"
        When call _get_default_ns
        The status should equal 1
        The stderr should include "Error"
      End
    End
  End

End
