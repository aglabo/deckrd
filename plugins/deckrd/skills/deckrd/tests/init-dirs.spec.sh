#!/usr/bin/env bash
# init-dirs.spec.sh - ShellSpec tests for init-dirs.sh
#
# Copyright (c) 2025 atsushifx <https://github.com/atsushifx>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

Include spec_helper.sh

SCRIPT="${SCRIPTS_DIR}/init-dirs.sh"

Describe "init-dirs.sh"

  Before "setup_deckrd_tmpdir"
  After  "teardown_deckrd_tmpdir"

  Describe "引数なしの場合"
    It "エラーメッセージを出力してexit 1する"
      When run bash "$SCRIPT"
      The status should equal 1
      The output should include "Usage:"
      The stderr should include "required"
    End
  End

  Describe "--help オプション"
    It "使い方を表示してexit 0する"
      When run bash "$SCRIPT" --help
      The status should equal 0
      The output should include "Usage:"
    End
  End

  Describe "不明なオプション"
    It "エラーメッセージを出力してexit 1する"
      When run bash "$SCRIPT" myapp webapp --unknown
      The status should equal 1
      The output should include "Usage:"
      The stderr should include "Unknown option"
    End
  End

  Describe "project-type なしの場合"
    It "エラーメッセージを出力してexit 1する"
      When run bash "$SCRIPT" myapp
      The status should equal 1
      The output should include "Usage:"
      The stderr should include "required"
    End
  End

  Describe "正常系"
    It "exit 0する"
      When run bash "$SCRIPT" myapp webapp
      The status should equal 0
      The output should include "myapp"
    End

    It "docs/.deckrd/ ベースディレクトリを作成する"
      When run bash "$SCRIPT" myapp webapp
      The output should include "Base directory"
      The path "$DECKRD_DOCS" should be directory
    End

    It "docs/.deckrd/notes/ を作成する"
      When run bash "$SCRIPT" myapp webapp
      The output should include "myapp"
      The path "${DECKRD_DOCS}/notes" should be directory
    End

    It "docs/.deckrd/temp/ を作成する"
      When run bash "$SCRIPT" myapp webapp
      The output should include "myapp"
      The path "${DECKRD_DOCS}/temp" should be directory
    End

    It "profile.json に project フィールドが含まれる"
      When run bash "$SCRIPT" myapp webapp
      The output should include "myapp"
    End

    It "profile.json に project_type フィールドが含まれる"
      When run bash "$SCRIPT" myapp webapp
      The output should include "webapp"
    End

    It "Session created または Session preserved メッセージを出力する"
      When run bash "$SCRIPT" myapp webapp
      The output should match pattern "*Session*"
    End
  End

  Describe "--language オプション"
    It "go を指定すると出力に go が含まれる"
      When run bash "$SCRIPT" myapp lib --language go
      The status should equal 0
      The output should include "go"
    End

    It "python を指定すると出力に python が含まれる"
      When run bash "$SCRIPT" myapp lib --language python
      The status should equal 0
      The output should include "python"
    End

    It "サポート外の言語はexit 1する"
      When run bash "$SCRIPT" myapp webapp --language cobol
      The status should equal 1
      The stderr should include "Unsupported language"
    End
  End

  Describe "--ai-model オプション"
    It "指定したモデルが出力に含まれる"
      When run bash "$SCRIPT" myapp webapp --ai-model claude-sonnet-4-5
      The status should equal 0
      The output should include "claude-sonnet-4-5"
    End

    It "無効文字を含むモデル名はexit 1する"
      When run bash "$SCRIPT" myapp webapp --ai-model "bad model!"
      The status should equal 1
      The stderr should include "AI model"
    End
  End

  Describe "--lang エイリアス"
    It "--lang でも言語を指定できる"
      When run bash "$SCRIPT" myapp webapp --lang rust
      The status should equal 0
      The output should include "rust"
    End
  End

End
