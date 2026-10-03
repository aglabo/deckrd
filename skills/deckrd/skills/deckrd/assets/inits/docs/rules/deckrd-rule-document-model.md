---
title: "Deckrd Rule: ドキュメントモデル"
description: "設計チェーン・ID 採番・ドキュメント命名・ディレクトリ配置を定める統一モデル"
version: 1.5.2
---

<!-- textlint-disable
  ja-technical-writing/sentence-length,
  ja-technical-writing/max-comma,
  -->

## Deckrd Rule: ドキュメントモデル

Deckrd の設計ドキュメントは、種別ごとに ID 書式・ファイル名・置き場所が決まっている。
この 3 つは常に同時に決まるため、本ルール 1 本にまとめて定義する。

本ルールに現れる `docs/.deckrd/` は既定のドキュメントルートを指す。プロジェクトが
ドキュメントルートを上書きしている場合、このパスは設定済みのルートに読み替える。
読み替えは本ルールが示すすべてのパスとコマンドの検索対象に及ぶ。

## 1. 設計チェーン

Deckrd プロジェクトは次の依存フローを維持する。

```text
REQ → SPEC → TASK → IMPL → TEST → COMMIT
```

下流のドキュメントは、必ず上流の ID を参照する。参照のないドキュメントは
チェーンから切れており、変更の影響範囲を追跡できない。

## 2. 種別の定義

| 種別 | 役割                                | ID 書式  | ファイル名           | 置き場所          |
| ---- | ----------------------------------- | -------- | -------------------- | ----------------- |
| REQ  | システムが持つ能力を定義する        | REQ-XXX  | `req-NNN-<slug>.md`  | `requirements/`   |
| SPEC | 振る舞いと制約を定義する            | SPEC-XXX | `spec-NNN-<slug>.md` | `specifications/` |
| TASK | 実装のための設計作業を定義する      | TASK-XXX | `task-NNN-<slug>.md` | `tasks/`          |
| IMPL | コミット 1 個分の実装単位を定義する | IMPL-XXX | `impl-NNN-<slug>.md` | `implementation/` |
| TEST | 検証基準を定義する                  | TEST-XXX | `test-NNN-<slug>.md` | 上流種別に準ずる  |

TEST が定義した検証基準を実装するテストコードの構造は
[Testing Guidelines](deckrd-rule-testing-guidelines.md) に従う。

### ファイル名の規則

`<prefix>-<number>-<slug>.md`

- `number`: 連番、3 桁ゼロ埋め (`001`, `002`, `003`)
- `slug`: 小文字・ケバブケース・人が読んで意味が分かること

```text
req-001-cli-input.md
spec-001-cli-input-format.md
task-001-parser-design.md
impl-001-cli-parser.md
test-001-cli-input.md
```

## 3. ID の採番

- ID は一意でなければならない
- ID を再利用してはならない
- ドキュメントは自身の ID を frontmatter で宣言する

```yaml
---
id: REQ-001
title: CLI Input Support
status: approved
---
```

**採番にあたるのは frontmatter の `id:` 宣言だけとする。** 他のドキュメントの散文中で ID を
参照することは常に許される。

### 名前空間

同じ主題が複数のモジュールに現れる場合、ベース ID を再利用しない。
後から作る方に名前空間セグメントを足す。**元の番号はリナンバーしない。**

```text
REQ-001      ベース
REQ-F-001    機能要件の名前空間
REQ-NF-001   非機能要件の名前空間
```

新しい名前空間セグメントを導入する前に、未使用であることを確認する。

```bash
grep -rl "REQ-<new-namespace>-" --include=*.md docs/.deckrd/
```

ここで定めるのはドキュメントの ID に限る。テストコードのケースに割り当てる
テストケース ID の第 1 セグメント (`test_scope`) は、本ルールの名前空間ではなく
モジュールの `workspaces/module/module.md` が宣言する
（[Testing Guidelines](deckrd-rule-testing-guidelines.md) 参照）。

### 重複検出

「ID は一意」はドキュメントを読むだけでは担保できない。採番済み ID の台帳を手書きで
維持してはならない。チェックはドキュメント自身から導出する。

宣言済みの ID をすべて抽出し、2 回以上採番されたものを報告する。出力は空でなければならない。

```bash
grep -rhoE "^id:[[:space:]]*\S+" --include=*.md docs/.deckrd/ \
  | tr -c 'A-Za-z0-9-' '\n' \
  | grep -xE "(REQ|SPEC|TASK|IMPL|TEST)(-[A-Z0-9]+)*-[0-9]{3}" \
  | sort | uniq -d
```

報告された ID があれば、その宣言箇所を特定する。

```bash
grep -rn "<reported ID>" --include=*.md docs/.deckrd/
```

このコマンドには 3 つの要点がある。どれか 1 つでも落とすと、検出漏れか誤検出が起きる。

1. **宣言箇所に限定する** (`^id:`)。ドキュメント全体を走査すると、下流からの相互参照を
   採番と取り違える
2. **トークン境界で一致させる** (`tr -c` で分割し `grep -x` で比較)。部分一致にすると
   `REQ-F-001` の中の `001` が `REQ-001` と衝突していると報告される
3. **全ファイルを通して出現回数を数える**。ファイルごとの `sort -u` は同一ドキュメント内の
   重複を隠してしまう

## 4. ディレクトリ配置

Deckrd の成果物は、初期化されたドキュメントルート `docs/.deckrd/` 配下に置く。
ドキュメントは名前空間・モジュールの 2 階層でモジュールごとに格納する。

```text
docs/.deckrd/
  <namespace>/
    <module>/
      requirements/
      specifications/
      implementation/
      tasks/
      workspaces/
        module/
          module.md
      decision-records.md
```

セッション状態はドキュメントルート配下ではなく `.local/deckrd/session.json` にある
（[Workflow](deckrd-rule-workflow.md) 参照）。

`workspaces/module/module.md` はモジュールのメタデータを持つ。テストケース ID の
スコープ宣言 (`test_scope` / `owns`) はここに置く
（[Testing Guidelines](deckrd-rule-testing-guidelines.md) 参照）。
`/deckrd module` が生成し、テスト ID 検査が読む。`workspaces/` 配下にあっても
作業用ファイルではないので、削除・移動してはならない。

旧配置（モジュールディレクトリ直下の `module.md`）は読まれない。旧配置のまま残っている
場合は `workspaces/module/module.md` へ移す。

`workspaces/` はそのモジュールに関する、次のセッションに残すメモを置く場所とする。
作業メモ・下書き・調査結果・設計メモはここに入れる。`requirements/` などと同列の
ディレクトリとする。チェックリストやフェーズ中間生成物のように再生成できるものは
ここに置かず、`.local/deckrd/temp/` に置く（[作業用ファイルの 3 層](#作業用ファイルの-3-層) 参照）。

`workspaces/` の中身は設計チェーンの一部ではない。ID を採番せず、下流ドキュメントから
参照もしない。

### モジュールディレクトリに置いてよいファイル

置いてよいファイルは次の表のとおりとする。これ以外のファイルは、モジュールに関するもので
あってもすべて `workspaces/` に入れる。

| 場所                                                         | 置いてよいもの                                                                           |
| ------------------------------------------------------------ | ---------------------------------------------------------------------------------------- |
| モジュールディレクトリ直下                                   | `decision-records.md`、および上のツリーが示す 5 つのディレクトリ                         |
| `requirements/` `specifications/` `tasks/` `implementation/` | [2. 種別の定義](#2-種別の定義) が定めるファイル名、集約ファイル、分割時の index ファイル |
| `workspaces/module/`                                         | `module.md`（作業用ファイルを置かない）                                                  |

規定のファイルだけが並んでいれば、一覧を見たときに消してよいものと消してはならないものが
区別できる。作業用ファイルが混ざると、正規のドキュメントごと誤って削除・編集する危険がある。

ドキュメントルート直下も同様とし、モジュールに関する作業用ファイルを置いてはならない。

例:

```text
docs/.deckrd/chatlog/normalize/
  requirements/requirements.md
  specifications/specifications.md
  implementation/implementation.md
  tasks/tasks.md
  workspaces/module/module.md
  workspaces/rename-lib-sh-notes.md
  decision-records.md
```

やってはならない配置:

```text
docs/.deckrd/chatlog/normalize/
  todo.md                            # モジュール直下の作業メモ
  requirements/req-draft-memo.md     # 規定の命名でない下書き
```

どちらも `workspaces/` に移す。

### 作業用ファイルの 3 層

作業用ファイルは `workspaces/` だけではない。**git 追跡の有無で 3 層に分ける。**

| 層             | 置き場所                              | git 追跡 | 置くもの                                                       |
| -------------- | ------------------------------------- | -------- | -------------------------------------------------------------- |
| 一時作業       | `.local/deckrd/temp/`                 | しない   | チェックリスト、フェーズ中間生成物、環境プロファイル、進捗ログ |
| 共通メモ       | `.local/deckrd/workspaces/`           | する     | モジュールに属さない、残すべきメモ                             |
| モジュールメモ | `docs/.deckrd/<ns>/<mod>/workspaces/` | する     | モジュール単位のメモ                                           |

振り分けは 2 問で決まる。

1. **次のセッションに残す必要があるか。** No なら一時作業層に置く
2. Yes なら、**特定のモジュールに属するか。** 属するならモジュールメモ、属さないなら共通メモ

コマンドやエージェントが生成する中間ファイルは、ほぼすべて一時作業層に当たる。
`codebase-context.md`・`prior-art.md`・`codebase-extraction.md`・`env-profile.md` は
機械生成であり、同じコマンドを再実行すれば作り直せる。人が書いたメモと同じ場所に置くと、
消してよいものと消してはならないものが混ざる。

一時作業層は git 追跡しない。**再生成できるものだけを置く。**
追跡されないため、消えても復元されない。

`.local/deckrd/` 配下の 2 つは、それぞれ `DECKRD_LOCAL_TEMP` と
`DECKRD_LOCAL_WORKSPACES` が指す。`DECKRD_LOCAL_TEMP` が環境変数で上書きされている場合は、
その値に読み替える。`DECKRD_LOCAL_WORKSPACES` は常に `${DECKRD_LOCAL_DATA}/workspaces` であり、
上書きできない。共通メモ層は `.local/deckrd/.gitignore` の許可リストで追跡されるため、
`DECKRD_LOCAL_DATA` の外には置けない。

### 仕様書を分割する場合

領域ごとに 1 ファイルとし、必ず index ファイルを追加する（spec コマンド参照）。

```text
specifications/specifications-index.md
specifications/specifications-auth.md
specifications/specifications-notify.md
```

## Common Rationalizations

| 言い訳                                                           | 反論                                                                                         |
| ---------------------------------------------------------------- | -------------------------------------------------------------------------------------------- |
| 番号が飛ぶのは気持ち悪いのでリナンバーする                       | 上流 ID は下流から参照されている。振り直せば参照先が静かに別物を指す                         |
| この ID は削除したドキュメントのものだから再利用してよい         | 過去のコミットメッセージや履歴が旧 ID を指したまま残り、追跡が壊れる                         |
| 採番済み ID の一覧をメモに書いておけば十分                       | メモは更新されなくなる。ドキュメント自身から導出できるものを二重管理しない                   |
| 作業メモは一時的なので置き場所はどこでもよい                     | 置き場所が決まっていないメモは他の人から見えず、同じ調査が繰り返される                       |
| requirements/ の中の下書きなら設計チェーンの一部だから置いてよい | 規定の命名に従わないファイルは下流から参照できない。正規のドキュメントに紛れて誤って消される |
| 中間生成物も調査結果なのでモジュールの workspaces に入れる       | 機械生成物は再実行で作り直せる。人が書いたメモと混ぜると、消してよいものが判別できなくなる   |
