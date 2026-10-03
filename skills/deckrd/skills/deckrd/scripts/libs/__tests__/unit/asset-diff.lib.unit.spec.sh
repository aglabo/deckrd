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

Describe "T-LIB-ASDF: asset-diff.lib.sh"
  # Helper: write <content> to <dir>/<name>, creating <dir>
  put_file() {
    mkdir -p "$1"
    printf '%s\n' "$3" >"$1/$2"
  }

  # Helper: set the mtime of <path> to the past, so the other side is newer
  make_old() {
    touch -d '2000-01-01 00:00:00' "$1"
  }

  # Helper: create symlink <link> pointing at <target>, creating the parent of <link>
  # MSYS=winsymlinks:nativestrict lets Git Bash create a native (even dangling) symlink; harmless elsewhere.
  put_symlink() {
    mkdir -p "$(dirname "$2")"
    MSYS=winsymlinks:nativestrict ln -s "$1" "$2"
  }

  # Helper: succeed when <path> still has the past mtime set by make_old
  is_old() {
    [[ "$(stat -c %Y "$1")" == "$(date -d '2000-01-01 00:00:00' +%s)" ]]
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

  Describe "_list_all_files"
    Before "setup_tmpdir"
    After "teardown_tmpdir"

    Describe "Given: 入れ子のソースディレクトリに非ソート順でファイルを作成した"
      setup_nested() {
        put_file "${NAMING_TMPDIR}/src" "z.md" "z"
        put_file "${NAMING_TMPDIR}/src" "a.md" "a"
        put_file "${NAMING_TMPDIR}/src/rules" "b.md" "b"
      }
      Before "setup_nested"

      Describe "When: _list_all_files を呼ぶ"
        It "Then: [Normal] T-LIB-ASDF-36: 再帰的に相対パスをソートして出力する"
          When call _list_all_files "${NAMING_TMPDIR}/src"
          The status should equal 0
          The output should equal "$(printf '%s\n' a.md rules/b.md z.md)"
        End
      End
    End

    Describe "Given: ソースディレクトリに dotfile だけが存在する"
      setup_dotfile_only() {
        put_file "${NAMING_TMPDIR}/src" ".gitignore.org" "ignore"
      }
      Before "setup_dotfile_only"

      Describe "When: _list_all_files を呼ぶ"
        It "Then: [Normal] T-LIB-ASDF-37: dotfile も出力する"
          When call _list_all_files "${NAMING_TMPDIR}/src"
          The status should equal 0
          The output should equal ".gitignore.org"
        End
      End
    End

    Describe "Given: ソースディレクトリが存在しない"
      Describe "When: _list_all_files を呼ぶ"
        It "Then: [Error] T-LIB-ASDF-38: 何も出力せず status 0 で終わる"
          When call _list_all_files "${NAMING_TMPDIR}/no-such-src"
          The status should equal 0
          The output should equal ""
          The stderr should equal ""
        End
      End
    End

    Describe "Given: ソースディレクトリが空"
      setup_empty_src() {
        mkdir -p "${NAMING_TMPDIR}/src"
      }
      Before "setup_empty_src"

      Describe "When: _list_all_files を呼ぶ"
        It "Then: [Edge] T-LIB-ASDF-39: 何も出力しない"
          When call _list_all_files "${NAMING_TMPDIR}/src"
          The status should equal 0
          The output should equal ""
        End
      End
    End

    Describe "Given: ソースディレクトリに空のサブディレクトリだけが存在する"
      setup_empty_subdir() {
        mkdir -p "${NAMING_TMPDIR}/src/rules"
      }
      Before "setup_empty_subdir"

      Describe "When: _list_all_files を呼ぶ"
        It "Then: [Edge] T-LIB-ASDF-40: ディレクトリは出力しない"
          When call _list_all_files "${NAMING_TMPDIR}/src"
          The status should equal 0
          The output should equal ""
        End
      End
    End

    Describe "Given: ソースディレクトリにファイルがあり、パスを末尾スラッシュ付きで渡す"
      setup_single_file() {
        put_file "${NAMING_TMPDIR}/src" "a.md" "a"
      }
      Before "setup_single_file"

      Describe "When: _list_all_files を呼ぶ"
        It "Then: [Edge] T-LIB-ASDF-41: 先頭に / のない相対パスを出力する"
          When call _list_all_files "${NAMING_TMPDIR}/src/"
          The status should equal 0
          The output should equal "a.md"
        End
      End
    End

    Describe "Given: ソースディレクトリにファイルがあり、パスを \ 区切りと末尾 \ 付きで渡す"
      setup_backslash_src() {
        put_file "${NAMING_TMPDIR}/src" "a.md" "a"
        put_file "${NAMING_TMPDIR}/src/rules" "b.md" "b"
        bs="${NAMING_TMPDIR//\//\\}"
      }
      Before "setup_backslash_src"

      Describe "When: _list_all_files を呼ぶ"
        It "Then: [Edge] T-LIB-ASDF-56: / 区切りの相対パスを出力する"
          When call _list_all_files "${bs}\\src\\"
          The status should equal 0
          The output should equal "$(printf '%s\n' a.md rules/b.md)"
        End
      End
    End

    Describe "Given: find が \ を含む相対パスを出力する"
      # Helper: create the empty src dir the -d guard requires
      setup_empty_src_for_stub() {
        mkdir -p "${NAMING_TMPDIR}/src"
      }
      Before "setup_empty_src_for_stub"

      # Helper: stub find; a real `a\b.md` cannot be created on Windows/MSYS
      find() {
        printf '%s\n' './sub/a\b.md' './z.md'
      }

      Describe "When: _list_all_files を呼ぶ"
        It "Then: [Edge] T-LIB-ASDF-57: \ を / に正規化して出力する"
          When call _list_all_files "${NAMING_TMPDIR}/src"
          The status should equal 0
          The output should equal "$(printf '%s\n' sub/a/b.md z.md)"
        End
      End
    End
  End

  Describe "list_asset_files"
    BeforeEach "setup_tmpdir"
    AfterEach "teardown_tmpdir"

    Describe "Given: ソースに入れ子ディレクトリとトップレベルのファイルがあり配置先が未作成"
      setup_nested_and_top_src() {
        put_file "${NAMING_TMPDIR}/src/rules" "a.md" "A"
        put_file "${NAMING_TMPDIR}/src" "top.md" "T"
      }
      BeforeEach "setup_nested_and_top_src"

      Describe "When: list_asset_files を呼ぶ"
        It "Then: [Normal] T-LIB-ASDF-58: 全ファイルを src_rel として列挙順に出力する"
          When call list_asset_files "${NAMING_TMPDIR}/src" "${NAMING_TMPDIR}/dest"
          The status should equal 0
          The output should equal "$(printf '%s\n' rules/a.md top.md)"
          The stderr should equal ""
        End
      End
    End

    Describe "Given: ソースに .org 付き dotfile があり配置先が未作成"
      setup_org_src() {
        put_file "${NAMING_TMPDIR}/src/rules" ".gitignore.org" "ignored"
      }
      BeforeEach "setup_org_src"

      Describe "When: list_asset_files を呼ぶ"
        It "Then: [Normal] T-LIB-ASDF-59: .org を残したソース相対パスを出力する"
          When call list_asset_files "${NAMING_TMPDIR}/src" "${NAMING_TMPDIR}/dest"
          The status should equal 0
          The output should equal "rules/.gitignore.org"
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

      Describe "When: list_asset_files を呼ぶ"
        It "Then: [Normal] T-LIB-ASDF-60: src_rel を出力し配置先ファイルは変えない"
          When call list_asset_files "${NAMING_TMPDIR}/src" "${NAMING_TMPDIR}/dest"
          The status should equal 0
          The output should equal "a.md"
          The contents of file "${NAMING_TMPDIR}/dest/a.md" should equal "old"
        End
      End
    End

    Describe "Given: 配置先にソースより新しく内容が同じ同名ファイルが既存"
      setup_dest_up_to_date() {
        put_file "${NAMING_TMPDIR}/src" "a.md" "same"
        make_old "${NAMING_TMPDIR}/src/a.md"
        put_file "${NAMING_TMPDIR}/dest" "a.md" "same"
      }
      BeforeEach "setup_dest_up_to_date"

      Describe "When: list_asset_files を呼ぶ"
        It "Then: [Normal] T-LIB-ASDF-61: 配置済みで最新なので何も出力しない"
          When call list_asset_files "${NAMING_TMPDIR}/src" "${NAMING_TMPDIR}/dest"
          The status should equal 0
          The output should equal ""
        End
      End
    End

    Describe "Given: ソースディレクトリが存在しない"
      Describe "When: list_asset_files を呼ぶ"
        It "Then: [Error] T-LIB-ASDF-62: 何も出力せず status 0 で終わる"
          When call list_asset_files "${NAMING_TMPDIR}/missing" "${NAMING_TMPDIR}/dest"
          The status should equal 0
          The output should equal ""
          The stderr should equal ""
        End
      End
    End

    Describe "Given: 配置先にソースより新しく内容が違う同名ファイル (ユーザー編集) が既存"
      setup_dest_user_edited() {
        put_file "${NAMING_TMPDIR}/src" "a.md" "upstream"
        make_old "${NAMING_TMPDIR}/src/a.md"
        put_file "${NAMING_TMPDIR}/dest" "a.md" "user edit"
      }
      BeforeEach "setup_dest_user_edited"

      Describe "When: list_asset_files を呼ぶ"
        It "Then: [Edge] T-LIB-ASDF-63: ユーザー編集とみなし何も出力せず配置先を変えない"
          When call list_asset_files "${NAMING_TMPDIR}/src" "${NAMING_TMPDIR}/dest"
          The status should equal 0
          The output should equal ""
          The contents of file "${NAMING_TMPDIR}/dest/a.md" should equal "user edit"
        End
      End
    End

    Describe "Given: 配置先にソースより古く内容が同じ同名ファイルが既存"
      setup_dest_old_same() {
        put_file "${NAMING_TMPDIR}/src" "a.md" "same"
        put_file "${NAMING_TMPDIR}/dest" "a.md" "same"
        make_old "${NAMING_TMPDIR}/dest/a.md"
      }
      BeforeEach "setup_dest_old_same"

      Describe "When: list_asset_files を呼ぶ"
        It "Then: [Edge] T-LIB-ASDF-64: 内容が同じなので何も出力しない"
          When call list_asset_files "${NAMING_TMPDIR}/src" "${NAMING_TMPDIR}/dest"
          The status should equal 0
          The output should equal ""
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

      Describe "When: keep パターン '*/.gitignore' を渡して list_asset_files を呼ぶ"
        It "Then: [Edge] T-LIB-ASDF-65: keep 対象は何も出力せず配置先を変えない"
          When call list_asset_files "${NAMING_TMPDIR}/src" "${NAMING_TMPDIR}/dest" '*/.gitignore'
          The status should equal 0
          The output should equal ""
          The contents of file "${NAMING_TMPDIR}/dest/rules/.gitignore" should equal "user"
        End
      End
    End

    Describe "Given: ソースに keep 対象の dotfile があり配置先が未作成"
      setup_keep_src_only() {
        put_file "${NAMING_TMPDIR}/src/rules" ".gitignore.org" "upstream"
      }
      BeforeEach "setup_keep_src_only"

      Describe "When: keep パターン '*/.gitignore' を渡して list_asset_files を呼ぶ"
        It "Then: [Edge] T-LIB-ASDF-66: 未配置なので keep 対象でも src_rel を出力する"
          When call list_asset_files "${NAMING_TMPDIR}/src" "${NAMING_TMPDIR}/dest" '*/.gitignore'
          The status should equal 0
          The output should equal "rules/.gitignore.org"
        End
      End
    End

    Describe "Given: 配置先が存在しないターゲットを指すシンボリックリンク (dangling)"
      Skip if "dangling symlinks are not supported on this host" dangling_symlink_unsupported
      setup_dest_dangling_symlink() {
        put_file "${NAMING_TMPDIR}/src" "a.md" "A"
        put_symlink "${NAMING_TMPDIR}/missing-target.md" "${NAMING_TMPDIR}/dest/a.md"
      }
      BeforeEach "setup_dest_dangling_symlink"

      Describe "When: list_asset_files を呼ぶ"
        It "Then: [Edge] T-LIB-ASDF-67: 配置済みとみなし何も出力せずシンボリックリンクを維持する"
          When call list_asset_files "${NAMING_TMPDIR}/src" "${NAMING_TMPDIR}/dest"
          The status should equal 0
          The output should equal ""
          The stderr should equal ""
          The path "${NAMING_TMPDIR}/dest/a.md" should be symlink
          The path "${NAMING_TMPDIR}/missing-target.md" should not be exist
        End
      End
    End

    Describe "Given: 配置先がプロジェクト外の古く内容が違うファイルを指すシンボリックリンク"
      Skip if "symlinks are not supported on this host" symlink_unsupported
      setup_dest_symlink_outdated() {
        put_file "${NAMING_TMPDIR}/src" "a.md" "NEW"
        put_file "${NAMING_TMPDIR}/outside" "a.md" "OLD"
        make_old "${NAMING_TMPDIR}/outside/a.md"
        put_symlink "${NAMING_TMPDIR}/outside/a.md" "${NAMING_TMPDIR}/dest/a.md"
      }
      BeforeEach "setup_dest_symlink_outdated"

      Describe "When: list_asset_files を呼ぶ"
        It "Then: [Normal] T-LIB-ASDF-80: リンク先が古く内容が違っても配置済みとみなし何も出力しない"
          When call list_asset_files "${NAMING_TMPDIR}/src" "${NAMING_TMPDIR}/dest"
          The status should equal 0
          The output should equal ""
          The stderr should equal ""
          The path "${NAMING_TMPDIR}/dest/a.md" should be symlink
          The contents of file "${NAMING_TMPDIR}/outside/a.md" should equal "OLD"
          Assert is_old "${NAMING_TMPDIR}/outside/a.md"
        End
      End
    End

    Describe "Given: 配置先が自分自身を指すシンボリックリンク (ループ)"
      Skip if "dangling symlinks are not supported on this host" dangling_symlink_unsupported
      setup_dest_symlink_loop() {
        put_file "${NAMING_TMPDIR}/src" "a.md" "NEW"
        put_symlink "${NAMING_TMPDIR}/dest/a.md" "${NAMING_TMPDIR}/dest/a.md"
      }
      BeforeEach "setup_dest_symlink_loop"

      Describe "When: list_asset_files を呼ぶ"
        # Characterization: passes before the symlink guard; RED confirmed by dropping `! -L` from the existence check.
        It "Then: [Error] T-LIB-ASDF-81: ループしたリンクも配置済みとみなし何も出力しない"
          When call list_asset_files "${NAMING_TMPDIR}/src" "${NAMING_TMPDIR}/dest"
          The status should equal 0
          The output should equal ""
          The stderr should equal ""
          The path "${NAMING_TMPDIR}/dest/a.md" should be symlink
        End
      End
    End

    Describe "Given: ソースに入れ子のファイルがあり配置先ディレクトリが未作成"
      setup_nested_src_no_dest() {
        put_file "${NAMING_TMPDIR}/src/rules" "a.md" "A"
      }
      BeforeEach "setup_nested_src_no_dest"

      Describe "When: list_asset_files を呼ぶ"
        It "Then: [Edge] T-LIB-ASDF-68: src_rel を出力するが配置先ディレクトリを作らない"
          When call list_asset_files "${NAMING_TMPDIR}/src" "${NAMING_TMPDIR}/dest"
          The status should equal 0
          The output should equal "rules/a.md"
          The path "${NAMING_TMPDIR}/dest" should not be exist
        End
      End
    End

    Describe "Given: 配置済みと未配置のファイルがあり、src/dest を \ 区切りと末尾区切り付きで渡す"
      setup_backslash_src_dest() {
        put_file "${NAMING_TMPDIR}/src" "a.md" "A"
        put_file "${NAMING_TMPDIR}/src/rules" "b.md" "B"
        put_file "${NAMING_TMPDIR}/dest" "a.md" "A"
        make_old "${NAMING_TMPDIR}/src/a.md"
        bs="${NAMING_TMPDIR//\//\\}"
      }
      BeforeEach "setup_backslash_src_dest"

      Describe "When: list_asset_files を呼ぶ"
        It "Then: [Edge] T-LIB-ASDF-69: 配置先を正しく解決し未配置の src_rel だけを出力する"
          When call list_asset_files "${bs}\\src\\" "${bs}\\dest\\"
          The status should equal 0
          The output should equal "rules/b.md"
          The stderr should equal ""
        End
      End
    End

    Describe "Given: ソースディレクトリが空で配置先が未作成"
      setup_empty_src_no_dest() {
        mkdir -p "${NAMING_TMPDIR}/src"
      }
      BeforeEach "setup_empty_src_no_dest"

      Describe "When: list_asset_files を呼ぶ"
        It "Then: [Edge] T-LIB-ASDF-70: 何も出力しない"
          When call list_asset_files "${NAMING_TMPDIR}/src" "${NAMING_TMPDIR}/dest"
          The status should equal 0
          The output should equal ""
        End
      End
    End

    Describe "Given: トップと入れ子の .gitignore と my.gitignore が古く内容が違う状態で配置済み"
      setup_dest_gitignores_outdated() {
        put_file "${NAMING_TMPDIR}/src" ".gitignore.org" "up1"
        put_file "${NAMING_TMPDIR}/src/rules" ".gitignore.org" "up2"
        put_file "${NAMING_TMPDIR}/src" "my.gitignore" "up3"
        put_file "${NAMING_TMPDIR}/dest" ".gitignore" "u1"
        put_file "${NAMING_TMPDIR}/dest/rules" ".gitignore" "u2"
        put_file "${NAMING_TMPDIR}/dest" "my.gitignore" "u3"
        make_old "${NAMING_TMPDIR}/dest/.gitignore"
        make_old "${NAMING_TMPDIR}/dest/rules/.gitignore"
        make_old "${NAMING_TMPDIR}/dest/my.gitignore"
      }
      BeforeEach "setup_dest_gitignores_outdated"

      Describe "When: ASSET_KEEP_PATTERNS を渡して list_asset_files を呼ぶ"
        # Boundary: `.gitignore` at the top level and at any depth is kept;
        # `my.gitignore` only ends in `.gitignore`, so it must still be reported.
        It "Then: [Edge] T-LIB-ASDF-71: 任意の深さの .gitignore だけを除外し my.gitignore は出力する"
          When call list_asset_files "${NAMING_TMPDIR}/src" "${NAMING_TMPDIR}/dest" "${ASSET_KEEP_PATTERNS[@]}"
          The status should equal 0
          The output should equal "my.gitignore"
          The contents of file "${NAMING_TMPDIR}/dest/.gitignore" should equal "u1"
          The contents of file "${NAMING_TMPDIR}/dest/rules/.gitignore" should equal "u2"
          The contents of file "${NAMING_TMPDIR}/dest/my.gitignore" should equal "u3"
        End
      End
    End

    Describe "Given: ソースにトップと入れ子の .gitignore.org があり配置先に .gitignore が無い"
      setup_dest_gitignores_missing() {
        put_file "${NAMING_TMPDIR}/src" ".gitignore.org" "up1"
        put_file "${NAMING_TMPDIR}/src/rules" ".gitignore.org" "up2"
        mkdir -p "${NAMING_TMPDIR}/dest"
      }
      BeforeEach "setup_dest_gitignores_missing"

      Describe "When: ASSET_KEEP_PATTERNS を渡して list_asset_files を呼ぶ"
        # Differs from T-LIB-ASDF-66 (nested only, pattern '*/.gitignore', no dest dir):
        # covers the top-level `.gitignore` with the real ASSET_KEEP_PATTERNS and an existing dest dir.
        It "Then: [Edge] T-LIB-ASDF-72: 未配置の保護ファイルは .gitignore.org と rules/.gitignore.org を出力する"
          When call list_asset_files "${NAMING_TMPDIR}/src" "${NAMING_TMPDIR}/dest" "${ASSET_KEEP_PATTERNS[@]}"
          The status should equal 0
          The line 1 of output should equal ".gitignore.org"
          The line 2 of output should equal "rules/.gitignore.org"
          The lines of output should equal 2
          The path "${NAMING_TMPDIR}/dest/.gitignore" should not be exist
          The path "${NAMING_TMPDIR}/dest/rules/.gitignore" should not be exist
        End
      End
    End

    Describe "Given: 配置先にソースより新しく内容が同じ同名ファイルが既存 (--force 検証)"
      setup_force_dest_up_to_date() {
        put_file "${NAMING_TMPDIR}/src" "a.md" "A"
        make_old "${NAMING_TMPDIR}/src/a.md"
        put_file "${NAMING_TMPDIR}/dest" "a.md" "A"
      }
      BeforeEach "setup_force_dest_up_to_date"

      Describe "When: --force を付けて list_asset_files を呼ぶ"
        # Differs from T-LIB-ASDF-61: --force ignores dest mtime and content.
        It "Then: [Normal] T-LIB-ASDF-73: 配置済みで最新でも src_rel を出力する"
          When call list_asset_files --force "${NAMING_TMPDIR}/src" "${NAMING_TMPDIR}/dest"
          The status should equal 0
          The output should equal "a.md"
        End
      End

      Describe "When: --force を 3 番目の引数に置いて list_asset_files を呼ぶ"
        # Differs from T-LIB-ASDF-73: --force is recognized only as $1; elsewhere it does not enable force mode.
        It "Then: [Edge] T-LIB-ASDF-79: 強制モードにならず何も出力しない"
          When call list_asset_files "${NAMING_TMPDIR}/src" "${NAMING_TMPDIR}/dest" --force
          The status should equal 0
          The output should equal ""
        End
      End
    End

    Describe "Given: 配置先にソースより新しく内容が違う同名ファイル (ユーザー編集) が既存 (強制モード)"
      setup_force_dest_user_edited() {
        put_file "${NAMING_TMPDIR}/src" "a.md" "upstream"
        make_old "${NAMING_TMPDIR}/src/a.md"
        put_file "${NAMING_TMPDIR}/dest" "a.md" "user"
      }
      BeforeEach "setup_force_dest_user_edited"

      Describe "When: --force を付けて list_asset_files を呼ぶ"
        # Differs from T-LIB-ASDF-63: --force reports user-edited files too.
        It "Then: [Normal] T-LIB-ASDF-74: ユーザー編集済みでも src_rel を出力し配置先を変えない"
          When call list_asset_files --force "${NAMING_TMPDIR}/src" "${NAMING_TMPDIR}/dest"
          The status should equal 0
          The output should equal "a.md"
          The contents of file "${NAMING_TMPDIR}/dest/a.md" should equal "user"
        End
      End
    End

    Describe "Given: 配置先がプロジェクト外のファイルを指すシンボリックリンク (強制モード)"
      Skip if "symlinks are not supported on this host" symlink_unsupported
      setup_force_dest_symlink() {
        put_file "${NAMING_TMPDIR}/src" "a.md" "NEW"
        put_file "${NAMING_TMPDIR}/outside" "a.md" "OLD"
        put_symlink "${NAMING_TMPDIR}/outside/a.md" "${NAMING_TMPDIR}/dest/a.md"
      }
      BeforeEach "setup_force_dest_symlink"

      Describe "When: --force を付けて list_asset_files を呼ぶ"
        # Differs from T-LIB-ASDF-80: --force ignores the symlink check.
        # Characterization: passes before the symlink guard; RED confirmed by disabling the --force branch.
        It "Then: [Edge] T-LIB-ASDF-82: 強制モードではリンクでも src_rel を出力し配置先を変えない"
          When call list_asset_files --force "${NAMING_TMPDIR}/src" "${NAMING_TMPDIR}/dest"
          The status should equal 0
          The output should equal "a.md"
          The path "${NAMING_TMPDIR}/dest/a.md" should be symlink
          The contents of file "${NAMING_TMPDIR}/outside/a.md" should equal "OLD"
        End
      End
    End

    Describe "Given: ソースディレクトリが存在しない (強制モード)"
      Describe "When: --force を付けて list_asset_files を呼ぶ"
        It "Then: [Error] T-LIB-ASDF-75: 何も出力せず status 0 で終わり配置先を作らない"
          When call list_asset_files --force "${NAMING_TMPDIR}/missing" "${NAMING_TMPDIR}/dest"
          The status should equal 0
          The output should equal ""
          The stderr should equal ""
          The path "${NAMING_TMPDIR}/dest" should not be exist
        End
      End
    End

    Describe "Given: 配置先に keep 対象の .gitignore が既存 (強制モード)"
      setup_force_dest_keep_exists() {
        put_file "${NAMING_TMPDIR}/src" ".gitignore.org" "upstream"
        put_file "${NAMING_TMPDIR}/dest" ".gitignore" "user"
      }
      BeforeEach "setup_force_dest_keep_exists"

      Describe "When: --force と ASSET_KEEP_PATTERNS を渡して list_asset_files を呼ぶ"
        # Differs from T-LIB-ASDF-65: --force ignores keep patterns.
        It "Then: [Edge] T-LIB-ASDF-76: keep 対象でも .gitignore.org を出力し配置先を変えない"
          When call list_asset_files --force "${NAMING_TMPDIR}/src" "${NAMING_TMPDIR}/dest" "${ASSET_KEEP_PATTERNS[@]}"
          The status should equal 0
          The output should equal ".gitignore.org"
          The contents of file "${NAMING_TMPDIR}/dest/.gitignore" should equal "user"
        End
      End
    End

    Describe "Given: 未配置・入れ子・配置済みのファイルが混在する (強制モード)"
      setup_force_mixed() {
        put_file "${NAMING_TMPDIR}/src" "b.md" "B"
        put_file "${NAMING_TMPDIR}/src" "Z.md" "Z"
        put_file "${NAMING_TMPDIR}/src" "a.md" "A"
        put_file "${NAMING_TMPDIR}/src/rules" "c.md" "C"
        make_old "${NAMING_TMPDIR}/src/a.md"
        put_file "${NAMING_TMPDIR}/dest" "a.md" "A"
      }
      BeforeEach "setup_force_mixed"

      Describe "When: --force を付けて list_asset_files を呼ぶ"
        It "Then: [Edge] T-LIB-ASDF-77: 全ファイルを byte-sorted で出力し配置先ディレクトリを作らない"
          When call list_asset_files --force "${NAMING_TMPDIR}/src" "${NAMING_TMPDIR}/dest"
          The status should equal 0
          The output should equal "$(printf '%s\n' Z.md a.md b.md rules/c.md)"
          The path "${NAMING_TMPDIR}/dest/rules" should not be exist
        End
      End
    End

    Describe "Given: ソースディレクトリが空で配置先が未作成 (強制モード)"
      setup_force_empty_src() {
        mkdir -p "${NAMING_TMPDIR}/src"
      }
      BeforeEach "setup_force_empty_src"

      Describe "When: --force を付けて list_asset_files を呼ぶ"
        It "Then: [Edge] T-LIB-ASDF-78: 何も出力せず status 0 で終わる"
          When call list_asset_files --force "${NAMING_TMPDIR}/src" "${NAMING_TMPDIR}/dest"
          The status should equal 0
          The output should equal ""
        End
      End
    End

    Describe "Given: ソースにトップレベルと入れ子のファイルがあり配置先が未作成 (未配置モード)"
      setup_missing_only_no_dest() {
        put_file "${NAMING_TMPDIR}/src" "a.md" "A"
        put_file "${NAMING_TMPDIR}/src/sub" "b.md" "B"
      }
      BeforeEach "setup_missing_only_no_dest"

      Describe "When: --missing-only を付けて list_asset_files を呼ぶ"
        It "Then: [Normal] T-LIB-ASDF-83: 全ファイルを src_rel として出力し配置先ディレクトリを作らない"
          When call list_asset_files --missing-only "${NAMING_TMPDIR}/src" "${NAMING_TMPDIR}/dest"
          The status should equal 0
          The output should equal "$(printf '%s\n' a.md sub/b.md)"
          The path "${NAMING_TMPDIR}/dest" should not be exist
        End
      End
    End

    Describe "Given: 配置先に古く内容が違う同名ファイルが既存 (未配置モード)"
      setup_missing_only_dest_outdated() {
        put_file "${NAMING_TMPDIR}/src" "a.md" "new"
        put_file "${NAMING_TMPDIR}/dest" "a.md" "old"
        make_old "${NAMING_TMPDIR}/dest/a.md"
      }
      BeforeEach "setup_missing_only_dest_outdated"

      Describe "When: --missing-only を付けて list_asset_files を呼ぶ"
        # Differs from T-LIB-ASDF-60: --missing-only ignores dest mtime and content.
        It "Then: [Normal] T-LIB-ASDF-84: 配置済みなので何も出力せず配置先の内容と mtime を変えない"
          When call list_asset_files --missing-only "${NAMING_TMPDIR}/src" "${NAMING_TMPDIR}/dest"
          The status should equal 0
          The output should equal ""
          The contents of file "${NAMING_TMPDIR}/dest/a.md" should equal "old"
          Assert is_old "${NAMING_TMPDIR}/dest/a.md"
        End
      End
    End

    Describe "Given: ソースディレクトリが存在しない (未配置モード)"
      Describe "When: --missing-only を付けて list_asset_files を呼ぶ"
        It "Then: [Error] T-LIB-ASDF-85: 何も出力せず status 0 で終わり配置先を作らない"
          When call list_asset_files --missing-only "${NAMING_TMPDIR}/missing" "${NAMING_TMPDIR}/dest"
          The status should equal 0
          The output should equal ""
          The stderr should equal ""
          The path "${NAMING_TMPDIR}/dest" should not be exist
        End
      End
    End

    Describe "Given: 配置済みと未配置のファイルが入れ子・.org 付きで混在する (未配置モード)"
      setup_missing_only_mixed() {
        put_file "${NAMING_TMPDIR}/src" "a.md" "A"
        put_file "${NAMING_TMPDIR}/src" "b.md" "B"
        put_file "${NAMING_TMPDIR}/src/sub" "c.md" "C"
        put_file "${NAMING_TMPDIR}/src/sub" "d.md.org" "D"
        put_file "${NAMING_TMPDIR}/dest" "a.md" "old-a"
        put_file "${NAMING_TMPDIR}/dest/sub" "d.md" "old-d"
        make_old "${NAMING_TMPDIR}/dest/a.md"
        make_old "${NAMING_TMPDIR}/dest/sub/d.md"
      }
      BeforeEach "setup_missing_only_mixed"

      Describe "When: --missing-only を付けて list_asset_files を呼ぶ"
        # Differs from the default mode: outdated a.md and sub/d.md are excluded because they exist.
        It "Then: [Normal] T-LIB-ASDF-86: 配置先に存在するファイルを除き未配置分だけを出力する"
          When call list_asset_files --missing-only "${NAMING_TMPDIR}/src" "${NAMING_TMPDIR}/dest"
          The status should equal 0
          The output should equal "$(printf '%s\n' b.md sub/c.md)"
          The contents of file "${NAMING_TMPDIR}/dest/a.md" should equal "old-a"
          The contents of file "${NAMING_TMPDIR}/dest/sub/d.md" should equal "old-d"
        End
      End
    End

    Describe "Given: 配置先にソースより新しく内容が違う同名ファイル (ユーザー編集) が既存 (未配置モード)"
      setup_missing_only_dest_user_edited() {
        put_file "${NAMING_TMPDIR}/src" "a.md" "upstream"
        make_old "${NAMING_TMPDIR}/src/a.md"
        put_file "${NAMING_TMPDIR}/dest" "a.md" "user"
      }
      BeforeEach "setup_missing_only_dest_user_edited"

      Describe "When: --missing-only を付けて list_asset_files を呼ぶ"
        It "Then: [Normal] T-LIB-ASDF-87: 配置済みなので何も出力せず配置先を変えない"
          When call list_asset_files --missing-only "${NAMING_TMPDIR}/src" "${NAMING_TMPDIR}/dest"
          The status should equal 0
          The output should equal ""
          The contents of file "${NAMING_TMPDIR}/dest/a.md" should equal "user"
        End
      End
    End

    Describe "Given: 配置先がプロジェクト外のファイルを指すシンボリックリンク (未配置モード)"
      Skip if "symlinks are not supported on this host" symlink_unsupported
      setup_missing_only_dest_symlink() {
        put_file "${NAMING_TMPDIR}/src" "a.md" "NEW"
        put_file "${NAMING_TMPDIR}/outside" "a.md" "OLD"
        put_symlink "${NAMING_TMPDIR}/outside/a.md" "${NAMING_TMPDIR}/dest/a.md"
      }
      BeforeEach "setup_missing_only_dest_symlink"

      Describe "When: --missing-only を付けて list_asset_files を呼ぶ"
        It "Then: [Edge] T-LIB-ASDF-88: リンクも配置済みとみなし何も出力せずリンク先を変えない"
          When call list_asset_files --missing-only "${NAMING_TMPDIR}/src" "${NAMING_TMPDIR}/dest"
          The status should equal 0
          The output should equal ""
          The path "${NAMING_TMPDIR}/dest/a.md" should be symlink
          The contents of file "${NAMING_TMPDIR}/outside/a.md" should equal "OLD"
        End
      End
    End

    Describe "Given: 配置先が存在しないターゲットを指すシンボリックリンク (dangling, 未配置モード)"
      Skip if "dangling symlinks are not supported on this host" dangling_symlink_unsupported
      setup_missing_only_dest_dangling() {
        put_file "${NAMING_TMPDIR}/src" "a.md" "A"
        put_symlink "${NAMING_TMPDIR}/missing-target.md" "${NAMING_TMPDIR}/dest/a.md"
      }
      BeforeEach "setup_missing_only_dest_dangling"

      Describe "When: --missing-only を付けて list_asset_files を呼ぶ"
        It "Then: [Edge] T-LIB-ASDF-89: dangling リンクも配置済みとみなし何も出力しない"
          When call list_asset_files --missing-only "${NAMING_TMPDIR}/src" "${NAMING_TMPDIR}/dest"
          The status should equal 0
          The output should equal ""
          The path "${NAMING_TMPDIR}/dest/a.md" should be symlink
          The path "${NAMING_TMPDIR}/missing-target.md" should not be exist
        End
      End
    End

  End

  Describe "init_asset_dirs"
    # Helper: clear asset variables so each case starts from an unset state
    unset_asset_vars() {
      unset INITS_DIR RULES_SRC_DIR RULES_INDEX_SRC_DIR CLAUDE_RULES_SRC_DIR DOCS_SRC_DIR \
        LOCAL_SRC_DIR DECKRD_RULES_DIR CLAUDE_RULES_DIR CLAUDE_RULES_INDEX_DIR \
        ASSET_TARGETS
    }
    Before "unset_asset_vars"

    Describe "Given: asset 系変数が未設定"
      Describe "When: init_asset_dirs を呼ぶ"
        It "Then: [Normal] T-LIB-ASDF-17: ASSET_TARGETS が 4 件で規定順に並ぶ"
          When call init_asset_dirs
          The status should equal 0
          The value "${#ASSET_TARGETS[@]}" should equal 4
          The value "${ASSET_TARGETS[0]}" should equal "claude-rules|${CLAUDE_RULES_SRC_DIR}|${CLAUDE_RULES_DIR}"
          The value "${ASSET_TARGETS[1]}" should equal "deckrd-rules-index|${RULES_INDEX_SRC_DIR}|${CLAUDE_RULES_INDEX_DIR}"
          The value "${ASSET_TARGETS[2]}" should equal "docs|${DOCS_SRC_DIR}|${DECKRD_DOCS_DIR}"
          The value "${ASSET_TARGETS[3]}" should equal "local-deckrd|${LOCAL_SRC_DIR}|${DECKRD_LOCAL_DATA}"
        End

        It "Then: [Normal] T-LIB-ASDF-18: 既定値が設定される"
          When call init_asset_dirs
          The status should equal 0
          The variable CLAUDE_RULES_SRC_DIR should equal "${DECKRD_ROOT}/assets/inits/claude-rules"
          The variable CLAUDE_RULES_DIR should equal "${PROJECT_ROOT}/.claude/rules/claude-rules"
          The variable CLAUDE_RULES_INDEX_DIR should equal "${PROJECT_ROOT}/.claude/rules/deckrd-rules"
          The value "${ASSET_TARGETS[0]}" should equal "claude-rules|${DECKRD_ROOT}/assets/inits/claude-rules|${PROJECT_ROOT}/.claude/rules/claude-rules"
        End

        It "Then: [Normal] T-LIB-ASDF-55: RULES_SRC_DIR と DECKRD_RULES_DIR は設定されない"
          When call init_asset_dirs
          The status should equal 0
          The variable RULES_SRC_DIR should be undefined
          The variable DECKRD_RULES_DIR should be undefined
        End
      End
    End

    Describe "Given: CLAUDE_RULES_SRC_DIR と CLAUDE_RULES_DIR が事前設定されている"
      preset_claude_rules_dirs() {
        CLAUDE_RULES_SRC_DIR="/tmp/src/claude-rules"
        CLAUDE_RULES_DIR="/tmp/dst/claude-rules"
      }
      Before "preset_claude_rules_dirs"

      Describe "When: init_asset_dirs を呼ぶ"
        It "Then: [Normal] T-LIB-ASDF-19: 事前設定値が ASSET_TARGETS に反映される"
          When call init_asset_dirs
          The status should equal 0
          The value "${ASSET_TARGETS[0]}" should equal "claude-rules|/tmp/src/claude-rules|/tmp/dst/claude-rules"
        End
      End
    End

    Describe "Given: CLAUDE_RULES_SRC_DIR が空文字で設定されている"
      preset_empty_claude_rules_src() {
        CLAUDE_RULES_SRC_DIR=""
      }
      Before "preset_empty_claude_rules_src"

      Describe "When: init_asset_dirs を呼ぶ"
        It "Then: [Error] T-LIB-ASDF-20: 空文字の変数は既定値になる"
          When call init_asset_dirs
          The status should equal 0
          The variable CLAUDE_RULES_SRC_DIR should equal "${DECKRD_ROOT}/assets/inits/claude-rules"
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
          The value "${ASSET_TARGETS[2]}" should equal "docs|/tmp/inits/docs|${DECKRD_DOCS_DIR}"
          The variable LOCAL_SRC_DIR should equal "/tmp/inits/local-deckrd"
        End
      End
    End

    Describe "Given: init_asset_dirs を一度呼んだ後"
      Before "init_asset_dirs"

      Describe "When: init_asset_dirs を再度呼ぶ"
        It "Then: [Edge] T-LIB-ASDF-22: 再呼び出しでも ASSET_TARGETS は 4 件のまま"
          When call init_asset_dirs
          The status should equal 0
          The value "${#ASSET_TARGETS[@]}" should equal 4
        End
      End
    End
  End

  Describe "workspaces_rule_missing"
    # Test data: gitignore contents passed as the argument (the function reads no file)
    _GITIGNORE_NO_RULE=$'*\n!README*\n!.gitignore'
    _GITIGNORE_NO_RULE_CRLF=$'*\r\n!README*\r\n!.gitignore\r\n'
    _GITIGNORE_NEAR_MISS=$'!/workspaces/**\n# !/workspaces/\n !/workspaces/'
    _GITIGNORE_RULE=$'*\n!/workspaces/'
    _GITIGNORE_RULE_CRLF=$'*\r\n!/workspaces/\r\n'

    Describe "Given: !/workspaces/ 行を持たない gitignore の内容"
      Describe "When: 正常系"
        It "Then: [Normal] T-LIB-ASDF-25: LF の内容は rule 欠落と判定し status 0 で終わる"
          When call workspaces_rule_missing "$_GITIGNORE_NO_RULE"
          The status should equal 0
        End

        It "Then: [Normal] T-LIB-ASDF-31: CRLF の内容も rule 欠落と判定し status 0 で終わる"
          When call workspaces_rule_missing "$_GITIGNORE_NO_RULE_CRLF"
          The status should equal 0
        End
      End
    End

    Describe "Given: !/workspaces/ に似ているが完全一致しない行だけを持つ内容"
      Describe "When: 異常系"
        It "Then: [Error] T-LIB-ASDF-34: 部分一致・コメント・先頭空白の行は rule とみなさず status 0 で終わる"
          When call workspaces_rule_missing "$_GITIGNORE_NEAR_MISS"
          The status should equal 0
        End
      End
    End

    Describe "Given: !/workspaces/ 行を持つ内容、または空の内容"
      Describe "When: エッジケース"
        It "Then: [Edge] T-LIB-ASDF-26: LF の rule 行があれば rule ありと判定し status 1 で終わる"
          When call workspaces_rule_missing "$_GITIGNORE_RULE"
          The status should equal 1
        End

        It "Then: [Edge] T-LIB-ASDF-30: 行末の CR を無視して rule ありと判定し、何も出力せず status 1 で終わる"
          When call workspaces_rule_missing "$_GITIGNORE_RULE_CRLF"
          The status should equal 1
          The output should equal ""
          The stderr should equal ""
        End

        It "Then: [Edge] T-LIB-ASDF-27: 空の内容は rule 欠落と判定し status 0 で終わる"
          When call workspaces_rule_missing ""
          The status should equal 0
        End
      End
    End
  End

  Describe "workspaces_rule_block"
    # Test data: template contents passed as the argument (the function reads no file)
    _TEMPLATE_TWO_SECTIONS=$'*
## ---- ##
##  Unrelated section ##
## ---- ##
!README*
## ---- ##
##  Shared notes layer: track workspaces/ only ##
## ---- ##
!/workspaces/
!/workspaces/**'
    _BLOCK_OF_TWO_SECTIONS=$'## ---- ##
##  Shared notes layer: track workspaces/ only ##
## ---- ##
!/workspaces/
!/workspaces/**'
    _TEMPLATE_MARKERLESS=$'*
!README*'
    _TEMPLATE_MARKER_NO_BANNER=$'*
##  Shared notes layer: track workspaces/ only ##'

    # Helper: print a template file from the line just above its first marker line through EOF
    # Computed with grep/tail from the file, independently of the sed in workspaces_rule_block
    _expected_rule_block() {
      local marker_line
      marker_line="$(grep -n -m 1 -F 'Shared notes layer' "$1" | cut -d: -f1)"
      tail -n "+$((marker_line - 1))" "$1"
    }

    Describe "Given: marker 行と直上の banner 行を持つテンプレートの内容"
      TEMPLATE="${SHELLSPEC_PROJECT_ROOT}/skills/deckrd/skills/deckrd/assets/inits/local-deckrd/.gitignore.org"
      read_bundled_template() {
        TEMPLATE_CONTENT="$(cat -- "$TEMPLATE")"
      }
      Before "read_bundled_template"

      Describe "When: 正常系"
        It "Then: [Normal] T-LIB-ASDF-28: 同梱テンプレートの内容から marker 直上の banner 行から末尾までと完全に一致する block を出力する"
          When call workspaces_rule_block "$TEMPLATE_CONTENT"
          The status should equal 0
          The output should equal "$(_expected_rule_block "$TEMPLATE")"
        End

        It "Then: [Normal] T-LIB-ASDF-33: 前の無関係なセクションを含めず marker 直上の banner 行から末尾までを出力する"
          When call workspaces_rule_block "$_TEMPLATE_TWO_SECTIONS"
          The status should equal 0
          The output should equal "$_BLOCK_OF_TWO_SECTIONS"
          The output should not include "Unrelated section"
        End
      End
    End

    Describe "Given: marker 行を持たないテンプレートの内容"
      Describe "When: 異常系"
        It "Then: [Error] T-LIB-ASDF-29: 何も出力せず status 1 で終わる"
          When call workspaces_rule_block "$_TEMPLATE_MARKERLESS"
          The status should equal 1
          The output should equal ""
        End
      End
    End

    Describe "Given: marker 行はあるが、その上に banner 行がないテンプレートの内容"
      Describe "When: エッジケース"
        It "Then: [Edge] T-LIB-ASDF-35: block の開始位置がないため何も出力せず status 1 で終わる"
          When call workspaces_rule_block "$_TEMPLATE_MARKER_NO_BANNER"
          The status should equal 1
          The output should equal ""
        End
      End
    End
  End
End
