#!/usr/bin/env bash
# runners/__tests__/spec_helper.sh
# @(#) : shared test helper for runners tests
#
# Copyright (c) 2026- atsushifx <https://github.com/atsushifx>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT
# spec_helper.sh — shared test helper for runners/libs tests

#
# @description Build a deterministic tree of fake spec files mirroring the real
#              repository layout (`__tests__/<type>/`) for testing get_filelist().
#              The tree is built once per ShellSpec invocation and reused afterwards.
#              The memo is an on-disk completion marker rather than a shell variable,
#              because ShellSpec forks a subshell per example and a variable would
#              never reach the parent shell. The marker is stamped only after every
#              mkdir and touch has *succeeded*; a failing step aborts the build with a
#              non-zero return and leaves no marker, so the next caller rebuilds from
#              scratch instead of latching onto a half-built tree. A spec file running
#              in parallel (`.shellspec` sets `--jobs 4`) therefore can never mistake
#              an incomplete tree for a finished one. Two jobs racing while the marker
#              is still absent is harmless: mkdir -p and touch are idempotent, and each
#              job enumerates only after its own build completes.
#
#              Consumer contract: the fixture is a read-only tree shared by every
#              example of every spec file in the run. Once the marker exists it is
#              never rebuilt, so any write to it (adding, renaming or deleting a path)
#              is visible to all later examples. A consumer that needs to mutate a
#              tree must create its own directory instead of touching this one.
# @arg none   takes no arguments; the fixture root comes from the environment (below)
# @return 0 when the fixture is ready; 1 when the tree could not be built
#         (no completion marker is left behind in that case)
# @sideeffect Sets TEMP_DIR to the fixture root
#             (`${SHELLSPEC_TMPBASE:-${TMPDIR:-/tmp}}/deckrd-spec-fixture`)
# @sideeffect Creates that fixture root on disk, and the `.fixture-ready` marker
#             inside it, unless that marker is already present
# @sideeffect Saves the current SPEC_SEARCH_ROOT into ORIG_SPEC_SEARCH_ROOT and
#             repoints SPEC_SEARCH_ROOT at TEMP_DIR
#
setup_temp_specs() {
  local __root="${SHELLSPEC_TMPBASE:-${TMPDIR:-/tmp}}/deckrd-spec-fixture"
  # Marker name must not match `*.spec.sh`: get_filelist() globs the tree for specs
  local __ready="${__root}/.fixture-ready"

  # shellcheck disable=SC2034
  ORIG_SPEC_SEARCH_ROOT="${SPEC_SEARCH_ROOT:-}"
  TEMP_DIR="$__root"
  # shellcheck disable=SC2034
  SPEC_SEARCH_ROOT="$TEMP_DIR"

  # Rebuild until the completion marker exists. Testing the root with `-d` instead
  # would also accept a tree a parallel job is still filling in, yielding a
  # short spec list. `-f` is a builtin test, not a fork()
  if [[ ! -f "$__ready" ]]; then
    # Fake spec files mirroring the real layout (no e2e directory on purpose)
    local __spec __dir
    local -A __seen=()
    local -a __dirs=() __files=()
    local -a __specs=(
      "runners/__tests__/unit/args-normalize.spec.sh"
      "runners/__tests__/unit/kv-store.spec.sh"
      "runners/__tests__/unit/init.spec.sh"
      "runners/__tests__/integration/args-normalize.spec.sh"
      "runners/__tests__/system/runner.spec.sh"
      "runners/libs/__tests__/unit/get-filelist.spec.sh"
      "skills/deckrd/skills/deckrd/scripts/__tests__/unit/project.unit.spec.sh"
      "skills/deckrd/skills/deckrd/scripts/libs/__tests__/functional/kv-store.lib.functional.spec.sh"
      "skills/deckrd/skills/deckrd/scripts/subcommands/__tests__/unit/generate-doc.unit.spec.sh"
    )

    # Collect unique parent directories and full paths, then materialize the whole
    # tree with one mkdir and one touch (each fork() costs ~0.2s on Windows/MSYS2)
    for __spec in "${__specs[@]}"; do
      __dir="${__root}/${__spec%/*}"
      [[ -v __seen["$__dir"] ]] || {
        __seen["$__dir"]=1
        __dirs+=("$__dir")
      }
      __files+=("${__root}/${__spec}")
    done

    # Fail fast: a partially built tree must not be stamped as complete.
    # `||` and `return` are shell internals, so this costs no extra fork().
    # `set -e` is not an option here: ShellSpec does not enable errexit in Before hooks
    mkdir -p "${__dirs[@]}" || return 1
    touch "${__files[@]}" || return 1
    # Stamp completion last and only on success, so the marker always implies a
    # finished tree. A redirection, not a command: no fork()
    : >"$__ready" || return 1
  fi
}

#
# @description Restore the variables saved by setup_temp_specs(). The fixture tree
#              itself is deliberately left on disk so the next example reuses it;
#              it lives under SHELLSPEC_TMPBASE, which ShellSpec's runner cleanup()
#              removes wholesale when the run ends, so nothing leaks.
# @sideeffect Unsets TEMP_DIR
# @sideeffect Restores SPEC_SEARCH_ROOT from ORIG_SPEC_SEARCH_ROOT
#
teardown_temp_specs() {
  unset TEMP_DIR
  # shellcheck disable=SC2034
  SPEC_SEARCH_ROOT="${ORIG_SPEC_SEARCH_ROOT:-}"
}
