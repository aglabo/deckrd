#!/usr/bin/env bash
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
  End

End
