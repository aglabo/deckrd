#!/usr/bin/env bash
# kv-store.lib.path.spec.sh - ShellSpec unit tests for kv-store.lib.sh (path resolution)
#
# Copyright (c) 2026- atsushifx <https://github.com/atsushifx>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

# shellcheck disable=SC1090,SC1091

_RUNTIME_LIBS_DIR="$(cd "${SHELLSPEC_PROJECT_ROOT}/plugins/_runtime/libs" && pwd)"

Include "../spec_helper.sh"

. "${_RUNTIME_LIBS_DIR}/bootstrap.lib.sh" --no-finalize
. "${_RUNTIME_LIBS_DIR}/kv-store.lib.sh"

Describe "kv-store.lib.sh"

  Describe "kv-store.lib.sh loading"
    Describe "When: スクリプトを読み込む"
      It "Then: [Normal] kv_init 関数が存在する"
        When call type kv_init
        The status should equal 0
        The output should include "kv_init"
      End

      It "Then: [Normal] kv_get 関数が存在する"
        When call type kv_get
        The status should equal 0
        The output should include "kv_get"
      End

      It "Then: [Normal] kv_set 関数が存在する"
        When call type kv_set
        The status should equal 0
        The output should include "kv_set"
      End

      It "Then: [Normal] kv_load 関数が存在する"
        When call type kv_load
        The status should equal 0
        The output should include "kv_load"
      End

      It "Then: [Normal] kv_save 関数が存在する"
        When call type kv_save
        The status should equal 0
        The output should include "kv_save"
      End

      It "Then: [Normal] kv_all 関数が存在する"
        When call type kv_all
        The status should equal 0
        The output should include "kv_all"
      End
    End
  End

  Describe "_kv_file_path"
    Describe "Given: Windows パス（バックスラッシュ区切り）"
      Describe "When: _kv_file_path を呼ぶ"
        It "Then: [Normal] .\\session は ./session.kv になる"
          When call _kv_file_path '.\session'
          The status should equal 0
          The output should equal "./session.kv"
        End

        It "Then: [Normal] foo\\bar\\session は foo/bar/session.kv になる"
          When call _kv_file_path 'foo\bar\session'
          The status should equal 0
          The output should equal "foo/bar/session.kv"
        End

        It "Then: [Edge] .\\session.json は ./session.kv になる"
          When call _kv_file_path '.\session.json'
          The status should equal 0
          The output should equal "./session.kv"
        End
      End
    End

    Describe "Given: パス + ファイル名の形式"
      Describe "When: _kv_file_path を呼ぶ"
        It "Then: [Normal] ディレクトリパスが保持され .kv が付加される"
          When call _kv_file_path "/foo/bar/session"
          The status should equal 0
          The output should equal "/foo/bar/session.kv"
        End

        It "Then: [Normal] 深いディレクトリパスが保持される"
          When call _kv_file_path "/path/to/dir/name"
          The status should equal 0
          The output should equal "/path/to/dir/name.kv"
        End

        It "Then: [Edge] 隠しディレクトリを含むパスでもディレクトリ部が保持される"
          When call _kv_file_path "/home/user/.config/.project.json"
          The status should equal 0
          The output should equal "/home/user/.config/.project.kv"
        End
      End
    End

    Describe "Given: ファイル名のみ（ディレクトリパスなし）"
      Describe "When: _kv_file_path を呼ぶ"
        It "Then: [Normal] ディレクトリなしのファイル名はそのまま .kv が付加される"
          When call _kv_file_path "session"
          The status should equal 0
          The output should equal "session.kv"
        End

        It "Then: [Edge] ドット始まりファイル名のみはそのまま .kv が付加される"
          When call _kv_file_path ".project"
          The status should equal 0
          The output should equal ".project.kv"
        End
      End
    End

    Describe "Given: ./ プレフィックス付きのパス"
      Describe "When: _kv_file_path を呼ぶ"
        It "Then: [Normal] ./session は ./session.kv になる"
          When call _kv_file_path "./session"
          The status should equal 0
          The output should equal "./session.kv"
        End

        It "Then: [Edge] ./.project は ./.project.kv になる"
          When call _kv_file_path "./.project"
          The status should equal 0
          The output should equal "./.project.kv"
        End
      End
    End

    Describe "Given: / 終わりのパス（ファイル名なし）"
      Describe "When: _kv_file_path を呼ぶ"
        It "Then: [Error] /foo/bar/ は return 1 かつ stderr に Error: を出力する"
          When call _kv_file_path "/foo/bar/"
          The status should equal 1
          The stderr should include "Error:"
        End

        It "Then: [Error] / のみは return 1 かつ stderr に Error: を出力する"
          When call _kv_file_path "/"
          The status should equal 1
          The stderr should include "Error:"
        End
      End
    End

    Describe "Given: 不正な basename を含むパス（ディレクトリ付き）"
      Describe "When: _kv_file_path を呼ぶ"
        It "Then: [Error] 数字始まりの basename は return 1 かつ Error: を出力する"
          When call _kv_file_path "/foo/bar/1invalid"
          The status should equal 1
          The stderr should include "Error:"
        End

        It "Then: [Error] スペースを含む basename は return 1 かつ Error: を出力する"
          When call _kv_file_path "/foo/bar/my file"
          The status should equal 1
          The stderr should include "Error:"
        End

        It "Then: [Error] @ を含む basename は return 1 かつ Error: を出力する"
          When call _kv_file_path "/foo/bar/my@store"
          The status should equal 1
          The stderr should include "Error:"
        End
      End
    End

    Describe "Given: 不正な basename のみ（ディレクトリなし）"
      Describe "When: _kv_file_path を呼ぶ"
        It "Then: [Error] 数字始まりのファイル名のみは return 1 かつ Error: を出力する"
          When call _kv_file_path "1invalid"
          The status should equal 1
          The stderr should include "Error:"
        End

        It "Then: [Error] スペースを含むファイル名のみは return 1 かつ Error: を出力する"
          When call _kv_file_path "my file"
          The status should equal 1
          The stderr should include "Error:"
        End
      End
    End
  End

  Describe "kv_store_path"
    Describe "Given: DECKRD_LOCAL_DATA=/tmp/deckrd-test"
      Before "export DECKRD_LOCAL_DATA=/tmp/deckrd-test"

      Describe "Given: ファイル名のみ（ディレクトリなし）"
        Describe "When: kv_store_path を呼ぶ"
          It "Then: [Normal] session → DECKRD_LOCAL_DATA/session.kv になる"
            When call kv_store_path "session"
            The status should equal 0
            The output should equal "/tmp/deckrd-test/session.kv"
          End

          It "Then: [Normal] .project → DECKRD_LOCAL_DATA/.project.kv になる"
            When call kv_store_path ".project"
            The status should equal 0
            The output should equal "/tmp/deckrd-test/.project.kv"
          End

          It "Then: [Normal] session.json → DECKRD_LOCAL_DATA/session.kv になる"
            When call kv_store_path "session.json"
            The status should equal 0
            The output should equal "/tmp/deckrd-test/session.kv"
          End
        End
      End

      Describe "Given: ディレクトリ付きパス"
        Describe "When: kv_store_path を呼ぶ"
          It "Then: [Normal] /foo/bar/session → /foo/bar/session.kv になる（DECKRD_LOCAL_DATA を使わない）"
            When call kv_store_path "/foo/bar/session"
            The status should equal 0
            The output should equal "/foo/bar/session.kv"
          End

          It "Then: [Normal] ./session → ./session.kv になる"
            When call kv_store_path "./session"
            The status should equal 0
            The output should equal "./session.kv"
          End

          It "Then: [Normal] /foo/bar/session.json → /foo/bar/session.kv になる"
            When call kv_store_path "/foo/bar/session.json"
            The status should equal 0
            The output should equal "/foo/bar/session.kv"
          End
        End
      End

      Describe "Given: Windows パス（バックスラッシュ区切り）"
        Describe "When: kv_store_path を呼ぶ"
          It "Then: [Normal] foo\\bar\\session → foo/bar/session.kv になる"
            When call kv_store_path 'foo\bar\session'
            The status should equal 0
            The output should equal "foo/bar/session.kv"
          End
        End
      End

      Describe "Given: エラーケース"
        Describe "When: kv_store_path を呼ぶ"
          It "Then: [Error] /foo/bar/ は return 1 かつ Error: を出力する"
            When call kv_store_path "/foo/bar/"
            The status should equal 1
            The stderr should include "Error:"
          End

          It "Then: [Error] 数字始まりのファイル名のみは return 1 かつ Error: を出力する"
            When call kv_store_path "1invalid"
            The status should equal 1
            The stderr should include "Error:"
          End

          It "Then: [Error] 不正な basename を含むパスは return 1 かつ Error: を出力する"
            When call kv_store_path "/foo/bar/1invalid"
            The status should equal 1
            The stderr should include "Error:"
          End
        End
      End
    End

    Describe "Given: DECKRD_LOCAL_DATA 未設定"
      Before "unset DECKRD_LOCAL_DATA"

      Describe "Given: ファイル名のみ（ディレクトリなし）"
        Describe "When: kv_store_path を呼ぶ"
          It "Then: [Error] return 1 かつ stderr に Error: を出力する"
            When call kv_store_path "session"
            The status should equal 1
            The stderr should include "Error:"
          End
        End
      End

      Describe "Given: ディレクトリ付きパス"
        Describe "When: kv_store_path を呼ぶ"
          It "Then: [Normal] DECKRD_LOCAL_DATA に依存しないため return 0 を返す"
            When call kv_store_path "/foo/bar/session"
            The status should equal 0
            The output should equal "/foo/bar/session.kv"
          End
        End
      End
    End
  End

  Describe "_kv_normalize_filename"
    Describe "Given: 通常ファイル名（ドットなし/拡張子あり）"
      Describe "When: _kv_normalize_filename を呼ぶ"
        It "Then: [Normal] 拡張子なしのファイル名はそのまま返る"
          When call _kv_normalize_filename "session"
          The status should equal 0
          The output should equal "session"
        End

        It "Then: [Normal] .json 拡張子が除去される"
          When call _kv_normalize_filename "kv.json"
          The status should equal 0
          The output should equal "kv"
        End

        It "Then: [Normal] 拡張子なしのファイル名 (name) はそのまま返る"
          When call _kv_normalize_filename "name"
          The status should equal 0
          The output should equal "name"
        End
      End
    End

    Describe "Given: エッジケース（複数ドット/ドット始まり）"
      Describe "When: _kv_normalize_filename を呼ぶ"
        It "Then: [Edge] 複数ドットのファイル名は最後の拡張子のみ除去される"
          When call _kv_normalize_filename "my.store.json"
          The status should equal 0
          The output should equal "my.store"
        End

        It "Then: [Edge] ドット始まりで拡張子なしはそのまま返る"
          When call _kv_normalize_filename ".project"
          The status should equal 0
          The output should equal ".project"
        End

        It "Then: [Edge] ドット始まり + 拡張子は拡張子のみ除去される"
          When call _kv_normalize_filename ".project.json"
          The status should equal 0
          The output should equal ".project"
        End

        It "Then: [Edge] .env.json は .env になる"
          When call _kv_normalize_filename ".env.json"
          The status should equal 0
          The output should equal ".env"
        End

        It "Then: [Edge] .env 拡張子なしはそのまま返る"
          When call _kv_normalize_filename ".env"
          The status should equal 0
          The output should equal ".env"
        End
      End
    End

    Describe "Given: 連続ドットを含むファイル名"
      Describe "When: _kv_normalize_filename を呼ぶ"
        It "Then: [Edge] a..json は連続ドットが正規化されて a になる"
          When call _kv_normalize_filename "a..json"
          The status should equal 0
          The output should equal "a"
        End

        It "Then: [Edge] my..store..json は my.store になる"
          When call _kv_normalize_filename "my..store..json"
          The status should equal 0
          The output should equal "my.store"
        End

        It "Then: [Edge] ..project は .project になる"
          When call _kv_normalize_filename "..project"
          The status should equal 0
          The output should equal ".project"
        End

        It "Then: [Edge] ...project.json は .project になる"
          When call _kv_normalize_filename "...project.json"
          The status should equal 0
          The output should equal ".project"
        End
      End
    End

    Describe "Given: 数字を含む有効なファイル名"
      Describe "When: _kv_normalize_filename を呼ぶ"
        It "Then: [Normal] アルファベット + 数字の名前はそのまま返る"
          When call _kv_normalize_filename "session1"
          The status should equal 0
          The output should equal "session1"
        End

        It "Then: [Normal] prefix + アルファベット + 数字の名前はそのまま返る"
          When call _kv_normalize_filename ".v1"
          The status should equal 0
          The output should equal ".v1"
        End

        It "Then: [Normal] バージョン形式の名前はそのまま返る"
          When call _kv_normalize_filename "v1.0"
          The status should equal 0
          The output should equal "v1"
        End
      End
    End

    Describe "Given: 不正なファイル名（バリデーションエラー）"
      Describe "When: _kv_normalize_filename を呼ぶ"
        It "Then: [Error] 空文字は return 1 かつ stderr に Error: を出力する"
          When call _kv_normalize_filename ""
          The status should equal 1
          The stderr should include "Error:"
        End

        It "Then: [Error] スペースを含む名前は return 1 かつ stderr に Error: を出力する"
          When call _kv_normalize_filename "my file"
          The status should equal 1
          The stderr should include "Error:"
        End

        It "Then: [Error] スラッシュを含む名前は return 1 かつ stderr に Error: を出力する"
          When call _kv_normalize_filename "foo/bar"
          The status should equal 1
          The stderr should include "Error:"
        End

        It "Then: [Error] @ を含む名前は return 1 かつ stderr に Error: を出力する"
          When call _kv_normalize_filename "my@store"
          The status should equal 1
          The stderr should include "Error:"
        End

        It "Then: [Error] . のみの名前は return 1 かつ stderr に Error: を出力する"
          When call _kv_normalize_filename "."
          The status should equal 1
          The stderr should include "Error:"
        End

        It "Then: [Error] .. の名前は return 1 かつ stderr に Error: を出力する"
          When call _kv_normalize_filename ".."
          The status should equal 1
          The stderr should include "Error:"
        End

        It "Then: [Error] __ の名前は return 1 かつ stderr に Error: を出力する"
          When call _kv_normalize_filename "__"
          The status should equal 1
          The stderr should include "Error:"
        End

        It "Then: [Error] 数字始まりの名前は return 1 かつ stderr に Error: を出力する"
          When call _kv_normalize_filename "1start"
          The status should equal 1
          The stderr should include "Error:"
        End
      End
    End
  End

End
