#!/usr/bin/env bash
# src: ./skills/deckrd/skills/deckrd/scripts/libs/__tests__/unit/naming.lib.unit.spec.sh
# @(#) : ShellSpec tests for naming.lib.sh
#
# Copyright (c) 2026- aglabo <https://github.com/aglabo>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

# shellcheck disable=SC1091

_RUNTIME_LIBS_DIR="$(cd "${SHELLSPEC_PROJECT_ROOT}/skills/deckrd/skills/deckrd/scripts/libs" && pwd)"

Include "../spec_helper.sh"

. "${_RUNTIME_LIBS_DIR}/naming.lib.sh"

Describe "naming.lib.sh"

  Describe "T-LIB-NLD: naming.lib.sh loading"
    Describe "When: スクリプトを読み込む"
      It "Then: [Normal] T-LIB-NLD-01: hacker_random 関数が存在する"
        When call type hacker_random
        The status should equal 0
        The output should include "hacker_random"
      End
    End
  End

  Describe "T-LIB-NHR: hacker_random"
    Describe "Given: デフォルトの hackers.dic が存在する"
      Before "PROJECT_ROOT=${SHELLSPEC_PROJECT_ROOT}"

      Describe "When: hacker_random を引数なしで呼ぶ"
        It "Then: [Normal] T-LIB-NHR-01: 空文字でない名前が返る"
          When call hacker_random
          The status should equal 0
          The output should not equal ""
        End

        It "Then: [Normal] T-LIB-NHR-02: 返値が hackers.dic 内のエントリである"
          result=$(hacker_random)
          When call grep -qx "$result" "${SHELLSPEC_PROJECT_ROOT}/skills/deckrd/_generated/hackers.dic"
          The status should equal 0
        End
      End
    End

    Describe "Given: 存在しないファイルパスを指定する"
      Describe "When: hacker_random に存在しないパスを渡す"
        It "Then: [Error] T-LIB-NHR-03: status=1 を返し stderr にエラーメッセージが出力される"
          When call hacker_random "/no/such/file.dic"
          The status should equal 1
          The error should include "file not found"
        End
      End
    End

    Describe "Given: カスタム .dic ファイルを用意する"
      Before "setup_tmpdir"
      After "teardown_tmpdir"

      Describe "When: hacker_random にカスタムファイルを渡す"
        It "Then: [Normal] T-LIB-NHR-04: ファイル内のエントリが返る"
          custom_dic="${NAMING_TMPDIR}/custom.dic"
          printf '# comment\nalice\nbob\n' >"$custom_dic"
          result=$(hacker_random "$custom_dic")
          When call grep -qx "$result" "$custom_dic"
          The status should equal 0
        End
      End
    End
  End

  Describe "T-LIB-NAR: adjective_random"
    Describe "naming.lib.sh loading"
      Describe "When: スクリプトを読み込む"
        It "Then: [Normal] T-LIB-NAR-01: adjective_random 関数が存在する"
          When call type adjective_random
          The status should equal 0
          The output should include "adjective_random"
        End
      End
    End

    Describe "Given: _ADJECTIVES 配列が定義されている"
      Describe "When: adjective_random を引数なしで呼ぶ"
        It "Then: [Normal] T-LIB-NAR-02: 空文字でない adjective が返る"
          When call adjective_random
          The status should equal 0
          The output should not equal ""
        End

        It "Then: [Normal] T-LIB-NAR-03: 返値が _ADJECTIVES 配列内の語である"
          _check_in_adjectives() {
            local word
            for word in "${_ADJECTIVES[@]}"; do
              [[ "$word" == "$1" ]] && return 0
            done
            return 1
          }
          result=$(adjective_random)
          When call _check_in_adjectives "$result"
          The status should equal 0
        End

        It "Then: [Normal] T-LIB-NAR-04: 30回呼び出すと 2種類以上の異なる値が返る (ランダム性)"
          result=$(for _ in $(seq 1 30); do adjective_random; done | sort -u | wc -l | tr -d ' ')
          When call test "$result" -gt 1
          The status should equal 0
        End
      End
    End
  End

  Describe "T-LIB-NGF: generate_filename"
    Describe "naming.lib.sh loading"
      Describe "When: スクリプトを読み込む"
        It "Then: [Normal] T-LIB-NGF-01: generate_filename 関数が存在する"
          When call type generate_filename
          The status should equal 0
          The output should include "generate_filename"
        End
      End
    End

    Describe "Given: PROJECT_ROOT が設定されており hackers.dic が存在する"
      Before "PROJECT_ROOT=${SHELLSPEC_PROJECT_ROOT}"

      Describe "When: generate_filename に slug と postfix を渡す"
        It "Then: [Normal] T-LIB-NGF-02: status=0 を返し出力が空でない"
          When call generate_filename "myfile" "doc"
          The status should equal 0
          The output should not equal ""
        End

        It "Then: [Normal] T-LIB-NGF-03: 出力が <slug>-<token>-<timestamp>-<hash>-<postfix> 形式に一致する"
          When call generate_filename "myfile" "doc"
          The output should match pattern "myfile-[a-z0-9-][a-z0-9-]*-[0-9][0-9][0-9][0-9][0-9][0-9]-[0-9][0-9][0-9][0-9][0-9][0-9]-[0-9a-f][0-9a-f][0-9a-f][0-9a-f]-doc"
        End

        It "Then: [Normal] T-LIB-NGF-04: hash 部分が 16進数4桁 (仕様固定) に一致する"
          When call generate_filename "myfile" "doc"
          The output should match pattern "*-[0-9a-f][0-9a-f][0-9a-f][0-9a-f]-doc"
        End
      End
    End

    Describe "Given: PROJECT_ROOT が未設定"
      Before "unset PROJECT_ROOT"

      Describe "When: generate_filename を呼ぶ"
        It "Then: [Error] T-LIB-NGF-05: status=1 を返す"
          When call generate_filename "myfile" "doc"
          The status should equal 1
          The stderr should include "Error:"
        End
      End
    End

    Describe "Given: キャッシュディレクトリ設定済みで PROJECT_ROOT が有効"
      Before "setup_naming_cache"
      Before "PROJECT_ROOT=${SHELLSPEC_PROJECT_ROOT}"
      After "teardown_naming_cache"

      Describe "When: generate_filename を呼ぶ"
        It "Then: [Normal] T-LIB-NGF-06: キャッシュディレクトリが作成される"
          When call generate_filename "myfile" "doc"
          The status should equal 0
          The output should not equal ""
          The path "${_FILENAME_CACHE_DIR}" should be directory
        End

        It "Then: [Normal] T-LIB-NGF-07: 生成されたファイル名がキャッシュに存在する"
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

        It "Then: [Normal] T-LIB-NGF-08: status=0 を返しファイル名が出力される"
          When call generate_filename "myfile" "doc"
          The status should equal 0
          The output should not equal ""
        End

        It "Then: [Normal] T-LIB-NGF-09: 登録済みの候補と異なるファイル名が返る"
          When call generate_filename "myfile" "doc"
          The output should not equal "myfile-fixed-260101-000000-abcd-doc"
        End

        It "Then: [Normal] T-LIB-NGF-10: 返されたファイル名がキャッシュに登録される"
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

        It "Then: [Error] T-LIB-NGF-11: status=1 を返しエラーが stderr に出力される"
          When call generate_filename "myfile" "doc"
          The status should equal 1
          The error should include "max retries"
        End

        It "Then: [Error] T-LIB-NGF-12: stderr に max retries exceeded メッセージが出力される"
          When call generate_filename "myfile" "doc"
          The status should equal 1
          The error should include "max retries"
        End

        It "Then: [Error] T-LIB-NGF-13: stderr に slug 名 myfile が含まれる"
          When call generate_filename "myfile" "doc"
          The status should equal 1
          The error should include "myfile"
        End
      End
    End
  End

  Describe "T-LIB-NGFR: generate_filename 並列実行 (race condition)"
    Before "setup_naming_cache"
    Before "PROJECT_ROOT=${SHELLSPEC_PROJECT_ROOT}"
    After "teardown_naming_cache"

    # Mock: token と timestamp だけを固定する。$(date +%N) は実時刻のまま通す。
    # slug/token/timestamp が固定されるので $base は 2 回とも同一になり、
    # 出力を分けられるのは hash に混ぜた $RANDOM と $(date +%N) だけになる。
    # +%N まで凍らせると差が $RANDOM の 1 源だけになり、同じ値を 2 回引いた時に
    # 出力が一致して間欠失敗する。bash のサブシェル再シード挙動にも依存しなくなる。
    # 残る不確実性は hash を 16 進 4 桁に畳むことによる 1/65536 の一致だけで、
    # これは名前の形式が仕様で固定されている以上テスト側では消せない。
    setup_fixed_entropy_mock() {
      # shellcheck disable=SC2329
      hacker_random() { printf '%s' 'knuth'; }
      # shellcheck disable=SC2329
      date() {
        case "${1}" in
          +%N) command date +%N ;;
          *) printf '%s' '260101-000000' ;;
        esac
      }
    }

    # generate_filename を並列に走らせ、生成された名前を 1 件 1 行で結果ファイルに書き出す。
    # 実装側の printf '%s' は改行を出さないため、改行はワーカー側で付ける。
    # ワーカーは generate_filename が失敗したら即 exit 1 し、xargs に失敗を伝える。
    #
    # @arg $1 int    並列度 (xargs -P)
    # @arg $2 int    実行件数
    # @arg $3 int    (任意) ワーカーに渡す NAMING_MAX_RETRIES。省略時はライブラリ既定値
    # @set _PARALLEL_RESULTS string 結果ファイルのパス (キャッシュ外に置く)
    # @set _PARALLEL_STATUS  int    xargs の終了コード (ワーカーが 1 件でも失敗すると 123)
    # @set _PARALLEL_STDERR  string ワーカーの stderr を集めたファイルのパス。
    #                           捨てずに残すのは、終了コードだけでは失敗の原因を
    #                           区別できない (パス誤り・コマンド不在でも 123 になる) ため
    run_parallel_generate() {
      local jobs="${1}"
      local count="${2}"
      local max_retries="${3:-}"
      local retries_export=""
      [[ -n "$max_retries" ]] && retries_export="export NAMING_MAX_RETRIES='${max_retries}'"

      _PARALLEL_RESULTS="${NAMING_TMPDIR}/parallel-results"
      _PARALLEL_STDERR="${NAMING_TMPDIR}/parallel-stderr"
      mkdir -p "${_FILENAME_CACHE_DIR}"
      seq 1 "$count" | xargs -P "$jobs" -I{} bash -c "
        export _FILENAME_CACHE_DIR='${_FILENAME_CACHE_DIR}'
        export PROJECT_ROOT='${SHELLSPEC_PROJECT_ROOT}'
        ${retries_export}
        source '${_RUNTIME_LIBS_DIR}/naming.lib.sh'
        name=\$(generate_filename 'parallel' 'doc') || exit 1
        printf '%s\n' \"\$name\"
      " >"${_PARALLEL_RESULTS}" 2>"${_PARALLEL_STDERR}"
      _PARALLEL_STATUS=$?
    }

    Describe "When: token と timestamp を固定して _generate_filename を 2 回呼ぶ"
      Before "setup_fixed_entropy_mock"

      It "Then: [Normal] T-LIB-NGF-16: 同一 token/timestamp でも呼び出しごとに異なる候補名を返す"
        # $() は副シェルになり $RANDOM の進み方が読みにくいため、出力はファイルで受ける
        _generate_filename 'parallel' 'doc' >"${NAMING_TMPDIR}/ngf16-first"
        _generate_filename 'parallel' 'doc' >"${NAMING_TMPDIR}/ngf16-second"
        first=$(cat "${NAMING_TMPDIR}/ngf16-first")
        second=$(cat "${NAMING_TMPDIR}/ngf16-second")
        When call test "$first" != "$second"
        The status should equal 0
      End
    End

    Describe "When: 10並列 × 20回 generate_filename を同時実行する"
      Before "run_parallel_generate 10 20"

      # T-LIB-NGF-17 / -18 は症状カナリアであり、レースの guard ではない。
      # 並列衝突の再現は確率的で、hash からエントロピー項を外しても両者は PASS しうる。
      # この欠陥を決定論的に守るのは T-LIB-NGF-16 だけ。
      # ここで押さえるのは「ワーカーが非 0 で落ちる」という唯一のユーザー可視症状で、
      # 追加コストは既存の並列実行 1 回分しかない。
      It "Then: [Normal] T-LIB-NGF-17: 全ワーカーが成功し xargs の終了コードが 0 になる"
        When call test "$_PARALLEL_STATUS" -eq 0
        The status should equal 0
      End

      It "Then: [Normal] T-LIB-NGF-18: 生成されたファイル名が 20 件そろう"
        generated=$(grep -c '^parallel-' "${_PARALLEL_RESULTS}")
        When call test "$generated" -eq 20
        The status should equal 0
      End

      It "Then: [Normal] T-LIB-NGF-14: 生成されたファイル名に重複がない"
        duplicated=$(sort "${_PARALLEL_RESULTS}" | uniq -d)
        When call test -z "$duplicated"
        The status should equal 0
      End

      It "Then: [Normal] T-LIB-NGF-15: 生成されたファイル名が全てキャッシュに存在する"
        missing=0
        while IFS= read -r name; do
          [[ -f "${_FILENAME_CACHE_DIR}/${name}" ]] || missing=1
        done <"${_PARALLEL_RESULTS}"
        When call test "$missing" -eq 0
        The status should equal 0
      End

      # 重複検査が vacuous pass でないことの裏付け。実装の printf '%s' は改行を出さないので、
      # ワーカーが改行を付けないと 20 件が 1 行に連結され、uniq -d が常に空になっていた
      It "Then: [Normal] T-LIB-NGF-19: 結果ファイルが 1 件 1 行の 20 行になる"
        lines=$(wc -l <"${_PARALLEL_RESULTS}" | tr -d ' ')
        When call test "$lines" -eq 20
        The status should equal 0
      End
    End

    # ワーカーにだけ NAMING_MAX_RETRIES=0 を渡す。ライブラリ既定値 5 は変更しない
    Describe "When: リトライ上限 0 のワーカーで 10並列 × 20回 実行する"
      Before "run_parallel_generate 10 20 0"

      # T-LIB-NGF-17 のステータス検査が vacuous でないことを示す example。
      # 終了コードだけを見ると source のパス誤りやコマンド不在でも 123 になるので、
      # 原因がリトライ枯渇であることを stderr のメッセージまで確かめる
      It "Then: [Error] T-LIB-NGF-20: リトライ枯渇が xargs の終了コード 123 と stderr に現れる"
        When call test "$_PARALLEL_STATUS" -eq 123
        The status should equal 0
        The contents of file "${_PARALLEL_STDERR}" should include "max retries"
      End
    End

    Describe "When: 1並列 × 1回 generate_filename を実行する (並列度の下限)"
      Before "run_parallel_generate 1 1"

      It "Then: [Edge] T-LIB-NGF-21: 成功し結果 1 行・キャッシュ 1 件になる"
        lines=$(wc -l <"${_PARALLEL_RESULTS}" | tr -d ' ')
        cached=$(find "${_FILENAME_CACHE_DIR}" -type f | wc -l | tr -d ' ')
        When call printf '%s %s %s' "$_PARALLEL_STATUS" "$lines" "$cached"
        The output should equal "0 1 1"
      End
    End
  End

  Describe "T-LIB-NTCC: _try_create_cache_file"
    Before "setup_naming_cache"
    After "teardown_naming_cache"

    Describe "Given: キャッシュディレクトリが設定されている"

      Describe "When: 存在しないファイル名で呼ぶ (新規作成)"
        It "Then: [Normal] T-LIB-NTCC-01: status=0 を返す"
          When call _try_create_cache_file "newfile-test-260101-000000-abcd-doc"
          The status should equal 0
        End

        It "Then: [Normal] T-LIB-NTCC-02: キャッシュファイルが作成される"
          _try_create_cache_file "newfile-test-260101-000000-abcd-doc"
          The path "${_FILENAME_CACHE_DIR}/newfile-test-260101-000000-abcd-doc" should be exist
        End
      End

      Describe "When: 同じファイル名で2回目を呼ぶ (既存ファイル)"
        Before "_try_create_cache_file 'existing-test-260101-000000-abcd-doc'"

        It "Then: [Error] T-LIB-NTCC-03: status=1 を返す"
          When call _try_create_cache_file "existing-test-260101-000000-abcd-doc"
          The status should equal 1
        End
      End

    End
  End

End
