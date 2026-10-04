#!/usr/bin/env bash
# src: ./skills/deckrd/skills/deckrd/scripts/libs/__tests__/integration/bootstrap.lib.integration.spec.sh
# @(#) : ShellSpec integration tests for bootstrap.lib.sh
#        git execution dependency, current-directory fallback, idempotency.
#        Tests rely on real git repository state and external process behavior.
#
# Copyright (c) 2026- aglabo <https://github.com/aglabo>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

# shellcheck disable=SC1091

_RUNTIME_LIBS_DIR="$(cd "${SHELLSPEC_PROJECT_ROOT}/skills/deckrd/skills/deckrd/scripts/libs" && pwd)"

Include "../spec_helper.sh"

SCRIPT="${_RUNTIME_LIBS_DIR}/bootstrap.lib.sh"

# ---- T-LIB-BPRFI test data (internal helpers) ----

# git 管理外の作業ディレクトリ。GIT_CEILING_DIRECTORIES に SHELLSPEC_TMPBASE を
# 渡すので、一時領域がリポジトリの内外どちらにあっても git は失敗する
_BPRFI_NOGIT_DIR="${SHELLSPEC_TMPBASE}/bprfi-nogit"

# スペースを含む git 管理外の作業ディレクトリ (値が分割されないことを確かめる)
_BPRFI_SPACE_DIR="${SHELLSPEC_TMPBASE}/bprfi no git"

# git を除いた PATH で dirname まで消えたときに、dirname へのリンクだけを置く場所
_BPRFI_SHIM_DIR="${SHELLSPEC_TMPBASE}/bprfi-shim"

# _bprfi_setup - Create the working directories used by T-LIB-BPRFI
_bprfi_setup() {
  mkdir -p "${_BPRFI_NOGIT_DIR}" "${_BPRFI_SPACE_DIR}"
}

# _bprfi_path_remove - Print a PATH string with one directory removed
#
# @arg $1 PATH string
# @arg $2 directory to remove (exact match)
_bprfi_path_remove() {
  local _path
  _path="$(printf '%s\n' "$1" | tr ':' '\n' | grep -vxF -- "$2" | tr '\n' ':')"
  printf '%s' "${_path%:}"
}

# _bprfi_path_without_git - Print the current PATH with every git directory removed
#
# Removes directories until `command -v git` fails, so a merged /usr (git in both
# /usr/bin and /bin) is handled. When dirname disappears with them, a shim
# directory holding a link to the original dirname is prepended, because
# bootstrap.lib.sh needs dirname to resolve SKILL_ROOT.
_bprfi_path_without_git() {
  local _path="${PATH}" _next _git _dirname
  _dirname="$(command -v dirname)"
  while _git="$(PATH="${_path}" && command -v git)" && [[ "${_git}" == */* ]]; do
    _next="$(_bprfi_path_remove "${_path}" "${_git%/*}")"
    [[ "${_next}" != "${_path}" ]] || break
    _path="${_next}"
  done
  if ! (PATH="${_path}" && command -v dirname >/dev/null); then
    mkdir -p "${_BPRFI_SHIM_DIR}"
    ln -sf "${_dirname}" "${_BPRFI_SHIM_DIR}/dirname"
    _path="${_BPRFI_SHIM_DIR}:${_path}"
  fi
  printf '%s' "${_path}"
}

# _bprfi_git_reachable - Succeed when git is still found after removing it from PATH
_bprfi_git_reachable() {
  (PATH="$(_bprfi_path_without_git)" && command -v git >/dev/null)
}

Describe "bootstrap.lib.sh"

  # ------------------------------------------------------------------ #
  #  PROJECT_ROOT: git 自動検出                                         #
  # ------------------------------------------------------------------ #
  Describe "T-LIB-BPRGI: PROJECT_ROOT: git 自動検出"

    It "[Normal] T-LIB-BPRGI-01: 未設定 → git rev-parse --show-toplevel と一致する"
      expected="$(git rev-parse --show-toplevel 2>/dev/null)"
      When run bash -c "unset PROJECT_ROOT; . \"$SCRIPT\" && echo \"\$PROJECT_ROOT\""
      The status should equal 0
      The output should equal "$expected"
    End

    It "[Normal] T-LIB-BPRGI-02: 未設定 → PROJECT_ROOT が空でない"
      When run bash -c "unset PROJECT_ROOT; . \"$SCRIPT\" && echo \"\$PROJECT_ROOT\""
      The status should equal 0
      The output should not equal ""
    End

    It "[Normal] T-LIB-BPRGI-03: 未設定 → PROJECT_ROOT が実際のディレクトリである"
      When run bash -c "unset PROJECT_ROOT; . \"$SCRIPT\" && [[ -d \"\$PROJECT_ROOT\" ]] && echo ok"
      The status should equal 0
      The output should equal "ok"
    End

    It "[Edge] T-LIB-BPRGI-04: 空文字設定 → 自動検出で上書きされる"
      When run bash -c "export PROJECT_ROOT=''; . \"$SCRIPT\" && echo \"\$PROJECT_ROOT\""
      The status should equal 0
      The output should not equal ""
    End

    It "[Edge] T-LIB-BPRGI-05: 空文字設定 → 上書き後は実際のディレクトリになる"
      When run bash -c "export PROJECT_ROOT=''; . \"$SCRIPT\" && [[ -d \"\$PROJECT_ROOT\" ]] && echo ok"
      The status should equal 0
      The output should equal "ok"
    End
  End

  # ------------------------------------------------------------------ #
  #  PROJECT_ROOT: カレントディレクトリ fallback (git 使用不可)        #
  # ------------------------------------------------------------------ #
  Describe "T-LIB-BPRFI: PROJECT_ROOT: カレントディレクトリ fallback"

    BeforeAll '_bprfi_setup'

    It "[Normal] T-LIB-BPRFI-01: git 管理外のディレクトリ → PROJECT_ROOT はカレントディレクトリ"
      When run bash -c "
        cd \"${_BPRFI_NOGIT_DIR}\" || exit 1
        export GIT_CEILING_DIRECTORIES=\"${SHELLSPEC_TMPBASE}\"
        unset PROJECT_ROOT
        . \"$SCRIPT\" && [[ \"\$PROJECT_ROOT\" == \"\$(pwd)\" ]] && echo ok
      "
      The status should equal 0
      The output should equal "ok"
    End

    It "[Normal] T-LIB-BPRFI-02: git が PATH にない → PROJECT_ROOT はカレントディレクトリ"
      Skip if "git を PATH から除けない" _bprfi_git_reachable
      nogit_path="$(_bprfi_path_without_git)"
      When run bash -c "
        export PATH=\"${nogit_path}\"
        cd \"${SHELLSPEC_PROJECT_ROOT}/skills/deckrd\" || exit 1
        unset PROJECT_ROOT
        . \"$SCRIPT\" && [[ \"\$PROJECT_ROOT\" == \"\$(pwd)\" ]] && echo ok
      "
      The status should equal 0
      The output should equal "ok"
    End

    It "[Error] T-LIB-BPRFI-03: git 管理外 → git のエラーを出さず status 0"
      When run bash -c "
        cd \"${_BPRFI_NOGIT_DIR}\" || exit 1
        export GIT_CEILING_DIRECTORIES=\"${SHELLSPEC_TMPBASE}\"
        unset PROJECT_ROOT
        . \"$SCRIPT\"
      "
      The status should equal 0
      The stderr should equal ""
    End

    It "[Edge] T-LIB-BPRFI-04: スペースを含む git 管理外ディレクトリ → PROJECT_ROOT はそのパス"
      When run bash -c "
        cd \"${_BPRFI_SPACE_DIR}\" || exit 1
        export GIT_CEILING_DIRECTORIES=\"${SHELLSPEC_TMPBASE}\"
        unset PROJECT_ROOT
        . \"$SCRIPT\" && [[ \"\$PROJECT_ROOT\" == \"\$(pwd)\" ]] && echo ok
      "
      The status should equal 0
      The output should equal "ok"
    End

    It "[Edge] T-LIB-BPRFI-05: git 管理外で PROJECT_ROOT が空文字 → カレントディレクトリで上書き"
      When run bash -c "
        cd \"${_BPRFI_NOGIT_DIR}\" || exit 1
        export GIT_CEILING_DIRECTORIES=\"${SHELLSPEC_TMPBASE}\"
        export PROJECT_ROOT=''
        . \"$SCRIPT\" && [[ \"\$PROJECT_ROOT\" == \"\$(pwd)\" ]] && echo ok
      "
      The status should equal 0
      The output should equal "ok"
    End
  End

  # ------------------------------------------------------------------ #
  #  冪等性: 2回 source                                                 #
  # ------------------------------------------------------------------ #
  Describe "T-LIB-BIDM2I: 冪等性: 2回 source"

    It "[Normal] T-LIB-BIDM2I-01: 2回 source → PROJECT_ROOT が変化しない"
      When run bash -c ". \"$SCRIPT\" && FIRST=\"\$PROJECT_ROOT\" && . \"$SCRIPT\" && [[ \"\$PROJECT_ROOT\" == \"\$FIRST\" ]] && echo ok"
      The status should equal 0
      The output should equal "ok"
    End

    It "[Normal] T-LIB-BIDM2I-02: 2回 source → DECKRD_ROOT が変化しない"
      When run bash -c ". \"$SCRIPT\" && FIRST=\"\$DECKRD_ROOT\" && . \"$SCRIPT\" && [[ \"\$DECKRD_ROOT\" == \"\$FIRST\" ]] && echo ok"
      The status should equal 0
      The output should equal "ok"
    End

    It "[Normal] T-LIB-BIDM2I-03: 2回 source → DECKRD_SCRIPTS_DIR が変化しない"
      When run bash -c ". \"$SCRIPT\" && FIRST=\"\$DECKRD_SCRIPTS_DIR\" && . \"$SCRIPT\" && [[ \"\$DECKRD_SCRIPTS_DIR\" == \"\$FIRST\" ]] && echo ok"
      The status should equal 0
      The output should equal "ok"
    End

    It "[Normal] T-LIB-BIDM2I-04: 2回 source → DECKRD_LIB_DIR が変化しない"
      When run bash -c ". \"$SCRIPT\" && FIRST=\"\$DECKRD_LIB_DIR\" && . \"$SCRIPT\" && [[ \"\$DECKRD_LIB_DIR\" == \"\$FIRST\" ]] && echo ok"
      The status should equal 0
      The output should equal "ok"
    End

    It "[Normal] T-LIB-BIDM2I-05: 2回 source → DECKRD_DATA_DIR が変化しない"
      When run bash -c ". \"$SCRIPT\" && FIRST=\"\$DECKRD_DATA_DIR\" && . \"$SCRIPT\" && [[ \"\$DECKRD_DATA_DIR\" == \"\$FIRST\" ]] && echo ok"
      The status should equal 0
      The output should equal "ok"
    End

    It "[Normal] T-LIB-BIDM2I-06: 2回 source → DECKRD_LOCAL_DATA が変化しない"
      When run bash -c ". \"$SCRIPT\" && FIRST=\"\$DECKRD_LOCAL_DATA\" && . \"$SCRIPT\" && [[ \"\$DECKRD_LOCAL_DATA\" == \"\$FIRST\" ]] && echo ok"
      The status should equal 0
      The output should equal "ok"
    End

    It "[Normal] T-LIB-BIDM2I-07: 2回 source → DECKRD_DOCS_DIR が変化しない"
      When run bash -c ". \"$SCRIPT\" && FIRST=\"\$DECKRD_DOCS_DIR\" && . \"$SCRIPT\" && [[ \"\$DECKRD_DOCS_DIR\" == \"\$FIRST\" ]] && echo ok"
      The status should equal 0
      The output should equal "ok"
    End

    It "[Normal] T-LIB-BIDM2I-08: 2回 source → SYMBOL が変化しない"
      When run bash -c ". \"$SCRIPT\" && FIRST=\"\$SYMBOL\" && . \"$SCRIPT\" && [[ \"\$SYMBOL\" == \"\$FIRST\" ]] && echo ok"
      The status should equal 0
      The output should equal "ok"
    End

    It "[Normal] T-LIB-BIDM2I-09: 2回 source → _BOOTSTRAP_LOADED が変化しない"
      When run bash -c ". \"$SCRIPT\" && FIRST=\"\$_BOOTSTRAP_LOADED\" && . \"$SCRIPT\" && [[ \"\$_BOOTSTRAP_LOADED\" == \"\$FIRST\" ]] && echo ok"
      The status should equal 0
      The output should equal "ok"
    End
  End

  # ------------------------------------------------------------------ #
  #  冪等性: 3回 source                                                 #
  # ------------------------------------------------------------------ #
  Describe "T-LIB-BIDM3I: 冪等性: 3回 source"

    It "[Edge] T-LIB-BIDM3I-01: 3回 source → DECKRD_ROOT が変化しない"
      When run bash -c ". \"$SCRIPT\" && FIRST=\"\$DECKRD_ROOT\" && . \"$SCRIPT\" && . \"$SCRIPT\" && [[ \"\$DECKRD_ROOT\" == \"\$FIRST\" ]] && echo ok"
      The status should equal 0
      The output should equal "ok"
    End

    It "[Edge] T-LIB-BIDM3I-02: 3回 source → PROJECT_ROOT が変化しない"
      When run bash -c ". \"$SCRIPT\" && FIRST=\"\$PROJECT_ROOT\" && . \"$SCRIPT\" && . \"$SCRIPT\" && [[ \"\$PROJECT_ROOT\" == \"\$FIRST\" ]] && echo ok"
      The status should equal 0
      The output should equal "ok"
    End

    It "[Edge] T-LIB-BIDM3I-03: 3回 source → ステータス 0 で終了する"
      When run bash -c ". \"$SCRIPT\" && . \"$SCRIPT\" && . \"$SCRIPT\" && echo ok"
      The status should equal 0
      The output should equal "ok"
    End
  End

End
