#!/usr/bin/env bash
# kv-store.lib.integration.spec.sh - ShellSpec integration tests for kv-store.lib.sh
#        Real filesystem access, jq error path (invalid JSON detection),
#        and schema-error paths that invoke the FS layer.
#
# Copyright (c) 2026- atsushifx <https://github.com/atsushifx>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

# shellcheck disable=SC1090,SC1091
# cspell:words badjson noschema kvtest

_RUNTIME_LIBS_DIR="$(cd "${SHELLSPEC_PROJECT_ROOT}/plugins/_runtime/libs" && pwd)"

Include "../spec_helper.sh"

. "${_RUNTIME_LIBS_DIR}/bootstrap.lib.sh" --no-finalize
. "${_RUNTIME_LIBS_DIR}/kv-store.lib.sh"

Describe "kv-store.lib.sh - integration tests"

  Describe "kv_load"
    Describe "Given: ファイルが存在しない"
      Before "kv_init 'loadstore' $'key1|default1\nkey2|default2'"

      Describe "When: kv_load を呼ぶ"
        It "Then: [Normal] return 0 を返しデフォルト値で初期化される"
          When call kv_load "loadstore" "/tmp/nonexistent_kvtest_$$_no_ext"
          The status should equal 0
        End

        It "Then: [Normal] key1 はデフォルト値 default1 になる"
          kv_load "loadstore" "/tmp/nonexistent_kvtest_$$_no_ext"
          When call kv_get "loadstore" "key1"
          The output should equal "default1"
        End

        It "Then: [Normal] key2 はデフォルト値 default2 になる"
          kv_load "loadstore" "/tmp/nonexistent_kvtest_$$_no_ext"
          When call kv_get "loadstore" "key2"
          The output should equal "default2"
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
      Before "setup_tmpdir; kv_init 'badjson_store' $'key1|def1\nkey2|def2'"
      After "teardown_tmpdir"

      Describe "When: kv_load を呼ぶ"
        It "Then: [Error] return 1 を返す (invalid JSON はエラー)"
          printf 'not-json' > "${NAMING_TMPDIR}/bad.kv"
          When call kv_load "badjson_store" "${NAMING_TMPDIR}/bad"
          The status should equal 1
          The output should include "Error"
        End
      End
    End
  End

  Describe "kv_save"
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

End
