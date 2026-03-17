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

    Describe "Given: PROJECT_ROOT に空文字列を export"
      Describe "When: bootstrap.sh を source する"
        It "Then: [Error] PROJECT_ROOT が空でない値に設定される"
          When run bash -c "export PROJECT_ROOT=''; source \"$SCRIPT\" && echo \"\$PROJECT_ROOT\""
          The status should equal 0
          The output should not equal ""
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

  Describe "SCRIPTS_DIR"
    Describe "Given: SCRIPTS_DIR が未設定"
      Describe "When: bootstrap.sh を source する"
        It "Then: [Normal] SCRIPTS_DIR が /scripts で終わる"
          When run bash -c "unset SCRIPTS_DIR; source \"$SCRIPT\" && echo \"\$SCRIPTS_DIR\""
          The status should equal 0
          The output should end with "/scripts"
        End
      End
    End

    Describe "Given: SCRIPTS_DIR=/tmp/scripts を事前設定"
      Describe "When: bootstrap.sh を source する"
        It "Then: [Normal] SCRIPTS_DIR が /tmp/scripts のまま維持される"
          When run bash -c "export SCRIPTS_DIR=/tmp/scripts; source \"$SCRIPT\" && echo \"\$SCRIPTS_DIR\""
          The status should equal 0
          The output should equal "/tmp/scripts"
        End
      End
    End

    Describe "Given: SCRIPTS_DIR にスペースを含むパスを事前設定"
      Describe "When: bootstrap.sh を source する"
        It "Then: [Edge] SCRIPTS_DIR がスペース込みパスのまま維持される"
          When run bash -c "export SCRIPTS_DIR='/tmp/my scripts'; source \"$SCRIPT\" && echo \"\$SCRIPTS_DIR\""
          The status should equal 0
          The output should equal "/tmp/my scripts"
        End
      End
    End
  End

  Describe "PLUGINS_DIR"
    Describe "Given: PLUGINS_DIR が未設定"
      Describe "When: bootstrap.sh を source する"
        It "Then: [Normal] PLUGINS_DIR が /plugins で終わる"
          When run bash -c "unset PLUGINS_DIR; source \"$SCRIPT\" && echo \"\$PLUGINS_DIR\""
          The status should equal 0
          The output should end with "/plugins"
        End
      End
    End

    Describe "Given: PLUGINS_DIR=/tmp/plugins を事前設定"
      Describe "When: bootstrap.sh を source する"
        It "Then: [Normal] PLUGINS_DIR が /tmp/plugins のまま維持される"
          When run bash -c "export PLUGINS_DIR=/tmp/plugins; source \"$SCRIPT\" && echo \"\$PLUGINS_DIR\""
          The status should equal 0
          The output should equal "/tmp/plugins"
        End
      End
    End

    Describe "Given: PLUGINS_DIR にスペースを含むパスを事前設定"
      Describe "When: bootstrap.sh を source する"
        It "Then: [Edge] PLUGINS_DIR がスペース込みパスのまま維持される"
          When run bash -c "export PLUGINS_DIR='/tmp/my plugins'; source \"$SCRIPT\" && echo \"\$PLUGINS_DIR\""
          The status should equal 0
          The output should equal "/tmp/my plugins"
        End
      End
    End
  End

  Describe "DECKRD_LIB_DIR"
    Describe "Given: DECKRD_LIB_DIR が未設定"
      Describe "When: bootstrap.sh を source する"
        It "Then: [Normal] DECKRD_LIB_DIR が /deckrd/skills/deckrd/scripts/libs で終わる"
          When run bash -c "unset DECKRD_LIB_DIR; source \"$SCRIPT\" && echo \"\$DECKRD_LIB_DIR\""
          The status should equal 0
          The output should end with "/deckrd/skills/deckrd/scripts/libs"
        End
      End
    End

    Describe "Given: DECKRD_LIB_DIR=/tmp/libs を事前設定"
      Describe "When: bootstrap.sh を source する"
        It "Then: [Normal] DECKRD_LIB_DIR が /tmp/libs のまま維持される"
          When run bash -c "export DECKRD_LIB_DIR=/tmp/libs; source \"$SCRIPT\" && echo \"\$DECKRD_LIB_DIR\""
          The status should equal 0
          The output should equal "/tmp/libs"
        End
      End
    End

    Describe "Given: DECKRD_LIB_DIR にスペースを含むパスを事前設定"
      Describe "When: bootstrap.sh を source する"
        It "Then: [Edge] DECKRD_LIB_DIR がスペース込みパスのまま維持される"
          When run bash -c "export DECKRD_LIB_DIR='/tmp/my libs'; source \"$SCRIPT\" && echo \"\$DECKRD_LIB_DIR\""
          The status should equal 0
          The output should equal "/tmp/my libs"
        End
      End
    End
  End

  Describe "ASSETS_DIR"
    Describe "Given: ASSETS_DIR が未設定"
      Describe "When: bootstrap.sh を source する"
        It "Then: [Normal] ASSETS_DIR が /.claude で終わる"
          When run bash -c "unset ASSETS_DIR; source \"$SCRIPT\" && echo \"\$ASSETS_DIR\""
          The status should equal 0
          The output should end with "/.claude"
        End
      End
    End

    Describe "Given: ASSETS_DIR=/tmp/assets を事前設定"
      Describe "When: bootstrap.sh を source する"
        It "Then: [Normal] ASSETS_DIR が /tmp/assets のまま維持される"
          When run bash -c "export ASSETS_DIR=/tmp/assets; source \"$SCRIPT\" && echo \"\$ASSETS_DIR\""
          The status should equal 0
          The output should equal "/tmp/assets"
        End
      End
    End

    Describe "Given: ASSETS_DIR にスペースを含むパスを事前設定"
      Describe "When: bootstrap.sh を source する"
        It "Then: [Edge] ASSETS_DIR がスペース込みパスのまま維持される"
          When run bash -c "export ASSETS_DIR='/tmp/my assets'; source \"$SCRIPT\" && echo \"\$ASSETS_DIR\""
          The status should equal 0
          The output should equal "/tmp/my assets"
        End
      End
    End
  End

  Describe "AGENTS_DIR"
    Describe "Given: AGENTS_DIR が未設定"
      Describe "When: bootstrap.sh を source する"
        It "Then: [Normal] AGENTS_DIR が /.claude/agents で終わる"
          When run bash -c "unset AGENTS_DIR; source \"$SCRIPT\" && echo \"\$AGENTS_DIR\""
          The status should equal 0
          The output should end with "/.claude/agents"
        End
      End
    End

    Describe "Given: AGENTS_DIR=/tmp/agents を事前設定"
      Describe "When: bootstrap.sh を source する"
        It "Then: [Normal] AGENTS_DIR が /tmp/agents のまま維持される"
          When run bash -c "export AGENTS_DIR=/tmp/agents; source \"$SCRIPT\" && echo \"\$AGENTS_DIR\""
          The status should equal 0
          The output should equal "/tmp/agents"
        End
      End
    End

    Describe "Given: AGENTS_DIR にスペースを含むパスを事前設定"
      Describe "When: bootstrap.sh を source する"
        It "Then: [Edge] AGENTS_DIR がスペース込みパスのまま維持される"
          When run bash -c "export AGENTS_DIR='/tmp/my agents'; source \"$SCRIPT\" && echo \"\$AGENTS_DIR\""
          The status should equal 0
          The output should equal "/tmp/my agents"
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

        It "Then: [Normal] SCRIPTS_DIR が変化しない"
          When run bash -c "source \"$SCRIPT\" && FIRST=\"\$SCRIPTS_DIR\" && source \"$SCRIPT\" && [[ \"\$SCRIPTS_DIR\" == \"\$FIRST\" ]] && echo ok"
          The status should equal 0
          The output should equal "ok"
        End

        It "Then: [Normal] PLUGINS_DIR が変化しない"
          When run bash -c "source \"$SCRIPT\" && FIRST=\"\$PLUGINS_DIR\" && source \"$SCRIPT\" && [[ \"\$PLUGINS_DIR\" == \"\$FIRST\" ]] && echo ok"
          The status should equal 0
          The output should equal "ok"
        End

        It "Then: [Normal] DECKRD_LIB_DIR が変化しない"
          When run bash -c "source \"$SCRIPT\" && FIRST=\"\$DECKRD_LIB_DIR\" && source \"$SCRIPT\" && [[ \"\$DECKRD_LIB_DIR\" == \"\$FIRST\" ]] && echo ok"
          The status should equal 0
          The output should equal "ok"
        End

        It "Then: [Normal] ASSETS_DIR が変化しない"
          When run bash -c "source \"$SCRIPT\" && FIRST=\"\$ASSETS_DIR\" && source \"$SCRIPT\" && [[ \"\$ASSETS_DIR\" == \"\$FIRST\" ]] && echo ok"
          The status should equal 0
          The output should equal "ok"
        End

        It "Then: [Normal] AGENTS_DIR が変化しない"
          When run bash -c "source \"$SCRIPT\" && FIRST=\"\$AGENTS_DIR\" && source \"$SCRIPT\" && [[ \"\$AGENTS_DIR\" == \"\$FIRST\" ]] && echo ok"
          The status should equal 0
          The output should equal "ok"
        End
      End
    End
  End
End
