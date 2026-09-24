---
title: "Deckrd Rule: ドキュメントモデル"
description: "設計チェーン・ID 採番・ドキュメント命名・ディレクトリ配置を定める統一モデル"
version: 2.0.0
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
モジュールの `workspaces/modules/module.md` が宣言する
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
        modules/
          module.md
      temp/
        checklists/
      decision-records.md
```

セッション状態はドキュメントルート配下ではなく `.local/deckrd/session.json` にある
（[Workflow](deckrd-rule-workflow.md) 参照）。

`module.md` はモジュールのメタデータを持つ。テストケース ID のスコープ宣言
(`test_scope` / `owns`) はここに置く
（[Testing Guidelines](deckrd-rule-testing-guidelines.md) 参照）。
設計チェーンの成果物ではなくモジュール自身のメタデータであるため、`requirements/` などと
同列には置かず、`workspaces/modules/` に置く。

### 作業用ファイルの置き場所

作業用ファイルは `workspaces/` と `temp/` の 2 つに分ける。**分ける基準は
仕様書チェーンに紐づくかどうかの 1 点とする。**

| ディレクトリ  | 置くもの                                                   | Git        |
| ------------- | ---------------------------------------------------------- | ---------- |
| `workspaces/` | 調査結果、設計メモ、レビュー記録。チェーンに紐づく作業成果 | 管理する   |
| `temp/`       | スクラッチ、下書き、コマンド出力、一時ログ                 | 管理しない |

`temp/` が Git に載らないことは `**/temp/` が保証する。したがって置き場所を選ぶことが、
そのまま残すかどうかを選ぶことになる。ファイル名で判断してはならない。

判断に迷ったときは次の問いに答える。

| 問い                                       | Yes           | No            |
| ------------------------------------------ | ------------- | ------------- |
| 消えたら他の人が同じ調査をやり直すか       | `workspaces/` | `temp/`       |
| 後からレビューや決定の根拠として引かれるか | `workspaces/` | `temp/`       |
| コマンド出力・その場限りの下書きか         | `temp/`       | `workspaces/` |

**迷ったら `workspaces/` に置く。** `temp/` に入れてよいのは、消えても誰も困らないものだけとする。

手書きの作業チェックリストは `temp/checklists/` に置く。
`tasks/implementation-checklist.md` は `tasks` コマンドが生成する設計チェーンの成果物であり、
これとは別物とする。`tasks/` に置き、Git で管理する。

### 置いてよいファイル

置いてよいファイルは次の表のとおりとする。これ以外のファイルは、モジュールに関するもので
あってもすべて `workspaces/` か `temp/` に入れる。

| 場所                                                         | 置いてよいもの                                                                           |
| ------------------------------------------------------------ | ---------------------------------------------------------------------------------------- |
| モジュールディレクトリ直下                                   | `decision-records.md`、および上のツリーが示す 6 つのディレクトリ                         |
| `requirements/` `specifications/` `tasks/` `implementation/` | [2. 種別の定義](#2-種別の定義) が定めるファイル名、集約ファイル、分割時の index ファイル |
| `workspaces/modules/`                                        | `module.md` のみ                                                                         |
| `workspaces/`（`modules/` 以外）                             | チェーンに紐づく作業ファイル                                                             |
| `temp/`                                                      | チェーンに紐づかない一時ファイル                                                         |

規定のファイルだけが並んでいれば、一覧を見たときに消してよいものと消してはならないものが
区別できる。作業用ファイルが混ざると、正規のドキュメントごと誤って削除・編集する危険がある。

ドキュメントルート直下も同様とし、モジュールに関する作業用ファイルを置いてはならない。

`workspaces/` と `temp/` の中身は設計チェーンの一部ではない。ID を採番せず、下流ドキュメントから
参照もしない。

例:

```text
docs/.deckrd/chatlog/normalize/
  requirements/requirements.md
  specifications/specifications.md
  implementation/implementation.md
  tasks/tasks.md
  tasks/implementation-checklist.md
  workspaces/modules/module.md
  workspaces/rename-lib-sh-survey.md
  temp/checklists/rename-lib-sh-checklist.md
  temp/grep-output.txt
  decision-records.md
```

やってはならない配置:

```text
docs/.deckrd/chatlog/normalize/
  module.md                          # モジュール直下のメタデータ
  todo.md                            # モジュール直下の作業メモ
  requirements/req-draft-memo.md     # 規定の命名でない下書き
  temp/design-review-notes.md        # 後から引かれる記録を temp に置いている
```

`module.md` は `workspaces/modules/` へ、残りの作業用ファイルは内容に応じて `workspaces/`
か `temp/` へ移す。最後の 1 行はレビューで引かれる記録なので `temp/` ではなく `workspaces/` とする。

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
| 消せる場所のほうが気楽なので作業メモは全部 temp/ に入れる        | `temp/` は Git に載らない。調査結果を入れれば他の人から見えず、同じ調査が繰り返される        |
| module.md は今まで直下にあったのだから直下でよい                 | 直下は正規のドキュメントだけが並ぶ場所とする。メタデータが混ざると一覧で区別できなくなる     |
