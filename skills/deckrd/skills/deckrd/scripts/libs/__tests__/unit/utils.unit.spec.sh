#!/usr/bin/env bash
# utils.unit.spec.sh - ShellSpec tests for utils.lib.sh
#
# Copyright (c) 2026- atsushifx <https://github.com/atsushifx>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

# shellcheck disable=SC1090,SC1091
# shellcheck disable=SC2034  # jqexe is assigned per example and read by jq_read
# shellcheck disable=SC1003,SC2286,SC2287,SC2288  # Parameters rows are path data, not commands

_RUNTIME_BOOTSTRAP="${SHELLSPEC_PROJECT_ROOT}/skills/deckrd/skills/deckrd/scripts/libs/bootstrap.lib.sh"
. "$_RUNTIME_BOOTSTRAP" "--no-finalize"
unset _RUNTIME_BOOTSTRAP

Include "${SHELLSPEC_SPECFILE%/*}/../spec_helper.sh"

SCRIPT="${DECKRD_LIB_DIR}/utils.lib.sh"
. "${SCRIPT}"

# ============================================================================
# Internal helpers (spec-local)
# ============================================================================

# Create an isolated directory to hold fake jq engines
_utils_spec_setup() {
  _UTILS_SPEC_TMPDIR="$(mktemp -d)"
}

_utils_spec_teardown() {
  [[ -n "${_UTILS_SPEC_TMPDIR:-}" && -d "$_UTILS_SPEC_TMPDIR" ]] && rm -rf "$_UTILS_SPEC_TMPDIR"
  unset _UTILS_SPEC_TMPDIR jqexe
}

# _utils_spec_fake_jq <name> <body> - write an executable fake jq and print its path
_utils_spec_fake_jq() {
  local path="${_UTILS_SPEC_TMPDIR}/$1"
  printf '#!/usr/bin/env bash\n%s\n' "$2" >"$path"
  chmod +x "$path"
  printf '%s' "$path"
}

# Report whether pipefail is enabled in the current shell
_utils_spec_pipefail_state() {
  if [[ -o pipefail ]]; then
    printf 'on'
  else
    printf 'off'
  fi
}

# _utils_spec_make_target <content> - set $target to data.json in the spec tmpdir
#   and write <content> plus a newline to it
_utils_spec_make_target() {
  target="${_UTILS_SPEC_TMPDIR}/data.json"
  printf '%s\n' "$1" >"$target"
}

# _utils_spec_make_dir_target - set $target to dir.json in the spec tmpdir
#   and create it as an empty directory
_utils_spec_make_dir_target() {
  target="${_UTILS_SPEC_TMPDIR}/dir.json"
  mkdir "$target"
}

# _utils_spec_tmp_leftovers - list temp files (`*.tmp.*`) left in the spec tmpdir
_utils_spec_tmp_leftovers() {
  find "$_UTILS_SPEC_TMPDIR" -name '*.tmp.*' -print
}

# _utils_spec_dir_entries - list the entries of the directory $target points to
#   (the trailing `/` makes ls follow a symlink to a directory)
_utils_spec_dir_entries() {
  ls -A "${target}/"
}

# _utils_spec_cannot_symlink - succeed if a real symlink cannot be created here
#   (MSYS may silently copy instead of linking, so the result is checked with -L)
_utils_spec_cannot_symlink() {
  local probe rc=0
  probe="$(mktemp -d)"
  ln -s "$probe" "${probe}/link" 2>/dev/null
  [[ -L "${probe}/link" ]] && rc=1
  rm -rf "$probe"
  return "$rc"
}

# _utils_spec_is_tmp_of <target> - succeed if the subject ($_utils_spec_is_tmp_of)
#   is "<target>.tmp.XXXXXX" as made by mktemp (6 chars of [A-Za-z0-9]);
#   used with `should satisfy`
_utils_spec_is_tmp_of() {
  local subject="${_utils_spec_is_tmp_of:-}"
  [[ "$subject" == "$1".tmp.* && "${subject#"$1".tmp.}" =~ ^[A-Za-z0-9]{6}$ ]]
}

Describe "utils.lib.sh"

  Before "_utils_spec_setup"
  After "_utils_spec_teardown"

  Describe "T-LIB-UJR: jq_read"

    Describe "When: 正常系"
      It "Then: [Normal] T-LIB-UJR-01-01: CR を含む出力が LF のみに正規化される"
        jqexe="$(_utils_spec_fake_jq crlf "printf 'a\r\nb\r\n'")"
        When call jq_read .
        The status should equal 0
        The output should equal "a
b"
      End

      It "Then: [Normal] T-LIB-UJR-01-02: CR を含まない出力はそのまま通る"
        jqexe="$(_utils_spec_fake_jq lf "printf 'a\nb\n'")"
        When call jq_read .
        The status should equal 0
        The output should equal "a
b"
      End
    End

    Describe "When: 異常系"
      It "Then: [Error] T-LIB-UJR-02-01: jq が非ゼロ終了すると同じ終了コードを返す"
        jqexe="$(_utils_spec_fake_jq fail3 'exit 3')"
        When call jq_read .
        The status should equal 3
      End

      It "Then: [Error] T-LIB-UJR-02-02: 呼び出し元が pipefail 未設定でも非ゼロを返す"
        set +o pipefail
        jqexe="$(_utils_spec_fake_jq fail5 'exit 5')"
        When call jq_read .
        The status should equal 5
      End
    End

    Describe "When: エッジケース"
      It "Then: [Edge] T-LIB-UJR-03-01: 呼び出し元の pipefail 設定を変えない"
        set +o pipefail
        jqexe="$(_utils_spec_fake_jq ok "printf 'ok\n'")"
        jq_read . >/dev/null
        When call _utils_spec_pipefail_state
        The status should equal 0
        The output should equal "off"
      End
    End

  End

  # Target: normalize_dir_path
  # Responsibility: unify directory path separators to `/`, collapse repeated `/`
  # and strip a trailing `/` (the root `/` is kept).
  Describe "T-LIB-NDP: normalize_dir_path"

    Describe "When: 正常系"
      Parameters
        'a\b\c' 'a/b/c'
        '/tmp/x/' '/tmp/x'
        'C:\Users\x\' 'C:/Users/x'
        '/a//b///c' '/a/b/c'
        '//server/share/project' '//server/share/project'
        '\\server\share\project\' '//server/share/project'
        '//server//share///x/' '//server/share/x'
      End

      It "Then: [Normal] T-LIB-NDP-01-01: $1 は $2 に正規化される"
        When call normalize_dir_path "$1"
        The status should equal 0
        The output should equal "$2"
      End
    End

    Describe "When: 異常系"
      It "Then: [Error] T-LIB-NDP-02-01: 引数なしでも空行を出力し status 0 で終わる"
        # nounset makes a bare `$1` reference fail, so the missing-argument guard is exercised
        Set 'nounset:on'
        When call normalize_dir_path
        The status should equal 0
        The output should equal ""
        The stderr should equal ""
      End
    End

    Describe "When: エッジケース"
      Parameters
        '/' '/'
        '//' '/'
        '///a//b' '/a/b'
        'C:\' 'C:'
        '' ''
      End

      It "Then: [Edge] T-LIB-NDP-03-01: $1 は $2 に正規化される"
        When call normalize_dir_path "$1"
        The status should equal 0
        The output should equal "$2"
      End
    End

  End

  # Target: strip_suffix
  # Responsibility: remove one trailing occurrence of a literal suffix from the
  # whole string with pure parameter expansion.
  Describe "T-LIB-SSF: strip_suffix"

    Describe "When: 正常系"
      Parameters
        'rules/.gitignore.org' '.org' 'rules/.gitignore'
        'a.md' '.org' 'a.md'
      End

      It "Then: [Normal] T-LIB-SSF-01-01: $1 から $2 を除くと $3 になる"
        When call strip_suffix "$1" "$2"
        The status should equal 0
        The output should equal "$3"
      End
    End

    Describe "When: 異常系"
      It "Then: [Error] T-LIB-SSF-02-01: 空の suffix は何も除去せず status 0 で終わる"
        When call strip_suffix 'a.md' ''
        The status should equal 0
        The output should equal "a.md"
        The stderr should equal ""
      End
    End

    Describe "When: エッジケース"
      Parameters
        'rules.org/a.md' '.org' 'rules.org/a.md'
        'a.org.org' '.org' 'a.org'
        'a.md' '*' 'a.md'
        'a.md' '.m?' 'a.md'
        '' '.org' ''
      End

      It "Then: [Edge] T-LIB-SSF-03-01: $1 から $2 を除くと $3 になる"
        When call strip_suffix "$1" "$2"
        The status should equal 0
        The output should equal "$3"
      End
    End

  End

  # Target: write_json_file
  # Responsibility: write jq_read output to a temp file next to the target and
  # replace the target with mv -f, leaving the target intact on failure.
  Describe "T-LIB-WJF: write_json_file"

    Describe "When: 正常系"
      It "Then: [Normal] T-LIB-WJF-01-01: 別入力 (-n) の出力で既存 target の内容が置き換わる"
        _utils_spec_make_target '{"a":1}'
        When call write_json_file "$target" -c -n '{"b":2}'
        The status should equal 0
        The contents of file "$target" should equal '{"b":2}'
        The result of function _utils_spec_tmp_leftovers should equal ""
      End

      It "Then: [Normal] T-LIB-WJF-01-02: target 自身を入力にしても読み込み後に置き換わる"
        _utils_spec_make_target '{"a":1}'
        # shellcheck disable=SC2016  # $x is a jq variable
        When call write_json_file "$target" -c --arg x 1 '.x = $x' "$target"
        The status should equal 0
        The contents of file "$target" should equal '{"a":1,"x":"1"}'
        The result of function _utils_spec_tmp_leftovers should equal ""
      End

      It "Then: [Normal] T-LIB-WJF-01-03: 同じディレクトリに mktemp \"\${target}.tmp.XXXXXX\" で作った tmp を mv -f で target に置き換える"
        _utils_spec_make_target '{"a":1}'
        mktemp_args="${_UTILS_SPEC_TMPDIR}/mktemp.args"
        mktemp_out="${_UTILS_SPEC_TMPDIR}/mktemp.out"
        mv_args="${_UTILS_SPEC_TMPDIR}/mv.args"
        # shellcheck disable=SC2329  # shadows the external mktemp for this example
        mktemp() {
          local out
          printf '%s\n' "$@" >"$mktemp_args"
          out="$(command mktemp "$@")" || return
          printf '%s\n' "$out" >"$mktemp_out"
          printf '%s\n' "$out"
        }
        # shellcheck disable=SC2329  # shadows the external mv for this example
        mv() {
          printf '%s\n' "$@" >"$mv_args"
          command mv "$@"
        }
        When call write_json_file "$target" -c -n '{"b":2}'
        The status should equal 0
        The lines of contents of file "$mktemp_args" should equal 1
        The line 1 of contents of file "$mktemp_args" should equal "${target}.tmp.XXXXXX"
        The line 1 of contents of file "$mv_args" should equal "-f"
        The line 2 of contents of file "$mv_args" should equal "$(cat "$mktemp_out" 2>/dev/null)"
        The line 2 of contents of file "$mv_args" should satisfy _utils_spec_is_tmp_of "$target"
        The line 3 of contents of file "$mv_args" should equal "$target"
        The contents of file "$target" should equal '{"b":2}'
      End
    End

    Describe "When: 異常系"
      It "Then: [Error] T-LIB-WJF-02-01: 不正なフィルタで jq_read が失敗すると 1 を返し target を保ち tmp を残さない"
        _utils_spec_make_target '{"a":1}'
        When call write_json_file "$target" -c '.[' "$target"
        The status should equal 1
        The contents of file "$target" should equal '{"a":1}'
        The result of function _utils_spec_tmp_leftovers should equal ""
        The stderr should be present
      End

      It "Then: [Error] T-LIB-WJF-02-02: mv が失敗すると 1 を返し target を保ち tmp を残さず、自身は何も出力しない"
        _utils_spec_make_target '{"a":1}'
        # shellcheck disable=SC2329  # shadows the external mv for this example
        mv() { return 1; }
        When call write_json_file "$target" -c -n '{"b":2}'
        The status should equal 1
        The contents of file "$target" should equal '{"a":1}'
        The result of function _utils_spec_tmp_leftovers should equal ""
        The stderr should equal ""
      End

      It "Then: [Error] T-LIB-WJF-02-03: target が既存ディレクトリのとき 1 を返し、ディレクトリの中身を変えず tmp を残さない"
        _utils_spec_make_dir_target
        printf 'x\n' >"$target/keep.txt"
        When call write_json_file "$target" -c -n '{"b":2}'
        The status should equal 1
        The result of function _utils_spec_dir_entries should equal "keep.txt"
        The contents of file "$target/keep.txt" should equal "x"
        The result of function _utils_spec_tmp_leftovers should equal ""
        The stderr should equal ""
      End

      It "Then: [Error] T-LIB-WJF-02-04: target が既存ディレクトリのとき jq_read を呼ばず tmp も作らない"
        _utils_spec_make_dir_target
        called="${_UTILS_SPEC_TMPDIR}/jq.called"
        # spy jq: records the call, then runs the real jq
        jqexe="$(_utils_spec_fake_jq spy ": >'${called}'; exec jq \"\$@\"")"
        When call write_json_file "$target" -c -n '{"b":2}'
        The status should equal 1
        The path "$called" should not be exist
        The result of function _utils_spec_tmp_leftovers should equal ""
      End

      It "Then: [Error] T-LIB-WJF-02-05: mktemp が失敗すると 1 を返し、jq_read を呼ばず target を保ち tmp を残さない"
        _utils_spec_make_target '{"a":1}'
        called="${_UTILS_SPEC_TMPDIR}/jq.called"
        # spy jq: records the call, then runs the real jq
        jqexe="$(_utils_spec_fake_jq spy ": >'${called}'; exec jq \"\$@\"")"
        # shellcheck disable=SC2329  # shadows the external mktemp for this example
        mktemp() { return 1; }
        When call write_json_file "$target" -c -n '{"b":2}'
        The status should equal 1
        The contents of file "$target" should equal '{"a":1}'
        The path "$called" should not be exist
        The result of function _utils_spec_tmp_leftovers should equal ""
        The stderr should equal ""
      End
    End

    Describe "When: エッジケース"
      It "Then: [Edge] T-LIB-WJF-03-01: target 自身が不正な JSON かつ入力のとき 1 を返し target を切り詰めない"
        _utils_spec_make_target 'not json'
        When call write_json_file "$target" -c '.x = 1' "$target"
        The status should equal 1
        The contents of file "$target" should equal 'not json'
        The result of function _utils_spec_tmp_leftovers should equal ""
        The stderr should be present
      End

      It "Then: [Edge] T-LIB-WJF-03-02: target が存在しない場合は新規作成される"
        target="${_UTILS_SPEC_TMPDIR}/new.json"
        When call write_json_file "$target" -c -n '{"k":"v"}'
        The status should equal 0
        The contents of file "$target" should equal '{"k":"v"}'
        The result of function _utils_spec_tmp_leftovers should equal ""
      End

      It "Then: [Edge] T-LIB-WJF-03-03: target がディレクトリへのシンボリックリンクのとき 1 を返し、リンク先の中身を変えず tmp を残さない"
        Skip if "シンボリックリンクを作れない" _utils_spec_cannot_symlink
        realdir="${_UTILS_SPEC_TMPDIR}/realdir"
        target="${_UTILS_SPEC_TMPDIR}/link.json"
        mkdir "$realdir"
        printf 'x\n' >"$realdir/keep.txt"
        ln -s "$realdir" "$target"
        When call write_json_file "$target" -c -n '{"b":2}'
        The status should equal 1
        The path "$target" should be symlink
        The result of function _utils_spec_dir_entries should equal "keep.txt"
        The contents of file "$realdir/keep.txt" should equal "x"
        The result of function _utils_spec_tmp_leftovers should equal ""
        The stderr should equal ""
      End

      It "Then: [Edge] T-LIB-WJF-03-04: target の親ディレクトリが存在しないとき mktemp が失敗し 1 を返し、何も作らない"
        target="${_UTILS_SPEC_TMPDIR}/missing/new.json"
        When call write_json_file "$target" -c -n '{"k":"v"}'
        The status should equal 1
        The path "${_UTILS_SPEC_TMPDIR}/missing" should not be exist
        The result of function _utils_spec_tmp_leftovers should equal ""
        The stderr should be present
      End
    End

  End

End
