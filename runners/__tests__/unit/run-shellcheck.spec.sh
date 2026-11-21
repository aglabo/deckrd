#!/usr/bin/env bash
# runners/__tests__/unit/run-shellcheck.spec.sh
# @(#) : BDD unit tests for run-shellcheck.sh
#
# Copyright (c) 2026- atsushifx <https://github.com/atsushifx>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT
# shellcheck shell=bash

# --- Subject under test ---
# run-shellcheck.sh runs `cd` at file scope, so the cwd is the repository root after it is included.
# This spec uses no relative paths: fixtures and targets are all passed as absolute paths
Include "${SHELLSPEC_PROJECT_ROOT}/runners/run-shellcheck.sh"

# --- Internal helpers ---

# Constants

# A normal file in a directory unrelated to the excluded names; it must be listed (T-RUN-FSF-01)
_NORMAL_FILE='src/a.sh'

# Files under directories named in the exclude list; they must not be listed (input table of T-RUN-FSF-02).
# In word order they guard the existing behaviour: .tools / top-level node_modules / nested node_modules
%const _FSF_EXCLUDED_FILES: .tools/t.sh node_modules/p/y.sh pkg/node_modules/p/z.sh

# A file in a directory whose name merely contains an excluded name without matching it; it must be listed (T-RUN-FSF-03)
_LOOKALIKE_FILE='my_node_modules_backup/w.sh'

# A directory named exactly like an excluded name, used as the walk start point (T-RUN-FSF-04)
_EXCLUDED_START_DIR='.tools'

# A file directly under the start point _EXCLUDED_START_DIR; it must be listed (T-RUN-FSF-04)
_START_DIR_FILE="${_EXCLUDED_START_DIR}/t.sh"

# A file under an excluded directory below the start point _EXCLUDED_START_DIR; it must not be listed (T-RUN-FSF-05)
_START_DIR_NESTED_FILE="${_EXCLUDED_START_DIR}/node_modules/p/y.sh"

# A file under node_modules for the main tests (tree of T-RUN-MSC-01, target of T-RUN-MSC-02)
_NODE_MODULES_FILE='node_modules/p/y.sh'

# Fixed rc file handed to main via SHELLCHECKRC, so config resolution is skipped and the expectation is deterministic (T-RUN-MSC-01/02)
_RCFILE='/fixture/shellcheckrc'

# Functions

#
# @description Build a tree of empty .sh files in a temporary directory.
#              The real repository tree is never touched
# @arg $@ string One or more paths relative to the tree root. Parent directories are created too
# @return 0 when the tree is ready
# @sideeffect Sets _TREE_ROOT to the absolute path of the temporary root
#
_setup_shell_tree() {
  _TREE_ROOT="$(mktemp -d)"
  local rel
  for rel in "$@"; do
    mkdir -p "${_TREE_ROOT}/$(dirname "$rel")"
    touch "${_TREE_ROOT}/${rel}"
  done
}

#
# @description Build the tree shared by every T-RUN-FSF case.
#              Cases that change the walk start point use the same tree,
#              and each case checks only one path of it
# @arg none
# @return 0 when the tree is ready
# @sideeffect Sets _TREE_ROOT (via _setup_shell_tree)
#
_setup_fsf_tree() {
  # shellcheck disable=SC2086 # word-split the %const word list into one file each
  _setup_shell_tree "$_NORMAL_FILE" $_FSF_EXCLUDED_FILES "$_LOOKALIKE_FILE" \
    "$_START_DIR_FILE" "$_START_DIR_NESTED_FILE"
}

#
# @description Delete the temporary tree made by _setup_shell_tree()
# @arg none
# @return 0 always
# @sideeffect Deletes _TREE_ROOT (only when it is under /tmp) and unsets it
#
_teardown_shell_tree() {
  [[ -n "${_TREE_ROOT:-}" && "$_TREE_ROOT" == /tmp/* ]] && rm -rf "$_TREE_ROOT"
  unset _TREE_ROOT
}

#
# @description Turn the NUL-terminated output of find_shell_files into one path per line in a stable order.
#              Called under pipefail, so a find_shell_files failure shows up in the exit status
# @arg $1 string Directory to walk (absolute path)
# @stdout Paths of the files found (one per line, sorted)
# @return 0 when find_shell_files succeeded
#
_list_shell_files() {
  find_shell_files "$1" | tr '\0' '\n' | sort
}

#
# @description Replace the real shellcheck with a shell function mock and pin SHELLCHECKRC.
#              The mock is inherited by main's subshell, so main's stdout
#              is exactly the argument list the mock received
# @arg none
# @stdout (when the mock is called) All received arguments joined as [arg], without a newline
# @return 0 always (the mock also returns 0)
# @sideeffect Defines the shell function shellcheck and sets SHELLCHECKRC
#
_setup_shellcheck_mock() {
  # shellcheck disable=SC2329 # called indirectly from main()
  shellcheck() {
    printf '[%s]' "$@"
  }
  SHELLCHECKRC="$_RCFILE"
}

#
# @description Remove the mock defined by _setup_shellcheck_mock()
# @arg none
# @return 0 always
# @sideeffect Unsets the shell function shellcheck and SHELLCHECKRC
#
_teardown_shellcheck_mock() {
  unset -f shellcheck
  unset SHELLCHECKRC
}

# --- Tests ---

#
# run-shellcheck.sh: runner that collects the .sh files and passes them to shellcheck
#
Describe 'run-shellcheck.sh'
  #
  # find_shell_files: list the .sh files under a directory, NUL-terminated.
  # A directory whose name matches the exclude list is not walked at any depth below the start point.
  # The start point itself is walked even when its name matches
  #
  Describe 'T-RUN-FSF: find_shell_files()'
    Before '_setup_fsf_tree'
    After '_teardown_shell_tree'

    Describe 'When: normal cases'
      It 'Then: [Normal] T-RUN-FSF-01: lists a .sh under a directory with no excluded name'
        When call _list_shell_files "$_TREE_ROOT"
        The output should include "${_TREE_ROOT}/${_NORMAL_FILE}"
        The status should be success
      End

      # shellcheck disable=SC2086 # word-split the %const table into one case each
      Parameters:value $_FSF_EXCLUDED_FILES

      It "Then: [Normal] T-RUN-FSF-02: does not list $1 under an excluded directory"
        When call _list_shell_files "$_TREE_ROOT"
        The output should not include "${_TREE_ROOT}/$1"
        The status should be success
      End
    End

    # Exclusion boundaries. Exclusion does not apply to names that merely resemble an excluded name, nor to the walk start point itself
    Describe 'When: edge cases'
      # Control case. Pruning on a partial match of an excluded name turns this RED
      It 'Then: [Edge] T-RUN-FSF-03: lists files under a directory whose name merely contains an excluded name'
        When call _list_shell_files "$_TREE_ROOT"
        The output should include "${_TREE_ROOT}/${_LOOKALIKE_FILE}"
        The status should be success
      End

      # If -name also applies to the start point, the whole start point is pruned and this turns RED
      It 'Then: [Edge] T-RUN-FSF-04: lists a .sh directly under the start point even when it is named like an excluded directory'
        When call _list_shell_files "${_TREE_ROOT}/${_EXCLUDED_START_DIR}"
        The output should include "${_TREE_ROOT}/${_START_DIR_FILE}"
        The status should be success
      End

      # Dropping exclusion altogether when the start point has an excluded name turns this RED
      It 'Then: [Edge] T-RUN-FSF-05: does not list excluded directories under the start point even when it is named like an excluded directory'
        When call _list_shell_files "${_TREE_ROOT}/${_EXCLUDED_START_DIR}"
        The output should not include "${_TREE_ROOT}/${_START_DIR_NESTED_FILE}"
        The status should be success
      End
    End
  End

  #
  # main: expand the targets into a file list for shellcheck and run it exactly once.
  # Directory targets are listed with find_shell_files; file targets are passed as they are.
  # The real shellcheck is replaced by a mock and the received arguments are observed on stdout
  #
  Describe 'T-RUN-MSC: main()'
    Before '_setup_shellcheck_mock'
    After '_teardown_shellcheck_mock' '_teardown_shell_tree'

    Describe 'When: normal cases'
      It 'Then: [Normal] T-RUN-MSC-01: for a directory target, passes only the files outside node_modules'
        _setup_shell_tree "$_NORMAL_FILE" "$_NODE_MODULES_FILE"
        When call main "$_TREE_ROOT"
        The output should equal "[--rcfile=${_RCFILE}][${_TREE_ROOT}/${_NORMAL_FILE}]"
        The status should be success
      End
    End

    # The exclude list applies only to directory walks, not to explicitly given files
    Describe 'When: edge cases'
      It 'Then: [Edge] T-RUN-MSC-02: passes a file target as is even under node_modules'
        _setup_shell_tree "$_NODE_MODULES_FILE"
        When call main "${_TREE_ROOT}/${_NODE_MODULES_FILE}"
        The output should equal "[--rcfile=${_RCFILE}][${_TREE_ROOT}/${_NODE_MODULES_FILE}]"
        The status should be success
      End
    End
  End
End
