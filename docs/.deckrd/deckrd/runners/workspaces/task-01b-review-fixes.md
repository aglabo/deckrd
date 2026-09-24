# タスク 1b: タスク 1 のレビュー指摘の是正

- 対象: `runners/run-check-test-ids.sh`
- テスト: `runners/__tests__/unit/run-check-test-ids.spec.sh`
- テストコマンド: `pnpm run test:sh runners/__tests__/unit/run-check-test-ids.spec.sh`
- 作業種別: リファクタリング（タスク 1 の続き。検査 A/B/C/D の判定ロジックは変えない）

コードレビューが挙げた 4 件を潰す。いずれも走査層の穴か、コメントと実装の食い違いにあたる。

## 1. 宣言パターンが ShellSpec の語彙を取りこぼしている

ShellSpec の DSL 定義（`.tools/shellspec/lib/libexec/grammar/dsls`）は次のとおり。

```text
 ExampleGroup |  Describe |  Context  =>   block_example_group
xExampleGroup | xDescribe | xContext  => x block_example_group
fExampleGroup | fDescribe | fContext  => f block_example_group
 Example      |  Specify  |  It       =>   block_example
xExample      | xSpecify  | xIt       => x block_example
fExample      | fSpecify  | fIt       => f block_example
Todo                                  =>   todo
```

現在の `GROUP_DECL_PATTERN` は `Describe|Context` しか見ていないため、
`ExampleGroup` / `xDescribe` / `fContext` などで宣言されたグループ ID が
**まるごと見えない**。見えないグループ ID は検査 C で「重複なし」と読める。
検査が黙って無力化される種類の穴なので塞ぐ。

```bash
readonly GROUP_DECL_PATTERN='^[[:space:]]*[xf]?(ExampleGroup|Describe|Context)[[:space:]]'
readonly CASE_DECL_PATTERN='^[[:space:]]*[xf]?(Example|Specify|It)[[:space:]]'
```

- `Todo` は ID を持たない placeholder なので **含めない**
- `Example` は `ExampleGroup` の prefix だが、末尾の `[[:space:]]` が両者を分ける。
  `ExampleGroup` はケース宣言に一致してはならない。これをテストで固定すること
- 追加したすべての綴りについて、グループ側・ケース側それぞれ 1 ケースは検証する
  （テーブル駆動にしてよい。ループはグループの内側・ケースの外側に置くこと）

## 2. グループ ID のアンカーが 1 つもテストされていない

`scan_spec_declarations` の awk に渡す `group_id` の `^(...)$` アンカーを外しても
**129 examples が 1 つも落ちない** ことをレビューが実測している。アンカーを外すと
`Describe "XT-AAA-BB: …"` が `G XT-AAA-BB` を、`Describe "T-AAA-BB-01 …"` が
`G T-AAA-BB-01` を出す。

- `extract_group_ids` に対し、`Describe "XT-AAA-BB: …"` が空出力になるケースを足す
- `Describe "T-AAA-BB-01: …"` がグループ ID を出さないケースを足す

## 3. `T-RUN-EGI-06` のコメントが嘘をついている

spec の 300 行目付近のコメントは
「トークン完全一致を外すと `T-RUN-IWH-01` の中の `T-RUN-IWH` が拾われて RED」
と書いているが、そのフィクスチャは `It` 行なのでグループ分岐に到達しない。
このケースが通るのはコメントが書いている理由とは別の理由による。

**間違ったガードコメントは、テストが無いことより悪い。** 次に読む人に
「その場合は押さえてある」と誤解させる。実際に何を固定しているかに書き直すこと。

## 4. レコード書式の根拠コメントが実装と矛盾している

`scan_spec_declarations` の `@stdout` ブロック（154-158 行目付近）と 212-214 行目付近は、
5 欄固定の理由を「5 変数の `read` で可変長の内容が最後の変数へ入るため」と
説明している。しかし 596-600 行目付近は、`IFS=$'\t' read -r kind a b c d` では
**それが成り立たない** と述べている（bash は TAB を IFS 空白として扱うため
連続 TAB が 1 個の区切りに潰れる）。だから 605-613 行目付近はパラメータ展開で
4 つの区切りを剥がしている。

`@stdout` だけを読んだ人は、この剥がし処理を冗長だと判断して「整理」し、
バグを戻す。実際の契約に書き直すこと。

- 5 欄固定であること
- 先頭 4 欄はパラメータ展開で剥がすこと。`read` の多変数分割は使えないこと
- 可変長の内容は最後に置くこと

## 5. `U` レコードの内容欄の TAB が `load_case_records` を通り抜けていない

内容欄の TAB を検証しているのは `find_unidentified_cases` の awk/`substr` 経路
（`T-RUN-FUC-07`）だけで、`load_case_records` のパラメータ展開経路には 1 ケースも無い。
レビューが `d` を最初の TAB で切り捨てる変異を入れて全 129 examples を走らせ、
**1 つも落ちない** ことを実測している。

`T-RUN-LCR-03` のフィクスチャが `_append_line` で書く内容に `${_TAB}` を入れ、
期待値も合わせること。これで剥がし処理が最後の欄を丸ごと保つことが固定される。

## 触ってはならないもの

- 検査 A/B/C/D の判定ロジック — `check_scopes` / `check_module` / `check_duplicates` / `check_targets`
- `load_layer_suffix` / `layer_suffix`
- `extract_case_ids` / `find_unidentified_cases` の公開 stdout 契約
- `docs/.deckrd/deckrd/runners/module.md`（略語表は後続タスクでまとめて直す）

## 扱わないもの（後続タスクに送る）

- `_add_spec_file` が作る 3 つのフィクスチャに埋まっている §5.4 ケース所属違反
- `load_case_records` の名前がグループ用インデックスまで含むようになった件
