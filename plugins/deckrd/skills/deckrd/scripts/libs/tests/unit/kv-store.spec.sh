#!/usr/bin/env bash
# kv-store.spec.sh - ShellSpec tests for kv-store.sh
#
# Copyright (c) 2026- atsushifx <https://github.com/atsushifx>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

# shellcheck disable=SC1091

_LIB_DIR="$(cd "${SHELLSPEC_PROJECT_ROOT}/plugins/deckrd/skills/deckrd/scripts/libs" && pwd)"
# shellcheck disable=SC1091
. "${_LIB_DIR}/bootstrap.sh"
unset _LIB_DIR

Include ../spec_helper.sh

. "${DECKRD_LIB_DIR}/kv-store.sh"

Describe "kv-store.sh"

  Describe "kv-store.sh loading"
    Describe "When: スクリプトを読み込む"
      It "Then: [Normal] kv_init 関数が存在する"
        When call type kv_init
        The status should equal 0
        The output should include "kv_init"
      End

      It "Then: [Normal] kv_get 関数が存在する"
        When call type kv_get
        The status should equal 0
        The output should include "kv_get"
      End

      It "Then: [Normal] kv_set 関数が存在する"
        When call type kv_set
        The status should equal 0
        The output should include "kv_set"
      End

      It "Then: [Normal] kv_load 関数が存在する"
        When call type kv_load
        The status should equal 0
        The output should include "kv_load"
      End

      It "Then: [Normal] kv_save 関数が存在する"
        When call type kv_save
        The status should equal 0
        The output should include "kv_save"
      End

      It "Then: [Normal] kv_all 関数が存在する"
        When call type kv_all
        The status should equal 0
        The output should include "kv_all"
      End
    End
  End

  Describe "_kv_file_path"
    Describe "When: _kv_file_path を呼ぶ"
      It "Then: [Normal] 拡張子なしのパスに .kv が付加される"
        When call _kv_file_path "/foo/bar/session"
        The status should equal 0
        The output should equal "/foo/bar/session.kv"
      End

      It "Then: [Normal] .json 拡張子が .kv に置き換えられる"
        When call _kv_file_path "/foo/bar/kv.json"
        The status should equal 0
        The output should equal "/foo/bar/kv.kv"
      End

      It "Then: [Normal] ディレクトリパスが保持される"
        When call _kv_file_path "/path/to/dir/name"
        The status should equal 0
        The output should equal "/path/to/dir/name.kv"
      End

      It "Then: [Edge] 複数ドットのファイル名は最初のドット以降が除去される"
        When call _kv_file_path "/foo/bar/my.store.json"
        The status should equal 0
        The output should equal "/foo/bar/my.kv"
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

        It "Then: [Normal] スキーマ外キーは空文字を返す"
          kv_init "onekey_store2" "key1|val1"
          When call kv_get "onekey_store2" "other_key"
          The status should equal 0
          The output should equal ""
        End
      End
    End

    Describe "Given: 空スキーマ"
      Describe "When: kv_init を呼ぶ"
        It "Then: [Edge] エラーにならず return 0 を返す"
          When call kv_init "emptyschema_store" ""
          The status should equal 0
        End

        It "Then: [Edge] スキーマが登録される (空でも)"
          kv_init "emptyschema_store2" ""
          When call test -n "${_KV_SCHEMA[emptyschema_store2]+set}"
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
  End

  Describe "kv_get / kv_set"
    Before "kv_init 'teststore' $'name|alice\nage|30'"

    Describe "When: kv_get を呼ぶ"
      It "Then: [Normal] デフォルト値が返る"
        When call kv_get "teststore" "name"
        The status should equal 0
        The output should equal "alice"
      End

      It "Then: [Normal] kv_set 後の値が返る"
        kv_set "teststore" "name" "bob"
        When call kv_get "teststore" "name"
        The status should equal 0
        The output should equal "bob"
      End

      It "Then: [Edge] 存在しないキーは空文字を返す"
        When call kv_get "teststore" "no_such_key"
        The status should equal 0
        The output should equal ""
      End

      It "Then: [Edge] スペースを含む値がそのまま返る"
        kv_set "teststore" "name" "hello world"
        When call kv_get "teststore" "name"
        The status should equal 0
        The output should equal "hello world"
      End

      It "Then: [Edge] タブを含む値がそのまま返る"
        kv_set "teststore" "name" $'hello\tworld'
        When call kv_get "teststore" "name"
        The status should equal 0
        The output should equal $'hello\tworld'
      End

      It "Then: [Edge] スキーマ外キーを kv_set 後に取得できる"
        kv_set "teststore" "extra_key" "extra_val"
        When call kv_get "teststore" "extra_key"
        The status should equal 0
        The output should equal "extra_val"
      End

      It "Then: [Edge] スキーマ外キーを未セットで呼ぶと空文字を返す"
        When call kv_get "teststore" "undefined_extra"
        The status should equal 0
        The output should equal ""
      End
    End

    Describe "When: kv_set を呼ぶ"
      It "Then: [Normal] 新規キーに値をセットできる"
        kv_set "teststore" "newkey" "newval"
        When call kv_get "teststore" "newkey"
        The status should equal 0
        The output should equal "newval"
      End

      It "Then: [Normal] 既存キーを上書きできる"
        kv_set "teststore" "name" "bob"
        When call kv_get "teststore" "name"
        The status should equal 0
        The output should equal "bob"
      End

      It "Then: [Edge] 空文字をセットできる"
        kv_set "teststore" "name" ""
        When call kv_get "teststore" "name"
        The status should equal 0
        The output should equal ""
      End

      It "Then: [Edge] 値引数なしで呼ぶと空文字がセットされる"
        # value=${3:-} の仕様: 引数省略 → 空文字
        kv_set "teststore" "name"
        When call kv_get "teststore" "name"
        The status should equal 0
        The output should equal ""
      End

      It "Then: [Edge] スペースを含む値がセットできる"
        kv_set "teststore" "age" "twenty five"
        When call kv_get "teststore" "age"
        The status should equal 0
        The output should equal "twenty five"
      End

      It "Then: [Edge] パイプ文字を含む値がセットできる"
        kv_set "teststore" "age" "a|b"
        When call kv_get "teststore" "age"
        The status should equal 0
        The output should equal "a|b"
      End

      It "Then: [Edge] スキーマ外の新規キーをセットすると kv_all 出力に含まれる"
        kv_set "teststore" "extra_for_all" "extra_val"
        When call kv_all "teststore"
        The status should equal 0
        The output should include "extra_for_all=extra_val"
      End
    End
  End

  Describe "kv_load"
    Describe "Given: ファイルが存在しない"
      Before "kv_init 'loadstore' $'key1|default1\nkey2|default2'"

      Describe "When: kv_load を呼ぶ"
        It "Then: [Normal] return 0 を返しデフォルト値で初期化される"
          When call kv_load "loadstore" "/tmp/nonexistent_kvtest_$$_noext"
          The status should equal 0
        End

        It "Then: [Normal] key1 はデフォルト値 default1 になる"
          kv_load "loadstore" "/tmp/nonexistent_kvtest_$$_noext"
          When call kv_get "loadstore" "key1"
          The output should equal "default1"
        End

        It "Then: [Normal] key2 はデフォルト値 default2 になる"
          kv_load "loadstore" "/tmp/nonexistent_kvtest_$$_noext"
          When call kv_get "loadstore" "key2"
          The output should equal "default2"
        End
      End
    End

    Describe "Given: 有効な JSON ファイルが存在する"
      Before "setup_deckrd_tmpdir; kv_init 'jsonstore' $'key1|default1\nkey2|default2'"
      After "teardown_deckrd_tmpdir"

      Describe "When: kv_load を呼ぶ"
        It "Then: [Normal] key1 が JSON から読み込まれる"
          printf '{"key1":"loaded1","key2":"loaded2"}' \
            > "${DECKRD_LOCAL}/kv.kv"
          kv_load "jsonstore" "${DECKRD_LOCAL}/kv"
          When call kv_get "jsonstore" "key1"
          The status should equal 0
          The output should equal "loaded1"
        End

        It "Then: [Normal] key2 が JSON から読み込まれる"
          printf '{"key1":"loaded1","key2":"loaded2"}' \
            > "${DECKRD_LOCAL}/kv.kv"
          kv_load "jsonstore" "${DECKRD_LOCAL}/kv"
          When call kv_get "jsonstore" "key2"
          The status should equal 0
          The output should equal "loaded2"
        End

        It "Then: [Normal] JSON に存在しないキーはデフォルト値になる"
          printf '{"key1":"only-key1"}' \
            > "${DECKRD_LOCAL}/kv.kv"
          kv_load "jsonstore" "${DECKRD_LOCAL}/kv"
          When call kv_get "jsonstore" "key2"
          The status should equal 0
          The output should equal "default2"
        End
      End
    End

    Describe "Given: 空 JSON {} のファイルが存在する"
      Before "setup_deckrd_tmpdir; kv_init 'emptyjson_store' $'key1|def1\nkey2|def2'"
      After "teardown_deckrd_tmpdir"

      Describe "When: kv_load を呼ぶ"
        It "Then: [Edge] return 0 を返す"
          printf '{}' > "${DECKRD_LOCAL}/empty.kv"
          When call kv_load "emptyjson_store" "${DECKRD_LOCAL}/empty"
          The status should equal 0
        End

        It "Then: [Edge] key1 はデフォルト値になる"
          printf '{}' > "${DECKRD_LOCAL}/empty.kv"
          kv_load "emptyjson_store" "${DECKRD_LOCAL}/empty"
          When call kv_get "emptyjson_store" "key1"
          The output should equal "def1"
        End

        It "Then: [Edge] key2 はデフォルト値になる"
          printf '{}' > "${DECKRD_LOCAL}/empty.kv"
          kv_load "emptyjson_store" "${DECKRD_LOCAL}/empty"
          When call kv_get "emptyjson_store" "key2"
          The output should equal "def2"
        End
      End
    End

    Describe "Given: JSON の値が空文字のファイルが存在する"
      Before "setup_deckrd_tmpdir; kv_init 'emptyval_store' $'key1|mydefault'"
      After "teardown_deckrd_tmpdir"

      Describe "When: kv_load を呼ぶ"
        It "Then: [Edge] 空文字値はデフォルト値にフォールバックする"
          # 仕様: ${value:-${default}} で空文字 → デフォルト値が使われる
          printf '{"key1":""}' > "${DECKRD_LOCAL}/emptyval.kv"
          kv_load "emptyval_store" "${DECKRD_LOCAL}/emptyval"
          When call kv_get "emptyval_store" "key1"
          The output should equal "mydefault"
        End
      End
    End

    Describe "Given: JSON にスキーマ外キーが含まれるファイルが存在する"
      Before "setup_deckrd_tmpdir; kv_init 'extrakey_store' $'key1|def1'"
      After "teardown_deckrd_tmpdir"

      Describe "When: kv_load を呼ぶ"
        It "Then: [Edge] スキーマ内キーは正しく読み込まれる"
          printf '{"key1":"loaded1","extra":"ignored"}' > "${DECKRD_LOCAL}/extra.kv"
          kv_load "extrakey_store" "${DECKRD_LOCAL}/extra"
          When call kv_get "extrakey_store" "key1"
          The output should equal "loaded1"
        End

        It "Then: [Edge] スキーマ外キーは kv_get で取得できない (無視)"
          printf '{"key1":"loaded1","extra":"ignored"}' > "${DECKRD_LOCAL}/extra.kv"
          kv_load "extrakey_store" "${DECKRD_LOCAL}/extra"
          When call kv_get "extrakey_store" "extra"
          The output should equal ""
        End
      End
    End

    Describe "Given: schema 未登録のストア"
      Describe "When: kv_load を呼ぶ"
        It "Then: [Error] return 1 を返し Error: を stdout に出力する"
          When call kv_load "noschema_store" "/tmp/any"
          The status should equal 1
          The output should include "Error:"
        End
      End
    End

    Describe "Given: 不正な JSON ファイルが存在する"
      Before "setup_deckrd_tmpdir; kv_init 'badjson_store' $'key1|def1\nkey2|def2'"
      After "teardown_deckrd_tmpdir"

      Describe "When: kv_load を呼ぶ"
        It "Then: [Error] return 1 を返す (invalid JSON はエラー)"
          printf 'not-json' > "${DECKRD_LOCAL}/bad.kv"
          When call kv_load "badjson_store" "${DECKRD_LOCAL}/bad"
          The status should equal 1
          The output should include "Error"
        End
      End
    End
  End

  Describe "kv_save"
    Describe "Given: データがセットされた状態"
      Before "setup_deckrd_tmpdir; kv_init 'savestore' $'key1|v1\nkey2|v2'"
      After "teardown_deckrd_tmpdir"

      Describe "When: kv_save を呼ぶ"
        It "Then: [Normal] ファイルが作成される"
          kv_set "savestore" "key1" "testval"
          kv_save "savestore" "${DECKRD_LOCAL}/kv"
          When call test -f "${DECKRD_LOCAL}/kv.kv"
          The status should equal 0
        End

        It "Then: [Normal] ディレクトリが自動作成される"
          kv_set "savestore" "key1" "testval"
          kv_save "savestore" "${DECKRD_LOCAL}/nested/dir/kv"
          When call test -f "${DECKRD_LOCAL}/nested/dir/kv.kv"
          The status should equal 0
        End
      End
    End

    Describe "Given: データがセットされた状態 (JSON 整形検証)"
      Before "setup_deckrd_tmpdir; kv_init 'jsoncheck_store' $'key1|v1'"
      After "teardown_deckrd_tmpdir"

      Describe "When: kv_save 後に JSON 内容を検証する"
        It "Then: [Normal] 保存されたファイルが有効な JSON である"
          kv_set "jsoncheck_store" "key1" "myvalue"
          kv_save "jsoncheck_store" "${DECKRD_LOCAL}/jsoncheck"
          When call cat "${DECKRD_LOCAL}/jsoncheck.kv"
          The status should equal 0
          The output should equal '{"key1":"myvalue"}'
        End

        It "Then: [Normal] kv_load でキー値が正しく復元できる"
          kv_set "jsoncheck_store" "key1" "myvalue"
          kv_save "jsoncheck_store" "${DECKRD_LOCAL}/jsoncheck"
          kv_load "jsoncheck_store" "${DECKRD_LOCAL}/jsoncheck"
          When call kv_get "jsoncheck_store" "key1"
          The output should equal "myvalue"
        End
      End
    End

    Describe "Given: 空スキーマのストア"
      Before "setup_deckrd_tmpdir; kv_init 'emptysave_store' ''"
      After "teardown_deckrd_tmpdir"

      Describe "When: kv_save を呼ぶ"
        It "Then: [Edge] ファイルが作成される"
          When call kv_save "emptysave_store" "${DECKRD_LOCAL}/empty_save"
          The status should equal 0
        End

        It "Then: [Edge] 作成されたファイルの内容は {} になる"
          kv_save "emptysave_store" "${DECKRD_LOCAL}/empty_save"
          When call cat "${DECKRD_LOCAL}/empty_save.kv"
          The output should equal "{}"
        End
      End
    End

    Describe "Given: 特殊文字を含む値がセットされた状態"
      Before "setup_deckrd_tmpdir; kv_init 'specialsave_store' $'key1|default'"
      After "teardown_deckrd_tmpdir"

      Describe "When: スペースを含む値を kv_save する"
        It "Then: [Edge] ファイルが作成される"
          kv_set "specialsave_store" "key1" "hello world"
          When call kv_save "specialsave_store" "${DECKRD_LOCAL}/special"
          The status should equal 0
        End

        It "Then: [Edge] kv_load で正しく復元できる"
          kv_set "specialsave_store" "key1" "hello world"
          kv_save "specialsave_store" "${DECKRD_LOCAL}/special"
          kv_init "specialsave_store" $'key1|default'
          kv_load "specialsave_store" "${DECKRD_LOCAL}/special"
          When call kv_get "specialsave_store" "key1"
          The output should equal "hello world"
        End
      End

      Describe "When: ダブルクォートを含む値を kv_save する"
        It "Then: [Edge] ファイルが作成される"
          kv_set "specialsave_store" "key1" 'say "hello"'
          When call kv_save "specialsave_store" "${DECKRD_LOCAL}/dq"
          The status should equal 0
        End

        It "Then: [Edge] kv_load で正しく復元できる"
          kv_set "specialsave_store" "key1" 'say "hello"'
          kv_save "specialsave_store" "${DECKRD_LOCAL}/dq"
          kv_init "specialsave_store" $'key1|default'
          kv_load "specialsave_store" "${DECKRD_LOCAL}/dq"
          When call kv_get "specialsave_store" "key1"
          The output should equal 'say "hello"'
        End
      End
    End

    Describe "Given: schema 未登録のストア"
      Describe "When: kv_save を呼ぶ"
        It "Then: [Error] return 1 を返し Error: を stdout に出力する"
          When call kv_save "noschema_save_store" "/tmp/any"
          The status should equal 1
          The output should include "Error:"
        End
      End
    End
  End

  Describe "kv_all"
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

    Describe "Given: 空スキーマのストア"
      Before "kv_init 'emptyall_store' ''"

      Describe "When: kv_all を呼ぶ"
        It "Then: [Edge] return 0 を返す"
          When call kv_all "emptyall_store"
          The status should equal 0
        End

        It "Then: [Edge] 出力が空になる"
          When call kv_all "emptyall_store"
          The status should equal 0
          The lines of output should equal 0
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
  End

  Describe "ラウンドトリップ (kv_save → kv_load)"
    Before "setup_deckrd_tmpdir; kv_init 'rtstore' $'key1|d1\nkey2|d2'"
    After "teardown_deckrd_tmpdir"

    Describe "When: kv_save 後に kv_load する"
      It "Then: [Normal] key1 の値が復元される"
        kv_set "rtstore" "key1" "roundtrip1"
        kv_set "rtstore" "key2" "roundtrip2"
        kv_save "rtstore" "${DECKRD_LOCAL}/rt"
        kv_init "rtstore" $'key1|d1\nkey2|d2'
        kv_load "rtstore" "${DECKRD_LOCAL}/rt"
        When call kv_get "rtstore" "key1"
        The status should equal 0
        The output should equal "roundtrip1"
      End

      It "Then: [Normal] key2 の値が復元される"
        kv_set "rtstore" "key1" "roundtrip1"
        kv_set "rtstore" "key2" "roundtrip2"
        kv_save "rtstore" "${DECKRD_LOCAL}/rt"
        kv_init "rtstore" $'key1|d1\nkey2|d2'
        kv_load "rtstore" "${DECKRD_LOCAL}/rt"
        When call kv_get "rtstore" "key2"
        The status should equal 0
        The output should equal "roundtrip2"
      End

      It "Then: [Normal] スペースを含む値が正しく復元される"
        kv_set "rtstore" "key1" "hello world"
        kv_save "rtstore" "${DECKRD_LOCAL}/rt_space"
        kv_init "rtstore" $'key1|d1\nkey2|d2'
        kv_load "rtstore" "${DECKRD_LOCAL}/rt_space"
        When call kv_get "rtstore" "key1"
        The status should equal 0
        The output should equal "hello world"
      End

      It "Then: [Normal] ダブルクォートを含む値が正しく復元される"
        kv_set "rtstore" "key1" 'say "hi"'
        kv_save "rtstore" "${DECKRD_LOCAL}/rt_dq"
        kv_init "rtstore" $'key1|d1\nkey2|d2'
        kv_load "rtstore" "${DECKRD_LOCAL}/rt_dq"
        When call kv_get "rtstore" "key1"
        The status should equal 0
        The output should equal 'say "hi"'
      End
    End
  End

  Describe "複数ストアの独立性"
    Before "kv_init 'store_a' $'key|valueA'; kv_init 'store_b' $'key|valueB'"

    Describe "When: store_a の値を変更する"
      It "Then: [Normal] store_b の値は変わらない"
        kv_set "store_a" "key" "modified"
        When call kv_get "store_b" "key"
        The status should equal 0
        The output should equal "valueB"
      End

      It "Then: [Normal] store_a の値は変更されている"
        kv_set "store_a" "key" "modified"
        When call kv_get "store_a" "key"
        The status should equal 0
        The output should equal "modified"
      End
    End

    Describe "Given: 3ストアを独立して初期化する"
      Before "kv_init 'sc_a' 'key|A'; kv_init 'sc_b' 'key|B'; kv_init 'sc_c' 'key|C'"

      Describe "When: sc_b の値を変更する"
        It "Then: [Normal] sc_a の値は変わらない"
          kv_set "sc_b" "key" "modified_b"
          When call kv_get "sc_a" "key"
          The status should equal 0
          The output should equal "A"
        End

        It "Then: [Normal] sc_c の値は変わらない"
          kv_set "sc_b" "key" "modified_b"
          When call kv_get "sc_c" "key"
          The status should equal 0
          The output should equal "C"
        End

        It "Then: [Normal] sc_b の値は変更されている"
          kv_set "sc_b" "key" "modified_b"
          When call kv_get "sc_b" "key"
          The status should equal 0
          The output should equal "modified_b"
        End
      End
    End
  End

End
