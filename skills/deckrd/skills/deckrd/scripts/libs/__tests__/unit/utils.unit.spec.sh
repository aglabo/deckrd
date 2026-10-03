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

Include ../spec_helper.sh

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
  # and strip a trailing `/` (the root `/` is kept) without external commands.
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

End
