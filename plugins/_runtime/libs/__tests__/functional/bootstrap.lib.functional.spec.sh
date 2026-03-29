#!/usr/bin/env bash
# src: ./plugins/_runtime/libs/__tests__/functional/bootstrap.lib.functional.spec.sh
# @(#) : ShellSpec functional tests for bootstrap.lib.sh
#        Multi-variable chain verification, deckrd-coder detection, side effects.
#        Each section covers one functional concern with Normal/Edge cases.
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
  #  PROJECT_ROOT: 事前設定の維持                                        #
  # ------------------------------------------------------------------ #
  Describe "PROJECT_ROOT: 事前設定維持"

    It "[Normal] 事前設定値が維持される"
      When run bash -c "export PROJECT_ROOT=/tmp; . \"$SCRIPT\" && echo \"\$PROJECT_ROOT\""
      The status should equal 0
      The output should equal "/tmp"
    End

    It "[Normal] export 済みなので readonly になっている"
      When run bash -c "export PROJECT_ROOT=/tmp; . \"$SCRIPT\" && ( PROJECT_ROOT=x ) 2>/dev/null && echo writable || echo readonly"
      The status should equal 0
      The output should equal "readonly"
    End

    It "[Edge] スペースを含むパスが維持される"
      When run bash -c "export PROJECT_ROOT='/tmp/my project'; . \"$SCRIPT\" && echo \"\$PROJECT_ROOT\""
      The status should equal 0
      The output should equal "/tmp/my project"
    End
  End

  # ------------------------------------------------------------------ #
  #  DECKRD_ROOT ← PROJECT_ROOT 連鎖                                   #
  # ------------------------------------------------------------------ #
  Describe "DECKRD_ROOT: PROJECT_ROOT 連鎖"

    It "[Normal] PROJECT_ROOT 変更 → DECKRD_ROOT が追従する"
      root_a=$(bash -c "export PROJECT_ROOT=/tmp/a; unset DECKRD_ROOT; . \"$SCRIPT\" && echo \"\$DECKRD_ROOT\"")
      root_b=$(bash -c "export PROJECT_ROOT=/tmp/b; unset DECKRD_ROOT; . \"$SCRIPT\" && echo \"\$DECKRD_ROOT\"")
      When call test "$root_a" != "$root_b" \
        -a "$root_a" = "/tmp/a/plugins/deckrd/skills/deckrd" \
        -a "$root_b" = "/tmp/b/plugins/deckrd/skills/deckrd"
      The status should equal 0
    End

    It "[Normal] DECKRD_ROOT を固定すると PROJECT_ROOT 変更に影響されない"
      root_a=$(bash -c "export DECKRD_ROOT=/tmp/fixed; export PROJECT_ROOT=/tmp/a; . \"$SCRIPT\" && echo \"\$DECKRD_ROOT\"")
      root_b=$(bash -c "export DECKRD_ROOT=/tmp/fixed; export PROJECT_ROOT=/tmp/b; . \"$SCRIPT\" && echo \"\$DECKRD_ROOT\"")
      When call test "$root_a" = "/tmp/fixed" -a "$root_b" = "/tmp/fixed"
      The status should equal 0
    End

    It "[Normal] PROJECT_ROOT 設定 → DECKRD_ROOT と PROJECT_ROOT の関係式が成立する"
      When run bash -c "export PROJECT_ROOT=/tmp/proj; unset DECKRD_ROOT; . \"$SCRIPT\" && [[ \"\$DECKRD_ROOT\" == \"\${PROJECT_ROOT}/plugins/deckrd/skills/deckrd\" ]] && echo ok"
      The status should equal 0
      The output should equal "ok"
    End
  End

  # ------------------------------------------------------------------ #
  #  DECKRD_ROOT 起点の連鎖 (SCRIPTS/LIB)                              #
  # ------------------------------------------------------------------ #
  Describe "DECKRD_SCRIPTS_DIR / DECKRD_LIB_DIR: DECKRD_ROOT 連鎖"

    It "[Normal] DECKRD_SCRIPTS_DIR が DECKRD_ROOT/scripts との関係式を満たす"
      When run bash -c "export DECKRD_ROOT=/tmp/deckrd; unset DECKRD_SCRIPTS_DIR; . \"$SCRIPT\" && [[ \"\$DECKRD_SCRIPTS_DIR\" == \"\${DECKRD_ROOT}/scripts\" ]] && echo ok"
      The status should equal 0
      The output should equal "ok"
    End

    It "[Normal] DECKRD_LIB_DIR が DECKRD_ROOT/scripts/libs との関係式を満たす"
      When run bash -c "export DECKRD_ROOT=/tmp/deckrd; unset DECKRD_LIB_DIR; . \"$SCRIPT\" && [[ \"\$DECKRD_LIB_DIR\" == \"\${DECKRD_ROOT}/scripts/libs\" ]] && echo ok"
      The status should equal 0
      The output should equal "ok"
    End

    It "[Normal] DECKRD_ROOT 変更 → DECKRD_SCRIPTS_DIR が追従する"
      scripts_a=$(bash -c "export DECKRD_ROOT=/tmp/a; unset DECKRD_SCRIPTS_DIR; . \"$SCRIPT\" && echo \"\$DECKRD_SCRIPTS_DIR\"")
      scripts_b=$(bash -c "export DECKRD_ROOT=/tmp/b; unset DECKRD_SCRIPTS_DIR; . \"$SCRIPT\" && echo \"\$DECKRD_SCRIPTS_DIR\"")
      When call test "$scripts_a" = "/tmp/a/scripts" -a "$scripts_b" = "/tmp/b/scripts"
      The status should equal 0
    End

    It "[Edge] DECKRD_ROOT を固定しても DECKRD_SCRIPTS_DIR は DECKRD_ROOT に従う"
      When run bash -c "export DECKRD_ROOT=/tmp/fixed; unset DECKRD_SCRIPTS_DIR; . \"$SCRIPT\" && echo \"\$DECKRD_SCRIPTS_DIR\""
      The status should equal 0
      The output should equal "/tmp/fixed/scripts"
    End
  End

  # ------------------------------------------------------------------ #
  #  PROJECT_ROOT 起点の連鎖 (LOCAL_DATA/DOCS)                         #
  # ------------------------------------------------------------------ #
  Describe "DECKRD_LOCAL_DATA / DECKRD_DOCS_DIR: PROJECT_ROOT 連鎖"

    It "[Normal] DECKRD_LOCAL_DATA が PROJECT_ROOT/.local/deckrd との関係式を満たす"
      When run bash -c "export PROJECT_ROOT=/tmp/proj; unset DECKRD_LOCAL_DATA; . \"$SCRIPT\" && [[ \"\$DECKRD_LOCAL_DATA\" == \"\${PROJECT_ROOT}/.local/deckrd\" ]] && echo ok"
      The status should equal 0
      The output should equal "ok"
    End

    It "[Normal] DECKRD_DOCS_DIR が PROJECT_ROOT/docs/.deckrd との関係式を満たす"
      When run bash -c "export PROJECT_ROOT=/tmp/proj; unset DECKRD_DOCS_DIR; . \"$SCRIPT\" && [[ \"\$DECKRD_DOCS_DIR\" == \"\${PROJECT_ROOT}/docs/.deckrd\" ]] && echo ok"
      The status should equal 0
      The output should equal "ok"
    End

    It "[Normal] DECKRD_LOCAL_DATA は DECKRD_ROOT に依らず PROJECT_ROOT に依存する"
      local_a=$(bash -c "export PROJECT_ROOT=/tmp/p; export DECKRD_ROOT=/tmp/d; unset DECKRD_LOCAL_DATA; . \"$SCRIPT\" && echo \"\$DECKRD_LOCAL_DATA\"")
      When call test "$local_a" = "/tmp/p/.local/deckrd"
      The status should equal 0
    End

    It "[Normal] DECKRD_DOCS_DIR は DECKRD_ROOT に依らず PROJECT_ROOT に依存する"
      docs_a=$(bash -c "export PROJECT_ROOT=/tmp/p; export DECKRD_ROOT=/tmp/d; unset DECKRD_DOCS_DIR; . \"$SCRIPT\" && echo \"\$DECKRD_DOCS_DIR\"")
      When call test "$docs_a" = "/tmp/p/docs/.deckrd"
      The status should equal 0
    End
  End

  # ------------------------------------------------------------------ #
  #  deckrd-coder パス検出                                              #
  # ------------------------------------------------------------------ #
  Describe "deckrd-coder パス検出"
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

    It "[Normal] deckrd-coder パスでも DECKRD_LOCAL_DATA は PROJECT_ROOT 起点になる"
      When call run_coder_tmpscript DECKRD_LOCAL_DATA "PROJECT_ROOT=/tmp/proj"
      The status should equal 0
      The output should equal "/tmp/proj/.local/deckrd"
    End

    It "[Normal] deckrd-coder パスでも DECKRD_DOCS_DIR は PROJECT_ROOT 起点になる"
      When call run_coder_tmpscript DECKRD_DOCS_DIR "PROJECT_ROOT=/tmp/proj"
      The status should equal 0
      The output should equal "/tmp/proj/docs/.deckrd"
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
  #  副作用: 内部変数                                                   #
  # ------------------------------------------------------------------ #
  Describe "副作用: 内部変数"

    It "[Normal] _caller_path が source 後に外部に漏れていない (ローカル変数)"
      When run bash -c ". \"$SCRIPT\" && [[ -z \"\${_caller_path+x}\" ]] && echo ok"
      The status should equal 0
      The output should equal "ok"
    End

    It "[Normal] _BOOTSTRAP_LOADED が設定される"
      When run bash -c ". \"$SCRIPT\" && [[ -n \"\${_BOOTSTRAP_LOADED+x}\" ]] && echo ok"
      The status should equal 0
      The output should equal "ok"
    End

    It "[Normal] 公開変数 9 つが全て export されている"
      When run bash -c "
        . \"$SCRIPT\"
        expected='PROJECT_ROOT RUNTIME_LIB_DIR DECKRD_ROOT DECKRD_SCRIPTS_DIR DECKRD_LIB_DIR DECKRD_DATA_DIR DECKRD_LOCAL_DATA DECKRD_DOCS_DIR SYMBOL'
        for var in \$expected; do
          [[ -n \"\${!var+x}\" ]] || { echo \"missing: \$var\"; exit 1; }
        done
        echo ok
      "
      The status should equal 0
      The output should equal "ok"
    End

    It "[Normal] PROJECT_ROOT〜DECKRD_DOCS_DIR の 8 変数が全て readonly になっている"
      When run bash -c "
        . \"$SCRIPT\"
        readonly_vars='PROJECT_ROOT RUNTIME_LIB_DIR DECKRD_ROOT DECKRD_SCRIPTS_DIR DECKRD_LIB_DIR DECKRD_DATA_DIR DECKRD_LOCAL_DATA DECKRD_DOCS_DIR'
        for var in \$readonly_vars; do
          ( eval \"\$var=x\" ) 2>/dev/null && { echo \"not readonly: \$var\"; exit 1; }
        done
        echo ok
      "
      The status should equal 0
      The output should equal "ok"
    End
  End

  # ------------------------------------------------------------------ #
  #  副作用: シェル環境変数                                             #
  # ------------------------------------------------------------------ #
  Describe "副作用: シェル環境変数"

    It "[Normal] PATH が変化しない"
      When run bash -c "before=\"\$PATH\"; . \"$SCRIPT\"; [[ \"\$PATH\" == \"\$before\" ]] && echo ok"
      The status should equal 0
      The output should equal "ok"
    End

    It "[Normal] IFS が変化しない"
      When run bash -c "before=\"\${IFS}\"; . \"$SCRIPT\"; [[ \"\${IFS}\" == \"\$before\" ]] && echo ok"
      The status should equal 0
      The output should equal "ok"
    End

    It "[Normal] PWD が変化しない"
      When run bash -c "before=\"\$PWD\"; . \"$SCRIPT\"; [[ \"\$PWD\" == \"\$before\" ]] && echo ok"
      The status should equal 0
      The output should equal "ok"
    End

    It "[Edge] OLDPWD が変化しない"
      When run bash -c "before=\"\${OLDPWD:-}\"; . \"$SCRIPT\"; [[ \"\${OLDPWD:-}\" == \"\$before\" ]] && echo ok"
      The status should equal 0
      The output should equal "ok"
    End
  End

End
