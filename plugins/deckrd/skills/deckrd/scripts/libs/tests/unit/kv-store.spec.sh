#!/usr/bin/env bash
# kv-store.spec.sh - ShellSpec tests for kv-store.sh
#
# Copyright (c) 2026- atsushifx <https://github.com/atsushifx>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

# shellcheck disable=SC1091

Include spec_helper.sh

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

  Describe "kv_init"
    Describe "Given: スキーマを登録する"
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

        It "Then: [Normal] デフォルト値が空のキーは空文字になる"
          kv_init "emptystore" $'key1|\nkey2|default2'
          When call kv_get "emptystore" "key1"
          The status should equal 0
          The output should equal ""
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

      It "Then: [Normal] 存在しないキーは空文字を返す"
        When call kv_get "teststore" "no_such_key"
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

      It "Then: [Normal] 空文字をセットできる"
        kv_set "teststore" "name" ""
        When call kv_get "teststore" "name"
        The status should equal 0
        The output should equal ""
      End
    End
  End

  Describe "kv_load"
    Describe "Given: schema 未登録のストア"
      Describe "When: kv_load を呼ぶ"
        It "Then: [Error] exit 1 を返し Error: を stderr に出力する"
          When call kv_load "noschema_store" "/tmp/any"
          The status should equal 1
          The stderr should include "Error:"
        End
      End
    End

    Describe "Given: ファイルが存在しない"
      Before "kv_init 'loadstore' $'key1|default1\nkey2|default2'"

      Describe "When: kv_load を呼ぶ"
        It "Then: [Normal] exit 0 を返しデフォルト値で初期化される"
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
  End

  Describe "kv_save"
    Describe "Given: schema 未登録のストア"
      Describe "When: kv_save を呼ぶ"
        It "Then: [Error] exit 1 を返し Error: を stderr に出力する"
          When call kv_save "noschema_save_store" "/tmp/any"
          The status should equal 1
          The stderr should include "Error:"
        End
      End
    End

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
  End

End
