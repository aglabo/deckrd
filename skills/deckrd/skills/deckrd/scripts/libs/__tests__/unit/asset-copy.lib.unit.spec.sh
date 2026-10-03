#!/usr/bin/env bash
# asset-copy.lib.unit.spec.sh - ShellSpec tests for asset-copy.lib.sh
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

SCRIPT="${DECKRD_LIB_DIR}/asset-copy.lib.sh"
. "$SCRIPT"

Describe "T-LIB-ASCP: asset-copy.lib.sh"
  # Helper: write <content> to <dir>/<name>, creating <dir>
  put_file() {
    mkdir -p "$1"
    printf '%s\n' "$3" >"$1/$2"
  }

  # Helper: set the mtime of <path> to the past, so the other side is newer
  make_old() {
    touch -d '2000-01-01 00:00:00' "$1"
  }

  # Helper: succeed when <a> and <b> have the same mtime (in seconds)
  same_mtime() {
    [[ "$(stat -c %Y "$1")" == "$(stat -c %Y "$2")" ]]
  }

  # Helper: succeed when <path> still has the past mtime set by make_old
  is_old() {
    [[ "$(stat -c %Y "$1")" == "$(date -d '2000-01-01 00:00:00' +%s)" ]]
  }

  # Helper: succeed when <a> is newer than <b>
  is_newer() {
    [[ "$1" -nt "$2" ]]
  }

  # Helper: create a symlink <link> pointing to <target>, creating the parent of <link>
  # MSYS=winsymlinks:nativestrict makes Git Bash create a native link; harmless elsewhere.
  put_symlink() {
    mkdir -p "$(dirname "$2")"
    MSYS=winsymlinks:nativestrict ln -s "$1" "$2"
  }

  # Helper: report whether this host cannot create a dangling symlink
  # Keeps the negation inside the function so that `Skip if` works.
  # @return 0 if a dangling symlink cannot be created, 1 if it can
  dangling_symlink_unsupported() {
    local probe_dir rc=1
    probe_dir="$(mktemp -d)" || return 0
    { MSYS=winsymlinks:nativestrict ln -s "${probe_dir}/missing" "${probe_dir}/link" 2>/dev/null &&
      [[ -L "${probe_dir}/link" ]]; } || rc=0
    rm -rf "$probe_dir"
    return "$rc"
  }

  # Helper: report whether this host cannot create a symlink to a regular file
  # Keeps the negation inside the function so that `Skip if` works.
  # @return 0 if a symlink to a regular file cannot be created, 1 if it can
  symlink_unsupported() {
    local probe_dir rc=1
    probe_dir="$(mktemp -d)" || return 0
    { : >"${probe_dir}/target" &&
      MSYS=winsymlinks:nativestrict ln -s "${probe_dir}/target" "${probe_dir}/link" 2>/dev/null &&
      [[ -L "${probe_dir}/link" ]]; } || rc=0
    rm -rf "$probe_dir"
    return "$rc"
  }

  Describe "copy_asset_file"
    BeforeEach "setup_tmpdir"
    AfterEach "teardown_tmpdir"

    Describe "Given: ソースファイルがあり配置先の親ディレクトリが既存"
      setup_parent_exists() {
        put_file "${NAMING_TMPDIR}/src" "a.md" "alpha"
        mkdir -p "${NAMING_TMPDIR}/dest"
      }
      BeforeEach "setup_parent_exists"

      Describe "When: copy_asset_file を呼ぶ"
        It "Then: [Normal] T-LIB-ASCP-01: ソースの内容で配置先ファイルを作成する"
          When call copy_asset_file "${NAMING_TMPDIR}/src/a.md" "${NAMING_TMPDIR}/dest/a.md"
          The status should equal 0
          The output should equal ""
          The contents of file "${NAMING_TMPDIR}/dest/a.md" should equal "alpha"
        End
      End
    End

    Describe "Given: ソースファイルがあり配置先の親ディレクトリが未作成"
      setup_parent_missing() {
        put_file "${NAMING_TMPDIR}/src" "a.md" "alpha"
      }
      BeforeEach "setup_parent_missing"

      Describe "When: 多段の配置先パスで copy_asset_file を呼ぶ"
        It "Then: [Normal] T-LIB-ASCP-02: 親ディレクトリを作成してコピーする"
          When call copy_asset_file "${NAMING_TMPDIR}/src/a.md" "${NAMING_TMPDIR}/dest/x/y/a.md"
          The status should equal 0
          The output should equal ""
          The contents of file "${NAMING_TMPDIR}/dest/x/y/a.md" should equal "alpha"
        End
      End
    End

    Describe "Given: ソースファイルが存在しない"
      Describe "When: copy_asset_file を呼ぶ"
        It "Then: [Error] T-LIB-ASCP-03: 非 0 を返し配置先ファイルを作成しない"
          When call copy_asset_file "${NAMING_TMPDIR}/src/missing.md" "${NAMING_TMPDIR}/dest/a.md"
          The status should be failure
          The output should equal ""
          The stderr should be present
          The path "${NAMING_TMPDIR}/dest/a.md" should not be exist
        End
      End
    End

    Describe "Given: 配置先に旧内容のファイルが既存"
      setup_dest_exists() {
        put_file "${NAMING_TMPDIR}/src" "a.md" "new"
        put_file "${NAMING_TMPDIR}/dest" "a.md" "old"
      }
      BeforeEach "setup_dest_exists"

      Describe "When: copy_asset_file を呼ぶ"
        It "Then: [Edge] T-LIB-ASCP-04: ソースの内容で上書きする"
          When call copy_asset_file "${NAMING_TMPDIR}/src/a.md" "${NAMING_TMPDIR}/dest/a.md"
          The status should equal 0
          The output should equal ""
          The contents of file "${NAMING_TMPDIR}/dest/a.md" should equal "new"
        End
      End
    End

    Describe "Given: 更新時刻が過去のソースファイルがある"
      setup_old_src() {
        put_file "${NAMING_TMPDIR}/src" "a.md" "alpha"
        make_old "${NAMING_TMPDIR}/src/a.md"
      }
      BeforeEach "setup_old_src"

      Describe "When: copy_asset_file を呼ぶ"
        It "Then: [Normal] T-LIB-ASCP-32: 配置先の更新時刻をソースと同じにする"
          When call copy_asset_file "${NAMING_TMPDIR}/src/a.md" "${NAMING_TMPDIR}/dest/a.md"
          The status should equal 0
          The output should equal ""
          Assert same_mtime "${NAMING_TMPDIR}/src/a.md" "${NAMING_TMPDIR}/dest/a.md"
        End
      End
    End

    # Differs from T-LIB-ASCP-04: dest is a symlink to a file outside dest, so the
    # link itself is replaced instead of writing through it.
    Describe "Given: 配置先がプロジェクト外ファイルへのシンボリックリンク"
      Skip if "symlinks are not supported on this host" symlink_unsupported
      setup_file_dest_symlink() {
        put_file "${NAMING_TMPDIR}/src" "a.md" "NEW"
        put_file "${NAMING_TMPDIR}/outside" "a.md" "OLD"
        put_symlink "${NAMING_TMPDIR}/outside/a.md" "${NAMING_TMPDIR}/dest/a.md"
      }
      BeforeEach "setup_file_dest_symlink"

      Describe "When: copy_asset_file を呼ぶ"
        # Characterization: passes since the -L guard in copy_asset_file;
        # without it `cp -p` writes through the link and overwrites outside/a.md.
        It "Then: [Normal] T-LIB-ASCP-54: 配置先のリンクを外して通常ファイルとしてコピーし、リンク先を変えない"
          When call copy_asset_file "${NAMING_TMPDIR}/src/a.md" "${NAMING_TMPDIR}/dest/a.md"
          The status should equal 0
          The output should equal ""
          The path "${NAMING_TMPDIR}/dest/a.md" should not be symlink
          The contents of file "${NAMING_TMPDIR}/dest/a.md" should equal "NEW"
          The contents of file "${NAMING_TMPDIR}/outside/a.md" should equal "OLD"
        End
      End
    End

    # Same Given style as T-LIB-ASCP-03, but dest is a symlink to a file outside dest.
    Describe "Given: ソースファイルが存在せず配置先がプロジェクト外ファイルへのシンボリックリンク"
      Skip if "symlinks are not supported on this host" symlink_unsupported
      setup_missing_src_dest_symlink() {
        put_file "${NAMING_TMPDIR}/outside" "a.md" "OLD"
        put_symlink "${NAMING_TMPDIR}/outside/a.md" "${NAMING_TMPDIR}/dest/a.md"
      }
      BeforeEach "setup_missing_src_dest_symlink"

      Describe "When: copy_asset_file を呼ぶ"
        # Characterization: `cp` fails on the missing source before writing anything,
        # so the link target stays as is with or without the -L guard (verified by a
        # mutation that truncates dest before `cp`: the test then fails).
        # Whether dest/a.md is still a link is implementation-dependent and not checked.
        It "Then: [Error] T-LIB-ASCP-55: ソースがなければ非 0 を返し、リンク先を変えない"
          When call copy_asset_file "${NAMING_TMPDIR}/src/a.md" "${NAMING_TMPDIR}/dest/a.md"
          The status should be failure
          The output should equal ""
          The stderr should be present
          The contents of file "${NAMING_TMPDIR}/outside/a.md" should equal "OLD"
        End
      End
    End

    Describe "Given: 配置先がリンク切れのシンボリックリンク"
      Skip if "dangling symlinks are not supported on this host" dangling_symlink_unsupported
      setup_file_dest_dangling_symlink() {
        put_file "${NAMING_TMPDIR}/src" "a.md" "NEW"
        put_symlink "${NAMING_TMPDIR}/missing-target.md" "${NAMING_TMPDIR}/dest/a.md"
      }
      BeforeEach "setup_file_dest_dangling_symlink"

      Describe "When: copy_asset_file を呼ぶ"
        # Characterization: passes since the -L guard in copy_asset_file;
        # without it `cp` follows the dangling link and creates missing-target.md.
        It "Then: [Edge] T-LIB-ASCP-56: リンク切れの配置先も外して通常ファイルを作り、リンク先を作らない"
          When call copy_asset_file "${NAMING_TMPDIR}/src/a.md" "${NAMING_TMPDIR}/dest/a.md"
          The status should equal 0
          The output should equal ""
          The path "${NAMING_TMPDIR}/dest/a.md" should not be symlink
          The contents of file "${NAMING_TMPDIR}/dest/a.md" should equal "NEW"
          The path "${NAMING_TMPDIR}/missing-target.md" should not be exist
        End
      End
    End
  End

  Describe "copy_assets"
    BeforeEach "setup_tmpdir"
    AfterEach "teardown_tmpdir"

    Describe "Given: ソースに入れ子ディレクトリとトップレベルのファイルがあり配置先が未作成"
      setup_nested_and_top_src() {
        put_file "${NAMING_TMPDIR}/src/rules" "a.md" "A"
        put_file "${NAMING_TMPDIR}/src" "top.md" "T"
      }
      BeforeEach "setup_nested_and_top_src"

      Describe "When: copy_assets を呼ぶ"
        It "Then: [Normal] T-LIB-ASCP-14: 入れ子を保って全ファイルをコピーし dst_rel を出力する"
          When call copy_assets "${NAMING_TMPDIR}/src" "${NAMING_TMPDIR}/dest"
          The status should equal 0
          The line 1 of output should equal "rules/a.md"
          The line 2 of output should equal "top.md"
          The lines of output should equal 2
          The stderr should equal ""
          The contents of file "${NAMING_TMPDIR}/dest/rules/a.md" should equal "A"
          The contents of file "${NAMING_TMPDIR}/dest/top.md" should equal "T"
        End
      End
    End

    Describe "Given: ソースに .org 付き dotfile があり配置先が未作成"
      setup_org_src() {
        put_file "${NAMING_TMPDIR}/src/rules" ".gitignore.org" "ignored"
      }
      BeforeEach "setup_org_src"

      Describe "When: copy_assets を呼ぶ"
        It "Then: [Normal] T-LIB-ASCP-15: .org を外した名前でコピーし .org ファイルを作らない"
          When call copy_assets "${NAMING_TMPDIR}/src" "${NAMING_TMPDIR}/dest"
          The status should equal 0
          The output should equal "rules/.gitignore"
          The contents of file "${NAMING_TMPDIR}/dest/rules/.gitignore" should equal "ignored"
          The path "${NAMING_TMPDIR}/dest/rules/.gitignore.org" should not be exist
        End
      End
    End

    Describe "Given: 配置先に古く内容が違う同名ファイルが既存"
      setup_dest_outdated() {
        put_file "${NAMING_TMPDIR}/src" "a.md" "new"
        put_file "${NAMING_TMPDIR}/dest" "a.md" "old"
        make_old "${NAMING_TMPDIR}/dest/a.md"
      }
      BeforeEach "setup_dest_outdated"

      Describe "When: copy_assets を呼ぶ"
        It "Then: [Normal] T-LIB-ASCP-16: ソースの内容で上書きし dst_rel を出力する"
          When call copy_assets "${NAMING_TMPDIR}/src" "${NAMING_TMPDIR}/dest"
          The status should equal 0
          The output should equal "a.md"
          The contents of file "${NAMING_TMPDIR}/dest/a.md" should equal "new"
        End
      End
    End

    # Differs from T-LIB-ASCP-16: dest is a symlink.
    Describe "Given: 配置先が古く内容が違うプロジェクト外ファイルへのシンボリックリンク"
      Skip if "symlinks are not supported on this host" symlink_unsupported
      setup_copy_dest_symlink() {
        put_file "${NAMING_TMPDIR}/src" "a.md" "NEW"
        put_file "${NAMING_TMPDIR}/outside" "a.md" "OLD"
        make_old "${NAMING_TMPDIR}/outside/a.md"
        put_symlink "${NAMING_TMPDIR}/outside/a.md" "${NAMING_TMPDIR}/dest/a.md"
      }
      BeforeEach "setup_copy_dest_symlink"

      Describe "When: copy_assets を呼ぶ"
        # Characterization: passes since the -L guard in _asset_can_update (T-01);
        # without it a.md is listed and copy_asset_file replaces the link with a
        # regular file (dest/a.md is no longer a symlink).
        It "Then: [Normal] T-LIB-ASCP-48: リンクの配置先はコピーせず、リンク先の内容も更新時刻も変えない"
          When call copy_assets "${NAMING_TMPDIR}/src" "${NAMING_TMPDIR}/dest"
          The status should equal 0
          The output should equal ""
          The stderr should equal ""
          The path "${NAMING_TMPDIR}/dest/a.md" should be symlink
          The contents of file "${NAMING_TMPDIR}/outside/a.md" should equal "OLD"
          Assert is_old "${NAMING_TMPDIR}/outside/a.md"
        End
      End
    End

    Describe "Given: 配置先がリンク切れのシンボリックリンク"
      Skip if "dangling symlinks are not supported on this host" dangling_symlink_unsupported
      setup_copy_dest_dangling_symlink() {
        put_file "${NAMING_TMPDIR}/src" "a.md" "NEW"
        put_symlink "${NAMING_TMPDIR}/missing-target.md" "${NAMING_TMPDIR}/dest/a.md"
      }
      BeforeEach "setup_copy_dest_dangling_symlink"

      Describe "When: copy_assets を呼ぶ"
        # Characterization: passes since the -L guard in _asset_can_update (T-01);
        # without it the dangling link is listed and replaced by a regular file
        # (dest/a.md is no longer a symlink, output is "a.md").
        It "Then: [Error] T-LIB-ASCP-49: リンク切れの配置先はコピーせず、リンク先を作らない"
          When call copy_assets "${NAMING_TMPDIR}/src" "${NAMING_TMPDIR}/dest"
          The status should equal 0
          The output should equal ""
          The stderr should equal ""
          The path "${NAMING_TMPDIR}/dest/a.md" should be symlink
          The path "${NAMING_TMPDIR}/missing-target.md" should not be exist
        End
      End
    End

    Describe "Given: 配置先に古く内容が違うファイルへのリンクがあり、別のファイルが未配置"
      Skip if "symlinks are not supported on this host" symlink_unsupported
      setup_copy_symlink_and_missing() {
        put_file "${NAMING_TMPDIR}/src" "a.md" "NEW"
        put_file "${NAMING_TMPDIR}/src" "b.md" "B"
        put_file "${NAMING_TMPDIR}/outside" "a.md" "OLD"
        make_old "${NAMING_TMPDIR}/outside/a.md"
        put_symlink "${NAMING_TMPDIR}/outside/a.md" "${NAMING_TMPDIR}/dest/a.md"
      }
      BeforeEach "setup_copy_symlink_and_missing"

      Describe "When: copy_assets を呼ぶ"
        # Characterization: passes since the -L guard in _asset_can_update (T-01);
        # without it a.md is listed too and the link is replaced by a regular file
        # (output becomes "a.md\nb.md").
        It "Then: [Edge] T-LIB-ASCP-50: リンクの配置先は飛ばし、未配置の b.md だけをコピーする"
          When call copy_assets "${NAMING_TMPDIR}/src" "${NAMING_TMPDIR}/dest"
          The status should equal 0
          The output should equal "b.md"
          The contents of file "${NAMING_TMPDIR}/dest/b.md" should equal "B"
          The contents of file "${NAMING_TMPDIR}/outside/a.md" should equal "OLD"
          The path "${NAMING_TMPDIR}/dest/a.md" should be symlink
        End
      End
    End

    Describe "Given: 配置先に keep 対象の古く内容が違うファイルが既存"
      setup_dest_keep_outdated() {
        put_file "${NAMING_TMPDIR}/src/rules" ".gitignore.org" "upstream"
        put_file "${NAMING_TMPDIR}/dest/rules" ".gitignore" "user"
        make_old "${NAMING_TMPDIR}/dest/rules/.gitignore"
      }
      BeforeEach "setup_dest_keep_outdated"

      Describe "When: keep パターン '*/.gitignore' を渡して copy_assets を呼ぶ"
        It "Then: [Edge] T-LIB-ASCP-20: 上書きせず何も出力しない"
          When call copy_assets "${NAMING_TMPDIR}/src" "${NAMING_TMPDIR}/dest" '*/.gitignore'
          The status should equal 0
          The output should equal ""
          The contents of file "${NAMING_TMPDIR}/dest/rules/.gitignore" should equal "user"
        End
      End
    End

    Describe "Given: ソースディレクトリが存在しない"
      Describe "When: copy_assets を呼ぶ"
        It "Then: [Error] T-LIB-ASCP-25: 出力なしで 0 を返す"
          When call copy_assets "${NAMING_TMPDIR}/missing" "${NAMING_TMPDIR}/dest"
          The status should equal 0
          The output should equal ""
          The stderr should equal ""
        End
      End

      Describe "When: --force を第 1 引数にして copy_assets を呼ぶ"
        It "Then: [Error] T-LIB-ASCP-43: 配置先を作成し、出力なしで 0 を返す"
          When call copy_assets --force "${NAMING_TMPDIR}/missing" "${NAMING_TMPDIR}/dest"
          The status should equal 0
          The output should equal ""
          The stderr should equal ""
          The path "${NAMING_TMPDIR}/dest" should be directory
        End
      End
    End

    Describe "Given: 配置先の親パスが通常ファイル"
      setup_dest_parent_blocked() {
        put_file "${NAMING_TMPDIR}/src" "a.md" "A"
        put_file "${NAMING_TMPDIR}" "blocker" "file"
      }
      BeforeEach "setup_dest_parent_blocked"

      Describe "When: copy_assets を呼ぶ"
        It "Then: [Error] T-LIB-ASCP-26: ディレクトリ作成エラーを出し 1 を返す"
          When call copy_assets "${NAMING_TMPDIR}/src" "${NAMING_TMPDIR}/blocker/dest"
          The status should equal 1
          The output should equal ""
          The stderr should include "Error: failed to create directory: ${NAMING_TMPDIR}/blocker/dest"
        End
      End
    End

    Describe "Given: 配置先のサブディレクトリ位置に通常ファイルがある"
      setup_dest_subdir_blocked() {
        put_file "${NAMING_TMPDIR}/src/rules" "a.md" "A"
        put_file "${NAMING_TMPDIR}/dest" "rules" "file"
      }
      BeforeEach "setup_dest_subdir_blocked"

      Describe "When: copy_assets を呼ぶ"
        It "Then: [Error] T-LIB-ASCP-27: コピーエラーを出し 1 を返す"
          When call copy_assets "${NAMING_TMPDIR}/src" "${NAMING_TMPDIR}/dest"
          The status should equal 1
          The output should equal ""
          The stderr should include "Error: failed to copy file: ${NAMING_TMPDIR}/dest/rules/a.md"
        End
      End
    End

    Describe "Given: 配置先のサブディレクトリ位置に通常ファイルがあり、dest を \ 区切りで渡す"
      setup_backslash_dest_subdir_blocked() {
        put_file "${NAMING_TMPDIR}/src/rules" "a.md" "A"
        put_file "${NAMING_TMPDIR}/dest" "rules" "file"
        bs="${NAMING_TMPDIR//\//\\}"
      }
      BeforeEach "setup_backslash_dest_subdir_blocked"

      Describe "When: copy_assets を呼ぶ"
        It "Then: [Error] T-LIB-ASCP-30: \ 区切りの dest でも / 区切りのパスでコピーエラーを出し 1 を返す"
          When call copy_assets "${NAMING_TMPDIR}/src" "${bs}\\dest"
          The status should equal 1
          The output should equal ""
          The stderr should include "Error: failed to copy file: ${NAMING_TMPDIR}/dest/rules/a.md"
          The stderr should not include "\\"
        End
      End
    End

    Describe "Given: ソースにファイルがあり、src/dest を \ 区切りと末尾区切り付きで渡す"
      setup_backslash_src_dest() {
        put_file "${NAMING_TMPDIR}/src" "a.md" "A"
        put_file "${NAMING_TMPDIR}/src/rules" "b.md" "B"
        bs="${NAMING_TMPDIR//\//\\}"
      }
      BeforeEach "setup_backslash_src_dest"

      Describe "When: copy_assets を呼ぶ"
        It "Then: [Edge] T-LIB-ASCP-29: 配置して dst_rel を出力する"
          When call copy_assets "${bs}\\src\\" "${bs}\\dest\\"
          The status should equal 0
          The output should equal "$(printf '%s\n' a.md rules/b.md)"
          The stderr should equal ""
          The path "${NAMING_TMPDIR}/dest/rules/b.md" should be file
          The contents of file "${NAMING_TMPDIR}/dest/a.md" should equal "A"
          The contents of file "${NAMING_TMPDIR}/dest/rules/b.md" should equal "B"
        End
      End
    End

    Describe "Given: ソースに a.md と a.md.org があり配置先が空"
      setup_plain_and_org_src() {
        put_file "${NAMING_TMPDIR}/src" "a.md" "plain"
        put_file "${NAMING_TMPDIR}/src" "a.md.org" "org"
        mkdir -p "${NAMING_TMPDIR}/dest"
      }
      BeforeEach "setup_plain_and_org_src"

      Describe "When: copy_assets を呼ぶ"
        # Both sources map to dst_rel `a.md`. The list is byte-sorted (a.md before
        # a.md.org) and captured before the first copy, so the .org copy runs last.
        It "Then: [Edge] T-LIB-ASCP-31: 各行のソースからコピーし、ソート順で後の a.md.org の内容が残る"
          When call copy_assets "${NAMING_TMPDIR}/src" "${NAMING_TMPDIR}/dest"
          The status should equal 0
          The output should equal "$(printf '%s\n' a.md a.md)"
          The stderr should equal ""
          The contents of file "${NAMING_TMPDIR}/dest/a.md" should equal "org"
          The path "${NAMING_TMPDIR}/dest/a.md.org" should not be exist
        End
      End
    End

    Describe "Given: ソースに .org が 2 重に付いた a.org.org があり配置先が未作成"
      setup_double_org_src() {
        put_file "${NAMING_TMPDIR}/src" "a.org.org" "x"
      }
      BeforeEach "setup_double_org_src"

      Describe "When: copy_assets を呼ぶ"
        It "Then: [Edge] T-LIB-ASCP-64: 末尾の .org を 1 回だけ外し、a.org としてコピーする"
          When call copy_assets "${NAMING_TMPDIR}/src" "${NAMING_TMPDIR}/dest"
          The status should equal 0
          The output should equal "a.org"
          The contents of file "${NAMING_TMPDIR}/dest/a.org" should equal "x"
          The path "${NAMING_TMPDIR}/dest/a.org.org" should not be exist
          The path "${NAMING_TMPDIR}/dest/a" should not be exist
        End
      End
    End

    Describe "Given: ソースに名前が .org で終わるディレクトリ rules.org があり配置先が未作成"
      setup_org_dir_src() {
        put_file "${NAMING_TMPDIR}/src/rules.org" "a.md" "x"
      }
      BeforeEach "setup_org_dir_src"

      Describe "When: copy_assets を呼ぶ"
        It "Then: [Edge] T-LIB-ASCP-65: ディレクトリ名の .org は外さず、rules.org/a.md としてコピーする"
          When call copy_assets "${NAMING_TMPDIR}/src" "${NAMING_TMPDIR}/dest"
          The status should equal 0
          The output should equal "rules.org/a.md"
          The contents of file "${NAMING_TMPDIR}/dest/rules.org/a.md" should equal "x"
          The path "${NAMING_TMPDIR}/dest/rules/a.md" should not be exist
        End
      End
    End

    Describe "Given: 配置先に古く内容が同じ同名ファイルが既存"
      setup_dest_old_identical() {
        put_file "${NAMING_TMPDIR}/src" "a.md" "same"
        put_file "${NAMING_TMPDIR}/dest" "a.md" "same"
        make_old "${NAMING_TMPDIR}/dest/a.md"
      }
      BeforeEach "setup_dest_old_identical"

      Describe "When: copy_assets を呼ぶ"
        It "Then: [Normal] T-LIB-ASCP-33: 何も出力せず内容を保ち、更新時刻をソースと同じにする"
          When call copy_assets "${NAMING_TMPDIR}/src" "${NAMING_TMPDIR}/dest"
          The status should equal 0
          The output should equal ""
          The stderr should equal ""
          The contents of file "${NAMING_TMPDIR}/dest/a.md" should equal "same"
          Assert same_mtime "${NAMING_TMPDIR}/src/a.md" "${NAMING_TMPDIR}/dest/a.md"
        End
      End
    End

    Describe "Given: 配置先に keep 対象の古く内容が同じファイルが既存"
      setup_dest_keep_old_identical() {
        put_file "${NAMING_TMPDIR}/src/rules" ".gitignore.org" "same"
        put_file "${NAMING_TMPDIR}/dest/rules" ".gitignore" "same"
        make_old "${NAMING_TMPDIR}/dest/rules/.gitignore"
      }
      BeforeEach "setup_dest_keep_old_identical"

      Describe "When: keep パターン '*/.gitignore' を渡して copy_assets を呼ぶ"
        It "Then: [Edge] T-LIB-ASCP-34: 更新時刻を変えず古いまま残す"
          When call copy_assets "${NAMING_TMPDIR}/src" "${NAMING_TMPDIR}/dest" '*/.gitignore'
          The status should equal 0
          The output should equal ""
          Assert is_old "${NAMING_TMPDIR}/dest/rules/.gitignore"
        End
      End
    End

    Describe "Given: 配置先にソースより新しく内容が違う同名ファイルが既存 (ユーザー編集)"
      setup_dest_newer_edited() {
        put_file "${NAMING_TMPDIR}/src" "a.md" "upstream"
        put_file "${NAMING_TMPDIR}/dest" "a.md" "user"
        make_old "${NAMING_TMPDIR}/src/a.md"
      }
      BeforeEach "setup_dest_newer_edited"

      Describe "When: copy_assets を呼ぶ"
        It "Then: [Edge] T-LIB-ASCP-35: 内容も更新時刻も変えない"
          When call copy_assets "${NAMING_TMPDIR}/src" "${NAMING_TMPDIR}/dest"
          The status should equal 0
          The output should equal ""
          The contents of file "${NAMING_TMPDIR}/dest/a.md" should equal "user"
          Assert is_newer "${NAMING_TMPDIR}/dest/a.md" "${NAMING_TMPDIR}/src/a.md"
        End
      End

      Describe "When: --force を第 1 引数にして copy_assets を呼ぶ"
        It "Then: [Normal] T-LIB-ASCP-40: ソースの内容で上書きし dst_rel を出力する"
          When call copy_assets --force "${NAMING_TMPDIR}/src" "${NAMING_TMPDIR}/dest"
          The status should equal 0
          The output should equal "a.md"
          The contents of file "${NAMING_TMPDIR}/dest/a.md" should equal "upstream"
        End
      End

      # --force is only recognized as $1; in any other position it does not enable force mode
      Describe "When: --force を第 3 引数にして copy_assets を呼ぶ"
        It "Then: [Edge] T-LIB-ASCP-44: 強制モードにならず、内容も更新時刻も変えない"
          When call copy_assets "${NAMING_TMPDIR}/src" "${NAMING_TMPDIR}/dest" --force
          The status should equal 0
          The output should equal ""
          The contents of file "${NAMING_TMPDIR}/dest/a.md" should equal "user"
          Assert is_newer "${NAMING_TMPDIR}/dest/a.md" "${NAMING_TMPDIR}/src/a.md"
        End
      End
    End

    Describe "Given: 配置先に古く内容が違う同名ファイルが既存 (更新時刻の確認)"
      setup_dest_old_different() {
        put_file "${NAMING_TMPDIR}/src" "a.md" "new"
        put_file "${NAMING_TMPDIR}/dest" "a.md" "old"
        make_old "${NAMING_TMPDIR}/dest/a.md"
      }
      BeforeEach "setup_dest_old_different"

      Describe "When: copy_assets を呼ぶ"
        It "Then: [Normal] T-LIB-ASCP-36: 上書きして dst_rel を出力し、更新時刻をソースと同じにする"
          When call copy_assets "${NAMING_TMPDIR}/src" "${NAMING_TMPDIR}/dest"
          The status should equal 0
          The output should equal "a.md"
          The contents of file "${NAMING_TMPDIR}/dest/a.md" should equal "new"
          Assert same_mtime "${NAMING_TMPDIR}/src/a.md" "${NAMING_TMPDIR}/dest/a.md"
        End
      End
    End

    Describe "Given: ソースに a.md があり配置先に a.md がない"
      setup_dest_missing() {
        put_file "${NAMING_TMPDIR}/src" "a.md" "new"
      }
      BeforeEach "setup_dest_missing"

      Describe "When: --missing-only を第 1 引数にして copy_assets を呼ぶ"
        It "Then: [Normal] T-LIB-ASCP-57: 未配置の a.md をコピーし dst_rel を出力する"
          When call copy_assets --missing-only "${NAMING_TMPDIR}/src" "${NAMING_TMPDIR}/dest"
          The status should equal 0
          The output should equal "a.md"
          The contents of file "${NAMING_TMPDIR}/dest/a.md" should equal "new"
        End
      End
    End

    # sync_asset_mtimes is replaced inside each It by a stub that records its
    # arguments to sync.log (or fails, in T-LIB-ASCP-63), so the tests observe
    # whether copy_assets calls it and how it handles a failure.
    Describe "Given: ソースに a.md があり配置先が未作成 (sync_asset_mtimes の呼び出し確認)"
      setup_sync_call_src() {
        put_file "${NAMING_TMPDIR}/src" "a.md" "NEW"
      }
      BeforeEach "setup_sync_call_src"

      Describe "When: --force を第 1 引数にして copy_assets を呼ぶ"
        It "Then: [Normal] T-LIB-ASCP-60: a.md をコピーし、sync_asset_mtimes を呼ばない"
          # shellcheck disable=SC2329 # copy_assets から間接的に呼ばれる
          sync_asset_mtimes() { printf '%s\n' "$*" >>"${NAMING_TMPDIR}/sync.log"; }
          When call copy_assets --force "${NAMING_TMPDIR}/src" "${NAMING_TMPDIR}/dest"
          The status should equal 0
          The output should equal "a.md"
          The contents of file "${NAMING_TMPDIR}/dest/a.md" should equal "NEW"
          The path "${NAMING_TMPDIR}/sync.log" should not be exist
        End
      End

      Describe "When: copy_assets を呼ぶ"
        It "Then: [Normal] T-LIB-ASCP-61: a.md をコピーし、src と dest を引数に sync_asset_mtimes を 1 回呼ぶ"
          # shellcheck disable=SC2329 # copy_assets から間接的に呼ばれる
          sync_asset_mtimes() { printf '%s\n' "$*" >>"${NAMING_TMPDIR}/sync.log"; }
          When call copy_assets "${NAMING_TMPDIR}/src" "${NAMING_TMPDIR}/dest"
          The status should equal 0
          The output should equal "a.md"
          The contents of file "${NAMING_TMPDIR}/sync.log" should equal "${NAMING_TMPDIR}/src ${NAMING_TMPDIR}/dest"
        End

        It "Then: [Error] T-LIB-ASCP-63: sync_asset_mtimes が失敗すると、コピー済みの a.md を出力したうえで 1 を返す"
          # shellcheck disable=SC2329 # copy_assets から間接的に呼ばれる
          sync_asset_mtimes() { return 1; }
          When call copy_assets "${NAMING_TMPDIR}/src" "${NAMING_TMPDIR}/dest"
          The status should equal 1
          The output should equal "a.md"
          The stderr should equal ""
        End
      End

      Describe "When: --missing-only を第 1 引数にして copy_assets を呼ぶ"
        It "Then: [Normal] T-LIB-ASCP-62: a.md をコピーし、src と dest を引数に sync_asset_mtimes を 1 回呼ぶ"
          # shellcheck disable=SC2329 # copy_assets から間接的に呼ばれる
          sync_asset_mtimes() { printf '%s\n' "$*" >>"${NAMING_TMPDIR}/sync.log"; }
          When call copy_assets --missing-only "${NAMING_TMPDIR}/src" "${NAMING_TMPDIR}/dest"
          The status should equal 0
          The output should equal "a.md"
          The contents of file "${NAMING_TMPDIR}/sync.log" should equal "${NAMING_TMPDIR}/src ${NAMING_TMPDIR}/dest"
        End
      End
    End

    # Differs from T-LIB-ASCP-16 / 36: --missing-only, so the outdated dest is kept.
    Describe "Given: 配置先に古く内容が違う同名ファイルが既存 (--missing-only)"
      setup_dest_outdated_missing_only() {
        put_file "${NAMING_TMPDIR}/src" "a.md" "new"
        put_file "${NAMING_TMPDIR}/dest" "a.md" "old"
        make_old "${NAMING_TMPDIR}/dest/a.md"
      }
      BeforeEach "setup_dest_outdated_missing_only"

      Describe "When: --missing-only を第 1 引数にして copy_assets を呼ぶ"
        It "Then: [Edge] T-LIB-ASCP-58: 既存の a.md を上書きせず何も出力しない"
          When call copy_assets --missing-only "${NAMING_TMPDIR}/src" "${NAMING_TMPDIR}/dest"
          The status should equal 0
          The output should equal ""
          The contents of file "${NAMING_TMPDIR}/dest/a.md" should equal "old"
        End
      End

      # --missing-only is only recognized as $1; in any other position it does not enable missing-only mode
      Describe "When: --missing-only を第 3 引数にして copy_assets を呼ぶ"
        It "Then: [Edge] T-LIB-ASCP-59: 欠落補完モードにならず、通常どおり上書きして dst_rel を出力する"
          When call copy_assets "${NAMING_TMPDIR}/src" "${NAMING_TMPDIR}/dest" --missing-only
          The status should equal 0
          The output should equal "a.md"
          The contents of file "${NAMING_TMPDIR}/dest/a.md" should equal "new"
        End
      End
    End

    Describe "Given: 配置先に保護対象の .gitignore が既存"
      setup_dest_protected() {
        put_file "${NAMING_TMPDIR}/src" ".gitignore.org" "upstream"
        put_file "${NAMING_TMPDIR}/dest" ".gitignore" "user"
      }
      BeforeEach "setup_dest_protected"

      Describe "When: --force を第 1 引数にし ASSET_KEEP_PATTERNS を渡して copy_assets を呼ぶ"
        It "Then: [Edge] T-LIB-ASCP-41: 保護を無視してソースの内容で上書きし dst_rel を出力する"
          When call copy_assets --force "${NAMING_TMPDIR}/src" "${NAMING_TMPDIR}/dest" "${ASSET_KEEP_PATTERNS[@]}"
          The status should equal 0
          The output should equal ".gitignore"
          The contents of file "${NAMING_TMPDIR}/dest/.gitignore" should equal "upstream"
        End
      End
    End

    Describe "Given: 配置先にソースより新しく内容が同じ同名ファイルが既存"
      setup_dest_newer_identical() {
        put_file "${NAMING_TMPDIR}/src" "a.md" "same"
        put_file "${NAMING_TMPDIR}/dest" "a.md" "same"
        make_old "${NAMING_TMPDIR}/src/a.md"
      }
      BeforeEach "setup_dest_newer_identical"

      Describe "When: --force を第 1 引数にして copy_assets を呼ぶ"
        It "Then: [Edge] T-LIB-ASCP-42: コピーして dst_rel を出力し、更新時刻をソースと同じにする"
          When call copy_assets --force "${NAMING_TMPDIR}/src" "${NAMING_TMPDIR}/dest"
          The status should equal 0
          The output should equal "a.md"
          The contents of file "${NAMING_TMPDIR}/dest/a.md" should equal "same"
          Assert same_mtime "${NAMING_TMPDIR}/src/a.md" "${NAMING_TMPDIR}/dest/a.md"
        End
      End
    End

    # Differs from T-LIB-ASCP-40: dest is a symlink, so force mode must replace
    # the link itself instead of writing through it to the link target.
    Describe "Given: 配置先が古く内容が違うプロジェクト外ファイルへのシンボリックリンク (強制モード)"
      Skip if "symlinks are not supported on this host" symlink_unsupported
      setup_force_dest_symlink() {
        put_file "${NAMING_TMPDIR}/src" "a.md" "NEW"
        put_file "${NAMING_TMPDIR}/outside" "a.md" "OLD"
        make_old "${NAMING_TMPDIR}/outside/a.md"
        put_symlink "${NAMING_TMPDIR}/outside/a.md" "${NAMING_TMPDIR}/dest/a.md"
      }
      BeforeEach "setup_force_dest_symlink"

      Describe "When: --force を第 1 引数にして copy_assets を呼ぶ"
        It "Then: [Normal] T-LIB-ASCP-51: 強制モードではリンクを外し、通常ファイルとしてコピーする"
          When call copy_assets --force "${NAMING_TMPDIR}/src" "${NAMING_TMPDIR}/dest"
          The status should equal 0
          The output should equal "a.md"
          The path "${NAMING_TMPDIR}/dest/a.md" should not be symlink
          The contents of file "${NAMING_TMPDIR}/dest/a.md" should equal "NEW"
          The contents of file "${NAMING_TMPDIR}/outside/a.md" should equal "OLD"
          Assert is_old "${NAMING_TMPDIR}/outside/a.md"
        End
      End
    End

    # Same checks as T-LIB-ASCP-51, but the link points to a directory: without the
    # -L guard in copy_asset_file, `cp -p` copies into outside/dir and dest stays a link.
    Describe "Given: 配置先がプロジェクト外ディレクトリへのシンボリックリンク (強制モード)"
      Skip if "symlinks are not supported on this host" symlink_unsupported
      setup_force_dest_dir_symlink() {
        put_file "${NAMING_TMPDIR}/src" "a.md" "NEW"
        mkdir -p "${NAMING_TMPDIR}/outside/dir"
        put_symlink "${NAMING_TMPDIR}/outside/dir" "${NAMING_TMPDIR}/dest/a.md"
      }
      BeforeEach "setup_force_dest_dir_symlink"

      Describe "When: --force を第 1 引数にして copy_assets を呼ぶ"
        It "Then: [Error] T-LIB-ASCP-52: ディレクトリを指すリンクも外し、ディレクトリ内へコピーしない"
          When call copy_assets --force "${NAMING_TMPDIR}/src" "${NAMING_TMPDIR}/dest"
          The status should equal 0
          The output should equal "a.md"
          The path "${NAMING_TMPDIR}/dest/a.md" should not be symlink
          The contents of file "${NAMING_TMPDIR}/dest/a.md" should equal "NEW"
          The path "${NAMING_TMPDIR}/outside/dir/a.md" should not be exist
        End
      End
    End

    # Differs from T-LIB-ASCP-41: the protected .gitignore is a symlink. Force mode
    # still ignores the keep patterns, and replaces the link instead of writing
    # through it; without the -L guard in copy_asset_file outside/gitignore is overwritten.
    Describe "Given: 配置先の保護対象 .gitignore がプロジェクト外ファイルへのシンボリックリンク (強制モード)"
      Skip if "symlinks are not supported on this host" symlink_unsupported
      setup_force_dest_keep_symlink() {
        put_file "${NAMING_TMPDIR}/src" ".gitignore.org" "NEW"
        put_file "${NAMING_TMPDIR}/outside" "gitignore" "OLD"
        put_symlink "${NAMING_TMPDIR}/outside/gitignore" "${NAMING_TMPDIR}/dest/.gitignore"
      }
      BeforeEach "setup_force_dest_keep_symlink"

      Describe "When: --force を第 1 引数にし ASSET_KEEP_PATTERNS を渡して copy_assets を呼ぶ"
        It "Then: [Edge] T-LIB-ASCP-53: 強制モードでは keep 対象のリンクも外し、リンク先を変えない"
          When call copy_assets --force "${NAMING_TMPDIR}/src" "${NAMING_TMPDIR}/dest" "${ASSET_KEEP_PATTERNS[@]}"
          The status should equal 0
          The output should equal ".gitignore"
          The path "${NAMING_TMPDIR}/dest/.gitignore" should not be symlink
          The contents of file "${NAMING_TMPDIR}/dest/.gitignore" should equal "NEW"
          The contents of file "${NAMING_TMPDIR}/outside/gitignore" should equal "OLD"
        End
      End
    End
  End

  Describe "sync_asset_mtimes"
    BeforeEach "setup_tmpdir"
    AfterEach "teardown_tmpdir"

    Describe "Given: ソースディレクトリが存在しない"
      Describe "When: sync_asset_mtimes を呼ぶ"
        It "Then: [Edge] T-LIB-ASCP-37: 出力なしで 0 を返す"
          When call sync_asset_mtimes "${NAMING_TMPDIR}/missing" "${NAMING_TMPDIR}/dest"
          The status should equal 0
          The output should equal ""
          The stderr should equal ""
        End
      End
    End

    Describe "Given: 配置先に古く内容が同じファイルがあり touch が失敗する"
      setup_sync_target() {
        put_file "${NAMING_TMPDIR}/src" "a.md" "same"
        put_file "${NAMING_TMPDIR}/dest" "a.md" "same"
        make_old "${NAMING_TMPDIR}/dest/a.md"
      }
      BeforeEach "setup_sync_target"

      Describe "When: sync_asset_mtimes を呼ぶ"
        It "Then: [Error] T-LIB-ASCP-38: 更新時刻エラーを出し 1 を返す"
          touch() { return 1; }
          When call sync_asset_mtimes "${NAMING_TMPDIR}/src" "${NAMING_TMPDIR}/dest"
          The status should equal 1
          The output should equal ""
          The stderr should equal "Error: failed to update timestamp: ${NAMING_TMPDIR}/dest/a.md"
        End
      End
    End

    Describe "Given: 配置先に keep 対象と非対象の古く内容が同じファイルが既存"
      setup_sync_keep_and_plain() {
        put_file "${NAMING_TMPDIR}/src" ".gitignore.org" "same"
        put_file "${NAMING_TMPDIR}/src" "a.md" "same"
        put_file "${NAMING_TMPDIR}/dest" ".gitignore" "same"
        put_file "${NAMING_TMPDIR}/dest" "a.md" "same"
        make_old "${NAMING_TMPDIR}/dest/.gitignore"
        make_old "${NAMING_TMPDIR}/dest/a.md"
      }
      BeforeEach "setup_sync_keep_and_plain"

      Describe "When: ASSET_KEEP_PATTERNS を渡して sync_asset_mtimes を呼ぶ"
        It "Then: [Edge] T-LIB-ASCP-39: 保護ファイルの更新時刻は変えず、非保護ファイルはソースに揃える"
          When call sync_asset_mtimes "${NAMING_TMPDIR}/src" "${NAMING_TMPDIR}/dest" "${ASSET_KEEP_PATTERNS[@]}"
          The status should equal 0
          The output should equal ""
          The stderr should equal ""
          Assert is_old "${NAMING_TMPDIR}/dest/.gitignore"
          Assert same_mtime "${NAMING_TMPDIR}/src/a.md" "${NAMING_TMPDIR}/dest/a.md"
        End
      End
    End

    Describe "Given: 配置先が古く内容が同じプロジェクト外ファイルへのシンボリックリンク"
      Skip if "symlinks are not supported on this host" symlink_unsupported
      setup_sync_dest_symlink() {
        put_file "${NAMING_TMPDIR}/src" "a.md" "A"
        put_file "${NAMING_TMPDIR}/outside" "a.md" "A"
        make_old "${NAMING_TMPDIR}/outside/a.md"
        put_symlink "${NAMING_TMPDIR}/outside/a.md" "${NAMING_TMPDIR}/dest/a.md"
      }
      BeforeEach "setup_sync_dest_symlink"

      Describe "When: sync_asset_mtimes を呼ぶ"
        It "Then: [Normal] T-LIB-ASCP-45: リンクの配置先はスキップし、リンク先の更新時刻を変えない"
          When call sync_asset_mtimes "${NAMING_TMPDIR}/src" "${NAMING_TMPDIR}/dest"
          The status should equal 0
          The output should equal ""
          The stderr should equal ""
          Assert is_old "${NAMING_TMPDIR}/outside/a.md"
          The path "${NAMING_TMPDIR}/dest/a.md" should be symlink
        End
      End
    End

    Describe "Given: 配置先がリンク切れのシンボリックリンク"
      Skip if "dangling symlinks are not supported on this host" dangling_symlink_unsupported
      setup_sync_dest_dangling_symlink() {
        put_file "${NAMING_TMPDIR}/src" "a.md" "A"
        put_symlink "${NAMING_TMPDIR}/missing-target.md" "${NAMING_TMPDIR}/dest/a.md"
      }
      BeforeEach "setup_sync_dest_dangling_symlink"

      Describe "When: sync_asset_mtimes を呼ぶ"
        # Characterization: passes without the -L guard too (`! -f` already skips a
        # dangling link); without both guards `touch -r` would create the target.
        It "Then: [Error] T-LIB-ASCP-46: リンク切れの配置先はスキップし、リンク先を作らない"
          When call sync_asset_mtimes "${NAMING_TMPDIR}/src" "${NAMING_TMPDIR}/dest"
          The status should equal 0
          The output should equal ""
          The stderr should equal ""
          The path "${NAMING_TMPDIR}/dest/a.md" should be symlink
          The path "${NAMING_TMPDIR}/missing-target.md" should not be exist
        End
      End
    End

    Describe "Given: 配置先にリンクと通常ファイルが混在し、どちらも古く内容が同じ"
      Skip if "symlinks are not supported on this host" symlink_unsupported
      setup_sync_symlink_and_plain() {
        put_file "${NAMING_TMPDIR}/src" "a.md" "A"
        put_file "${NAMING_TMPDIR}/src" "b.md" "B"
        put_file "${NAMING_TMPDIR}/outside" "a.md" "A"
        make_old "${NAMING_TMPDIR}/outside/a.md"
        put_symlink "${NAMING_TMPDIR}/outside/a.md" "${NAMING_TMPDIR}/dest/a.md"
        put_file "${NAMING_TMPDIR}/dest" "b.md" "B"
        make_old "${NAMING_TMPDIR}/dest/b.md"
      }
      BeforeEach "setup_sync_symlink_and_plain"

      Describe "When: sync_asset_mtimes を呼ぶ"
        It "Then: [Edge] T-LIB-ASCP-47: リンクはスキップし、通常ファイルの更新時刻だけをソースに揃える"
          When call sync_asset_mtimes "${NAMING_TMPDIR}/src" "${NAMING_TMPDIR}/dest"
          The status should equal 0
          The output should equal ""
          The stderr should equal ""
          Assert is_old "${NAMING_TMPDIR}/outside/a.md"
          Assert same_mtime "${NAMING_TMPDIR}/src/b.md" "${NAMING_TMPDIR}/dest/b.md"
          The path "${NAMING_TMPDIR}/dest/b.md" should not be symlink
        End
      End
    End
  End

  Describe "_copy_listed_assets"
    BeforeEach "setup_tmpdir"
    AfterEach "teardown_tmpdir"

    # Helper: succeed when <dir> exists and has no entries
    is_empty_dir() {
      [[ -d "$1" && -z "$(ls -A "$1")" ]]
    }

    Describe "Given: ソースと配置先が空ディレクトリとして存在する"
      setup_empty_dirs() {
        mkdir -p "${NAMING_TMPDIR}/src" "${NAMING_TMPDIR}/dest"
      }
      BeforeEach "setup_empty_dirs"

      Describe "When: 空リストを渡して _copy_listed_assets を呼ぶ"
        It "Then: [Normal] T-LIB-ASCP-66: 何もコピーせず、出力なしで 0 を返す"
          When call _copy_listed_assets "${NAMING_TMPDIR}/src" "${NAMING_TMPDIR}/dest" ""
          The status should equal 0
          The output should equal ""
          The stderr should equal ""
          Assert is_empty_dir "${NAMING_TMPDIR}/dest"
        End
      End
    End

    Describe "Given: ソースに .gitignore.org と b.md があり、配置先は空"
      setup_org_and_plain() {
        put_file "${NAMING_TMPDIR}/src" ".gitignore.org" "IGNORE"
        put_file "${NAMING_TMPDIR}/src" "b.md" "B"
        mkdir -p "${NAMING_TMPDIR}/dest"
      }
      BeforeEach "setup_org_and_plain"

      Describe "When: 2 件のリストを渡して _copy_listed_assets を呼ぶ"
        It "Then: [Normal] T-LIB-ASCP-67: .org を外した名前でコピーし、各 dst_rel を出力する"
          When call _copy_listed_assets "${NAMING_TMPDIR}/src" "${NAMING_TMPDIR}/dest" $'.gitignore.org\nb.md'
          The status should equal 0
          The line 1 of output should equal ".gitignore"
          The line 2 of output should equal "b.md"
          The lines of output should equal 2
          The contents of file "${NAMING_TMPDIR}/dest/.gitignore" should equal "IGNORE"
          The contents of file "${NAMING_TMPDIR}/dest/b.md" should equal "B"
          The path "${NAMING_TMPDIR}/dest/.gitignore.org" should not be exist
        End
      End
    End

    Describe "Given: ソースに sub/a.md があり、配置先のサブディレクトリ位置に通常ファイルがある"
      setup_listed_dest_subdir_blocked() {
        put_file "${NAMING_TMPDIR}/src/sub" "a.md" "A"
        put_file "${NAMING_TMPDIR}/dest" "sub" "file"
      }
      BeforeEach "setup_listed_dest_subdir_blocked"

      Describe "When: sub/a.md のリストを渡して _copy_listed_assets を呼ぶ"
        It "Then: [Error] T-LIB-ASCP-68: コピーエラーを出し 1 を返す"
          When call _copy_listed_assets "${NAMING_TMPDIR}/src" "${NAMING_TMPDIR}/dest" "sub/a.md"
          The status should equal 1
          The output should equal ""
          The stderr should include "Error: failed to copy file: ${NAMING_TMPDIR}/dest/sub/a.md"
        End
      End
    End
  End
End
