#!/usr/bin/env bash
# status.spec.sh - ShellSpec tests for status.sh
#
# Copyright (c) 2025 atsushifx <https://github.com/atsushifx>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

# shellcheck disable=SC1090

# ============================================================================
# テスト基盤
# ============================================================================

_RUNTIME_BOOTSTRAP="${SHELLSPEC_PROJECT_ROOT}/skills/deckrd/skills/deckrd/scripts/libs/bootstrap.lib.sh"
. "$_RUNTIME_BOOTSTRAP" "--no-finalize"
unset _RUNTIME_BOOTSTRAP

Include ../spec_helper.sh

# ============================================================================
# テスト対象
# ============================================================================

SCRIPT="${DECKRD_SCRIPTS_DIR}/status.sh"

# ============================================================================
# 内部ヘルパー
# ============================================================================

# 定数

# _UNSET - _apply_docs_override に「DECKRD_DOCS を unset する」と伝える印。実パスと衝突しない固有値
_UNSET='<unset>'

# _ACTIVE_MODULE - session.json の active に書く値。Module Path の末尾に現れる
_ACTIVE_MODULE='myns/mymod'

# _SENTINEL_DOCS - DECKRD_DOCS に入れるセンチネル。上書き枠が最優先で返ることの確認に使う
#
# DECKRD_DOCS_DIR (一時ディレクトリ) と必ず異なる実在しないパスにする。
# 検証対象は表示される文字列の優先順位であり、パスの実在ではない。
_SENTINEL_DOCS='/deckrd-sentinel/status-docs-override'

# 関数

# _write_valid_session - active モジュールを持つ session.json を一時ディレクトリへ書く
#
# @return 0 always
_write_valid_session() {
  mkdir -p "$DECKRD_LOCAL"
  cat >"${DECKRD_LOCAL}/session.json" <<JSON
{
  "active": "${_ACTIVE_MODULE}",
  "modules": {
    "${_ACTIVE_MODULE}": {
      "current_step": "req",
      "completed": ["module", "req"]
    }
  },
  "created_at": "2025-01-01T00:00:00Z",
  "updated_at": "2026-06-01T00:00:00Z"
}
JSON
}

# _write_no_active_session - active モジュールを持たない session.json を一時ディレクトリへ書く
#
# @return 0 always
_write_no_active_session() {
  mkdir -p "$DECKRD_LOCAL"
  cat >"${DECKRD_LOCAL}/session.json" <<'JSON'
{
  "current_step": "module",
  "completed": ["module"],
  "documents": {},
  "created_at": "2025-01-01T00:00:00Z",
  "updated_at": "2025-01-01T00:00:00Z"
}
JSON
}

# _expect_module_path - status.sh が表示する "Module Path:" 行を組む
#
# 実装の式を写さず、「基底ディレクトリ + active モジュール」という表示仕様の側から組む。
#
# @arg $1 string  Module Path の基底ディレクトリ
# @stdout 期待する "Module Path:" 行
_expect_module_path() {
  echo "Module Path:   ${1}/${_ACTIVE_MODULE}"
}

# _apply_docs_override - DECKRD_DOCS をケースの前提状態へ整える
#
# 「未設定」と「空文字」が init_vars にとって同じ入力であることを確かめるケースがあるため、
# 両者を引数で撃ち分けられるようにする。DECKRD_DOCS_DIR は setup_deckrd_tmpdir が
# 一時ディレクトリへ向けるので、こちらでは触らない。
#
# @arg $1 string  DECKRD_DOCS に入れる値。$_UNSET なら unset する
# @return 0 always
_apply_docs_override() {
  if [[ "$1" == "$_UNSET" ]]; then
    unset DECKRD_DOCS
  else
    export DECKRD_DOCS="$1"
  fi
}

# _restore_docs_override - ケースが触った DECKRD_DOCS を元の状態へ戻す
#
# DECKRD_DOCS はリポジトリの誰も設定しないので、unset が元の状態である。
#
# @return 0 always
_restore_docs_override() {
  unset DECKRD_DOCS
}

# ============================================================================
# テスト本体
# ============================================================================

Describe "T-CLI-ST: status.sh"
  Describe "Given: session.json does not exist"
    Before "setup_deckrd_tmpdir"
    After "teardown_deckrd_tmpdir"

    Describe "When: run status"
      It "[Error] T-CLI-ST-01: Should: exit with status 1 and output 'No session file' message"
        When run bash "$SCRIPT"
        The status should equal 1
        The stderr should include "No session file"
        The output should not include "Error:"
      End
    End
  End

  Describe "Given: session.json exists without active module"
    Before "setup_deckrd_tmpdir"
    After "teardown_deckrd_tmpdir"

    Before "_write_no_active_session"

    Describe "When: run status"
      It "[Error] T-CLI-ST-02: Should: exit with status 1 and output 'No active module' message"
        When run bash "$SCRIPT"
        The status should equal 1
        The stderr should include "No active module"
        The output should not include "Error:"
      End
    End
  End

  Describe "Given: session.json with active module"
    Before "setup_deckrd_tmpdir"
    After "teardown_deckrd_tmpdir"

    Before "_write_valid_session"

    Describe "When: run status"
      It "[Normal] T-CLI-ST-03: Should: exit with status 0, output 'DECKRD Status' header, and display active module name"
        When run bash "$SCRIPT"
        The status should equal 0
        The output should include "DECKRD Status"
        The output should include "myns/mymod"
      End
    End
  End

  Describe "Given: validate_env fails"
    Before "setup_deckrd_tmpdir"
    After "teardown_deckrd_tmpdir"

    mock_validate_env_failure() {
      # shellcheck disable=SC2329
      validate_env() { echo "Error: jq or jaq is required but not installed." >&2; return 1; }
      export -f validate_env
    }
    unmock_validate_env_failure() {
      unset -f validate_env
    }
    Before "mock_validate_env_failure"
    After "unmock_validate_env_failure"

    Describe "When: run status"
      It "[Error] T-CLI-ST-04: Should: exit with status 1, output the library message to stderr, and keep stdout blank"
        When run bash "$SCRIPT"
        The status should equal 1
        The stderr should include "jq or jaq is required"
        The output should be blank
      End
    End
  End

  Describe "Given: DECKRD_DOCS が未設定で DECKRD_DOCS_DIR が一時ディレクトリを指す"
    Before "setup_deckrd_tmpdir"
    After "teardown_deckrd_tmpdir"

    Before "_write_valid_session"

    Before "_apply_docs_override '$_UNSET'"
    After "_restore_docs_override"

    Describe "When: run status"
      It "[Normal] T-CLI-ST-05: Should: exit with status 0 and display Module Path under DECKRD_DOCS_DIR"
        When run bash "$SCRIPT"
        The status should equal 0
        The output should include "$(_expect_module_path "$DECKRD_DOCS_DIR")"
      End
    End
  End

  Describe "Given: DECKRD_DOCS がセンチネル値で上書きされている"
    Before "setup_deckrd_tmpdir"
    After "teardown_deckrd_tmpdir"

    Before "_write_valid_session"

    Before "_apply_docs_override '$_SENTINEL_DOCS'"
    After "_restore_docs_override"

    Describe "When: run status"
      It "[Normal] T-CLI-ST-06: Should: exit with status 0 and display Module Path under the DECKRD_DOCS override"
        When run bash "$SCRIPT"
        The status should equal 0
        The output should include "$(_expect_module_path "$_SENTINEL_DOCS")"
      End
    End
  End

  Describe "Given: DECKRD_DOCS が空文字で DECKRD_DOCS_DIR が一時ディレクトリを指す"
    Before "setup_deckrd_tmpdir"
    After "teardown_deckrd_tmpdir"

    Before "_write_valid_session"

    Before "_apply_docs_override ''"
    After "_restore_docs_override"

    Describe "When: run status"
      It "[Edge] T-CLI-ST-07: Should: treat the empty string as unset and display Module Path under DECKRD_DOCS_DIR"
        When run bash "$SCRIPT"
        The status should equal 0
        The output should include "$(_expect_module_path "$DECKRD_DOCS_DIR")"
      End
    End
  End
End
