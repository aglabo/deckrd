#!/usr/bin/env bash
<<<<<<< HEAD
# plugins/deckrd/skills/deckrd/tests/init-dirs.spec.sh
# @(#) : BDD unit tests for init-dirs.sh (プロジェクトディレクトリ初期化)
#
# Copyright (c) 2025 atsushifx <https://github.com/atsushifx>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

Include spec_helper.sh

SCRIPT="${SCRIPTS_DIR}/init-dirs.sh"

# ============================================================================
# init-dirs.sh
# ============================================================================

Describe "init-dirs.sh"

  # --------------------------------------------------------------------------
  # Given: no arguments provided
  # --------------------------------------------------------------------------

  Describe "Given: no arguments provided"

    Before "setup_deckrd_tmpdir"
    After  "teardown_deckrd_tmpdir"

    Describe "When: run without arguments"
      It "[Error] Should: exit with status 1 and output Usage and 'required' error"
        When run bash "$SCRIPT"
        The status should equal 1
        The output should include "Usage:"
        The stderr should include "required"
      End
    End

  End

  # --------------------------------------------------------------------------
  # Given: --help option provided
  # --------------------------------------------------------------------------

  Describe "Given: --help option provided"

    Before "setup_deckrd_tmpdir"
    After  "teardown_deckrd_tmpdir"

    Describe "When: run with --help"
      It "[Normal] Should: exit with status 0 and output Usage"
        When run bash "$SCRIPT" --help
        The status should equal 0
        The output should include "Usage:"
      End
    End

  End

  # --------------------------------------------------------------------------
  # Given: unknown option provided
  # --------------------------------------------------------------------------

  Describe "Given: unknown option provided"

    Before "setup_deckrd_tmpdir"
    After  "teardown_deckrd_tmpdir"

    Describe "When: run with unknown option"
      It "[Error] Should: exit with status 1 and output 'Unknown option' error"
        When run bash "$SCRIPT" myapp webapp --unknown
        The status should equal 1
        The output should include "Usage:"
        The stderr should include "Unknown option"
      End
    End

  End

  # --------------------------------------------------------------------------
  # Given: project-type not provided
  # --------------------------------------------------------------------------

  Describe "Given: project-type not provided"

    Before "setup_deckrd_tmpdir"
    After  "teardown_deckrd_tmpdir"

    Describe "When: run with project name only"
      It "[Error] Should: exit with status 1 and output 'required' error"
        When run bash "$SCRIPT" myapp
        The status should equal 1
        The output should include "Usage:"
        The stderr should include "required"
      End
    End

  End

  # --------------------------------------------------------------------------
  # Given: valid project and project-type provided
  # --------------------------------------------------------------------------

  Describe "Given: valid project and project-type provided"

    Before "setup_deckrd_tmpdir"
    After  "teardown_deckrd_tmpdir"

    Describe "When: run with 'myapp webapp'"
      It "[Normal] Should: exit with status 0, create directories, output project/type, and show Session message"
        When run bash "$SCRIPT" myapp webapp
        The status should equal 0
        The output should include "myapp"
        The output should include "webapp"
        The output should include "Base directory"
        The output should match pattern "*Session*"
        The path "$DECKRD_DOCS" should be directory
        The path "${DECKRD_DOCS}/notes" should be directory
        The path "${DECKRD_DOCS}/temp" should be directory
      End
    End

  End

  # --------------------------------------------------------------------------
  # Given: --language option provided
  # --------------------------------------------------------------------------

  Describe "Given: --language option provided"

    Before "setup_deckrd_tmpdir"
    After  "teardown_deckrd_tmpdir"

    Describe "When: run with supported language"
      It "[Normal] Should: include 'go' in output for --language go"
        When run bash "$SCRIPT" myapp lib --language go
        The status should equal 0
        The output should include "go"
      End

      It "[Normal] Should: include 'python' in output for --language python"
        When run bash "$SCRIPT" myapp lib --language python
        The status should equal 0
        The output should include "python"
      End

      It "[Normal] Should: include 'rust' in output for --lang rust (alias)"
        When run bash "$SCRIPT" myapp webapp --lang rust
        The status should equal 0
        The output should include "rust"
      End
    End

    Describe "When: run with unsupported language"
      It "[Error] Should: exit with status 1 and output 'Unsupported language' error"
        When run bash "$SCRIPT" myapp webapp --language cobol
        The status should equal 1
        The stderr should include "Unsupported language"
      End
    End

  End

  # --------------------------------------------------------------------------
  # Given: --ai-model option provided
  # --------------------------------------------------------------------------

  Describe "Given: --ai-model option provided"

    Before "setup_deckrd_tmpdir"
    After  "teardown_deckrd_tmpdir"

    Describe "When: run with valid model name"
      It "[Normal] Should: include specified model name in output"
        When run bash "$SCRIPT" myapp webapp --ai-model claude-sonnet-4-5
        The status should equal 0
        The output should include "claude-sonnet-4-5"
      End
    End

    Describe "When: run with invalid model name"
      It "[Error] Should: exit with status 1 and output 'AI model' validation error"
        When run bash "$SCRIPT" myapp webapp --ai-model "bad model!"
        The status should equal 1
        The stderr should include "AI model"
      End
    End

||||||| f6e572e
=======
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

    It "project.json に project フィールドが含まれる"
      When run bash "$SCRIPT" myapp webapp
      The output should include "myapp"
    End

    It "project.json に project_type フィールドが含まれる"
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
>>>>>>> main
  End

End
