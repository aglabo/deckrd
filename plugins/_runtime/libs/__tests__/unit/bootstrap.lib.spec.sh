#!/usr/bin/env bash
# src: ./plugins/_runtime/libs/__tests__/unit/bootstrap.lib.spec.sh
# @(#) : ShellSpec unit tests for bootstrap.lib.sh
#
# Unit test design:
#   - Treats bootstrap as a public API (black-box strategy).
#   - Internal resolver functions are NOT tested directly.
#   - bootstrap_init is called in Before with injected dependencies.
#   - bootstrap_finalize is NOT called in Before -> variables remain writable.
#   - "When call" directly reads variable values set by bootstrap_init.
#   - All upstream variables are fixed before calling bootstrap_init.
#
# Coverage requirements:
#   (1) Input patterns per variable: normal absolute path, pre-set, space in path
#   (2) Dependency fixation: verify which upstream variable each variable depends on
#   (3) Idempotency: bootstrap_init x2, bootstrap_finalize x2 -> no error, no change
#   (4) Side effects: export confirmed via "export -p", other variables unaffected
#   (5) BASH_SOURCE detection: deckrd-coder path vs deckrd path
#
# Copyright (c) 2026- aglabo <https://github.com/aglabo>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

# shellcheck disable=SC1091

_RUNTIME_LIBS_DIR="$(cd "${SHELLSPEC_PROJECT_ROOT}/plugins/_runtime/libs" && pwd)"

Include "../spec_helper.sh"

SCRIPT="${_RUNTIME_LIBS_DIR}/bootstrap.lib.sh"

# Source bootstrap with no-finalize so variables remain writable in this spec
# process. Before blocks call bootstrap_init with fixed dependencies to re-set
# variables under test. bootstrap_finalize is NOT called globally so that
# "When call" can inspect mutable variable values.
# shellcheck disable=SC1090
. "$SCRIPT" --no-finalize

Describe "bootstrap.lib.sh"

  # ------------------------------------------------------------------ #
  #  loading — source/init/finalize を分離して検証                     #
  # ------------------------------------------------------------------ #
  Describe "loading"

    It "[Normal] source して status=0 で終了する"
      When run bash -c "export PROJECT_ROOT=/tmp/proj; . \"$SCRIPT\"; echo ok"
      The status should equal 0
      The output should equal "ok"
    End

    It "[Normal] bootstrap_init を呼んで status=0 で終了する"
      When run bash -c "export PROJECT_ROOT=/tmp/proj; . \"$SCRIPT\" --no-finalize; bootstrap_init && echo ok"
      The status should equal 0
      The output should equal "ok"
    End

    It "[Normal] bootstrap_finalize を呼んで status=0 で終了する"
      When run bash -c "export PROJECT_ROOT=/tmp/proj; . \"$SCRIPT\"; bootstrap_finalize && echo ok"
      The status should equal 0
      The output should equal "ok"
    End
  End

  # ------------------------------------------------------------------ #
  #  export 検証 — export -p で実際に export されているか確認           #
  # ------------------------------------------------------------------ #
  Describe "export 検証"

    Describe "Given: PROJECT_ROOT=/tmp/proj で bootstrap_init を呼ぶ"
      Before "export PROJECT_ROOT=/tmp/proj; unset DECKRD_ROOT DECKRD_SCRIPTS_DIR DECKRD_LIB_DIR DECKRD_DATA_DIR DECKRD_LOCAL_DATA DECKRD_DOCS_DIR SYMBOL RUNTIME_LIB_DIR; bootstrap_init"

      It "[Normal] PROJECT_ROOT が export されている"
        When call bash -c 'export -p | grep -q "^declare -x PROJECT_ROOT=" && echo ok'
        The output should equal "ok"
      End

      It "[Normal] RUNTIME_LIB_DIR が export されている"
        When call bash -c 'export -p | grep -q "^declare -x RUNTIME_LIB_DIR=" && echo ok'
        The output should equal "ok"
      End

      It "[Normal] DECKRD_ROOT が export されている"
        When call bash -c 'export -p | grep -q "^declare -x DECKRD_ROOT=" && echo ok'
        The output should equal "ok"
      End

      It "[Normal] DECKRD_SCRIPTS_DIR が export されている"
        When call bash -c 'export -p | grep -q "^declare -x DECKRD_SCRIPTS_DIR=" && echo ok'
        The output should equal "ok"
      End

      It "[Normal] DECKRD_LIB_DIR が export されている"
        When call bash -c 'export -p | grep -q "^declare -x DECKRD_LIB_DIR=" && echo ok'
        The output should equal "ok"
      End

      It "[Normal] DECKRD_DATA_DIR が export されている"
        When call bash -c 'export -p | grep -q "^declare -x DECKRD_DATA_DIR=" && echo ok'
        The output should equal "ok"
      End

      It "[Normal] DECKRD_LOCAL_DATA が export されている"
        When call bash -c 'export -p | grep -q "^declare -x DECKRD_LOCAL_DATA=" && echo ok'
        The output should equal "ok"
      End

      It "[Normal] DECKRD_DOCS_DIR が export されている"
        When call bash -c 'export -p | grep -q "^declare -x DECKRD_DOCS_DIR=" && echo ok'
        The output should equal "ok"
      End

      It "[Normal] SYMBOL が export されている"
        When call bash -c 'export -p | grep -q "^declare -x SYMBOL=" && echo ok'
        The output should equal "ok"
      End
    End
  End

  # ------------------------------------------------------------------ #
  #  副作用: 他変数への影響なし                                         #
  # ------------------------------------------------------------------ #
  Describe "副作用: 他変数"

    It "[Normal] 事前設定した任意変数 FOO が bootstrap_init 後も維持される"
      When run bash -c "export FOO=bar; export PROJECT_ROOT=/tmp/proj; . \"$SCRIPT\"; [[ \"\$FOO\" == \"bar\" ]] && echo ok"
      The status should equal 0
      The output should equal "ok"
    End

    It "[Normal] 事前設定した任意変数 MY_VAR が bootstrap_finalize 後も維持される"
      When run bash -c "export MY_VAR=hello; export PROJECT_ROOT=/tmp/proj; . \"$SCRIPT\" && bootstrap_finalize; [[ \"\$MY_VAR\" == \"hello\" ]] && echo ok"
      The status should equal 0
      The output should equal "ok"
    End

    It "[Normal] PATH が変化しない"
      When run bash -c "before=\"\$PATH\"; export PROJECT_ROOT=/tmp/proj; . \"$SCRIPT\"; [[ \"\$PATH\" == \"\$before\" ]] && echo ok"
      The status should equal 0
      The output should equal "ok"
    End

    It "[Normal] IFS が変化しない"
      When run bash -c "before=\"\${IFS}\"; export PROJECT_ROOT=/tmp/proj; . \"$SCRIPT\"; [[ \"\${IFS}\" == \"\$before\" ]] && echo ok"
      The status should equal 0
      The output should equal "ok"
    End
  End

  # ------------------------------------------------------------------ #
  #  bootstrap_finalize — readonly 化の保証と冪等性                    #
  # ------------------------------------------------------------------ #
  Describe "bootstrap_finalize"

    It "[Normal] finalize 後は PROJECT_ROOT が readonly になっている"
      When run bash -c "export PROJECT_ROOT=/tmp/proj; . \"$SCRIPT\" && ( PROJECT_ROOT=x ) 2>/dev/null && echo writable || echo readonly"
      The status should equal 0
      The output should equal "readonly"
    End

    It "[Normal] finalize 後は RUNTIME_LIB_DIR が readonly になっている"
      When run bash -c "export PROJECT_ROOT=/tmp/proj; . \"$SCRIPT\" && ( RUNTIME_LIB_DIR=x ) 2>/dev/null && echo writable || echo readonly"
      The status should equal 0
      The output should equal "readonly"
    End

    It "[Normal] finalize 後は DECKRD_ROOT が readonly になっている"
      When run bash -c "export PROJECT_ROOT=/tmp/proj; . \"$SCRIPT\" && ( DECKRD_ROOT=x ) 2>/dev/null && echo writable || echo readonly"
      The status should equal 0
      The output should equal "readonly"
    End

    It "[Normal] finalize 後は DECKRD_SCRIPTS_DIR が readonly になっている"
      When run bash -c "export PROJECT_ROOT=/tmp/proj; . \"$SCRIPT\" && ( DECKRD_SCRIPTS_DIR=x ) 2>/dev/null && echo writable || echo readonly"
      The status should equal 0
      The output should equal "readonly"
    End

    It "[Normal] finalize 後は DECKRD_LIB_DIR が readonly になっている"
      When run bash -c "export PROJECT_ROOT=/tmp/proj; . \"$SCRIPT\" && ( DECKRD_LIB_DIR=x ) 2>/dev/null && echo writable || echo readonly"
      The status should equal 0
      The output should equal "readonly"
    End

    It "[Normal] finalize 後は DECKRD_DATA_DIR が readonly になっている"
      When run bash -c "export PROJECT_ROOT=/tmp/proj; . \"$SCRIPT\" && ( DECKRD_DATA_DIR=x ) 2>/dev/null && echo writable || echo readonly"
      The status should equal 0
      The output should equal "readonly"
    End

    It "[Normal] finalize 後は DECKRD_LOCAL_DATA が readonly になっている"
      When run bash -c "export PROJECT_ROOT=/tmp/proj; . \"$SCRIPT\" && ( DECKRD_LOCAL_DATA=x ) 2>/dev/null && echo writable || echo readonly"
      The status should equal 0
      The output should equal "readonly"
    End

    It "[Normal] finalize 後は DECKRD_DOCS_DIR が readonly になっている"
      When run bash -c "export PROJECT_ROOT=/tmp/proj; . \"$SCRIPT\" && ( DECKRD_DOCS_DIR=x ) 2>/dev/null && echo writable || echo readonly"
      The status should equal 0
      The output should equal "readonly"
    End

    It "[Normal] finalize 後は SYMBOL が readonly になっている"
      When run bash -c "export PROJECT_ROOT=/tmp/proj; . \"$SCRIPT\" && ( SYMBOL=x ) 2>/dev/null && echo writable || echo readonly"
      The status should equal 0
      The output should equal "readonly"
    End

    It "[Edge] bootstrap_finalize を 2 回呼んでもエラーにならない"
      When run bash -c "export PROJECT_ROOT=/tmp/proj; . \"$SCRIPT\" && bootstrap_finalize && echo ok"
      The status should equal 0
      The output should equal "ok"
    End
  End

  # ------------------------------------------------------------------ #
  #  冪等性: bootstrap_init 2回呼び出し                                 #
  # ------------------------------------------------------------------ #
  Describe "冪等性: bootstrap_init 2回"

    It "[Normal] PROJECT_ROOT が変化しない"
      When run bash -c "export PROJECT_ROOT=/tmp/proj; . \"$SCRIPT\" --no-finalize; FIRST=\"\$PROJECT_ROOT\"; bootstrap_init; [[ \"\$PROJECT_ROOT\" == \"\$FIRST\" ]] && echo ok"
      The status should equal 0
      The output should equal "ok"
    End

    It "[Normal] RUNTIME_LIB_DIR が変化しない"
      When run bash -c "export PROJECT_ROOT=/tmp/proj; export DECKRD_ROOT=/tmp/deckrd; . \"$SCRIPT\" --no-finalize; FIRST=\"\$RUNTIME_LIB_DIR\"; bootstrap_init; [[ \"\$RUNTIME_LIB_DIR\" == \"\$FIRST\" ]] && echo ok"
      The status should equal 0
      The output should equal "ok"
    End

    It "[Normal] DECKRD_ROOT が変化しない"
      When run bash -c "export PROJECT_ROOT=/tmp/proj; export DECKRD_ROOT=/tmp/deckrd; . \"$SCRIPT\" --no-finalize; FIRST=\"\$DECKRD_ROOT\"; bootstrap_init; [[ \"\$DECKRD_ROOT\" == \"\$FIRST\" ]] && echo ok"
      The status should equal 0
      The output should equal "ok"
    End

    It "[Normal] DECKRD_SCRIPTS_DIR が変化しない"
      When run bash -c "export PROJECT_ROOT=/tmp/proj; export DECKRD_ROOT=/tmp/deckrd; . \"$SCRIPT\" --no-finalize; FIRST=\"\$DECKRD_SCRIPTS_DIR\"; bootstrap_init; [[ \"\$DECKRD_SCRIPTS_DIR\" == \"\$FIRST\" ]] && echo ok"
      The status should equal 0
      The output should equal "ok"
    End

    It "[Normal] DECKRD_LIB_DIR が変化しない"
      When run bash -c "export PROJECT_ROOT=/tmp/proj; export DECKRD_ROOT=/tmp/deckrd; . \"$SCRIPT\" --no-finalize; FIRST=\"\$DECKRD_LIB_DIR\"; bootstrap_init; [[ \"\$DECKRD_LIB_DIR\" == \"\$FIRST\" ]] && echo ok"
      The status should equal 0
      The output should equal "ok"
    End
  End

  # ------------------------------------------------------------------ #
  #  BASH_SOURCE 依存: deckrd-coder パス検出                           #
  #  source したスクリプトのパスで DECKRD_ROOT が切り替わる             #
  # ------------------------------------------------------------------ #
  Describe "BASH_SOURCE 依存: deckrd-coder パス検出"
    Before setup_coder_tmpscript
    After teardown_coder_tmpscript

    It "[Normal] deckrd-coder パスから source → DECKRD_ROOT が deckrd-coder になる"
      When call run_coder_tmpscript DECKRD_ROOT
      The status should equal 0
      The output should end with "/plugins/deckrd-coder/skills/deckrd-coder"
    End

    It "[Normal] deckrd-coder パスから source → DECKRD_SCRIPTS_DIR が deckrd-coder/scripts になる"
      When call run_coder_tmpscript DECKRD_SCRIPTS_DIR
      The status should equal 0
      The output should end with "/plugins/deckrd-coder/skills/deckrd-coder/scripts"
    End

    It "[Normal] deckrd-coder パスから source → DECKRD_LIB_DIR が deckrd-coder/scripts/libs になる"
      When call run_coder_tmpscript DECKRD_LIB_DIR
      The status should equal 0
      The output should end with "/plugins/deckrd-coder/skills/deckrd-coder/scripts/libs"
    End

    It "[Normal] deckrd-coder パスでも DECKRD_ROOT 事前設定値が優先される"
      When run bash -c "
        mkdir -p /tmp/plugins/deckrd-coder
        tmpscript=\"\$(mktemp /tmp/plugins/deckrd-coder/XXXXXX.sh)\"
        printf 'export DECKRD_ROOT=/tmp/custom\n. \"%s\" && echo \"\$DECKRD_ROOT\"\n' \"$SCRIPT\" > \"\$tmpscript\"
        result=\$(bash \"\$tmpscript\")
        rm -f \"\$tmpscript\"
        echo \"\$result\"
      "
      The status should equal 0
      The output should equal "/tmp/custom"
    End
  End

  # ------------------------------------------------------------------ #
  #  RUNTIME_LIB_DIR                                                   #
  #  依存: PROJECT_ROOT のみ                                           #
  # ------------------------------------------------------------------ #
  Describe "RUNTIME_LIB_DIR"

    Describe "Given: PROJECT_ROOT=/tmp/proj、RUNTIME_LIB_DIR 未設定"
      Before "export PROJECT_ROOT=/tmp/proj; unset RUNTIME_LIB_DIR; bootstrap_init"

      It "[Normal] PROJECT_ROOT/plugins/_runtime/libs になる"
        When call echo "$RUNTIME_LIB_DIR"
        The output should equal "/tmp/proj/plugins/_runtime/libs"
      End

      It "[Normal] PROJECT_ROOT との関係式が成立する"
        When call test "$RUNTIME_LIB_DIR" = "${PROJECT_ROOT}/plugins/_runtime/libs"
        The status should equal 0
      End

      It "[Normal] export -p で export されている"
        When call bash -c 'export -p | grep -q "^declare -x RUNTIME_LIB_DIR=" && echo ok'
        The output should equal "ok"
      End
    End

    Describe "Given: RUNTIME_LIB_DIR=/tmp/custom-libs を事前設定"
      Before "export PROJECT_ROOT=/tmp/proj; export RUNTIME_LIB_DIR=/tmp/custom-libs; bootstrap_init"

      It "[Normal] 事前設定値が維持される"
        When call echo "$RUNTIME_LIB_DIR"
        The output should equal "/tmp/custom-libs"
      End
    End

    Describe "Given: PROJECT_ROOT にスペースを含むパス"
      Before "export PROJECT_ROOT='/tmp/my project'; unset RUNTIME_LIB_DIR; bootstrap_init"

      It "[Edge] パスが正しく連結される"
        When call echo "$RUNTIME_LIB_DIR"
        The output should equal "/tmp/my project/plugins/_runtime/libs"
      End
    End

    Describe "Given: DECKRD_ROOT=/tmp/other を設定 (PROJECT_ROOT から独立)"
      Before "export PROJECT_ROOT=/tmp/proj; export DECKRD_ROOT=/tmp/other; unset RUNTIME_LIB_DIR; bootstrap_init"

      It "[Edge] DECKRD_ROOT に依存せず PROJECT_ROOT が基点になる"
        When call echo "$RUNTIME_LIB_DIR"
        The output should equal "/tmp/proj/plugins/_runtime/libs"
      End
    End
  End

  # ------------------------------------------------------------------ #
  #  DECKRD_ROOT                                                        #
  #  依存: PROJECT_ROOT (未設定時の自動計算はソースパス依存)            #
  # ------------------------------------------------------------------ #
  Describe "DECKRD_ROOT"

    Describe "Given: PROJECT_ROOT=/tmp/proj、DECKRD_ROOT 未設定"
      Before "export PROJECT_ROOT=/tmp/proj; unset DECKRD_ROOT; bootstrap_init"

      It "[Normal] PROJECT_ROOT/plugins/deckrd/skills/deckrd になる"
        When call echo "$DECKRD_ROOT"
        The output should equal "/tmp/proj/plugins/deckrd/skills/deckrd"
      End

      It "[Normal] PROJECT_ROOT との関係式が成立する"
        When call test "$DECKRD_ROOT" = "${PROJECT_ROOT}/plugins/deckrd/skills/deckrd"
        The status should equal 0
      End

      It "[Normal] export -p で export されている"
        When call bash -c 'export -p | grep -q "^declare -x DECKRD_ROOT=" && echo ok'
        The output should equal "ok"
      End
    End

    Describe "Given: DECKRD_ROOT=/tmp/custom を事前設定"
      Before "export PROJECT_ROOT=/tmp/proj; export DECKRD_ROOT=/tmp/custom; bootstrap_init"

      It "[Normal] 事前設定値が維持される"
        When call echo "$DECKRD_ROOT"
        The output should equal "/tmp/custom"
      End
    End

    Describe "Given: DECKRD_ROOT=/tmp/custom を事前設定し PROJECT_ROOT を変更"
      Before "export PROJECT_ROOT=/tmp/other; export DECKRD_ROOT=/tmp/custom; bootstrap_init"

      It "[Normal] 事前設定時は PROJECT_ROOT が変わっても維持される"
        When call echo "$DECKRD_ROOT"
        The output should equal "/tmp/custom"
      End
    End

    Describe "Given: PROJECT_ROOT にスペースを含むパス"
      Before "export PROJECT_ROOT='/tmp/my project'; unset DECKRD_ROOT; bootstrap_init"

      It "[Edge] パスが正しく連結される"
        When call echo "$DECKRD_ROOT"
        The output should equal "/tmp/my project/plugins/deckrd/skills/deckrd"
      End
    End
  End

  # ------------------------------------------------------------------ #
  #  DECKRD_SCRIPTS_DIR                                                 #
  #  依存: DECKRD_ROOT のみ                                            #
  # ------------------------------------------------------------------ #
  Describe "DECKRD_SCRIPTS_DIR"

    Describe "Given: PROJECT_ROOT=/tmp/proj、DECKRD_ROOT=/tmp/deckrd、DECKRD_SCRIPTS_DIR 未設定"
      Before "export PROJECT_ROOT=/tmp/proj; export DECKRD_ROOT=/tmp/deckrd; unset DECKRD_SCRIPTS_DIR; bootstrap_init"

      It "[Normal] DECKRD_ROOT/scripts になる"
        When call echo "$DECKRD_SCRIPTS_DIR"
        The output should equal "/tmp/deckrd/scripts"
      End

      It "[Normal] DECKRD_ROOT との関係式が成立する"
        When call test "$DECKRD_SCRIPTS_DIR" = "${DECKRD_ROOT}/scripts"
        The status should equal 0
      End

      It "[Normal] export -p で export されている"
        When call bash -c 'export -p | grep -q "^declare -x DECKRD_SCRIPTS_DIR=" && echo ok'
        The output should equal "ok"
      End
    End

    Describe "Given: DECKRD_SCRIPTS_DIR=/tmp/scripts を事前設定"
      Before "export PROJECT_ROOT=/tmp/proj; export DECKRD_ROOT=/tmp/deckrd; export DECKRD_SCRIPTS_DIR=/tmp/scripts; bootstrap_init"

      It "[Normal] 事前設定値が維持される"
        When call echo "$DECKRD_SCRIPTS_DIR"
        The output should equal "/tmp/scripts"
      End
    End

    Describe "Given: DECKRD_ROOT にスペースを含むパス"
      Before "export PROJECT_ROOT=/tmp/proj; export DECKRD_ROOT='/tmp/my deckrd'; unset DECKRD_SCRIPTS_DIR; bootstrap_init"

      It "[Edge] パスが正しく連結される"
        When call echo "$DECKRD_SCRIPTS_DIR"
        The output should equal "/tmp/my deckrd/scripts"
      End
    End

    Describe "Given: PROJECT_ROOT=/tmp/other を設定 (DECKRD_ROOT から独立)"
      Before "export PROJECT_ROOT=/tmp/other; export DECKRD_ROOT=/tmp/deckrd; unset DECKRD_SCRIPTS_DIR; bootstrap_init"

      It "[Edge] PROJECT_ROOT に依存せず DECKRD_ROOT が基点になる"
        When call echo "$DECKRD_SCRIPTS_DIR"
        The output should equal "/tmp/deckrd/scripts"
      End
    End
  End

  # ------------------------------------------------------------------ #
  #  DECKRD_LIB_DIR                                                     #
  #  依存: DECKRD_ROOT のみ                                            #
  # ------------------------------------------------------------------ #
  Describe "DECKRD_LIB_DIR"

    Describe "Given: PROJECT_ROOT=/tmp/proj、DECKRD_ROOT=/tmp/deckrd、DECKRD_LIB_DIR 未設定"
      Before "export PROJECT_ROOT=/tmp/proj; export DECKRD_ROOT=/tmp/deckrd; unset DECKRD_LIB_DIR; bootstrap_init"

      It "[Normal] DECKRD_ROOT/scripts/libs になる"
        When call echo "$DECKRD_LIB_DIR"
        The output should equal "/tmp/deckrd/scripts/libs"
      End

      It "[Normal] DECKRD_ROOT との関係式が成立する"
        When call test "$DECKRD_LIB_DIR" = "${DECKRD_ROOT}/scripts/libs"
        The status should equal 0
      End

      It "[Normal] export -p で export されている"
        When call bash -c 'export -p | grep -q "^declare -x DECKRD_LIB_DIR=" && echo ok'
        The output should equal "ok"
      End
    End

    Describe "Given: DECKRD_LIB_DIR=/tmp/libs を事前設定"
      Before "export PROJECT_ROOT=/tmp/proj; export DECKRD_ROOT=/tmp/deckrd; export DECKRD_LIB_DIR=/tmp/libs; bootstrap_init"

      It "[Normal] 事前設定値が維持される"
        When call echo "$DECKRD_LIB_DIR"
        The output should equal "/tmp/libs"
      End
    End

    Describe "Given: DECKRD_ROOT にスペースを含むパス"
      Before "export PROJECT_ROOT=/tmp/proj; export DECKRD_ROOT='/tmp/my deckrd'; unset DECKRD_LIB_DIR; bootstrap_init"

      It "[Edge] パスが正しく連結される"
        When call echo "$DECKRD_LIB_DIR"
        The output should equal "/tmp/my deckrd/scripts/libs"
      End
    End

    Describe "Given: PROJECT_ROOT=/tmp/other を設定 (DECKRD_ROOT から独立)"
      Before "export PROJECT_ROOT=/tmp/other; export DECKRD_ROOT=/tmp/deckrd; unset DECKRD_LIB_DIR; bootstrap_init"

      It "[Edge] PROJECT_ROOT に依存せず DECKRD_ROOT が基点になる"
        When call echo "$DECKRD_LIB_DIR"
        The output should equal "/tmp/deckrd/scripts/libs"
      End
    End
  End

  # ------------------------------------------------------------------ #
  #  DECKRD_DATA_DIR                                                    #
  #  依存: XDG_DATA_HOME または HOME のみ (PROJECT_ROOT/DECKRD_ROOT 非依存) #
  # ------------------------------------------------------------------ #
  Describe "DECKRD_DATA_DIR"

    Describe "Given: XDG_DATA_HOME=/tmp/xdg"
      Before "export PROJECT_ROOT=/tmp/proj; export XDG_DATA_HOME=/tmp/xdg; unset DECKRD_DATA_DIR; bootstrap_init"

      It "[Normal] XDG_DATA_HOME/deckrd になる"
        When call echo "$DECKRD_DATA_DIR"
        The output should equal "/tmp/xdg/deckrd"
      End

      It "[Normal] XDG_DATA_HOME との関係式が成立する"
        When call test "$DECKRD_DATA_DIR" = "${XDG_DATA_HOME}/deckrd"
        The status should equal 0
      End

      It "[Normal] export -p で export されている"
        When call bash -c 'export -p | grep -q "^declare -x DECKRD_DATA_DIR=" && echo ok'
        The output should equal "ok"
      End
    End

    Describe "Given: XDG_DATA_HOME 未設定、HOME=/tmp/home"
      Before "export PROJECT_ROOT=/tmp/proj; unset XDG_DATA_HOME; export HOME=/tmp/home; unset DECKRD_DATA_DIR; bootstrap_init"

      It "[Normal] HOME/.local/share/deckrd になる"
        When call echo "$DECKRD_DATA_DIR"
        The output should equal "/tmp/home/.local/share/deckrd"
      End

      It "[Normal] HOME との関係式が成立する"
        When call test "$DECKRD_DATA_DIR" = "${HOME}/.local/share/deckrd"
        The status should equal 0
      End

      It "[Normal] XDG_DATA_HOME が未設定のまま (副作用なし)"
        When call bash -c '[[ -z "${XDG_DATA_HOME+x}" ]] && echo ok'
        The output should equal "ok"
      End
    End

    Describe "Given: DECKRD_DATA_DIR=/tmp/mydata を事前設定"
      Before "export PROJECT_ROOT=/tmp/proj; export DECKRD_DATA_DIR=/tmp/mydata; bootstrap_init"

      It "[Normal] 事前設定値が維持される"
        When call echo "$DECKRD_DATA_DIR"
        The output should equal "/tmp/mydata"
      End
    End

    Describe "Given: XDG_DATA_HOME='' (空文字)、HOME=/tmp/home"
      Before "export PROJECT_ROOT=/tmp/proj; export XDG_DATA_HOME=''; export HOME=/tmp/home; unset DECKRD_DATA_DIR; bootstrap_init"

      It "[Edge] HOME/.local/share/deckrd にフォールバックする"
        When call echo "$DECKRD_DATA_DIR"
        The output should equal "/tmp/home/.local/share/deckrd"
      End
    End

    Describe "Given: XDG_DATA_HOME にスペースを含むパス"
      Before "export PROJECT_ROOT=/tmp/proj; export XDG_DATA_HOME='/tmp/my xdg'; unset DECKRD_DATA_DIR; bootstrap_init"

      It "[Edge] パスが正しく連結される"
        When call echo "$DECKRD_DATA_DIR"
        The output should equal "/tmp/my xdg/deckrd"
      End
    End

    Describe "Given: HOME にスペースを含むパス (XDG未設定)"
      Before "export PROJECT_ROOT=/tmp/proj; unset XDG_DATA_HOME; export HOME='/tmp/my home'; unset DECKRD_DATA_DIR; bootstrap_init"

      It "[Edge] パスが正しく連結される"
        When call echo "$DECKRD_DATA_DIR"
        The output should equal "/tmp/my home/.local/share/deckrd"
      End
    End

    Describe "Given: PROJECT_ROOT=/tmp/other、DECKRD_ROOT=/tmp/deckrd (非依存確認)"
      Before "export PROJECT_ROOT=/tmp/other; export DECKRD_ROOT=/tmp/deckrd; export XDG_DATA_HOME=/tmp/xdg; unset DECKRD_DATA_DIR; bootstrap_init"

      It "[Edge] PROJECT_ROOT/DECKRD_ROOT に依存せず XDG_DATA_HOME が基点になる"
        When call echo "$DECKRD_DATA_DIR"
        The output should equal "/tmp/xdg/deckrd"
      End
    End
  End

  # ------------------------------------------------------------------ #
  #  DECKRD_LOCAL_DATA                                                  #
  #  依存: PROJECT_ROOT のみ (DECKRD_ROOT 非依存)                      #
  # ------------------------------------------------------------------ #
  Describe "DECKRD_LOCAL_DATA"

    Describe "Given: PROJECT_ROOT=/tmp/proj、DECKRD_LOCAL_DATA 未設定"
      Before "export PROJECT_ROOT=/tmp/proj; unset DECKRD_LOCAL_DATA; bootstrap_init"

      It "[Normal] PROJECT_ROOT/.local/deckrd になる"
        When call echo "$DECKRD_LOCAL_DATA"
        The output should equal "/tmp/proj/.local/deckrd"
      End

      It "[Normal] PROJECT_ROOT との関係式が成立する"
        When call test "$DECKRD_LOCAL_DATA" = "${PROJECT_ROOT}/.local/deckrd"
        The status should equal 0
      End

      It "[Normal] export -p で export されている"
        When call bash -c 'export -p | grep -q "^declare -x DECKRD_LOCAL_DATA=" && echo ok'
        The output should equal "ok"
      End
    End

    Describe "Given: DECKRD_LOCAL_DATA=/tmp/localdata を事前設定"
      Before "export PROJECT_ROOT=/tmp/proj; export DECKRD_LOCAL_DATA=/tmp/localdata; bootstrap_init"

      It "[Normal] 事前設定値が維持される"
        When call echo "$DECKRD_LOCAL_DATA"
        The output should equal "/tmp/localdata"
      End
    End

    Describe "Given: PROJECT_ROOT にスペースを含むパス"
      Before "export PROJECT_ROOT='/tmp/my project'; unset DECKRD_LOCAL_DATA; bootstrap_init"

      It "[Edge] パスが正しく連結される"
        When call echo "$DECKRD_LOCAL_DATA"
        The output should equal "/tmp/my project/.local/deckrd"
      End
    End

    Describe "Given: DECKRD_ROOT=/tmp/other を設定 (PROJECT_ROOT から独立)"
      Before "export PROJECT_ROOT=/tmp/proj; export DECKRD_ROOT=/tmp/other; unset DECKRD_LOCAL_DATA; bootstrap_init"

      It "[Edge] DECKRD_ROOT に依存せず PROJECT_ROOT が基点になる"
        When call echo "$DECKRD_LOCAL_DATA"
        The output should equal "/tmp/proj/.local/deckrd"
      End
    End
  End

  # ------------------------------------------------------------------ #
  #  DECKRD_DOCS_DIR                                                    #
  #  依存: PROJECT_ROOT のみ (DECKRD_ROOT 非依存)                      #
  # ------------------------------------------------------------------ #
  Describe "DECKRD_DOCS_DIR"

    Describe "Given: PROJECT_ROOT=/tmp/proj、DECKRD_DOCS_DIR 未設定"
      Before "export PROJECT_ROOT=/tmp/proj; unset DECKRD_DOCS_DIR; bootstrap_init"

      It "[Normal] PROJECT_ROOT/docs/.deckrd になる"
        When call echo "$DECKRD_DOCS_DIR"
        The output should equal "/tmp/proj/docs/.deckrd"
      End

      It "[Normal] PROJECT_ROOT との関係式が成立する"
        When call test "$DECKRD_DOCS_DIR" = "${PROJECT_ROOT}/docs/.deckrd"
        The status should equal 0
      End

      It "[Normal] export -p で export されている"
        When call bash -c 'export -p | grep -q "^declare -x DECKRD_DOCS_DIR=" && echo ok'
        The output should equal "ok"
      End
    End

    Describe "Given: DECKRD_DOCS_DIR=/tmp/docs を事前設定"
      Before "export PROJECT_ROOT=/tmp/proj; export DECKRD_DOCS_DIR=/tmp/docs; bootstrap_init"

      It "[Normal] 事前設定値が維持される"
        When call echo "$DECKRD_DOCS_DIR"
        The output should equal "/tmp/docs"
      End
    End

    Describe "Given: PROJECT_ROOT にスペースを含むパス"
      Before "export PROJECT_ROOT='/tmp/my project'; unset DECKRD_DOCS_DIR; bootstrap_init"

      It "[Edge] パスが正しく連結される"
        When call echo "$DECKRD_DOCS_DIR"
        The output should equal "/tmp/my project/docs/.deckrd"
      End
    End

    Describe "Given: DECKRD_ROOT=/tmp/other を設定 (PROJECT_ROOT から独立)"
      Before "export PROJECT_ROOT=/tmp/proj; export DECKRD_ROOT=/tmp/other; unset DECKRD_DOCS_DIR; bootstrap_init"

      It "[Edge] DECKRD_ROOT に依存せず PROJECT_ROOT が基点になる"
        When call echo "$DECKRD_DOCS_DIR"
        The output should equal "/tmp/proj/docs/.deckrd"
      End
    End
  End

  # ------------------------------------------------------------------ #
  #  SYMBOL — 仕様: ^[a-z][a-z_-]*$ (先頭は小文字のみ)                 #
  # ------------------------------------------------------------------ #
  Describe "SYMBOL"

    Describe "Given: SYMBOL 未設定"
      Before "export PROJECT_ROOT=/tmp/proj; unset SYMBOL; bootstrap_init"

      It "[Normal] デフォルト値 [a-z][a-z_-]* が設定される"
        When call echo "$SYMBOL"
        The output should equal '[a-z][a-z_-]*'
      End

      It "[Normal] 正規表現パターン文字 [ を含む"
        When call bash -c '[[ "$SYMBOL" == *"["* ]] && echo ok'
        The output should equal "ok"
      End

      It "[Normal] export -p で export されている"
        When call bash -c 'export -p | grep -q "^declare -x SYMBOL=" && echo ok'
        The output should equal "ok"
      End

      It "[Normal] 小文字のみ 'abc' にマッチする"
        When call bash -c '[[ "abc" =~ ^'"$SYMBOL"'$ ]] && echo ok'
        The status should equal 0
        The output should equal "ok"
      End

      It "[Normal] 'abc-def_ghi' にマッチする"
        When call bash -c '[[ "abc-def_ghi" =~ ^'"$SYMBOL"'$ ]] && echo ok'
        The status should equal 0
        The output should equal "ok"
      End

      It "[Normal] 大文字 'ABC' にマッチしない"
        When call bash -c '[[ ! "ABC" =~ ^'"$SYMBOL"'$ ]] && echo ok'
        The status should equal 0
        The output should equal "ok"
      End

      It "[Normal] 数字含む 'abc123' にマッチしない"
        When call bash -c '[[ ! "abc123" =~ ^'"$SYMBOL"'$ ]] && echo ok'
        The status should equal 0
        The output should equal "ok"
      End

      It "[Normal] 大文字+数字混在 'Abc-1' にマッチしない"
        When call bash -c '[[ ! "Abc-1" =~ ^'"$SYMBOL"'$ ]] && echo ok'
        The status should equal 0
        The output should equal "ok"
      End

      It "[Edge] 空文字 '' にマッチしない"
        When call bash -c '[[ ! "" =~ ^'"$SYMBOL"'$ ]] && echo ok'
        The status should equal 0
        The output should equal "ok"
      End

      It "[Edge] 先頭ハイフン '-abc' にマッチしない (先頭は小文字のみ)"
        When call bash -c '[[ ! "-abc" =~ ^'"$SYMBOL"'$ ]] && echo ok'
        The status should equal 0
        The output should equal "ok"
      End

      It "[Edge] 先頭アンダースコア '_abc' にマッチしない (先頭は小文字のみ)"
        When call bash -c '[[ ! "_abc" =~ ^'"$SYMBOL"'$ ]] && echo ok'
        The status should equal 0
        The output should equal "ok"
      End

      It "[Edge] 1文字小文字 'a' にマッチする"
        When call bash -c '[[ "a" =~ ^'"$SYMBOL"'$ ]] && echo ok'
        The status should equal 0
        The output should equal "ok"
      End
    End

    Describe "Given: SYMBOL=custom_pattern を事前設定"
      Before "export PROJECT_ROOT=/tmp/proj; export SYMBOL=custom_pattern; bootstrap_init"

      It "[Normal] 事前設定値が維持される"
        When call echo "$SYMBOL"
        The output should equal "custom_pattern"
      End
    End
  End

End
