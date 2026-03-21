#!/usr/bin/env bash
# bootstrap.spec.sh - ShellSpec tests for scripts/lib/bootstrap.sh
#
# Copyright (c) 2026- atsushifx <https://github.com/atsushifx>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

_LIB_DIR="$(cd "${SHELLSPEC_PROJECT_ROOT}/plugins/deckrd/skills/deckrd/scripts/libs" && pwd)"
# shellcheck disable=SC1091
. "${_LIB_DIR}/bootstrap.sh"
unset _LIB_DIR

Include ../spec_helper.sh

SCRIPT="${DECKRD_LIB_DIR}/bootstrap.sh"

Describe "bootstrap.sh"
  Describe "bootstrap.sh loading"
    Describe "When: bootstrap.sh を source する"
      It "Then: [Normal] ステータス 0 で終了する"
        When run bash -c "source \"$SCRIPT\" && echo ok"
        The status should equal 0
        The output should equal "ok"
      End
    End
  End

  Describe "PROJECT_ROOT"
    Describe "Given: PROJECT_ROOT が未設定"
      Describe "When: bootstrap.sh を source する"
        It "Then: [Normal] PROJECT_ROOT が空でない"
          When run bash -c "unset PROJECT_ROOT; source \"$SCRIPT\" && echo \"\$PROJECT_ROOT\""
          The status should equal 0
          The output should not equal ""
        End
      End
    End

    Describe "Given: PROJECT_ROOT=/tmp を事前設定"
      Describe "When: bootstrap.sh を source する"
        It "Then: [Normal] PROJECT_ROOT が /tmp のまま維持される"
          When run bash -c "export PROJECT_ROOT=/tmp; source \"$SCRIPT\" && echo \"\$PROJECT_ROOT\""
          The status should equal 0
          The output should equal "/tmp"
        End
      End
    End

    Describe "Given: PROJECT_ROOT にスペースを含むパスを事前設定"
      Describe "When: bootstrap.sh を source する"
        It "Then: [Edge] PROJECT_ROOT がスペース込みパスのまま維持される"
          When run bash -c "export PROJECT_ROOT='/tmp/my project'; source \"$SCRIPT\" && echo \"\$PROJECT_ROOT\""
          The status should equal 0
          The output should equal "/tmp/my project"
        End
      End
    End
  End

  Describe "DECKRD_ROOT"
    Describe "Given: DECKRD_ROOT が未設定"
      Describe "When: bootstrap.sh を source する"
        It "Then: [Normal] DECKRD_ROOT が /plugins/deckrd/skills/deckrd で終わる"
          When run bash -c "unset DECKRD_ROOT; source \"$SCRIPT\" && echo \"\$DECKRD_ROOT\""
          The status should equal 0
          The output should end with "/plugins/deckrd/skills/deckrd"
        End
      End
    End

    Describe "Given: DECKRD_ROOT=/tmp/deckrd を事前設定"
      Describe "When: bootstrap.sh を source する"
        It "Then: [Normal] DECKRD_ROOT が /tmp/deckrd のまま維持される"
          When run bash -c "export DECKRD_ROOT=/tmp/deckrd; source \"$SCRIPT\" && echo \"\$DECKRD_ROOT\""
          The status should equal 0
          The output should equal "/tmp/deckrd"
        End
      End
    End
  End

  Describe "DECKRD_SCRIPTS_DIR"
    Describe "Given: DECKRD_SCRIPTS_DIR が未設定"
      Describe "When: bootstrap.sh を source する"
        It "Then: [Normal] DECKRD_SCRIPTS_DIR が /scripts で終わる"
          When run bash -c "unset DECKRD_SCRIPTS_DIR; source \"$SCRIPT\" && echo \"\$DECKRD_SCRIPTS_DIR\""
          The status should equal 0
          The output should end with "/scripts"
        End
      End
    End

    Describe "Given: DECKRD_ROOT=/tmp/deckrd を事前設定"
      Describe "When: bootstrap.sh を source する"
        It "Then: [Normal] DECKRD_SCRIPTS_DIR が DECKRD_ROOT/scripts になる"
          When run bash -c "unset DECKRD_SCRIPTS_DIR; export DECKRD_ROOT=/tmp/deckrd; source \"$SCRIPT\" && echo \"\$DECKRD_SCRIPTS_DIR\""
          The status should equal 0
          The output should equal "/tmp/deckrd/scripts"
        End
      End
    End
  End

  Describe "DECKRD_LIB_DIR"
    Describe "Given: DECKRD_LIB_DIR が未設定"
      Describe "When: bootstrap.sh を source する"
        It "Then: [Normal] DECKRD_LIB_DIR が /scripts/libs で終わる"
          When run bash -c "unset DECKRD_LIB_DIR; source \"$SCRIPT\" && echo \"\$DECKRD_LIB_DIR\""
          The status should equal 0
          The output should end with "/scripts/libs"
        End
      End
    End

    Describe "Given: DECKRD_ROOT=/tmp/deckrd を事前設定"
      Describe "When: bootstrap.sh を source する"
        It "Then: [Normal] DECKRD_LIB_DIR が DECKRD_ROOT/scripts/libs になる"
          When run bash -c "unset DECKRD_LIB_DIR; export DECKRD_ROOT=/tmp/deckrd; source \"$SCRIPT\" && echo \"\$DECKRD_LIB_DIR\""
          The status should equal 0
          The output should equal "/tmp/deckrd/scripts/libs"
        End
      End
    End
  End

  Describe "冪等性"
    Describe "Given: bootstrap.sh が既に source 済み"
      Describe "When: 再度 bootstrap.sh を source する"
        It "Then: [Normal] PROJECT_ROOT が変化しない"
          When run bash -c "source \"$SCRIPT\" && FIRST=\"\$PROJECT_ROOT\" && source \"$SCRIPT\" && [[ \"\$PROJECT_ROOT\" == \"\$FIRST\" ]] && echo ok"
          The status should equal 0
          The output should equal "ok"
        End

        It "Then: [Normal] DECKRD_ROOT が変化しない"
          When run bash -c "source \"$SCRIPT\" && FIRST=\"\$DECKRD_ROOT\" && source \"$SCRIPT\" && [[ \"\$DECKRD_ROOT\" == \"\$FIRST\" ]] && echo ok"
          The status should equal 0
          The output should equal "ok"
        End

        It "Then: [Normal] DECKRD_SCRIPTS_DIR が変化しない"
          When run bash -c "source \"$SCRIPT\" && FIRST=\"\$DECKRD_SCRIPTS_DIR\" && source \"$SCRIPT\" && [[ \"\$DECKRD_SCRIPTS_DIR\" == \"\$FIRST\" ]] && echo ok"
          The status should equal 0
          The output should equal "ok"
        End

        It "Then: [Normal] DECKRD_LIB_DIR が変化しない"
          When run bash -c "source \"$SCRIPT\" && FIRST=\"\$DECKRD_LIB_DIR\" && source \"$SCRIPT\" && [[ \"\$DECKRD_LIB_DIR\" == \"\$FIRST\" ]] && echo ok"
          The status should equal 0
          The output should equal "ok"
        End
      End
    End
  End
End
