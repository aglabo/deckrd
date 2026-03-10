#!/usr/bin/env bash
# plugins/deckrd/skills/deckrd/tests/run-prompt.spec.sh
# @(#) : BDD unit tests for run-prompt.sh (AIプロンプト実行)
#
# Copyright (c) 2025 atsushifx <https://github.com/atsushifx>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

Include spec_helper.sh

SCRIPT="${SCRIPTS_DIR}/run-prompt.sh"

# ============================================================================
# run-prompt.sh
# ============================================================================

Describe "run-prompt.sh"

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
        When run bash "$SCRIPT" requirements --unknown
        The status should equal 1
        The output should include "Usage:"
        The stderr should include "Unknown option"
      End
    End

  End

  # --------------------------------------------------------------------------
  # Given: unknown document type provided
  # --------------------------------------------------------------------------

  Describe "Given: unknown document type provided"

    Before "setup_deckrd_tmpdir"
    After  "teardown_deckrd_tmpdir"

    Describe "When: run with unknown document type"
      It "[Error] Should: exit with status 1 and output 'Unknown document type' error"
        When run bash "$SCRIPT" invalid_type
        The status should equal 1
        The stderr should include "Unknown document type"
      End
    End

  End

  # --------------------------------------------------------------------------
  # Given: short format document type provided to validate_doc_type
  # --------------------------------------------------------------------------

  # prompt ファイルが存在しないため実行はエラーになるが、
  # "Unknown document type" エラーにはならないことを確認する

  Describe "Given: short format document type provided to validate_doc_type"

    Before "setup_deckrd_tmpdir"
    After  "teardown_deckrd_tmpdir"

    Describe "When: run with each short format (req/spec/impl/task)"
      It "[Edge] Should: not output 'Unknown document type' error for 'req'"
        When run bash "$SCRIPT" req
        The status should equal 1
        The stderr should not include "Unknown document type"
      End

      It "[Edge] Should: not output 'Unknown document type' error for 'spec'"
        When run bash "$SCRIPT" spec
        The status should equal 1
        The stderr should not include "Unknown document type"
      End

      It "[Edge] Should: not output 'Unknown document type' error for 'impl'"
        When run bash "$SCRIPT" impl
        The status should equal 1
        The stderr should not include "Unknown document type"
      End

      It "[Edge] Should: not output 'Unknown document type' error for 'task'"
        When run bash "$SCRIPT" task
        The status should equal 1
        The stderr should not include "Unknown document type"
      End
    End

  End

  # --------------------------------------------------------------------------
  # Given: --ai-model option provided
  # --------------------------------------------------------------------------

  Describe "Given: --ai-model option provided"

    Before "setup_deckrd_tmpdir"
    After  "teardown_deckrd_tmpdir"

    Describe "When: run with invalid model name containing spaces"
      It "[Error] Should: exit with status 1 and output 'AI model' error for 'bad model!'"
        When run bash "$SCRIPT" requirements --ai-model "bad model!"
        The status should equal 1
        The stderr should include "AI model"
      End

      It "[Error] Should: exit with status 1 and output 'AI model' error for 'bad@model'"
        When run bash "$SCRIPT" requirements --ai-model "bad@model"
        The status should equal 1
        The stderr should include "AI model"
      End
    End

  End

  # --------------------------------------------------------------------------
  # Given: --phase option provided
  # --------------------------------------------------------------------------

  Describe "Given: --phase option provided"

    Before "setup_deckrd_tmpdir"
    After  "teardown_deckrd_tmpdir"

    Describe "When: run with invalid phase"
      It "[Error] Should: exit with status 1 and output 'Invalid review phase' error"
        When run bash "$SCRIPT" review --phase invalid
        The status should equal 1
        The stderr should include "Invalid review phase"
      End
    End

    Describe "When: run with valid phase"
      It "[Normal] Should: not output 'Invalid review phase' error for '--phase explore'"
        When run bash "$SCRIPT" review --phase explore
        The status should equal 1
        The stderr should not include "Invalid review phase"
      End

      It "[Normal] Should: not output 'Invalid review phase' error for '--phase harden'"
        When run bash "$SCRIPT" review --phase harden
        The status should equal 1
        The stderr should not include "Invalid review phase"
      End

      It "[Normal] Should: not output 'Invalid review phase' error for '--phase fix'"
        When run bash "$SCRIPT" review --phase fix
        The status should equal 1
        The stderr should not include "Invalid review phase"
      End
    End

  End

  # --------------------------------------------------------------------------
  # Given: too many positional arguments provided
  # --------------------------------------------------------------------------

  Describe "Given: too many positional arguments provided"

    Before "setup_deckrd_tmpdir"
    After  "teardown_deckrd_tmpdir"

    Describe "When: run with 3 or more positional arguments"
      It "[Error] Should: exit with status 1 and output 'Too many positional arguments' error"
        When run bash "$SCRIPT" requirements context1 extra_arg
        The status should equal 1
        The output should include "Usage:"
        The stderr should include "Too many positional arguments"
      End
    End

  End

End
