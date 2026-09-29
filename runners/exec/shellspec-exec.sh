#!/usr/bin/env bash
# src: ./runners/exec/shellspec-exec.sh
# @(#) : shellspec runner
#
# Copyright (c) 2026- atsushifx <https://github.com/atsushifx>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

# shellcheck disable=SC1091

set -euo pipefail

# shellcheck source=runners/libs/init-vars.lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/../libs/init-vars.lib.sh"

SHELLSPEC="${SHELLSPEC:-${PROJECT_ROOT}/.tools/shellspec/shellspec}"

# Valid test type identifiers
readonly TEST_TYPES=("all" "unit" "functional" "integration" "system" "e2e")

# Directory name that roots every spec tree (runners/__tests__/unit/... etc.)
readonly TESTS_DIR='__tests__'

# login shell の報告を見分ける目印。行頭に現れたら、その行の残りが報告された PATH。
# ユーザーの起動ファイルは stdout へ進捗行を書くので、報告を丸ごと読むことはできない
readonly LOGIN_PATH_MARKER='__DECKRD_LOGIN_PATH__'

# Test mode: set SKIP_INTEGRATION_TESTS=1 by default (development mode)
# Override with INTEGRATION_TEST=1 env var or --integration flag to run real-machine tests
SKIP_INTEGRATION_TESTS="${SKIP_INTEGRATION_TESTS:-1}"

# Search root for spec file discovery (override in tests to point at a temp dir)
SPEC_SEARCH_ROOT="${SPEC_SEARCH_ROOT:-${PROJECT_ROOT}}"

# shellcheck source=runners/libs/get-filelist.lib.sh
. "${SCRIPT_ROOT}/../libs/get-filelist.lib.sh"

#
# @description Check if argument is a valid test type
# @arg $1 string Argument to check
# @exitcode 0 if valid test type, 1 otherwise
#
is_test_type() {
  local arg="$1"
  local type
  for type in "${TEST_TYPES[@]}"; do
    [[ "$arg" == "$type" ]] && return 0
  done
  return 1
}

#
# @description Check if argument is a spec file path
# @arg $1 string Argument to check
# @exitcode 0 if spec file path, 1 otherwise
#
is_spec_file() {
  local arg="$1"
  [[ "$arg" == *.spec.sh ]]
}

#
# @description Check if argument is a glob path pattern targeting spec files
# @arg $1 string Argument to check
# @exitcode 0 if glob path containing *.spec.sh pattern, 1 otherwise
#
is_spec_glob() {
  local arg="$1"
  is_glob_pattern "$arg" && [[ "$arg" == *".spec.sh"* ]]
}

#
# @description Expand a glob path pattern to matching spec file paths
# @arg $1 string Glob path pattern (e.g. runners/libs/tests/unit/*.spec.sh)
# @stdout List of matching spec file paths
# @exitcode 0 always (warns if no match)
#
expand_spec_glob() {
  local pattern="$1"
  local norm_pattern
  norm_pattern=$(normalize_path "$pattern")

  local -a matches
  # Use compgen -G for glob expansion (handles no-match gracefully)
  mapfile -t matches < <(
    cd "$SPEC_SEARCH_ROOT" && compgen -G "$norm_pattern" 2>/dev/null || true
  )

  if [[ ${#matches[@]} -eq 0 ]]; then
    echo "Warning: No spec files found matching glob '${pattern}'" >&2
    return 0
  fi

  local f
  for f in "${matches[@]}"; do
    normalize_path "$f"
  done
}

#
# @description Get spec files for a given test type
# @arg $1 string Test type (all, unit, functional, etc.)
# @arg $@ Additional file patterns to filter by
# @stdout List of spec file paths relative to project root
#
get_spec_files() {
  local test_type="$1"
  shift
  local type_filter
  if [[ "$test_type" == "all" ]]; then
    type_filter="${TESTS_DIR}/"
  else
    type_filter="${TESTS_DIR}/${test_type}/"
  fi
  get_filelist "$SPEC_SEARCH_ROOT" "*.spec.sh" "$type_filter" "$@"
}

#
# @description Decide whether real-machine (integration) tests should be enabled.
#              Pure: reads only its arguments so the caller can assign the result
#              in its own shell
# @arg $@ Command line arguments
# @exitcode 0 if --integration is given or the target is the system test type,
#           1 otherwise
#
should_enable_integration() {
  local arg
  for arg in "$@"; do
    [[ "$arg" == "--integration" ]] && return 0
  done
  # ターゲットは先頭に並ぶので、種別は $1 に現れる。$1 が --integration の場合は
  # 上のループで確定済み
  [[ "${1:-}" == "system" ]]
}

#
# @description Pick the PATH a probe reported out of the probe's whole stdout. The
#              startup files a login shell reads write their own lines to stdout, so
#              the report cannot be taken wholesale; only the line the probe introduced
#              with the marker carries the PATH. The marker counts at the start of a
#              line only, and the last such line wins, so a startup file that prints the
#              marker's spelling cannot shadow what the probe appended last.
#              Pure function: reads only its arguments
# @arg $1 string Marker the probe printed in front of the PATH
# @arg $2 string Whole stdout of the probe
# @stdout The rest of the marked line, i.e. the reported PATH; empty when the marked
#         line carries none
# @exitcode 0 when the output holds a marked line, 1 when it holds none
#
extract_marked_path() {
  local __marker="$1"
  local __raw="$2"
  # 先頭へ改行を足す。目印を行頭でだけ認めるための下ごしらえで、目印行が 1 行目に
  # 来る入力も 2 行目以降と同じ規則で扱える
  local __haystack=$'\n'"$__raw"
  # 目印行が 1 本も無ければ失敗させる。切り出せなかったことを呼び出し元へ伝えないと、
  # 進捗行が PATH として採られる
  [[ "$__haystack" == *$'\n'"$__marker"* ]] || return 1
  # 最後の目印行より後ろを残す。起動ファイルが目印と同じ綴りを印字しても、
  # プローブが最後に足した 1 行が勝つ
  local __tail="${__haystack##*$'\n'"$__marker"}"
  printf '%s\n' "${__tail%%$'\n'*}"
}

#
# @description Drop the empty entries of a colon separated PATH. An empty entry names
#              the current directory, so one left in a reported PATH puts whatever
#              directory ShellSpec runs from on the command search path.
#              Pure function: reads only its argument
# @arg $1 string Colon separated PATH
# @stdout The same PATH without its empty entries; empty when every entry was empty
# @exitcode 0 always
#
drop_empty_path_entries() {
  local __path="$1"
  local -a __entries=()
  # here-string が末尾へ改行を足すので read は必ず 1 行読み切って 0 を返す。
  # 末尾の空要素はこの分割で落ちるが、落としたいものと同じなので構わない
  IFS=':' read -ra __entries <<<"$__path"

  local __entry
  local __kept=''
  for __entry in ${__entries[@]+"${__entries[@]}"}; do
    [[ -n "$__entry" ]] || continue
    __kept="${__kept:+${__kept}:}${__entry}"
  done
  printf '%s\n' "$__kept"
}

#
# @description Replace PATH with the one a login and interactive shell reports, so that
#              tools installed by the user's startup files (volta, linuxbrew, nix) become
#              reachable. Real-machine tests need them; the non-login, non-interactive
#              shell that runs this script reads no startup file and has none of them.
#              `-lic` rather than `-lc`: a startup chain may add its entries from the
#              interactive rc, and only a shell that is both login and interactive reads
#              both halves — the same shell the user gets when opening a terminal.
#              The report replaces PATH instead of extending it: it is a superset of the
#              inherited PATH, so nothing is lost, and the inherited entries no longer
#              shadow the copy of a tool the startup files installed
# @sideeffect Replaces PATH when the login shell reports one
# @exitcode 0 always; a login shell that fails, reports no marked line, or reports
#           nothing but empty entries leaves PATH untouched
#
ensure_integration_path() {
  local _raw _marked _cleaned
  # 目印は位置パラメータで渡す。プローブ本文を単引用符のままに保てるので、入れ子の
  # 引用符を数えずに済む ($0 に当たる 'bash' はエラー表示用の名前)。
  # stdin は閉じる: 対話シェルは stdin を読む権利があり、起動ファイルが read すると
  # テスト実行全体が失敗ではなく停止する
  # shellcheck disable=SC2016 # プローブ本文。$1 と $PATH は login shell が解決する
  _raw="$(bash -lic 'printf "\n%s%s\n" "$1" "$PATH"' bash "$LOGIN_PATH_MARKER" 2>/dev/null </dev/null)" || return 0
  _marked="$(extract_marked_path "$LOGIN_PATH_MARKER" "$_raw")" || return 0
  _cleaned="$(drop_empty_path_entries "$_marked")"
  [[ -n "$_cleaned" ]] && PATH="$_cleaned"
  return 0
}

#
# @description Drop the --integration flag from the argument list. The flag is
#              consumed here; the gate it opens is decided by
#              should_enable_integration() in the caller's own shell
# @arg $@ Command line arguments
# @stdout Remaining arguments (without --integration), newline-separated
#
parse_options() {
  local arg
  for arg in "$@"; do
    [[ "$arg" == "--integration" ]] && continue
    printf '%s\n' "$arg"
  done
}

#
# @description Resolve spec files from arguments (handles test types, globs, single files)
# @arg $@ Command line arguments (test type, spec file, or glob pattern)
# @stdout List of spec file paths
# @stderr Error and warning messages
# @exitcode 0 on success, 1 on error
#
resolve_spec_files() {
  [[ $# -eq 0 ]] && {
    printf 'Error: No arguments given.\n' >&2
    return 1
  }

  local first_arg="$1"

  # 単一 .spec.sh ファイルはそのまま出力
  if is_spec_file "$first_arg"; then
    printf '%s\n' "$first_arg"
    return 0
  fi

  # glob パス（*.spec.sh を含む glob）は expand_spec_glob で展開
  if is_spec_glob "$first_arg"; then
    expand_spec_glob "$first_arg"
    return 0
  fi

  # テスト種別以外 → エラー (stderr)
  if ! is_test_type "$first_arg"; then
    printf "Error: Unknown argument '%s'. Expected a test type, spec file, or glob pattern.\n" "$first_arg" >&2
    return 1
  fi

  # テスト種別 → get_spec_files で展開
  local test_type="$1"
  shift
  local -a spec_files
  mapfile -t spec_files < <(get_spec_files "$test_type" "$@")
  if [[ ${#spec_files[@]} -eq 0 || -z "${spec_files[0]}" ]]; then
    echo "Warning: No spec files found for test type '${test_type}'" >&2
    return 0
  fi
  printf '%s\n' "${spec_files[@]}"
}

#
# @description Run ShellSpec with normalized path arguments
# @arg $@ Spec file paths followed by ShellSpec options (options pass through
#         normalize_path unchanged unless they contain backslashes)
# @exitcode Exit code from ShellSpec
#
run_shellspec() {
  local -a normalized_args=()
  local arg
  for arg in "$@"; do
    normalized_args+=("$(normalize_path "$arg")")
  done

  # Run ShellSpec from project root using subshell
  # Subshell ensures caller's directory remains unchanged
  (cd "$PROJECT_ROOT" && export SKIP_INTEGRATION_TESTS && bash "$SHELLSPEC" "${normalized_args[@]}")
}

#
# @description Main entry point for running ShellSpec tests
# @arg $@ Command line arguments (test type, paths and options)
# @exitcode Exit code from ShellSpec
#
# @example
#   main unit                         # Run unit tests (auto-resolved)
#   main integration                  # Run integration tests (auto-resolved)
#   main all                          # Run all tests
#   main runners/libs/tests/unit/*.spec.sh  # Run spec glob
#   main test.spec.sh --repair        # Run with ShellSpec options
#
main() {
  if [[ $# -eq 0 ]]; then
    echo "Usage: run-shellspec.sh <test-type|spec-file|spec-glob> [--integration] [shellspec-options]" >&2
    exit 1
  fi

  # 実機テストの有効化は親シェルで決める。parse_options / resolve_spec_files は
  # サブシェルで呼ぶため、その中で代入しても呼び出し元へは戻らない
  if should_enable_integration "$@"; then
    SKIP_INTEGRATION_TESTS=0
    ensure_integration_path
  fi

  local -a filtered_args
  mapfile -t filtered_args < <(parse_options "$@")

  # Targets come first, so everything from the first option onward is a
  # ShellSpec option (its values must not be mistaken for targets)
  local -a targets=() options=()
  local arg seen_option=0
  for arg in ${filtered_args[@]+"${filtered_args[@]}"}; do
    [[ $seen_option -eq 0 && "$arg" == -* ]] && seen_option=1
    if [[ $seen_option -eq 1 ]]; then
      options+=("$arg")
    else
      targets+=("$arg")
    fi
  done

  local resolved
  resolved=$(resolve_spec_files ${targets[@]+"${targets[@]}"}) || exit 1

  [[ -z "$resolved" ]] && exit 0

  local -a spec_files
  mapfile -t spec_files <<<"$resolved"
  run_shellspec "${spec_files[@]}" ${options[@]+"${options[@]}"}
}

# Execute main only if script is run directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
