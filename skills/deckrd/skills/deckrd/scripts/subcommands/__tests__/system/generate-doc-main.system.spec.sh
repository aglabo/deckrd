#!/usr/bin/env bash
# generate-doc-main.system.spec.sh - ShellSpec system tests for main in generate-doc.sh
#
# System test design:
#   - TK-G3 / TK-G4（docs/.deckrd/deckrd/libs/workspaces/205-208-tasks.md）の
#     手動 system テストを自動化したもの。手動の実測値は同ファイルの Evidence に残す。
#   - generate-doc-main.functional.spec.sh と起動経路は同じだが、AI CLI の stub を
#     置かない。実機の AI CLI と実機の jq / jaq をそのまま使うことがこのファイルの目的であり、
#     それが system（実行環境を含めた全体）と functional を分ける点である。
#   - 既定の SKIP_INTEGRATION_TESTS=1 では全ケースを skip する。
#     `pnpm run test:sh system` が 0 を立てるので、そのときだけ実行される。
#     spec ファイルを直接指定するときは `--integration` を付ける。
#   - 書き込み先はすべて tmpdir に閉じ込める。実 AI が本当に応答を返すので、
#     DECKRD_DOCS を tmpdir へ向けないとリポジトリ本体の docs/.deckrd を汚す。
#   - stdin は /dev/null から与える。main の `elif [[ ! -t 0 ]]` 分岐が
#     `config_set "context_input" "$(cat)"` でハングするのを防ぐ。
#   - CLAUDECODE は unset して起動する。Claude Code の中から claude CLI を
#     入れ子で起動すると挙動が変わるため（ai-runner.system.spec.sh と同じ扱い）。
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

# _AI_TIMEOUT_SEC - run_ai に渡すタイムアウト秒数
#
# resolve_ai_timeout の既定は 300 秒だが、@requirements（sonnet）の実測は
# 成功時 150 秒・jaq 経由 255 秒で、既定値のまま exit 124 になった実測もある
# （205-208-tasks.md「本 issue の範囲外」）。実測幅に対して既定値が狭く、
# そのまま使うと flaky になるので、このファイルでは明示的に広げる。
readonly _AI_TIMEOUT_SEC=600

# _SESSION_ACTIVE - session.json の active。deckrd_base の導出元になる
#
# config_init は deckrd_base を "${DECKRD_DOCS}/${active}" として組み立てる。
# DECKRD_DOCS は tmpdir を指すので、この値は tmpdir の中にしか広がらない。
readonly _SESSION_ACTIVE='deckrd/skill-runners'

# _SESSION_AI_MODEL - session.json の ai_model。設定ダンプでの突き合わせに使う
readonly _SESSION_AI_MODEL='sonnet'

# _SESSION_JSON - 注入する session.json の本文
readonly _SESSION_JSON="{ \"active\": \"${_SESSION_ACTIVE}\", \"ai_model\": \"${_SESSION_AI_MODEL}\", \"lang\": \"en\" }"

# _CONFIG_DUMP_MARKER - 設定ダンプが走ったことを示す印
#
# kv_init がスキーマの全キーを積むため、config_all は bash のハッシュ順に依らず
# 必ずこのキーを出す。他の stderr 出力（generate-doc.sh の `Output written to:`）は
# この印を含まない。stderr が空であることを期待してはならない。
readonly _CONFIG_DUMP_MARKER='prompt_mode='

# _CONTEXT_INPUT - @requirements に渡すユーザー入力
readonly _CONTEXT_INPUT='system test input'

# _OUTPUT_RELATIVE_PATH - --output に渡す DECKRD_BASE 相対パス
readonly _OUTPUT_RELATIVE_PATH='requirements/requirements.md'

# _VALIDATE_ENV_ERROR - jq も jaq も無いときに validate_env が出す唯一のメッセージ
readonly _VALIDATE_ENV_ERROR='Error: jq or jaq is required but not installed.'

# 関数

# _write_session - session.json を tmpdir に書き出し、そのパスを返す
#
# 置き場所は setup_deckrd_tmpdir が用意した DECKRD_LOCAL 配下とする。
#
# @return 0 always
# @stdout 書き出した session.json の絶対パス
_write_session() {
  local _path="${DECKRD_LOCAL}/session.json"
  printf '%s\n' "$_SESSION_JSON" >"$_path"
  printf '%s' "$_path"
}

# _mirror_dir_hiding - 1 つのディレクトリを tmpdir に張り直し、指定名だけを除く
#
# 相対パスを渡してはならない。`ln -s` が相対リンクを作り、ミラーの中から
# 解決できないリンクになる（リンク先が「ミラーからの相対」と解釈される）。
# 呼び出し側は readlink -f で解決したパスを渡す。
#
# @arg $1 string 元のディレクトリ（絶対パス）
# @arg $@ string 除く実行ファイル名
# @return 0 on success, 1 if the mirror could not be built
# @stdout 作ったミラーディレクトリの絶対パス
_mirror_dir_hiding() {
  local _src="$1"
  shift

  local _dst
  _dst="$(mktemp -d "${DECKRD_TMPDIR}/path-mirror.XXXXXX")" || return 1

  local _file _name _hide _skip
  for _file in "$_src"/*; do
    [[ -f "$_file" && -x "$_file" ]] || continue
    _name="${_file##*/}"

    _skip=0
    for _hide in "$@"; do
      if [[ "$_name" == "$_hide" ]]; then
        _skip=1
        break
      fi
    done
    [[ $_skip -eq 1 ]] && continue

    ln -s "$_file" "${_dst}/${_name}" || return 1
  done

  printf '%s' "$_dst"
}

# _path_hiding - 指定した実行ファイルが見つからない PATH を組み立てて返す
#
# 素朴に「その実行ファイルを含むディレクトリを PATH から外す」方式は使えない。
# Debian 系では jq が dirname や git と同じ /usr/bin に居るため、ディレクトリごと
# 落とすと generate-doc.sh が validate_env より手前で別の理由で落ちる。
# さらに /bin は /usr/bin へのシンボリックリンクなので、PATH から 1 つ外しても
# もう一方の名前で同じ実体に届いてしまう。
#
# そこで、隠す対象を実際に含むディレクトリだけをミラーに差し替える。対象を含まない
# ディレクトリは元のまま残すので、volta shim のように自分の置き場所に依存する
# コマンド（claude）は素通りする。ミラーは解決後のパスで共有し、
# /bin と /usr/bin が二重に張られるのを防ぐ。
#
# @arg $@ string 隠す実行ファイル名（1 個以上）
# @return 0 always
# @stdout 組み立てた PATH
_path_hiding() {
  local -a _hidden=("$@")
  local -a _entries=()
  local -a _result=()
  local -A _mirrors=()

  # `IFS=':' read -ra` は末尾の空フィールドを落とす。PATH の末尾の `:` は
  # 「カレントディレクトリも探す」を意味する有効な要素なので、手で分解する。
  local _rest="$PATH"
  while true; do
    _entries+=("${_rest%%:*}")
    [[ "$_rest" == *:* ]] || break
    _rest="${_rest#*:}"
  done

  local _entry _probe _resolved _hide _found
  for _entry in "${_entries[@]}"; do
    # 空の要素はカレントディレクトリを指す。隠す対象がそこに居れば見逃せない
    _probe="${_entry:-.}"
    if [[ ! -d "$_probe" ]]; then
      _result+=("$_entry")
      continue
    fi

    _found=0
    for _hide in "${_hidden[@]}"; do
      if [[ -x "${_probe}/${_hide}" ]]; then
        _found=1
        break
      fi
    done
    if [[ $_found -eq 0 ]]; then
      _result+=("$_entry")
      continue
    fi

    # ミラーの共有キーも、ミラーに渡すパスも解決後のものを使う。
    # 未解決のまま渡すと相対リンクができ、ミラーの中から解決できなくなる
    _resolved="$(readlink -f "$_probe")" || return 1
    if [[ -z "${_mirrors[$_resolved]:-}" ]]; then
      _mirrors[$_resolved]="$(_mirror_dir_hiding "$_resolved" "${_hidden[@]}")" || return 1
    fi
    _result+=("${_mirrors[$_resolved]}")
  done

  local _joined
  _joined="$(printf '%s:' "${_result[@]}")"
  printf '%s' "${_joined%:}"
}

# _run_generate_doc_with_path - PATH を指定して main をサブプロセスで起動する
#
# 前提: setup_deckrd_tmpdir が済んでいること（DECKRD_TMPDIR / DECKRD_LOCAL /
#       DECKRD_DOCS_DIR が tmpdir を指していること）。
#
# @arg $1 string 起動時に使う PATH
# @arg $@ string generate-doc.sh へ追加で渡す引数（省略可）
# @return generate-doc.sh の終了ステータス
# @stdout generate-doc.sh の標準出力
# @stderr generate-doc.sh の標準エラー出力
_run_generate_doc_with_path() {
  local _path="$1"
  shift

  local _session
  _session="$(_write_session)"

  env -u CLAUDECODE \
    SESSION_FILE="$_session" \
    DECKRD_DOCS="${DECKRD_DOCS_DIR}" \
    DECKRD_AI_TIMEOUT="$_AI_TIMEOUT_SEC" \
    PATH="$_path" \
    bash "${SUBCOMMANDS_DIR}/generate-doc.sh" @requirements "$_CONTEXT_INPUT" \
    --output "$_OUTPUT_RELATIVE_PATH" "$@" </dev/null
}

# _run_generate_doc - 実行環境の PATH のまま main をサブプロセスで起動する
#
# @arg $@ string generate-doc.sh へ追加で渡す引数（省略可）
# @return generate-doc.sh の終了ステータス
# @stdout generate-doc.sh の標準出力
# @stderr generate-doc.sh の標準エラー出力
#
# SC2120 抑止: 引数を渡す呼び出しは `When run _run_generate_doc --verbose` の形でしかなく、
# ShellSpec の DSL 行は静的解析から関数呼び出しに見えないため検出されない。
# shellcheck disable=SC2120
_run_generate_doc() {
  _run_generate_doc_with_path "$PATH" "$@"
}

# _expected_deckrd_base - 設定ダンプに現れるはずの deckrd_base 行
#
# @return 0 always
# @stdout "deckrd_base=<解決後のパス>"
_expected_deckrd_base() {
  printf 'deckrd_base=%s/%s' "$DECKRD_DOCS_DIR" "$_SESSION_ACTIVE"
}

# _count_body_noise_lines - 生成された本文に混ざってはならない行を数える
#
# issue #205 の核心は「AI CLI の出力や終了コードが本文へ流れ込む」ことだった。
# `Error:` で始まる行と、数字だけの行（終了コードがそのまま落ちた形）を数える。
# 「雑音が 0 行」は、本文が実際に書かれて初めて意味を持つ。実行が失敗した場合や
# 本文が空の場合に 0 を返すと「書かれていないのに通る」テストになるので、
# それぞれ数値にならない文字列を返して呼び出し側で落とす。返す文字列は
# 失敗の原因をそのまま示すので、失敗メッセージだけで切り分けられる。
#
# @return 0 always
# @stdout 見つかった行数、または失敗の原因を示す文字列
_count_body_noise_lines() {
  if ! _run_generate_doc >/dev/null 2>&1; then
    printf 'run-failed'
    return 0
  fi

  local _path="${DECKRD_DOCS_DIR}/${_SESSION_ACTIVE}/${_OUTPUT_RELATIVE_PATH}"
  if [[ ! -f "$_path" ]]; then
    printf 'no-output-file'
    return 0
  fi
  if [[ ! -s "$_path" ]]; then
    printf 'empty-output-file'
    return 0
  fi

  grep -cE '^(Error:|[0-9]+$)' "$_path" || true
}

# _run_generate_doc_jaq_only - jq を隠し jaq だけを残した PATH で main を起動する
#
# 組み立てた PATH が狙いどおりになっているかを先に確かめる。ここを確かめないと、
# 「jq が隠せていなかったので通った」ケースと本物の成功を区別できない。
# 前提が崩れていたら実行せず、原因を stderr に出して失敗させる。
#
# @arg $@ string generate-doc.sh へ追加で渡す引数（省略可）
# @return generate-doc.sh の終了ステータス、前提が崩れていれば 1
# @stdout generate-doc.sh の標準出力
# @stderr generate-doc.sh の標準エラー出力、または前提が崩れた理由
_run_generate_doc_jaq_only() {
  local _path
  _path="$(_path_hiding jq)" || return 1

  if PATH="$_path" command -v jq >/dev/null 2>&1; then
    echo "precondition failed: jq is still reachable on the constructed PATH" >&2
    return 1
  fi
  if ! PATH="$_path" command -v jaq >/dev/null 2>&1; then
    echo "precondition failed: jaq is not reachable on the constructed PATH" >&2
    return 1
  fi

  _run_generate_doc_with_path "$_path" "$@"
}

# ============================================================================
# テスト本体
# ============================================================================

Describe "T-SUB-MAINS: generate-doc.sh main"

  Skip if "integration tests are disabled" [ "${SKIP_INTEGRATION_TESTS:-1}" = "1" ]

  Before "setup_deckrd_tmpdir"
  After "teardown_deckrd_tmpdir"

  Describe "Given: 実機の AI CLI と実機の jq でのサブプロセス実行"
    Skip if "claude is not installed" command_missing claude

    Describe "When: 正常系"
      It "Then: [Normal] T-SUB-MAINS-01: --verbose 有り → 設定ダンプが session の active と ai_model を反映する"
        When run _run_generate_doc --verbose
        The status should equal 0
        The stderr should include "$(_expected_deckrd_base)"
        The stderr should include "ai_model=${_SESSION_AI_MODEL}"
      End

      It "Then: [Normal] T-SUB-MAINS-02: --verbose 無し → stderr に設定ダンプを出さない"
        When run _run_generate_doc
        The status should equal 0
        The stderr should not include "$_CONFIG_DUMP_MARKER"
      End

      It "Then: [Normal] T-SUB-MAINS-03: 生成本文に AI CLI の出力と終了コードを混ぜない"
        When call _count_body_noise_lines
        The output should equal "0"
      End
    End
  End

  Describe "Given: jq を隠し jaq だけを残した PATH でのサブプロセス実行"
    Skip if "claude is not installed" command_missing claude
    Skip if "jaq is not installed" command_missing jaq

    Describe "When: 正常系"
      It "Then: [Normal] T-SUB-MAINS-04: jq が無くても jaq 経由でセッションを読んで完走する"
        When run _run_generate_doc_jaq_only --verbose
        The status should equal 0
        # 設定ダンプの deckrd_base は session.json の active から組み立てられる。
        # この行が出ていることが「jaq がセッションを実際に読んだ」ことの証拠になる
        The stderr should include "$(_expected_deckrd_base)"
      End
    End
  End

  Describe "Given: jq と jaq の両方を隠した PATH でのサブプロセス実行"
    Describe "When: 異常系"
      It "Then: [Error] T-SUB-MAINS-05: validate_env が原因だけを stderr に出して停止する"
        When run _run_generate_doc_with_path "$(_path_hiding jq jaq)"
        The status should equal 1
        The stderr should equal "$_VALIDATE_ENV_ERROR"
        The output should equal ""
      End
    End
  End
End
