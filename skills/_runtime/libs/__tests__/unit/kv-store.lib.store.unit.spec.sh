#!/usr/bin/env bash
# kv-store.lib.store.spec.sh - ShellSpec unit tests for kv-store.lib.sh (schema and store operations)
#
# Copyright (c) 2026- atsushifx <https://github.com/atsushifx>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

# shellcheck disable=SC1090,SC1091,SC2288,SC2289
# cspell:words reinit eqval uninit nofile emptyjson roundtrip noschema

_RUNTIME_LIBS_DIR="$(cd "${SHELLSPEC_PROJECT_ROOT}/skills/_runtime/libs" && pwd)"

Include "../spec_helper.sh"

. "${_RUNTIME_LIBS_DIR}/bootstrap.lib.sh" --no-finalize
. "${_RUNTIME_LIBS_DIR}/kv-store.lib.sh"

Describe "kv-store.lib.sh (store)"

  Describe "_kv_normalize_key"
    Describe "Given: 有効なキー名"
      Describe "When: _kv_normalize_key を呼ぶ"
        Parameters
          "name"
          "_key"
          "key1"
          "Key_Name"
          "_123"
        End

        It "Then: [Normal] '$1' は return 0 かつ正規化済みキーを返す"
          When call _kv_normalize_key "$1"
          The status should equal 0
          The output should equal "$1"
        End
      End
    End

    Describe "Given: 前後に空白を含むキー名"
      Describe "When: _kv_normalize_key を呼ぶ"
        It "Then: [Normal] ' name ' は return 0 かつ 'name' を返す"
          When call _kv_normalize_key " name "
          The status should equal 0
          The output should equal "name"
        End

        It "Then: [Normal] '  _key  ' は return 0 かつ '_key' を返す"
          When call _kv_normalize_key "  _key  "
          The status should equal 0
          The output should equal "_key"
        End

        It "Then: [Normal] $'\\tkey1\\t' は return 0 かつ 'key1' を返す"
          When call _kv_normalize_key $'\tkey1\t'
          The status should equal 0
          The output should equal "key1"
        End
      End
    End

    Describe "Given: 無効なキー名 (空文字)"
      Describe "When: _kv_normalize_key を呼ぶ"
        It "Then: [Error] 空文字は return 1 かつ 'must not be empty' を出力する"
          When call _kv_normalize_key ""
          The status should equal 1
          The stderr should include "Error: _kv_normalize_key: key must not be empty"
        End
      End
    End

    Describe "Given: 無効なキー名 (不正文字)"
      Describe "When: _kv_normalize_key を呼ぶ"
        Parameters
          "my key"
          "my.key"
          "a,b"
          "a/b"
          "1key"
          "my-key"
        End

        It "Then: [Error] '$1' は return 1 かつ 'invalid key' を出力する"
          When call _kv_normalize_key "$1"
          The status should equal 1
          The stderr should include "Error: _kv_normalize_key: invalid key: '$1'"
        End
      End
    End
  End

  Describe "kv_init"
    Describe "Given: 複数キーのスキーマ"
      Describe "When: kv_init を呼ぶ"
        It "Then: [Normal] スキーマが登録される"
          kv_init "mystore" $'key1|val1\nkey2|val2'
          When call test -n "${_KV_SCHEMA[mystore]}"
          The status should equal 0
        End

        It "Then: [Normal] key1 のデフォルト値 val1 が設定される"
          kv_init "mystore" $'key1|val1\nkey2|val2'
          When call kv_get "mystore" "key1"
          The status should equal 0
          The output should equal "val1"
        End

        It "Then: [Normal] key2 のデフォルト値 val2 が設定される"
          kv_init "mystore" $'key1|val1\nkey2|val2'
          When call kv_get "mystore" "key2"
          The status should equal 0
          The output should equal "val2"
        End

        It "Then: [Edge] デフォルト値が空のキーは空文字になる"
          kv_init "emptystore" $'key1|\nkey2|default2'
          When call kv_get "emptystore" "key1"
          The status should equal 0
          The output should equal ""
        End

        It "Then: [Edge] スペースを含むデフォルト値がそのまま設定される"
          kv_init "space_store" "key1|hello world"
          When call kv_get "space_store" "key1"
          The status should equal 0
          The output should equal "hello world"
        End

        It "Then: [Edge] = を含むデフォルト値がそのまま設定される"
          kv_init "eq_store" "key1|a=b"
          When call kv_get "eq_store" "key1"
          The status should equal 0
          The output should equal "a=b"
        End

        It "Then: [Edge] 前後に空白を含むキー名は normalize されてデフォルト値が設定される"
          kv_init "trim_store" " key1 |val1"
          When call kv_get "trim_store" "key1"
          The status should equal 0
          The output should equal "val1"
        End
      End
    End

    Describe "Given: 1キーのみのスキーマ"
      Describe "When: kv_init を呼ぶ"
        It "Then: [Normal] key1 にデフォルト値が設定される"
          kv_init "onekey_store" "key1|val1"
          When call kv_get "onekey_store" "key1"
          The status should equal 0
          The output should equal "val1"
        End

        It "Then: [Error] スキーマ外キーは return 1 かつ 'Error: kv_get:' を出力する"
          kv_init "onekey_store2" "key1|val1"
          When call kv_get "onekey_store2" "other_key"
          The status should equal 1
          The stderr should include "Error: kv_get:"
        End
      End
    End

    Describe "Given: 空スキーマ"
      Describe "When: kv_init を呼ぶ"
        It "Then: [Error] 空スキーマは return 1 かつ stderr に Error: を出力する"
          When call kv_init "emptyschema_store" ""
          The status should equal 1
          The stderr should include "Error:"
        End

        It "Then: [Error] 空スキーマはストアが登録されない"
          kv_init "emptyschema_store2" "" 2>/dev/null || true
          When call test -z "${_KV_SCHEMA[emptyschema_store2]+set}"
          The status should equal 0
        End
      End
    End

    Describe "Given: 既存ストアを再初期化する"
      Describe "When: kv_set 後に kv_init を呼ぶ"
        It "Then: [Normal] デフォルト値にリセットされる"
          kv_init "reinit_store" "key1|original"
          kv_set "reinit_store" "key1" "modified"
          kv_init "reinit_store" "key1|original"
          When call kv_get "reinit_store" "key1"
          The status should equal 0
          The output should equal "original"
        End

        It "Then: [Normal] スキーマが新しい内容に更新される"
          kv_init "reinit_store2" "key1|val1"
          kv_init "reinit_store2" $'key1|new1\nkey2|new2'
          When call kv_get "reinit_store2" "key2"
          The status should equal 0
          The output should equal "new2"
        End
      End
    End

    Describe "Given: 不正なキーを含むスキーマ"
      Describe "When: kv_init を呼ぶ"
        Parameters
          "my key|val"
          "my.key|val"
          "a,b|val"
          "a/b|val"
          "1key|val"
          "my-key|val"
          "|val"
        End

        It "Then: [Error] '$1' は return 1 かつ stderr に Error: を出力する"
          When call kv_init "badkey_store" "$1"
          The status should equal 1
          The stderr should include "Error:"
        End
      End

      Describe "When: kv_init を呼ぶ (複数キー中に 1 つ不正)"
        It "Then: [Error] 複数キー中に 1 つ不正があれば return 1 かつ stderr に Error: を出力する"
          When call kv_init "badkey_store_multi" $'valid_key|val1\nmy-key|val2'
          The status should equal 1
          The stderr should include "Error:"
        End

        It "Then: [Edge] 不正キーがあってもストアのスキーマは登録されない"
          kv_init "no_init_store" "bad.key|val" 2>/dev/null || true
          When call test -z "${_KV_SCHEMA[no_init_store]+set}"
          The status should equal 0
        End
      End
    End
  End

  Describe "kv_get"
    Describe "Given: 初期化済みストア"
      Before "kv_init 'get_store' $'name|alice\nage|30'"

      Describe "When: kv_get を呼ぶ"
        It "Then: [Normal] デフォルト値が返る"
          When call kv_get "get_store" "name"
          The status should equal 0
          The output should equal "alice"
        End

        It "Then: [Normal] kv_set 後の値が返る"
          kv_set "get_store" "name" "bob"
          When call kv_get "get_store" "name"
          The status should equal 0
          The output should equal "bob"
        End

        It "Then: [Error] スキーマ外キーは return 1 かつ 'Error: kv_get:' を出力する"
          When call kv_get "get_store" "no_such_key"
          The status should equal 1
          The stderr should include "Error: kv_get:"
        End

        It "Then: [Edge] スペースを含む値がそのまま返る"
          kv_set "get_store" "name" "hello world"
          When call kv_get "get_store" "name"
          The status should equal 0
          The output should equal "hello world"
        End

        It "Then: [Edge] タブを含む値がそのまま返る"
          kv_set "get_store" "name" $'hello\tworld'
          When call kv_get "get_store" "name"
          The status should equal 0
          The output should equal $'hello\tworld'
        End

        It "Then: [Error] スキーマ外キーを kv_set すると return 1 かつ 'Error: kv_set:' を出力する"
          When call kv_set "get_store" "extra_key" "extra_val"
          The status should equal 1
          The stderr should include "Error: kv_set:"
        End

        It "Then: [Error] スキーマ外キーを kv_get すると return 1 かつ 'Error: kv_get:' を出力する"
          When call kv_get "get_store" "undefined_extra"
          The status should equal 1
          The stderr should include "Error: kv_get:"
        End
      End
    End

    Describe "Given: ストア未初期化の状態"
      Describe "When: kv_get を呼ぶ"
        It "Then: [Edge] 未初期化ストアへの kv_get は return 0 かつ空文字を返す"
          When call kv_get "uninit_get_store" "key1"
          The status should equal 0
          The output should equal ""
        End

        It "Then: [Edge] キー引数なしで kv_get を呼ぶと return 1 かつ 'Error:' を出力する"
          When call kv_get "uninit_get_store" ""
          The status should equal 1
          The stderr should include "Error:"
        End
      End
    End

    Describe "Given: 前後に空白を含むキーを kv_get する"
      Before "kv_init 'norm_get_store' $'name|alice\nage|30'"

      Describe "When: kv_get を呼ぶ"
        Parameters
          " name "    "alice"
          "  name  " "alice"
          $'\tname\t' "alice"
          " age "     "30"
        End

        It "Then: [Normal] '$1' が normalize されて正しい値が返る"
          When call kv_get "norm_get_store" "$1"
          The status should equal 0
          The output should equal "$2"
        End
      End
    End

    Describe "Given: 不正なキー名を kv_get する"
      Before "kv_init 'invalid_get_store' 'name|alice'"

      Describe "When: kv_get を呼ぶ"
        Parameters
          "my-key"
          "1key"
          "my.key"
          "a/b"
        End

        It "Then: [Error] '$1' は return 1 かつ 'Error:' を出力する"
          When call kv_get "invalid_get_store" "$1"
          The status should equal 1
          The stderr should include "Error:"
        End
      End
    End
  End

  Describe "kv_set"
    Describe "Given: 初期化済みストア"
      Before "kv_init 'set_store' $'name|alice\nage|30'"

      Describe "When: kv_set を呼ぶ"
        It "Then: [Error] スキーマ外の新規キーをセットすると return 1 かつ 'Error: kv_set:' を出力する"
          When call kv_set "set_store" "newkey" "newval"
          The status should equal 1
          The stderr should include "Error: kv_set:"
        End

        It "Then: [Normal] 既存キーを上書きできる"
          kv_set "set_store" "name" "bob"
          When call kv_get "set_store" "name"
          The status should equal 0
          The output should equal "bob"
        End

        It "Then: [Edge] 空文字をセットできる"
          kv_set "set_store" "name" ""
          When call kv_get "set_store" "name"
          The status should equal 0
          The output should equal ""
        End

        It "Then: [Edge] 値引数なしで呼ぶと空文字がセットされる"
          # value=${3:-} の仕様: 引数省略 → 空文字
          kv_set "set_store" "name"
          When call kv_get "set_store" "name"
          The status should equal 0
          The output should equal ""
        End

        It "Then: [Error] スキーマ外キーを kv_set すると return 1 かつ 'Error: kv_set:' を出力する"
          When call kv_set "set_store" "extra_for_all" "extra_val"
          The status should equal 1
          The stderr should include "Error: kv_set:"
        End
      End

      Describe "When: 特殊文字を含む値を kv_set する"
        Parameters
          "twenty five"
          "a|b"
          "a=b"
        End

        It "Then: [Edge] '$1' を含む値がセットできる"
          kv_set "set_store" "age" "$1"
          When call kv_get "set_store" "age"
          The status should equal 0
          The output should equal "$1"
        End
      End
    End

    Describe "Given: ストア未初期化の状態"
      Describe "When: kv_set を呼ぶ"
        It "Then: [Edge] 未初期化ストアへの kv_set は return 0 を返す"
          When call kv_set "uninit_set_store" "key1" "val"
          The status should equal 0
        End

        It "Then: [Edge] キー引数なしで kv_set を呼ぶと return 1 かつ 'Error:' を出力する"
          When call kv_set "uninit_set_store2" "" "val"
          The status should equal 1
          The stderr should include "Error:"
        End
      End
    End

    Describe "Given: 前後に空白を含むキーを kv_set する"
      Before "kv_init 'norm_set_store' 'name|alice'"

      Describe "When: kv_set を呼ぶ"
        It "Then: [Normal] ' name ' が normalize されて 'name' キーで値がセットされる"
          kv_set "norm_set_store" " name " "bob"
          When call kv_get "norm_set_store" "name"
          The status should equal 0
          The output should equal "bob"
        End
      End
    End

    Describe "Given: 不正なキー名を kv_set する"
      Before "kv_init 'invalid_set_store' 'name|alice'"

      Describe "When: kv_set を呼ぶ"
        Parameters
          "my-key"
          "1key"
          "my.key"
        End

        It "Then: [Error] '$1' は return 1 かつ 'Error:' を出力する"
          When call kv_set "invalid_set_store" "$1" "val"
          The status should equal 1
          The stderr should include "Error:"
        End
      End
    End
  End

  Describe "kv_all"
    Describe "Given: 複数キーを持つ初期化済みストア"
      Before "kv_init 'allstore' $'name|alice\ncity|tokyo'"

      Describe "When: kv_all を呼ぶ"
        It "Then: [Normal] name=alice が出力に含まれる"
          When call kv_all "allstore"
          The status should equal 0
          The output should include "name=alice"
        End

        It "Then: [Normal] city=tokyo が出力に含まれる"
          When call kv_all "allstore"
          The status should equal 0
          The output should include "city=tokyo"
        End
      End

      Describe "When: kv_set 後に kv_all を呼ぶ"
        It "Then: [Normal] 更新された name=bob が出力に含まれる"
          kv_set "allstore" "name" "bob"
          When call kv_all "allstore"
          The status should equal 0
          The output should include "name=bob"
        End

        It "Then: [Normal] 更新されていない city=tokyo は出力に含まれる"
          kv_set "allstore" "name" "bob"
          When call kv_all "allstore"
          The status should equal 0
          The output should include "city=tokyo"
        End
      End
    End

    Describe "Given: = を含む値がセットされた状態"
      Before "kv_init 'eqval_store' 'key1|a=b'"

      Describe "When: kv_all を呼ぶ"
        It "Then: [Edge] key1=a=b が出力に含まれる"
          When call kv_all "eqval_store"
          The status should equal 0
          The output should include "key1=a=b"
        End
      End
    End

    Describe "Given: ストア未初期化の状態"
      Describe "When: kv_all を呼ぶ"
        It "Then: [Edge] return 0 かつ空出力になる"
          When call kv_all "uninit_all_store"
          The status should equal 0
          The lines of output should equal 0
        End
      End
    End
  End

  Describe "kv_load"
    Describe "Given: スキーマ未登録のストア"
      Describe "When: kv_load を呼ぶ"
        It "Then: [Error] return 1 かつ stderr に 'Error: kv_load:' を出力する"
          When call kv_load "noschema_load_store" "/tmp/dummy"
          The status should equal 1
          The stderr should include "Error: kv_load:"
        End
      End
    End

    Describe "Given: ファイルが存在しない状態"
      Before "setup_tmpdir; kv_init 'nofile_load_store' $'key1|default1\nkey2|default2'"
      After "teardown_tmpdir"

      Describe "When: kv_load を呼ぶ (ファイルなし)"
        It "Then: [Normal] return 0 を返す"
          When call kv_load "nofile_load_store" "${NAMING_TMPDIR}/nonexistent"
          The status should equal 0
        End

        Parameters
          "key1"  "default1"
          "key2"  "default2"
        End

        It "Then: [Normal] $1 がデフォルト値で初期化される"
          kv_load "nofile_load_store" "${NAMING_TMPDIR}/nonexistent"
          When call kv_get "nofile_load_store" "$1"
          The status should equal 0
          The output should equal "$2"
        End
      End
    End

    Describe "Given: 有効な JSON ファイルが存在する"
      Before "setup_tmpdir; kv_init 'valid_json_store' $'key1|default1\nkey2|default2'"
      After "teardown_tmpdir"

      Describe "When: kv_load を呼ぶ"
        Parameters
          "key1"  "loaded1"
          "key2"  "loaded2"
        End

        It "Then: [Normal] $1 が JSON から読み込まれる"
          printf '%s' '{"key1":"loaded1","key2":"loaded2"}' > "${NAMING_TMPDIR}/valid.kv"
          kv_load "valid_json_store" "${NAMING_TMPDIR}/valid"
          When call kv_get "valid_json_store" "$1"
          The status should equal 0
          The output should equal "$2"
        End
      End

      Describe "When: kv_load を呼ぶ (部分的な JSON)"
        It "Then: [Normal] JSON に存在しないキーはデフォルト値になる"
          printf '%s' '{"key1":"only_key1"}' > "${NAMING_TMPDIR}/partial.kv"
          kv_load "valid_json_store" "${NAMING_TMPDIR}/partial"
          When call kv_get "valid_json_store" "key2"
          The status should equal 0
          The output should equal "default2"
        End
      End
    End

    Describe "Given: 無効な JSON ファイルが存在する"
      Before "setup_tmpdir; kv_init 'invalid_json_store' $'key1|default1'"
      After "teardown_tmpdir"

      Describe "When: kv_load を呼ぶ"
        It "Then: [Error] return 1 を返す"
          printf '%s' 'this is not json' > "${NAMING_TMPDIR}/broken.kv"
          When call kv_load "invalid_json_store" "${NAMING_TMPDIR}/broken"
          The status should equal 1
          The stderr should include "Error: kv_load:"
        End

        It "Then: [Error] stdout に 'Error: kv_load:' を出力する"
          printf '%s' 'this is not json' > "${NAMING_TMPDIR}/broken.kv"
          When call kv_load "invalid_json_store" "${NAMING_TMPDIR}/broken"
          The status should equal 1
          The stderr should include "Error: kv_load:"
        End
      End
    End

    Describe "Given: 空 JSON {} のファイルが存在する"
      Before "setup_tmpdir; kv_init 'emptyjson_load_store' $'key1|def1\nkey2|def2'"
      After "teardown_tmpdir"

      Describe "When: kv_load を呼ぶ"
        It "Then: [Edge] return 0 を返す"
          printf '%s' '{}' > "${NAMING_TMPDIR}/empty.kv"
          When call kv_load "emptyjson_load_store" "${NAMING_TMPDIR}/empty"
          The status should equal 0
        End

        Parameters
          "key1"  "def1"
          "key2"  "def2"
        End

        It "Then: [Edge] $1 はデフォルト値になる"
          printf '%s' '{}' > "${NAMING_TMPDIR}/empty.kv"
          kv_load "emptyjson_load_store" "${NAMING_TMPDIR}/empty"
          When call kv_get "emptyjson_load_store" "$1"
          The status should equal 0
          The output should equal "$2"
        End
      End
    End

    Describe "Given: 特殊文字を含む値の JSON ファイルが存在する"
      Before "setup_tmpdir; kv_init 'special_load_store' $'key1|default\nkey2|default'"
      After "teardown_tmpdir"

      Describe "When: 特殊文字を含む値のファイルを kv_load する"
        Parameters
          "key1"  "hello world"  "space"
          "key2"  "a=b=c"        "eq"
        End

        It "Then: [Edge] '$2' を含む値が正しく読み込まれる"
          printf '%s' "{\"$1\":\"$2\"}" > "${NAMING_TMPDIR}/$3.kv"
          kv_load "special_load_store" "${NAMING_TMPDIR}/$3"
          When call kv_get "special_load_store" "$1"
          The status should equal 0
          The output should equal "$2"
        End
      End
    End

    Describe "Given: スキーマ外キーを含む JSON ファイルが存在する"
      Before "setup_tmpdir; kv_init 'extra_key_store' $'key1|default1\nkey2|default2'"
      After "teardown_tmpdir"

      Describe "When: kv_load を呼ぶ"
        It "Then: [Error] return 1 かつ stderr に 'Error:' を出力する"
          printf '%s' '{"key1":"v1","key2":"v2","unknown":"x"}' > "${NAMING_TMPDIR}/extra.kv"
          When call kv_load "extra_key_store" "${NAMING_TMPDIR}/extra"
          The status should equal 1
          The stderr should include "Error:"
        End
      End
    End
  End

  Describe "kv_save"
    Describe "Given: スキーマ未登録のストア"
      Describe "When: kv_save を呼ぶ"
        It "Then: [Error] return 1 かつ stderr に 'Error: kv_save:' を出力する"
          When call kv_save "noschema_save_store" "/tmp/dummy"
          The status should equal 1
          The stderr should include "Error: kv_save:"
        End
      End
    End

    Describe "Given: データがセットされた状態"
      Before "setup_tmpdir; kv_init 'unit_save_store' $'key1|v1\nkey2|v2'"
      After "teardown_tmpdir"

      Describe "When: kv_save を呼ぶ"
        It "Then: [Normal] return 0 を返す"
          kv_set "unit_save_store" "key1" "saved_val"
          When call kv_save "unit_save_store" "${NAMING_TMPDIR}/save_test"
          The status should equal 0
        End

        It "Then: [Normal] ファイルが作成される"
          kv_set "unit_save_store" "key1" "saved_val"
          kv_save "unit_save_store" "${NAMING_TMPDIR}/save_file"
          When call test -f "${NAMING_TMPDIR}/save_file.kv"
          The status should equal 0
        End

        It "Then: [Normal] kv_load で key1 の値が復元できる (round-trip  )"
          kv_set "unit_save_store" "key1" "roundtrip_val"
          kv_save "unit_save_store" "${NAMING_TMPDIR}/rt"
          kv_init "unit_save_store" $'key1|v1\nkey2|v2'
          kv_load "unit_save_store" "${NAMING_TMPDIR}/rt"
          When call kv_get "unit_save_store" "key1"
          The status should equal 0
          The output should equal "roundtrip_val"
        End
      End
    End

    Describe "Given: 特殊文字を含む値がセットされた状態"
      Before "setup_tmpdir; kv_init 'special_save_store' $'key1|default'"
      After "teardown_tmpdir"

      Describe "When: 特殊文字を含む値を kv_save / kv_load する"
        Parameters
          "hello world"  "sp_space"
          "a=b"          "sp_eq"
          "a|b"          "sp_pipe"
        End

        It "Then: [Edge] round-trip 後に '$1' を含む値が正しく復元できる"
          kv_set "special_save_store" "key1" "$1"
          kv_save "special_save_store" "${NAMING_TMPDIR}/$2"
          kv_init "special_save_store" $'key1|default'
          kv_load "special_save_store" "${NAMING_TMPDIR}/$2"
          When call kv_get "special_save_store" "key1"
          The status should equal 0
          The output should equal "$1"
        End
      End
    End
  End

End
