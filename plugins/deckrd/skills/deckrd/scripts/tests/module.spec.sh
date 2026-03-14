#!/usr/bin/env bash
<<<<<<< HEAD
# plugins/deckrd/skills/deckrd/tests/module.spec.sh
# @(#) : BDD unit tests for module.sh (モジュールディレクトリ管理)
#
# Copyright (c) 2025 atsushifx <https://github.com/atsushifx>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

Include spec_helper.sh

SCRIPT="${SCRIPTS_DIR}/module.sh"

# ============================================================================
# module.sh
# ============================================================================

Describe "module.sh"

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
        When run bash "$SCRIPT" --unknown
        The status should equal 1
        The output should include "Usage:"
        The stderr should include "Unknown option"
      End
    End

  End

  # --------------------------------------------------------------------------
  # Given: valid legacy format argument (<namespace>/<module>)
  # --------------------------------------------------------------------------

  Describe "Given: valid legacy format argument (<namespace>/<module>)"

    Before "setup_deckrd_tmpdir"
    After  "teardown_deckrd_tmpdir"

    Describe "When: run with 'myns/mymod'"
      It "[Normal] Should: exit with status 0, create all module directories, skip .profile.json, and output 'Session updated'"
        When run bash "$SCRIPT" myns/mymod
        The status should equal 0
        The output should include "myns/mymod"
        The output should include "requirements"
        The output should include "specifications"
        The output should include "implementation"
        The output should include "tasks"
        The output should include "Session updated"
        The path "${DECKRD_DOCS}/myns/mymod/requirements" should be directory
        The path "${DECKRD_DOCS}/myns/mymod/specifications" should be directory
        The path "${DECKRD_DOCS}/myns/mymod/implementation" should be directory
        The path "${DECKRD_DOCS}/myns/mymod/tasks" should be directory
        The path "${DECKRD_DOCS}/myns/mymod/.profile.json" should not be exist
      End
    End

    Describe "When: run with uppercase 'MyNS/MyMod'"
      It "[Edge] Should: normalize to lowercase and create 'myns/mymod' directory"
        When run bash "$SCRIPT" MyNS/MyMod
        The output should include "myns/mymod"
        The path "${DECKRD_DOCS}/myns/mymod/requirements" should be directory
      End
    End

  End

  # --------------------------------------------------------------------------
  # Given: invalid legacy format argument
  # --------------------------------------------------------------------------

  Describe "Given: invalid legacy format argument"

    Before "setup_deckrd_tmpdir"
    After  "teardown_deckrd_tmpdir"

    Describe "When: run with 'mymod' (no slash)"
      It "[Error] Should: exit with status 1 and output 'namespace' error"
        When run bash "$SCRIPT" mymod
        The status should equal 1
        The stderr should include "namespace"
      End
    End

    Describe "When: run with '/mymod' (empty namespace)"
      It "[Error] Should: exit with status 1 and output 'empty' error"
        When run bash "$SCRIPT" "/mymod"
        The status should equal 1
        The stderr should include "empty"
      End
    End

    Describe "When: run with 'myns/' (empty module)"
      It "[Error] Should: exit with status 1 and output 'empty' error"
        When run bash "$SCRIPT" "myns/"
        The status should equal 1
        The stderr should include "empty"
      End
    End

    Describe "When: run with 'my ns/mymod' (space in namespace)"
      It "[Error] Should: exit with status 1 and output 'invalid characters' error"
        When run bash "$SCRIPT" "my ns/mymod"
        The status should equal 1
        The stderr should include "invalid characters"
      End
    End

    Describe "When: run with 'myns/mymod' on existing directory without --force"
      It "[Error] Should: exit with status 1 and output 'already exists' error"
        mkdir -p "${DECKRD_DOCS}/myns/mymod"
        When run bash "$SCRIPT" myns/mymod
        The status should equal 1
        The stderr should include "already exists"
      End
    End

    Describe "When: run with 'myns/mymod' on existing directory with --force"
      It "[Edge] Should: exit with status 0 and output 'myns/mymod'"
        mkdir -p "${DECKRD_DOCS}/myns/mymod"
        When run bash "$SCRIPT" myns/mymod --force
        The status should equal 0
        The output should include "myns/mymod"
      End
    End

  End

  # --------------------------------------------------------------------------
  # Given: create subcommand with <namespace>/<module> format
  # --------------------------------------------------------------------------

  Describe "Given: create subcommand with <namespace>/<module> format"

    Before "setup_deckrd_tmpdir"
    After  "teardown_deckrd_tmpdir"

    Describe "When: run 'create myns/mymod'"
      It "[Normal] Should: exit with status 0, create .profile.json with name/created_at fields, and output 'Session updated'"
        When run bash "$SCRIPT" create myns/mymod
        The status should equal 0
        The output should include "myns/mymod"
        The output should include "profile.json"
        The output should include "Session updated"
        The path "${DECKRD_DOCS}/myns/mymod/.profile.json" should be exist
        The contents of file "${DECKRD_DOCS}/myns/mymod/.profile.json" should include "mymod"
        The contents of file "${DECKRD_DOCS}/myns/mymod/.profile.json" should include "created_at"
      End
    End

    Describe "When: run create with invalid namespace 'my ns/mymod'"
      It "[Error] Should: exit with status 1 and output 'invalid characters' error"
        When run bash "$SCRIPT" create "my ns/mymod"
        The status should equal 1
        The stderr should include "invalid characters"
      End
    End

  End

  # --------------------------------------------------------------------------
  # Given: create subcommand with <module> format (git remote auto-completion)
  # --------------------------------------------------------------------------

  Describe "Given: create subcommand with <module> format"

    Before "setup_deckrd_tmpdir"
    After  "teardown_deckrd_tmpdir"

    Describe "When: run 'create myfeature'"
      It "[Normal] Should: exit with status 0, output 'myfeature', and create .profile.json"
        When run bash "$SCRIPT" create myfeature
        The status should equal 0
        The output should include "myfeature"
        The output should include "profile.json"
      End
    End

||||||| f6e572e
=======
# module.spec.sh - ShellSpec tests for module.sh
#
# Copyright (c) 2025 atsushifx <https://github.com/atsushifx>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

Include spec_helper.sh

SCRIPT="${SCRIPTS_DIR}/module.sh"

Describe "module.sh"

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
      When run bash "$SCRIPT" --unknown
      The status should equal 1
      The output should include "Usage:"
      The stderr should include "Unknown option"
    End
  End

  Describe "既存の動作 (legacy: <namespace>/<module>)"
    Describe "正常系"
      It "ディレクトリを作成してexit 0する"
        When run bash "$SCRIPT" myns/mymod
        The status should equal 0
        The output should include "myns/mymod"
      End

      It "requirements/ ディレクトリを作成する"
        When run bash "$SCRIPT" myns/mymod
        The output should include "requirements"
        The path "${DECKRD_DOCS}/myns/mymod/requirements" should be directory
      End

      It "specifications/ ディレクトリを作成する"
        When run bash "$SCRIPT" myns/mymod
        The output should include "specifications"
        The path "${DECKRD_DOCS}/myns/mymod/specifications" should be directory
      End

      It "implementation/ ディレクトリを作成する"
        When run bash "$SCRIPT" myns/mymod
        The output should include "implementation"
        The path "${DECKRD_DOCS}/myns/mymod/implementation" should be directory
      End

      It "tasks/ ディレクトリを作成する"
        When run bash "$SCRIPT" myns/mymod
        The output should include "tasks"
        The path "${DECKRD_DOCS}/myns/mymod/tasks" should be directory
      End

      It ".project.json を作成しない (legacy 動作)"
        When run bash "$SCRIPT" myns/mymod
        The output should include "myns/mymod"
        The path "${DECKRD_DOCS}/myns/mymod/.project.json" should not be exist
      End

      It "大文字を小文字に正規化する"
        When run bash "$SCRIPT" MyNS/MyMod
        The output should include "myns/mymod"
        The path "${DECKRD_DOCS}/myns/mymod/requirements" should be directory
      End

      It "Session updated メッセージを出力する"
        When run bash "$SCRIPT" myns/mymod
        The output should include "Session updated"
      End
    End

    Describe "異常系"
      It "スラッシュなしの場合はexit 1する"
        When run bash "$SCRIPT" mymod
        The status should equal 1
        The stderr should include "namespace"
      End

      It "namespace が空の場合はexit 1する"
        When run bash "$SCRIPT" "/mymod"
        The status should equal 1
        The stderr should include "empty"
      End

      It "module が空の場合はexit 1する"
        When run bash "$SCRIPT" "myns/"
        The status should equal 1
        The stderr should include "empty"
      End

      It "無効文字を含むnamespaceはexit 1する"
        When run bash "$SCRIPT" "my ns/mymod"
        The status should equal 1
        The stderr should include "invalid characters"
      End

      It "既存ディレクトリに --force なしの場合はexit 1する"
        mkdir -p "${DECKRD_DOCS}/myns/mymod"
        When run bash "$SCRIPT" myns/mymod
        The status should equal 1
        The stderr should include "already exists"
      End

      It "--force オプションで既存ディレクトリも成功する"
        mkdir -p "${DECKRD_DOCS}/myns/mymod"
        When run bash "$SCRIPT" myns/mymod --force
        The status should equal 0
        The output should include "myns/mymod"
      End
    End
  End

  Describe "create サブコマンド (<namespace>/<module> 形式)"
    Describe "正常系"
      It "ディレクトリを作成してexit 0する"
        When run bash "$SCRIPT" create myns/mymod
        The status should equal 0
        The output should include "myns/mymod"
      End

      It ".project.json を作成する"
        When run bash "$SCRIPT" create myns/mymod
        The output should include "project.json"
        The path "${DECKRD_DOCS}/myns/mymod/.project.json" should be exist
      End

      It ".project.json に name フィールドが含まれる"
        When run bash "$SCRIPT" create myns/mymod
        The output should include "project.json"
        The contents of file "${DECKRD_DOCS}/myns/mymod/.project.json" should include "mymod"
      End

      It ".project.json に created_at フィールドが含まれる"
        When run bash "$SCRIPT" create myns/mymod
        The output should include "project.json"
        The contents of file "${DECKRD_DOCS}/myns/mymod/.project.json" should include "created_at"
      End

      It "Session updated メッセージを出力する"
        When run bash "$SCRIPT" create myns/mymod
        The output should include "Session updated"
      End
    End

    Describe "異常系"
      It "無効文字を含むnamespaceはexit 1する"
        When run bash "$SCRIPT" create "my ns/mymod"
        The status should equal 1
        The stderr should include "invalid characters"
      End
    End
  End

  Describe "create サブコマンド (<module> 形式 - git remote から自動補完)"
    Describe "正常系"
      It "ディレクトリを作成してexit 0する"
        When run bash "$SCRIPT" create myfeature
        The status should equal 0
        The output should include "myfeature"
      End

      It ".project.json を作成する"
        When run bash "$SCRIPT" create myfeature
        The output should include "project.json"
      End
    End
>>>>>>> main
  End

End
