#!/usr/bin/env bash
# skills/deckrd/skills/deckrd/scripts/__tests__/unit/init-parse-args.unit.spec.sh
# @(#) : BDD unit tests for init.sh - main() argument parsing (args.lib.sh)
#
# Copyright (c) 2026- atsushifx <https://github.com/atsushifx>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

# OPTIONS / OPTIONS_SET are declared by args.lib.sh (args_init); shellcheck
# cannot see that declaration.
# shellcheck disable=SC1090,SC2154

# ============================================================================
# Test infrastructure
# ============================================================================

_RUNTIME_BOOTSTRAP="${SHELLSPEC_PROJECT_ROOT}/skills/deckrd/skills/deckrd/scripts/libs/bootstrap.lib.sh"
. "$_RUNTIME_BOOTSTRAP" --no-finalize
unset _RUNTIME_BOOTSTRAP

Include "${SHELLSPEC_SPECFILE%/*}/../spec_helper.sh"

# ============================================================================
# Target
# ============================================================================

SCRIPT="${DECKRD_SCRIPTS_DIR}/init.sh"

# ============================================================================
# Internal helpers
# ============================================================================

##
# @description Source init.sh with the environment validators stubbed out and
#   replace _run_init_steps with a dumper of the parse result, so `main` runs the
#   real declarations and parse_args without touching the file system.
# @stdout (from main) one `key=value` line per dumped item, in this order:
#   1 project, 2 project_type, 3 prog, 4 lang, 5 ai_model, 6 force,
#   7 set_prog, 8 set_lang, 9 set_force, 10 show_help,
#   11 language (`set` when the legacy key OPTIONS[language] exists)
_load_script_with_dumper() {
  # shellcheck disable=SC2329
  validate_env() { return 0; }
  # shellcheck disable=SC2329
  validate_ai_model() { return 0; }
  . "$SCRIPT"

  # shellcheck disable=SC2329
  _run_init_steps() {
    local k
    for k in project project_type prog lang ai_model force; do
      printf '%s=%s\n' "$k" "${OPTIONS[$k]}"
    done
    printf 'set_prog=%s\nset_lang=%s\nset_force=%s\n' \
      "${OPTIONS_SET[prog]:-}" "${OPTIONS_SET[lang]:-}" "${OPTIONS_SET[force]:-}"
    printf 'show_help=%s\nlanguage=%s\n' "${OPTIONS[SHOW_HELP]:-}" "${OPTIONS[language]+set}"
  }
}

##
# @description Expected dump for `main myapp webapp` (every option at its default)
# @stdout The dump lines
_default_dump() {
  printf '%s\n' \
    project=myapp project_type=webapp prog=typescript lang=system \
    ai_model=sonnet force=false set_prog= set_lang= set_force= show_help=false language=
}

##
# @description Run main with options, then again without any, in the same shell
# @stdout The dump of the second main only
_main_with_options_then_defaults() {
  main myapp webapp --prog go --lang ja --force >/dev/null
  main myapp webapp
}

# ============================================================================
# init.sh: main argument parsing
# ============================================================================

Describe "T-CLI-PA: init.sh: main argument parsing"
  Before "_load_script_with_dumper"

  Describe "When: 正常系"
    It "[Normal] T-CLI-PA-01: main myapp webapp -> positionals set, every option at its default, nothing marked"
      When run main myapp webapp
      The status should equal 0
      The stdout should equal "$(_default_dump)"
    End

    It "[Normal] T-CLI-PA-24: --prog go -> prog=go and marked as given"
      When run main myapp webapp --prog go
      The status should equal 0
      The line 3 of stdout should equal "prog=go"
      The line 7 of stdout should equal "set_prog=true"
    End

    It "[Normal] T-CLI-PA-03: --language python -> prog=python, marked as given, no OPTIONS[language] key"
      When run main myapp webapp --language python
      The status should equal 0
      The line 3 of stdout should equal "prog=python"
      The line 7 of stdout should equal "set_prog=true"
      The line 11 of stdout should equal "language="
    End

    It "[Normal] T-CLI-PA-25: --prog=go (inline form) -> prog=go and marked as given"
      When run main myapp webapp --prog=go
      The status should equal 0
      The line 3 of stdout should equal "prog=go"
      The line 7 of stdout should equal "set_prog=true"
    End

    It "[Normal] T-CLI-PA-26: --prog bash -> normalized to prog=shell, still marked as given"
      When run main myapp webapp --prog bash
      The status should equal 0
      The line 3 of stdout should equal "prog=shell"
      The line 7 of stdout should equal "set_prog=true"
    End

    It "[Normal] T-CLI-PA-04: --lang ja -> lang=ja marked as given, prog left at default and unmarked"
      When run main myapp webapp --lang ja
      The status should equal 0
      The line 3 of stdout should equal "prog=typescript"
      The line 4 of stdout should equal "lang=ja"
      The line 7 of stdout should equal "set_prog="
      The line 8 of stdout should equal "set_lang=true"
    End

    It "[Normal] T-CLI-PA-08: --ai-model claude-sonnet-4-5 -> ai_model=claude-sonnet-4-5"
      When run main myapp webapp --ai-model claude-sonnet-4-5
      The status should equal 0
      The line 5 of stdout should equal "ai_model=claude-sonnet-4-5"
    End

    It "[Normal] T-CLI-PA-18: --force -> force=true marked as given, positionals intact"
      When run main myapp webapp --force
      The status should equal 0
      The line 1 of stdout should equal "project=myapp"
      The line 6 of stdout should equal "force=true"
      The line 9 of stdout should equal "set_force=true"
    End

    It "[Normal] T-CLI-PA-13: -h -> exit 0 with Usage on stderr, init steps not run"
      When run main -h
      The status should equal 0
      The stderr should include "Usage: init.sh"
      The stdout should equal ""
    End

    It "[Normal] T-CLI-PA-38: main with options, then main without -> second run back to defaults, nothing marked"
      When run _main_with_options_then_defaults
      The status should equal 0
      The stdout should equal "$(_default_dump)"
    End
  End

  Describe "When: 異常系"
    It "[Error] T-CLI-PA-10: --unknown -> exit 1, library error reported, Usage shown"
      When run main myapp webapp --unknown
      The status should equal 1
      The stderr should include "Error: Unknown option: --unknown"
      The stderr should include "Usage: init.sh"
    End

    It "[Error] T-CLI-PA-39: third positional extra -> exit 1, Unexpected argument, no Usage"
      When run main myapp webapp extra
      The status should equal 1
      The stderr should include "Error: Unexpected argument: extra"
      The stderr should not include "Usage:"
    End

    It "[Error] T-CLI-PA-29: --prog without a value -> exit 1, requires a value, no Usage"
      When run main myapp webapp --prog
      The status should equal 1
      The stderr should include "Error: --prog requires a value"
      The stderr should not include "Usage:"
    End

    It "[Error] T-CLI-PA-20: --force=yes -> exit 1, flag does not take a value, no Usage"
      When run main myapp webapp --force=yes
      The status should equal 1
      The stderr should include "Error: --force does not take a value"
      The stderr should not include "Usage:"
    End
  End

  Describe "When: エッジケース"
    It "[Edge] T-CLI-PA-33: --lang bash -> lang=bash kept as is (bash to shell applies to prog only)"
      When run main myapp webapp --lang bash
      The status should equal 0
      The line 3 of stdout should equal "prog=typescript"
      The line 4 of stdout should equal "lang=bash"
    End

    It "[Edge] T-CLI-PA-31: --lang= (empty inline value) -> exit 1, requires a value"
      When run main myapp webapp --lang=
      The status should equal 1
      The stderr should include "Error: --lang requires a value"
    End

    It "[Edge] T-CLI-PA-21: --force between positionals -> force=true, positionals in order"
      When run main myapp --force webapp
      The status should equal 0
      The line 1 of stdout should equal "project=myapp"
      The line 2 of stdout should equal "project_type=webapp"
      The line 6 of stdout should equal "force=true"
    End

    It "[Edge] T-CLI-PA-40: --unknown=x -> exit 1, error names the option without the value, Usage shown"
      When run main myapp webapp --unknown=x
      The status should equal 1
      The line 1 of stderr should equal "Error: Unknown option: --unknown"
      The stderr should include "Usage: init.sh"
    End
  End

End

# ============================================================================
# init.sh: structure after the args.lib.sh migration
# ============================================================================

Describe "T-CLI-STR: init.sh: structure after the args.lib.sh migration"
  Before "_load_script_with_dumper"

  Describe "When: 正常系"
    It "[Normal] T-CLI-STR-01: after sourcing init.sh -> library API defined and parse_args is the library's"
      When call declare -F args_init args_value args_flag args_positional parse_args
      The status should equal 0
      The lines of stdout should equal 5
      Assert eval '[[ "$(declare -f parse_args)" == *_args_option* ]]'
    End
  End

  Describe "When: 異常系"
    It "[Error] T-CLI-STR-02: after sourcing init.sh -> the removed local parser helpers are undefined"
      When call declare -F _require_option_value _set_prog_option _set_lang_option _normalize_prog_option
      The status should equal 1
      The stdout should equal ""
    End
  End

  Describe "When: エッジケース"
    It "[Edge] T-CLI-STR-03: unset OPTIONS; init_vars -> OPTIONS stays undeclared (args_init owns it)"
      _init_vars_without_options() {
        unset OPTIONS
        init_vars
        declare -p OPTIONS
      }
      When call _init_vars_without_options
      The status should equal 1
      The stderr should include "OPTIONS"
    End
  End
End
