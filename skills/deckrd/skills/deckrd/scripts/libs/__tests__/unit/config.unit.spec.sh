#!/usr/bin/env bash
# config.spec.sh - ShellSpec tests for config.sh
#
# Copyright (c) 2026- atsushifx <https://github.com/atsushifx>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

# shellcheck disable=SC1090,SC1091
# cspell:words myproject myns mymod jqexe jaq

_RUNTIME_BOOTSTRAP="${SHELLSPEC_PROJECT_ROOT}/skills/deckrd/skills/deckrd/scripts/libs/bootstrap.lib.sh"
. "$_RUNTIME_BOOTSTRAP" "--no-finalize"
unset _RUNTIME_BOOTSTRAP

Include ../spec_helper.sh

. "${DECKRD_LIB_DIR}/session.lib.sh"
. "${DECKRD_LIB_DIR}/config.lib.sh"

# ============================================================================
# 内部ヘルパー
# ============================================================================

# 関数

# _write_session_json - 標準入力の内容を ${DECKRD_LOCAL}/session.json に書き出す
#
# 各フィクスチャ共通の書き出し処理。中身だけがケースごとに変わるので、
# 置き場所とディレクトリ作成をここに 1 箇所だけ持つ。
#
# 前提: setup_deckrd_tmpdir が DECKRD_LOCAL を export していること
#
# @stdin session.json として書き出す JSON テキスト
# @return 0 always
_write_session_json() {
  mkdir -p "$DECKRD_LOCAL"
  cat >"${DECKRD_LOCAL}/session.json"
}

# _write_session_json_minimal - deckrd が読む 3 キーだけを持つ session.json を書き出す
#
# active / ai_model / lang の反映だけを検査するための最小形式。
# active は 1 階層 (myproject) とし、deckrd_base の連結結果を短く保つ。
#
# 前提: setup_deckrd_tmpdir が DECKRD_LOCAL を export していること
#
# @return 0 always
_write_session_json_minimal() {
  _write_session_json <<'JSON'
{
  "active": "myproject",
  "ai_model": "opus",
  "lang": "ja"
}
JSON
}

# _write_session_json_broken - JSON として閉じていない session.json を書き出す
#
# 途中で切れた書き込みや手による編集ミスを模す。config_init が壊れた入力を
# 既定値で素通りさせないことを検査する。
#
# 前提: setup_deckrd_tmpdir が DECKRD_LOCAL を export していること
#
# @return 0 always
_write_session_json_broken() {
  _write_session_json <<'JSON'
{
  "active": "myproject",
  "ai_model": "opus
JSON
}

# _write_session_json_empty - 0 バイトの session.json を書き出す
#
# 書き込みが始まる前に中断された状態を模す。空入力を妥当な JSON と見なす判定は
# 存在するため、この入力が既定値のまま無言で素通りしないことを検査する。
#
# 前提: setup_deckrd_tmpdir が DECKRD_LOCAL を export していること
#
# @return 0 always
_write_session_json_empty() {
  _write_session_json </dev/null
}

# _write_session_json_array - トップレベルが配列の session.json を書き出す
#
# JSON としては妥当だがオブジェクトではない入力を模す。値の取得が生の jq エラー
# (Cannot index array with string) を stderr に漏らさないことを検査する。
#
# 前提: setup_deckrd_tmpdir が DECKRD_LOCAL を export していること
#
# @return 0 always
_write_session_json_array() {
  _write_session_json <<'JSON'
[]
JSON
}

# _write_session_json_null_active - active が null の session.json を書き出す
#
# session_save がアクティブモジュール未設定のまま書き出した状態を模す。
# JSON の null が空文字として扱われ、deckrd_base が組み立てられないことを検査する。
#
# 前提: setup_deckrd_tmpdir が DECKRD_LOCAL を export していること
#
# @return 0 always
_write_session_json_null_active() {
  _write_session_json <<'JSON'
{
  "active": null,
  "ai_model": "opus",
  "lang": "ja"
}
JSON
}

# _write_session_json_real - 実運用形式の session.json を書き出す
#
# deckrd が実際に保存する形を再現する。ネストした modules と created_at /
# updated_at を含み、active は <namespace>/<module> の 2 階層とする。
# これにより deckrd_base が階層を保ったまま解決されることを検査できる。
#
# 前提: setup_deckrd_tmpdir が DECKRD_LOCAL を export していること
#
# @return 0 always
_write_session_json_real() {
  _write_session_json <<'JSON'
{
  "active": "myns/mymod",
  "ai_model": "opus",
  "lang": "ja",
  "modules": {
    "myns/mymod": {
      "current_step": "req",
      "completed": ["module", "req"]
    }
  },
  "created_at": "2025-01-01T00:00:00Z",
  "updated_at": "2026-06-01T00:00:00Z"
}
JSON
}

Describe "config.sh"
  Describe "T-LIB-CLD: config.sh loading"
    Describe "When: スクリプトを読み込む"
      It "Then: [Normal] T-LIB-CLD-01: config_init 関数が存在する"
        When call type config_init
        The status should equal 0
        The output should include "config_init"
      End

      It "Then: [Normal] T-LIB-CLD-02: config_get 関数が存在する"
        When call type config_get
        The status should equal 0
        The output should include "config_get"
      End

      It "Then: [Normal] T-LIB-CLD-03: config_set 関数が存在する"
        When call type config_set
        The status should equal 0
        The output should include "config_set"
      End

      It "Then: [Normal] T-LIB-CLD-04: config_all 関数が存在する"
        When call type config_all
        The status should equal 0
        The output should include "config_all"
      End
    End
  End

  Describe "T-LIB-CGS: config_get / config_set"
    Describe "Given: config_init 済みの状態"
      Before "config_init"

      Describe "When: config_get を呼ぶ"
        It "Then: [Normal] T-LIB-CGS-01: セットした値が返る"
          config_set "lang" "ja"
          When call config_get "lang"
          The status should equal 0
          The output should equal "ja"
        End

        It "Then: [Error] T-LIB-CGS-02: スキーマ外のキーはエラーになる"
          When call config_get "no_such_key"
          The status should equal 1
          The stderr should include "not in schema"
        End
      End

      Describe "When: config_set を呼ぶ"
        It "Then: [Normal] T-LIB-CGS-03: スキーマ内キーに値をセットできる"
          config_set "lang" "en"
          When call config_get "lang"
          The status should equal 0
          The output should equal "en"
        End

        It "Then: [Normal] T-LIB-CGS-04: 既存キーを上書きできる"
          config_set "lang" "first"
          config_set "lang" "second"
          When call config_get "lang"
          The status should equal 0
          The output should equal "second"
        End

        It "Then: [Normal] T-LIB-CGS-05: 空文字をセットできる"
          config_set "doc_type" ""
          When call config_get "doc_type"
          The status should equal 0
          The output should equal ""
        End

        It "Then: [Error] T-LIB-CGS-06: スキーマ外のキーはエラーになる"
          When call config_set "no_such_key" "val"
          The status should equal 1
          The stderr should include "not in schema"
        End
      End
    End
  End

  Describe "T-LIB-CALL: config_all"
    Describe "Given: CONFIG に複数のキーがセットされた状態"
      Before "config_init; config_set 'ai_model' 'sonnet'; config_set 'lang' 'ja'"

      Describe "When: config_all を呼ぶ"
        It "Then: [Normal] T-LIB-CALL-01: ai_model=sonnet が出力に含まれる"
          When call config_all
          The status should equal 0
          The output should include "ai_model=sonnet"
        End

        It "Then: [Normal] T-LIB-CALL-02: lang=ja が出力に含まれる"
          When call config_all
          The status should equal 0
          The output should include "lang=ja"
        End
      End
    End
  End

  Describe "T-LIB-CINI: config_init"
    Describe "Given: セッションファイルなし（引数省略）"
      Before "CONFIG=()"

      Describe "When: config_init を引数なしで呼ぶ"
        It "Then: [Normal] T-LIB-CINI-01: ai_model のデフォルト値が sonnet になる"
          config_init
          When call config_get "ai_model"
          The status should equal 0
          The output should equal "sonnet"
        End

        It "Then: [Normal] T-LIB-CINI-02: lang のデフォルト値が system になる"
          config_init
          When call config_get "lang"
          The status should equal 0
          The output should equal "system"
        End

        It "Then: [Normal] T-LIB-CINI-03: doc_type のデフォルト値が空文字になる"
          config_init
          When call config_get "doc_type"
          The status should equal 0
          The output should equal ""
        End

        It "Then: [Normal] T-LIB-CINI-04: prompt_mode のデフォルト値が 0 になる"
          config_init
          When call config_get "prompt_mode"
          The status should equal 0
          The output should equal "0"
        End
      End
    End

    Describe "Given: 実セッション形式の session.json が存在する"
      Before "setup_deckrd_tmpdir; unset DECKRD_DOCS; CONFIG=(); SESSION=()"
      After "teardown_deckrd_tmpdir"

      Describe "When: 正常系"
        It "Then: [Normal] T-LIB-CINI-08: modules/created_at/updated_at を含む実形式 JSON でも active が読める"
          _write_session_json_real
          config_init "${DECKRD_LOCAL}/session.json"
          When call config_get "deckrd_base"
          The status should equal 0
          The output should equal "${DECKRD_DOCS_DIR}/myns/mymod"
        End

        It "Then: [Normal] T-LIB-CINI-05: セッションの ai_model が CONFIG に読み込まれる"
          _write_session_json_minimal
          config_init "${DECKRD_LOCAL}/session.json"
          When call config_get "ai_model"
          The status should equal 0
          The output should equal "opus"
        End

        It "Then: [Normal] T-LIB-CINI-06: セッションの lang が CONFIG に読み込まれる"
          _write_session_json_minimal
          config_init "${DECKRD_LOCAL}/session.json"
          When call config_get "lang"
          The status should equal 0
          The output should equal "ja"
        End

        It "Then: [Normal] T-LIB-CINI-07: セッションの active から deckrd_base が計算される"
          _write_session_json_minimal
          config_init "${DECKRD_LOCAL}/session.json"
          When call config_get "deckrd_base"
          The status should equal 0
          The output should equal "${DECKRD_DOCS_DIR}/myproject"
        End
      End
    End

    Describe "Given: JSON オブジェクトとして読めない session.json が存在する"
      Before "setup_deckrd_tmpdir; unset DECKRD_DOCS; CONFIG=(); SESSION=()"
      After "teardown_deckrd_tmpdir"

      Describe "When: 異常系"
        It "Then: [Error] T-LIB-CINI-09: 壊れた JSON は status 1 で報告する"
          _write_session_json_broken
          When call config_init "${DECKRD_LOCAL}/session.json"
          The status should equal 1
          The stderr should include "Error: config_init:"
        End

        It "Then: [Error] T-LIB-CINI-12: 0 バイトのセッションファイルは status 1 で報告する"
          _write_session_json_empty
          When call config_init "${DECKRD_LOCAL}/session.json"
          The status should equal 1
          The stderr should include "Error: config_init:"
        End

        It "Then: [Error] T-LIB-CINI-13: オブジェクトでない JSON は status 1 で報告し生の jq エラーを漏らさない"
          _write_session_json_array
          When call config_init "${DECKRD_LOCAL}/session.json"
          The status should equal 1
          The stderr should include "Error: config_init:"
          The stderr should not include "Cannot index"
        End
      End
    End

    Describe "Given: session.json は正常だが jq も jaq も利用できない"
      Before "setup_deckrd_tmpdir; unset DECKRD_DOCS; CONFIG=(); SESSION=(); export jqexe='deckrd-no-such-jq'"
      After "unset jqexe; teardown_deckrd_tmpdir"

      Describe "When: 異常系"
        It "Then: [Error] T-LIB-CINI-14: jq インタプリタ不在は探した名前を挙げて status 1 で報告する"
          _write_session_json_minimal
          When call config_init "${DECKRD_LOCAL}/session.json"
          The status should equal 1
          The stderr should include "deckrd-no-such-jq"
        End

        It "Then: [Error] T-LIB-CINI-15: jq インタプリタ不在を session.json の形状不正として報告しない"
          _write_session_json_minimal
          When call config_init "${DECKRD_LOCAL}/session.json"
          The status should equal 1
          The stderr should not include "as a JSON object"
        End
      End
    End

    Describe "Given: session.json がまだ作成されていない"
      Before "setup_deckrd_tmpdir; unset DECKRD_DOCS; CONFIG=(); SESSION=()"
      After "teardown_deckrd_tmpdir"

      Describe "When: エッジケース"
        It "Then: [Edge] T-LIB-CINI-10: セッションファイル不在は既定値のまま静かに成功する"
          When call config_init "${DECKRD_LOCAL}/session.json"
          The status should equal 0
          The stderr should equal ""
          The value "$(config_get "ai_model")" should equal "sonnet"
        End
      End
    End

    Describe "Given: active が null の session.json が存在する"
      Before "setup_deckrd_tmpdir; unset DECKRD_DOCS; CONFIG=(); SESSION=()"
      After "teardown_deckrd_tmpdir"

      Describe "When: エッジケース"
        It "Then: [Edge] T-LIB-CINI-11: active が null なら deckrd_base を設定しない"
          _write_session_json_null_active
          config_init "${DECKRD_LOCAL}/session.json"
          When call config_get "deckrd_base"
          The status should equal 0
          The output should equal ""
        End
      End
    End
  End
End
