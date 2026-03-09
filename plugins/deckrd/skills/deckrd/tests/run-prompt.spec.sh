#!/usr/bin/env bash
# run-prompt.spec.sh - ShellSpec tests for run-prompt.sh
#
# Copyright (c) 2025 atsushifx <https://github.com/atsushifx>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

Include spec_helper.sh

SCRIPT="${SCRIPTS_DIR}/run-prompt.sh"

Describe "run-prompt.sh"

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
      When run bash "$SCRIPT" requirements --unknown
      The status should equal 1
      The output should include "Usage:"
      The stderr should include "Unknown option"
    End
  End

  Describe "不明なドキュメントタイプ"
    It "エラーメッセージを出力してexit 1する"
      When run bash "$SCRIPT" invalid_type
      The status should equal 1
      The stderr should include "Unknown document type"
    End
  End

  Describe "validate_doc_type - ショート形式の変換"
    # prompt ファイルが存在しないため実行はエラーになるが、
    # "Unknown document type" エラーにはならないことを確認する
    It "req は Unknown document type エラーにならない"
      When run bash "$SCRIPT" req
      The status should equal 1
      The stderr should not include "Unknown document type"
    End

    It "spec は Unknown document type エラーにならない"
      When run bash "$SCRIPT" spec
      The status should equal 1
      The stderr should not include "Unknown document type"
    End

    It "impl は Unknown document type エラーにならない"
      When run bash "$SCRIPT" impl
      The status should equal 1
      The stderr should not include "Unknown document type"
    End

    It "task は Unknown document type エラーにならない"
      When run bash "$SCRIPT" task
      The status should equal 1
      The stderr should not include "Unknown document type"
    End
  End

  Describe "--ai-model オプションのバリデーション"
    It "無効文字を含むモデル名はexit 1する"
      When run bash "$SCRIPT" requirements --ai-model "bad model!"
      The status should equal 1
      The stderr should include "AI model"
    End

    It "invalid char の場合は AI model バリデーションエラーになる"
      When run bash "$SCRIPT" requirements --ai-model "bad@model"
      The status should equal 1
      The stderr should include "AI model"
    End
  End

  Describe "--phase オプション"
    It "無効な phase はexit 1する"
      When run bash "$SCRIPT" review --phase invalid
      The status should equal 1
      The stderr should include "Invalid review phase"
    End

    It "explore は Invalid review phase エラーにならない"
      When run bash "$SCRIPT" review --phase explore
      The status should equal 1
      The stderr should not include "Invalid review phase"
    End

    It "harden は Invalid review phase エラーにならない"
      When run bash "$SCRIPT" review --phase harden
      The status should equal 1
      The stderr should not include "Invalid review phase"
    End

    It "fix は Invalid review phase エラーにならない"
      When run bash "$SCRIPT" review --phase fix
      The status should equal 1
      The stderr should not include "Invalid review phase"
    End
  End

  Describe "位置引数が多すぎる場合"
    It "エラーメッセージを出力してexit 1する"
      When run bash "$SCRIPT" requirements context1 extra_arg
      The status should equal 1
      The output should include "Usage:"
      The stderr should include "Too many positional arguments"
    End
  End

End
