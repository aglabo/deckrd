#!/usr/bin/env bash
# generate-doc-main.functional.spec.sh - ShellSpec functional tests for main in generate-doc.sh
#
# Functional test design:
#   - main は generate-doc.sh 末尾の [[ "${BASH_SOURCE[0]}" == "$0" ]] ガードの内側で
#     呼ばれるため、source では起動できない。サブプロセスとして bash で実行する。
#   - SESSION_FILE は別プロセスへ渡すので、コマンド前置の変数代入で環境に載せる。
#     これが効くこと自体が検証対象であり、静的検査で代用しない。
#   - stdin は /dev/null から与える。main の `elif [[ ! -t 0 ]]` 分岐が
#     `config_set "context_input" "$(cat)"` でハングするのを防ぐ。
#   - 書き込み先はすべて tmpdir に閉じ込める。DECKRD_DOCS も tmpdir へ向けることで、
#     セッション読込が（欠陥時に）成功して後続処理まで進んでも、
#     リポジトリ本体の docs/.deckrd を汚さない。
#   - 実 AI CLI は絶対に起動させない。PATH 先頭に tmpdir 内の stub を置く。
#     stub は jq/jaq を隠さないよう PATH を置換ではなく前置する。
#
# Copyright (c) 2026- atsushifx <https://github.com/atsushifx>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

# shellcheck disable=SC1090,SC1091,SC2287

_RUNTIME_BOOTSTRAP="${SHELLSPEC_PROJECT_ROOT}/skills/deckrd/skills/deckrd/scripts/libs/bootstrap.lib.sh"
. "$_RUNTIME_BOOTSTRAP" --no-finalize
unset _RUNTIME_BOOTSTRAP

Include ../spec_helper.sh

# テスト対象は ${SUBCOMMANDS_DIR}/generate-doc.sh をサブプロセスとして起動する。
# main はガードの内側なので source による取り込みはしない。

# ============================================================================
# 内部ヘルパー
# ============================================================================

# 定数

# _BROKEN_SESSION_JSON - JSON オブジェクトとして読めない壊れたセッション本文（両ケースで使う）
readonly _BROKEN_SESSION_JSON='{ "active": "deckrd/subcommands"'

# _VALID_SESSION_JSON - JSON オブジェクトとして読める正常なセッション本文。
# active が deckrd/subcommands なので deckrd_base は DECKRD_DOCS_DIR 配下 (tmpdir) を指す
readonly _VALID_SESSION_JSON='{ "active": "deckrd/subcommands", "ai_model": "sonnet", "lang": "en" }'

# _CONFIG_DUMP_MARKER - 設定ダンプが走ったことを示す印。
# kv_init がスキーマの全キーを積むため、config_all は bash のハッシュ順に依らず
# 必ずこのキーを出す。他の stderr 出力（例: generate-doc.sh の
# `Output written to:`）はこの印を含まない。stderr が空であることを
# 期待してはならない。見るのはこの印の有無だけとする
readonly _CONFIG_DUMP_MARKER='prompt_mode='

# _AI_CLI_NAMES - run_ai が起動しうる AI CLI 名。stub を置いて実体の起動を防ぐ
readonly _AI_CLI_NAMES=('claude' 'codex' 'gemini' 'copilot' 'opencode')

# _OUTPUT_RELATIVE_PATH - --output に渡す DECKRD_BASE 相対パス（両ケースで使う）
readonly _OUTPUT_RELATIVE_PATH='requirements/requirements.md'

# _OUTPUT_FILE_NAME - 出力の有無を数えるときに探すファイル名
readonly _OUTPUT_FILE_NAME='requirements.md'

# 関数

# _install_ai_cli_stubs - tmpdir に AI CLI の stub を作り、その置き場所を返す
#
# run_ai は resolve_ai_cli の結果を command -v で探すので、stub ディレクトリを
# PATH 先頭に置けば実 CLI には到達しない。stub は stdin を読み捨てる。
# 読み捨てないと build_ai_input 側が EPIPE で落ち、pipefail が
# 「セッション読込で中断した」のと区別できない失敗を作ってしまう。
#
# @return 0 always
# @stdout stub を置いたディレクトリの絶対パス
_install_ai_cli_stubs() {
  local _dir="${DECKRD_TMPDIR}/stub-bin"
  mkdir -p "$_dir"

  local _cli
  for _cli in "${_AI_CLI_NAMES[@]}"; do
    cat >"${_dir}/${_cli}" <<'STUB_EOF'
#!/usr/bin/env bash
# stub AI CLI: プロンプトを読み捨てて固定文字列だけを返す
cat >/dev/null
printf '%s\n' 'STUB AI RESPONSE'
STUB_EOF
    chmod +x "${_dir}/${_cli}"
  done

  printf '%s' "$_dir"
}

# _write_session - session.json を tmpdir に書き出し、そのパスを返す
#
# 置き場所は setup_deckrd_tmpdir が用意した DECKRD_LOCAL 配下とする。
# 壊れたセッションと正常なセッションの両方がこれを共有する。書き出しを 2 箇所に
# 分けると、片方だけが更新されて静かに乖離する。
#
# @arg $1 string ファイル名（DECKRD_LOCAL 相対）
# @arg $2 string 書き出す session.json の本文
# @return 0 always
# @stdout 書き出した session.json の絶対パス
_write_session() {
  local _name="$1"
  local _body="$2"

  local _path="${DECKRD_LOCAL}/${_name}"
  printf '%s
' "$_body" >"$_path"
  printf '%s' "$_path"
}

# _run_generate_doc_with_session - 指定した session.json を注入して main を起動する
#
# 前提: setup_deckrd_tmpdir が済んでいること（DECKRD_TMPDIR / DECKRD_LOCAL /
#       DECKRD_DOCS_DIR が tmpdir を指していること）。
# 副作用: tmpdir に AI CLI の stub を作る。正常なセッションでは生成結果も書く。
#
# 第 2 引数以降はそのまま generate-doc.sh へ転送する。壊れたセッションのケースと
# --verbose 有り / 無しのケースが、この 1 本の起動経路を共有する。
#
# @arg $1 string 注入する session.json の絶対パス
# @arg $@ string generate-doc.sh へ追加で渡す引数（省略可）
# @return generate-doc.sh の終了ステータス
# @stdout generate-doc.sh の標準出力
# @stderr generate-doc.sh の標準エラー出力
_run_generate_doc_with_session() {
  local _session="$1"
  shift

  local _stub_dir
  _stub_dir="$(_install_ai_cli_stubs)"

  SESSION_FILE="$_session"     DECKRD_DOCS="${DECKRD_DOCS_DIR}"     PATH="${_stub_dir}:${PATH}"     bash "${SUBCOMMANDS_DIR}/generate-doc.sh" @requirements "test"     --output "$_OUTPUT_RELATIVE_PATH" "$@" </dev/null
}

# _run_generate_doc_with_broken_session - 壊れた session.json で main を起動する
#
# @return generate-doc.sh の終了ステータス
# @stdout generate-doc.sh の標準出力
# @stderr generate-doc.sh の標準エラー出力
_run_generate_doc_with_broken_session() {
  _run_generate_doc_with_session     "$(_write_session 'broken-session.json' "$_BROKEN_SESSION_JSON")"
}

# _run_generate_doc_with_valid_session - 正常な session.json で main を起動する
#
# @arg $@ string generate-doc.sh へ追加で渡す引数（省略可）
# @return generate-doc.sh の終了ステータス
# @stdout generate-doc.sh の標準出力
# @stderr generate-doc.sh の標準エラー出力
_run_generate_doc_with_valid_session() {
  _run_generate_doc_with_session     "$(_write_session 'valid-session.json' "$_VALID_SESSION_JSON")" "$@"
}

# _count_files_named - $DECKRD_DOCS_DIR 配下で指定名のファイル数を数える
#
# 出力先の固定パスを直接 -f で見ると、出力先が変わったときに
# 「書かれているのに通る」テストになる。名前で数えてそれを防ぐ。
#
# @arg $1 string ファイル名
# @return 0 always
# @stdout 見つかった件数
_count_files_named() {
  local _name="$1"
  find "$DECKRD_DOCS_DIR" -type f -name "$_name" 2>/dev/null | wc -l | tr -d '[:space:]'
}

# _count_outputs_after_broken_session - 壊れた session.json で main を起動した後の出力件数
#
# main の出力・終了ステータスは T-SUB-MAINF-01 が見るので、ここでは捨てる。
#
# @return 0 always
# @stdout $DECKRD_DOCS_DIR 配下で見つかった出力ファイルの件数
_count_outputs_after_broken_session() {
  _run_generate_doc_with_broken_session >/dev/null 2>&1 || true
  _count_files_named "$_OUTPUT_FILE_NAME"
}

# ============================================================================
# テスト本体
# ============================================================================

Describe "T-SUB-MAINF: generate-doc.sh main"

  Before "setup_deckrd_tmpdir"
  After "teardown_deckrd_tmpdir"

  Describe "Given: SESSION_FILE に壊れた session.json を注入したサブプロセス実行"
    Describe "When: 異常系"
      It "Then: [Error] T-SUB-MAINF-01: 壊れた session.json → exit 0 以外、stderr に Error: config_init: を出す"
        When run _run_generate_doc_with_broken_session
        The status should not equal 0
        The stderr should include 'Error: config_init:'
      End

      It "Then: [Error] T-SUB-MAINF-02: 壊れた session.json → DECKRD_DOCS_DIR 配下に出力を 1 つも書かない"
        When call _count_outputs_after_broken_session
        The output should equal "0"
      End
    End
  End

  Describe "Given: SESSION_FILE に正常な session.json を注入したサブプロセス実行"
    Describe "When: 正常系"
      It "Then: [Normal] T-SUB-MAINF-03: --verbose 無し → stderr に設定ダンプを出さない"
        When run _run_generate_doc_with_valid_session
        The status should equal 0
        The stderr should not include "$_CONFIG_DUMP_MARKER"
      End

      It "Then: [Normal] T-SUB-MAINF-04: --verbose 有り → stderr に設定ダンプを出す"
        When run _run_generate_doc_with_valid_session --verbose
        The stderr should include "$_CONFIG_DUMP_MARKER"
      End
    End
  End
End
