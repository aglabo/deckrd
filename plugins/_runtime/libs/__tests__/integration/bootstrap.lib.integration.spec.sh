#!/usr/bin/env bash
# src: ./plugins/_runtime/libs/__tests__/integration/bootstrap.lib.integration.spec.sh
# @(#) : ShellSpec integration tests for bootstrap.lib.sh
#        git execution dependency, BASH_SOURCE fallback, idempotency.
#        Tests rely on real git repository state and external process behavior.
#
# Copyright (c) 2026- aglabo <https://github.com/aglabo>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

# shellcheck disable=SC1091

_RUNTIME_LIBS_DIR="$(cd "${SHELLSPEC_PROJECT_ROOT}/plugins/_runtime/libs" && pwd)"

Include "../spec_helper.sh"

SCRIPT="${_RUNTIME_LIBS_DIR}/bootstrap.lib.sh"

Describe "bootstrap.lib.sh"

  # ------------------------------------------------------------------ #
  #  PROJECT_ROOT: git 自動検出                                         #
  # ------------------------------------------------------------------ #
  Describe "PROJECT_ROOT: git 自動検出"

    It "[Normal] 未設定 → git rev-parse --show-toplevel と一致する"
      expected="$(git rev-parse --show-toplevel 2>/dev/null)"
      When run bash -c "unset PROJECT_ROOT; . \"$SCRIPT\" && echo \"\$PROJECT_ROOT\""
      The status should equal 0
      The output should equal "$expected"
    End

    It "[Normal] 未設定 → PROJECT_ROOT が空でない"
      When run bash -c "unset PROJECT_ROOT; . \"$SCRIPT\" && echo \"\$PROJECT_ROOT\""
      The status should equal 0
      The output should not equal ""
    End

    It "[Normal] 未設定 → PROJECT_ROOT が実際のディレクトリである"
      When run bash -c "unset PROJECT_ROOT; . \"$SCRIPT\" && [[ -d \"\$PROJECT_ROOT\" ]] && echo ok"
      The status should equal 0
      The output should equal "ok"
    End

    It "[Edge] 空文字設定 → 自動検出で上書きされる"
      When run bash -c "export PROJECT_ROOT=''; . \"$SCRIPT\" && echo \"\$PROJECT_ROOT\""
      The status should equal 0
      The output should not equal ""
    End

    It "[Edge] 空文字設定 → 上書き後は実際のディレクトリになる"
      When run bash -c "export PROJECT_ROOT=''; . \"$SCRIPT\" && [[ -d \"\$PROJECT_ROOT\" ]] && echo ok"
      The status should equal 0
      The output should equal "ok"
    End
  End

  # ------------------------------------------------------------------ #
  #  PROJECT_ROOT: BASH_SOURCE fallback (git なし)                     #
  # ------------------------------------------------------------------ #
  Describe "PROJECT_ROOT: BASH_SOURCE fallback"

    It "[Normal] git が PATH にない → BASH_SOURCE fallback で PROJECT_ROOT が空でない"
      saved_path="$PATH"
      When run bash -c "
        export PATH=\"${saved_path}\"
        git_dir=\"\$(dirname \"\$(command -v git 2>/dev/null)\" 2>/dev/null || true)\"
        if [[ -n \"\$git_dir\" ]]; then
          export PATH=\"\$(printf '%s' \"\$PATH\" | tr ':' '\n' | grep -v \"^\${git_dir}\$\" | tr '\n' ':')\"
          export PATH=\"\${PATH%:}\"
        fi
        unset PROJECT_ROOT
        . \"$SCRIPT\" && echo \"\$PROJECT_ROOT\"
      "
      The status should equal 0
      The output should not equal ""
    End

    It "[Normal] git が PATH にない → BASH_SOURCE fallback の PROJECT_ROOT は実際のディレクトリ"
      saved_path="$PATH"
      When run bash -c "
        export PATH=\"${saved_path}\"
        git_dir=\"\$(dirname \"\$(command -v git 2>/dev/null)\" 2>/dev/null || true)\"
        if [[ -n \"\$git_dir\" ]]; then
          export PATH=\"\$(printf '%s' \"\$PATH\" | tr ':' '\n' | grep -v \"^\${git_dir}\$\" | tr '\n' ':')\"
          export PATH=\"\${PATH%:}\"
        fi
        unset PROJECT_ROOT
        . \"$SCRIPT\" && [[ -d \"\$PROJECT_ROOT\" ]] && echo ok
      "
      The status should equal 0
      The output should equal "ok"
    End
  End

  # ------------------------------------------------------------------ #
  #  冪等性: 2回 source                                                 #
  # ------------------------------------------------------------------ #
  Describe "冪等性: 2回 source"

    It "[Normal] 2回 source → PROJECT_ROOT が変化しない"
      When run bash -c ". \"$SCRIPT\" && FIRST=\"\$PROJECT_ROOT\" && . \"$SCRIPT\" && [[ \"\$PROJECT_ROOT\" == \"\$FIRST\" ]] && echo ok"
      The status should equal 0
      The output should equal "ok"
    End

    It "[Normal] 2回 source → DECKRD_ROOT が変化しない"
      When run bash -c ". \"$SCRIPT\" && FIRST=\"\$DECKRD_ROOT\" && . \"$SCRIPT\" && [[ \"\$DECKRD_ROOT\" == \"\$FIRST\" ]] && echo ok"
      The status should equal 0
      The output should equal "ok"
    End

    It "[Normal] 2回 source → DECKRD_SCRIPTS_DIR が変化しない"
      When run bash -c ". \"$SCRIPT\" && FIRST=\"\$DECKRD_SCRIPTS_DIR\" && . \"$SCRIPT\" && [[ \"\$DECKRD_SCRIPTS_DIR\" == \"\$FIRST\" ]] && echo ok"
      The status should equal 0
      The output should equal "ok"
    End

    It "[Normal] 2回 source → DECKRD_LIB_DIR が変化しない"
      When run bash -c ". \"$SCRIPT\" && FIRST=\"\$DECKRD_LIB_DIR\" && . \"$SCRIPT\" && [[ \"\$DECKRD_LIB_DIR\" == \"\$FIRST\" ]] && echo ok"
      The status should equal 0
      The output should equal "ok"
    End

    It "[Normal] 2回 source → RUNTIME_LIB_DIR が変化しない"
      When run bash -c ". \"$SCRIPT\" && FIRST=\"\$RUNTIME_LIB_DIR\" && . \"$SCRIPT\" && [[ \"\$RUNTIME_LIB_DIR\" == \"\$FIRST\" ]] && echo ok"
      The status should equal 0
      The output should equal "ok"
    End

    It "[Normal] 2回 source → DECKRD_DATA_DIR が変化しない"
      When run bash -c ". \"$SCRIPT\" && FIRST=\"\$DECKRD_DATA_DIR\" && . \"$SCRIPT\" && [[ \"\$DECKRD_DATA_DIR\" == \"\$FIRST\" ]] && echo ok"
      The status should equal 0
      The output should equal "ok"
    End

    It "[Normal] 2回 source → DECKRD_LOCAL_DATA が変化しない"
      When run bash -c ". \"$SCRIPT\" && FIRST=\"\$DECKRD_LOCAL_DATA\" && . \"$SCRIPT\" && [[ \"\$DECKRD_LOCAL_DATA\" == \"\$FIRST\" ]] && echo ok"
      The status should equal 0
      The output should equal "ok"
    End

    It "[Normal] 2回 source → DECKRD_DOCS_DIR が変化しない"
      When run bash -c ". \"$SCRIPT\" && FIRST=\"\$DECKRD_DOCS_DIR\" && . \"$SCRIPT\" && [[ \"\$DECKRD_DOCS_DIR\" == \"\$FIRST\" ]] && echo ok"
      The status should equal 0
      The output should equal "ok"
    End

    It "[Normal] 2回 source → SYMBOL が変化しない"
      When run bash -c ". \"$SCRIPT\" && FIRST=\"\$SYMBOL\" && . \"$SCRIPT\" && [[ \"\$SYMBOL\" == \"\$FIRST\" ]] && echo ok"
      The status should equal 0
      The output should equal "ok"
    End

    It "[Normal] 2回 source → _BOOTSTRAP_LOADED が変化しない"
      When run bash -c ". \"$SCRIPT\" && FIRST=\"\$_BOOTSTRAP_LOADED\" && . \"$SCRIPT\" && [[ \"\$_BOOTSTRAP_LOADED\" == \"\$FIRST\" ]] && echo ok"
      The status should equal 0
      The output should equal "ok"
    End
  End

  # ------------------------------------------------------------------ #
  #  冪等性: 3回 source                                                 #
  # ------------------------------------------------------------------ #
  Describe "冪等性: 3回 source"

    It "[Edge] 3回 source → DECKRD_ROOT が変化しない"
      When run bash -c ". \"$SCRIPT\" && FIRST=\"\$DECKRD_ROOT\" && . \"$SCRIPT\" && . \"$SCRIPT\" && [[ \"\$DECKRD_ROOT\" == \"\$FIRST\" ]] && echo ok"
      The status should equal 0
      The output should equal "ok"
    End

    It "[Edge] 3回 source → PROJECT_ROOT が変化しない"
      When run bash -c ". \"$SCRIPT\" && FIRST=\"\$PROJECT_ROOT\" && . \"$SCRIPT\" && . \"$SCRIPT\" && [[ \"\$PROJECT_ROOT\" == \"\$FIRST\" ]] && echo ok"
      The status should equal 0
      The output should equal "ok"
    End

    It "[Edge] 3回 source → ステータス 0 で終了する"
      When run bash -c ". \"$SCRIPT\" && . \"$SCRIPT\" && . \"$SCRIPT\" && echo ok"
      The status should equal 0
      The output should equal "ok"
    End
  End

End
