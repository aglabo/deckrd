#!/usr/bin/env bash
# src: ./skills/deckrd/skills/deckrd/scripts/libs/__tests__/unit/spec-helper.unit.spec.sh
# @(#) : ShellSpec unit tests for spec_helper.sh - setup_coder_tmpscript / setup_naming_cache
#
# Unit test design:
#   - The target is the test harness itself, so the only observable surface is its public
#     contract: the `_CODER_TMPSCRIPT` path and the traces left on the file system.
#     Internal variables (`_CODER_TMPROOT`, etc.) are never read.
#   - "Not a fixed path" and "Nothing left after teardown" are negative checks.
#     Keep the negation inside internal helper functions, not in ShellSpec conditions.
#   - Calling setup twice without teardown in between makes the test leak a parent directory.
#     Cases that call setup a second time always call teardown first.
#   - Verify exports from a child process. Bash keeps the export attribute across plain
#     reassignment, so reading the value in the same shell cannot tell whether it was exported.
#
# Copyright (c) 2026- atsushifx <https://github.com/atsushifx>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

# ============================================================================
# Target under test
# ============================================================================

Include ../spec_helper.sh

# ============================================================================
# Internal helpers
# ============================================================================

# Constants

# _CODER_PATH_SEGMENT - Path sequence that bdd-coder path detection depends on.
# setup_coder_tmpscript must keep it intact as a single segment
_CODER_PATH_SEGMENT='/plugins/bdd-coder/'

# _FIXED_PLUGINS_DIR - Parent of the fixed temp directory that must not be used.
# All jobs share it under `--jobs 4`, and it collides with other users on shared hosts
_FIXED_PLUGINS_DIR='/tmp/plugins'

# _FIXED_CODER_DIR - Fixed temp directory that must not be used
_FIXED_CODER_DIR="${_FIXED_PLUGINS_DIR}/bdd-coder"

# _INLINE_TMP_WRITE_COMMANDS - Commands that create the fixed temp directory by hand.
# The check regex is built at runtime by joining these with _FIXED_PLUGINS_DIR.
# Putting the joined string in the source would make this spec count itself as a violation
_INLINE_TMP_WRITE_COMMANDS=('mkdir -p' 'mktemp')

# _LIBS_SPEC_DIR - Static check target: the directory holding the libs module specs
_LIBS_SPEC_DIR="${SHELLSPEC_PROJECT_ROOT}/skills/deckrd/skills/deckrd/scripts/libs/__tests__"

# _SPEC_FILE_GLOB - Glob of spec files picked up by the static check.
# Shared by the violation counter and the scan counter. Writing it twice invites fixing
# only one copy, which defeats the purpose of the control
_SPEC_FILE_GLOB='*.spec.sh'

# _REAL_LOCAL_DATA_DIR - Real-repository DECKRD_LOCAL_DATA that bootstrap.lib.sh derives at runtime.
# Used by the edge case to recreate the pre-override initial state by hand
_REAL_LOCAL_DATA_DIR="${SHELLSPEC_PROJECT_ROOT}/.local/deckrd"

# Functions

# _coder_tmpscript_dir - Print the directory where setup_coder_tmpscript placed the temp script
#
# The location is reachable only through the public contract _CODER_TMPSCRIPT. Teardown
# unsets _CODER_TMPSCRIPT, so cases that call teardown must call this first.
# Fails immediately via `:?` when unset; taking dirname of an empty string is meaningless.
#
# @stdout Absolute path of the directory holding the temp script
# shellcheck disable=SC2329
_coder_tmpscript_dir() {
  dirname "${_CODER_TMPSCRIPT:?}"
}

# _tmpscript_keeps_coder_segment - Report whether the _CODER_TMPSCRIPT path
#     contains plugins/bdd-coder as a single segment
#
# Suffixed directory names (`bdd-coder-XXXXXX`, etc.) break the segment and do not
# match. The intent of T-LIB-BSRC / T-LIB-BSRCF is encoded in this path name.
#
# @return 0 if the path contains the segment, 1 otherwise
# shellcheck disable=SC2329
_tmpscript_keeps_coder_segment() {
  [[ "${_CODER_TMPSCRIPT:-}" == *"${_CODER_PATH_SEGMENT}"* ]]
}

# _tmpscript_outside_fixed_dir - Report whether _CODER_TMPSCRIPT lies outside the fixed directory
#
# @return 0 if the path is outside _FIXED_CODER_DIR, 1 if inside
# shellcheck disable=SC2329
_tmpscript_outside_fixed_dir() {
  [[ "${_CODER_TMPSCRIPT:-}" != "${_FIXED_CODER_DIR}"/* ]]
}

# _teardown_leaves_no_dir - Report whether teardown_coder_tmpscript leaves
#     none of the created directories behind
#
# Record the created paths before calling teardown. Teardown unsets _CODER_TMPSCRIPT,
# so afterwards there is no way to know what to check.
#
# Check all three levels. Setup creates the root from mktemp -d, `plugins` under it,
# and `bdd-coder` below that; if any one remains, one directory per example
# accumulates in /tmp. The root is two levels above `bdd-coder` and is reachable
# from the public contract _CODER_TMPSCRIPT. Internal variables are not read.
#
# @return 0 if none of the three created directories remains, 1 otherwise
# shellcheck disable=SC2329
_teardown_leaves_no_dir() {
  local coder_dir plugins_dir root_dir
  coder_dir="$(_coder_tmpscript_dir)"
  plugins_dir="$(dirname "$coder_dir")"
  root_dir="$(dirname "$plugins_dir")"

  teardown_coder_tmpscript

  [[ ! -d "$coder_dir" && ! -d "$plugins_dir" && ! -d "$root_dir" ]]
}

# _second_setup_uses_new_dir - Report whether a second setup after teardown
#     creates a directory different from the first
#
# The caller's Before already ran the first setup. Teardown runs before the second,
# so this helper never leaves a parent directory untracked.
#
# @return 0 if the two setups created different directories, 1 if they shared one
# shellcheck disable=SC2329
_second_setup_uses_new_dir() {
  local first_dir second_dir
  first_dir="$(_coder_tmpscript_dir)"

  teardown_coder_tmpscript
  setup_coder_tmpscript

  second_dir="$(_coder_tmpscript_dir)"

  [[ "$first_dir" != "$second_dir" ]]
}

# _count_inline_tmp_writes - Report how many places in the libs module specs
#     write directly to the fixed temp directory
#
# Hard-coding the fixed path instead of using the helpers (setup_coder_tmpscript /
# run_coder_tmpscript) limits cleanup to files, leaving directories in /tmp.
#
# Do not use grep's exit code as the verdict. It returns 1 on zero hits, so
# "no violations" and "the check itself failed" become indistinguishable. Count and compare in the caller.
#
# @stdout Number of violations
# @return 0 always
# shellcheck disable=SC2329
_count_inline_tmp_writes() {
  local -a patterns=("${_INLINE_TMP_WRITE_COMMANDS[@]/%/ ${_FIXED_PLUGINS_DIR}}")
  local IFS='|'

  grep -rhoE "${patterns[*]}" --include="$_SPEC_FILE_GLOB" "$_LIBS_SPEC_DIR" | wc -l
}

# _scans_at_least_one_spec_file - Report whether the static check scans at least one spec file
#
# Positive control for _count_inline_tmp_writes. When no file matches the --include
# pattern, grep returns zero hits without writing anything to stderr. An empty scan
# passes as "no violations", so the violation count alone cannot prove the check is alive.
#
# Shares _LIBS_SPEC_DIR and _SPEC_FILE_GLOB, which define the scan scope, with the control.
# `^` matches every line, so the number of files grep lists equals the number scanned.
#
# @return 0 if the scan covers one or more spec files, 1 if it covers none
# shellcheck disable=SC2329
_scans_at_least_one_spec_file() {
  local scanned
  scanned="$(grep -rlE '^' --include="$_SPEC_FILE_GLOB" "$_LIBS_SPEC_DIR" | wc -l)"

  ((scanned >= 1))
}

# _naming_local_dirs_exported - Report whether setup_naming_cache exports
#     DECKRD_LOCAL_TEMP and DECKRD_LOCAL_WORKSPACES to child processes
#
# Call teardown_naming_cache first to remove both variables along with their attributes, then rerun setup.
# Skipping this reset would credit setup with export attributes left by an earlier example,
# letting an implementation that dropped the export from setup pass.
#
# `export -p` in a child bash lists only exported variables. Scripts started as child processes
# read exactly this list, so an implementation that assigns without exporting is caught only this way.
#
# @return 0 if both variables are exported, 1 otherwise
# shellcheck disable=SC2329
_naming_local_dirs_exported() {
  teardown_naming_cache
  setup_naming_cache

  bash -c 'export -p | grep -q "^declare -x DECKRD_LOCAL_TEMP=" &&
    export -p | grep -q "^declare -x DECKRD_LOCAL_WORKSPACES="'
}

# _naming_overrides_real_local_dirs - Report whether setup_naming_cache redirects
#     DECKRD_LOCAL_TEMP / DECKRD_LOCAL_WORKSPACES to the sandbox even when
#     real-repository paths were exported beforehand
#
# This spec does not source bootstrap.lib.sh. The runtime initial state (bootstrap having
# exported real-repository paths) is recreated by hand inside this function.
#
# Before seeding the initial state, call teardown_naming_cache to remove the temp
# directory created by the caller's Before, then rerun setup.
#
# `${VAR:-default}` in bootstrap.lib.sh does not re-derive variables that already have values.
# If setup overrides only DECKRD_LOCAL_DATA, these two variables keep pointing at the real
# repository, and scripts reading them write into it.
#
# @return 0 if both variables point outside the repository tree, 1 otherwise
# shellcheck disable=SC2329
_naming_overrides_real_local_dirs() {
  teardown_naming_cache

  export DECKRD_LOCAL_TEMP="${_REAL_LOCAL_DATA_DIR}/temp"
  export DECKRD_LOCAL_WORKSPACES="${_REAL_LOCAL_DATA_DIR}/workspaces"

  setup_naming_cache

  path_outside_repo "$DECKRD_LOCAL_TEMP" && path_outside_repo "$DECKRD_LOCAL_WORKSPACES"
}

# ============================================================================
# Test body
# ============================================================================

# Shared test harness for the libs module specs.
#
# Its job is to provide a per-spec temp directory and keep execution confined to it.
# Using fixed paths or leaving environment variables pointing at the real repository
# lets specs write outside the sandbox.
Describe "spec_helper.sh"

  # Pair of setup_coder_tmpscript / teardown_coder_tmpscript.
  #
  # Their role is to simulate sourcing bootstrap.lib.sh from a bdd-coder path;
  # including plugins/bdd-coder in the path is the contract.
  #
  # Setup creates a dedicated temp directory per example, and teardown removes it without a trace.
  # With a fixed path, jobs under `--jobs 4` share the same directory, and if cleanup
  # removes only files, empty directories keep piling up in /tmp.
  Describe "T-LIB-SHCT: setup_coder_tmpscript"
    Before "setup_coder_tmpscript"
    After "teardown_coder_tmpscript"

    Describe "When: 正常系"

      It '[Normal] T-LIB-SHCT-01: plugins/bdd-coder を 1 セグメントとして含むパスを作る'
        When call _tmpscript_keeps_coder_segment
        The status should be success
      End

      It '[Normal] T-LIB-SHCT-02: 固定パス /tmp/plugins/bdd-coder 配下を使わない'
        When call _tmpscript_outside_fixed_dir
        The status should be success
      End

      # The second teardown in After is harmless thanks to the teardown guard
      It '[Normal] T-LIB-SHCT-03: teardown 後に作成先ディレクトリを残さない'
        When call _teardown_leaves_no_dir
        The status should be success
      End

      It '[Normal] T-LIB-SHCT-05: libs モジュールの spec は固定の一時ディレクトリへ直接書き込まない'
        When call _count_inline_tmp_writes
        The output should equal "0"
        # grep returns zero hits when it cannot read the target directory.
        # Prevents a check with a broken path from passing as "no violations"
        The stderr should be blank
      End

      It '[Normal] T-LIB-SHCT-06: 静的検査が libs モジュールの spec ファイルを 1 件以上走査する'
        When call _scans_at_least_one_spec_file
        The status should be success
      End
    End

    Describe "When: エッジケース"

      It '[Edge] T-LIB-SHCT-04: teardown を挟んだ 2 回目の setup は別のディレクトリを作る'
        When call _second_setup_uses_new_dir
        The status should be success
      End
    End
  End

  # Pair of setup_naming_cache / teardown_naming_cache.
  #
  # Redirects DECKRD_LOCAL_* to the sandbox for naming cache tests and restores them
  # on teardown. If even one variable keeps pointing at the real repository,
  # scripts reading it write into the real repository.
  Describe "T-LIB-SHNC: setup_naming_cache"
    Before "setup_naming_cache"
    After "teardown_naming_cache"

    Describe "When: 正常系"

      It '[Normal] T-LIB-SHNC-01: DECKRD_LOCAL_TEMP を sandbox の temp ディレクトリへ向ける'
        The variable DECKRD_LOCAL_TEMP should equal "${DECKRD_LOCAL_DATA}/temp"
      End

      It '[Normal] T-LIB-SHNC-02: DECKRD_LOCAL_WORKSPACES を sandbox の workspaces ディレクトリへ向ける'
        The variable DECKRD_LOCAL_WORKSPACES should equal "${DECKRD_LOCAL_DATA}/workspaces"
      End

      It '[Normal] T-LIB-SHNC-03: 2 変数を子プロセスへ export する'
        When call _naming_local_dirs_exported
        The status should be success
      End

      It '[Normal] T-LIB-SHNC-04: DECKRD_LOCAL_TEMP をリポジトリツリーの外に保つ'
        When call path_outside_repo "${DECKRD_LOCAL_TEMP:-}"
        The status should be success
      End

      It '[Normal] T-LIB-SHNC-05: DECKRD_LOCAL_WORKSPACES をリポジトリツリーの外に保つ'
        When call path_outside_repo "${DECKRD_LOCAL_WORKSPACES:-}"
        The status should be success
      End

      # The second teardown in After is harmless thanks to the teardown guard
      It '[Normal] T-LIB-SHNC-06: teardown で 3 変数すべてを undefined にする'
        When call teardown_naming_cache
        The variable DECKRD_LOCAL_DATA should be undefined
        The variable DECKRD_LOCAL_TEMP should be undefined
        The variable DECKRD_LOCAL_WORKSPACES should be undefined
      End
    End

    Describe "When: エッジケース"

      It '[Edge] T-LIB-SHNC-07: 実リポジトリのパスが先に export されていても差し替える'
        When call _naming_overrides_real_local_dirs
        The status should be success
      End
    End
  End
End
