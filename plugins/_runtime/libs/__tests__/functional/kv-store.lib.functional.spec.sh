#!/usr/bin/env bash
# kv-store.lib.functional.spec.sh - ShellSpec functional tests for kv-store.lib.sh
#        Multi-function interaction: kv_load/kv_save file I/O, round-trip,
#        and multi-store independence.
#
# Copyright (c) 2026- atsushifx <https://github.com/atsushifx>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

# shellcheck disable=SC1090,SC1091
# cspell:words mydefault myvalue rtstore envval projval

_RUNTIME_LIBS_DIR="$(cd "${SHELLSPEC_PROJECT_ROOT}/plugins/_runtime/libs" && pwd)"

Include "../spec_helper.sh"

. "${_RUNTIME_LIBS_DIR}/bootstrap.lib.sh" --no-finalize
. "${_RUNTIME_LIBS_DIR}/kv-store.lib.sh"

Describe "kv-store.lib.sh - functional tests"

  Describe "kv_load"
    Describe "Given: 有効な JSON ファイルが存在する"
      Before "setup_tmpdir; kv_init 'jsonstore' $'key1|default1\nkey2|default2'"
      After "teardown_tmpdir"

      Describe "When: kv_load を呼ぶ"
        It "Then: [Normal] key1 が JSON から読み込まれる"
          printf '{"key1":"loaded1","key2":"loaded2"}' \
            > "${NAMING_TMPDIR}/kv.kv"
          kv_load "jsonstore" "${NAMING_TMPDIR}/kv"
          When call kv_get "jsonstore" "key1"
          The status should equal 0
          The output should equal "loaded1"
        End

        It "Then: [Normal] key2 が JSON から読み込まれる"
          printf '{"key1":"loaded1","key2":"loaded2"}' \
            > "${NAMING_TMPDIR}/kv.kv"
          kv_load "jsonstore" "${NAMING_TMPDIR}/kv"
          When call kv_get "jsonstore" "key2"
          The status should equal 0
          The output should equal "loaded2"
        End

        It "Then: [Normal] JSON に存在しないキーはデフォルト値になる"
          printf '{"key1":"only-key1"}' \
            > "${NAMING_TMPDIR}/kv.kv"
          kv_load "jsonstore" "${NAMING_TMPDIR}/kv"
          When call kv_get "jsonstore" "key2"
          The status should equal 0
          The output should equal "default2"
        End
      End
    End

    Describe "Given: 空 JSON {} のファイルが存在する"
      Before "setup_tmpdir; kv_init 'emptyjson_store' $'key1|def1\nkey2|def2'"
      After "teardown_tmpdir"

      Describe "When: kv_load を呼ぶ"
        It "Then: [Edge] return 0 を返す"
          printf '{}' > "${NAMING_TMPDIR}/empty.kv"
          When call kv_load "emptyjson_store" "${NAMING_TMPDIR}/empty"
          The status should equal 0
        End

        It "Then: [Edge] key1 はデフォルト値になる"
          printf '{}' > "${NAMING_TMPDIR}/empty.kv"
          kv_load "emptyjson_store" "${NAMING_TMPDIR}/empty"
          When call kv_get "emptyjson_store" "key1"
          The output should equal "def1"
        End

        It "Then: [Edge] key2 はデフォルト値になる"
          printf '{}' > "${NAMING_TMPDIR}/empty.kv"
          kv_load "emptyjson_store" "${NAMING_TMPDIR}/empty"
          When call kv_get "emptyjson_store" "key2"
          The output should equal "def2"
        End
      End
    End

    Describe "Given: JSON の値が空文字のファイルが存在する"
      Before "setup_tmpdir; kv_init 'emptyval_store' $'key1|mydefault'"
      After "teardown_tmpdir"

      Describe "When: kv_load を呼ぶ"
        It "Then: [Edge] 空文字値はデフォルト値にフォールバックする"
          # 仕様: ${value:-${default}} で空文字 → デフォルト値が使われる
          printf '{"key1":""}' > "${NAMING_TMPDIR}/emptyval.kv"
          kv_load "emptyval_store" "${NAMING_TMPDIR}/emptyval"
          When call kv_get "emptyval_store" "key1"
          The output should equal "mydefault"
        End
      End
    End

    Describe "Given: JSON にスキーマ外キーが含まれるファイルが存在する"
      Before "setup_tmpdir; kv_init 'extrakey_store' $'key1|def1'"
      After "teardown_tmpdir"

      Describe "When: kv_load を呼ぶ"
        It "Then: [Error] return 1 かつ stderr に 'Error:' を出力する"
          printf '{"key1":"loaded1","unknown":"ignored"}' > "${NAMING_TMPDIR}/extra.kv"
          When call kv_load "extrakey_store" "${NAMING_TMPDIR}/extra"
          The status should equal 1
          The stderr should include "Error:"
        End
      End
    End
  End

  Describe "kv_save"
    Describe "Given: データがセットされた状態"
      Before "setup_tmpdir; kv_init 'savestore' $'key1|v1\nkey2|v2'"
      After "teardown_tmpdir"

      Describe "When: kv_save を呼ぶ"
        It "Then: [Normal] ファイルが作成される"
          kv_set "savestore" "key1" "testval"
          kv_save "savestore" "${NAMING_TMPDIR}/kv"
          When call test -f "${NAMING_TMPDIR}/kv.kv"
          The status should equal 0
        End

        It "Then: [Normal] ディレクトリが自動作成される"
          kv_set "savestore" "key1" "testval"
          kv_save "savestore" "${NAMING_TMPDIR}/nested/dir/kv"
          When call test -f "${NAMING_TMPDIR}/nested/dir/kv.kv"
          The status should equal 0
        End
      End
    End

    Describe "Given: データがセットされた状態 (JSON 整形検証)"
      Before "setup_tmpdir; kv_init 'jsoncheck_store' $'key1|v1'"
      After "teardown_tmpdir"

      Describe "When: kv_save 後に JSON 内容を検証する"
        It "Then: [Normal] 保存されたファイルが有効な JSON である"
          kv_set "jsoncheck_store" "key1" "myvalue"
          kv_save "jsoncheck_store" "${NAMING_TMPDIR}/jsoncheck"
          When call cat "${NAMING_TMPDIR}/jsoncheck.kv"
          The status should equal 0
          The output should equal '{"key1":"myvalue"}'
        End

        It "Then: [Normal] kv_load でキー値が正しく復元できる"
          kv_set "jsoncheck_store" "key1" "myvalue"
          kv_save "jsoncheck_store" "${NAMING_TMPDIR}/jsoncheck"
          kv_load "jsoncheck_store" "${NAMING_TMPDIR}/jsoncheck"
          When call kv_get "jsoncheck_store" "key1"
          The output should equal "myvalue"
        End
      End
    End

    Describe "Given: ドット始まりパスにデータが保存された状態"
      Before "setup_tmpdir; kv_init 'dotpathstore' $'key1|default1'"
      After "teardown_tmpdir"

      Describe "When: .env.json 相当のパスに kv_save する"
        It "Then: [Edge] .env.kv ファイルが作成される"
          kv_set "dotpathstore" "key1" "envval"
          kv_save "dotpathstore" "${NAMING_TMPDIR}/.env.json"
          When call test -f "${NAMING_TMPDIR}/.env.kv"
          The status should equal 0
        End

        It "Then: [Edge] kv_load で正しく復元できる"
          kv_set "dotpathstore" "key1" "envval"
          kv_save "dotpathstore" "${NAMING_TMPDIR}/.env.json"
          kv_init "dotpathstore" $'key1|default1'
          kv_load "dotpathstore" "${NAMING_TMPDIR}/.env.json"
          When call kv_get "dotpathstore" "key1"
          The output should equal "envval"
        End
      End

      Describe "When: 隠しディレクトリを含むパス (.config/.project.json) に kv_save する"
        It "Then: [Edge] .config/.project.kv ファイルが作成される"
          kv_set "dotpathstore" "key1" "projval"
          kv_save "dotpathstore" "${NAMING_TMPDIR}/.config/.project.json"
          When call test -f "${NAMING_TMPDIR}/.config/.project.kv"
          The status should equal 0
        End

        It "Then: [Edge] kv_load で正しく復元できる"
          kv_set "dotpathstore" "key1" "projval"
          kv_save "dotpathstore" "${NAMING_TMPDIR}/.config/.project.json"
          kv_init "dotpathstore" $'key1|default1'
          kv_load "dotpathstore" "${NAMING_TMPDIR}/.config/.project.json"
          When call kv_get "dotpathstore" "key1"
          The output should equal "projval"
        End
      End

      Describe "When: 空拡張子（.project）パスに kv_save する"
        It "Then: [Edge] .project.kv ファイルが作成される"
          kv_set "dotpathstore" "key1" "dotonly"
          kv_save "dotpathstore" "${NAMING_TMPDIR}/.project"
          When call test -f "${NAMING_TMPDIR}/.project.kv"
          The status should equal 0
        End

        It "Then: [Edge] kv_load で正しく復元できる"
          kv_set "dotpathstore" "key1" "dotonly"
          kv_save "dotpathstore" "${NAMING_TMPDIR}/.project"
          kv_init "dotpathstore" $'key1|default1'
          kv_load "dotpathstore" "${NAMING_TMPDIR}/.project"
          When call kv_get "dotpathstore" "key1"
          The output should equal "dotonly"
        End
      End
    End

    Describe "Given: 特殊文字を含む値がセットされた状態"
      Before "setup_tmpdir; kv_init 'specialsave_store' $'key1|default'"
      After "teardown_tmpdir"

      Describe "When: スペースを含む値を kv_save する"
        It "Then: [Edge] ファイルが作成される"
          kv_set "specialsave_store" "key1" "hello world"
          When call kv_save "specialsave_store" "${NAMING_TMPDIR}/special"
          The status should equal 0
        End

        It "Then: [Edge] kv_load で正しく復元できる"
          kv_set "specialsave_store" "key1" "hello world"
          kv_save "specialsave_store" "${NAMING_TMPDIR}/special"
          kv_init "specialsave_store" $'key1|default'
          kv_load "specialsave_store" "${NAMING_TMPDIR}/special"
          When call kv_get "specialsave_store" "key1"
          The output should equal "hello world"
        End
      End

      Describe "When: ダブルクォートを含む値を kv_save する"
        It "Then: [Edge] ファイルが作成される"
          kv_set "specialsave_store" "key1" 'say "hello"'
          When call kv_save "specialsave_store" "${NAMING_TMPDIR}/dq"
          The status should equal 0
        End

        It "Then: [Edge] kv_load で正しく復元できる"
          kv_set "specialsave_store" "key1" 'say "hello"'
          kv_save "specialsave_store" "${NAMING_TMPDIR}/dq"
          kv_init "specialsave_store" $'key1|default'
          kv_load "specialsave_store" "${NAMING_TMPDIR}/dq"
          When call kv_get "specialsave_store" "key1"
          The output should equal 'say "hello"'
        End
      End
    End
  End

  Describe "ラウンドトリップ (kv_save → kv_load)"
    Before "setup_tmpdir; kv_init 'rtstore' $'key1|d1\nkey2|d2'"
    After "teardown_tmpdir"

    Describe "When: kv_save 後に kv_load する"
      It "Then: [Normal] key1 の値が復元される"
        kv_set "rtstore" "key1" "roundtrip1"
        kv_set "rtstore" "key2" "roundtrip2"
        kv_save "rtstore" "${NAMING_TMPDIR}/rt"
        kv_init "rtstore" $'key1|d1\nkey2|d2'
        kv_load "rtstore" "${NAMING_TMPDIR}/rt"
        When call kv_get "rtstore" "key1"
        The status should equal 0
        The output should equal "roundtrip1"
      End

      It "Then: [Normal] key2 の値が復元される"
        kv_set "rtstore" "key1" "roundtrip1"
        kv_set "rtstore" "key2" "roundtrip2"
        kv_save "rtstore" "${NAMING_TMPDIR}/rt"
        kv_init "rtstore" $'key1|d1\nkey2|d2'
        kv_load "rtstore" "${NAMING_TMPDIR}/rt"
        When call kv_get "rtstore" "key2"
        The status should equal 0
        The output should equal "roundtrip2"
      End

      It "Then: [Normal] スペースを含む値が正しく復元される"
        kv_set "rtstore" "key1" "hello world"
        kv_save "rtstore" "${NAMING_TMPDIR}/rt_space"
        kv_init "rtstore" $'key1|d1\nkey2|d2'
        kv_load "rtstore" "${NAMING_TMPDIR}/rt_space"
        When call kv_get "rtstore" "key1"
        The status should equal 0
        The output should equal "hello world"
      End

      It "Then: [Normal] ダブルクォートを含む値が正しく復元される"
        kv_set "rtstore" "key1" 'say "hi"'
        kv_save "rtstore" "${NAMING_TMPDIR}/rt_dq"
        kv_init "rtstore" $'key1|d1\nkey2|d2'
        kv_load "rtstore" "${NAMING_TMPDIR}/rt_dq"
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
