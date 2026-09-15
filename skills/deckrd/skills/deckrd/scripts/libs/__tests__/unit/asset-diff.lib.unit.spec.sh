#!/usr/bin/env bash
# asset-diff.lib.unit.spec.sh - ShellSpec tests for asset-diff.lib.sh
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

SCRIPT="${DECKRD_LIB_DIR}/asset-diff.lib.sh"
. "$SCRIPT"

Describe "asset-diff.lib.sh"
  Describe "asset_dest_name"
    Describe "Given: アセットのソースファイルパス"
      Describe "When: asset_dest_name を呼ぶ"
        Parameters
          "/a/foo.md" "foo.md"
          "/a/.gitignore.org" ".gitignore"
          "/a/bar.md.org" "bar.md"
        End

        It "Then: [Normal] T-LIB-ASDF-01: $1 の配置先名は $2"
          When call asset_dest_name "$1"
          The status should equal 0
          The output should equal "$2"
        End
      End
    End
  End

  Describe "asset_src_path"
    Before "setup_tmpdir"
    After "teardown_tmpdir"

    Describe "Given: ソースディレクトリに通常名のファイルだけが存在する"
      setup_plain() {
        touch "${NAMING_TMPDIR}/foo.md"
      }
      Before "setup_plain"

      Describe "When: asset_src_path を呼ぶ"
        It "Then: [Normal] T-LIB-ASDF-12: 通常名のパスを出力する"
          When call asset_src_path "$NAMING_TMPDIR" "foo.md"
          The status should equal 0
          The output should equal "${NAMING_TMPDIR}/foo.md"
        End
      End
    End

    Describe "Given: ソースディレクトリに .org 付きのファイルだけが存在する"
      setup_org_only() {
        touch "${NAMING_TMPDIR}/.gitignore.org"
      }
      Before "setup_org_only"

      Describe "When: asset_src_path を呼ぶ"
        It "Then: [Normal] T-LIB-ASDF-13: .org 付きパスを出力する"
          When call asset_src_path "$NAMING_TMPDIR" ".gitignore"
          The status should equal 0
          The output should equal "${NAMING_TMPDIR}/.gitignore.org"
        End
      End
    End

    Describe "Given: ソースディレクトリが存在しない"
      Describe "When: asset_src_path を呼ぶ"
        It "Then: [Error] T-LIB-ASDF-14: .org 付きパスを出力し status 0 で終わる"
          When call asset_src_path "${NAMING_TMPDIR}/no-such-src" "foo.md"
          The status should equal 0
          The output should equal "${NAMING_TMPDIR}/no-such-src/foo.md.org"
        End
      End
    End

    Describe "Given: ソースディレクトリに通常名と .org 付きの両方のファイルが存在する"
      setup_both() {
        touch "${NAMING_TMPDIR}/foo.md" "${NAMING_TMPDIR}/foo.md.org"
      }
      Before "setup_both"

      Describe "When: asset_src_path を呼ぶ"
        It "Then: [Edge] T-LIB-ASDF-15: 通常名のパスを優先して出力する"
          When call asset_src_path "$NAMING_TMPDIR" "foo.md"
          The status should equal 0
          The output should equal "${NAMING_TMPDIR}/foo.md"
        End
      End
    End

    Describe "Given: ソースディレクトリが空"
      Describe "When: asset_src_path を呼ぶ"
        It "Then: [Edge] T-LIB-ASDF-16: .org 付きパスを出力する"
          When call asset_src_path "$NAMING_TMPDIR" "bar.md"
          The status should equal 0
          The output should equal "${NAMING_TMPDIR}/bar.md.org"
        End
      End
    End
  End

  Describe "list_updated_assets"
    Before "setup_tmpdir"
    After "teardown_tmpdir"

    # Helper: write <content> to <dir>/<name>, creating <dir>
    put_file() {
      mkdir -p "$1"
      printf '%s\n' "$3" >"$1/$2"
    }

    # Helper: set an old mtime on <file> so the other side counts as newer
    make_old() {
      touch -d '2000-01-01 00:00:00' "$1"
    }

    Describe "Given: 配置先に内容の異なるファイルと同一のファイルが混在する"
      setup_mixed() {
        put_file "${NAMING_TMPDIR}/src" "changed.md" "new"
        put_file "${NAMING_TMPDIR}/dest" "changed.md" "old"
        make_old "${NAMING_TMPDIR}/dest/changed.md"
        put_file "${NAMING_TMPDIR}/src" "same.md" "same"
        put_file "${NAMING_TMPDIR}/dest" "same.md" "same"
      }
      Before "setup_mixed"

      Describe "When: list_updated_assets を呼ぶ"
        It "Then: [Normal] T-LIB-ASDF-04: 差分のあるファイル名だけを出力する"
          When call list_updated_assets "${NAMING_TMPDIR}/src" "${NAMING_TMPDIR}/dest"
          The status should equal 0
          The output should equal "changed.md"
        End
      End
    End

    Describe "Given: 配置先のファイルがすべてソースと同一"
      setup_identical() {
        put_file "${NAMING_TMPDIR}/src" "a.md" "a"
        put_file "${NAMING_TMPDIR}/dest" "a.md" "a"
        put_file "${NAMING_TMPDIR}/src" "b.md" "b"
        put_file "${NAMING_TMPDIR}/dest" "b.md" "b"
      }
      Before "setup_identical"

      Describe "When: list_updated_assets を呼ぶ"
        It "Then: [Edge] T-LIB-ASDF-05: 何も出力しない"
          When call list_updated_assets "${NAMING_TMPDIR}/src" "${NAMING_TMPDIR}/dest"
          The status should equal 0
          The output should equal ""
        End
      End
    End

    Describe "Given: 配置先にファイルが存在しない"
      setup_missing_dest() {
        put_file "${NAMING_TMPDIR}/src" "a.md" "a"
        mkdir -p "${NAMING_TMPDIR}/dest"
      }
      Before "setup_missing_dest"

      Describe "When: list_updated_assets を呼ぶ"
        It "Then: [Edge] T-LIB-ASDF-06: 何も出力しない"
          When call list_updated_assets "${NAMING_TMPDIR}/src" "${NAMING_TMPDIR}/dest"
          The status should equal 0
          The output should equal ""
        End
      End
    End

    Describe "Given: .org 付きソースと内容の異なる dotfile が配置先にある"
      setup_dotfile() {
        put_file "${NAMING_TMPDIR}/src" ".gitignore.org" "new"
        put_file "${NAMING_TMPDIR}/dest" ".gitignore" "old"
        make_old "${NAMING_TMPDIR}/dest/.gitignore"
      }
      Before "setup_dotfile"

      Describe "When: list_updated_assets を呼ぶ"
        It "Then: [Edge] T-LIB-ASDF-07: .gitignore は除外され何も出力しない"
          When call list_updated_assets "${NAMING_TMPDIR}/src" "${NAMING_TMPDIR}/dest"
          The status should equal 0
          The output should equal ""
        End
      End
    End

    Describe "Given: 配置先のファイルがソースより新しく内容が異なる（ユーザー編集）"
      setup_user_edited() {
        put_file "${NAMING_TMPDIR}/src" "edited.md" "upstream"
        put_file "${NAMING_TMPDIR}/dest" "edited.md" "user edit"
        make_old "${NAMING_TMPDIR}/src/edited.md"
      }
      Before "setup_user_edited"

      Describe "When: list_updated_assets を呼ぶ"
        It "Then: [Edge] T-LIB-ASDF-09: 何も出力しない"
          When call list_updated_assets "${NAMING_TMPDIR}/src" "${NAMING_TMPDIR}/dest"
          The status should equal 0
          The output should equal ""
        End
      End
    End

    Describe "Given: ソースの方が新しいが内容は配置先と同一"
      setup_newer_identical() {
        put_file "${NAMING_TMPDIR}/src" "a.md" "a"
        put_file "${NAMING_TMPDIR}/dest" "a.md" "a"
        make_old "${NAMING_TMPDIR}/dest/a.md"
      }
      Before "setup_newer_identical"

      Describe "When: list_updated_assets を呼ぶ"
        It "Then: [Edge] T-LIB-ASDF-10: 何も出力しない"
          When call list_updated_assets "${NAMING_TMPDIR}/src" "${NAMING_TMPDIR}/dest"
          The status should equal 0
          The output should equal ""
        End
      End
    End

    Describe "Given: ソースディレクトリ内にサブディレクトリがあり配置先に同名ファイルがある"
      setup_subdir() {
        mkdir -p "${NAMING_TMPDIR}/src/sub"
        put_file "${NAMING_TMPDIR}/dest" "sub" "file"
        make_old "${NAMING_TMPDIR}/dest/sub"
      }
      Before "setup_subdir"

      Describe "When: list_updated_assets を呼ぶ"
        It "Then: [Edge] T-LIB-ASDF-11: サブディレクトリは対象外で何も出力しない"
          When call list_updated_assets "${NAMING_TMPDIR}/src" "${NAMING_TMPDIR}/dest"
          The status should equal 0
          The output should equal ""
        End
      End
    End

    Describe "Given: .org 付きソースと内容の異なる通常ファイルが配置先にある"
      setup_org_regular() {
        put_file "${NAMING_TMPDIR}/src" "foo.md.org" "new"
        put_file "${NAMING_TMPDIR}/dest" "foo.md" "old"
        make_old "${NAMING_TMPDIR}/dest/foo.md"
      }
      Before "setup_org_regular"

      Describe "When: list_updated_assets を呼ぶ"
        It "Then: [Normal] T-LIB-ASDF-23: .org を除いた配置先名を出力する"
          When call list_updated_assets "${NAMING_TMPDIR}/src" "${NAMING_TMPDIR}/dest"
          The status should equal 0
          The output should equal "foo.md"
        End
      End
    End

    Describe "Given: 通常名の .gitignore ソースと内容の異なる .gitignore が配置先にある"
      setup_plain_gitignore() {
        put_file "${NAMING_TMPDIR}/src" ".gitignore" "new"
        put_file "${NAMING_TMPDIR}/dest" ".gitignore" "old"
        make_old "${NAMING_TMPDIR}/dest/.gitignore"
      }
      Before "setup_plain_gitignore"

      Describe "When: list_updated_assets を呼ぶ"
        It "Then: [Edge] T-LIB-ASDF-24: 配置先名で除外され何も出力しない"
          When call list_updated_assets "${NAMING_TMPDIR}/src" "${NAMING_TMPDIR}/dest"
          The status should equal 0
          The output should equal ""
        End
      End
    End

    Describe "Given: ソースディレクトリが存在しない"
      Describe "When: list_updated_assets を呼ぶ"
        It "Then: [Error] T-LIB-ASDF-08: 何も出力せず status 0 で終わる"
          When call list_updated_assets "${NAMING_TMPDIR}/no-such-src" "${NAMING_TMPDIR}/dest"
          The status should equal 0
          The output should equal ""
        End
      End
    End
  End
  Describe "init_asset_dirs"
    # Helper: clear asset variables so each case starts from an unset state
    unset_asset_vars() {
      unset INITS_DIR RULES_SRC_DIR RULES_INDEX_SRC_DIR CLAUDE_RULES_SRC_DIR DOCS_SRC_DIR \
        LOCAL_SRC_DIR DECKRD_RULES_DIR CLAUDE_RULES_DIR CLAUDE_RULES_INDEX_DIR ASSET_TARGETS
    }
    Before "unset_asset_vars"

    Describe "Given: asset 系変数が未設定"
      Describe "When: init_asset_dirs を呼ぶ"
        It "Then: [Normal] T-LIB-ASDF-17: ASSET_TARGETS が 5 件で規定順に並ぶ"
          When call init_asset_dirs
          The status should equal 0
          The value "${#ASSET_TARGETS[@]}" should equal 5
          The value "${ASSET_TARGETS[0]}" should equal "deckrd-rules|${RULES_SRC_DIR}|${DECKRD_RULES_DIR}"
          The value "${ASSET_TARGETS[1]}" should equal "claude-rules|${CLAUDE_RULES_SRC_DIR}|${CLAUDE_RULES_DIR}"
          The value "${ASSET_TARGETS[2]}" should equal "deckrd-rules-index|${RULES_INDEX_SRC_DIR}|${CLAUDE_RULES_INDEX_DIR}"
          The value "${ASSET_TARGETS[3]}" should equal "docs|${DOCS_SRC_DIR}|${DECKRD_DOCS_DIR}"
          The value "${ASSET_TARGETS[4]}" should equal "local-deckrd|${LOCAL_SRC_DIR}|${DECKRD_LOCAL_DATA}"
        End

        It "Then: [Normal] T-LIB-ASDF-18: 既定値が設定される"
          When call init_asset_dirs
          The status should equal 0
          The variable RULES_SRC_DIR should equal "${DECKRD_ROOT}/assets/inits/deckrd-rules"
          The variable DECKRD_RULES_DIR should equal "${DECKRD_DOCS_DIR}/rules"
          The variable CLAUDE_RULES_DIR should equal "${PROJECT_ROOT}/.claude/rules/claude-rules"
          The variable CLAUDE_RULES_INDEX_DIR should equal "${PROJECT_ROOT}/.claude/rules/deckrd-rules"
          The value "${ASSET_TARGETS[0]}" should equal "deckrd-rules|${DECKRD_ROOT}/assets/inits/deckrd-rules|${DECKRD_DOCS_DIR}/rules"
        End
      End
    End

    Describe "Given: RULES_SRC_DIR と DECKRD_RULES_DIR が事前設定されている"
      preset_rules_dirs() {
        RULES_SRC_DIR="/tmp/src/rules"
        DECKRD_RULES_DIR="/tmp/dst/rules"
      }
      Before "preset_rules_dirs"

      Describe "When: init_asset_dirs を呼ぶ"
        It "Then: [Normal] T-LIB-ASDF-19: 事前設定値が ASSET_TARGETS に反映される"
          When call init_asset_dirs
          The status should equal 0
          The value "${ASSET_TARGETS[0]}" should equal "deckrd-rules|/tmp/src/rules|/tmp/dst/rules"
        End
      End
    End

    Describe "Given: RULES_SRC_DIR が空文字で設定されている"
      preset_empty_rules_src() {
        RULES_SRC_DIR=""
      }
      Before "preset_empty_rules_src"

      Describe "When: init_asset_dirs を呼ぶ"
        It "Then: [Error] T-LIB-ASDF-20: 空文字の変数は既定値になる"
          When call init_asset_dirs
          The status should equal 0
          The variable RULES_SRC_DIR should equal "${DECKRD_ROOT}/assets/inits/deckrd-rules"
        End
      End
    End

    Describe "Given: INITS_DIR のみ事前設定されている"
      preset_inits_dir() {
        # shellcheck disable=SC2034  # read by init_asset_dirs
        INITS_DIR="/tmp/inits"
      }
      Before "preset_inits_dir"

      Describe "When: init_asset_dirs を呼ぶ"
        It "Then: [Edge] T-LIB-ASDF-21: 各ソースディレクトリが INITS_DIR 配下になる"
          When call init_asset_dirs
          The status should equal 0
          The value "${ASSET_TARGETS[3]}" should equal "docs|/tmp/inits/docs|${DECKRD_DOCS_DIR}"
          The variable LOCAL_SRC_DIR should equal "/tmp/inits/local-deckrd"
        End
      End
    End

    Describe "Given: init_asset_dirs を一度呼んだ後"
      Before "init_asset_dirs"

      Describe "When: init_asset_dirs を再度呼ぶ"
        It "Then: [Edge] T-LIB-ASDF-22: 再呼び出しでも ASSET_TARGETS は 5 件のまま"
          When call init_asset_dirs
          The status should equal 0
          The value "${#ASSET_TARGETS[@]}" should equal 5
        End
      End
    End
  End
End
