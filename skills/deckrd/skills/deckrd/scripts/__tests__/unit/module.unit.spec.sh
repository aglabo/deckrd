#!/usr/bin/env bash
# plugins/deckrd/skills/deckrd/tests/module.spec.sh
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

Include ../spec_helper.sh

SCRIPT="${DECKRD_SCRIPTS_DIR}/module.sh"

# Helper: setup tmpdir and create .project.json with project name "myproject"
setup_deckrd_tmpdir_with_project() {
  setup_deckrd_tmpdir
  mkdir -p "$DECKRD_LOCAL_DATA"
  printf '{"project":"myproject","project_type":"feature","language":"shell","ai_model":"sonnet","created_at":"2026-01-01T00:00:00Z","updated_at":"2026-01-01T00:00:00Z"}\n' \
    >"${DECKRD_LOCAL_DATA}/.project.json"
}

# ============================================================================
# module.sh
# ============================================================================

Describe "module.sh"

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
  # Given: valid legacy format argument (<namespace>/<module>)
  # --------------------------------------------------------------------------

  Describe "Given: valid legacy format argument (<namespace>/<module>)"
    Before "setup_deckrd_tmpdir"
    After "teardown_deckrd_tmpdir"

    Describe "When: run with 'myns/mymod'"
      It "[Normal] T-CLI-MOD-04: Should: exit with status 0, create all module directories, skip .project.json, and output 'Session updated'"
        When run bash "$SCRIPT" myns/mymod
        The status should equal 0
        The output should include "myns/mymod"
        The output should include "requirements"
        The output should include "specifications"
        The output should include "implementation"
        The output should include "tasks"
        The output should include "Session updated"
        The path "${DECKRD_DOCS_DIR}/myns/mymod/requirements" should be directory
        The path "${DECKRD_DOCS_DIR}/myns/mymod/specifications" should be directory
        The path "${DECKRD_DOCS_DIR}/myns/mymod/implementation" should be directory
        The path "${DECKRD_DOCS_DIR}/myns/mymod/tasks" should be directory
        The path "${DECKRD_DOCS_DIR}/myns/mymod/.project.json" should not be exist
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

    Describe "When: run with '/mymod' (empty namespace)"
      It "[Error] T-CLI-MOD-06: Should: exit with status 1 and output 'empty' error"
        When run bash "$SCRIPT" "/mymod"
        The status should equal 1
        The stderr should include "empty"
      End
    End

    Describe "When: run with 'myns/' (empty module)"
      It "[Error] T-CLI-MOD-07: Should: exit with status 1 and output 'empty' error"
        When run bash "$SCRIPT" "myns/"
        The status should equal 1
        The stderr should include "empty"
      End
    End

    Describe "When: run with 'my ns/mymod' (space in namespace)"
      It "[Error] T-CLI-MOD-08: Should: exit with status 1 and output 'invalid characters' error"
        When run bash "$SCRIPT" "my ns/mymod"
        The status should equal 1
        The stderr should include "invalid characters"
      End
    End

    Describe "When: run with 'myns/mymod' on existing directory without --force"
      It "[Error] T-CLI-MOD-09: Should: exit with status 1 and output 'already exists' error"
        mkdir -p "${DECKRD_DOCS_DIR}/myns/mymod"
        When run bash "$SCRIPT" myns/mymod
        The status should equal 1
        The stderr should include "already exists"
      End
    End

    Describe "When: run with 'myns/mymod' on existing directory with --force"
      It "[Edge] T-CLI-MOD-10: Should: exit with status 0 and output 'myns/mymod'"
        mkdir -p "${DECKRD_DOCS_DIR}/myns/mymod"
        When run bash "$SCRIPT" myns/mymod --force
        The status should equal 0
        The output should include "myns/mymod"
      End
    End
  End

  # --------------------------------------------------------------------------
  # Given: create subcommand with <namespace>/<module> format
  # --------------------------------------------------------------------------

  Describe "Given: create subcommand with <namespace>/<module> format"
    Before "setup_deckrd_tmpdir"
    After "teardown_deckrd_tmpdir"

    Describe "When: run 'create myns/mymod'"
      It "[Normal] T-CLI-MOD-11: Should: exit with status 0, create module dirs, and output 'Session updated'"
        When run bash "$SCRIPT" create myns/mymod
        The status should equal 0
        The output should include "myns/mymod"
        The output should include "Session updated"
        The path "${DECKRD_DOCS_DIR}/myns/mymod/requirements" should be directory
        The path "${DECKRD_DOCS_DIR}/myns/mymod/specifications" should be directory
        The path "${DECKRD_DOCS_DIR}/myns/mymod/.project.json" should not be exist
      End
    End

    Describe "When: run create with invalid namespace 'my ns/mymod'"
      It "[Error] T-CLI-MOD-12: Should: exit with status 1 and output 'invalid characters' error"
        When run bash "$SCRIPT" create "my ns/mymod"
        The status should equal 1
        The stderr should include "invalid characters"
      End
    End
  End

  # --------------------------------------------------------------------------
  # Given: create subcommand with <module> format (git remote auto-completion)
  # --------------------------------------------------------------------------

  Describe "Given: create subcommand with <module> format"
    Before "setup_deckrd_tmpdir"
    After "teardown_deckrd_tmpdir"

    Describe "When: run 'create myfeature'"
      It "[Normal] T-CLI-MOD-13: Should: exit with status 0 and output 'myfeature'"
        When run bash "$SCRIPT" create myfeature
        The status should equal 0
        The output should include "myfeature"
      End
    End
  End

  # --------------------------------------------------------------------------
  # derive_test_scope
  # --------------------------------------------------------------------------

  Describe "derive_test_scope"

    load_module_functions() {
      # Mock: validate_env を常に成功させる
      # shellcheck disable=SC2329
      validate_env() { return 0; }
      export -f validate_env

      # module.sh を source して関数をロード
      # shellcheck disable=SC1090
      . "$SCRIPT"
    }
    Before "load_module_functions"

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
  # collect_declared_scopes
  # --------------------------------------------------------------------------

  Describe "collect_declared_scopes"

    load_module_functions_for_scopes() {
      # Mock: validate_env を常に成功させる
      # shellcheck disable=SC2329
      validate_env() { return 0; }
      export -f validate_env

      # module.sh を source して関数をロード
      # shellcheck disable=SC1090
      . "$SCRIPT"
    }

    # Helper: 一時 docs ディレクトリに <namespace>/<module>/module.md を作る
    # shellcheck disable=SC2329
    write_module_md() {
      local module_path="$1"
      shift
      mkdir -p "${DECKRD_DOCS_DIR}/${module_path}"
      printf '%s\n' "$@" >"${DECKRD_DOCS_DIR}/${module_path}/module.md"
    }

    Before "setup_deckrd_tmpdir" "load_module_functions_for_scopes"
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
          The output should equal "$(printf 'NOR\talpha/normalize/module.md\nPAR\tbravo/parser/module.md')"
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
          The output should equal "$(printf 'PAD\tcharlie/padded/module.md')"
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
          The output should equal "$(printf 'ECH\techo/scoped/module.md')"
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
        write_module_md "hotel/nofrontmatter" "test_scope: BAD" "" "# no frontmatter"
      }
      Before "setup_body_text_modules"

      Describe "When: call collect_declared_scopes"
        It "[Edge] T-CLI-CDS-05: Should: exit with status 0 and read test_scope only from the frontmatter"
          When call collect_declared_scopes
          The status should equal 0
          The output should equal "$(printf 'GOL\tgolf/both/module.md')"
        End
      End
    End
  End


  # --------------------------------------------------------------------------
  # resolve_test_scope
  # --------------------------------------------------------------------------

  Describe "resolve_test_scope"

    load_module_functions_for_resolve() {
      # Mock: validate_env を常に成功させる
      # shellcheck disable=SC2329
      validate_env() { return 0; }
      export -f validate_env

      # module.sh を source して関数をロード
      # shellcheck disable=SC1090
      . "$SCRIPT"
    }

    # Helper: 一時 docs ディレクトリに <namespace>/<module>/module.md を作る
    # shellcheck disable=SC2329
    declare_module_scope() {
      local module_path="$1"
      local scope="$2"
      mkdir -p "${DECKRD_DOCS_DIR}/${module_path}"
      printf '%s\n' "---" "test_scope: ${scope}" "---" >"${DECKRD_DOCS_DIR}/${module_path}/module.md"
    }

    Before "setup_deckrd_tmpdir" "load_module_functions_for_resolve"
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
          The stderr should include "bravo/notation/module.md"
          The stderr should include "--test-scope"
          The output should equal ""
        End
      End

      Describe "When: call resolve_test_scope with the same scope given explicitly"
        It "[Error] T-CLI-RTS-07: Should: exit with status 1 and report the conflict, the owner module.md and the --test-scope hint"
          When call resolve_test_scope "alpha/normalize" "NOR"
          The status should equal 1
          The stderr should include "conflict"
          The stderr should include "bravo/notation/module.md"
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
    End
  End

  # --------------------------------------------------------------------------
  # create_module_meta / CLI wiring
  # --------------------------------------------------------------------------

  Describe "Given: a module path and no explicit test scope"
    Before "setup_deckrd_tmpdir"
    After "teardown_deckrd_tmpdir"

    Describe "When: run module.sh with the module path"
      It "[Normal] T-CLI-MOD-14: Should: exit with status 0 and write module.md declaring the derived test_scope"
        When run bash "$SCRIPT" myns/mymod
        The status should equal 0
        The output should include "module.md"
        The contents of file "${DECKRD_DOCS_DIR}/myns/mymod/module.md" should include "title: mymod"
        The contents of file "${DECKRD_DOCS_DIR}/myns/mymod/module.md" should include "test_scope: MYM"
        The contents of file "${DECKRD_LOCAL_DATA}/session.json" should include '"test_scope": "MYM"'
      End
    End
  End

  Describe "Given: a module path and an explicit test scope"
    Before "setup_deckrd_tmpdir"
    After "teardown_deckrd_tmpdir"

    Describe "When: run module.sh with --test-scope"
      It "[Normal] T-CLI-MOD-15: Should: exit with status 0 and write module.md declaring the explicit test_scope"
        When run bash "$SCRIPT" myns/mymod --test-scope XY
        The status should equal 0
        The output should include "module.md"
        The contents of file "${DECKRD_DOCS_DIR}/myns/mymod/module.md" should include "test_scope: XY"
      End
    End
  End

  Describe "Given: another module already declares the requested test scope"
    # shellcheck disable=SC2329
    setup_conflicting_declaration() {
      setup_deckrd_tmpdir
      mkdir -p "${DECKRD_DOCS_DIR}/otherns/othermod"
      printf '%s\n' "---" "test_scope: XY" "---" >"${DECKRD_DOCS_DIR}/otherns/othermod/module.md"
    }
    Before "setup_conflicting_declaration"
    After "teardown_deckrd_tmpdir"

    Describe "When: run module.sh with the taken scope via --test-scope"
      It "[Error] T-CLI-MOD-16: Should: exit with status 1, report the conflicting module.md and write no module.md"
        When run bash "$SCRIPT" myns/mymod --test-scope XY
        The status should equal 1
        The output should include "Initializing module"
        The stderr should include "conflict"
        The stderr should include "otherns/othermod/module.md"
        The path "${DECKRD_DOCS_DIR}/myns/mymod/module.md" should not be exist
      End
    End
  End

  Describe "Given: an existing module.md declaring a test scope"
    # shellcheck disable=SC2329
    setup_existing_module_meta() {
      setup_deckrd_tmpdir
      mkdir -p "${DECKRD_DOCS_DIR}/myns/mymod"
      printf '%s\n' "---" "title: mymod" "test_scope: ZZ" "---" >"${DECKRD_DOCS_DIR}/myns/mymod/module.md"
    }
    Before "setup_existing_module_meta"
    After "teardown_deckrd_tmpdir"

    Describe "When: re-initialize the module with --force"
      It "[Edge] T-CLI-MOD-17: Should: exit with status 0 and keep the test_scope already declared in module.md"
        When run bash "$SCRIPT" myns/mymod --force
        The status should equal 0
        The output should include "module.md"
        The contents of file "${DECKRD_DOCS_DIR}/myns/mymod/module.md" should include "test_scope: ZZ"
      End
    End
  End

  Describe "Given: --test-scope given without a value"
    Before "setup_deckrd_tmpdir"
    After "teardown_deckrd_tmpdir"

    Describe "When: run module.sh with a trailing --test-scope"
      It "[Error] T-CLI-MOD-18: Should: exit with status 1 and report that --test-scope requires a value"
        When run bash "$SCRIPT" myns/mymod --test-scope
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
      bash "$SCRIPT" myns/mymod --test-scope XY >/dev/null 2>&1
    }
    Before "setup_module_with_explicit_scope"
    After "teardown_deckrd_tmpdir"

    Describe "When: re-initialize the module with --force and no --test-scope"
      It "[Normal] T-CLI-MOD-19: Should: keep the declared scope in both module.md and session.json"
        When run bash "$SCRIPT" myns/mymod --force
        The status should equal 0
        The output should include "module.md"
        The contents of file "${DECKRD_DOCS_DIR}/myns/mymod/module.md" should include "test_scope: XY"
        The contents of file "${DECKRD_LOCAL_DATA}/session.json" should include '"test_scope": "XY"'
        The contents of file "${DECKRD_LOCAL_DATA}/session.json" should not include '"test_scope": "MYM"'
      End
    End
  End

  Describe "Given: a third module already declares the scope derived from the module name"
    # shellcheck disable=SC2329
    setup_derived_scope_taken_by_third_module() {
      setup_deckrd_tmpdir_with_project
      mkdir -p "${DECKRD_DOCS_DIR}/myns/mymod" "${DECKRD_DOCS_DIR}/thirdns/thirdmod"
      printf '%s\n' "---" "title: mymod" "test_scope: XY" "---" >"${DECKRD_DOCS_DIR}/myns/mymod/module.md"
      printf '%s\n' "---" "title: thirdmod" "test_scope: MYM" "---" >"${DECKRD_DOCS_DIR}/thirdns/thirdmod/module.md"
    }
    Before "setup_derived_scope_taken_by_third_module"
    After "teardown_deckrd_tmpdir"

    Describe "When: re-initialize the module with --force and no --test-scope"
      It "[Edge] T-CLI-MOD-20: Should: exit with status 0 because the declared scope is used instead of the derived one"
        When run bash "$SCRIPT" myns/mymod --force
        The status should equal 0
        The output should include "module.md"
        The stderr should not include "conflict"
        The contents of file "${DECKRD_LOCAL_DATA}/session.json" should include '"test_scope": "XY"'
      End
    End
  End
End
