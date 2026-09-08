---
title: "Deckrd Rule: ドキュメントモデル"
description: "設計チェーン・ID 採番・ドキュメント命名・ディレクトリ配置を定める統一モデル"
version: 1.1.0
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
モジュール直下の `module.md` が宣言する
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
      module.md
      requirements/
      specifications/
      implementation/
      tasks/
      decision-records.md
```

セッション状態はドキュメントルート配下ではなく `.local/deckrd/session.json` にある
（[Workflow](deckrd-rule-workflow.md) 参照）。

`module.md` はモジュールのメタデータを持つ。テストケース ID のスコープ宣言
(`test_scope` / `owns`) はここに置く
（[Testing Guidelines](deckrd-rule-testing-guidelines.md) 参照）。

例:

```text
docs/.deckrd/chatlog/normalize/
  module.md
  requirements/requirements.md
  specifications/specifications.md
  implementation/implementation.md
  tasks/tasks.md
  decision-records.md
```

### 仕様書を分割する場合

領域ごとに 1 ファイルとし、必ず index ファイルを追加する（spec コマンド参照）。

```text
specifications/specifications-index.md
specifications/specifications-auth.md
specifications/specifications-notify.md
```

## Common Rationalizations

| 言い訳                                                   | 反論                                                                       |
| -------------------------------------------------------- | -------------------------------------------------------------------------- |
| 番号が飛ぶのは気持ち悪いのでリナンバーする               | 上流 ID は下流から参照されている。振り直せば参照先が静かに別物を指す       |
| この ID は削除したドキュメントのものだから再利用してよい | 過去のコミットメッセージや履歴が旧 ID を指したまま残り、追跡が壊れる       |
| 採番済み ID の一覧をメモに書いておけば十分               | メモは更新されなくなる。ドキュメント自身から導出できるものを二重管理しない |
