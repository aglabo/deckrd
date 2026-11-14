#!/usr/bin/env bash
# session.spec.sh - ShellSpec tests for session.sh
#
# Copyright (c) 2026- atsushifx <https://github.com/atsushifx>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

# shellcheck disable=SC1090
# cspell:words myproject

_RUNTIME_BOOTSTRAP="${SHELLSPEC_PROJECT_ROOT}/skills/deckrd/skills/deckrd/scripts/libs/bootstrap.lib.sh"
. "$_RUNTIME_BOOTSTRAP" "--no-finalize"
unset _RUNTIME_BOOTSTRAP

Include "${SHELLSPEC_SPECFILE%/*}/../spec_helper.sh"

SCRIPT="${DECKRD_LIB_DIR}/session.lib.sh"
. "$SCRIPT"

# Schema used in tests
SESSION_SCHEMA_TEST="
active|false
ai_model|sonnet
lang|en
"

Describe "session.sh"

  Describe "T-LIB-SLD: session.sh loading"
    Describe "When: スクリプトを読み込む"
      It "Then: [Normal] T-LIB-SLD-01: session_init 関数が存在する"
        When call type session_init
        The status should equal 0
        The output should include "session_init"
      End

      It "Then: [Normal] T-LIB-SLD-02: session_load 関数が存在する"
        When call type session_load
        The status should equal 0
        The output should include "session_load"
      End

      It "Then: [Normal] T-LIB-SLD-03: session_save 関数が存在する"
        When call type session_save
        The status should equal 0
        The output should include "session_save"
      End

      It "Then: [Normal] T-LIB-SLD-04: session_get 関数が存在する"
        When call type session_get
        The status should equal 0
        The output should include "session_get"
      End

      It "Then: [Normal] T-LIB-SLD-05: session_set 関数が存在する"
        When call type session_set
        The status should equal 0
        The output should include "session_set"
      End
    End
  End

  Describe "T-LIB-SINI: session_init"
    Describe "Given: schema を登録する"
      Before "declare -gA BUF=()"

      Describe "When: session_init を呼ぶ"
        It "Then: [Normal] T-LIB-SINI-01: schema が SESSION_SCHEMA に登録される"
          session_init BUF "$SESSION_SCHEMA_TEST"
          When call test -n "${SESSION_SCHEMA[BUF]}"
          The status should equal 0
        End

        It "Then: [Normal] T-LIB-SINI-02: active のデフォルト値 false が設定される"
          session_init BUF "$SESSION_SCHEMA_TEST"
          When call session_get BUF "active"
          The status should equal 0
          The output should equal "false"
        End

        It "Then: [Normal] T-LIB-SINI-03: ai_model のデフォルト値 sonnet が設定される"
          session_init BUF "$SESSION_SCHEMA_TEST"
          When call session_get BUF "ai_model"
          The status should equal 0
          The output should equal "sonnet"
        End

        It "Then: [Normal] T-LIB-SINI-04: lang のデフォルト値 en が設定される"
          session_init BUF "$SESSION_SCHEMA_TEST"
          When call session_get BUF "lang"
          The status should equal 0
          The output should equal "en"
        End
      End
    End
  End

  Describe "T-LIB-SGS: session_get / session_set"
    Before "declare -gA BUF=(); session_init BUF \"$SESSION_SCHEMA_TEST\""

    Describe "Given: BUF にキーをセットした状態"
      Before "session_set BUF active myproject"

      Describe "When: session_get を呼ぶ"
        It "Then: [Normal] T-LIB-SGS-01: セットした値が返る"
          When call session_get BUF "active"
          The status should equal 0
          The output should equal "myproject"
        End

        It "Then: [Error] T-LIB-SGS-02: スキーマ外キーは exit 1 を返す"
          When call session_get BUF "no_such_key"
          The status should equal 1
          The stderr should include "Error:"
        End
      End
    End

    Describe "When: session_set を呼ぶ"
      It "Then: [Normal] T-LIB-SGS-03: 新規キーに値をセットできる"
        session_set BUF "ai_model" "claude-3-5"
        When call session_get BUF "ai_model"
        The status should equal 0
        The output should equal "claude-3-5"
      End

      It "Then: [Normal] T-LIB-SGS-04: 既存キーを上書きできる"
        session_set BUF "lang" "first"
        session_set BUF "lang" "second"
        When call session_get BUF "lang"
        The status should equal 0
        The output should equal "second"
      End

      It "Then: [Normal] T-LIB-SGS-05: 空文字をセットできる"
        session_set BUF "lang" ""
        When call session_get BUF "lang"
        The status should equal 0
        The output should equal ""
      End
    End
  End

  Describe "T-LIB-SLOAD: session_load"
    Describe "Given: schema 未登録のバッファ"
      Before "declare -gA UNREGISTERED=()"

      Describe "When: session_load を呼ぶ"
        It "Then: [Error] T-LIB-SLOAD-01: exit 1 を返し Error: を stderr に出力する"
          When call session_load "/tmp/any.json" UNREGISTERED
          The status should equal 1
          The stderr should include "Error:"
        End
      End
    End

    Describe "Given: セッションファイルが存在しない"
      Before "declare -gA BUF=(); session_init BUF \"$SESSION_SCHEMA_TEST\""

      Describe "When: session_load を呼ぶ"
        It "Then: [Normal] T-LIB-SLOAD-02: exit 0 を返しデフォルト値で初期化される"
          When call session_load "/tmp/nonexistent_session_$$" BUF
          The status should equal 0
        End

        It "Then: [Normal] T-LIB-SLOAD-03: active はデフォルト値 false になる"
          session_load "/tmp/nonexistent_session_$$" BUF
          When call session_get BUF "active"
          The output should equal "false"
        End

        It "Then: [Normal] T-LIB-SLOAD-04: ai_model はデフォルト値 sonnet になる"
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
        It "Then: [Normal] T-LIB-SLOAD-05: active キーが読み込まれる"
          printf '{"active":"myproject","ai_model":"opus","lang":"ja"}' \
            > "${DECKRD_LOCAL}/session.kv"
          session_load "${DECKRD_LOCAL}/session" BUF
          When call session_get BUF "active"
          The status should equal 0
          The output should equal "myproject"
        End

        It "Then: [Normal] T-LIB-SLOAD-06: ai_model キーが読み込まれる"
          printf '{"active":"myproject","ai_model":"opus","lang":"ja"}' \
            > "${DECKRD_LOCAL}/session.kv"
          session_load "${DECKRD_LOCAL}/session" BUF
          When call session_get BUF "ai_model"
          The status should equal 0
          The output should equal "opus"
        End

        It "Then: [Normal] T-LIB-SLOAD-07: lang キーが読み込まれる"
          printf '{"active":"myproject","ai_model":"opus","lang":"ja"}' \
            > "${DECKRD_LOCAL}/session.kv"
          session_load "${DECKRD_LOCAL}/session" BUF
          When call session_get BUF "lang"
          The status should equal 0
          The output should equal "ja"
        End

        It "Then: [Normal] T-LIB-SLOAD-08: JSON に存在しないキーはデフォルト値になる"
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

  Describe "T-LIB-SSAVE: session_save"
    Describe "Given: BUF にデータがセットされた状態"
      Before "setup_deckrd_tmpdir; declare -gA BUF=(); session_init BUF \"$SESSION_SCHEMA_TEST\""
      After "teardown_deckrd_tmpdir"

      Describe "When: session_save を呼ぶ"
        It "Then: [Normal] T-LIB-SSAVE-01: ファイルが作成される"
          session_set BUF "active" "testproj"
          session_save "${DECKRD_LOCAL}/session" BUF
          When call test -f "${DECKRD_LOCAL}/session.kv"
          The status should equal 0
        End

        It "Then: [Normal] T-LIB-SSAVE-02: ディレクトリが自動作成される"
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
        It "Then: [Normal] T-LIB-SSAVE-03: active の値が復元される"
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

  Describe "T-LIB-SMIG: session_migrate_lang_to_prog"
    Before "setup_deckrd_tmpdir"
    After "teardown_deckrd_tmpdir"

    # Helper: entries of DECKRD_LOCAL (including dotfiles), for leftover-file checks
    session_dir_entries() {
      ls -A "${DECKRD_LOCAL}"
    }

    # Helper: session.json normalized with sorted keys, for structural comparison
    session_json_sorted() {
      jq -c -S . "${DECKRD_LOCAL}/session.json"
    }

    Describe "Given: lang にプログラミング言語が入り prog が無い session.json"
      Describe "When: session_migrate_lang_to_prog を呼ぶ"
        Describe "Then: Task T-01-01 - lang を prog に移行する"
          It "[Normal] T-LIB-SMIG-01: lang=typescript が prog=typescript に移り lang が消える"
            printf '{"lang":"typescript"}' > "${DECKRD_LOCAL}/session.json"
            When call session_migrate_lang_to_prog "${DECKRD_LOCAL}/session.json"
            The status should equal 0
            The result of function session_json_sorted should equal '{"prog":"typescript"}'
          End

          It "[Normal] T-LIB-SMIG-02: lang 以外のキーは全て保持される"
            printf '%s' '{"active":"deckrd/core","ai_model":"sonnet","lang":"go","modules":["deckrd/core"],"bdd_coder":{"enabled":true},"created_at":"2026-01-01T00:00:00Z"}' \
              > "${DECKRD_LOCAL}/session.json"
            When call session_migrate_lang_to_prog "${DECKRD_LOCAL}/session.json"
            The status should equal 0
            The result of function session_json_sorted should equal '{"active":"deckrd/core","ai_model":"sonnet","bdd_coder":{"enabled":true},"created_at":"2026-01-01T00:00:00Z","modules":["deckrd/core"],"prog":"go"}'
          End

          It "[Normal] T-LIB-SMIG-03: stderr に 1 行だけ出力し stdout は空"
            printf '{"lang":"python"}' > "${DECKRD_LOCAL}/session.json"
            When call session_migrate_lang_to_prog "${DECKRD_LOCAL}/session.json"
            The status should equal 0
            The output should equal ""
            The lines of stderr should equal 1
          End
        End
      End
    End

    Describe "Given: 移行の必要が無い session.json"
      Describe "When: session_migrate_lang_to_prog を呼ぶ"
        Describe "Then: Task T-01-02 - 何もせず内容不変で return 0"
          It "[Normal] T-LIB-SMIG-04: prog が既に存在すれば変更しない"
            printf '{"lang":"typescript","prog":"go"}' > "${DECKRD_LOCAL}/session.json"
            before="$(cat "${DECKRD_LOCAL}/session.json")"
            When call session_migrate_lang_to_prog "${DECKRD_LOCAL}/session.json"
            The status should equal 0
            The stderr should equal ""
            The contents of file "${DECKRD_LOCAL}/session.json" should equal "$before"
          End

          It "[Normal] T-LIB-SMIG-05: lang キーが無ければ変更しない"
            printf '{"active":"deckrd/core"}' > "${DECKRD_LOCAL}/session.json"
            before="$(cat "${DECKRD_LOCAL}/session.json")"
            When call session_migrate_lang_to_prog "${DECKRD_LOCAL}/session.json"
            The status should equal 0
            The stderr should equal ""
            The contents of file "${DECKRD_LOCAL}/session.json" should equal "$before"
          End

          It "[Normal] T-LIB-SMIG-06: lang がドキュメント言語コード ja なら変更しない"
            printf '{"lang":"ja"}' > "${DECKRD_LOCAL}/session.json"
            before="$(cat "${DECKRD_LOCAL}/session.json")"
            When call session_migrate_lang_to_prog "${DECKRD_LOCAL}/session.json"
            The status should equal 0
            The stderr should equal ""
            The contents of file "${DECKRD_LOCAL}/session.json" should equal "$before"
          End

          It "[Normal] T-LIB-SMIG-07: lang が特別値 system なら変更しない"
            printf '{"lang":"system"}' > "${DECKRD_LOCAL}/session.json"
            before="$(cat "${DECKRD_LOCAL}/session.json")"
            When call session_migrate_lang_to_prog "${DECKRD_LOCAL}/session.json"
            The status should equal 0
            The stderr should equal ""
            The contents of file "${DECKRD_LOCAL}/session.json" should equal "$before"
          End
        End
      End
    End

    Describe "Given: session.json が無い、または JSON オブジェクトとして読めない"
      Describe "When: session_migrate_lang_to_prog を呼ぶ"
        Describe "Then: Task T-01-03 - エラーを出して return 1"
          It "[Error] T-LIB-SMIG-08: 存在しないパスは return 1 でファイルを作らない"
            When call session_migrate_lang_to_prog "${DECKRD_LOCAL}/missing.json"
            The status should equal 1
            The stderr should include "Error"
            The path "${DECKRD_LOCAL}/missing.json" should not be exist
          End

          It "[Error] T-LIB-SMIG-09: 不正な JSON は return 1 でファイル不変"
            printf '{"lang":' > "${DECKRD_LOCAL}/session.json"
            before="$(cat "${DECKRD_LOCAL}/session.json")"
            When call session_migrate_lang_to_prog "${DECKRD_LOCAL}/session.json"
            The status should equal 1
            The stderr should include "Error"
            The contents of file "${DECKRD_LOCAL}/session.json" should equal "$before"
          End

          It "[Error] T-LIB-SMIG-10: JSON 配列 (オブジェクトでない) は return 1 でファイル不変"
            printf '["typescript"]' > "${DECKRD_LOCAL}/session.json"
            before="$(cat "${DECKRD_LOCAL}/session.json")"
            When call session_migrate_lang_to_prog "${DECKRD_LOCAL}/session.json"
            The status should equal 1
            The stderr should include "Error"
            The contents of file "${DECKRD_LOCAL}/session.json" should equal "$before"
          End
        End
      End
    End

    Describe "Given: 境界値・特殊値の session.json"
      Describe "When: session_migrate_lang_to_prog を呼ぶ"
        Describe "Then: Task T-01-04 - 許可リストの完全一致だけを移行する"
          It "[Edge] T-LIB-SMIG-11: 許可リスト末尾の bash は移行される"
            printf '{"lang":"bash"}' > "${DECKRD_LOCAL}/session.json"
            When call session_migrate_lang_to_prog "${DECKRD_LOCAL}/session.json"
            The status should equal 0
            The stderr should be present
            The result of function session_json_sorted should equal '{"prog":"bash"}'
          End

          It "[Edge] T-LIB-SMIG-12: lang が空文字なら変更しない"
            printf '{"lang":""}' > "${DECKRD_LOCAL}/session.json"
            before="$(cat "${DECKRD_LOCAL}/session.json")"
            When call session_migrate_lang_to_prog "${DECKRD_LOCAL}/session.json"
            The status should equal 0
            The stderr should equal ""
            The contents of file "${DECKRD_LOCAL}/session.json" should equal "$before"
          End

          It "[Edge] T-LIB-SMIG-13: 前方一致だけの typescripts は変更しない"
            printf '{"lang":"typescripts"}' > "${DECKRD_LOCAL}/session.json"
            before="$(cat "${DECKRD_LOCAL}/session.json")"
            When call session_migrate_lang_to_prog "${DECKRD_LOCAL}/session.json"
            The status should equal 0
            The stderr should equal ""
            The contents of file "${DECKRD_LOCAL}/session.json" should equal "$before"
          End

          It "[Edge] T-LIB-SMIG-14: 0 バイトのファイルは return 1 で 0 バイトのまま"
            : > "${DECKRD_LOCAL}/session.json"
            When call session_migrate_lang_to_prog "${DECKRD_LOCAL}/session.json"
            The status should equal 1
            The stderr should include "Error"
            The file "${DECKRD_LOCAL}/session.json" should be empty file
          End
        End
      End
    End

    Describe "Given: session.json だけがあるディレクトリ"
      Describe "When: session_migrate_lang_to_prog で移行する"
        Describe "Then: Task T-01-05 - 一時ファイル経由で書き込み残骸を残さない"
          It "[Normal] T-LIB-SMIG-15: 移行後のディレクトリには session.json だけが残る"
            printf '{"lang":"rust"}' > "${DECKRD_LOCAL}/session.json"
            When call session_migrate_lang_to_prog "${DECKRD_LOCAL}/session.json"
            The status should equal 0
            The stderr should be present
            The result of function session_json_sorted should equal '{"prog":"rust"}'
            The result of function session_dir_entries should equal "session.json"
          End
        End
      End
    End

    Describe "Given: 一度移行した session.json"
      Describe "When: session_migrate_lang_to_prog を再度呼ぶ"
        Describe "Then: Task T-01-06 - 2 回目は no-op (冪等)"
          It "[Normal] T-LIB-SMIG-16: 2 回目は return 0 で stderr 空、内容は 1 回目の結果のまま"
            printf '{"lang":"typescript"}' > "${DECKRD_LOCAL}/session.json"
            session_migrate_lang_to_prog "${DECKRD_LOCAL}/session.json" 2>/dev/null
            after_first="$(cat "${DECKRD_LOCAL}/session.json")"
            When call session_migrate_lang_to_prog "${DECKRD_LOCAL}/session.json"
            The status should equal 0
            The stderr should equal ""
            The contents of file "${DECKRD_LOCAL}/session.json" should equal "$after_first"
            The result of function session_json_sorted should equal '{"prog":"typescript"}'
          End
        End
      End
    End
  End

  Describe "T-LIB-SLMN: session_lang_migration_needed"
    Before "setup_deckrd_tmpdir"
    After "teardown_deckrd_tmpdir"

    Describe "Given: lang にプログラミング言語が入り prog が無い session.json"
      Describe "When: session_lang_migration_needed を呼ぶ"
        Describe "Then: Task T-01-01 - 移行が必要なら return 0"
          It "[Normal] T-LIB-SLMN-01: lang=typescript は return 0 で出力なし、ファイル不変"
            printf '{"active":"true","lang":"typescript"}' > "${DECKRD_LOCAL}/session.json"
            before="$(cat "${DECKRD_LOCAL}/session.json")"
            When call session_lang_migration_needed "${DECKRD_LOCAL}/session.json"
            The status should equal 0
            The output should equal ""
            The stderr should equal ""
            The contents of file "${DECKRD_LOCAL}/session.json" should equal "$before"
          End
        End
      End
    End

    Describe "Given: 移行の必要が無い JSON オブジェクトの session.json"
      Describe "When: session_lang_migration_needed を呼ぶ"
        Describe "Then: Task T-01-02 - 移行不要なら return 1"
          It "[Normal] T-LIB-SLMN-02: prog が既にあれば return 1 で出力なし"
            printf '{"lang":"typescript","prog":"go"}' > "${DECKRD_LOCAL}/session.json"
            When call session_lang_migration_needed "${DECKRD_LOCAL}/session.json"
            The status should equal 1
            The output should equal ""
            The stderr should equal ""
          End

          It "[Normal] T-LIB-SLMN-03: lang がドキュメント言語コード ja なら return 1 で出力なし"
            printf '{"lang":"ja"}' > "${DECKRD_LOCAL}/session.json"
            When call session_lang_migration_needed "${DECKRD_LOCAL}/session.json"
            The status should equal 1
            The output should equal ""
            The stderr should equal ""
          End

          It "[Normal] T-LIB-SLMN-04: lang キーが無ければ return 1 で出力なし"
            printf '{"active":"true"}' > "${DECKRD_LOCAL}/session.json"
            When call session_lang_migration_needed "${DECKRD_LOCAL}/session.json"
            The status should equal 1
            The output should equal ""
            The stderr should equal ""
          End
        End
      End
    End

    Describe "Given: session.json が無い、または JSON オブジェクトとして読めない"
      Describe "When: session_lang_migration_needed を呼ぶ"
        Describe "Then: Task T-01-03 - エラーを出して return 2"
          It "[Error] T-LIB-SLMN-05: 存在しないパスは return 2 でファイルを作らない"
            When call session_lang_migration_needed "${DECKRD_LOCAL}/missing/session.json"
            The status should equal 2
            The output should equal ""
            The stderr should include "Error:"
            The path "${DECKRD_LOCAL}/missing/session.json" should not be exist
          End

          It "[Error] T-LIB-SLMN-06: JSON 配列 (オブジェクトでない) は return 2"
            printf '["lang","typescript"]' > "${DECKRD_LOCAL}/session.json"
            When call session_lang_migration_needed "${DECKRD_LOCAL}/session.json"
            The status should equal 2
            The output should equal ""
            The stderr should include "Error:"
          End

          It "[Error] T-LIB-SLMN-07: 不正な JSON (閉じ括弧なし) は return 2"
            printf '{"lang":"typescript"' > "${DECKRD_LOCAL}/session.json"
            When call session_lang_migration_needed "${DECKRD_LOCAL}/session.json"
            The status should equal 2
            The output should equal ""
            The stderr should include "Error:"
          End
        End
      End
    End

    Describe "Given: 境界値・特殊値の session.json"
      Describe "When: session_lang_migration_needed を呼ぶ"
        Describe "Then: Task T-01-04 - 許可リストの完全一致だけを移行要とし、空ファイルはエラー"
          It "[Edge] T-LIB-SLMN-08: 許可リスト末尾の bash は return 0 で出力なし"
            printf '{"lang":"bash"}' > "${DECKRD_LOCAL}/session.json"
            When call session_lang_migration_needed "${DECKRD_LOCAL}/session.json"
            The status should equal 0
            The output should equal ""
            The stderr should equal ""
          End

          It "[Edge] T-LIB-SLMN-09: 前方一致だけの typescripts は return 1 で出力なし"
            printf '{"lang":"typescripts"}' > "${DECKRD_LOCAL}/session.json"
            When call session_lang_migration_needed "${DECKRD_LOCAL}/session.json"
            The status should equal 1
            The output should equal ""
            The stderr should equal ""
          End

          It "[Edge] T-LIB-SLMN-10: 0 バイトのファイルは return 2 で 0 バイトのまま"
            : > "${DECKRD_LOCAL}/session.json"
            When call session_lang_migration_needed "${DECKRD_LOCAL}/session.json"
            The status should equal 2
            The output should equal ""
            The stderr should include "Error:"
            The file "${DECKRD_LOCAL}/session.json" should be empty file
          End
        End
      End
    End
  End

End
