#!/usr/bin/env bash
# validate-env.spec.sh - ShellSpec tests for validate-env.sh
#
# Copyright (c) 2026- atsushifx <https://github.com/atsushifx>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

Include spec_helper.sh

SCRIPT="${DECKRD_LIB_DIR}/validate-env.sh"

# shellcheck disable=SC1090
. "$SCRIPT"

Describe "validate-env.sh"
  Describe "validate-env.sh loading"
    Describe "When: スクリプトを読み込む"
      It "Then: [Normal] validate_env 関数が存在する"
        When call type validate_env
        The status should equal 0
        The output should include "validate_env"
      End
    End
  End

  Describe "validate_env"
    Describe "Given: jq がインストールされている環境"
      Describe "When: validate_env を呼ぶ"
        It "Then: [Normal] exit 0 を返す"
          When call validate_env
          The status should equal 0
        End
      End
    End

    Describe "Given: jq がインストールされていない環境 (jq を隠す)"
      Describe "When: validate_env を呼ぶ"
        It "Then: [Error] return 1 を返し、stdout に 'jq is required' を含む"
          # 新規サブシェルで validate-env.sh を source し、jq を隠して validate_env を呼ぶ
          When run /usr/bin/bash -c "command() { [[ \"\$*\" == *jq* ]] && return 1; builtin command \"\$@\"; }; export -f command; . '${DECKRD_LIB_DIR}/validate-env.sh'; validate_env"
          The status should equal 1
          The output should include "jq is required"
        End
      End
    End
  End
End
