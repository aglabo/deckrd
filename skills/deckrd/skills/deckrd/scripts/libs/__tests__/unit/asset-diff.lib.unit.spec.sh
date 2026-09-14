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
          "T-LIB-ASDF-01" "/a/foo.md" "foo.md"
          "T-LIB-ASDF-02" "/a/.gitignore.org" ".gitignore"
          "T-LIB-ASDF-03" "/a/bar.md.org" "bar.md"
        End

        It "Then: [Normal] $1: $2 の配置先名は $3"
          When call asset_dest_name "$2"
          The status should equal 0
          The output should equal "$3"
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
        It "Then: [Normal] T-LIB-ASDF-07: .org を除いた配置先名を出力する"
          When call list_updated_assets "${NAMING_TMPDIR}/src" "${NAMING_TMPDIR}/dest"
          The status should equal 0
          The output should equal ".gitignore"
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
End
