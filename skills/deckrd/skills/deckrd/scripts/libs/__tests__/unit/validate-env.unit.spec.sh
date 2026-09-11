#!/usr/bin/env bash
# validate-env.spec.sh - ShellSpec tests for validate-env.sh
#
# Copyright (c) 2026- atsushifx <https://github.com/atsushifx>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

# shellcheck disable=SC1090

_RUNTIME_BOOTSTRAP="${SHELLSPEC_PROJECT_ROOT}/skills/deckrd/skills/deckrd/scripts/libs/bootstrap.lib.sh"
. "$_RUNTIME_BOOTSTRAP"
unset _RUNTIME_BOOTSTRAP

Include ../spec_helper.sh

SCRIPT="${DECKRD_LIB_DIR}/validate-env.lib.sh"
. "$SCRIPT"

Describe "validate-env.sh"
  Describe "validate-env.sh loading"
    Describe "When: スクリプトを読み込む"
      It "Then: [Normal] T-LIB-VLD-01: validate_env 関数が存在する"
        When call type validate_env
        The status should equal 0
        The output should include "validate_env"
      End
    End
  End

  Describe "validate_env"
    Describe "Given: jq がインストールされている環境"
      Describe "When: validate_env を呼ぶ"
        It "Then: [Normal] T-LIB-VENV-01: exit 0 を返し、jqexe が設定される"
          When call validate_env
          The status should equal 0
          The variable jqexe should not be blank
        End
      End
    End

    Describe "Given: jaq も jq もインストールされていない環境 (両方を隠す)"
      Describe "When: validate_env を呼ぶ"
        It "Then: [Error] T-LIB-VENV-02: return 1 を返し、stderr に 'jq or jaq is required' を含む"
          # 新規サブシェルで validate-env.sh を source し、jq/jaq を隠して validate_env を呼ぶ
          When run /usr/bin/bash -c "command() { [[ \"\$*\" == *jq* || \"\$*\" == *jaq* ]] && return 1; builtin command \"\$@\"; }; export -f command; . '${DECKRD_LIB_DIR}/validate-env.lib.sh'; validate_env"
          The status should equal 1
          The stderr should include "jq or jaq is required"
        End
      End
    End

    Describe "Given: jq と jaq の両方が使える環境 (両方を見つかる扱いにする)"
      Describe "When: validate_env を呼ぶ"
        It "Then: [Normal] T-LIB-VENV-03-01: jqexe が 'jq' に解決される"
          # 新規サブシェルで command を上書きし、jq/jaq をどちらも利用可能として validate_env を呼ぶ
          When run /usr/bin/bash -c "command() { [[ \"\$*\" == *jaq* || \"\$*\" == *jq* ]] && return 0; builtin command \"\$@\"; }; export -f command; . '${DECKRD_LIB_DIR}/validate-env.lib.sh'; validate_env; echo \"\$jqexe\""
          The status should equal 0
          The output should equal "jq"
        End
      End
    End

    Describe "Given: jq が使えず jaq だけがある環境 (jq を隠す)"
      Describe "When: validate_env を呼ぶ"
        It "Then: [Normal] T-LIB-VENV-03-02: jqexe が 'jaq' にフォールバックする"
          When run /usr/bin/bash -c "command() { [[ \"\$*\" == *jaq* ]] && return 0; [[ \"\$*\" == *jq* ]] && return 1; builtin command \"\$@\"; }; export -f command; . '${DECKRD_LIB_DIR}/validate-env.lib.sh'; validate_env; echo \"\$jqexe\""
          The status should equal 0
          The output should equal "jaq"
        End
      End
    End

    Describe "Given: jqexe が事前に設定されている環境"
      Describe "When: validate_env を呼ぶ"
        It "Then: [Normal] T-LIB-VENV-04: 事前設定値を無条件に上書きする"
          When run /usr/bin/bash -c "command() { [[ \"\$*\" == *jaq* || \"\$*\" == *jq* ]] && return 0; builtin command \"\$@\"; }; export -f command; export jqexe=PRESET; . '${DECKRD_LIB_DIR}/validate-env.lib.sh'; validate_env; echo \"\$jqexe\""
          The status should equal 0
          The output should equal "jq"
        End
      End
    End
  End
End
