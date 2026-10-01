#!/usr/bin/env bash
# skills/deckrd/skills/deckrd/scripts/__tests__/unit/spec-helper.unit.spec.sh
# @(#) : BDD unit tests for spec_helper.sh - setup_deckrd_tmpdir / teardown_deckrd_tmpdir /
#        sandbox isolation invariant / path_outside_repo
#
# Copyright (c) 2026- atsushifx <https://github.com/atsushifx>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

# cspell:words SHTD

# ============================================================================
# テスト基盤
# ============================================================================

# bootstrap.lib.sh を `--no-finalize` で source する。
#
# 実行時と同じ初期状態を再現するために要る。bootstrap は DECKRD_LOCAL_* を
# 「実リポジトリの」 .local/deckrd/ 配下として export するので、この source を
# 省くと「実リポジトリのパスが残る」状態そのものを検証できない。
# `--no-finalize` は readonly 化を抑える。finalize 済みでは setup_deckrd_tmpdir の
# 代入が失敗する。
#
# ここで DECKRD_LOCAL_TEMP / DECKRD_LOCAL_WORKSPACES を unset してはならない。
# 隔離はテスト対象である setup_deckrd_tmpdir の責務であり、
# spec 側で先に消すと欠陥が隠れる。
# shellcheck disable=SC1090
_RUNTIME_BOOTSTRAP="${SHELLSPEC_PROJECT_ROOT}/skills/deckrd/skills/deckrd/scripts/libs/bootstrap.lib.sh"
. "$_RUNTIME_BOOTSTRAP" --no-finalize
unset _RUNTIME_BOOTSTRAP

# ============================================================================
# テスト対象
# ============================================================================

Include ../spec_helper.sh

# ============================================================================
# 内部ヘルパー
# ============================================================================

# 定数

# _SPEC_HELPER_SCAN_DIR - sandbox 隔離不変条件の静的検査が走査するルート。
# cli / libs / subcommands の __tests__/spec_helper.sh がこの下に入る。
# deckrd の scripts/ ツリーに限るのは意図的である。runners/__tests__/spec_helper.sh
# などは DECKRD_LOCAL_* に触れないため、不変条件の対象ではない
_SPEC_HELPER_SCAN_DIR="${SHELLSPEC_PROJECT_ROOT}/skills/deckrd/skills/deckrd/scripts"

# _SPEC_HELPER_GLOB - 静的検査が拾うファイル名。テストハーネス本体だけを見る。
# 違反件数を数える側と走査件数を数える側で共有する。別々に書くと片方だけ直され、
# 対照としての意味が失われる
_SPEC_HELPER_GLOB='spec_helper.sh'

# _KNOWN_SPEC_HELPERS - 走査が必ず覆っていなければならないハーネスのパス末尾。
# 各要素は _SPEC_HELPER_SCAN_DIR の最終セグメント（`scripts`）から始まる相対パスであり、
# 走査ルートの下に実在するハーネスを全件挙げる。モジュールを足したらこの一覧にも足す
_KNOWN_SPEC_HELPERS=(
  'scripts/__tests__/spec_helper.sh'
  'scripts/libs/__tests__/spec_helper.sh'
  'scripts/subcommands/__tests__/spec_helper.sh'
)

# _RELATIVE_LOCAL_PATH - リポジトリ外と断言できない相対パス。
# cwd 次第でリポジトリ内を指すので、path_outside_repo は偽を返さなければならない
_RELATIVE_LOCAL_PATH='.local/deckrd/temp'

# _SANDBOX_ANCHOR_VAR - 不変条件の起点となる変数名。これを差し替えるファイルは
# 対の変数も差し替えていなければならない
_SANDBOX_ANCHOR_VAR='DECKRD_LOCAL_DATA'

# _SANDBOX_TEMP_VAR - 起点と対で差し替えられていなければならない変数名（temp 側）
_SANDBOX_TEMP_VAR='DECKRD_LOCAL_TEMP'

# _SANDBOX_WORKSPACES_VAR - 起点と対で差し替えられていなければならない変数名（workspaces 側）
_SANDBOX_WORKSPACES_VAR='DECKRD_LOCAL_WORKSPACES'

# 関数

# _both_local_dirs_exported - setup_deckrd_tmpdir が DECKRD_LOCAL_TEMP と
#                             DECKRD_LOCAL_WORKSPACES を子プロセスへ export するかを報告する
#
# 判定の前に teardown_deckrd_tmpdir を呼び、2 変数を属性ごと消してから setup をやり直す。
# bash の export 属性は後続の素の代入をまたいで残るため、この作り直しを省くと
# spec 冒頭で source した bootstrap.lib.sh が付けた属性を setup の手柄として数えてしまい、
# setup から export を落とした実装が通ってしまう。
#
# 先に teardown を呼ぶので、呼び出し側の Before が作った一時ディレクトリはここで片付く。
# 順序を入れ替えると一時ディレクトリが追跡不能になりリークする。
#
# 子 bash の `export -p` は export された変数だけを挙げる。子プロセスとして起動される
# スクリプトが読むのはこの一覧なので、代入だけで export を忘れた実装はこの形でしか捕まらない。
#
# @return 0 if both variables are exported, 1 otherwise
# shellcheck disable=SC2329
_both_local_dirs_exported() {
  teardown_deckrd_tmpdir
  setup_deckrd_tmpdir

  bash -c 'export -p | grep -q "^declare -x DECKRD_LOCAL_TEMP=" &&
    export -p | grep -q "^declare -x DECKRD_LOCAL_WORKSPACES="'
}

# _count_nul_records - NUL 区切りで与えたレコードの件数を報告する
#
# パス列は NUL 区切りで受け渡す。改行区切りのまま xargs へ渡すとパスが空白で
# 単語分割され、SHELLSPEC_PROJECT_ROOT に空白が含まれる環境（Windows では珍しくない）で
# grep が断片ごとにエラーを出し、違反件数が 0 件へ戻る。
#
# `wc -l` は改行を数えるので NUL 区切りの入力には使えない。NUL の個数がレコード数になる。
#
# @stdin NUL 区切りのレコード列
# @stdout レコードの件数
# @return 0 always
# shellcheck disable=SC2329
_count_nul_records() {
  tr -cd '\0' | wc -c
}

# _list_sandbox_anchor_files - _SANDBOX_ANCHOR_VAR を差し替えている spec_helper.sh を挙げる
#
# 代入の行だけを見る。行頭からその変数名までに `#` が現れない形に限ることで、
# コメント中の言及を差し替えと誤認しない。`\b` は変数名の前に別の識別子が
# 付いた形（`MY_DECKRD_LOCAL_DATA=`）を除く。
#
# 代入行の総数を数える _count_sandbox_anchor_assignments と同じ定数・同じ正規表現を
# 見る。こちらはファイル単位、あちらは行単位であり、対の検査と総数の検査が
# 同じ「代入」の定義を共有する。
#
# @stdout 差し替えているファイルのパス（NUL 区切り）
# @return grep の終了コード。呼び出し側はこれを合否に使わない
# shellcheck disable=SC2329
_list_sandbox_anchor_files() {
  grep -rlZE "^[^#]*\b${_SANDBOX_ANCHOR_VAR}=" --include="$_SPEC_HELPER_GLOB" "$_SPEC_HELPER_SCAN_DIR"
}

# _count_sandbox_anchor_assignments - ハーネス全体にある _SANDBOX_ANCHOR_VAR の
#     代入行の総数を報告する
#
# 走査範囲・ファイル名 glob・変数名は _list_sandbox_anchor_files と同じ定数
# （_SPEC_HELPER_SCAN_DIR / _SPEC_HELPER_GLOB / _SANDBOX_ANCHOR_VAR）から引く。
# 違うのは抽出の単位だけで、あちらは `-l` でファイルを挙げ、こちらは `-h` で行を挙げる。
#
# ファイル単位の判定では足りない。_count_partial_sandbox_overrides は「起点を
# 差し替えたファイルが対の変数も差し替えているか」をファイル単位で見るので、
# 起点だけを差し替える新しいヘルパーを export_sandbox_local_dirs と同じファイルへ
# 足すと、同じファイルにある対の代入が条件を満たし、違反件数は 0 件のまま通る。
# 代入が export_sandbox_local_dirs の中だけにあるのが正しい姿であり、
# 総数が 1 件であるなら部分差し替えはハーネスのどこにも書けない。
#
# grep の終了コードを合否にしない。ヒット 0 件で 1 を返すので、
# 「代入なし」と「検査そのものの失敗」が区別できなくなる。件数を数えて呼び出し側で比べる。
#
# @stdout 代入行の総数
# @return 0 always
# shellcheck disable=SC2329
_count_sandbox_anchor_assignments() {
  grep -rhE "^[^#]*\b${_SANDBOX_ANCHOR_VAR}=" --include="$_SPEC_HELPER_GLOB" "$_SPEC_HELPER_SCAN_DIR" | wc -l
}

# _count_partial_sandbox_overrides - 起点の変数だけを差し替えて対の変数を差し替え忘れた
#     spec_helper.sh の件数を報告する
#
# export_sandbox_local_dirs を使わず自前で 1 変数だけ差し替えると、残りの変数は
# 実リポジトリを指したまま残り、それを読むスクリプトが実リポジトリへ書き込む。
# ガードを spec 側に置くと新しい spec を書くたび同じ穴が開くので、
# ハーネス全体を 1 箇所で数える。
#
# grep の終了コードをそのまま合否にしない。ヒット 0 件で 1 を返すので、
# 「違反なし」と「検査そのものの失敗」が区別できなくなる。件数を数えて呼び出し側で比べる。
#
# @arg $1 string 起点と対で差し替えられていなければならない変数名
# @stdout 違反しているファイルの件数
# @return 0 always
# shellcheck disable=SC2329
_count_partial_sandbox_overrides() {
  _list_sandbox_anchor_files | xargs -0 -r grep -LZE "^[^#]*\b${1}=" | _count_nul_records
}

# _list_scanned_spec_helpers - 静的検査が走査するハーネスのパスを挙げる
#
# 走査の範囲を決める _SPEC_HELPER_SCAN_DIR と _SPEC_HELPER_GLOB を違反件数の判定と
# 共有する。`^` はどの行にも一致するので、grep が拾ったファイルがそのまま走査対象になる。
#
# @stdout 走査対象のファイルのパス（NUL 区切り）
# @return grep の終了コード。呼び出し側はこれを合否に使わない
# shellcheck disable=SC2329
_list_scanned_spec_helpers() {
  grep -rlZE '^' --include="$_SPEC_HELPER_GLOB" "$_SPEC_HELPER_SCAN_DIR"
}

# _suffix_matches_any - 与えたパス列のいずれかが指定の末尾で終わるかを報告する
#
# 末尾はディレクトリ境界で照合する。`/` を前置しないと `own-spec_helper.sh` のような
# 別のファイルを一致とみなす。
#
# @arg $1 string 照合する末尾（先頭の `/` は付けずに渡す）
# @arg $@ string 照合されるパス列
# @return 0 if one of the paths ends with the suffix, 1 if none does
# shellcheck disable=SC2329
_suffix_matches_any() {
  local suffix="$1"
  shift

  local path
  for path in "$@"; do
    [[ "$path" == *"/${suffix}" ]] && return 0
  done

  return 1
}

# _scan_covers_known_spec_helpers - 静的検査が _KNOWN_SPEC_HELPERS のすべてを
#     走査に含めているかを報告する
#
# _count_partial_sandbox_overrides の正の対照である。grep は --include のパターンが
# 1 件も一致しないとき、標準エラー出力に何も書かずに 0 件を返す。走査が空振りしても
# 「違反なし」として通るので、違反件数の判定だけでは検査が生きていることを示せない。
#
# 「1 件以上」では足りない。走査ルートを既に適合しているディレクトリ 1 つへ狭めると、
# 違反件数は 0 件、走査件数は 1 件のままなので全ケースが通るのに、
# libs と subcommands のハーネスが検査の範囲から静かに落ちる。
# 件数ではなくどのハーネスを覆ったかを見るので、範囲が縮んだこと自体が失敗になる。
#
# 件数を定数で持たない。件数だけを見ると、モジュールが増えたときに
# どのハーネスが落ちたのかが分からない。
#
# @return 0 if the scan covers every known helper, 1 if any of them is missing
# shellcheck disable=SC2329
_scan_covers_known_spec_helpers() {
  local -a scanned
  mapfile -d '' -t scanned < <(_list_scanned_spec_helpers)

  local known
  for known in "${_KNOWN_SPEC_HELPERS[@]}"; do
    _suffix_matches_any "$known" "${scanned[@]}" || return 1
  done
}

# _has_sandbox_anchor_file - 起点の変数を差し替えている spec_helper.sh が
#     1 件以上あるかを報告する
#
# _count_partial_sandbox_overrides のもう 1 つの正の対照である。違反件数の判定は
# 判定の入力（起点を差し替えているファイルの集合）が空でも 0 件を返して合格する。
# 変数名の綴りを間違えた検査が「違反なし」として通るのを防ぐ。
#
# 入力を作る _list_sandbox_anchor_files を違反件数の判定と共有するので、
# 起点の綴りが崩れればこちらが必ず落ちる。
#
# @return 0 if one or more files override the anchor variable, 1 if none do
# shellcheck disable=SC2329
_has_sandbox_anchor_file() {
  local overriding
  overriding="$(_list_sandbox_anchor_files | _count_nul_records)"

  ((overriding >= 1))
}

# ============================================================================
# テスト本体
# ============================================================================

# spec_helper.sh の一時ディレクトリハーネス。
#
# setup_deckrd_tmpdir は bootstrap.lib.sh が export する DECKRD_LOCAL_* を
# sandbox 側へ差し替え、teardown_deckrd_tmpdir はそれを元へ戻す。
# 1 変数でも実リポジトリを指したまま残ると、その変数を読むスクリプトが
# 実リポジトリへ書き込む。
Describe "T-CLI-SHTD: spec_helper.sh: setup_deckrd_tmpdir"
  Before "setup_deckrd_tmpdir"
  After "teardown_deckrd_tmpdir"

  It '[Normal] T-CLI-SHTD-01: Should: point DECKRD_LOCAL_TEMP at the sandbox temp dir'
    The variable DECKRD_LOCAL_TEMP should equal "${DECKRD_LOCAL_DATA}/temp"
  End

  It '[Normal] T-CLI-SHTD-02: Should: point DECKRD_LOCAL_WORKSPACES at the sandbox workspaces dir'
    The variable DECKRD_LOCAL_WORKSPACES should equal "${DECKRD_LOCAL_DATA}/workspaces"
  End

  It '[Normal] T-CLI-SHTD-03: Should: export both variables to child processes'
    When call _both_local_dirs_exported
    The status should be success
  End

  It '[Normal] T-CLI-SHTD-04: Should: keep DECKRD_LOCAL_TEMP outside the repository tree'
    When call path_outside_repo "${DECKRD_LOCAL_TEMP:-}"
    The status should be success
  End

  It '[Normal] T-CLI-SHTD-05: Should: keep DECKRD_LOCAL_WORKSPACES outside the repository tree'
    When call path_outside_repo "${DECKRD_LOCAL_WORKSPACES:-}"
    The status should be success
  End

  # After の 2 度目の呼び出しは teardown 側のガードにより無害である
  It '[Normal] T-CLI-SHTD-06: Should: unset both variables on teardown'
    When call teardown_deckrd_tmpdir
    The variable DECKRD_LOCAL_TEMP should be undefined
    The variable DECKRD_LOCAL_WORKSPACES should be undefined
  End
End

# spec_helper.sh の sandbox 隔離不変条件。
#
# 隔離ヘルパーが DECKRD_LOCAL_DATA を差し替えるなら、対になる DECKRD_LOCAL_* も
# 差し替えなければならない。1 変数でも実リポジトリを指したまま残ると、
# その変数を読むスクリプトが実リポジトリへ書き込む。
#
# ガードを spec 側に置く限り、新しい spec を書くたびに同じ穴が開く。
# ハーネス全体を静的に走査して不変条件そのものを検査する。
# この検査は環境変数を読まないので、一時ディレクトリの Before / After は持たない。
#
# 対の変数ごとのケースは、_count_partial_sandbox_overrides へ渡す変数名だけを変えて
# 同じ判定ロジックを呼ぶ。判定を変数ごとに書き分けると、片方だけが直されて
# もう片方が静かに取り残される。
Describe "T-CLI-SHIV: spec_helper.sh: sandbox isolation invariant"

  It '[Normal] T-CLI-SHIV-01: Should: report no helper that overrides DECKRD_LOCAL_DATA without DECKRD_LOCAL_TEMP'
    When call _count_partial_sandbox_overrides "$_SANDBOX_TEMP_VAR"
    The output should equal "0"
    # 走査パスが存在しないと grep は stderr へ `No such file or directory` を書き、
    # 終了コード 2 を返す。件数が 0 件になるのと同時に stderr が空でなくなるので、
    # パスの壊れた検査が「違反なし」として通るのを防ぐ
    The stderr should be blank
  End

  It '[Normal] T-CLI-SHIV-02: Should: report no helper that overrides DECKRD_LOCAL_DATA without DECKRD_LOCAL_WORKSPACES'
    When call _count_partial_sandbox_overrides "$_SANDBOX_WORKSPACES_VAR"
    The output should equal "0"
    The stderr should be blank
  End

  # 次の 2 ケースは違反件数の判定に対する正の対照である。
  # SHIV-03 は走査範囲を決める _SPEC_HELPER_SCAN_DIR / _SPEC_HELPER_GLOB を、
  # SHIV-04 は起点の _SANDBOX_ANCHOR_VAR を、それぞれ違反件数の判定と共有する。
  # 走査の範囲が縮んでも、起点の綴りが崩れても、
  # 違反件数だけは 0 件を返して合格してしまう。
  It '[Normal] T-CLI-SHIV-03: Should: cover every known spec_helper.sh in the scan'
    When call _scan_covers_known_spec_helpers
    The status should be success
    The stderr should be blank
  End

  It '[Normal] T-CLI-SHIV-04: Should: find at least one helper that overrides DECKRD_LOCAL_DATA'
    When call _has_sandbox_anchor_file
    The status should be success
    The stderr should be blank
  End

  # 対の有無ではなく代入の総数を見る。ファイル単位の判定では、
  # export_sandbox_local_dirs と同じファイルへ足された部分差し替えが、
  # そのファイルにある対の代入に隠れて通り抜ける。
  It '[Normal] T-CLI-SHIV-05: Should: assign DECKRD_LOCAL_DATA at exactly one place in the harness'
    When call _count_sandbox_anchor_assignments
    The output should equal "1"
    The stderr should be blank
  End
End

# spec_helper.sh のリポジトリ外判定。
#
# 隔離ヘルパーが差し替えた DECKRD_LOCAL_* が実リポジトリを指していないことを、
# T-CLI-SHTD-04 / T-CLI-SHTD-05 と libs 側の T-LIB-SHNC-04 / T-LIB-SHNC-05 /
# T-LIB-SHNC-07 はこの述語 1 本で判定している。述語の土台が緩いと、
# それらのケースがまとめて盲目になる。
#
# 緩さは 2 つの入力に現れる。絶対パスでない入力（未設定の変数が `${VAR:-}` で
# 空文字列になった形と、cwd 次第でリポジトリ内を指す相対パス）を「外」と報告すると、
# 変数を差し替え忘れた実装がそのまま通る。どちらも偽であることを要求する。
Describe "T-CLI-SHPO: spec_helper.sh: path_outside_repo"

  It '[Normal] T-CLI-SHPO-01: Should: report an empty path as not outside the repository'
    When call path_outside_repo ""
    The status should be failure
  End

  It '[Normal] T-CLI-SHPO-02: Should: report a relative path as not outside the repository'
    When call path_outside_repo "$_RELATIVE_LOCAL_PATH"
    The status should be failure
  End
End
