# タスク 1: グループ宣言の走査とインデックス

対象: `runners/run-check-test-ids.sh`
テスト: `runners/__tests__/unit/run-check-test-ids.spec.sh`
テストコマンド: `pnpm run test:sh runners/__tests__/unit/run-check-test-ids.spec.sh`
作業種別: リファクタリング（外部から見える検査結果は本タスクでは変えない）

本タスクは走査層とインデックス層だけを扱う。検査 A/B/C/D の判定ロジックは
次のタスクで変更するため、**本タスクでは触らない**。

## 背景

テスト ID の規約が変わった。新しい規約は
`docs/.deckrd/rules/deckrd-rule-testing-guidelines.md` の §5.1 / §5.4 / §6.1 にある。
着手前に必ず読むこと。要点だけ再掲する。

- ID は 2 段になった。グループ ID `T-<scope>-<target>` を機能階層の `Describe` が
  宣言し、ケース ID `T-<scope>-<target>-<NN>[-<NN>]` を `It` が持つ
- グループ ID はケース ID の prefix なので、**両者を同じパターンで拾ってはならない**
- ケースがどのグループに属するかは、入れ子を追わずに判定する。宣言は上から順に
  現れるので、ファイルを 1 度なぞり「直前に現れたグループ ID」を覚えておけばよい

## 実装すること

### 1. 文法定数

```bash
readonly GROUP_DECL_PATTERN='^[[:space:]]*(Describe|Context)[[:space:]]'
readonly CASE_DECL_PATTERN='^[[:space:]]*(It|Example)[[:space:]]'
readonly GROUP_ID_PATTERN='T-[A-Z0-9]{2,4}-[A-Z0-9]+'
readonly TEST_ID_PATTERN='T-[A-Z0-9]{2,4}-[A-Z0-9]+-[0-9]{2}(-[0-9]{2})?'
```

`TEST_ID_PATTERN` は現在 `(-[A-Z0-9]+)+` で target セグメントを複数許しているが、
1 個に固定する。トークン境界での完全一致（`split` + アンカー付き照合）は現状のまま
維持すること。これにより `T-RUN-IWH-01` が `GROUP_ID_PATTERN` に一致することはない。

### 2. 走査 `scan_case_declarations` → `scan_spec_declarations`

`Describe` / `Context` 行も走査対象に加える。awk が線形走査するあいだに「直前の
グループ ID」を保持し、`I` レコードに載せる。

レコードは **すべて 5 フィールド固定**とし、TAB を含みうる可変長の内容を必ず最後に置く。

```text
G <TAB> <グループ ID> <TAB> <file> <TAB> <line> <TAB> (空)
I <TAB> <ケース ID>   <TAB> <file> <TAB> <line> <TAB> <直前のグループ ID / 無ければ空>
U <TAB> <file> <TAB> <line> <TAB> (空) <TAB> <宣言行の内容>
```

`U` の 4 番目を空で埋めるのは、`read -r kind a b c d` で読んだとき宣言行の内容が
必ず最後の変数に入るようにするため。`U` の内容欄は TAB を含みうる。

現行の設計制約は維持すること。

- 読めない引数は awk に渡す前に落とし、`>&2` に警告する（gawk は最初の読めない
  引数で全体を中断し、以降のファイルを読まない。黙って ID 一覧が短くなる）
- 単一 awk 実行。走査ごとにファイルを読み直さない

`extract_case_ids` / `find_unidentified_cases` の **公開 stdout 契約は変えない**。
`find_unidentified_cases` は今までどおり `<file><TAB><line><TAB><内容>` の 3 欄を出す。

新しい公開ラッパー `extract_group_ids` を足す。`extract_case_ids` と同じ規約
（`sort` は全ファイル読み終えてから 1 回、`sort -u` は使わない）に従う。

### 3. インデックス `load_case_records`

既存の `_CASE_IDS_BY_FILE` / `_CASE_FILES_BY_ID` / `_UNIDENT_BY_FILE` に加えて足す。

- `_GROUP_IDS_BY_FILE` — ファイル → そのファイルが宣言するグループ ID の一覧
- `_GROUP_FILES_BY_ID` — グループ ID → 宣言しているファイルの一覧（`_CASE_FILES_BY_ID`
  と同じ「全項目一致」の入れ方にすること）
- `_CASE_GROUP_BY_RECORD` — ケース ID の出現ごとの「直前のグループ ID」。
  所属違反の報告にはファイルと行も要るので、`<case id><TAB><group id><TAB><file><TAB><line>`
  をファイル単位で持つ形でよい

`case "$kind"` の分岐に `G` を足す。分岐の無い kind が読み飛ばされる現在の性質は保つ。
`reset_check_caches` は新しい連想配列もすべて空にすること（このテストが
`T-RUN-RCC-01` にある。全グローバルを数えているので期待値の更新が要る）。

**fork を増やさないこと。** `load_case_records` は awk の exec とプロセス置換の 2 回で
収まっている。ループの中にコマンド置換・パイプ・ヒアストリング・`sort` を入れない。
Windows では fork 1 回が 0.11〜0.13 秒かかり、全体の実行時間はほぼ fork 数で決まる。

## テスト

`runners/__tests__/unit/run-check-test-ids.spec.sh` に対して行うこと。

- 内部ヘルパー `_add_spec_file` を、`Describe` 行と `It` 行の両方を書き出す形に変える。
  グループ ID を引数で受け、その配下にケースを並べる。既存の呼び出し側
  （擬似 scope `AAA` `ALP` `BET` `DUP` `STA` `OLD` `NEW` `OUT` `AB` `ABCD` の
  フィクスチャ約 155 件）が追従できるようにすること
- 新規ケース: グループ ID の抽出、`I` レコードへの直前グループ ID の付与、
  グループが 1 つも無い位置のケース、`U` レコードの 5 欄化
- 既存の `T-RUN-SCD-*` / `T-RUN-ECI-*` / `T-RUN-FUC-*` / `T-RUN-LCR-*` /
  `T-RUN-RCC-*` は新しいレコード書式に合わせて期待値を更新する
- このファイル自身のテスト ID も新規約に移すこと。機能階層の `Describe` に
  グループ ID を付ける（例: `Describe 'T-RUN-SCD: scan_spec_declarations()'`）。
  `It` 行の ID 文字列は変えない。`scan_spec_declarations` への改名に伴い、
  略語 `SCD` の対象名だけ読み替える

このタスクで `load_layer_suffix` / `layer_suffix` / 検査 A/B/C/D の判定ロジックを
変更してはならない。
