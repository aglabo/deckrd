# タスク 2: 検査 B / C / D を新しい一意性モデルに書き換える

- 対象: `runners/run-check-test-ids.sh`
- テスト: `runners/__tests__/unit/run-check-test-ids.spec.sh`
- テストコマンド: `pnpm run test:sh runners/__tests__/unit/run-check-test-ids.spec.sh`
- 作業種別: リファクタリング

タスク 1 / 1b で用意した G レコードとグループ用インデックスを、検査本体に繋ぐ。
規約は `docs/.deckrd/rules/deckrd-rule-testing-guidelines.md` の §5.4 と §6.2〜§6.5。
着手前に必ず読むこと。

## 1. 重複検査を `uniq -d` から件数比較へ

**これが本タスクの中心となる。**

`uniq -d` はソート済みで重複が隣接していることに依存する。そのために現行コードは
`load_indexed_case_ids` で全ファイル分を連結してから 1 回だけ `sort` しており、
`T-RUN-CM-10` がその並び順を固定している。

重複判定を **総数と異なり数の比較** に置き換える（§6.1）。

| 判定                | 扱い                     |
| ------------------- | ------------------------ |
| `total` が 0        | パイプラインが壊れている |
| `total` != `unique` | 重複あり                 |
| `total` == `unique` | 合格                     |

ID は既に配列に載っているので、**連想配列で出現回数を数える。**
`sort` とパイプを使わずに済み、fork は 0 個。重複した ID の一覧もその場で得られる。
`uniq -d` は使わない。

`extract_case_ids` / `extract_group_ids` の「ソート済みで出す」公開契約は
報告のために残すが、**検査の合否はその並び順に依存しない。**

`total == 0` の扱いは走査範囲で分ける。

- 検査 B: そのモジュールが spec を 1 本も所有しない、または ID が 0 個 →
  今までどおり警告して合格とする（テストをまだ書いていないモジュールは正当）
- 検査 C: spec ファイルが 1 本以上あるのにグループ ID が 0 個 → **失格**。
  これは抽出が壊れている状態であり、現行のように警告して合格にしてはならない

## 2. 検査 B (`check_module`) — §6.3

そのモジュールの `owns` 配下について、次の 5 つを確認する。

1. ケース宣言の行がすべて well-formed なケース ID を持つ（現行の U レコード経路のまま）
2. **各ケース ID の `T-<scope>-<target>` 部分が、直前のグループ ID と一致する。**
   一致しない場合はファイルと行を挙げてエラー。
   直前のグループが 1 つも無い位置にあるケースも、同じくエラーとする
3. グループ ID の総数と異なり数が一致する
4. ケース ID の総数と異なり数が一致する（同一グループ内の連番衝突を捕える）
5. **グループ ID** の第 1 セグメントが、そのモジュールの `test_scope` と一致する

現行はケース ID の scope を見ているが、規則 2 でケースはグループに従属するので、
グループ ID の scope を見れば足りる。

## 3. 検査 C (`check_duplicates`) — §6.4

全テストファイルから **グループ ID** を集め、総数と異なり数を比較する。
**ケース ID の全件照合は廃止する。**

グループ ID が全体で一意であり（本検査）、各ケースが自分のグループに属し
連番が重複しなければ（検査 B）、ケース ID の全体一意性はそこから従う。

重複が出たら、その ID を宣言しているファイルを挙げる。
`locate_case_id` にあたるグループ版が要る（`_GROUP_FILES_BY_ID` を引く）。

## 4. 検査 D (`check_targets`) — §6.5

**グループ ID** の第 2 セグメントを綴りのまま取り出し、略語表と `comm` で突き合わせる。
ケース ID からは取らない。1 グループにつき 1 回だけ数える。

### 削除するもの

- `load_layer_suffix` / `layer_suffix` / `_LAYER_SUFFIX`
- `base_targets` の末尾 1 文字を落とす処理
- spec 側の `T-RUN-LS-*`（`Describe 'T-RUN-LS: layer_suffix() / load_layer_suffix()'` ごと）

レイヤは略語の綴りの一部であり、切り離さない（§5.1）。
`CINI` を `CIN` と `I` に分けない。

## 5. `load_case_records` の改名

タスク 1 で `scan_case_declarations` を `scan_spec_declarations` に改めたが、
ローダは取り残された。いまやグループ用を含む 6 本のインデックスを組み立てるので、
名前が実体を表していない。

- `load_case_records` → `load_spec_records`
- `_CASE_RECORDS_ROOT` → `_SPEC_RECORDS_ROOT`
- `_CASE_RECORDS_VALID` → `_SPEC_RECORDS_VALID`

`reset_check_caches` とその検証ケースも追随させること。

## 6. フィクスチャに埋まっている §5.4 違反の解消

コードレビューが指摘した 3 箇所は、1 つのグループの下に他グループのケース ID を
置いている。検査 B の規則 2 を入れると、これらは自分でエラーになる。

- `T-RUN-CM-10`
- `T-RUN-BT-01`
- `T-RUN-CT-02`

いずれも `_add_spec_file … 'T-ALP-AA' 'T-ALP-AA-01' 'T-ALP-BB-01'` の形をしている。
`T-ALP-BB-01` の前に `Describe "T-ALP-BB: …"` を足す形へ組み替える。
**`T-RUN-CM-10` が本来固定していた「重複がファイル境界をまたいで隣接しない」性質を
壊さないこと。** 件数比較に変えたことでこの性質は検査の前提ではなくなるが、
ケース自体は残し、何を固定しているかをコメントで書き直す。

## 触ってはならないもの

- 検査 A (`check_scopes`) の判定ロジック
- `scan_spec_declarations` の走査ロジックとレコード書式
- `extract_case_ids` / `extract_group_ids` / `find_unidentified_cases` の公開 stdout 契約
- `docs/.deckrd/deckrd/runners/module.md`（略語表は後続タスクでまとめて直す）

## 完了時に期待される状態

- 当該 spec の全ケースが green
- `pnpm run check:test-ids` は **RED のまま**。検査 B が
  「ケース ID が直前のグループ ID と一致しない」を 36 ファイル分、約 760 件報告する。
  これは移行がまだ済んでいないためであり、本タスクの失敗ではない。
  `runners/__tests__/unit/run-check-test-ids.spec.sh` だけは 0 件であること
- 検査 D は `LS` が未使用になった分だけ報告が増える
