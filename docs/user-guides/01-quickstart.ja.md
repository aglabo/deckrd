---
title: deckrd クイックスタートガイド
description:
type: userguide
scope: deckrd, deckrd-coder
audience:
  - 新規ユーザー
  - 開発者
purpose:
  - deckrd の基本的な使い方を素早く把握する
  - 新機能開発の典型的なフローを理解する
meta:
  author: atsushifx
  version: 0.1.0
---

<!--textlint-disable
  ja-technical-writing/sentence-length -->
<!-- markdownlint-disable line-length -->

## deckrd クイックスタートガイド

deckrd は **Goals → Requirements → Specifications → Implementation → Tasks** の流れで、
目標から実行可能なタスクリストを段階的に導出するフレームワークです。

## 概要

| プラグイン     | コマンド                  | 目的                           |
| -------------- | ------------------------- | ------------------------------ |
| `deckrd`       | `/deckrd <command>`       | 要件・仕様・タスクの段階的導出 |
| `deckrd-coder` | `/deckrd-coder <task-id>` | BDD スタイルでの実装           |

## 典型的なワークフロー

```bash
/deckrd init        # プロジェクト初期化
/deckrd module      # モジュール作成
/deckrd req         # 要件導出
/deckrd spec        # 仕様導出
/deckrd impl        # 実装計画
/deckrd tasks       # タスクリスト生成
/deckrd-coder T01   # BDD 実装
```

---

## Step 1: プロジェクト初期化

```bash
/deckrd init <project-name> <project-type>
```

例:

```bash
/deckrd init my-app library
```

**何が起きるか:**

- `.local/deckrd/project.json` — プロジェクト設定
- `.local/deckrd/session.json` — セッション状態
- `docs/.deckrd/` — ドキュメント格納ディレクトリ
- `.claude/rules/` — deckrd ルールファイル群

---

## Step 2: モジュール作成

機能単位でモジュールを作成します。

```bash
/deckrd module <namespace>/<module>
```

例:

```bash
/deckrd module http/retry-client
```

**命名規則:**

- 小文字のみ（大文字不可）
- ハイフン・アンダースコア使用可
- `namespace/module` 形式で指定

**何が起きるか:**

```text
docs/.deckrd/http/retry-client/
├── requirements/
├── specifications/
├── implementation/
└── tasks/
```

---

## Step 3: 要件導出

モジュールの要件を AI との対話で明確にします。

```bash
/deckrd req
```

**フロー:**

1. 目標・背景を入力（自由記述）
2. Claude が質問を通じて要件を深掘り（最大 5 ラウンド）
3. `requirements/requirements.md` を生成

**入力例:**

```text
HTTP クライアントにリトライ機能を追加したい。
一時的なネットワークエラーに対して自動リトライし、
最大リトライ回数と間隔を設定できるようにしたい。
```

---

## Step 4: 仕様導出

要件から具体的な仕様を導出します。

```bash
/deckrd spec
```

**フロー:**

1. 要件を読み込み、コードを調査
2. 設計方針のドラフトを提示
3. ユーザーレビューで設計を確定
4. `specifications/specifications.md` を生成

---

## Step 5: 実装計画

仕様から実装計画を導出します（コードは書かない）。

```bash
/deckrd impl
```

**フロー:**

1. 仕様を読み込み、実装方針のドラフト提示
2. フェーズ分解・コミット単位への分割
3. `implementation/implementation.md` を生成

> 注意:
> `impl` はコード設計の文書化です。実際のコードは `/deckrd-coder` が担当します。

---

## Step 6: タスクリスト生成

実装計画から実行可能なタスクリストを生成します。

```bash
/deckrd tasks
```

**出力ファイル:**

- `tasks/tasks.md` — タスク一覧
- `tasks/implementation-checklist.md` — BDD 実装チェックリスト

**タスク ID 形式:**

```text
T-<Target>-<Scenario>-<Case>
例: T-01-01-01 （RetryClient, 正常リトライ, 3回成功）
```

---

## Step 7: BDD 実装

タスクを 1 つずつ BDD スタイルで実装します。

```bash
/deckrd-coder <task-id>
```

例:

```bash
/deckrd-coder T01-01
```

**実行フロー**:

deckrd-coder はオーケストレーター専用です。BDD 実装（Red → Green → Refactor）は **bdd-coder** エージェントに委譲します。

| Phase   | 内容                                                    |
| ------- | ------------------------------------------------------- |
| Phase 0 | 開発環境検出（言語・テストフレームワーク・lint 設定）   |
| Phase 1 | tasks.md・チェックリストからタスク情報取得              |
| Phase 2 | タスク間の依存関係分析（直列 / 並列グループ分類）       |
| Phase 3 | bdd-coder に委譲して BDD 実装（Red → Green → Refactor） |
| Phase 4 | 全体品質ゲート（lint + 型チェック + テスト）            |
| Phase 5 | 完了確認（チェックリスト全項目）                        |
| Phase 6 | セッション終了（コミットはユーザーが手動実施）          |

> **原則:** bdd-coder は 1 タスクずつ起動。複数タスクの同時実装は NG。

---

## その他のコマンド

### 進捗確認

```bash
/deckrd status
```

現在のステップとドキュメント生成状況を表示します。

### ドキュメントレビュー

```bash
/deckrd review req              # 要件レビュー（explore フェーズ）
/deckrd review spec --phase harden  # 仕様レビュー（harden フェーズ）
```

| フェーズ  | 目的                        |
| --------- | --------------------------- |
| `explore` | ギャップ・曖昧点の発見      |
| `harden`  | MUST/SHALL による要件の強化 |
| `fix`     | 一貫性の正規化              |

### 決定記録（Decision Records）

設計上の重要な判断を記録します。

```bash
/deckrd dr --add
```

req/spec/impl/tasks いずれのステップ中でも実行できます。

### リバースエンジニアリング

既存コードからドキュメントを生成します。

```bash
/deckrd rev --to req    # 既存コードから要件ドキュメント生成
```

---

## 既存コードがある場合のフロー

```bash
/deckrd init <project> <type>
/deckrd module <ns>/<mod>
/deckrd rev --to req        # ここから開始（コード → 要件）
/deckrd spec
/deckrd impl
/deckrd tasks
/deckrd-coder <task-id>
```

---

## ゲートルール

コマンドは順序通りに実行すしてください。スキップは不可です。

```text
init → module → req → [dr] → spec → impl → tasks → deckrd-coder
```

現在のステップを確認するには `/deckrd status` を使用してください。

---

## セッションファイル

deckrd はセッション状態を `.local/deckrd/session.json` で管理します。
通常、このファイルを直接編集する必要はありません。

複数モジュールを切り替える場合は、`/deckrd module` でアクティブモジュールを変更します。

---

## 関連ドキュメント

- [アーキテクチャ概要](../developer-guides/architecture.md)
- [プラグインシステム](../developer-guides/plugin-system.md)
- [開発ワークフロー](../developer-guides/workflow.md)
- [deckrd コマンドリファレンス](../developer-guides/deckrd-commands.md)
