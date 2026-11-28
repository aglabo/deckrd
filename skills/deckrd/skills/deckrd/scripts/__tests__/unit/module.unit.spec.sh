#!/usr/bin/env bash
# skills/deckrd/skills/deckrd/scripts/__tests__/unit/module.unit.spec.sh
# @(#) : BDD unit tests for module.sh (モジュールディレクトリ管理)
#
# Copyright (c) 2025 atsushifx <https://github.com/atsushifx>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

# shellcheck disable=SC1090

_RUNTIME_BOOTSTRAP="${SHELLSPEC_PROJECT_ROOT}/skills/deckrd/skills/deckrd/scripts/libs/bootstrap.lib.sh"
. "$_RUNTIME_BOOTSTRAP" "--no-finalize"
unset _RUNTIME_BOOTSTRAP

Include "${SHELLSPEC_SPECFILE%/*}/../spec_helper.sh"

SCRIPT="${DECKRD_SCRIPTS_DIR}/module.sh"

# Helper: setup tmpdir and create .project.json with project name "my-project"
setup_deckrd_tmpdir_with_project() {
  setup_deckrd_tmpdir
  mkdir -p "$DECKRD_LOCAL_DATA"
  printf '{"project":"my-project","project_type":"feature","language":"shell","ai_model":"sonnet","created_at":"2026-01-01T00:00:00Z","updated_at":"2026-01-01T00:00:00Z"}\n' \
    >"${DECKRD_LOCAL_DATA}/.project.json"
}

# Helpers: make the frontmatter reader fail to run (fm_read_scalar honors $AWK).
# Works on every platform, unlike removing read permission
# shellcheck disable=SC2329
break_frontmatter_reader() { export AWK="${DECKRD_TMPDIR}/no-such-awk"; }
# shellcheck disable=SC2329
restore_frontmatter_reader() { unset AWK; }

# Helper: succeed when chmod cannot block reading (root, or Windows file systems)
# shellcheck disable=SC2329
chmod_cannot_block_read() {
  local probe status=1
  probe="$(mktemp)"
  chmod 000 "$probe"
  if { : <"$probe"; } 2>/dev/null; then status=0; fi
  rm -f "$probe"
  return "$status"
}

# ============================================================================
# module.sh
# ============================================================================

Describe "module.sh"

  Describe "T-CLI-MOD: module.sh の引数処理とディレクトリ生成"

    # --------------------------------------------------------------------------
    # Given: no arguments provided
    # --------------------------------------------------------------------------

    Describe "Given: no arguments provided"
      Before "setup_deckrd_tmpdir"
      After "teardown_deckrd_tmpdir"

      Describe "When: run without arguments"
        It "[Error] T-CLI-MOD-01: Should: exit with status 1 and output Usage and 'required' error"
          When run bash "$SCRIPT"
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
        It "[Normal] T-CLI-MOD-02: Should: exit with status 0 and output Usage"
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

      Describe "When: run with unknown option"
        It "[Error] T-CLI-MOD-03: Should: exit with status 1 and output 'Unknown option' error"
          When run bash "$SCRIPT" --unknown
          The status should equal 1
          The output should include "Usage:"
          The stderr should include "Unknown option"
        End
      End
    End

    # --------------------------------------------------------------------------
    # Given: more than one module path provided
    # --------------------------------------------------------------------------

    Describe "Given: more than one module path provided"
      Before "setup_deckrd_tmpdir"
      After "teardown_deckrd_tmpdir"

      Describe "When: run with 'a/b c/d'"
        It "[Error] T-CLI-MOD-14: Should: exit with status 1 and output 'Unexpected argument: c/d' error and Usage"
          When run bash "$SCRIPT" a/b c/d
          The status should equal 1
          The output should include "Usage:"
          The stderr should include "Unexpected argument: c/d"
        End
      End
    End

    # --------------------------------------------------------------------------
    # Given: a value attached to a flag option
    # --------------------------------------------------------------------------

    Describe "Given: a value attached to a flag option"
      Before "setup_deckrd_tmpdir"
      After "teardown_deckrd_tmpdir"

      Describe "When: run with 'my-ns/my-mod --force=x'"
        It "[Error] T-CLI-MOD-16: Should: exit with status 1 and output '--force does not take a value' error and Usage"
          When run bash "$SCRIPT" my-ns/my-mod --force=x
          The status should equal 1
          The output should include "Usage:"
          The stderr should include "--force does not take a value"
        End
      End
    End

    # --------------------------------------------------------------------------
    # Given: valid legacy format argument (<namespace>/<module>)
    # --------------------------------------------------------------------------

    Describe "Given: valid legacy format argument (<namespace>/<module>)"
      Before "setup_deckrd_tmpdir"
      After "teardown_deckrd_tmpdir"

      Describe "When: run with 'my-ns/my-mod'"
        It "[Normal] T-CLI-MOD-04: Should: exit with status 0, create all module directories, skip .project.json, and output 'Session updated'"
          When run bash "$SCRIPT" my-ns/my-mod
          The status should equal 0
          The output should include "my-ns/my-mod"
          The output should include "requirements"
          The output should include "specifications"
          The output should include "implementation"
          The output should include "tasks"
          The output should include "workspaces"
          The output should include "Session updated"
          The path "${DECKRD_DOCS_DIR}/my-ns/my-mod/requirements" should be directory
          The path "${DECKRD_DOCS_DIR}/my-ns/my-mod/specifications" should be directory
          The path "${DECKRD_DOCS_DIR}/my-ns/my-mod/implementation" should be directory
          The path "${DECKRD_DOCS_DIR}/my-ns/my-mod/tasks" should be directory
          The path "${DECKRD_DOCS_DIR}/my-ns/my-mod/workspaces" should be directory
          The path "${DECKRD_DOCS_DIR}/my-ns/my-mod/.project.json" should not be exist
        End
      End

      Describe "When: run with uppercase 'MyNS/MyMod'"
        It "[Edge] T-CLI-MOD-05: Should: exit with status 1 and output 'invalid characters' error"
          When run bash "$SCRIPT" MyNS/MyMod
          The status should eq 1
          The stderr should include "invalid characters"
        End
      End
    End

  # --------------------------------------------------------------------------
  # Given: invalid legacy format argument
  # --------------------------------------------------------------------------

    Describe "Given: invalid legacy format argument"
      Before "setup_deckrd_tmpdir"
      After "teardown_deckrd_tmpdir"

      Describe "When: run with '/my-mod' (empty namespace)"
        It "[Error] T-CLI-MOD-06: Should: exit with status 1 and output 'empty' error"
          When run bash "$SCRIPT" "/my-mod"
          The status should equal 1
          The stderr should include "empty"
        End
      End

      Describe "When: run with 'my-ns/' (empty module)"
        It "[Error] T-CLI-MOD-07: Should: exit with status 1 and output 'empty' error"
          When run bash "$SCRIPT" "my-ns/"
          The status should equal 1
          The stderr should include "empty"
        End
      End

      Describe "When: run with 'my ns/my-mod' (space in namespace)"
        It "[Error] T-CLI-MOD-08: Should: exit with status 1 and output 'invalid characters' error"
          When run bash "$SCRIPT" "my ns/my-mod"
          The status should equal 1
          The stderr should include "invalid characters"
        End
      End

      Describe "When: run with 'my-ns/my-mod' on existing directory with --force"
        It "[Edge] T-CLI-MOD-10: Should: exit with status 0 and output 'my-ns/my-mod'"
          mkdir -p "${DECKRD_DOCS_DIR}/my-ns/my-mod"
          When run bash "$SCRIPT" my-ns/my-mod --force
          The status should equal 0
          The output should include "my-ns/my-mod"
        End
      End
    End

    # --------------------------------------------------------------------------
    # Given: create subcommand with <namespace>/<module> format
    # --------------------------------------------------------------------------

    Describe "Given: create subcommand with <namespace>/<module> format"
      Before "setup_deckrd_tmpdir"
      After "teardown_deckrd_tmpdir"

      Describe "When: run 'create my-ns/my-mod'"
        It "[Normal] T-CLI-MOD-11: Should: exit with status 0, create module dirs, and output 'Session updated'"
          When run bash "$SCRIPT" create my-ns/my-mod
          The status should equal 0
          The output should include "my-ns/my-mod"
          The output should include "Session updated"
          The path "${DECKRD_DOCS_DIR}/my-ns/my-mod/requirements" should be directory
          The path "${DECKRD_DOCS_DIR}/my-ns/my-mod/specifications" should be directory
          The path "${DECKRD_DOCS_DIR}/my-ns/my-mod/.project.json" should not be exist
        End
      End

      Describe "When: run create with invalid namespace 'my ns/my-mod'"
        It "[Error] T-CLI-MOD-12: Should: exit with status 1 and output 'invalid characters' error"
          When run bash "$SCRIPT" create "my ns/my-mod"
          The status should equal 1
          The stderr should include "invalid characters"
        End
      End
    End

    # --------------------------------------------------------------------------
    # Given: create subcommand with <module> format (namespace from .project.json or the git root directory name)
    # --------------------------------------------------------------------------

    Describe "Given: create subcommand with <module> format"
      Before "setup_deckrd_tmpdir"
      After "teardown_deckrd_tmpdir"

      Describe "When: run 'create my-feature'"
        It "[Normal] T-CLI-MOD-13: Should: exit with status 0 and output 'my-feature'"
          When run bash "$SCRIPT" create my-feature
          The status should equal 0
          The output should include "my-feature"
        End
      End
    End

    # --------------------------------------------------------------------------
    # Given: module.sh is sourced instead of executed
    # --------------------------------------------------------------------------

    Describe "Given: module.sh is sourced instead of executed"
      # Mock: validate_env が source 時に実行されたら検出できるよう、大きく失敗させる
      # shellcheck disable=SC2329
      mock_validate_env_must_not_run() {
        validate_env() { echo "validate_env must not run on source" >&2; return 1; }
        export -f validate_env
      }
      # shellcheck disable=SC2329
      unmock_validate_env_must_not_run() {
        unset -f validate_env
      }
      Before "setup_deckrd_tmpdir" "mock_validate_env_must_not_run"
      After "unmock_validate_env_must_not_run" "teardown_deckrd_tmpdir"

      Describe "When: source module.sh"
        It "[Normal] T-CLI-MOD-15: Should: return status 0 without running main or printing anything"
          When run source "$SCRIPT"
          The status should equal 0
          The output should equal ""
          The stderr should equal ""
        End
      End
    End
  End

  # --------------------------------------------------------------------------
  # derive_test_scope
  # --------------------------------------------------------------------------

  Describe "T-CLI-DTS: derive_test_scope"

    load_module_functions() {
      # shellcheck disable=SC2329
      validate_env() { return 0; }
      export -f validate_env

      # shellcheck disable=SC1090
      . "$SCRIPT"
    }
    Before "load_module_functions"
    Before "init_vars"

    Describe "Given: module name containing a word separator"
      Parameters
        "is-collection" "IC"
        "chat-log-normalize" "CLN"
        "a-b-c-d-e-f" "ABCD"
        "foo_bar" "FB"
      End

      Describe "When: call derive_test_scope"
        It "[Normal] T-CLI-DTS-01: Should: exit with status 0 and output the uppercased word initials truncated to 4 characters"
          When call derive_test_scope "$1"
          The status should equal 0
          The output should equal "$2"
        End
      End
    End

    Describe "Given: module name without a word separator"
      Parameters
        "libs" "LIB"
        "runners" "RUN"
        "subcommands" "SUB"
        "cli" "CLI"
        "normalize" "NOR"
      End

      Describe "When: call derive_test_scope"
        It "[Normal] T-CLI-DTS-02: Should: exit with status 0 and output the first 3 characters uppercased"
          When call derive_test_scope "$1"
          The status should equal 0
          The output should equal "$2"
        End
      End
    End

    Describe "Given: module name whose derived scope is shorter than 2 characters"
      Describe "When: call derive_test_scope with 'a'"
        It "[Error] T-CLI-DTS-03: Should: exit with status 1 and output an error to stderr"
          When call derive_test_scope "a"
          The status should equal 1
          The stderr should include "Error"
          The stderr should include "'a'"
          The output should equal ""
        End
      End
    End

    Describe "Given: single word module name with only 2 characters"
      Describe "When: call derive_test_scope with 'ab'"
        It "[Edge] T-CLI-DTS-04: Should: exit with status 0 and output the 2 available characters uppercased"
          When call derive_test_scope "ab"
          The status should equal 0
          The output should equal "AB"
        End
      End
    End
  End

  # --------------------------------------------------------------------------
  # validate_and_normalize
  # --------------------------------------------------------------------------

  Describe "T-CLI-VAN: validate_and_normalize"

    load_module_functions_for_van() {
      # shellcheck disable=SC2329
      validate_env() { return 0; }
      export -f validate_env

      # shellcheck disable=SC1090
      . "$SCRIPT"
    }
    Before "load_module_functions_for_van"
    Before "init_vars"

    Describe "Given: a well-formed <namespace>/<module> path"
      Describe "When: call validate_and_normalize with 'my-ns/my-mod'"
        It "[Normal] T-CLI-VAN-01: Should: return status 0 and output the path unchanged"
          When call validate_and_normalize "my-ns/my-mod"
          The status should equal 0
          The output should equal "my-ns/my-mod"
        End
      End

      Describe "When: call validate_and_normalize with the shortest path 'a/b'"
        It "[Edge] T-CLI-VAN-07: Should: return status 0 and output 'a/b'"
          When call validate_and_normalize "a/b"
          The status should equal 0
          The output should equal "a/b"
        End
      End
    End

    Describe "Given: a path without a slash"
      Describe "When: call validate_and_normalize with 'no-path'"
        It "[Error] T-CLI-VAN-02: Should: return status 1 and output a format error to stderr"
          When call validate_and_normalize "no-path"
          The status should equal 1
          The stderr should include "Path must be in format <namespace>/<module>"
          The output should equal ""
        End
      End

      Describe "When: call validate_and_normalize inside a caller that handles the failure"
        caller_continues() {
          validate_and_normalize "no-path" || echo "continued"
        }

        It "[Error] T-CLI-VAN-08: Should: return to the caller instead of exiting the shell"
          When call caller_continues
          The status should equal 0
          The output should include "continued"
          The stderr should include "Path must be in format"
        End
      End
    End

    Describe "Given: a path with an empty part"
      Describe "When: call validate_and_normalize with '/my-mod' (empty namespace)"
        It "[Error] T-CLI-VAN-03: Should: return status 1 and output an empty-part error to stderr"
          When call validate_and_normalize "/my-mod"
          The status should equal 1
          The stderr should include "namespace and module must not be empty"
          The output should equal ""
        End
      End

      Describe "When: call validate_and_normalize with 'my-ns/' (empty module)"
        It "[Edge] T-CLI-VAN-06: Should: return status 1 and output an empty-part error to stderr"
          When call validate_and_normalize "my-ns/"
          The status should equal 1
          The stderr should include "namespace and module must not be empty"
          The output should equal ""
        End
      End
    End

    Describe "Given: a path containing uppercase characters"
      Describe "When: call validate_and_normalize with 'MyNS/my-mod'"
        It "[Error] T-CLI-VAN-04: Should: return status 1 and report the invalid namespace"
          When call validate_and_normalize "MyNS/my-mod"
          The status should equal 1
          The stderr should include "namespace 'MyNS' contains invalid characters"
          The output should equal ""
        End
      End

      Describe "When: call validate_and_normalize with 'my-ns/MyMod'"
        It "[Error] T-CLI-VAN-05: Should: return status 1 and report the invalid module"
          When call validate_and_normalize "my-ns/MyMod"
          The status should equal 1
          The stderr should include "module 'MyMod' contains invalid characters"
          The output should equal ""
        End
      End
    End
  End

  # --------------------------------------------------------------------------
  # validate_and_normalize_with_fallback
  # --------------------------------------------------------------------------

  Describe "T-CLI-VNF: validate_and_normalize_with_fallback"

    load_module_functions_for_vnf() {
      # shellcheck disable=SC2329
      validate_env() { return 0; }
      export -f validate_env

      # shellcheck disable=SC1090
      . "$SCRIPT"
    }
    Before "load_module_functions_for_vnf"
    Before "init_vars"

    Describe "Given: a <namespace>/<module> path"
      Describe "When: call validate_and_normalize_with_fallback with 'my-ns/my-mod'"
        It "[Normal] T-CLI-VNF-01: Should: return status 0 and output the path unchanged"
          When call validate_and_normalize_with_fallback "my-ns/my-mod"
          The status should equal 0
          The output should equal "my-ns/my-mod"
        End
      End

      Describe "When: call validate_and_normalize_with_fallback with 'MyNS/my-mod'"
        It "[Error] T-CLI-VNF-04: Should: return status 1 and report the invalid namespace"
          When call validate_and_normalize_with_fallback "MyNS/my-mod"
          The status should equal 1
          The stderr should include "namespace 'MyNS' contains invalid characters"
          The output should equal ""
        End
      End
    End

    Describe "Given: a <module>-only path and a resolvable default namespace"
      # Mock: source 後に _get_default_ns を上書きし、既定 namespace 'proj' を返す
      mock_default_ns_resolves() {
        # shellcheck disable=SC2329
        _get_default_ns() { echo "proj"; }
      }
      Before "mock_default_ns_resolves"

      Describe "When: call validate_and_normalize_with_fallback with 'my-feature'"
        It "[Normal] T-CLI-VNF-02: Should: return status 0 and output the path prefixed with the default namespace"
          When call validate_and_normalize_with_fallback "my-feature"
          The status should equal 0
          The output should equal "proj/my-feature"
        End
      End

      Describe "When: call validate_and_normalize_with_fallback with 'MyFeature'"
        It "[Edge] T-CLI-VNF-05: Should: return status 1 and report the invalid module after the namespace is filled in"
          When call validate_and_normalize_with_fallback "MyFeature"
          The status should equal 1
          The stderr should include "module 'MyFeature' contains invalid characters"
          The output should equal ""
        End
      End
    End

    Describe "Given: a <module>-only path and an unresolvable default namespace"
      # Mock: source 後に _get_default_ns を上書きし、解決失敗を返す
      mock_default_ns_fails() {
        # shellcheck disable=SC2329
        _get_default_ns() {
          echo "Error: Cannot determine default namespace" >&2
          return 1
        }
      }
      Before "mock_default_ns_fails"

      Describe "When: call validate_and_normalize_with_fallback with 'my-feature'"
        It "[Error] T-CLI-VNF-03: Should: return status 1 and output nothing"
          When call validate_and_normalize_with_fallback "my-feature"
          The status should equal 1
          The output should equal ""
          The stderr should include "Cannot determine default namespace"
        End
      End

      Describe "When: call validate_and_normalize_with_fallback inside a caller that handles the failure"
        caller_continues_vnf() {
          validate_and_normalize_with_fallback "my-feature" || echo "continued"
        }

        It "[Error] T-CLI-VNF-06: Should: return to the caller instead of exiting the shell"
          When call caller_continues_vnf
          The status should equal 0
          The output should include "continued"
          The stderr should include "Cannot determine default namespace"
        End
      End
    End
  End

  # --------------------------------------------------------------------------
  # create_module_dirs
  # --------------------------------------------------------------------------

  Describe "T-CLI-CMD: create_module_dirs"

    load_module_functions_for_cmd() {
      # shellcheck disable=SC2329
      validate_env() { return 0; }
      export -f validate_env

      # shellcheck disable=SC1090
      . "$SCRIPT"
    }
    Before "setup_deckrd_tmpdir" "load_module_functions_for_cmd"
    Before "init_vars"
    After "teardown_deckrd_tmpdir"

    Describe "Given: the module directory does not exist"
      Describe "When: call create_module_dirs with 'my-ns/my-mod' and force=false"
        It "[Normal] T-CLI-CMD-01: Should: return status 0 and create every module subdirectory"
          When call create_module_dirs "my-ns/my-mod" false
          The status should equal 0
          The output should include "Initializing module: my-ns/my-mod"
          The path "${DECKRD_DOCS_DIR}/my-ns/my-mod/requirements" should be directory
          The path "${DECKRD_DOCS_DIR}/my-ns/my-mod/specifications" should be directory
          The path "${DECKRD_DOCS_DIR}/my-ns/my-mod/implementation" should be directory
          The path "${DECKRD_DOCS_DIR}/my-ns/my-mod/tasks" should be directory
          The path "${DECKRD_DOCS_DIR}/my-ns/my-mod/workspaces" should be directory
        End
      End

      Describe "When: call create_module_dirs with 'my-ns/my-mod' and force=true"
        It "[Edge] T-CLI-CMD-05: Should: return status 0 and create the module as if force were false"
          When call create_module_dirs "my-ns/my-mod" true
          The status should equal 0
          The output should include "Initializing module: my-ns/my-mod"
          The path "${DECKRD_DOCS_DIR}/my-ns/my-mod/workspaces" should be directory
        End
      End
    End

    Describe "Given: the module directory already exists"
      # shellcheck disable=SC2329
      setup_existing_module_dir() {
        mkdir -p "${DECKRD_DOCS_DIR}/my-ns/my-mod"
      }
      Before "setup_existing_module_dir"

      Describe "When: call create_module_dirs with 'my-ns/my-mod' and force=true"
        It "[Normal] T-CLI-CMD-02: Should: return status 0 and re-initialize the module"
          When call create_module_dirs "my-ns/my-mod" true
          The status should equal 0
          The output should include "Initializing module: my-ns/my-mod"
        End
      End

      Describe "When: call create_module_dirs with 'my-ns/my-mod' and force=false"
        It "[Error] T-CLI-CMD-03: Should: return status 1 and report the existing directory"
          When call create_module_dirs "my-ns/my-mod" false
          The status should equal 1
          The output should equal ""
          The stderr should include "Error: Module directory already exists: ${DECKRD_DOCS_DIR}/my-ns/my-mod"
          The stderr should include "Use --force to re-initialize."
        End
      End

      Describe "When: call create_module_dirs with 'my-ns/my-mod' and force omitted"
        It "[Edge] T-CLI-CMD-04: Should: return status 1 because an omitted force means false"
          When call create_module_dirs "my-ns/my-mod"
          The status should equal 1
          The stderr should include "Error: Module directory already exists: ${DECKRD_DOCS_DIR}/my-ns/my-mod"
        End
      End

      Describe "When: call create_module_dirs inside a caller that handles the failure"
        caller_continues_cmd() {
          create_module_dirs "my-ns/my-mod" false || echo "continued"
        }

        It "[Error] T-CLI-CMD-06: Should: return to the caller instead of exiting the shell"
          When call caller_continues_cmd
          The status should equal 0
          The output should include "continued"
          The stderr should include "Module directory already exists"
        End
      End
    End

    Describe "Given: the module directory exists and a regular file occupies a subdirectory path"
      # shellcheck disable=SC2329
      setup_blocked_subdir() {
        mkdir -p "${DECKRD_DOCS_DIR}/my-ns/my-mod"
        : >"${DECKRD_DOCS_DIR}/my-ns/my-mod/requirements"
      }
      Before "setup_blocked_subdir"

      Describe "When: call create_module_dirs with force=true inside a caller that handles the failure"
        # main と同じ `|| ` 文脈 (set -e 無効) で呼び出す
        caller_handles_mkdir_failure() {
          create_module_dirs "my-ns/my-mod" true || echo "failed"
        }

        It "[Error] T-CLI-CMD-08: Should: return failure without reporting the subdirectory as created"
          When call caller_handles_mkdir_failure
          The status should equal 0
          The output should include "failed"
          The output should not include "created: requirements/"
          The stderr should include "Error: failed to create directory: ${DECKRD_DOCS_DIR}/my-ns/my-mod/requirements"
        End
      End
    End

    Describe "Given: the module directory already exists and the global force option is true"
      # shellcheck disable=SC2329,SC2034 # OPTIONS is the module.sh global that create_module_dirs must ignore
      setup_existing_module_dir_with_global_force() {
        mkdir -p "${DECKRD_DOCS_DIR}/my-ns/my-mod"
        OPTIONS["force"]=true
      }
      Before "setup_existing_module_dir_with_global_force"

      Describe "When: call create_module_dirs with 'my-ns/my-mod' and force=false"
        It "[Error] T-CLI-CMD-07: Should: return status 1 because only the force argument is honored"
          When call create_module_dirs "my-ns/my-mod" false
          The status should equal 1
          The stderr should include "Module directory already exists"
        End
      End
    End
  End

  # --------------------------------------------------------------------------
  # collect_declared_scopes
  # --------------------------------------------------------------------------

  Describe "T-CLI-CDS: collect_declared_scopes"

    load_module_functions_for_scopes() {
      # shellcheck disable=SC2329
      validate_env() { return 0; }
      export -f validate_env

      # shellcheck disable=SC1090
      . "$SCRIPT"
    }

    # Helper: 一時 docs ディレクトリに <namespace>/<module>/module.md を作る
    # shellcheck disable=SC2329
    write_module_md() {
      local module_path="$1"
      shift
      mkdir -p "${DECKRD_DOCS_DIR}/${module_path}/workspaces/module"
      printf '%s\n' "$@" >"${DECKRD_DOCS_DIR}/${module_path}/workspaces/module/module.md"
    }

    Before "setup_deckrd_tmpdir" "load_module_functions_for_scopes"
    Before "init_vars"
    After "teardown_deckrd_tmpdir"

    Describe "Given: multiple module.md files declaring test_scope"
      # shellcheck disable=SC2329
      setup_declared_modules() {
        write_module_md "alpha/normalize" "---" "title: normalize" "test_scope: NOR" "---" "" "# normalize"
        write_module_md "bravo/parser" "---" "title: parser" "test_scope: PAR" "---"
      }
      Before "setup_declared_modules"

      Describe "When: call collect_declared_scopes"
        It "[Normal] T-CLI-CDS-01: Should: exit with status 0 and output '<test_scope><TAB><relative module.md path>' per module"
          When call collect_declared_scopes
          The status should equal 0
          The output should equal "$(printf 'NOR\talpha/normalize/workspaces/module/module.md\nPAR\tbravo/parser/workspaces/module/module.md')"
        End
      End
    End

    Describe "Given: a module.md whose test_scope value is padded with whitespace"
      # shellcheck disable=SC2329
      setup_padded_module() {
        write_module_md "charlie/padded" "---" "test_scope:   PAD   " "---"
      }
      Before "setup_padded_module"

      Describe "When: call collect_declared_scopes"
        It "[Normal] T-CLI-CDS-02: Should: exit with status 0 and output the scope with surrounding whitespace stripped"
          When call collect_declared_scopes
          The status should equal 0
          The output should equal "$(printf 'PAD\tcharlie/padded/workspaces/module/module.md')"
        End
      End
    End

    Describe "Given: a module.md without a test_scope key alongside one that has it"
      # shellcheck disable=SC2329
      setup_mixed_modules() {
        write_module_md "delta/plain" "---" "title: plain" "---" "" "# plain"
        write_module_md "echo/scoped" "---" "test_scope: ECH" "---"
      }
      Before "setup_mixed_modules"

      Describe "When: call collect_declared_scopes"
        It "[Normal] T-CLI-CDS-03: Should: exit with status 0 and output only the module that declares test_scope"
          When call collect_declared_scopes
          The status should equal 0
          The output should equal "$(printf 'ECH\techo/scoped/workspaces/module/module.md')"
        End
      End
    End

    Describe "Given: no module.md exists under the docs directory"
      Describe "When: call collect_declared_scopes"
        It "[Edge] T-CLI-CDS-04: Should: exit with status 0 and output nothing"
          When call collect_declared_scopes
          The status should equal 0
          The output should equal ""
          The stderr should equal ""
        End
      End
    End

    Describe "Given: module.md files with test_scope written outside the frontmatter"
      # shellcheck disable=SC2329
      setup_body_text_modules() {
        write_module_md "foxtrot/bodyonly" "---" "title: bodyonly" "---" "" "test_scope: BAD"
        write_module_md "golf/both" "---" "test_scope: GOL" "---" "" "test_scope: BAD"
        write_module_md "hotel/no-frontmatter" "test_scope: BAD" "" "# no frontmatter"
      }
      Before "setup_body_text_modules"

      Describe "When: call collect_declared_scopes"
        It "[Edge] T-CLI-CDS-05: Should: exit with status 0 and read test_scope only from the frontmatter"
          When call collect_declared_scopes
          The status should equal 0
          The output should equal "$(printf 'GOL\tgolf/both/workspaces/module/module.md')"
        End
      End
    End

    Describe "Given: a module.md whose test_scope value is wrapped in double quotes"
      # shellcheck disable=SC2329
      setup_double_quoted_module() {
        write_module_md "india/quoted" "---" 'test_scope: "QDQ"' "---"
      }
      Before "setup_double_quoted_module"

      Describe "When: call collect_declared_scopes"
        It "[Normal] T-CLI-CDS-06: Should: exit with status 0 and output the scope with the surrounding double quotes stripped"
          When call collect_declared_scopes
          The status should equal 0
          The output should equal "$(printf 'QDQ\tindia/quoted/workspaces/module/module.md')"
        End
      End
    End

    Describe "Given: a module.md whose test_scope value is wrapped in single quotes"
      # shellcheck disable=SC2329
      setup_single_quoted_module() {
        write_module_md "juliett/quoted" "---" "test_scope: 'QSQ'" "---"
      }
      Before "setup_single_quoted_module"

      Describe "When: call collect_declared_scopes"
        It "[Normal] T-CLI-CDS-07: Should: exit with status 0 and output the scope with the surrounding single quotes stripped"
          When call collect_declared_scopes
          The status should equal 0
          The output should equal "$(printf 'QSQ\t%s' 'juliett/quoted/workspaces/module/module.md')"
        End
      End
    End

    Describe "Given: a module.md whose test_scope value is quoted and padded with whitespace"
      # shellcheck disable=SC2329
      setup_quoted_padded_module() {
        write_module_md "kilo/padded" "---" 'test_scope:   "QPD"   ' "---"
      }
      Before "setup_quoted_padded_module"

      Describe "When: call collect_declared_scopes"
        It "[Edge] T-CLI-CDS-08: Should: exit with status 0 and output the scope with both the whitespace and the quotes stripped"
          When call collect_declared_scopes
          The status should equal 0
          The output should equal "$(printf 'QPD\tkilo/padded/workspaces/module/module.md')"
        End
      End
    End

    Describe "Given: a module.md whose test_scope value has a trailing double quote only"
      # shellcheck disable=SC2329
      setup_trailing_quote_module() {
        write_module_md "lima/unbalanced" "---" 'test_scope: QTR"' "---"
      }
      Before "setup_trailing_quote_module"

      Describe "When: call collect_declared_scopes"
        It "[Error] T-CLI-CDS-09: Should: exit with status 0 and keep the unmatched trailing quote"
          When call collect_declared_scopes
          The status should equal 0
          The output should equal "$(printf 'QTR"\tlima/unbalanced/workspaces/module/module.md')"
        End
      End
    End

    Describe "Given: a module.md whose test_scope value has a leading double quote only"
      # shellcheck disable=SC2329
      setup_leading_quote_module() {
        write_module_md "mike/unbalanced" "---" 'test_scope: "QLD' "---"
      }
      Before "setup_leading_quote_module"

      Describe "When: call collect_declared_scopes"
        It "[Error] T-CLI-CDS-10: Should: exit with status 0 and keep the unmatched leading quote"
          When call collect_declared_scopes
          The status should equal 0
          The output should equal "$(printf '"QLD\tmike/unbalanced/workspaces/module/module.md')"
        End
      End
    End

    Describe "Given: a module.md whose test_scope value mixes a single and a double quote"
      # shellcheck disable=SC2329
      setup_mixed_quote_module() {
        write_module_md "november/unbalanced" "---" 'test_scope: '"'"'QMX"' "---"
      }
      Before "setup_mixed_quote_module"

      Describe "When: call collect_declared_scopes"
        It "[Error] T-CLI-CDS-11: Should: exit with status 0 and keep both mismatched quotes"
          When call collect_declared_scopes
          The status should equal 0
          The output should equal "$(printf "'QMX\"\tnovember/unbalanced/workspaces/module/module.md")"
        End
      End
    End

    Describe "Given: a module.md whose test_scope value is an empty pair of double quotes"
      # shellcheck disable=SC2329
      setup_empty_quotes_module() {
        write_module_md "oscar/emptyquotes" "---" 'test_scope: ""' "---"
      }
      Before "setup_empty_quotes_module"

      Describe "When: call collect_declared_scopes"
        It "[Edge] T-CLI-CDS-12: Should: exit with status 0 and keep the empty quote pair as a declared but invalid value"
          When call collect_declared_scopes
          The status should equal 0
          The output should equal "$(printf '""\toscar/emptyquotes/workspaces/module/module.md')"
          The stderr should equal ""
        End
      End
    End

    Describe "Given: a module.md whose test_scope value is an empty pair of single quotes"
      # shellcheck disable=SC2329
      setup_empty_single_quotes_module() {
        write_module_md "quebec/emptysinglequotes" "---" "test_scope: ''" "---"
      }
      Before "setup_empty_single_quotes_module"

      Describe "When: call collect_declared_scopes"
        It "[Edge] T-CLI-CDS-14: Should: exit with status 0 and keep the empty quote pair as a declared but invalid value"
          When call collect_declared_scopes
          The status should equal 0
          The output should equal "$(printf "''\tquebec/emptysinglequotes/workspaces/module/module.md")"
          The stderr should equal ""
        End
      End
    End

    Describe "Given: a module.md whose test_scope value ends with a carriage return and a space"
      # shellcheck disable=SC2329
      setup_cr_scope_module() {
        # The CR must not sit at end of line: Windows gawk reads in text mode and
        # would strip it, making this case pass vacuously.
        write_module_md "romeo/cr-scope" "---" "$(printf 'test_scope: "ALP"\r ')" "---"
      }
      Before "setup_cr_scope_module"

      Describe "When: call collect_declared_scopes"
        It "[Edge] T-CLI-CDS-15: Should: exit with status 0 and strip the trailing carriage return as whitespace"
          When call collect_declared_scopes
          The status should equal 0
          The output should equal "$(printf 'ALP\tromeo/cr-scope/workspaces/module/module.md')"
          The stderr should equal ""
        End
      End
    End

    Describe "Given: a module.md whose test_scope value is a single double quote character"
      # shellcheck disable=SC2329
      setup_lone_quote_module() {
        write_module_md "papa/lonequote" "---" 'test_scope: "' "---"
      }
      Before "setup_lone_quote_module"

      Describe "When: call collect_declared_scopes"
        It "[Edge] T-CLI-CDS-13: Should: exit with status 0 and keep the lone quote because it has no pair"
          When call collect_declared_scopes
          The status should equal 0
          The output should equal "$(printf '"\tpapa/lonequote/workspaces/module/module.md')"
        End
      End
    End

    Describe "Given: a module.md only at the legacy location directly under the module directory"
      # shellcheck disable=SC2329
      setup_legacy_module_md() {
        mkdir -p "${DECKRD_DOCS_DIR}/sierra/legacy"
        printf '%s\n' "---" "test_scope: LEG" "---" >"${DECKRD_DOCS_DIR}/sierra/legacy/module.md"
      }
      Before "setup_legacy_module_md"

      Describe "When: call collect_declared_scopes"
        It "[Edge] T-CLI-CDS-16: Should: exit with status 0 and output nothing because the legacy location is not read"
          When call collect_declared_scopes
          The status should equal 0
          The output should equal ""
          The stderr should equal ""
        End
      End
    End

    Describe "Given: a module.md nested deeper than <namespace>/<module>"
      # shellcheck disable=SC2329
      setup_nested_module_md() {
        write_module_md "tango/deep/nested" "---" "test_scope: DEP" "---"
      }
      Before "setup_nested_module_md"

      Describe "When: call collect_declared_scopes"
        It "[Edge] T-CLI-CDS-17: Should: exit with status 0 and output nothing because only <namespace>/<module> is searched"
          When call collect_declared_scopes
          The status should equal 0
          The output should equal ""
          The stderr should equal ""
        End
      End
    End

    Describe "Given: a module.md and a frontmatter reader that cannot run"
      # shellcheck disable=SC2329
      setup_module_without_reader() {
        write_module_md "uniform/no-reader" "---" "test_scope: UNI" "---"
        break_frontmatter_reader
      }
      Before "setup_module_without_reader"
      After "restore_frontmatter_reader"

      Describe "When: call collect_declared_scopes"
        It "[Error] T-CLI-CDS-18: Should: exit with status 1 and name the unreadable declaration on stderr"
          When call collect_declared_scopes
          The status should equal 1
          The output should equal ""
          The stderr should include "cannot read module declaration"
          The stderr should include "uniform/no-reader/workspaces/module/module.md"
        End
      End
    End

    Describe "Given: a module.md without read permission"
      Skip if "chmod cannot block reading here" chmod_cannot_block_read

      # shellcheck disable=SC2329
      setup_unreadable_module() {
        write_module_md "victor/locked" "---" "test_scope: VIC" "---"
        chmod 000 "${DECKRD_DOCS_DIR}/victor/locked/workspaces/module/module.md"
      }
      Before "setup_unreadable_module"

      Describe "When: call collect_declared_scopes"
        It "[Error] T-CLI-CDS-19: Should: exit with status 1 and name the unreadable declaration on stderr"
          When call collect_declared_scopes
          The status should equal 1
          The output should equal ""
          The stderr should include "cannot read module declaration"
          The stderr should include "victor/locked/workspaces/module/module.md"
        End
      End
    End
  End

  # --------------------------------------------------------------------------
  # read_declared_scope
  # --------------------------------------------------------------------------

  Describe "T-CLI-RDS: read_declared_scope"

    load_module_functions_for_read_declared() {
      # shellcheck disable=SC2329
      validate_env() { return 0; }
      export -f validate_env

      # shellcheck disable=SC1090
      . "$SCRIPT"
    }

    # Helper: 一時 docs ディレクトリに test_scope を宣言した module.md を作る
    # 値は加工せずそのまま書き込むので、引用符つきの宣言もそのまま再現できる
    # shellcheck disable=SC2329
    declare_raw_module_scope() {
      local module_path="$1"
      local raw_value="$2"
      mkdir -p "${DECKRD_DOCS_DIR}/${module_path}/workspaces/module"
      printf '%s\n' "---" "title: normalize" "test_scope: ${raw_value}" "---" \
        >"${DECKRD_DOCS_DIR}/${module_path}/workspaces/module/module.md"
    }

    Before "setup_deckrd_tmpdir" "load_module_functions_for_read_declared"
    Before "init_vars"
    After "teardown_deckrd_tmpdir"

    Describe "Given: a module.md whose test_scope value has no quotes"
      # shellcheck disable=SC2329
      setup_unquoted_declaration() {
        declare_raw_module_scope "alpha/normalize" "NOR"
      }
      Before "setup_unquoted_declaration"

      Describe "When: call read_declared_scope for that module"
        It "[Normal] T-CLI-RDS-01: Should: exit with status 0 and output the declared scope as written"
          When call read_declared_scope "alpha/normalize"
          The status should equal 0
          The output should equal "NOR"
        End
      End
    End

    Describe "Given: a module.md whose test_scope value is wrapped in double quotes"
      # shellcheck disable=SC2329
      setup_double_quoted_declaration() {
        declare_raw_module_scope "alpha/normalize" '"NOR"'
      }
      Before "setup_double_quoted_declaration"

      Describe "When: call read_declared_scope for that module"
        It "[Normal] T-CLI-RDS-02: Should: exit with status 0 and output the scope with the double quotes stripped"
          When call read_declared_scope "alpha/normalize"
          The status should equal 0
          The output should equal "NOR"
        End
      End
    End

    Describe "Given: a module.md whose test_scope value is wrapped in single quotes"
      # shellcheck disable=SC2329
      setup_single_quoted_declaration() {
        declare_raw_module_scope "alpha/normalize" "'NOR'"
      }
      Before "setup_single_quoted_declaration"

      Describe "When: call read_declared_scope for that module"
        It "[Normal] T-CLI-RDS-03: Should: exit with status 0 and output the scope with the single quotes stripped"
          When call read_declared_scope "alpha/normalize"
          The status should equal 0
          The output should equal "NOR"
        End
      End
    End

    Describe "Given: the module has no module.md at all"
      Describe "When: call read_declared_scope for that module"
        It "[Edge] T-CLI-RDS-04: Should: exit with status 0 and output nothing"
          When call read_declared_scope "alpha/normalize"
          The status should equal 0
          The output should equal ""
          The stderr should equal ""
        End
      End
    End

    Describe "Given: a module.md only at the legacy location directly under the module directory"
      # shellcheck disable=SC2329
      setup_legacy_declaration() {
        mkdir -p "${DECKRD_DOCS_DIR}/alpha/normalize"
        printf '%s\n' "---" "title: normalize" "test_scope: NOR" "---" >"${DECKRD_DOCS_DIR}/alpha/normalize/module.md"
      }
      Before "setup_legacy_declaration"

      Describe "When: call read_declared_scope for that module"
        It "[Edge] T-CLI-RDS-05: Should: exit with status 0 and output nothing because the legacy location is not read"
          When call read_declared_scope "alpha/normalize"
          The status should equal 0
          The output should equal ""
          The stderr should equal ""
        End
      End
    End

    Describe "Given: a module.md and a frontmatter reader that cannot run"
      # shellcheck disable=SC2329
      setup_declaration_without_reader() {
        declare_raw_module_scope "alpha/normalize" "NOR"
        break_frontmatter_reader
      }
      Before "setup_declaration_without_reader"
      After "restore_frontmatter_reader"

      Describe "When: call read_declared_scope for that module"
        It "[Error] T-CLI-RDS-06: Should: exit with status 1 and name the unreadable declaration on stderr"
          When call read_declared_scope "alpha/normalize"
          The status should equal 1
          The output should equal ""
          The stderr should include "cannot read module declaration"
        End
      End
    End

    Describe "Given: a module.md without read permission"
      Skip if "chmod cannot block reading here" chmod_cannot_block_read

      # shellcheck disable=SC2329
      setup_unreadable_declaration() {
        declare_raw_module_scope "alpha/normalize" "NOR"
        chmod 000 "${DECKRD_DOCS_DIR}/alpha/normalize/workspaces/module/module.md"
      }
      Before "setup_unreadable_declaration"

      Describe "When: call read_declared_scope for that module"
        It "[Error] T-CLI-RDS-07: Should: exit with status 1 and name the unreadable declaration on stderr"
          When call read_declared_scope "alpha/normalize"
          The status should equal 1
          The output should equal ""
          The stderr should include "cannot read module declaration"
        End
      End
    End
  End


  # --------------------------------------------------------------------------
  # resolve_test_scope
  # --------------------------------------------------------------------------

  Describe "T-CLI-RTS: resolve_test_scope"

    load_module_functions_for_resolve() {
      # shellcheck disable=SC2329
      validate_env() { return 0; }
      export -f validate_env

      # shellcheck disable=SC1090
      . "$SCRIPT"
    }

    # Helper: 一時 docs ディレクトリに <namespace>/<module>/module.md を作る
    # shellcheck disable=SC2329
    declare_module_scope() {
      local module_path="$1"
      local scope="$2"
      mkdir -p "${DECKRD_DOCS_DIR}/${module_path}/workspaces/module"
      printf '%s\n' "---" "test_scope: ${scope}" "---" >"${DECKRD_DOCS_DIR}/${module_path}/workspaces/module/module.md"
    }

    Before "setup_deckrd_tmpdir" "load_module_functions_for_resolve"
    Before "init_vars"
    After "teardown_deckrd_tmpdir"

    Describe "Given: an explicit test scope that no module has declared"
      Describe "When: call resolve_test_scope with the explicit scope"
        It "[Normal] T-CLI-RTS-01: Should: exit with status 0 and output the explicit scope"
          When call resolve_test_scope "alpha/normalize" "XYZ"
          The status should equal 0
          The output should equal "XYZ"
        End
      End
    End

    Describe "Given: no explicit test scope is provided"
      Describe "When: call resolve_test_scope with only the module path"
        It "[Normal] T-CLI-RTS-02: Should: exit with status 0 and output the scope derived from the module name"
          When call resolve_test_scope "alpha/normalize"
          The status should equal 0
          The output should equal "NOR"
        End
      End

      Describe "When: call resolve_test_scope with an empty explicit scope"
        It "[Edge] T-CLI-RTS-03: Should: exit with status 0 and output the scope derived from the module name"
          When call resolve_test_scope "alpha/normalize" ""
          The status should equal 0
          The output should equal "NOR"
        End
      End
    End

    Describe "Given: an explicit test scope that is not 2-4 uppercase alphanumerics"
      Parameters
        "abc"
        "A"
        "ABCDE"
        "A-B"
      End

      Describe "When: call resolve_test_scope with the malformed explicit scope"
        It "[Error] T-CLI-RTS-04: Should: exit with status 1 and report the rejected scope on stderr"
          When call resolve_test_scope "alpha/normalize" "$1"
          The status should equal 1
          The stderr should include "Error"
          The stderr should include "$1"
          The output should equal ""
        End
      End
    End

    Describe "Given: no explicit scope and a module name too short to derive a scope from"
      Describe "When: call resolve_test_scope with only the module path"
        It "[Error] T-CLI-RTS-05: Should: exit with status 1 and propagate the derivation error to stderr"
          When call resolve_test_scope "alpha/a"
          The status should equal 1
          The stderr should include "cannot derive a test scope"
          The output should equal ""
        End
      End
    End

    Describe "Given: another module already declares the candidate scope"
      # shellcheck disable=SC2329
      setup_conflicting_module() {
        declare_module_scope "bravo/notation" "NOR"
      }
      Before "setup_conflicting_module"

      Describe "When: call resolve_test_scope without an explicit scope"
        It "[Error] T-CLI-RTS-06: Should: exit with status 1 and report the conflict, the owner module.md and the --test-scope hint"
          When call resolve_test_scope "alpha/normalize"
          The status should equal 1
          The stderr should include "conflict"
          The stderr should include "bravo/notation/workspaces/module/module.md"
          The stderr should include "--test-scope"
          The output should equal ""
        End
      End

      Describe "When: call resolve_test_scope with the same scope given explicitly"
        It "[Error] T-CLI-RTS-07: Should: exit with status 1 and report the conflict, the owner module.md and the --test-scope hint"
          When call resolve_test_scope "alpha/normalize" "NOR"
          The status should equal 1
          The stderr should include "conflict"
          The stderr should include "bravo/notation/workspaces/module/module.md"
          The stderr should include "--test-scope"
          The output should equal ""
        End
      End
    End

    Describe "Given: the module itself already declares the candidate scope"
      # shellcheck disable=SC2329
      setup_self_declared_module() {
        declare_module_scope "alpha/normalize" "NOR"
      }
      Before "setup_self_declared_module"

      Describe "When: call resolve_test_scope for that same module"
        It "[Edge] T-CLI-RTS-08: Should: exit with status 0 and output the scope, ignoring its own declaration"
          When call resolve_test_scope "alpha/normalize"
          The status should equal 0
          The output should equal "NOR"
          The stderr should equal ""
        End
      End

      Describe "When: call resolve_test_scope with the same scope given explicitly"
        It "[Normal] T-CLI-RTS-14: Should: exit with status 0 and output the scope, accepting the redundant explicit scope"
          When call resolve_test_scope "alpha/normalize" "NOR"
          The status should equal 0
          The output should equal "NOR"
          The stderr should equal ""
        End
      End

      Describe "When: call resolve_test_scope with a different scope given explicitly"
        It "[Error] T-CLI-RTS-13: Should: exit with status 1 and report both the declared scope and the explicit one on stderr"
          When call resolve_test_scope "alpha/normalize" "XYZ"
          The status should equal 1
          The stderr should include "NOR"
          The stderr should include "XYZ"
          The output should equal ""
        End
      End
    End

    Describe "Given: another module declares the candidate scope wrapped in double quotes"
      # shellcheck disable=SC2329
      setup_double_quoted_conflict() {
        declare_module_scope "bravo/notation" '"NOR"'
      }
      Before "setup_double_quoted_conflict"

      Describe "When: call resolve_test_scope with the same scope given explicitly"
        It "[Error] T-CLI-RTS-09: Should: exit with status 1 and report the conflict, the owner module.md and the --test-scope hint"
          When call resolve_test_scope "alpha/normalize" "NOR"
          The status should equal 1
          The stderr should include "conflict"
          The stderr should include "bravo/notation/workspaces/module/module.md"
          The stderr should include "--test-scope"
          The output should equal ""
        End
      End
    End

    Describe "Given: another module declares the candidate scope wrapped in single quotes"
      # shellcheck disable=SC2329
      setup_single_quoted_conflict() {
        declare_module_scope "bravo/notation" "'NOR'"
      }
      Before "setup_single_quoted_conflict"

      Describe "When: call resolve_test_scope with the same scope given explicitly"
        It "[Error] T-CLI-RTS-10: Should: exit with status 1 and report the conflict, the owner module.md and the --test-scope hint"
          When call resolve_test_scope "alpha/normalize" "NOR"
          The status should equal 1
          The stderr should include "conflict"
          The stderr should include "bravo/notation/workspaces/module/module.md"
          The stderr should include "--test-scope"
          The output should equal ""
        End
      End
    End

    Describe "Given: the module itself declares the candidate scope wrapped in double quotes"
      # shellcheck disable=SC2329
      setup_self_double_quoted_module() {
        declare_module_scope "alpha/normalize" '"NOR"'
      }
      Before "setup_self_double_quoted_module"

      Describe "When: call resolve_test_scope with the scope read back from its own module.md"
        It "[Edge] T-CLI-RTS-11: Should: exit with status 0 and keep the declared scope"
          When call resolve_test_scope "alpha/normalize" "$(read_declared_scope "alpha/normalize")"
          The status should equal 0
          The output should equal "NOR"
          The stderr should equal ""
        End
      End
    End

    Describe "Given: another module's declaration cannot be read"
      # shellcheck disable=SC2329
      setup_unread_conflict() {
        declare_module_scope "bravo/notation" "NOR"
        break_frontmatter_reader
      }
      Before "setup_unread_conflict"
      After "restore_frontmatter_reader"

      Describe "When: call resolve_test_scope with the scope that module declares"
        It "[Error] T-CLI-RTS-15: Should: exit with status 1 and output no scope instead of accepting a possible duplicate"
          When call resolve_test_scope "alpha/normalize" "NOR"
          The status should equal 1
          The output should equal ""
          The stderr should include "bravo/notation/workspaces/module/module.md"
        End
      End
    End

    Describe "Given: another module declares the candidate scope and the reader exits with a failure"
      # shellcheck disable=SC2329
      setup_failing_reader_conflict() {
        declare_module_scope "bravo/notation" "NOR"
        export AWK=false
      }
      Before "setup_failing_reader_conflict"
      After "restore_frontmatter_reader"

      Describe "When: call resolve_test_scope with the scope that module declares"
        It "[Error] T-CLI-RTS-16: Should: exit with status 1 and output no scope instead of accepting the duplicate"
          When call resolve_test_scope "alpha/normalize" "NOR"
          The status should equal 1
          The output should equal ""
          The stderr should include "Error: cannot read module declaration: ${DECKRD_DOCS_DIR}/bravo/notation/workspaces/module/module.md"
        End
      End
    End

    Describe "Given: the module itself declares the candidate scope wrapped in single quotes"
      # shellcheck disable=SC2329
      setup_self_single_quoted_module() {
        declare_module_scope "alpha/normalize" "'NOR'"
      }
      Before "setup_self_single_quoted_module"

      Describe "When: call resolve_test_scope with the scope read back from its own module.md"
        It "[Edge] T-CLI-RTS-12: Should: exit with status 0 and keep the declared scope"
          When call resolve_test_scope "alpha/normalize" "$(read_declared_scope "alpha/normalize")"
          The status should equal 0
          The output should equal "NOR"
          The stderr should equal ""
        End
      End
    End
  End

  Describe "T-CLI-MMT: create_module_meta と CLI 連携"

    # --------------------------------------------------------------------------
    # create_module_meta / CLI wiring
    # --------------------------------------------------------------------------

    Describe "Given: a module path and no explicit test scope"
      Before "setup_deckrd_tmpdir"
      After "teardown_deckrd_tmpdir"

      Describe "When: run module.sh with the module path"
        It "[Normal] T-CLI-MMT-01: Should: exit with status 0 and write module.md declaring the derived test_scope"
          When run bash "$SCRIPT" my-ns/my-mod
          The status should equal 0
          The output should include "module.md"
          The contents of file "${DECKRD_DOCS_DIR}/my-ns/my-mod/workspaces/module/module.md" should include "title: my-mod"
          The contents of file "${DECKRD_DOCS_DIR}/my-ns/my-mod/workspaces/module/module.md" should include "test_scope: MM"
          The contents of file "${DECKRD_LOCAL_DATA}/session.json" should include '"test_scope": "MM"'
        End
      End
    End

    Describe "Given: a module path and an explicit test scope"
      Before "setup_deckrd_tmpdir"
      After "teardown_deckrd_tmpdir"

      Describe "When: run module.sh with --test-scope"
        It "[Normal] T-CLI-MMT-02: Should: exit with status 0 and write module.md declaring the explicit test_scope"
          When run bash "$SCRIPT" my-ns/my-mod --test-scope XY
          The status should equal 0
          The output should include "module.md"
          The contents of file "${DECKRD_DOCS_DIR}/my-ns/my-mod/workspaces/module/module.md" should include "test_scope: XY"
        End
      End

      Describe "When: run module.sh with the inline form --test-scope=XY"
        It "[Normal] T-CLI-MMT-10: Should: exit with status 0 and write module.md declaring the inline test_scope"
          When run bash "$SCRIPT" my-ns/my-mod --test-scope=XY
          The status should equal 0
          The output should include "module.md"
          The contents of file "${DECKRD_DOCS_DIR}/my-ns/my-mod/workspaces/module/module.md" should include "test_scope: XY"
        End
      End
    End

    Describe "Given: another module already declares the requested test scope"
      # shellcheck disable=SC2329
      setup_conflicting_declaration() {
        setup_deckrd_tmpdir
        mkdir -p "${DECKRD_DOCS_DIR}/other-ns/othermod/workspaces/module"
        printf '%s\n' "---" "test_scope: XY" "---" >"${DECKRD_DOCS_DIR}/other-ns/othermod/workspaces/module/module.md"
      }
      Before "setup_conflicting_declaration"
      After "teardown_deckrd_tmpdir"

      Describe "When: run module.sh with the taken scope via --test-scope"
        It "[Error] T-CLI-MMT-03: Should: exit with status 1, report the conflicting module.md and write no module.md"
          When run bash "$SCRIPT" my-ns/my-mod --test-scope XY
          The status should equal 1
          The output should include "Initializing module"
          The stderr should include "conflict"
          The stderr should include "other-ns/othermod/workspaces/module/module.md"
          The path "${DECKRD_DOCS_DIR}/my-ns/my-mod/workspaces/module/module.md" should not be exist
        End
      End
    End

    Describe "Given: an existing module.md declaring a test scope"
      # shellcheck disable=SC2329
      setup_existing_module_meta() {
        setup_deckrd_tmpdir
        mkdir -p "${DECKRD_DOCS_DIR}/my-ns/my-mod/workspaces/module"
        printf '%s\n' "---" "title: my-mod" "test_scope: ZZ" "---" >"${DECKRD_DOCS_DIR}/my-ns/my-mod/workspaces/module/module.md"
      }
      Before "setup_existing_module_meta"
      After "teardown_deckrd_tmpdir"

      Describe "When: re-initialize the module with --force"
        It "[Edge] T-CLI-MMT-04: Should: exit with status 0 and keep the test_scope already declared in module.md"
          When run bash "$SCRIPT" my-ns/my-mod --force
          The status should equal 0
          The output should include "module.md"
          The contents of file "${DECKRD_DOCS_DIR}/my-ns/my-mod/workspaces/module/module.md" should include "test_scope: ZZ"
        End
      End
    End

    Describe "Given: --test-scope given without a value"
      Before "setup_deckrd_tmpdir"
      After "teardown_deckrd_tmpdir"

      Describe "When: run module.sh with a trailing --test-scope"
        It "[Error] T-CLI-MMT-05: Should: exit with status 1 and report that --test-scope requires a value"
          When run bash "$SCRIPT" my-ns/my-mod --test-scope
          The status should equal 1
          The output should include "Usage:"
          The stderr should include "requires a value"
        End
      End
    End

    Describe "Given: a module initialized with an explicit test scope"
      # shellcheck disable=SC2329
      setup_module_with_explicit_scope() {
        setup_deckrd_tmpdir_with_project
        bash "$SCRIPT" my-ns/my-mod --test-scope XY >/dev/null 2>&1
      }
      Before "setup_module_with_explicit_scope"
      After "teardown_deckrd_tmpdir"

      Describe "When: re-initialize the module with --force and no --test-scope"
        It "[Normal] T-CLI-MMT-06: Should: keep the declared scope in both module.md and session.json"
          When run bash "$SCRIPT" my-ns/my-mod --force
          The status should equal 0
          The output should include "module.md"
          The contents of file "${DECKRD_DOCS_DIR}/my-ns/my-mod/workspaces/module/module.md" should include "test_scope: XY"
          The contents of file "${DECKRD_LOCAL_DATA}/session.json" should include '"test_scope": "XY"'
          The contents of file "${DECKRD_LOCAL_DATA}/session.json" should not include '"test_scope": "MM"'
        End
      End
    End

    Describe "Given: a third module already declares the scope derived from the module name"
      # shellcheck disable=SC2329
      setup_derived_scope_taken_by_third_module() {
        setup_deckrd_tmpdir_with_project
        mkdir -p "${DECKRD_DOCS_DIR}/my-ns/my-mod/workspaces/module" "${DECKRD_DOCS_DIR}/third-ns/thirdmod/workspaces/module"
        printf '%s\n' "---" "title: my-mod" "test_scope: XY" "---" >"${DECKRD_DOCS_DIR}/my-ns/my-mod/workspaces/module/module.md"
        printf '%s\n' "---" "title: thirdmod" "test_scope: MM" "---" >"${DECKRD_DOCS_DIR}/third-ns/thirdmod/workspaces/module/module.md"
      }
      Before "setup_derived_scope_taken_by_third_module"
      After "teardown_deckrd_tmpdir"

      Describe "When: re-initialize the module with --force and no --test-scope"
        It "[Edge] T-CLI-MMT-07: Should: exit with status 0 because the declared scope is used instead of the derived one"
          When run bash "$SCRIPT" my-ns/my-mod --force
          The status should equal 0
          The output should include "module.md"
          The stderr should not include "conflict"
          The contents of file "${DECKRD_LOCAL_DATA}/session.json" should include '"test_scope": "XY"'
        End
      End
    End

    Describe "Given: an existing module.md whose test_scope value is wrapped in double quotes"
      # shellcheck disable=SC2329
      setup_quoted_declaration() {
        setup_deckrd_tmpdir_with_project
        mkdir -p "${DECKRD_DOCS_DIR}/my-ns/my-mod/workspaces/module"
        printf '%s\n' "---" "title: my-mod" 'test_scope: "ZZ"' "---" \
          >"${DECKRD_DOCS_DIR}/my-ns/my-mod/workspaces/module/module.md"
      }
      Before "setup_quoted_declaration"
      After "teardown_deckrd_tmpdir"

      Describe "When: re-initialize the module with --force and no --test-scope"
        It "[Normal] T-CLI-MMT-08: Should: exit with status 0 and keep the quoted scope, recording it unquoted in session.json"
          When run bash "$SCRIPT" my-ns/my-mod --force
          The status should equal 0
          The stderr should not include "invalid test scope"
          The output should include "kept existing test_scope"
          The contents of file "${DECKRD_LOCAL_DATA}/session.json" should include '"test_scope": "ZZ"'
          The contents of file "${DECKRD_DOCS_DIR}/my-ns/my-mod/workspaces/module/module.md" should include 'test_scope: "ZZ"'
        End
      End
    End

    Describe "Given: the environment has neither jq nor jaq"
      mock_validate_env_failure() {
        setup_deckrd_tmpdir
        # shellcheck disable=SC2329
        validate_env() { echo "Error: jq or jaq is required but not installed." >&2; return 1; }
        export -f validate_env
      }
      unmock_validate_env_failure() {
        unset -f validate_env
        teardown_deckrd_tmpdir
      }
      Before "mock_validate_env_failure"
      After "unmock_validate_env_failure"

      Describe "When: run module.sh with a module path"
        It "[Error] T-CLI-MMT-09: Should: exit with status 1 and print only the library message to stderr"
          When run bash "$SCRIPT" my-ns/my-mod
          The status should equal 1
          The lines of entire stderr should eq 1
          The stderr should include "jq or jaq is required"
        End
      End
    End

    Describe "Given: a declared module.md and a frontmatter reader that cannot run"
      # shellcheck disable=SC2329
      setup_cli_without_reader() {
        setup_deckrd_tmpdir
        mkdir -p "${DECKRD_DOCS_DIR}/bravo/notation/workspaces/module"
        printf '%s\n' "---" "test_scope: NOR" "---" >"${DECKRD_DOCS_DIR}/bravo/notation/workspaces/module/module.md"
        # module.sh ignores $AWK, so the reader is broken through the awk command itself
        awk() { return 1; }
        export -f awk
      }
      # shellcheck disable=SC2329
      restore_awk_command() { unset -f awk; }
      Before "setup_cli_without_reader"
      After "restore_awk_command" "teardown_deckrd_tmpdir"

      Describe "When: run module.sh for another module that would derive the same scope"
        It "[Error] T-CLI-MMT-11: Should: exit with status 1 and write neither module.md nor session.json"
          When run bash "$SCRIPT" alpha/normalize
          The status should equal 1
          The output should not include "Session updated"
          The stderr should include "cannot read module declaration"
          The path "${DECKRD_DOCS_DIR}/alpha/normalize/workspaces/module/module.md" should not be exist
          The path "${DECKRD_LOCAL_DATA}/session.json" should not be exist
        End
      End

      Describe "When: run module.sh with --force for the declared module itself"
        It "[Error] T-CLI-MMT-12: Should: exit with status 1 and write no session.json"
          When run bash "$SCRIPT" bravo/notation --force --test-scope XYZ
          The status should equal 1
          The output should not include "Session updated"
          The stderr should include "cannot read module declaration"
          The path "${DECKRD_LOCAL_DATA}/session.json" should not be exist
        End
      End
    End

    # Helper: declare <test_scope> in the module.md of <namespace/module>, then set a
    # multi-word AWK that no command lookup can resolve
    # shellcheck disable=SC2329
    setup_awk_env_with_declaration() {
      setup_deckrd_tmpdir
      mkdir -p "${DECKRD_DOCS_DIR}/$1/workspaces/module"
      printf '%s\n' "---" "test_scope: $2" "---" >"${DECKRD_DOCS_DIR}/$1/workspaces/module/module.md"
      export AWK="gawk --posix"
    }

    Describe "Given: another module declares a different scope and AWK is a multi-word command"
      # shellcheck disable=SC2329
      setup_awk_env_with_other_scope() { setup_awk_env_with_declaration "bravo/notation" "NOR"; }
      Before "setup_awk_env_with_other_scope"
      After "restore_frontmatter_reader" "teardown_deckrd_tmpdir"

      Describe "When: run module.sh for a new module"
        It "[Normal] T-CLI-MMT-13: Should: exit with status 0 and create the module with the derived scope"
          When run bash "$SCRIPT" my-ns/my-mod
          The status should equal 0
          The output should include "Session updated"
          The stderr should equal ""
          The contents of file "${DECKRD_DOCS_DIR}/my-ns/my-mod/workspaces/module/module.md" should include "test_scope: MM"
          The contents of file "${DECKRD_LOCAL_DATA}/session.json" should include '"test_scope": "MM"'
        End
      End
    End

    Describe "Given: another module declares the derived scope and AWK is a multi-word command"
      # shellcheck disable=SC2329
      setup_awk_env_with_taken_scope() { setup_awk_env_with_declaration "third-ns/thirdmod" "MM"; }
      Before "setup_awk_env_with_taken_scope"
      After "restore_frontmatter_reader" "teardown_deckrd_tmpdir"

      Describe "When: run module.sh for a new module"
        It "[Error] T-CLI-MMT-14: Should: exit with status 1, report the conflicting module.md and write no module.md"
          When run bash "$SCRIPT" my-ns/my-mod
          The status should equal 1
          The output should include "Initializing module"
          The stderr should include "conflict"
          The stderr should include "third-ns/thirdmod/workspaces/module/module.md"
          The path "${DECKRD_DOCS_DIR}/my-ns/my-mod/workspaces/module/module.md" should not be exist
        End
      End
    End

    Describe "Given: a module declaring its own test scope and AWK is a multi-word command"
      # shellcheck disable=SC2329
      setup_awk_env_with_own_scope() { setup_awk_env_with_declaration "my-ns/my-mod" "ZZ"; }
      Before "setup_awk_env_with_own_scope"
      After "restore_frontmatter_reader" "teardown_deckrd_tmpdir"

      Describe "When: re-initialize the module with --force"
        It "[Edge] T-CLI-MMT-15: Should: exit with status 0 and read back the declared scope into session.json"
          When run bash "$SCRIPT" my-ns/my-mod --force
          The status should equal 0
          The output should include "kept existing test_scope"
          The stderr should equal ""
          The contents of file "${DECKRD_LOCAL_DATA}/session.json" should include '"test_scope": "ZZ"'
        End
      End
    End
  End

  Describe "T-CLI-MSW: main の switch モード (既存モジュールの切り替え)"
    # Two registered modules: ns/a (active, has progress) and ns/b (module.md declares BBB)
    _MSW_MODULES='{"ns/a":{"current_step":"req","completed":["module","req"],"documents":{"req":"x.md"},"test_scope":"AAA"},"ns/b":{"current_step":"module","completed":["module"],"documents":{},"test_scope":"BBB"}}'
    _MSW_SESSION="{\"active\":\"ns/a\",\"modules\":${_MSW_MODULES},\"created_at\":\"2026-01-01T00:00:00Z\",\"updated_at\":\"2026-01-01T00:00:00Z\"}"

    # shellcheck disable=SC2329
    setup_two_modules() {
      setup_deckrd_tmpdir
      local ns_mod
      for ns_mod in a:AAA b:BBB; do
        mkdir -p "${DECKRD_DOCS_DIR}/ns/${ns_mod%%:*}/workspaces/module"
        printf '%s\n' "---" "title: ${ns_mod%%:*}" "test_scope: ${ns_mod##*:}" "---" \
          >"${DECKRD_DOCS_DIR}/ns/${ns_mod%%:*}/workspaces/module/module.md"
      done
      printf '%s\n' "$_MSW_SESSION" >"${DECKRD_LOCAL_DATA}/session.json"
    }

    # shellcheck disable=SC2329
    session_query() {
      jq -c "$1" "${DECKRD_LOCAL_DATA}/session.json"
    }

    Describe "Given: two registered modules whose directories exist"
      Before "setup_two_modules"
      After "teardown_deckrd_tmpdir"

      Describe "When: run module.sh with the existing module path and no --force"
        It "[Normal] T-CLI-MSW-01: Should: exit with status 0 and switch the active module to ns/b"
          When run bash "$SCRIPT" ns/b
          The status should equal 0
          The output should include "Switched active module: ns/b"
          The value "$(session_query '.active')" should equal '"ns/b"'
        End
      End

      Describe "When: run module.sh with the existing module path and no --force"
        It "[Normal] T-CLI-MSW-02: Should: leave module.md and the module directory untouched and skip create output"
          When run bash "$SCRIPT" ns/b
          The status should equal 0
          The output should not include "Initializing module"
          The output should not include "Module meta"
          The contents of file "${DECKRD_DOCS_DIR}/ns/b/workspaces/module/module.md" should equal "$(printf '%s\n' '---' 'title: b' 'test_scope: BBB' '---')"
          The value "$(cd "${DECKRD_DOCS_DIR}/ns/b" && find . | sort | tr '\n' ' ')" should equal ". ./workspaces ./workspaces/module ./workspaces/module/module.md "
        End
      End

      Describe "When: run module.sh with a new module path whose directory does not exist"
        It "[Normal] T-CLI-MSW-03: Should: create the module and register it as active at the module step"
          When run bash "$SCRIPT" ns/new
          The status should equal 0
          The output should include "Session updated"
          The path "${DECKRD_DOCS_DIR}/ns/new/requirements" should be directory
          The path "${DECKRD_DOCS_DIR}/ns/new/specifications" should be directory
          The path "${DECKRD_DOCS_DIR}/ns/new/implementation" should be directory
          The path "${DECKRD_DOCS_DIR}/ns/new/tasks" should be directory
          The path "${DECKRD_DOCS_DIR}/ns/new/workspaces" should be directory
          The path "${DECKRD_DOCS_DIR}/ns/new/workspaces/module/module.md" should be file
          The value "$(session_query '.modules["ns/new"].current_step')" should equal '"module"'
          The value "$(session_query '.active')" should equal '"ns/new"'
        End
      End

      Describe "When: run module.sh with --force on the existing module with progress"
        It "[Normal] T-CLI-MSW-04: Should: bypass switch mode and reset the entry to the module step keeping test_scope"
          When run bash "$SCRIPT" ns/a --force
          The status should equal 0
          The output should include "Session updated"
          The value "$(session_query '.modules["ns/a"]')" should equal '{"current_step":"module","completed":["module"],"documents":{},"test_scope":"AAA"}'
        End
      End

      Describe "When: run module.sh with --test-scope on the existing module without --force"
        It "[Error] T-CLI-MSW-07: Should: exit with status 1, name --test-scope in stderr and leave session.json untouched"
          When run bash "$SCRIPT" ns/b --test-scope MYM
          The status should equal 1
          The stderr should include "--test-scope"
          The stderr should include "cannot be changed"
          The output should not include "Switched"
          The contents of file "${DECKRD_LOCAL_DATA}/session.json" should equal "$_MSW_SESSION"
        End
      End
    End

    Describe "Given: an existing module directory that session.json does not register"
      # shellcheck disable=SC2329
      setup_unregistered_dir() {
        setup_two_modules
        mkdir -p "${DECKRD_DOCS_DIR}/ns/c"
      }
      Before "setup_unregistered_dir"
      After "teardown_deckrd_tmpdir"

      Describe "When: run module.sh with the unregistered module path and no --force"
        It "[Error] T-CLI-MSW-05: Should: exit with status 1, hint --force and leave session.json untouched"
          When run bash "$SCRIPT" ns/c
          The status should equal 1
          The stderr should include "--force"
          The output should not include "Switched"
          The contents of file "${DECKRD_LOCAL_DATA}/session.json" should equal "$_MSW_SESSION"
        End
      End
    End

    Describe "Given: an existing module directory and no session.json"
      # shellcheck disable=SC2329
      setup_dir_without_session() {
        setup_two_modules
        rm -f "${DECKRD_LOCAL_DATA}/session.json"
      }
      Before "setup_dir_without_session"
      After "teardown_deckrd_tmpdir"

      Describe "When: run module.sh with the existing module path and no --force"
        It "[Error] T-CLI-MSW-06: Should: exit with status 1, hint --force and create no session.json"
          When run bash "$SCRIPT" ns/b
          The status should equal 1
          The stderr should include "--force"
          The path "${DECKRD_LOCAL_DATA}/session.json" should not be exist
        End
      End
    End

    Describe "Given: two modules created one after another through module.sh"
      Before "setup_deckrd_tmpdir_with_project"
      After "teardown_deckrd_tmpdir"

      Describe "When: switch back and forth between them"
        It "[Transition] T-CLI-MSW-08: Should: switch the active module each time and keep the progress of both"
          bash "$SCRIPT" ns/aa >/dev/null
          jq '.modules["ns/aa"] |= (.current_step = "req" | .completed = ["module","req"] | .documents = {req:"x.md"})' \
            "${DECKRD_LOCAL_DATA}/session.json" >"${DECKRD_LOCAL_DATA}/session.tmp"
          mv "${DECKRD_LOCAL_DATA}/session.tmp" "${DECKRD_LOCAL_DATA}/session.json"
          bash "$SCRIPT" ns/bb >/dev/null
          jq '.modules["ns/bb"] |= (.current_step = "spec" | .completed = ["module","req","spec"] | .documents = {spec:"y.md"})' \
            "${DECKRD_LOCAL_DATA}/session.json" >"${DECKRD_LOCAL_DATA}/session.tmp"
          mv "${DECKRD_LOCAL_DATA}/session.tmp" "${DECKRD_LOCAL_DATA}/session.json"
          _MSW_CREATED_AT="$(session_query '.created_at')"
          bash "$SCRIPT" ns/aa >/dev/null
          bash "$SCRIPT" ns/bb >/dev/null
          When run bash "$SCRIPT" ns/aa
          The status should equal 0
          The output should include "Switched active module: ns/aa"
          The value "$(session_query '.active')" should equal '"ns/aa"'
          The value "$(session_query '.modules["ns/aa"] | [.current_step, .completed, .documents, .test_scope]')" should equal '["req",["module","req"],{"req":"x.md"},"AA"]'
          The value "$(session_query '.modules["ns/bb"] | [.current_step, .completed, .documents, .test_scope]')" should equal '["spec",["module","req","spec"],{"spec":"y.md"},"BB"]'
          The value "$(session_query '.created_at')" should equal "$_MSW_CREATED_AT"
        End
      End
    End
  End
End
