#!/usr/bin/env bash
# session.spec.sh - ShellSpec tests for session.sh
#
# Copyright (c) 2026- atsushifx <https://github.com/atsushifx>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

_LIB_DIR="$(cd "${SHELLSPEC_PROJECT_ROOT}/plugins/deckrd/skills/deckrd/scripts/libs" && pwd)"
# shellcheck disable=SC1091
. "${_LIB_DIR}/bootstrap.sh"
unset _LIB_DIR

Include ../spec_helper.sh

SCRIPT="${DECKRD_LIB_DIR}/session.sh"

# shellcheck disable=SC1090
. "$SCRIPT"

# Schema used in tests
SESSION_SCHEMA_TEST="
active|false
ai_model|sonnet
lang|en
"

Describe "session.sh"

  Describe "session.sh loading"
    Describe "When: スクリプトを読み込む"
      It "Then: [Normal] session_init 関数が存在する"
        When call type session_init
        The status should equal 0
        The output should include "session_init"
      End

      It "Then: [Normal] session_load 関数が存在する"
        When call type session_load
        The status should equal 0
        The output should include "session_load"
      End

      It "Then: [Normal] session_save 関数が存在する"
        When call type session_save
        The status should equal 0
        The output should include "session_save"
      End

      It "Then: [Normal] session_get 関数が存在する"
        When call type session_get
        The status should equal 0
        The output should include "session_get"
      End

      It "Then: [Normal] session_set 関数が存在する"
        When call type session_set
        The status should equal 0
        The output should include "session_set"
      End
    End
  End

  Describe "session_init"
    Describe "Given: schema を登録する"
      Before "declare -gA BUF=()"

      Describe "When: session_init を呼ぶ"
        It "Then: [Normal] schema が SESSION_SCHEMA に登録される"
          session_init BUF "$SESSION_SCHEMA_TEST"
          When call test -n "${SESSION_SCHEMA[BUF]}"
          The status should equal 0
        End

        It "Then: [Normal] active のデフォルト値 false が設定される"
          session_init BUF "$SESSION_SCHEMA_TEST"
          When call session_get BUF "active"
          The status should equal 0
          The output should equal "false"
        End

        It "Then: [Normal] ai_model のデフォルト値 sonnet が設定される"
          session_init BUF "$SESSION_SCHEMA_TEST"
          When call session_get BUF "ai_model"
          The status should equal 0
          The output should equal "sonnet"
        End

        It "Then: [Normal] lang のデフォルト値 en が設定される"
          session_init BUF "$SESSION_SCHEMA_TEST"
          When call session_get BUF "lang"
          The status should equal 0
          The output should equal "en"
        End
      End
    End
  End

  Describe "session_get / session_set"
    Before "declare -gA BUF=(); session_init BUF \"$SESSION_SCHEMA_TEST\""

    Describe "Given: BUF にキーをセットした状態"
      Before "session_set BUF key1 value1"

      Describe "When: session_get を呼ぶ"
        It "Then: [Normal] セットした値が返る"
          When call session_get BUF "key1"
          The status should equal 0
          The output should equal "value1"
        End

        It "Then: [Normal] 存在しないキーは空文字を返す"
          When call session_get BUF "no_such_key"
          The status should equal 0
          The output should equal ""
        End
      End
    End

    Describe "When: session_set を呼ぶ"
      It "Then: [Normal] 新規キーに値をセットできる"
        session_set BUF "newkey" "newval"
        When call session_get BUF "newkey"
        The status should equal 0
        The output should equal "newval"
      End

      It "Then: [Normal] 既存キーを上書きできる"
        session_set BUF "existing" "first"
        session_set BUF "existing" "second"
        When call session_get BUF "existing"
        The status should equal 0
        The output should equal "second"
      End

      It "Then: [Normal] 空文字をセットできる"
        session_set BUF "emptykey" ""
        When call session_get BUF "emptykey"
        The status should equal 0
        The output should equal ""
      End
    End
  End

  Describe "session_load"
    Describe "Given: schema 未登録のバッファ"
      Before "declare -gA UNREGISTERED=()"

      Describe "When: session_load を呼ぶ"
        It "Then: [Error] exit 1 を返し Error: を stderr に出力する"
          When call session_load "/tmp/any.json" UNREGISTERED
          The status should equal 1
          The stderr should include "Error:"
        End
      End
    End

    Describe "Given: セッションファイルが存在しない"
      Before "declare -gA BUF=(); session_init BUF \"$SESSION_SCHEMA_TEST\""

      Describe "When: session_load を呼ぶ"
        It "Then: [Normal] exit 0 を返しデフォルト値で初期化される"
          When call session_load "/tmp/nonexistent_session_$$" BUF
          The status should equal 0
        End

        It "Then: [Normal] active はデフォルト値 false になる"
          session_load "/tmp/nonexistent_session_$$" BUF
          When call session_get BUF "active"
          The output should equal "false"
        End

        It "Then: [Normal] ai_model はデフォルト値 sonnet になる"
          session_load "/tmp/nonexistent_session_$$" BUF
          When call session_get BUF "ai_model"
          The output should equal "sonnet"
        End
      End
    End

    Describe "Given: 有効な JSON ファイルが存在する"
      Before "setup_deckrd_tmpdir; declare -gA BUF=(); session_init BUF \"$SESSION_SCHEMA_TEST\""
      After "teardown_deckrd_tmpdir"

      Describe "When: session_load を呼ぶ"
        It "Then: [Normal] active キーが読み込まれる"
          printf '{"active":"myproject","ai_model":"opus","lang":"ja"}' \
            > "${DECKRD_LOCAL}/session.kv"
          session_load "${DECKRD_LOCAL}/session" BUF
          When call session_get BUF "active"
          The status should equal 0
          The output should equal "myproject"
        End

        It "Then: [Normal] ai_model キーが読み込まれる"
          printf '{"active":"myproject","ai_model":"opus","lang":"ja"}' \
            > "${DECKRD_LOCAL}/session.kv"
          session_load "${DECKRD_LOCAL}/session" BUF
          When call session_get BUF "ai_model"
          The status should equal 0
          The output should equal "opus"
        End

        It "Then: [Normal] lang キーが読み込まれる"
          printf '{"active":"myproject","ai_model":"opus","lang":"ja"}' \
            > "${DECKRD_LOCAL}/session.kv"
          session_load "${DECKRD_LOCAL}/session" BUF
          When call session_get BUF "lang"
          The status should equal 0
          The output should equal "ja"
        End

        It "Then: [Normal] JSON に存在しないキーはデフォルト値になる"
          printf '{"active":"only-active"}' \
            > "${DECKRD_LOCAL}/session.kv"
          session_load "${DECKRD_LOCAL}/session" BUF
          When call session_get BUF "ai_model"
          The status should equal 0
          The output should equal "sonnet"
        End
      End
    End
  End

  Describe "session_save"
    Describe "Given: BUF にデータがセットされた状態"
      Before "setup_deckrd_tmpdir; declare -gA BUF=(); session_init BUF \"$SESSION_SCHEMA_TEST\""
      After "teardown_deckrd_tmpdir"

      Describe "When: session_save を呼ぶ"
        It "Then: [Normal] ファイルが作成される"
          session_set BUF "active" "testproj"
          session_save "${DECKRD_LOCAL}/session" BUF
          When call test -f "${DECKRD_LOCAL}/session.kv"
          The status should equal 0
        End

        It "Then: [Normal] ディレクトリが自動作成される"
          session_set BUF "active" "testproj"
          session_save "${DECKRD_LOCAL}/nested/dir/session" BUF
          When call test -f "${DECKRD_LOCAL}/nested/dir/session.kv"
          The status should equal 0
        End
      End
    End

    Describe "Given: save → load のラウンドトリップ"
      Before "setup_deckrd_tmpdir; declare -gA BUF=(); session_init BUF \"$SESSION_SCHEMA_TEST\""
      After "teardown_deckrd_tmpdir"

      Describe "When: save 後に load する"
        It "Then: [Normal] active の値が復元される"
          session_set BUF "active" "roundtrip-proj"
          session_set BUF "ai_model" "claude-3-5"
          session_set BUF "lang" "ja"
          session_save "${DECKRD_LOCAL}/session" BUF
          unset BUF
          declare -gA BUF
          session_init BUF "$SESSION_SCHEMA_TEST"
          session_load "${DECKRD_LOCAL}/session" BUF
          When call session_get BUF "active"
          The status should equal 0
          The output should equal "roundtrip-proj"
        End
      End
    End
  End

End
