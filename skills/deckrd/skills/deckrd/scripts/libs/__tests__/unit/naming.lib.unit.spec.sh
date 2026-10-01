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

# --- 内部ヘルパー ---

# 定数

# _NHR_DECKRD_DIC - deckrd 本体の既定辞書。既定パス解決の Case で返値の所属を確かめる
_NHR_DECKRD_DIC="${SHELLSPEC_PROJECT_ROOT}/skills/deckrd/skills/deckrd/assets/dic/hackers.dic"

# _NHR_SYMLINK_HINT_KEYWORD - 辞書を使えない異常系で stderr に含まれるべきヒントの語
_NHR_SYMLINK_HINT_KEYWORD="symlink"

# 関数

# _nhr_fresh_hacker_random - 新しい bash プロセスで naming.lib.sh を source し hacker_random を呼ぶ
#
# 二重読み込みガード (_NAMING_LIB_LOADED) と source 時に解決される既定パスを
# Case ごとに作り直すため、現在のシェルではなく子プロセスで読み込む。
# PROJECT_ROOT は子プロセスで unset し、既定パスが PROJECT_ROOT に依存しないことを前提にする。
#
# @arg $1 string 前処理 (source の前に実行するコマンド。不要なら空文字)
# @arg $2 string source する naming.lib.sh のパス (相対パス可)
# @arg $3 string (optional) source 後・呼び出し前に実行するコマンド
# @stdout hacker_random の出力
# @stderr hacker_random のエラー出力
# @return hacker_random の終了ステータス (source 失敗時は 1)
_nhr_fresh_hacker_random() {
  local pre="${1}"
  local lib="${2}"
  local post="${3:-:}"
  bash -c "unset PROJECT_ROOT; ${pre:-:}; . '${lib}' || exit 1; ${post}; hacker_random"
}

# _nhr_symlink_unsupported - 実リンクを作れない環境かを調べる (Skip if の条件)
#
# Windows の Git Bash は MSYS=winsymlinks:nativestrict がないと ln -s がコピーになる。
# 独立した一時ディレクトリでリンクを作り、[[ -L ]] で実リンクかを確かめる。
#
# @return 0 実リンクを作れない (Skip する), 1 作れる
_nhr_symlink_unsupported() {
  local probe_dir
  probe_dir="$(mktemp -d)"
  MSYS=winsymlinks:nativestrict ln -s "$probe_dir" "${probe_dir}/link" 2>/dev/null
  local status=0
  [[ -L "${probe_dir}/link" ]] && status=1
  rm -rf "$probe_dir"
  return "$status"
}

# _nhr_setup_linked_skill - naming.lib.sh へのリンクと専用辞書を持つ別スキルを作る
#
# 前提: NAMING_TMPDIR が作成済みであること (setup_tmpdir)
#
# @arg $1 string スキルのディレクトリ名 (NAMING_TMPDIR 直下)
# @arg $2 string 辞書に書く唯一のエントリ
# @stdout リンクとして置いた naming.lib.sh のパス
_nhr_setup_linked_skill() {
  local skill_dir="${NAMING_TMPDIR}/${1}"
  mkdir -p "${skill_dir}/scripts/libs" "${skill_dir}/assets/dic"
  printf '%s\n' "${2}" >"${skill_dir}/assets/dic/hackers.dic"
  MSYS=winsymlinks:nativestrict ln -s "${_RUNTIME_LIBS_DIR}/naming.lib.sh" "${skill_dir}/scripts/libs/naming.lib.sh"
  printf '%s' "${skill_dir}/scripts/libs/naming.lib.sh"
}

# _nhr_write_dic - 一時辞書を NAMING_TMPDIR 直下に作る
#
# 前提: NAMING_TMPDIR が作成済みであること (setup_tmpdir)
#
# @arg $1   string 辞書のファイル名
# @arg $2.. string 辞書の各行 (コメント行・空行も 1 引数 1 行で渡す)
# @stdout 作成した辞書のパス
_nhr_write_dic() {
  local dic="${NAMING_TMPDIR}/${1}"
  shift
  printf '%s\n' "$@" >"$dic"
  printf '%s' "$dic"
}

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
    Describe "Given: PROJECT_ROOT に依存せず既定の hackers.dic が存在する"
      Before "unset PROJECT_ROOT"

      Describe "When: hacker_random を引数なしで呼ぶ"
        It "Then: [Normal] T-LIB-NHR-01: 空文字でない名前が返る"
          When call hacker_random
          The status should equal 0
          The output should not equal ""
        End

        It "Then: [Normal] T-LIB-NHR-02: 返値が hackers.dic 内のエントリである"
          result=$(hacker_random)
          When call grep -qx "$result" "$_NHR_DECKRD_DIC"
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
          custom_dic=$(_nhr_write_dic "custom.dic" "# comment" "alice" "bob")
          result=$(hacker_random "$custom_dic")
          When call grep -qx "$result" "$custom_dic"
          The status should equal 0
        End
      End
    End

    Describe "Given: 環境変数・カレントディレクトリ・読み込み経路が異なる"
      Before "setup_tmpdir"
      After "teardown_tmpdir"

      Describe "When: 存在しない PROJECT_ROOT を設定して引数なしで呼ぶ"
        It "Then: [Normal] T-LIB-NHR-05: status=0 を返し空でない名前が返る"
          export PROJECT_ROOT=/no/such/project
          When call hacker_random
          The status should equal 0
          The output should not equal ""
        End
      End

      Describe "When: 辞書のない別スキルの SKILL_ROOT を export してから source する"
        It "Then: [Normal] T-LIB-NHR-06: deckrd の hackers.dic のエントリが返る"
          mkdir -p "${NAMING_TMPDIR}/other-skill"
          result=$(_nhr_fresh_hacker_random "export SKILL_ROOT='${NAMING_TMPDIR}/other-skill'" "${_RUNTIME_LIBS_DIR}/naming.lib.sh")
          When call grep -qx "$result" "$_NHR_DECKRD_DIC"
          The status should equal 0
        End
      End

      Describe "When: 相対パスで source した後に別ディレクトリへ cd して呼ぶ"
        It "Then: [Normal] T-LIB-NHR-07: deckrd の hackers.dic のエントリが返る"
          result=$(_nhr_fresh_hacker_random "cd '${_RUNTIME_LIBS_DIR}'" "./naming.lib.sh" "cd '${NAMING_TMPDIR}'")
          When call grep -qx "$result" "$_NHR_DECKRD_DIC"
          The status should equal 0
        End
      End

      Describe "When: 別スキルに置いたリンク経由で source する"
        It "Then: [Normal] T-LIB-NHR-08: リンクを置いたスキルの辞書のエントリが返る"
          Skip if "実リンクを作れない環境" _nhr_symlink_unsupported
          linked_lib=$(_nhr_setup_linked_skill "skillB" "zeta")
          When call _nhr_fresh_hacker_random "" "$linked_lib"
          The status should equal 0
          The output should equal "zeta"
        End
      End
    End

    Describe "Given: 辞書を名前の候補として使えない"
      Before "setup_tmpdir"
      After "teardown_tmpdir"

      Describe "When: assets を持たない場所へコピーした naming.lib.sh を source して引数なしで呼ぶ"
        It "Then: [Error] T-LIB-NHR-09: status=1 を返し stderr に解決パスと symlink ヒントが出力される"
          mkdir -p "${NAMING_TMPDIR}/skillC/scripts/libs"
          cp "${_RUNTIME_LIBS_DIR}/naming.lib.sh" "${NAMING_TMPDIR}/skillC/scripts/libs/naming.lib.sh"
          When call _nhr_fresh_hacker_random "" "${NAMING_TMPDIR}/skillC/scripts/libs/naming.lib.sh"
          The status should equal 1
          The output should equal ""
          The error should include "file not found"
          The error should include "skillC/scripts/libs/../../assets/dic/hackers.dic"
          The error should include "$_NHR_SYMLINK_HINT_KEYWORD"
        End
      End

      Describe "When: リンク先パス 1 行だけのテキストになった辞書を渡す"
        It "Then: [Error] T-LIB-NHR-10: status=1 を返し名前を出力せず stderr に symlink ヒントが出力される"
          linktext_dic=$(_nhr_write_dic "linktext.dic" "../../../../deckrd/skills/deckrd/assets/dic/hackers.dic")
          When call hacker_random "$linktext_dic"
          The status should equal 1
          The output should equal ""
          The error should include "$_NHR_SYMLINK_HINT_KEYWORD"
        End
      End
    End

    Describe "Given: コメント・空行を除いた有効エントリが 1 件だけの辞書"
      Before "setup_tmpdir"
      After "teardown_tmpdir"

      Describe "When: コメント・空行に続くパス 1 件だけの辞書を渡す"
        It "Then: [Edge] T-LIB-NHR-11: status=1 を返し名前を出力せず stderr に symlink ヒントが出力される"
          commented_dic=$(_nhr_write_dic "commented.dic" "# header" "" "../dic/hackers.dic")
          When call hacker_random "$commented_dic"
          The status should equal 1
          The output should equal ""
          The error should include "$_NHR_SYMLINK_HINT_KEYWORD"
        End
      End

      Describe "When: / を含まないエントリ 1 件だけの辞書を渡す"
        It "Then: [Edge] T-LIB-NHR-12: そのエントリが名前として返る"
          solo_dic=$(_nhr_write_dic "solo.dic" "# c" "solo")
          When call hacker_random "$solo_dic"
          The status should equal 0
          The output should equal "solo"
        End
      End

      Describe "When: - で始まるエントリ 1 件だけの辞書を渡す"
        It "Then: [Edge] T-LIB-NHR-13: shuf のオプションとして扱われず、そのエントリが名前として返る"
          dash_dic=$(_nhr_write_dic "dash.dic" "--help")
          When call hacker_random "$dash_dic"
          The status should equal 0
          The output should equal "--help"
        End
      End
    End

    Describe "Given: 名前の抽選または辞書パスの解決を妨げる環境"
      Before "setup_tmpdir"
      After "teardown_tmpdir"

      Describe "When: shuf が失敗する状態で引数なしで呼ぶ"
        It "Then: [Error] T-LIB-NHR-14: status=1 を返し名前を出力しない"
          When call _nhr_fresh_hacker_random "" "${_RUNTIME_LIBS_DIR}/naming.lib.sh" "shuf() { return 1; }"
          The status should equal 1
          The output should equal ""
        End
      End

      Describe "When: CDPATH を設定し相対パスで source して引数なしで呼ぶ"
        It "Then: [Edge] T-LIB-NHR-15: deckrd の hackers.dic のエントリが返る"
          skill_dir="${_RUNTIME_LIBS_DIR}/../.."
          result=$(_nhr_fresh_hacker_random "cd '${skill_dir}'; export CDPATH='${skill_dir}'" "scripts/libs/naming.lib.sh")
          When call grep -qx "$result" "$_NHR_DECKRD_DIC"
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

    Describe "Given: 既定の hackers.dic が見つからない"
      Before "_NAMING_DIC_DEFAULT=/no/such/assets/dic/hackers.dic"

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

      # Mock: override _generate_filename with a fixed-value sequence
      # One generate_filename call caches "myfile-fixed-...-doc"
      # On the second generate_filename call the same fixed value is the first candidate and collides ->
      # the second candidate "myfile-other-...-doc" is returned
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

      # Call generate_filename once to cache "myfile-fixed-...-doc"
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

      # Mock: _generate_filename always returns the same fixed value
      # One generate_filename call caches "myfile-fixed-...-doc"
      # Every later call collides on the same value and fails once max_retries is reached
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

    # Mock: fix only token and timestamp; $(date +%N) still uses the real clock.
    # With slug/token/timestamp fixed, $base is identical on both calls,
    # so only $RANDOM and $(date +%N) mixed into the hash can make the outputs differ.
    # Freezing +%N as well would leave $RANDOM as the only source of difference, so drawing
    # the same value twice would make the outputs match and fail intermittently. It also avoids relying on bash subshell reseeding.
    # The only remaining uncertainty is a 1/65536 match from folding the hash into 4 hex digits,
    # which the test cannot eliminate because the name format is fixed by the spec.
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

    # Run generate_filename in parallel and write each generated name to the result file, one per line.
    # The implementation's printf '%s' emits no newline, so the worker appends it.
    # A worker exits 1 immediately when generate_filename fails, reporting the failure to xargs.
    #
    # @arg $1 int    Parallelism (xargs -P)
    # @arg $2 int    Number of runs
    # @arg $3 int    (optional) NAMING_MAX_RETRIES passed to workers; defaults to the library value
    # @set _PARALLEL_RESULTS string Path of the result file (kept outside the cache)
    # @set _PARALLEL_STATUS  int    Exit code of xargs (123 if any worker fails)
    # @set _PARALLEL_STDERR  string Path of the file collecting worker stderr.
    #                           Kept because the exit code alone cannot tell failure causes
    #                           apart (a wrong path or missing command also yields 123)
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

      It "Then: [Normal] T-LIB-NGFR-03: 同一 token/timestamp でも呼び出しごとに異なる候補名を返す"
        # $() runs in a subshell, making $RANDOM progression hard to follow, so capture output via a file
        _generate_filename 'parallel' 'doc' >"${NAMING_TMPDIR}/ngfr03-first"
        _generate_filename 'parallel' 'doc' >"${NAMING_TMPDIR}/ngfr03-second"
        first=$(cat "${NAMING_TMPDIR}/ngfr03-first")
        second=$(cat "${NAMING_TMPDIR}/ngfr03-second")
        When call test "$first" != "$second"
        The status should equal 0
      End
    End

    Describe "When: 10並列 × 20回 generate_filename を同時実行する"
      Before "run_parallel_generate 10 20"

      # T-LIB-NGFR-04 / -05 are symptom canaries, not guards against the race.
      # Reproducing parallel collisions is probabilistic; both may PASS even with the entropy terms removed from the hash.
      # Only T-LIB-NGFR-03 guards this defect deterministically.
      # This covers the only user-visible symptom, a worker exiting non-zero,
      # at the cost of just one extra parallel run.
      It "Then: [Normal] T-LIB-NGFR-04: 全ワーカーが成功し xargs の終了コードが 0 になる"
        When call test "$_PARALLEL_STATUS" -eq 0
        The status should equal 0
      End

      It "Then: [Normal] T-LIB-NGFR-05: 生成されたファイル名が 20 件そろう"
        generated=$(grep -c '^parallel-' "${_PARALLEL_RESULTS}")
        When call test "$generated" -eq 20
        The status should equal 0
      End

      It "Then: [Normal] T-LIB-NGFR-01: 生成されたファイル名に重複がない"
        duplicated=$(sort "${_PARALLEL_RESULTS}" | uniq -d)
        When call test -z "$duplicated"
        The status should equal 0
      End

      It "Then: [Normal] T-LIB-NGFR-02: 生成されたファイル名が全てキャッシュに存在する"
        missing=0
        while IFS= read -r name; do
          [[ -f "${_FILENAME_CACHE_DIR}/${name}" ]] || missing=1
        done <"${_PARALLEL_RESULTS}"
        When call test "$missing" -eq 0
        The status should equal 0
      End

      # Proves the duplicate check is not a vacuous pass. The implementation's printf '%s' emits no newline,
      # so without the worker's newline all 20 names were joined into one line and uniq -d was always empty
      It "Then: [Normal] T-LIB-NGFR-08: 結果ファイルが 1 件 1 行の 20 行になる"
        lines=$(wc -l <"${_PARALLEL_RESULTS}" | tr -d ' ')
        When call test "$lines" -eq 20
        The status should equal 0
      End
    End

    # Pass NAMING_MAX_RETRIES=0 to the workers only. The library default of 5 is left unchanged
    Describe "When: リトライ上限 0 のワーカーで 10並列 × 20回 実行する"
      Before "run_parallel_generate 10 20 0"

      # Example showing the T-LIB-NGFR-04 status check is not vacuous.
      # The exit code alone is 123 even for a wrong source path or a missing command,
      # so check the stderr message to confirm the cause is retry exhaustion
      It "Then: [Error] T-LIB-NGFR-06: リトライ枯渇が xargs の終了コード 123 と stderr に現れる"
        When call test "$_PARALLEL_STATUS" -eq 123
        The status should equal 0
        The contents of file "${_PARALLEL_STDERR}" should include "max retries"
      End
    End

    Describe "When: 1並列 × 1回 generate_filename を実行する (並列度の下限)"
      Before "run_parallel_generate 1 1"

      It "Then: [Edge] T-LIB-NGFR-07: 成功し結果 1 行・キャッシュ 1 件になる"
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
