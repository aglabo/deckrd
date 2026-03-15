#!/usr/bin/env bash
# session.spec.sh - ShellSpec tests for session.sh
#
# Copyright (c) 2026- atsushifx <https://github.com/atsushifx>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

Include spec_helper.sh

SCRIPT="${DECKRD_LIB_DIR}/session.sh"

# shellcheck disable=SC1090
. "$SCRIPT"

Describe "session.sh"

  Describe "session.sh loading"
    Describe "When: スクリプトを読み込む"
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

  Describe "session_get / session_set"

    Describe "Given: SESSION 配列にキーをセットした状態"
      Before "SESSION=(); SESSION[key1]=value1"

      Describe "When: session_get を呼ぶ"
        It "Then: [Normal] セットした値が返る"
          When call session_get "key1"
          The status should equal 0
          The output should equal "value1"
        End

        It "Then: [Normal] 存在しないキーは空文字を返す"
          When call session_get "no_such_key"
          The status should equal 0
          The output should equal ""
        End
      End
    End

    Describe "Given: SESSION 配列が空の状態"
      Before "SESSION=()"

      Describe "When: session_set を呼ぶ"
        It "Then: [Normal] 新規キーに値をセットできる"
          session_set "newkey" "newval"
          When call session_get "newkey"
          The status should equal 0
          The output should equal "newval"
        End

        It "Then: [Normal] 既存キーを上書きできる"
          session_set "existing" "first"
          session_set "existing" "second"
          When call session_get "existing"
          The status should equal 0
          The output should equal "second"
        End

        It "Then: [Normal] 空文字をセットできる"
          session_set "emptykey" ""
          When call session_get "emptykey"
          The status should equal 0
          The output should equal ""
        End
      End
    End

  End

  Describe "session_load"

    Describe "Given: セッションファイルが存在しない"
      Before "SESSION=()"

      Describe "When: session_load を呼ぶ"
        It "Then: [Error] exit 1 を返す"
          When call session_load "/tmp/nonexistent_session_file_$$"
          The status should equal 1
        End
      End
    End

    Describe "Given: 有効な session.json が存在する (jq あり)"
      Before "setup_deckrd_tmpdir; SESSION=()"
      After "teardown_deckrd_tmpdir"

      Describe "When: session_load を呼ぶ"
        It "Then: [Normal] active キーが SESSION に読み込まれる"
          printf '{"active":"myproject","ai_model":"sonnet","lang":"ja"}' \
            >"${DECKRD_LOCAL}/session.json"
          session_load "${DECKRD_LOCAL}/session.json"
          When call session_get "active"
          The status should equal 0
          The output should equal "myproject"
        End

        It "Then: [Normal] ai_model キーが SESSION に読み込まれる"
          printf '{"active":"myproject","ai_model":"sonnet","lang":"ja"}' \
            >"${DECKRD_LOCAL}/session.json"
          session_load "${DECKRD_LOCAL}/session.json"
          When call session_get "ai_model"
          The status should equal 0
          The output should equal "sonnet"
        End

        It "Then: [Normal] lang キーが SESSION に読み込まれる"
          printf '{"active":"myproject","ai_model":"sonnet","lang":"ja"}' \
            >"${DECKRD_LOCAL}/session.json"
          session_load "${DECKRD_LOCAL}/session.json"
          When call session_get "lang"
          The status should equal 0
          The output should equal "ja"
        End

        It "Then: [Normal] キーが欠損しても空文字で読み込まれる"
          printf '{"active":"only-active"}' \
            >"${DECKRD_LOCAL}/session.json"
          session_load "${DECKRD_LOCAL}/session.json"
          When call session_get "ai_model"
          The status should equal 0
          The output should equal ""
        End
      End
    End

    Describe "Given: 有効な session.json が存在する (jq なし / fallback)"
      Before "setup_deckrd_tmpdir"
      After "teardown_deckrd_tmpdir"

      Describe "When: _session_extract_json_fallback を呼ぶ"
        It "Then: [Normal] active の値が返る"
          printf '{"active":"fb-project","ai_model":"opus","lang":"en"}' \
            >"${DECKRD_LOCAL}/session.json"
          When call _session_extract_json_fallback "${DECKRD_LOCAL}/session.json" "active"
          The status should equal 0
          The output should equal "fb-project"
        End
      End
    End

  End

  Describe "session_save"

    Describe "Given: SESSION にデータがセットされた状態"
      Before "setup_deckrd_tmpdir; SESSION=()"
      After "teardown_deckrd_tmpdir"

      Describe "When: session_save を呼ぶ"
        It "Then: [Normal] ファイルが作成される"
          SESSION["active"]="testproj"
          session_save "${DECKRD_LOCAL}/session.json"
          When call test -f "${DECKRD_LOCAL}/session.json"
          The status should equal 0
        End

        It "Then: [Normal] ディレクトリが自動作成される"
          SESSION["active"]="testproj"
          session_save "${DECKRD_LOCAL}/nested/dir/session.json"
          When call test -f "${DECKRD_LOCAL}/nested/dir/session.json"
          The status should equal 0
        End
      End
    End

    Describe "Given: SESSION にデータをセットして save → load する"
      Before "setup_deckrd_tmpdir; SESSION=()"
      After "teardown_deckrd_tmpdir"

      Describe "When: ラウンドトリップ (save → load)"
        It "Then: [Normal] active の値が復元される"
          SESSION["active"]="roundtrip-proj"
          SESSION["ai_model"]="claude-3-5"
          SESSION["lang"]="ja"
          session_save "${DECKRD_LOCAL}/session.json"
          SESSION=()
          session_load "${DECKRD_LOCAL}/session.json"
          When call session_get "active"
          The status should equal 0
          The output should equal "roundtrip-proj"
        End
      End
    End

  End

End
