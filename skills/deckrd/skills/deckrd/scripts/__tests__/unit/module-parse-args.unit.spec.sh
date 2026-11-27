#!/usr/bin/env bash
# skills/deckrd/skills/deckrd/scripts/__tests__/unit/module-parse-args.unit.spec.sh
# @(#) : BDD unit tests for module.sh - init_vars / main() argument parsing (args.lib.sh)
#
# Copyright (c) 2026- atsushifx <https://github.com/atsushifx>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

# OPTIONS / OPTIONS_SET are declared by args.lib.sh (args_init); shellcheck
# cannot see that declaration.
# shellcheck disable=SC1090,SC2154

_RUNTIME_BOOTSTRAP="${SHELLSPEC_PROJECT_ROOT}/skills/deckrd/skills/deckrd/scripts/libs/bootstrap.lib.sh"
. "$_RUNTIME_BOOTSTRAP" --no-finalize
unset _RUNTIME_BOOTSTRAP

Include "${SHELLSPEC_SPECFILE%/*}/../spec_helper.sh"

SCRIPT="${DECKRD_SCRIPTS_DIR}/module.sh"

# ============================================================================
# Internal helpers
# ============================================================================

##
# @description Source module.sh with validate_env mocked to succeed
# @description Loads the functions only; the top-level execution block is skipped when sourced
load_script_with_mocks() {
  # shellcheck disable=SC2329
  validate_env() { return 0; }
  export -f validate_env

  # shellcheck disable=SC1090
  . "$SCRIPT"
}

##
# @description Source module.sh with validate_env stubbed and replace the steps
#   after argument parsing, so `main` runs the real declarations and the library
#   parse_args without touching the file system.
# @stdout (from main) one `key=value` line per dumped item, in this order:
#   1 subcommand, 2 module_path, 3 force, 4 test_scope, 5 set_module_path,
#   6 set_force, 7 set_test_scope, 8 show_help,
#   9 help (`set` when the legacy key OPTIONS[help] exists)
_load_script_with_dumper() {
  load_script_with_mocks

  # shellcheck disable=SC2329
  validate_and_normalize_with_fallback() { printf '%s\n' "$1"; }
  # shellcheck disable=SC2329
  create_module_dirs() {
    printf 'subcommand=%s\n' "${SUBCOMMAND:-}"
    local k
    for k in module_path force test_scope; do
      printf '%s=%s\n' "$k" "${OPTIONS[$k]:-}"
    done
    printf 'set_module_path=%s\nset_force=%s\nset_test_scope=%s\n' \
      "${OPTIONS_SET[module_path]:-}" "${OPTIONS_SET[force]:-}" "${OPTIONS_SET[test_scope]:-}"
    printf 'show_help=%s\nhelp=%s\n' "${OPTIONS[SHOW_HELP]:-}" "${OPTIONS[help]+set}"
  }
  # shellcheck disable=SC2329
  read_declared_scope() { :; }
  # shellcheck disable=SC2329
  resolve_test_scope() { echo "XX"; }
  # shellcheck disable=SC2329
  create_module_meta() { :; }
  # shellcheck disable=SC2329
  update_session() { :; }
}

##
# @description Expected dump for `main my-ns/my-mod` (every option at its default)
# @stdout The dump lines
_default_dump() {
  printf '%s\n' \
    subcommand= module_path=my-ns/my-mod force=false test_scope= \
    set_module_path=true set_force= set_test_scope= show_help=false help=
}

##
# @description Run main with every option, then again with defaults, in the same shell
# @stdout The dump of the second main only
_main_with_options_then_defaults() {
  main create my-ns/my-mod --force --test-scope XY >/dev/null
  main my-ns/my-mod
}

# ============================================================================
# module.sh: init_vars
# ============================================================================

##
# init_vars sets the script configuration variables.
# SESSION_FILE honors a non-empty preset value (mock / override); the other
# variables are reset to their defaults on every call. OPTIONS / OPTIONS_SET
# are not declared here: args_init (libs/args.lib.sh) owns them.
Describe "T-CLI-MIV: module.sh: init_vars"
  Before "load_script_with_mocks"

  Describe "Given: SESSION_FILE is unset"
    It "[Normal] T-CLI-MIV-01: Should: set default configuration variables and leave OPTIONS undeclared"
      unset OPTIONS SESSION_FILE
      When call init_vars
      The status should equal 0
      The value "$SESSION_FILE" should equal "${DECKRD_LOCAL_DATA}/session.json"
      The value "${SUBDIRS[*]}" should equal "requirements specifications implementation tasks workspaces"
      The value "$MODULE_META_SUBPATH" should equal "workspaces/module/module.md"
      The value "$SUBCOMMAND" should equal ""
      The value "$(declare -p OPTIONS >/dev/null 2>&1 && echo declared || echo undeclared)" should equal "undeclared"
    End
  End

  Describe "Given: SESSION_FILE is an empty string"
    It "[Error] T-CLI-MIV-02: Should: fall back to the default SESSION_FILE"
      SESSION_FILE=""
      When call init_vars
      The value "$SESSION_FILE" should equal "${DECKRD_LOCAL_DATA}/session.json"
    End
  End

  Describe "Given: SESSION_FILE is preset to a custom path"
    It "[Edge] T-CLI-MIV-03: Should: keep the preset SESSION_FILE"
      SESSION_FILE="/tmp/custom/session.json"
      When call init_vars
      The value "$SESSION_FILE" should equal "/tmp/custom/session.json"
    End
  End

  Describe "Given: SUBCOMMAND is left over from a previous run"
    It "[Edge] T-CLI-MIV-04: Should: reset SUBCOMMAND to empty"
      SUBCOMMAND="create"
      When call init_vars
      The value "$SUBCOMMAND" should equal ""
    End
  End
End

# ============================================================================
# module.sh: main argument parsing
# ============================================================================

##
# main declares the options with args.lib.sh and parses them with the library
# parse_args. Errors print "Error: ${ARGS_ERROR}" on stderr plus usage on stdout
# and exit 1; --help prints usage and exits 0.
Describe "T-CLI-MPA: module.sh: main argument parsing"
  Before "_load_script_with_dumper"

  Describe "When: 正常系"
    It "[Normal] T-CLI-MPA-02: main my-ns/my-mod -> module path set, every option at its default"
      When run main my-ns/my-mod
      The status should equal 0
      The stdout should equal "$(_default_dump)"
    End

    It "[Normal] T-CLI-MPA-03: main create my-ns/my-mod -> SUBCOMMAND=create, create shifted off"
      When run main create my-ns/my-mod
      The status should equal 0
      The line 1 of stdout should equal "subcommand=create"
      The line 2 of stdout should equal "module_path=my-ns/my-mod"
    End

    It "[Normal] T-CLI-MPA-04: --force -> force=true and marked as given"
      When run main my-ns/my-mod --force
      The status should equal 0
      The line 3 of stdout should equal "force=true"
      The line 6 of stdout should equal "set_force=true"
    End

    It "[Normal] T-CLI-MPA-05: --test-scope XY -> test_scope=XY and marked as given"
      When run main my-ns/my-mod --test-scope XY
      The status should equal 0
      The line 4 of stdout should equal "test_scope=XY"
      The line 7 of stdout should equal "set_test_scope=true"
    End

    It "[Normal] T-CLI-MPA-15: --test-scope=XY (inline form) -> test_scope=XY and marked as given"
      When run main my-ns/my-mod --test-scope=XY
      The status should equal 0
      The line 4 of stdout should equal "test_scope=XY"
      The line 7 of stdout should equal "set_test_scope=true"
    End

    It "[Normal] T-CLI-MPA-06: --help -> exit 0 with Usage on stdout, later steps not run"
      When run main --help
      The status should equal 0
      The stdout should include "Usage: module.sh"
      The stdout should not include "module_path="
    End

    It "[Normal] T-CLI-MPA-21: --help -> Usage lists <namespace>/<module> with --force and --test-scope"
      When run main --help
      The status should equal 0
      The stdout should include "module.sh <namespace>/<module> [--force] [--test-scope <SCOPE>]"
    End

    It "[Normal] T-CLI-MPA-22: --help -> Usage lists <module> with --force and --test-scope"
      When run main --help
      The status should equal 0
      The stdout should include "module.sh <module> [--force] [--test-scope <SCOPE>]"
    End

    It "[Normal] T-CLI-MPA-23: --help -> Usage lists create <namespace>/<module> with --force and --test-scope"
      When run main --help
      The status should equal 0
      The stdout should include "module.sh create <namespace>/<module> [--force] [--test-scope <SCOPE>]"
    End

    It "[Normal] T-CLI-MPA-24: --help -> Usage lists create <module> with --force and --test-scope"
      When run main --help
      The status should equal 0
      The stdout should include "module.sh create <module> [--force] [--test-scope <SCOPE>]"
    End

    It "[Normal] T-CLI-MPA-25: --help -> Options documents the inline form --test-scope=<SCOPE>"
      When run main --help
      The status should equal 0
      The stdout should include "--test-scope=<SCOPE>"
    End

    It "[Normal] T-CLI-MPA-20: main my-ns/my-mod -> help reported via SHOW_HELP, legacy key OPTIONS[help] absent"
      When run main my-ns/my-mod
      The status should equal 0
      The line 8 of stdout should equal "show_help=false"
      The line 9 of stdout should equal "help="
    End

    It "[Normal] T-CLI-MPA-28: module.sh source -> the shared lib functions are defined"
      When call declare -F fm_read_scalar module_decl_file_of
      The status should equal 0
      The stdout should include "fm_read_scalar"
      The stdout should include "module_decl_file_of"
    End
  End

  Describe "When: 異常系"
    It "[Error] T-CLI-MPA-08: --bogus -> exit 1, library error on stderr, Usage on stdout"
      When run main my-ns/my-mod --bogus
      The status should equal 1
      The stderr should include "Error: Unknown option: --bogus"
      The stdout should include "Usage:"
    End

    It "[Error] T-CLI-MPA-26: --bogus -> exit 1, Usage on stdout lists <module> with --force and --test-scope"
      When run main my-ns/my-mod --bogus
      The status should equal 1
      The stdout should include "module.sh <module> [--force] [--test-scope <SCOPE>]"
      The stderr should be present
    End

    It "[Error] T-CLI-MPA-09: a/b c/d -> exit 1, Unexpected argument for the second path, Usage on stdout"
      When run main a/b c/d
      The status should equal 1
      The stderr should include "Error: Unexpected argument: c/d"
      The stdout should include "Usage:"
    End

    It "[Error] T-CLI-MPA-07: trailing --test-scope -> exit 1, requires a value, Usage on stdout"
      When run main my-ns/my-mod --test-scope
      The status should equal 1
      The stderr should include "Error: --test-scope requires a value"
      The stdout should include "Usage:"
    End

    It "[Error] T-CLI-MPA-16: --force=x -> exit 1, flag does not take a value, Usage on stdout"
      When run main my-ns/my-mod --force=x
      The status should equal 1
      The stderr should include "Error: --force does not take a value"
      The stdout should include "Usage:"
    End

    It "[Error] T-CLI-MPA-01: no arguments -> exit 1, module path required, Usage on stdout, later steps not run"
      When run main
      The status should equal 1
      The stderr should include "Error: <namespace>/<module> is required"
      The stdout should include "Usage:"
      The stdout should not include "module_path="
    End

    It "[Error] T-CLI-MPA-18: module.sh source -> no local parse_args definition (the library's is used)"
      When call grep -c '^parse_args()' "$SCRIPT"
      The status should equal 1
      The stdout should equal 0
    End

    It "[Error] T-CLI-MPA-19: module.sh source -> no PARSE_ARGS_ERROR / OPTIONS[help] references left"
      When call grep -cE 'PARSE_ARGS_ERROR|OPTIONS\[help\]' "$SCRIPT"
      The status should equal 1
      The stdout should equal 0
    End

    It "[Error] T-CLI-MPA-29: module.sh source -> no local frontmatter reader (the library's is used)"
      When call grep -c '_read_frontmatter_scope' "$SCRIPT"
      The status should equal 1
      The stdout should equal 0
    End

    It "[Error] T-CLI-MPA-30: module.sh source -> no literal module.md layout (the library's is used)"
      When call grep -c 'MODULE_META_SUBPATH="workspaces' "$SCRIPT"
      The status should equal 1
      The stdout should equal 0
    End
  End

  Describe "When: エッジケース"
    It "[Edge] T-CLI-MPA-10: --test-scope \"\" (empty separate value) -> exit 1, requires a value, Usage on stdout"
      When run main my-ns/my-mod --test-scope ""
      The status should equal 1
      The stderr should include "Error: --test-scope requires a value"
      The stdout should include "Usage:"
    End

    It "[Edge] T-CLI-MPA-17: --test-scope= (empty inline value) -> exit 1, requires a value, Usage on stdout"
      When run main my-ns/my-mod --test-scope=
      The status should equal 1
      The stderr should include "Error: --test-scope requires a value"
      The stdout should include "Usage:"
    End

    It "[Edge] T-CLI-MPA-11: create alone -> create shifted off, exit 1, module path required"
      When run main create
      The status should equal 1
      The stderr should include "Error: <namespace>/<module> is required"
      The stdout should include "Usage:"
    End

    It "[Edge] T-CLI-MPA-13: my-ns/my-mod create -> non-leading create is a positional, exit 1, Unexpected argument"
      When run main my-ns/my-mod create
      The status should equal 1
      The stderr should include "Error: Unexpected argument: create"
      The stdout should include "Usage:"
    End

    It "[Edge] T-CLI-MPA-14: main with every option, then main without -> second run back to defaults, nothing left marked"
      When run _main_with_options_then_defaults
      The status should equal 0
      The stdout should equal "$(_default_dump)"
    End

    It "[Edge] T-CLI-MPA-12: --help --bogus -> help stops parsing first, exit 0, no error"
      When run main --help --bogus
      The status should equal 0
      The stdout should include "Usage: module.sh"
      The stderr should not include "Error:"
    End

    It "[Edge] T-CLI-MPA-27: --help -> Usage line 1 matches exactly, nothing missing or trailing"
      When run main --help
      The status should equal 0
      The line 1 of stdout should equal "Usage: module.sh <namespace>/<module> [--force] [--test-scope <SCOPE>]"
    End
  End
End
