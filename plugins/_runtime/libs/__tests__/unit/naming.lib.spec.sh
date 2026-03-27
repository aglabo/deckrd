#!/usr/bin/env bash
# src: ./plugins/_runtime/libs/__tests__/naming.lib.spec.sh
# @(#) : ShellSpec tests for naming.lib.sh
#
# Copyright (c) 2026- aglabo <https://github.com/aglabo>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

# shellcheck disable=SC1091

_RUNTIME_LIBS_DIR="$(cd "${SHELLSPEC_PROJECT_ROOT}/plugins/_runtime/libs" && pwd)"

Include "../spec_helper.sh"

. "${_RUNTIME_LIBS_DIR}/naming.lib.sh"

Describe "naming.lib.sh"

  Describe "naming.lib.sh loading"
    Describe "When: スクリプトを読み込む"
      It "Then: [Normal] hacker_random 関数が存在する"
        When call type hacker_random
        The status should equal 0
        The output should include "hacker_random"
      End
    End
  End

  Describe "hacker_random"
    Describe "Given: デフォルトの hackers.dic が存在する"
      Before "PROJECT_ROOT=${SHELLSPEC_PROJECT_ROOT}"

      Describe "When: hacker_random を引数なしで呼ぶ"
        It "Then: [Normal] 空文字でない名前が返る"
          When call hacker_random
          The status should equal 0
          The output should not equal ""
        End

        It "Then: [Normal] 返値が hackers.dic 内のエントリである"
          result=$(hacker_random)
          When call grep -qx "$result" "${SHELLSPEC_PROJECT_ROOT}/plugins/_generated/hackers.dic"
          The status should equal 0
        End
      End
    End

    Describe "Given: 存在しないファイルパスを指定する"
      Describe "When: hacker_random に存在しないパスを渡す"
        It "Then: [Error] status=1 を返し stdout にエラーメッセージが出力される"
          When call hacker_random "/no/such/file.dic"
          The status should equal 1
          The output should include "file not found"
        End
      End
    End

    Describe "Given: カスタム .dic ファイルを用意する"
      Before "setup_tmpdir"
      After "teardown_tmpdir"

      Describe "When: hacker_random にカスタムファイルを渡す"
        It "Then: [Normal] ファイル内のエントリが返る"
          custom_dic="${NAMING_TMPDIR}/custom.dic"
          printf '# comment\nalice\nbob\n' >"$custom_dic"
          result=$(hacker_random "$custom_dic")
          When call grep -qx "$result" "$custom_dic"
          The status should equal 0
        End
      End
    End
  End

  Describe "generate_filename"
    Describe "naming.lib.sh loading"
      Describe "When: スクリプトを読み込む"
        It "Then: [Normal] generate_filename 関数が存在する"
          When call type generate_filename
          The status should equal 0
          The output should include "generate_filename"
        End
      End
    End

    Describe "Given: PROJECT_ROOT が設定されており hackers.dic が存在する"
      Before "PROJECT_ROOT=${SHELLSPEC_PROJECT_ROOT}"

      Describe "When: generate_filename に slug と postfix を渡す"
        It "Then: [Normal] status=0 を返し出力が空でない"
          When call generate_filename "myfile" "doc"
          The status should equal 0
          The output should not equal ""
        End

        It "Then: [Normal] 出力が <slug>-<token>-<timestamp>-<hash>-<postfix> 形式に一致する"
          When call generate_filename "myfile" "doc"
          The output should match pattern "myfile-[a-z0-9-][a-z0-9-]*-[0-9][0-9][0-9][0-9][0-9][0-9]-[0-9][0-9][0-9][0-9][0-9][0-9]-[0-9a-f][0-9a-f][0-9a-f][0-9a-f]-doc"
        End

        It "Then: [Normal] hash 部分が 16進数4桁 (仕様固定) に一致する"
          When call generate_filename "myfile" "doc"
          The output should match pattern "*-[0-9a-f][0-9a-f][0-9a-f][0-9a-f]-doc"
        End
      End
    End

    Describe "Given: PROJECT_ROOT が未設定"
      Before "unset PROJECT_ROOT"

      Describe "When: generate_filename を呼ぶ"
        It "Then: [Error] status=1 を返す"
          When call generate_filename "myfile" "doc"
          The status should equal 1
        End
      End
    End

    Describe "Given: キャッシュディレクトリ設定済みで PROJECT_ROOT が有効"
      Before "setup_naming_cache"
      Before "PROJECT_ROOT=${SHELLSPEC_PROJECT_ROOT}"
      After "teardown_naming_cache"

      Describe "When: generate_filename を呼ぶ"
        It "Then: [Normal] キャッシュディレクトリが作成される"
          When call generate_filename "myfile" "doc"
          The status should equal 0
          The output should not equal ""
          The path "${_FILENAME_CACHE_DIR}" should be directory
        End

        It "Then: [Normal] 生成されたファイル名がキャッシュに存在する"
          result=$(generate_filename "myfile" "doc")
          The path "${_FILENAME_CACHE_DIR}/${result}" should be exist
        End
      End
    End

    Describe "Given: generate_filename で登録済みの名前が存在する (衝突回避)"
      Before "setup_naming_cache"
      Before "PROJECT_ROOT=${SHELLSPEC_PROJECT_ROOT}"
      After "teardown_naming_cache"

      # Mock: _generate_filename を固定値シーケンスで上書きする
      # generate_filename を1回呼ぶと "myfile-fixed-...-doc" がキャッシュ登録される
      # 2回目の generate_filename 呼び出しでは同じ固定値が1回目候補になり衝突 →
      # 2回目候補 "myfile-other-...-doc" が返る
      setup_collision_mock() {
        _MOCK_SEQ_FILE="${_FILENAME_CACHE_DIR}/.mock_seq"
        mkdir -p "${_FILENAME_CACHE_DIR}"
        printf '0' >"${_MOCK_SEQ_FILE}"
        # shellcheck disable=SC2329
        _generate_filename() {
          local seq
          seq=$(cat "${_MOCK_SEQ_FILE}")
          printf '%d' $(( seq + 1 )) >"${_MOCK_SEQ_FILE}"
          if [[ "$seq" -eq 0 || "$seq" -eq 2 ]]; then
            printf '%s' "myfile-fixed-260101-000000-abcd-doc"
          else
            printf '%s' "myfile-other-260101-000001-1234-doc"
          fi
        }
      }

      # generate_filename を1回呼んで "myfile-fixed-...-doc" をキャッシュに登録する
      register_first_filename() {
        generate_filename "myfile" "doc" >/dev/null
      }

      Describe "When: generate_filename で登録し、同じ候補が返る状態で再度呼ぶ"
        Before "setup_collision_mock"
        Before "register_first_filename"

        It "Then: [Normal] status=0 を返しファイル名が出力される"
          When call generate_filename "myfile" "doc"
          The status should equal 0
          The output should not equal ""
        End

        It "Then: [Normal] 登録済みの候補と異なるファイル名が返る"
          When call generate_filename "myfile" "doc"
          The output should not equal "myfile-fixed-260101-000000-abcd-doc"
        End

        It "Then: [Normal] 返されたファイル名がキャッシュに登録される"
          result=$(generate_filename "myfile" "doc")
          The path "${_FILENAME_CACHE_DIR}/${result}" should be exist
        End
      End
    End

    Describe "Given: すべての候補が登録済みでリトライ上限を超える"
      Before "setup_naming_cache"
      After "teardown_naming_cache"

      # Mock: _generate_filename が常に同じ固定値を返す
      # generate_filename を1回呼ぶと "myfile-fixed-...-doc" がキャッシュ登録される
      # 以降の呼び出しはすべて同じ値が衝突し、max_retries に達してエラーになる
      setup_always_same_mock() {
        mkdir -p "${_FILENAME_CACHE_DIR}"
        # shellcheck disable=SC2329
        _generate_filename() {
          printf '%s' "myfile-fixed-260101-000000-abcd-doc"
        }
        export NAMING_MAX_RETRIES=3
      }

      teardown_always_same_mock() {
        unset NAMING_MAX_RETRIES
      }

      register_fixed_filename() {
        generate_filename "myfile" "doc" >/dev/null
      }

      Describe "When: リトライ上限を超えるまですべての候補が登録済み"
        Before "setup_always_same_mock"
        Before "register_fixed_filename"
        After "teardown_always_same_mock"

        It "Then: [Error] status=1 を返しエラーが stdout に出力される"
          When call generate_filename "myfile" "doc"
          The status should equal 1
          The output should include "max retries"
        End

        It "Then: [Error] stdout に max retries exceeded メッセージが出力される"
          When call generate_filename "myfile" "doc"
          The status should equal 1
          The output should include "max retries"
        End

        It "Then: [Error] stdout に slug 名 myfile が含まれる"
          When call generate_filename "myfile" "doc"
          The status should equal 1
          The output should include "myfile"
        End
      End
    End
  End

  Describe "generate_filename 並列実行 (race condition)"
    Before "setup_naming_cache"
    Before "PROJECT_ROOT=${SHELLSPEC_PROJECT_ROOT}"
    After "teardown_naming_cache"

    Describe "When: 10並列 × 20回 generate_filename を同時実行する"
      It "Then: [Normal] 生成されたファイル名に重複がない"
        mkdir -p "${_FILENAME_CACHE_DIR}"
        seq 1 20 | xargs -P 10 -I{} bash -c "
          export _FILENAME_CACHE_DIR='${_FILENAME_CACHE_DIR}'
          export PROJECT_ROOT='${SHELLSPEC_PROJECT_ROOT}'
          source '${_RUNTIME_LIBS_DIR}/naming.lib.sh'
          generate_filename 'parallel' 'doc'
        " >"${_FILENAME_CACHE_DIR}/.parallel_results" 2>/dev/null
        result=$(sort "${_FILENAME_CACHE_DIR}/.parallel_results" | uniq -d)
        When call test -z "$result"
        The status should equal 0
      End

      It "Then: [Normal] 生成されたファイル名が全てキャッシュに存在する"
        mkdir -p "${_FILENAME_CACHE_DIR}"
        seq 1 20 | xargs -P 10 -I{} bash -c "
          export _FILENAME_CACHE_DIR='${_FILENAME_CACHE_DIR}'
          export PROJECT_ROOT='${SHELLSPEC_PROJECT_ROOT}'
          source '${_RUNTIME_LIBS_DIR}/naming.lib.sh'
          generate_filename 'parallel' 'doc'
        " >"${_FILENAME_CACHE_DIR}/.parallel_results2" 2>/dev/null
        missing=0
        while IFS= read -r name; do
          [[ -f "${_FILENAME_CACHE_DIR}/${name}" ]] || missing=1
        done <"${_FILENAME_CACHE_DIR}/.parallel_results2"
        When call test "$missing" -eq 0
        The status should equal 0
      End
    End
  End

  Describe "_try_create_cache_file"
    Before "setup_naming_cache"
    After "teardown_naming_cache"

    Describe "Given: キャッシュディレクトリが設定されている"

      Describe "When: 存在しないファイル名で呼ぶ (新規作成)"
        It "Then: [Normal] status=0 を返す"
          When call _try_create_cache_file "newfile-test-260101-000000-abcd-doc"
          The status should equal 0
        End

        It "Then: [Normal] キャッシュファイルが作成される"
          _try_create_cache_file "newfile-test-260101-000000-abcd-doc"
          The path "${_FILENAME_CACHE_DIR}/newfile-test-260101-000000-abcd-doc" should be exist
        End
      End

      Describe "When: 同じファイル名で2回目を呼ぶ (既存ファイル)"
        Before "_try_create_cache_file 'existing-test-260101-000000-abcd-doc'"

        It "Then: [Error] status=1 を返す"
          When call _try_create_cache_file "existing-test-260101-000000-abcd-doc"
          The status should equal 1
        End
      End

    End
  End

End
