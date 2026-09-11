#!/usr/bin/env bash
# utils.unit.spec.sh - ShellSpec tests for utils.lib.sh
#
# Copyright (c) 2026- atsushifx <https://github.com/atsushifx>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

# shellcheck disable=SC1090,SC1091
# shellcheck disable=SC2034  # jqexe is assigned per example and read by jq_read

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

  Describe "jq_read"

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

End
