#!/usr/bin/env bash
# project.spec.sh - ShellSpec tests for project.sh
#
# Copyright (c) 2025 atsushifx <https://github.com/atsushifx>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

# shellcheck disable=SC1090

_RUNTIME_BOOTSTRAP="${SHELLSPEC_PROJECT_ROOT}/skills/deckrd/skills/deckrd/scripts/libs/bootstrap.lib.sh"
. "$_RUNTIME_BOOTSTRAP" "--no-finalize"
unset _RUNTIME_BOOTSTRAP

Include "${SHELLSPEC_SPECFILE%/*}/../spec_helper.sh"

SCRIPT="${DECKRD_SCRIPTS_DIR}/project.sh"

Describe "T-CLI-PRJ: project.sh"
  Before "setup_deckrd_tmpdir"
  After "teardown_deckrd_tmpdir"

  # Internal helpers: read fields of the generated .project.json
  _project_prog() {
    jq -r '.prog' "${DECKRD_LOCAL_DATA}/.project.json"
  }
  _project_has_language() {
    jq 'has("language")' "${DECKRD_LOCAL_DATA}/.project.json"
  }
  _project_created_at() {
    jq -r '.created_at' "${DECKRD_LOCAL_DATA}/.project.json"
  }
  _project_ai_model() {
    jq -r '.ai_model' "${DECKRD_LOCAL_DATA}/.project.json"
  }
  # Fixture: an existing .project.json whose ai_model is "opus"
  _setup_existing_opus_project() {
    mkdir -p "$DECKRD_LOCAL_DATA"
    cat >"${DECKRD_LOCAL_DATA}/.project.json" <<'JSON'
{
  "project": "oldapp",
  "project_type": "",
  "prog": "typescript",
  "ai_model": "opus",
  "created_at": "2025-01-01T00:00:00Z",
  "updated_at": "2025-01-01T00:00:00Z"
}
JSON
  }
  # Succeeds only if project.sh parses via args.lib.sh and no longer defines parse_options
  _uses_args_lib() {
    grep -qE '^[[:space:]]+args_init$' "$1" &&
      grep -qF 'parse_args "$@"' "$1" &&
      ! grep -q '^parse_options()' "$1"
  }

  Describe "引数なしの場合"
    It "T-CLI-PRJ-01: エラーメッセージを出力してexit 1する"
      When run bash "$SCRIPT"
      The status should equal 1
      The stderr should include "required"
    End
  End

  Describe "--help オプション"
    It "T-CLI-PRJ-02: 使い方を表示してexit 0する"
      When run bash "$SCRIPT" --help
      The status should equal 0
      The output should include "Usage:"
    End

    It "[Normal] T-CLI-PRJ-21: ヘルプに .local/deckrd/.project.json が含まれる"
      When run bash "$SCRIPT" --help
      The output should include ".local/deckrd/.project.json"
    End

    It "[Normal] T-CLI-PRJ-43: ヘルプが --prog を programming language オプションとして記載する"
      When run bash "$SCRIPT" --help
      The status should equal 0
      The output should include "--prog <lang>, --language"
      The output should include "Programming language (default: typescript)"
    End

    It "[Edge] T-CLI-PRJ-46: ヘルプがサポート言語一覧と bash エイリアス注記を維持する"
      When run bash "$SCRIPT" --help
      The status should equal 0
      The output should include "Supported: typescript go python rust shell"
      The output should include "Alias: bash → shell"
    End

    It "[Normal] T-CLI-PRJ-44: ヘルプの例が --prog を使う"
      When run bash "$SCRIPT" --help
      The status should equal 0
      The output should include "project.sh --project myapp --prog go"
    End

    # Count help lines with a standalone --lang token (--language excluded)
    _help_lang_token_count() {
      bash "$SCRIPT" --help | grep -cE -- '--lang([^u]|$)' || true
    }

    It "[Error] T-CLI-PRJ-45: ヘルプに単独トークンの --lang を記載しない"
      When call _help_lang_token_count
      The output should equal "0"
    End
  End

  Describe "不明なオプション"
    It "T-CLI-PRJ-03: エラーメッセージを出力してexit 1する"
      When run bash "$SCRIPT" --project myapp --unknown
      The status should equal 1
      The output should include "Usage:"
      The stderr should include "Unknown option"
    End
  End

  Describe "予期しない位置引数"
    It "T-CLI-PRJ-04: エラーメッセージを出力してexit 1する"
      When run bash "$SCRIPT" --project myapp unexpected
      The status should equal 1
      The output should include "Usage:"
      The stderr should include "Unexpected argument"
    End
  End

  Describe "正常系"
    It "T-CLI-PRJ-05: exit 0する"
      When run bash "$SCRIPT" --project myapp --prog go
      The status should equal 0
      The output should include "myapp"
    End

    It "T-CLI-PRJ-06: project が出力に含まれる"
      When run bash "$SCRIPT" --project myapp --prog go
      The output should include "  project:      myapp"
    End

    It "T-CLI-PRJ-07: prog が出力に含まれる"
      When run bash "$SCRIPT" --project myapp --prog go
      The output should include "go"
    End

    It "T-CLI-PRJ-08: 結果サマリーを出力する"
      When run bash "$SCRIPT" --project myapp --prog typescript
      The output should include "myapp"
      The output should include "typescript"
    End

    It "[Normal] T-CLI-PRJ-22: project: 行に .local/deckrd/.project.json が含まれる"
      When run bash "$SCRIPT" --project myapp --prog go
      The output should include "project:      .local/deckrd/.project.json"
    End
  End

  Describe "--prog オプション"
    It "[Normal] T-CLI-PRJ-23: --prog go を受け付けて prog: 行に表示する"
      When run bash "$SCRIPT" --project myapp --prog go
      The status should equal 0
      The output should include "  prog:         go"
    End

    It "[Normal] T-CLI-PRJ-24: --prog=rust (= 構文) を受け付けて prog: 行に表示する"
      When run bash "$SCRIPT" --project myapp --prog=rust
      The status should equal 0
      The output should include "  prog:         rust"
    End

    It "[Error] T-CLI-PRJ-29: --prog の値が無い場合はexit 1する"
      When run bash "$SCRIPT" --project myapp --prog
      The status should equal 1
      The output should include "Usage:"
      The stderr should include "--prog requires a value"
    End

    It "[Error] T-CLI-PRJ-30: --prog にサポート外の言語を指定するとexit 1する"
      When run bash "$SCRIPT" --project myapp --prog cobol
      The status should equal 1
      The stderr should include "Unsupported language: cobol"
    End
  End

  Describe "--language エイリアス"
    It "T-CLI-PRJ-09: typescript を指定できる"
      When run bash "$SCRIPT" --project myapp --language typescript
      The status should equal 0
      The output should include "  prog:         typescript"
    End

    It "T-CLI-PRJ-10: python を指定できる"
      When run bash "$SCRIPT" --project myapp --language python
      The status should equal 0
      The output should include "  prog:         python"
    End

    It "T-CLI-PRJ-11: rust を指定できる"
      When run bash "$SCRIPT" --project myapp --language rust
      The status should equal 0
      The output should include "  prog:         rust"
    End

    It "T-CLI-PRJ-12: shell を指定できる"
      When run bash "$SCRIPT" --project myapp --language shell
      The status should equal 0
      The output should include "  prog:         shell"
    End

    It "[Normal] T-CLI-PRJ-25: --language=typescript (= 構文) を受け付けて prog: 行に表示する"
      When run bash "$SCRIPT" --project myapp --language=typescript
      The status should equal 0
      The output should include "  prog:         typescript"
    End

    It "T-CLI-PRJ-15: サポート外の言語はexit 1する"
      When run bash "$SCRIPT" --project myapp --language cobol
      The status should equal 1
      The stderr should include "Unsupported language"
    End
  End

  Describe "bash → shell 正規化"
    It "[Normal] T-CLI-PRJ-26: --prog bash は shell に正規化される"
      When run bash "$SCRIPT" --project myapp --prog bash
      The status should equal 0
      The output should include "  prog:         shell"
    End

    It "[Normal] T-CLI-PRJ-27: --prog=bash (= 構文) は shell に正規化される"
      When run bash "$SCRIPT" --project myapp --prog=bash
      The status should equal 0
      The output should include "  prog:         shell"
    End

    It "T-CLI-PRJ-13: --language bash は shell に正規化される"
      When run bash "$SCRIPT" --project myapp --language bash
      The status should equal 0
      The output should include "  prog:         shell"
    End

    It "T-CLI-PRJ-14: --language=bash (= 構文) は shell に正規化され language: 行を表示しない"
      When run bash "$SCRIPT" --project myapp --language=bash
      The status should equal 0
      The output should include "  prog:         shell"
      The output should not include "language:"
    End
  End

  Describe "--lang は受け付けない"
    It "[Error] T-CLI-PRJ-16: --lang は Unknown option として exit 1する"
      When run bash "$SCRIPT" --project myapp --lang go
      The status should equal 1
      The stderr should include "Unknown option: --lang"
      The output should include "Usage:"
    End

    It "[Error] T-CLI-PRJ-28: --lang=go (= 構文) はオプション名 --lang の Unknown option として exit 1する"
      When run bash "$SCRIPT" --project myapp --lang=go
      The status should equal 1
      The stderr should equal "Error: Unknown option: --lang"
      The output should include "Usage:"
    End

    It "[Error] T-CLI-PRJ-36: --lang go では .project.json を作らない"
      When run bash "$SCRIPT" --project myapp --lang go
      The status should equal 1
      The stderr should include "Unknown option: --lang"
      The output should include "Usage:"
      The path "${DECKRD_LOCAL_DATA}/.project.json" should not be exist
    End
  End

  Describe "言語オプションのエッジケース"
    It "[Edge] T-CLI-PRJ-31: --prog= (空値) は値の欠落としてexit 1する"
      When run bash "$SCRIPT" --project myapp --prog=
      The status should equal 1
      The output should include "Usage:"
      The stderr should include "--prog requires a value"
    End

    It "[Edge] T-CLI-PRJ-32: --language と --prog を両方指定すると後勝ちになる"
      When run bash "$SCRIPT" --project myapp --language go --prog rust
      The status should equal 0
      The output should include "  prog:         rust"
    End

    It "[Edge] T-CLI-PRJ-33: 言語オプションを省略すると typescript になる"
      When run bash "$SCRIPT" --project myapp
      The status should equal 0
      The output should include "  prog:         typescript"
    End
  End

  Describe ".project.json の内容"
    It "[Normal] T-CLI-PRJ-34: --prog go は prog キーに go を書く"
      When run bash "$SCRIPT" --project myapp --prog go
      The status should equal 0
      The output should include "myapp"
      The result of function _project_prog should equal "go"
    End

    It "[Normal] T-CLI-PRJ-35: --prog go は language キーを書かない"
      When run bash "$SCRIPT" --project myapp --prog go
      The status should equal 0
      The output should include "myapp"
      The result of function _project_has_language should equal "false"
    End

    It "[Edge] T-CLI-PRJ-37: --prog=bash は正規化後の shell を prog キーに書く"
      When run bash "$SCRIPT" --project myapp --prog=bash
      The status should equal 0
      The output should include "myapp"
      The result of function _project_prog should equal "shell"
    End

    It "[Edge] T-CLI-PRJ-38: 言語オプションを省略すると既定値 typescript を prog キーに書く"
      When run bash "$SCRIPT" --project myapp
      The status should equal 0
      The output should include "myapp"
      The result of function _project_prog should equal "typescript"
    End
  End

  Describe "結果表示"
    It "[Normal] T-CLI-PRJ-40: --prog go は prog: 行を表示し language: 行を表示しない"
      When run bash "$SCRIPT" --project myapp --prog go
      The status should equal 0
      The output should include "  prog:         go"
      The output should not include "language:"
    End

    It "[Error] T-CLI-PRJ-41: --prog cobol は検証で失敗し結果を表示しない"
      When run bash "$SCRIPT" --project myapp --prog cobol
      The status should equal 1
      The stderr should include "Unsupported language: cobol"
      The output should not include "prog:"
      The output should not include "Deckrd project configured."
    End
  End

  Describe "--project-type オプション"
    It "T-CLI-PRJ-17: project_type が出力に含まれる"
      When run bash "$SCRIPT" --project myapp --project-type webapp
      The output should include "webapp"
    End
  End

  Describe "--ai-model オプション"
    It "T-CLI-PRJ-18: 指定したモデルが出力に含まれる"
      When run bash "$SCRIPT" --project myapp --ai-model claude-sonnet-4-5
      The output should include "claude-sonnet-4-5"
    End
  End

  Describe "既存の .project.json の更新"
    Before "setup_existing_project"
    setup_existing_project() {
      mkdir -p "$DECKRD_LOCAL"
      cat >"${DECKRD_LOCAL}/.project.json" <<'JSON'
{
  "project": "oldapp",
  "language": "go",
  "created_at": "2025-01-01T00:00:00Z",
  "updated_at": "2025-01-01T00:00:00Z"
}
JSON
    }

    It "T-CLI-PRJ-19: exit 0する"
      When run bash "$SCRIPT" --project newapp --prog typescript
      The status should equal 0
      The output should include "newapp"
    End

    It "[Normal] T-CLI-PRJ-39: 旧形式の language キーを prog に置き換え、created_at を維持する"
      When run bash "$SCRIPT" --project newapp --prog typescript
      The status should equal 0
      The output should include "newapp"
      The result of function _project_prog should equal "typescript"
      The result of function _project_has_language should equal "false"
      The result of function _project_created_at should equal "2025-01-01T00:00:00Z"
    End
  End

  Describe "jq / jaq のいずれも無い場合"
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

    It "T-CLI-PRJ-20: ライブラリのメッセージのみを stderr に出力して exit 1する"
      When run bash "$SCRIPT" --project myapp
      The status should equal 1
      The lines of entire stderr should eq 1
      The stderr should include "jq or jaq is required"
    End
  End

  Describe "args.lib.sh による引数解析"
    It "[Normal] T-CLI-PRJ-55: --project= / --project-type= / --ai-model= (= 構文) を受け付けて出力に表示する"
      When run bash "$SCRIPT" --project=myapp --project-type=webapp --ai-model=opus
      The status should equal 0
      The output should include "  project:      myapp"
      The output should include "  project_type: webapp"
      The output should include "  ai_model:     opus"
    End

    It "[Error] T-CLI-PRJ-56: --project= (空値) は値の欠落としてexit 1する"
      When run bash "$SCRIPT" --project=
      The status should equal 1
      The output should include "Usage:"
      The stderr should include "--project requires a value"
    End

    It "[Normal] T-CLI-PRJ-59: project.sh は args_init と parse_args を使い parse_options を定義しない"
      When call _uses_args_lib "$SCRIPT"
      The status should be success
    End
  End

  Describe "既存の .project.json の ai_model 引き継ぎ"
    Before "_setup_existing_opus_project"

    It "[Normal] T-CLI-PRJ-57: --ai-model sonnet を明示すると既存の opus を上書きして sonnet を書く"
      When run bash "$SCRIPT" --project myapp --ai-model sonnet
      The status should equal 0
      The output should include "  ai_model:     sonnet"
      The result of function _project_ai_model should equal "sonnet"
    End

    It "[Normal] T-CLI-PRJ-58: --ai-model を省略すると既存の opus を維持する"
      When run bash "$SCRIPT" --project myapp
      The status should equal 0
      The output should include "  ai_model:     opus"
      The result of function _project_ai_model should equal "opus"
    End
  End

  # write_project writes through write_json_file; a failure is reported and stops main
  Describe "write_json_file の失敗"
    _EXISTING_PROJECT='{"project":"oldapp","created_at":"2025-01-01T00:00:00Z"}'

    # Run a snippet in a fresh bash that sources project.sh (main is guarded by
    # BASH_SOURCE) with write_json_file stubbed to fail. PROJECT_FILE is readonly
    # in project.sh, so this cannot be done in the spec shell.
    # @arg $1 string snippet to run after the stub is defined
    _run_with_failing_write() {
      SCRIPT="$SCRIPT" bash -c '
        . "$SCRIPT"
        validate_env() { return 0; }
        write_json_file() { return 1; }
        '"$1"'
      '
    }
    _write_project_with_failing_write() {
      _run_with_failing_write '
        args_init
        OPTIONS[project]=myapp OPTIONS[project_type]="" OPTIONS[prog]=typescript OPTIONS[ai_model]=sonnet
        write_project'
    }
    _main_with_failing_write() {
      _run_with_failing_write 'main --project myapp'
    }
    _list_project_tmp() {
      find "$DECKRD_LOCAL_DATA" -maxdepth 1 -name '.project.json.tmp*'
    }
    _write_existing_project() {
      mkdir -p "$DECKRD_LOCAL_DATA"
      printf '%s' "$_EXISTING_PROJECT" >"${DECKRD_LOCAL_DATA}/.project.json"
    }
    It "[Error] T-CLI-PRJ-60: .project.json が無く write_json_file が失敗 -> stderr に Error、status 1、ファイル未作成、tmp なし"
      When call _write_project_with_failing_write
      The status should equal 1
      The stderr should include "Error: write_project: failed to write: ${DECKRD_LOCAL_DATA}/.project.json"
      The path "${DECKRD_LOCAL_DATA}/.project.json" should not be exist
      The value "$(_list_project_tmp)" should be blank
    End

    It "[Error] T-CLI-PRJ-61: 既存の .project.json があり write_json_file が失敗 -> status 1、内容は不変、tmp なし"
      _write_existing_project
      When call _write_project_with_failing_write
      The status should equal 1
      The stderr should include "Error: write_project: failed to write: ${DECKRD_LOCAL_DATA}/.project.json"
      The contents of file "${DECKRD_LOCAL_DATA}/.project.json" should equal "$_EXISTING_PROJECT"
      The value "$(_list_project_tmp)" should be blank
    End

    It "[Error] T-CLI-PRJ-62: write_project が失敗 -> main は exit 1 し、完了メッセージを出さない"
      When call _main_with_failing_write
      The status should equal 1
      The stderr should include "Error: write_project: failed to write"
      The stdout should not include "Deckrd project configured."
    End
  End

End
