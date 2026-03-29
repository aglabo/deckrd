#!/usr/bin/env bash
# config.spec.sh - ShellSpec tests for config.sh
#
# Copyright (c) 2026- atsushifx <https://github.com/atsushifx>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

# shellcheck disable=SC1090,SC1091
# cspell:words myproject

_RUNTIME_BOOTSTRAP="${SHELLSPEC_PROJECT_ROOT}/plugins/_runtime/libs/bootstrap.lib.sh"
. "$_RUNTIME_BOOTSTRAP" "--no-finalize"
unset _RUNTIME_BOOTSTRAP

Include ../spec_helper.sh

. "${DECKRD_LIB_DIR}/session.sh"
. "${DECKRD_LIB_DIR}/config.sh"

Describe "config.sh"
  Describe "config.sh loading"
    Describe "When: スクリプトを読み込む"
      It "Then: [Normal] config_init 関数が存在する"
        When call type config_init
        The status should equal 0
        The output should include "config_init"
      End

      It "Then: [Normal] config_get 関数が存在する"
        When call type config_get
        The status should equal 0
        The output should include "config_get"
      End

      It "Then: [Normal] config_set 関数が存在する"
        When call type config_set
        The status should equal 0
        The output should include "config_set"
      End

      It "Then: [Normal] config_all 関数が存在する"
        When call type config_all
        The status should equal 0
        The output should include "config_all"
      End
    End
  End

  Describe "config_get / config_set"
    Describe "Given: CONFIG 配列にキーをセットした状態"
      Before "CONFIG=(); CONFIG[key1]=value1"

      Describe "When: config_get を呼ぶ"
        It "Then: [Normal] セットした値が返る"
          When call config_get "key1"
          The status should equal 0
          The output should equal "value1"
        End

        It "Then: [Normal] 存在しないキーは空文字を返す"
          When call config_get "no_such_key"
          The status should equal 0
          The output should equal ""
        End
      End
    End

    Describe "Given: CONFIG 配列が空の状態"
      Before "CONFIG=()"

      Describe "When: config_set を呼ぶ"
        It "Then: [Normal] 新規キーに値をセットできる"
          config_set "newkey" "newval"
          When call config_get "newkey"
          The status should equal 0
          The output should equal "newval"
        End

        It "Then: [Normal] 既存キーを上書きできる"
          config_set "existing" "first"
          config_set "existing" "second"
          When call config_get "existing"
          The status should equal 0
          The output should equal "second"
        End

        It "Then: [Normal] 空文字をセットできる"
          config_set "emptykey" ""
          When call config_get "emptykey"
          The status should equal 0
          The output should equal ""
        End
      End
    End
  End

  Describe "config_all"
    Describe "Given: CONFIG に複数のキーがセットされた状態"
      Before "CONFIG=(); CONFIG[ai_model]=sonnet; CONFIG[lang]=ja"

      Describe "When: config_all を呼ぶ"
        It "Then: [Normal] ai_model=sonnet が出力に含まれる"
          When call config_all
          The status should equal 0
          The output should include "ai_model=sonnet"
        End

        It "Then: [Normal] lang=ja が出力に含まれる"
          When call config_all
          The status should equal 0
          The output should include "lang=ja"
        End
      End
    End
  End

  Describe "config_init"
    Describe "Given: セッションファイルなし（引数省略）"
      Before "CONFIG=()"

      Describe "When: config_init を引数なしで呼ぶ"
        It "Then: [Normal] ai_model のデフォルト値が sonnet になる"
          config_init
          When call config_get "ai_model"
          The status should equal 0
          The output should equal "sonnet"
        End

        It "Then: [Normal] lang のデフォルト値が system になる"
          config_init
          When call config_get "lang"
          The status should equal 0
          The output should equal "system"
        End

        It "Then: [Normal] doc_type のデフォルト値が空文字になる"
          config_init
          When call config_get "doc_type"
          The status should equal 0
          The output should equal ""
        End

        It "Then: [Normal] prompt_mode のデフォルト値が 0 になる"
          config_init
          When call config_get "prompt_mode"
          The status should equal 0
          The output should equal "0"
        End
      End
    End

    Describe "Given: 有効な session.kv が存在する"
      Before "setup_deckrd_tmpdir; CONFIG=(); SESSION=()"
      After "teardown_deckrd_tmpdir"

      Describe "When: config_init をセッションファイルパスを指定して呼ぶ"
        It "Then: [Normal] セッションの ai_model が CONFIG に読み込まれる"
          kv_init "_test_session" $'\nactive|\nai_model|\nlang|\n'
          kv_set "_test_session" "active" "myproject"
          kv_set "_test_session" "ai_model" "opus"
          kv_set "_test_session" "lang" "ja"
          kv_save "_test_session" "${DECKRD_LOCAL}/session"
          config_init "${DECKRD_LOCAL}/session.kv"
          When call config_get "ai_model"
          The status should equal 0
          The output should equal "opus"
        End

        It "Then: [Normal] セッションの lang が CONFIG に読み込まれる"
          kv_init "_test_session" $'\nactive|\nai_model|\nlang|\n'
          kv_set "_test_session" "active" "myproject"
          kv_set "_test_session" "ai_model" "opus"
          kv_set "_test_session" "lang" "ja"
          kv_save "_test_session" "${DECKRD_LOCAL}/session"
          config_init "${DECKRD_LOCAL}/session.kv"
          When call config_get "lang"
          The status should equal 0
          The output should equal "ja"
        End

        It "Then: [Normal] セッションの active から deckrd_base が計算される"
          kv_init "_test_session" $'\nactive|\nai_model|\nlang|\n'
          kv_set "_test_session" "active" "myproject"
          kv_set "_test_session" "ai_model" "opus"
          kv_set "_test_session" "lang" "ja"
          kv_save "_test_session" "${DECKRD_LOCAL}/session"
          config_init "${DECKRD_LOCAL}/session.kv"
          When call config_get "deckrd_base"
          The status should equal 0
          The output should include "myproject"
        End
      End
    End
  End
End
