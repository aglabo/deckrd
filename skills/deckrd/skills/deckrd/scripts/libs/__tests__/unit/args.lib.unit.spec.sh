#!/usr/bin/env bash
# src: ./skills/deckrd/skills/deckrd/scripts/libs/__tests__/unit/args.lib.unit.spec.sh
# @(#) : ShellSpec unit tests for args.lib.sh (declarative argument parser)
#
# Copyright (c) 2026- aglabo <https://github.com/aglabo>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

# shellcheck disable=SC1090,SC1091,SC2034

. "${SHELLSPEC_PROJECT_ROOT}/skills/deckrd/skills/deckrd/scripts/libs/bootstrap.lib.sh" --no-finalize

Include "${SHELLSPEC_SPECFILE%/*}/../spec_helper.sh"

SCRIPT="${DECKRD_LIB_DIR}/args.lib.sh"
. "${SCRIPT}"

# --- 内部ヘルパー ---

# _aini_key_of_count_after_second_init - args_flag で宣言した後に args_init し、_ARGS_KEY_OF の要素数を出力する
#
# @stdout _ARGS_KEY_OF の要素数
_aini_key_of_count_after_second_init() {
  args_init
  args_flag force --force
  args_init
  echo "${#_ARGS_KEY_OF[@]}"
}

# _aini_type_count_after_second_init - args_value で宣言した後に args_init し、_ARGS_TYPE の要素数を出力する
#
# @stdout _ARGS_TYPE の要素数
_aini_type_count_after_second_init() {
  args_init
  args_value model sonnet --model
  args_init
  echo "${#_ARGS_TYPE[@]}"
}

# _aini_positional_count_after_second_init - args_positional で宣言した後に args_init し、_ARGS_POSITIONAL の要素数を出力する
#
# @stdout _ARGS_POSITIONAL の要素数
_aini_positional_count_after_second_init() {
  args_init
  args_positional project type
  args_init
  echo "${#_ARGS_POSITIONAL[@]}"
}

# _aini_options_stale_after_second_init - OPTIONS に古いキーを入れた後に args_init し、キーの有無を出力する
#
# @stdout "set" (キーが残っている) または "unset" (消えている)
_aini_options_stale_after_second_init() {
  args_init
  OPTIONS[stale]=x
  args_init
  if [[ -v 'OPTIONS[stale]' ]]; then echo "set"; else echo "unset"; fi
}

# _aini_options_set_stale_after_second_init - OPTIONS_SET に古いキーを入れた後に args_init し、キーの有無を出力する
#
# @stdout "set" (キーが残っている) または "unset" (消えている)
_aini_options_set_stale_after_second_init() {
  args_init
  OPTIONS_SET[stale]=true
  args_init
  if [[ -v 'OPTIONS_SET[stale]' ]]; then echo "set"; else echo "unset"; fi
}

# _aini_init_inside_function - 関数内で args_init を呼び、関数を抜けた後に OPTIONS へ書き込む
#
# @stdout 1 行目: OPTIONS[k] の値 / 2 行目: declare -p OPTIONS の出力
_aini_init_inside_function() {
  _aini_wrapper() { args_init; }
  _aini_wrapper
  OPTIONS[k]=v
  echo "${OPTIONS[k]}"
  declare -p OPTIONS
}

# _aini_parse_after_second_init - --force を宣言・解析した後に args_init で宣言をやり直し、再度 --force を解析する
#
# 1 回目の parse_args が失敗した場合は前提崩れとして 9 を返す。
#
# @return 2 回目の parse_args の終了ステータス
_aini_parse_after_second_init() {
  args_init
  args_flag force --force
  parse_args --force || return 9
  args_init
  args_flag verbose --verbose
  parse_args --force
}

# _aflg_parse_force - args_flag force <opts...> を宣言して parse_args を実行し、OPTIONS[force] を出力する
#
# @arg $1 string opts 宣言するオプション名 (空白区切り)
# @arg $@ string args parse_args に渡す引数
# @stdout OPTIONS[force] の値 (未設定なら "<unset>")
# @return parse_args の終了ステータス
_aflg_parse_force() {
  local opts="$1" rc=0
  shift
  args_init
  # shellcheck disable=SC2086 # opts は意図的に単語分割する
  args_flag force $opts
  parse_args "$@" || rc=$?
  echo "${OPTIONS[force]:-<unset>}"
  return "$rc"
}

# _aflg_tables_after_declare - args_flag force -f --force を宣言し、内部テーブルの登録内容を出力する
#
# @stdout 1 行目: _ARGS_TYPE[force] / 2 行目: _ARGS_KEY_OF[-f] / 3 行目: _ARGS_KEY_OF[--force]
_aflg_tables_after_declare() {
  args_init
  args_flag force -f --force
  echo "${_ARGS_TYPE[force]:-<unset>}"
  echo "${_ARGS_KEY_OF[-f]:-<unset>}"
  echo "${_ARGS_KEY_OF[--force]:-<unset>}"
}

# _aval_parse - args_value <key> <default> <opts...> を宣言して parse_args を実行し、OPTIONS[key] を出力する
#
# @arg $1 string key     宣言するキー
# @arg $2 string default 既定値
# @arg $3 string opts    宣言するオプション名 (空白区切り)
# @arg $@ string args    parse_args に渡す引数
# @stdout OPTIONS[key] の値 (未設定なら "<unset>"、空文字はそのまま空)
# @return parse_args の終了ステータス
_aval_parse() {
  local key="$1" default="$2" opts="$3" rc=0
  shift 3
  args_init
  # shellcheck disable=SC2086 # opts は意図的に単語分割する
  args_value "$key" "$default" $opts
  parse_args "$@" || rc=$?
  echo "${OPTIONS[$key]-<unset>}"
  return "$rc"
}

# _aval_tables_after_declare - args_value model sonnet -m --model を宣言し、内部テーブルの登録内容を出力する
#
# @stdout 1 行目: _ARGS_TYPE[model] / 2 行目: _ARGS_KEY_OF[-m] / 3 行目: _ARGS_KEY_OF[--model]
_aval_tables_after_declare() {
  args_init
  args_value model sonnet -m --model
  echo "${_ARGS_TYPE[model]:-<unset>}"
  echo "${_ARGS_KEY_OF[-m]:-<unset>}"
  echo "${_ARGS_KEY_OF[--model]:-<unset>}"
}

# _apos_parse - args_positional project type を宣言して parse_args を実行し、位置引数のキーを出力する
#
# @arg $@ string args parse_args に渡す引数
# @stdout 1 行目: project=<OPTIONS[project]> / 2 行目: type=<OPTIONS[type]> (未設定なら "<unset>")
# @return parse_args の終了ステータス
_apos_parse() {
  local rc=0
  args_init
  args_positional project type
  parse_args "$@" || rc=$?
  echo "project=${OPTIONS[project]-<unset>}"
  echo "type=${OPTIONS[type]-<unset>}"
  return "$rc"
}

# _apos_parse_with_force - args_flag force --force と args_positional project type を宣言して parse_args を実行する
#
# @arg $@ string args parse_args に渡す引数
# @stdout 1 行目: project=<値> / 2 行目: type=<値> / 3 行目: force=<値> (未設定なら "<unset>")
# @return parse_args の終了ステータス
_apos_parse_with_force() {
  local rc=0
  args_init
  args_flag force --force
  args_positional project type
  parse_args "$@" || rc=$?
  echo "project=${OPTIONS[project]-<unset>}"
  echo "type=${OPTIONS[type]-<unset>}"
  echo "force=${OPTIONS[force]-<unset>}"
  return "$rc"
}

# _apos_table_after_declare - args_positional project type を宣言し、_ARGS_POSITIONAL の内容を出力する
#
# @stdout _ARGS_POSITIONAL の要素を空白区切りで連結した文字列
_apos_table_after_declare() {
  args_init
  args_positional project type
  echo "${_ARGS_POSITIONAL[*]}"
}

# _parg_parse_mixed - フラグ・値・位置引数を宣言し、それらを混ぜた引数で parse_args を実行する
#
# @arg $@ string args parse_args に渡す引数
# @return parse_args の終了ステータス
_parg_parse_mixed() {
  args_init
  args_flag force --force
  args_value model sonnet --model
  args_positional project
  parse_args "$@"
}

# _parg_parse_after_stale_error - ARGS_ERROR に古いエラーを残したまま --force を解析する
#
# @arg $@ string args parse_args に渡す引数
# @return parse_args の終了ステータス
_parg_parse_after_stale_error() {
  args_init
  args_flag force --force
  ARGS_ERROR="old"
  parse_args "$@"
}

# _parg_parse_bare - 何も宣言せずに parse_args を実行する
#
# @arg $@ string args parse_args に渡す引数
# @return parse_args の終了ステータス
_parg_parse_bare() {
  args_init
  parse_args "$@"
}

# _parg_show_help - OPTIONS[SHOW_HELP] の値を出力する (When call の後に結果を読むアクセサ)
#
# @stdout OPTIONS[SHOW_HELP] の値 (未設定なら "<unset>")
_parg_show_help() {
  echo "${OPTIONS[SHOW_HELP]-<unset>}"
}

# _parg_print_set - 指定したキーごとに OPTIONS_SET の値を出力する
#
# @arg $@ string keys OPTIONS_SET のキー
# @stdout 1 キー 1 行: <key>=<OPTIONS_SET[key]> (未設定なら "<unset>")
_parg_print_set() {
  local key
  for key in "$@"; do
    echo "${key}=${OPTIONS_SET[$key]-<unset>}"
  done
}

# _parg_set_flag - args_flag force --force を宣言して parse_args を実行し、OPTIONS_SET[force] を出力する
#
# @arg $@ string args parse_args に渡す引数
# @stdout force=<OPTIONS_SET[force]>
# @return parse_args の終了ステータス
_parg_set_flag() {
  local rc=0
  args_init
  args_flag force --force
  parse_args "$@" || rc=$?
  _parg_print_set force
  return "$rc"
}

# _parg_set_value - args_value model sonnet -m --model を宣言して parse_args を実行し、値と OPTIONS_SET を出力する
#
# @arg $@ string args parse_args に渡す引数
# @stdout 1 行目: value=<OPTIONS[model]> / 2 行目: model=<OPTIONS_SET[model]> / 3 行目: -m=<OPTIONS_SET[-m]>
# @return parse_args の終了ステータス
_parg_set_value() {
  local rc=0
  args_init
  args_value model sonnet -m --model
  parse_args "$@" || rc=$?
  echo "value=${OPTIONS[model]-<unset>}"
  _parg_print_set model -m
  return "$rc"
}

# _parg_set_positional - args_positional project type を宣言して parse_args を実行し、OPTIONS_SET を出力する
#
# @arg $@ string args parse_args に渡す引数
# @stdout 1 行目: project=<OPTIONS_SET[project]> / 2 行目: type=<OPTIONS_SET[type]>
# @return parse_args の終了ステータス
_parg_set_positional() {
  local rc=0
  args_init
  args_positional project type
  parse_args "$@" || rc=$?
  _parg_print_set project type
  return "$rc"
}

# _parg_parse_flag - args_flag force <opt> を宣言して parse_args を実行する (無出力)
#
# @arg $1 string opt  宣言するオプション名
# @arg $@ string args parse_args に渡す引数
# @return parse_args の終了ステータス
_parg_parse_flag() {
  local opt="$1"
  shift
  args_init
  args_flag force "$opt"
  parse_args "$@"
}

# _parg_parse_value - args_value model sonnet --model を宣言して parse_args を実行する (無出力)
#
# @arg $@ string args parse_args に渡す引数
# @return parse_args の終了ステータス
_parg_parse_value() {
  args_init
  args_value model sonnet --model
  parse_args "$@"
}

# _parg_parse_file - args_positional file を宣言して parse_args を実行する (無出力)
#
# @arg $@ string args parse_args に渡す引数
# @return parse_args の終了ステータス
_parg_parse_file() {
  args_init
  args_positional file
  parse_args "$@"
}

# _aspl_parse - args_value model <default> --model を宣言して parse_args を実行し、値と OPTIONS_SET を出力する
#
# @arg $1 string default model の既定値
# @arg $@ string args    parse_args に渡す引数
# @stdout 1 行目: value=<OPTIONS[model]> / 2 行目: model=<OPTIONS_SET[model]>
# @return parse_args の終了ステータス
_aspl_parse() {
  local rc=0 default="$1"
  shift
  args_init
  args_value model "$default" --model
  parse_args "$@" || rc=$?
  echo "value=${OPTIONS[model]-<unset>}"
  _parg_print_set model
  return "$rc"
}

# _atkv_parse - args_value model sonnet -m --model を宣言して parse_args を実行する (無出力)
#
# @arg $@ string args parse_args に渡す引数
# @return parse_args の終了ステータス
_atkv_parse() {
  args_init
  args_value model sonnet -m --model
  parse_args "$@"
}

# _afix_parse_value - args_value model を宣言して parse_args を実行し OPTIONS_SET の model 有無を返す
#
# @arg $@ string args parse_args に渡す引数
# @stdout "set" または "unset"
_afix_parse_value() {
  args_init
  args_value model sonnet --model
  local rc=0
  parse_args "$@" || rc=$?
  if [[ -n "${OPTIONS_SET[model]+x}" ]]; then echo set; else echo unset; fi
  return "$rc"
}

# _afix_parse_flag - args_flag force と args_positional name を宣言して parse_args を実行する (無出力)
#
# @arg $@ string args parse_args に渡す引数
_afix_parse_flag() {
  args_init
  args_flag force --force
  args_positional name
  parse_args "$@"
}

# _apex_parse - args_positional project type を宣言して parse_args を実行する (無出力)
#
# @arg $@ string args parse_args に渡す引数
# @return parse_args の終了ステータス
_apex_parse() {
  args_init
  args_positional project type
  parse_args "$@"
}

# _apex_parse_undeclared - 位置引数を宣言せずに parse_args を実行する (無出力)
#
# @arg $@ string args parse_args に渡す引数
# @return parse_args の終了ステータス
_apex_parse_undeclared() {
  args_init
  parse_args "$@"
}

Describe "args.lib.sh"
  Describe "T-LIB-AINI: args_init"
    Describe "When: 正常系"
      It "Then: [Normal] T-LIB-AINI-01: 既存の _ARGS_KEY_OF を消す (T-01-01-01)"
        When call _aini_key_of_count_after_reinit
        The status should equal 0
        The output should equal "0"
        The stderr should equal ""
      End

      It "Then: [Normal] T-LIB-AINI-02: 既存の _ARGS_TYPE を消す (T-01-01-02)"
        When call _aini_type_count_after_reinit
        The status should equal 0
        The output should equal "0"
        The stderr should equal ""
      End

      It "Then: [Normal] T-LIB-AINI-03: 既存の _ARGS_POSITIONAL を消す (T-01-01-03)"
        When call _aini_positional_count_after_reinit
        The status should equal 0
        The output should equal "0"
        The stderr should equal ""
      End

      It "Then: [Normal] T-LIB-AINI-04: 古い OPTIONS のキーを消す (T-01-01-04)"
        When call _aini_options_stale_after_reinit
        The status should equal 0
        The output should equal "unset"
        The stderr should equal ""
      End

      It "Then: [Normal] T-LIB-AINI-05: 古い OPTIONS_SET のキーを消す (T-01-01-05)"
        When call _aini_options_set_stale_after_reinit
        The status should equal 0
        The output should equal "unset"
        The stderr should equal ""
      End

      It "Then: [Normal] T-LIB-AINI-06: ARGS_ERROR を空にして 0 を返す (T-01-01-06)"
        ARGS_ERROR="old"
        When call args_init
        The status should equal 0
        The variable ARGS_ERROR should equal ""
      End
    End

    Describe "When: エッジケース"
      It "Then: [Edge] T-LIB-AINI-07: set -u の新規 bash で source 直後に呼ぶとグローバル連想配列ができる (T-01-02-01)"
        When run bash -u -c '. "$1"; args_init; declare -p OPTIONS OPTIONS_SET _ARGS_KEY_OF _ARGS_TYPE' _ "${SCRIPT}"
        The status should equal 0
        The line 1 of output should start with "declare -A OPTIONS"
        The line 2 of output should start with "declare -A OPTIONS_SET"
        The line 3 of output should start with "declare -A _ARGS_KEY_OF"
        The line 4 of output should start with "declare -A _ARGS_TYPE"
        The stderr should equal ""
      End

      It "Then: [Edge] T-LIB-AINI-08: 関数内から呼んでも OPTIONS がグローバル連想配列として残る (T-01-02-02)"
        When call _aini_init_inside_function
        The status should equal 0
        The line 1 of output should equal "v"
        The line 2 of output should start with "declare -A OPTIONS"
        The stderr should equal ""
      End
    End

    Describe "When: 状態遷移"
      It "Then: [Normal] T-LIB-AINI-09: 再初期化後は 1 回目の宣言 --force が未知になる (T-01-03-01)"
        When call _aini_parse_after_reinit
        The status should equal 1
        The variable ARGS_ERROR should equal "Unknown option: --force"
        The output should equal ""
        The stderr should equal ""
      End
    End
  End
  Describe "T-LIB-AFLG: args_flag"
    Describe "When: 正常系"
      It "Then: [Normal] T-LIB-AFLG-01: 未指定なら false (T-02-01-01)"
        When call _aflg_parse_force "--force"
        The status should equal 0
        The output should equal "false"
        The stderr should equal ""
      End

      It "Then: [Normal] T-LIB-AFLG-02: --force を指定すると true (T-02-01-02)"
        When call _aflg_parse_force "--force" --force
        The status should equal 0
        The output should equal "true"
        The stderr should equal ""
      End

      It "Then: [Normal] T-LIB-AFLG-03: 別名 -f を指定しても同じキーが true (T-02-01-03)"
        When call _aflg_parse_force "-f --force" -f
        The status should equal 0
        The output should equal "true"
        The stderr should equal ""
      End

      It "Then: [Normal] T-LIB-AFLG-04: 内部テーブルに flag 型と全別名が登録される (T-02-01-04)"
        When call _aflg_tables_after_declare
        The status should equal 0
        The line 1 of output should equal "flag"
        The line 2 of output should equal "force"
        The line 3 of output should equal "force"
        The stderr should equal ""
      End
    End

    Describe "When: エッジケース"
      It "Then: [Edge] T-LIB-AFLG-05: 同じフラグを 2 回指定しても true のまま成功する (T-02-02-01)"
        When call _aflg_parse_force "--force" --force --force
        The status should equal 0
        The output should equal "true"
        The variable ARGS_ERROR should equal ""
        The stderr should equal ""
      End
    End
  End
  Describe "T-LIB-AVAL: args_value"
    Describe "When: 正常系"
      It "Then: [Normal] T-LIB-AVAL-01: 未指定なら既定値 (T-03-01-01)"
        When call _aval_parse model sonnet "--model"
        The status should equal 0
        The output should equal "sonnet"
        The stderr should equal ""
      End

      It "Then: [Normal] T-LIB-AVAL-02: 空文字の既定値はそのまま空 (T-03-01-02)"
        When call _aval_parse model "" "--model"
        The status should equal 0
        The output should equal ""
        The stderr should equal ""
      End

      It "Then: [Normal] T-LIB-AVAL-03: 空白区切りで渡した値で既定値を上書きする (T-03-01-03)"
        When call _aval_parse model sonnet "--model" --model opus
        The status should equal 0
        The output should equal "opus"
        The stderr should equal ""
      End

      It "Then: [Normal] T-LIB-AVAL-04: 短い別名 -m でも同じキーに入る (T-03-01-04)"
        When call _aval_parse model sonnet "-m --model --ai-model" -m opus
        The status should equal 0
        The output should equal "opus"
        The stderr should equal ""
      End

      It "Then: [Normal] T-LIB-AVAL-05: 3 つ目の別名 --ai-model でも同じキーに入る (T-03-01-05)"
        When call _aval_parse model sonnet "-m --model --ai-model" --ai-model haiku
        The status should equal 0
        The output should equal "haiku"
        The stderr should equal ""
      End

      It "Then: [Normal] T-LIB-AVAL-06: 内部テーブルに value 型と全別名が登録される (T-03-01-06)"
        When call _aval_tables_after_declare
        The status should equal 0
        The line 1 of output should equal "value"
        The line 2 of output should equal "model"
        The line 3 of output should equal "model"
        The stderr should equal ""
      End
    End

    Describe "When: エッジケース"
      It "Then: [Edge] T-LIB-AVAL-07: 空白を含む値をそのまま保持する (T-03-02-01)"
        When call _aval_parse msg "" "--msg" --msg "a b"
        The status should equal 0
        The output should equal "a b"
        The stderr should equal ""
      End
    End
  End
  Describe "T-LIB-APOS: args_positional"
    Describe "When: 正常系"
      It "Then: [Normal] T-LIB-APOS-01: 宣言数ちょうどの位置引数を宣言順に割り当てる (T-04-01-01)"
        When call _apos_parse foo bar
        The status should equal 0
        The line 1 of output should equal "project=foo"
        The line 2 of output should equal "type=bar"
        The stderr should equal ""
      End

      It "Then: [Normal] T-LIB-APOS-02: 足りない位置引数は空文字になる (T-04-01-02)"
        When call _apos_parse foo
        The status should equal 0
        The line 1 of output should equal "project=foo"
        The line 2 of output should equal "type="
        The stderr should equal ""
      End

      It "Then: [Normal] T-LIB-APOS-03: 内部テーブルに宣言順で登録される (T-04-01-03)"
        When call _apos_table_after_declare
        The status should equal 0
        The output should equal "project type"
        The stderr should equal ""
      End
    End

    Describe "When: エッジケース"
      It "Then: [Edge] T-LIB-APOS-04: 位置引数を 1 つも渡さなければ全キーが空文字 (T-04-02-01)"
        When call _apos_parse
        The status should equal 0
        The line 1 of output should equal "project="
        The line 2 of output should equal "type="
        The stderr should equal ""
      End

      It "Then: [Edge] T-LIB-APOS-05: オプションを挟んでも位置引数の順序を保つ (T-04-02-02)"
        When call _apos_parse_with_force foo --force bar
        The status should equal 0
        The line 1 of output should equal "project=foo"
        The line 2 of output should equal "type=bar"
        The line 3 of output should equal "force=true"
        The stderr should equal ""
      End
    End
  End
  Describe "T-LIB-PARG: parse_args"
    Describe "When: 正常系"
      It "Then: [Normal] T-LIB-PARG-01: フラグ・値・位置引数を混ぜた成功呼び出しは 0 を返し無出力 (T-05-01-01)"
        When call _parg_parse_mixed --force --model opus foo
        The status should equal 0
        The output should equal ""
        The stderr should equal ""
        The variable ARGS_ERROR should equal ""
      End

      It "Then: [Normal] T-LIB-PARG-02: 直前のエラーが成功時に残らない (T-05-01-02)"
        When call _parg_parse_after_stale_error --force
        The status should equal 0
        The variable ARGS_ERROR should equal ""
      End

      It "Then: [Normal] T-LIB-PARG-03: --help で SHOW_HELP=true を立て無出力で 0 を返す (T-05-02-01)"
        When call _parg_parse_bare --help
        The status should equal 0
        The result of function _parg_show_help should equal "true"
        The output should equal ""
        The stderr should equal ""
      End

      It "Then: [Normal] T-LIB-PARG-04: -h で SHOW_HELP=true を立てて 0 を返す (T-05-02-02)"
        When call _parg_parse_bare -h
        The status should equal 0
        The result of function _parg_show_help should equal "true"
      End

      It "Then: [Normal] T-LIB-PARG-05: help を渡さなければ SHOW_HELP=false (T-05-02-03)"
        When call _parg_parse_bare
        The status should equal 0
        The result of function _parg_show_help should equal "false"
      End

      It "Then: [Normal] T-LIB-PARG-06: help の後ろの未知オプションは評価せず即 0 を返す (T-05-02-04)"
        When call _parg_parse_bare --help --bogus
        The status should equal 0
        The result of function _parg_show_help should equal "true"
        The variable ARGS_ERROR should equal ""
      End

      It "Then: [Normal] T-LIB-PARG-07: 指定したフラグは OPTIONS_SET が true (T-05-03-01)"
        When call _parg_set_flag --force
        The status should equal 0
        The output should equal "force=true"
      End

      It "Then: [Normal] T-LIB-PARG-08: 未指定のフラグは OPTIONS_SET に無い (T-05-03-02)"
        When call _parg_set_flag
        The status should equal 0
        The output should equal "force=<unset>"
      End

      It "Then: [Normal] T-LIB-PARG-09: 既定値のままの値オプションは OPTIONS_SET に無い (T-05-03-03)"
        When call _parg_set_value
        The status should equal 0
        The line 1 of output should equal "value=sonnet"
        The line 2 of output should equal "model=<unset>"
      End

      It "Then: [Normal] T-LIB-PARG-10: 別名で指定した値オプションはキー名で OPTIONS_SET が true (T-05-03-04)"
        When call _parg_set_value -m opus
        The status should equal 0
        The line 2 of output should equal "model=true"
        The line 3 of output should equal "-m=<unset>"
      End

      It "Then: [Normal] T-LIB-PARG-11: 渡された位置引数だけ OPTIONS_SET が true (T-05-03-05)"
        When call _parg_set_positional foo
        The status should equal 0
        The line 1 of output should equal "project=true"
        The line 2 of output should equal "type=<unset>"
      End
    End

    Describe "When: 異常系"
      It "Then: [Error] T-LIB-PARG-12: 未知の長いオプションは 1 を返し無出力でエラーを設定する (T-05-04-01)"
        When call _parg_parse_flag --force --bogus
        The status should equal 1
        The variable ARGS_ERROR should equal "Unknown option: --bogus"
        The output should equal ""
        The stderr should equal ""
      End

      It "Then: [Error] T-LIB-PARG-13: 未知の短いオプションは 1 を返しエラーを設定する (T-05-04-02)"
        When call _parg_parse_flag -f -x
        The status should equal 1
        The variable ARGS_ERROR should equal "Unknown option: -x"
      End

      It "Then: [Error] T-LIB-PARG-14: 正しい値オプションの後ろに続く未知オプションでも 1 を返す (T-05-04-03)"
        When call _parg_parse_value --model opus --bogus
        The status should equal 1
        The variable ARGS_ERROR should equal "Unknown option: --bogus"
      End
    End

    Describe "When: エッジケース"
      It "Then: [Edge] T-LIB-PARG-15: 単独の \"-\" は位置引数ではなく未知オプション (T-05-05-01)"
        When call _parg_parse_file -
        The status should equal 1
        The variable ARGS_ERROR should equal "Unknown option: -"
      End
    End

    Describe "When: 状態遷移 (呼び出し側の strict mode)"
      It "Then: [Normal] T-LIB-PARG-16: set -eo pipefail の呼び出し側でエラーが返っても後続が動く (T-05-06-01)"
        When run bash -c 'set -eo pipefail; . "$1"; args_init; rc=0; parse_args --bogus || rc=$?; echo "after rc=$rc"' _ "${SCRIPT}"
        The status should equal 0
        The output should equal "after rc=1"
      End

      It "Then: [Edge] T-LIB-PARG-17: set -u で位置引数宣言なし・引数なしで呼んでも unbound にならない (T-05-06-02)"
        When run bash -u -c '. "$1"; args_init; parse_args; echo ok' _ "${SCRIPT}"
        The status should equal 0
        The output should equal "ok"
        The stderr should equal ""
      End

      It "Then: [Edge] T-LIB-PARG-18: set -u で未指定の値・位置引数を参照しても unbound にならない (T-05-06-03)"
        When run bash -u -c '. "$1"; args_init; args_value model "" --model; args_positional project; parse_args; echo "[${OPTIONS[model]}][${OPTIONS[project]}]"' _ "${SCRIPT}"
        The status should equal 0
        The output should equal "[][]"
        The stderr should equal ""
      End

      It "Then: [Error] T-LIB-PARG-19: エラーでも呼び出し元のシェルを exit しない (T-05-06-04)"
        When run bash -c '. "$1"; args_init; parse_args --bogus; echo still-running' _ "${SCRIPT}"
        The output should equal "still-running"
      End
    End

    Describe "When: FN確認 (静的検査)"
      It "Then: [Normal] T-LIB-PARG-20: ライブラリ本文に exit 文が無い (T-05-07-01)"
        When run grep -nE '(^|[;&[:space:]])exit([[:space:]]|$)' "${SCRIPT}"
        The status should equal 1
        The output should equal ""
      End
    End
  End

  Describe "T-LIB-ASPL: --name=value 分割 (_args_option, parse_args 経由)"
    Describe "When: 正常系"
      It "Then: [Normal] T-LIB-ASPL-01: --model=opus を名前と値に分けて値を取る (T-06-01-01)"
        When call _aspl_parse sonnet --model=opus
        The status should equal 0
        The line 1 of output should equal "value=opus"
        The line 2 of output should equal "model=true"
      End
    End

    Describe "When: エッジケース"
      It "Then: [Edge] T-LIB-ASPL-02: 値に \"=\" を含むときは最初の \"=\" だけで分割する (T-06-02-01)"
        When call _aspl_parse "" --model=a=b
        The status should equal 0
        The line 1 of output should equal "value=a=b"
      End
    End
  End

  Describe "T-LIB-ATKV: _args_take_value (parse_args 経由)"
    Describe "When: 異常系"
      It "Then: [Error] T-LIB-ATKV-01: 値オプションが最後で次の引数が無いと 1 を返し無出力でエラーを設定する (T-07-01-01)"
        When call _atkv_parse --model
        The status should equal 1
        The variable ARGS_ERROR should equal "--model requires a value"
        The output should equal ""
        The stderr should equal ""
      End

      It "Then: [Error] T-LIB-ATKV-02: 次の引数が空文字なら 1 を返しエラーを設定する (T-07-01-02)"
        When call _atkv_parse --model ""
        The status should equal 1
        The variable ARGS_ERROR should equal "--model requires a value"
      End

      It "Then: [Error] T-LIB-ATKV-03: --model= (空値) 形式なら 1 を返しエラーを設定する (T-07-01-03)"
        When call _atkv_parse --model=
        The status should equal 1
        The variable ARGS_ERROR should equal "--model requires a value"
      End
    End

    Describe "When: エッジケース"
      It "Then: [Edge] T-LIB-ATKV-04: エラー文言は実際に渡した短い別名 -m を使う (T-07-02-01)"
        When call _atkv_parse -m
        The status should equal 1
        The variable ARGS_ERROR should equal "-m requires a value"
      End
    End
  End

  Describe "T-LIB-APEX: _args_positional (parse_args 経由)"
    Describe "When: 異常系"
      It "Then: [Error] T-LIB-APEX-01: 宣言数 +1 個の位置引数は 1 を返し無出力で \"Unexpected argument: baz\" を設定する (T-08-01-01)"
        When call _apex_parse foo bar baz
        The status should equal 1
        The variable ARGS_ERROR should equal "Unexpected argument: baz"
        The output should equal ""
        The stderr should equal ""
      End
    End

    Describe "When: エッジケース"
      It "Then: [Edge] T-LIB-APEX-02: 位置引数を宣言していなければ 1 個目で \"Unexpected argument: foo\" を設定する (T-08-02-01)"
        When call _apex_parse_undeclared foo
        The status should equal 1
        The variable ARGS_ERROR should equal "Unexpected argument: foo"
      End
    End
  End

  Describe "T-LIB-AFIX: parse_args 修正"
    Describe "When: 異常系"
      It "Then: [Error] T-LIB-AFIX-01: 値の無い --model は OPTIONS_SET に model を残さない (FIX-01)"
        When call _afix_parse_value --model
        The status should equal 1
        The variable ARGS_ERROR should equal "--model requires a value"
        The output should equal "unset"
      End

      It "Then: [Error] T-LIB-AFIX-02: --model= も OPTIONS_SET に model を残さない (FIX-01)"
        When call _afix_parse_value --model=
        The status should equal 1
        The variable ARGS_ERROR should equal "--model requires a value"
        The output should equal "unset"
      End

      It "Then: [Error] T-LIB-AFIX-03: フラグに =value を付けると 1 を返し無出力でエラーを設定する (FIX-02)"
        When call _afix_parse_flag --force=yes
        The status should equal 1
        The variable ARGS_ERROR should equal "--force does not take a value"
        The variable "OPTIONS[name]" should equal ""
        The output should equal ""
        The stderr should equal ""
      End

      It "Then: [Error] T-LIB-AFIX-04: 未知オプションの = 形式は = の前の名前で報告する (FIX-02)"
        When call _afix_parse_flag --x=1
        The status should equal 1
        The variable ARGS_ERROR should equal "Unknown option: --x"
      End
    End

    Describe "When: 正常系"
      It "Then: [Normal] T-LIB-AFIX-05: --force 単独は従来どおり true になる (FIX-02)"
        When call _afix_parse_flag --force
        The status should equal 0
        The variable "OPTIONS[force]" should equal "true"
      End
    End
  End
End
