#!/usr/bin/env bash
# skills/deckrd/skills/deckrd/scripts/__tests__/unit/spec-helper.unit.spec.sh
# @(#) : BDD unit tests for spec_helper.sh - setup_deckrd_tmpdir / teardown_deckrd_tmpdir /
#        sandbox isolation invariant / path_outside_repo
#
# Copyright (c) 2026- atsushifx <https://github.com/atsushifx>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

# cspell:words SHTD

# ============================================================================
# Test infrastructure
# ============================================================================

# Source bootstrap.lib.sh with `--no-finalize`.
#
# This reproduces the runtime initial state. bootstrap exports DECKRD_LOCAL_* as
# paths under the real repository's .local/deckrd/, so skipping this source makes
# it impossible to test the very state where real-repository paths remain.
# `--no-finalize` suppresses readonly. Once finalized, the assignments in
# setup_deckrd_tmpdir fail.
#
# Do NOT unset DECKRD_LOCAL_TEMP / DECKRD_LOCAL_WORKSPACES here.
# Isolation is the responsibility of setup_deckrd_tmpdir, the code under test;
# clearing them in the spec first would hide defects.
# shellcheck disable=SC1090
_RUNTIME_BOOTSTRAP="${SHELLSPEC_PROJECT_ROOT}/skills/deckrd/skills/deckrd/scripts/libs/bootstrap.lib.sh"
. "$_RUNTIME_BOOTSTRAP" --no-finalize
unset _RUNTIME_BOOTSTRAP

# ============================================================================
# Code under test
# ============================================================================

Include ../spec_helper.sh

# ============================================================================
# Internal helpers
# ============================================================================

# Constants

# _SPEC_HELPER_SCAN_DIR - Root scanned by the static check of the sandbox isolation invariant.
# The __tests__/spec_helper.sh files of cli / libs / subcommands live under it.
# Limiting it to deckrd's scripts/ tree is intentional. runners/__tests__/spec_helper.sh
# and the like never touch DECKRD_LOCAL_*, so the invariant does not apply to them
_SPEC_HELPER_SCAN_DIR="${SHELLSPEC_PROJECT_ROOT}/skills/deckrd/skills/deckrd/scripts"

# _SPEC_HELPER_GLOB - File names picked up by the static check. Only test harnesses are examined.
# Shared by the violation counter and the scan counter. Writing them separately lets one
# get fixed alone, which defeats their purpose as a control
_SPEC_HELPER_GLOB='spec_helper.sh'

# _KNOWN_SPEC_HELPERS - Harness path suffixes that the scan must always cover.
# Each entry is a relative path starting at the last segment of _SPEC_HELPER_SCAN_DIR (`scripts`),
# listing every harness that exists under the scan root. Add to this list when adding a module
_KNOWN_SPEC_HELPERS=(
  'scripts/__tests__/spec_helper.sh'
  'scripts/libs/__tests__/spec_helper.sh'
  'scripts/subcommands/__tests__/spec_helper.sh'
)

# _RELATIVE_LOCAL_PATH - A relative path that cannot be asserted to be outside the repository.
# Depending on cwd it points inside the repository, so path_outside_repo must return false
_RELATIVE_LOCAL_PATH='.local/deckrd/temp'

# _SANDBOX_ANCHOR_VAR - Variable name that anchors the invariant. A file that overrides it
# must also override its paired variables
_SANDBOX_ANCHOR_VAR='DECKRD_LOCAL_DATA'

# _SANDBOX_TEMP_VAR - Variable that must be overridden together with the anchor (temp side)
_SANDBOX_TEMP_VAR='DECKRD_LOCAL_TEMP'

# _SANDBOX_WORKSPACES_VAR - Variable that must be overridden together with the anchor (workspaces side)
_SANDBOX_WORKSPACES_VAR='DECKRD_LOCAL_WORKSPACES'

# Functions

# _both_local_dirs_exported - Report whether setup_deckrd_tmpdir exports DECKRD_LOCAL_TEMP and
#                             DECKRD_LOCAL_WORKSPACES to child processes
#
# Before checking, call teardown_deckrd_tmpdir to remove both variables with their attributes, then redo setup.
# Bash's export attribute survives later plain assignments, so without this rebuild the attribute
# set by bootstrap.lib.sh (sourced at the top of the spec) would be credited to setup,
# and an implementation whose setup drops the export would pass.
#
# Because teardown runs first, the temp directory created by the caller's Before is cleaned up here.
# Reversing the order leaves that temp directory untracked and leaks it.
#
# `export -p` in a child bash lists only exported variables. Scripts launched as child processes
# read exactly this list, so an implementation that assigns without exporting is caught only this way.
#
# @return 0 if both variables are exported, 1 otherwise
# shellcheck disable=SC2329
_both_local_dirs_exported() {
  teardown_deckrd_tmpdir
  setup_deckrd_tmpdir

  bash -c 'export -p | grep -q "^declare -x DECKRD_LOCAL_TEMP=" &&
    export -p | grep -q "^declare -x DECKRD_LOCAL_WORKSPACES="'
}

# _count_nul_records - Report the number of NUL-delimited records
#
# Paths are passed NUL-delimited. Passing newline-delimited paths to xargs splits them on whitespace,
# so in environments where SHELLSPEC_PROJECT_ROOT contains spaces (common on Windows)
# grep errors on each fragment and the violation count falls back to 0.
#
# `wc -l` counts newlines and cannot handle NUL-delimited input. The NUL count is the record count.
#
# @stdin NUL-delimited records
# @stdout Number of records
# @return 0 always
# shellcheck disable=SC2329
_count_nul_records() {
  tr -cd '\0' | wc -c
}

# _list_sandbox_anchor_files - List spec_helper.sh files that override _SANDBOX_ANCHOR_VAR
#
# Only assignment lines are matched. Requiring no `#` between line start and the variable name
# keeps mentions in comments from being mistaken for overrides. `\b` excludes forms where
# another identifier is prefixed to the variable name (`MY_DECKRD_LOCAL_DATA=`).
#
# Uses the same constants and regex as _count_sandbox_anchor_assignments, which counts
# all assignment lines. This one works per file, that one per line, so the pairing check and
# the total-count check share the same definition of an assignment.
#
# @stdout Paths of overriding files (NUL-delimited)
# @return grep exit status; callers do not use it for pass/fail
# shellcheck disable=SC2329
_list_sandbox_anchor_files() {
  grep -rlZE "^[^#]*\b${_SANDBOX_ANCHOR_VAR}=" --include="$_SPEC_HELPER_GLOB" "$_SPEC_HELPER_SCAN_DIR"
}

# _count_sandbox_anchor_assignments - Report the total number of _SANDBOX_ANCHOR_VAR
#     assignment lines across all harnesses
#
# Scan scope, file name glob, and variable name come from the same constants as _list_sandbox_anchor_files
# (_SPEC_HELPER_SCAN_DIR / _SPEC_HELPER_GLOB / _SANDBOX_ANCHOR_VAR).
# Only the extraction unit differs: that one lists files with `-l`, this one lists lines with `-h`.
#
# A per-file check is not enough. _count_partial_sandbox_overrides checks per file whether
# a file overriding the anchor also overrides the paired variables, so adding a new helper
# that overrides only the anchor to the same file as export_sandbox_local_dirs
# is satisfied by the paired assignments in that file, and the violation count stays at 0.
# The correct state is that the assignment exists only inside export_sandbox_local_dirs;
# if the total is 1, no partial override can be written anywhere in the harnesses.
#
# Do not use grep's exit status for pass/fail. It returns 1 on zero hits, making
# "no assignments" indistinguishable from "the check itself failed". Count and compare in the caller.
#
# @stdout Total number of assignment lines
# @return 0 always
# shellcheck disable=SC2329
_count_sandbox_anchor_assignments() {
  grep -rhE "^[^#]*\b${_SANDBOX_ANCHOR_VAR}=" --include="$_SPEC_HELPER_GLOB" "$_SPEC_HELPER_SCAN_DIR" | wc -l
}

# _count_partial_sandbox_overrides - Report the number of spec_helper.sh files that override
#     only the anchor variable and forget the paired variable
#
# Overriding a single variable by hand instead of using export_sandbox_local_dirs leaves the rest
# pointing at the real repository, and scripts reading them write into it.
# Guards placed in each spec reopen the same hole with every new spec,
# so the whole harness set is counted in one place.
#
# Do not use grep's exit status directly for pass/fail. It returns 1 on zero hits, making
# "no violations" indistinguishable from "the check itself failed". Count and compare in the caller.
#
# @arg $1 string Variable name that must be overridden together with the anchor
# @stdout Number of violating files
# @return 0 always
# shellcheck disable=SC2329
_count_partial_sandbox_overrides() {
  _list_sandbox_anchor_files | xargs -0 -r grep -LZE "^[^#]*\b${1}=" | _count_nul_records
}

# _list_scanned_spec_helpers - List harness paths scanned by the static check
#
# Shares _SPEC_HELPER_SCAN_DIR and _SPEC_HELPER_GLOB, which define the scan scope, with the
# violation count. `^` matches every line, so every file grep finds is a scan target.
#
# @stdout Paths of scanned files (NUL-delimited)
# @return grep exit status; callers do not use it for pass/fail
# shellcheck disable=SC2329
_list_scanned_spec_helpers() {
  grep -rlZE '^' --include="$_SPEC_HELPER_GLOB" "$_SPEC_HELPER_SCAN_DIR"
}

# _suffix_matches_any - Report whether any of the given paths ends with the given suffix
#
# The suffix is matched at a directory boundary. Without a leading `/`, a different file
# such as `own-spec_helper.sh` would match.
#
# @arg $1 string Suffix to match (pass it without a leading `/`)
# @arg $@ string Paths to match against
# @return 0 if one of the paths ends with the suffix, 1 if none does
# shellcheck disable=SC2329
_suffix_matches_any() {
  local suffix="$1"
  shift

  local path
  for path in "$@"; do
    [[ "$path" == *"/${suffix}" ]] && return 0
  done

  return 1
}

# _scan_covers_known_spec_helpers - Report whether the static check scans every entry
#     of _KNOWN_SPEC_HELPERS
#
# Positive control for _count_partial_sandbox_overrides. When no file matches the --include
# pattern, grep writes nothing to stderr and returns zero hits. An empty scan still passes
# as "no violations", so the violation count alone cannot prove the check is alive.
#
# "At least one" is not enough. Narrowing the scan root to a single already-compliant directory
# keeps the violation count at 0 and the scan count at 1, so every case passes while
# the libs and subcommands harnesses silently drop out of the check.
# Checking which harnesses are covered, not how many, makes a shrunken scope itself a failure.
#
# The count is not kept as a constant. A bare count does not tell which harness
# dropped out when modules are added.
#
# @return 0 if the scan covers every known helper, 1 if any of them is missing
# shellcheck disable=SC2329
_scan_covers_known_spec_helpers() {
  local -a scanned
  mapfile -d '' -t scanned < <(_list_scanned_spec_helpers)

  local known
  for known in "${_KNOWN_SPEC_HELPERS[@]}"; do
    _suffix_matches_any "$known" "${scanned[@]}" || return 1
  done
}

# _has_sandbox_anchor_file - Report whether at least one spec_helper.sh
#     overrides the anchor variable
#
# Another positive control for _count_partial_sandbox_overrides. The violation count
# returns 0 and passes even when its input (the set of files overriding the anchor) is empty.
# This prevents a check with a misspelled variable name from passing as "no violations".
#
# It shares _list_sandbox_anchor_files, which builds that input, with the violation count,
# so a broken anchor spelling always fails here.
#
# @return 0 if one or more files override the anchor variable, 1 if none do
# shellcheck disable=SC2329
_has_sandbox_anchor_file() {
  local overriding
  overriding="$(_list_sandbox_anchor_files | _count_nul_records)"

  ((overriding >= 1))
}

# ============================================================================
# Test body
# ============================================================================

# Temp directory harness of spec_helper.sh.
#
# setup_deckrd_tmpdir redirects the DECKRD_LOCAL_* exported by bootstrap.lib.sh
# into the sandbox, and teardown_deckrd_tmpdir restores them.
# If even one variable still points at the real repository, scripts reading it
# write into the real repository.
Describe "T-CLI-SHTD: spec_helper.sh: setup_deckrd_tmpdir"
  Before "setup_deckrd_tmpdir"
  After "teardown_deckrd_tmpdir"

  It '[Normal] T-CLI-SHTD-01: Should: point DECKRD_LOCAL_TEMP at the sandbox temp dir'
    The variable DECKRD_LOCAL_TEMP should equal "${DECKRD_LOCAL_DATA}/temp"
  End

  It '[Normal] T-CLI-SHTD-02: Should: point DECKRD_LOCAL_WORKSPACES at the sandbox workspaces dir'
    The variable DECKRD_LOCAL_WORKSPACES should equal "${DECKRD_LOCAL_DATA}/workspaces"
  End

  It '[Normal] T-CLI-SHTD-03: Should: export both variables to child processes'
    When call _both_local_dirs_exported
    The status should be success
  End

  It '[Normal] T-CLI-SHTD-04: Should: keep DECKRD_LOCAL_TEMP outside the repository tree'
    When call path_outside_repo "${DECKRD_LOCAL_TEMP:-}"
    The status should be success
  End

  It '[Normal] T-CLI-SHTD-05: Should: keep DECKRD_LOCAL_WORKSPACES outside the repository tree'
    When call path_outside_repo "${DECKRD_LOCAL_WORKSPACES:-}"
    The status should be success
  End

  # The second call in After is harmless thanks to the guard in teardown
  It '[Normal] T-CLI-SHTD-06: Should: unset both variables on teardown'
    When call teardown_deckrd_tmpdir
    The variable DECKRD_LOCAL_TEMP should be undefined
    The variable DECKRD_LOCAL_WORKSPACES should be undefined
  End
End

# Sandbox isolation invariant of spec_helper.sh.
#
# If an isolation helper overrides DECKRD_LOCAL_DATA, it must also override the paired
# DECKRD_LOCAL_* variables. If even one still points at the real repository,
# scripts reading it write into the real repository.
#
# As long as guards live in each spec, every new spec reopens the same hole.
# Scan all harnesses statically and check the invariant itself.
# This check reads no environment variables, so it has no temp directory Before / After.
#
# The per-variable cases call the same logic, changing only the variable name passed to
# _count_partial_sandbox_overrides. Writing the logic per variable lets one get fixed
# while the other is silently left behind.
Describe "T-CLI-SHIV: spec_helper.sh: sandbox isolation invariant"

  It '[Normal] T-CLI-SHIV-01: Should: report no helper that overrides DECKRD_LOCAL_DATA without DECKRD_LOCAL_TEMP'
    When call _count_partial_sandbox_overrides "$_SANDBOX_TEMP_VAR"
    The output should equal "0"
    # If the scan path does not exist, grep writes `No such file or directory` to stderr
    # and exits 2. The count drops to 0 while stderr becomes non-empty, so
    # a check with a broken path cannot pass as "no violations"
    The stderr should be blank
  End

  It '[Normal] T-CLI-SHIV-02: Should: report no helper that overrides DECKRD_LOCAL_DATA without DECKRD_LOCAL_WORKSPACES'
    When call _count_partial_sandbox_overrides "$_SANDBOX_WORKSPACES_VAR"
    The output should equal "0"
    The stderr should be blank
  End

  # The next two cases are positive controls for the violation count.
  # SHIV-03 shares _SPEC_HELPER_SCAN_DIR / _SPEC_HELPER_GLOB (the scan scope), and
  # SHIV-04 shares the anchor _SANDBOX_ANCHOR_VAR, with the violation count.
  # Even if the scan scope shrinks or the anchor spelling breaks,
  # the violation count alone still returns 0 and passes.
  It '[Normal] T-CLI-SHIV-03: Should: cover every known spec_helper.sh in the scan'
    When call _scan_covers_known_spec_helpers
    The status should be success
    The stderr should be blank
  End

  It '[Normal] T-CLI-SHIV-04: Should: find at least one helper that overrides DECKRD_LOCAL_DATA'
    When call _has_sandbox_anchor_file
    The status should be success
    The stderr should be blank
  End

  # Check the total number of assignments, not just pairing. With a per-file check,
  # a partial override added to the same file as export_sandbox_local_dirs
  # slips through, hidden by the paired assignments in that file.
  It '[Normal] T-CLI-SHIV-05: Should: assign DECKRD_LOCAL_DATA at exactly one place in the harness'
    When call _count_sandbox_anchor_assignments
    The output should equal "1"
    The stderr should be blank
  End
End

# Out-of-repository check of spec_helper.sh.
#
# T-CLI-SHTD-04 / T-CLI-SHTD-05 and, on the libs side, T-LIB-SHNC-04 / T-LIB-SHNC-05 /
# T-LIB-SHNC-07 all rely on this single predicate to verify that the DECKRD_LOCAL_*
# overridden by the isolation helper do not point at the real repository. A loose predicate
# blinds all of those cases at once.
#
# Looseness shows up in two inputs. Reporting non-absolute inputs (an unset variable that
# `${VAR:-}` turns into an empty string, and a relative path that may point inside the
# repository depending on cwd) as "outside" lets a missed override pass. Both must be false.
Describe "T-CLI-SHPO: spec_helper.sh: path_outside_repo"

  It '[Normal] T-CLI-SHPO-01: Should: report an empty path as not outside the repository'
    When call path_outside_repo ""
    The status should be failure
  End

  It '[Normal] T-CLI-SHPO-02: Should: report a relative path as not outside the repository'
    When call path_outside_repo "$_RELATIVE_LOCAL_PATH"
    The status should be failure
  End
End
