#!/usr/bin/env bash
# generate-doc-parse-options.unit.spec.sh - ShellSpec tests for the verbose flag in parse_options
#
# Unit test design:
#   - generate-doc.sh は source して使う。main は末尾の
#     [[ "${BASH_SOURCE[0]}" == "$0" ]] ガードの内側なので起動しない。
#     parse_options は source 後にそのまま呼べる。
#   - 検証するのは「--verbose が config ストアの verbose へ配線されているか」だけである。
#     ダンプが実際に抑止されるかはサブプロセス実行を要するため functional 側が見る。
#   - 各ケースは config_init でストアをスキーマ既定値へ戻してから parse_options を呼ぶ。
#     戻さないと前のケースが立てた verbose=1 が次のケースへ漏れ、
#     既定値のケースが「たまたま通る」状態になる。
#   - 既定値のケースとフラグ指定のケースは同一のヘルパーを共有し、
#     違いを転送する引数だけに閉じる。オラクルを 2 本に分けると、
#     片方だけが更新されて静かに乖離する。
#
# Copyright (c) 2026- atsushifx <https://github.com/atsushifx>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

# cspell:words shellspec subcommands

# shellcheck disable=SC1090,SC1091,SC2287

# ============================================================================
# テスト基盤
# ============================================================================

_RUNTIME_BOOTSTRAP="${SHELLSPEC_PROJECT_ROOT}/skills/deckrd/skills/deckrd/scripts/libs/bootstrap.lib.sh"
. "$_RUNTIME_BOOTSTRAP" --no-finalize
unset _RUNTIME_BOOTSTRAP

Include ../spec_helper.sh

# ============================================================================
# テスト対象
# ============================================================================

# shellcheck source=../generate-doc.sh
. "${SUBCOMMANDS_DIR}/generate-doc.sh"

# ============================================================================
# 内部ヘルパー
# ============================================================================

# 定数

# _VERBOSE_ON - --verbose 指定時に config の verbose が取る値
readonly _VERBOSE_ON='1'

# _VERBOSE_OFF - --verbose 未指定時のスキーマ既定値
readonly _VERBOSE_OFF='0'

# 関数

# _parse_and_read_verbose - ストアを既定値へ戻して parse_options を呼び、verbose を読み出す
#
# 前提: generate-doc.sh が source 済みであること (config_init / parse_options /
#       config_get が呼べること)。
# 副作用: config ストアをスキーマ既定値で再初期化する。
#
# @arg $@ string parse_options へそのまま転送する引数列 (省略可)
# @stdout config の verbose の値
# @return config_get の終了ステータス
_parse_and_read_verbose() {
  config_init
  parse_options "$@"
  config_get "verbose"
}

# ============================================================================
# テスト本体
# ============================================================================

# parse_options はコマンドラインオプションを config ストアへ写す。
# verbose フラグは設定ダンプの出力可否だけを決め、他のキーには触れない。
Describe "T-SUB-PO: generate-doc.sh parse_options の verbose フラグ"

  Describe "Given: --verbose を渡さずに parse_options を呼んだ config ストア"
    Describe "When: 正常系"
      It "Then: [Normal] T-SUB-PO-02: 引数なし → verbose はスキーマ既定値 0 のままである"
        When run _parse_and_read_verbose
        The status should equal 0
        The output should equal "$_VERBOSE_OFF"
      End
    End
  End

  Describe "Given: --verbose を渡して parse_options を呼んだ config ストア"
    Describe "When: 正常系"
      It "Then: [Normal] T-SUB-PO-01: --verbose → verbose が 1 になる"
        When run _parse_and_read_verbose --verbose
        The status should equal 0
        The output should equal "$_VERBOSE_ON"
      End
    End
  End
End
