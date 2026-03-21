---
title: deckrd コマンドガイド
description: deckrd の全コマンドを図解で解説するユーザーガイド
type: userguide
scope: deckrd
audience:
  - 新規ユーザー
  - 開発者
purpose:
  - 各コマンドの役割・入出力・フローを視覚的に把握する
  - コマンド選択の判断基準を理解する
meta:
  author: atsushifx
  version: 0.1.0
---

<!--textlint-disable
  ja-technical-writing/sentence-length -->
<!-- markdownlint-disable line-length -->

## deckrd コマンドガイド

このガイドでは、deckrd の全コマンドを図解付きで解説します。

---

## ワークフロー全体図

deckrd は **Goals → Requirements → Specifications → Implementation → Tasks** の順に
ドキュメントを導出するフレームワークです。各コマンドが 1 つのステップに対応しています。

```text
       【プロジェクト準備】
              |
    /deckrd init <project> <type>
              |
              v
     .local/deckrd/project.json
     .local/deckrd/session.json
              |
    /deckrd module <ns>/<mod>
              |
              v
docs/.deckrd/<ns>/<mod>/  (ディレクトリ作成)
              |
              |
       【ドキュメント導出ループ】
              |
              v
    /deckrd req  (要件導出)
              |
              v
     requirements/requirements.md
              |
     (任意) /deckrd review req
     (任意) /deckrd dr --add
              |
              v
    /deckrd spec  (仕様導出)
              |
              v
   specifications/specifications.md
              |
     (任意) /deckrd review spec
              |
              v
    /deckrd impl  (実装計画)
              |
              v
    implementation/implementation.md
              |
              v
    /deckrd tasks  (タスク生成)
              |
              v
     tasks/tasks.md
     tasks/implementation-checklist.md
              |
              |
       【BDD 実装フェーズ】
              |
              v
    /deckrd-coder <task-id>
              |
              v
          実装完了
```

---

## コマンド一覧

| コマンド | 役割                     | 入力                 | 出力                                      |
| -------- | ------------------------ | -------------------- | ----------------------------------------- |
| `init`   | プロジェクト初期化       | project名・type      | `project.json`, `session.json`            |
| `module` | モジュール作成           | namespace/module 名  | `docs/.deckrd/<ns>/<mod>/` ディレクトリ   |
| `req`    | 要件導出                 | ユーザーの目標・制約 | `requirements.md`                         |
| `spec`   | 仕様導出                 | `requirements.md`    | `specifications.md`                       |
| `impl`   | 実装計画導出             | `specifications.md`  | `implementation.md`                       |
| `tasks`  | タスク生成               | `implementation.md`  | `tasks.md`, `implementation-checklist.md` |
| `review` | ドキュメントレビュー     | 任意のドキュメント   | レビュー結果（任意: DR追記）              |
| `dr`     | 決定記録追加             | 設計判断の文脈       | `decision-records.md` (追記)              |
| `status` | 進捗確認                 | —                    | 現在ステップ・完了状況の表示              |
| `rev`    | リバースエンジニアリング | 既存コード           | 指定フェーズのドキュメント                |

---

## init — プロジェクト初期化

```bash
/deckrd init <project> <project-type> [OPTIONS]
```

### 入出力図

```text
ユーザー入力
┌─────────────────────────────────┐
│ project:      myapp             │
│ project-type: webapp            │
│ --language:   typescript        │  (省略時: typescript)
│ --ai-model:   sonnet            │  (省略時: sonnet)
└─────────────────────────────────┘
             |
             v
/deckrd init myapp webapp --language typescript
             |
             v
┌─────────────────────────────────────────────────┐
│ 生成ファイル                                     │
│                                                 │
│  .local/deckrd/                                 │
│  ├── project.json   ← プロジェクト設定           │
│  └── session.json   ← セッション状態             │
│                                                 │
│  docs/.deckrd/                                  │
│  ├── notes/                                     │
│  └── temp/                                      │
│                                                 │
│  .claude/rules/     ← deckrd ルールファイル群    │
└─────────────────────────────────────────────────┘
```

### Options

| オプション           | デフォルト   | 説明                                          |
| -------------------- | ------------ | --------------------------------------------- |
| `--language <lang>`  | `typescript` | `typescript`, `go`, `python`, `rust`, `shell` |
| `--ai-model <model>` | `sonnet`     | 使用するAIモデル                              |

### 実行例

```bash
/deckrd init myapp webapp                              # 最小構成
/deckrd init myapp lib --language go                   # Go プロジェクト
/deckrd init myapp webapp --language typescript --ai-model claude-sonnet-4-5
```

> 注意:
> リポジトリごとに 1 回だけ実行します。

---

## module — モジュール作成

```bash
/deckrd module <namespace>/<module> [--force]
/deckrd module <module> [--force]          # AI が namespace を自動類推
/deckrd module create <namespace>/<module> [--force]
/deckrd module create <module> [--force]
```

### 入出力図

```text
ユーザー入力
┌──────────────────────────────┐
│ namespace: http              │
│ module:    retry-client      │
└──────────────────────────────┘
             |
             v
/deckrd module http/retry-client
             |
             v
┌─────────────────────────────────────────────┐
│ 生成ディレクトリ                              │
│                                             │
│  docs/.deckrd/http/retry-client/            │
│  ├── requirements/                          │
│  ├── specifications/                        │
│  ├── implementation/                        │
│  └── tasks/                                 │
│                                             │
│  session.json (active モジュール更新)         │
└─────────────────────────────────────────────┘
```

### module 名だけ指定した場合の AI 類推フロー

```text
/deckrd module user-login
             |
             v
AI が docs/.deckrd/ をスキャン
             |
        ┌────┴────────────────────────────┐
        │ 既存: auth/session, auth/token  │
        └────────────────────────────────┘
             |
             v
AI: "auth/user-login と推測しました。実行しますか？ (y/n)"
             |
        y ───┘
             v
bash module.sh auth/user-login
```

### namespace 類推の優先順位

```text
優先度 1: docs/.deckrd/ 内の既存 namespace と意味的マッチング
優先度 2: namespace が 1 つだけ → それを使用
優先度 3: project.json に namespace フィールドあり → それを使用
優先度 4: module名のキーワードから類推 (例: auth-* → auth)
優先度 5: git remote origin のリポジトリ名にフォールバック
```

### 命名規則

| ルール         | 詳細                                       |
| -------------- | ------------------------------------------ |
| 使用可能文字   | `a-z`、ハイフン `-`、アンダースコア `_`    |
| 大文字・小文字 | 小文字のみ（大文字は拒否）                 |
| フォーマット   | `namespace/module` 形式（`/` が 1 つ必須） |

---

## req — 要件導出

```bash
/deckrd req
```

### 実行フロー

```text
/deckrd req
     |
     v
Phase 0: コードベース調査
     |   └─ explore-agent に委譲
     |       └─ temp/deckrd-work/codebase-context.md 生成
     |
     v  (並行して)
Phase 1: ユーザー入力収集
     |   └─ 目標・制約・背景を自由記述で入力
     |
     v
Phase 1-D: システムコンテキスト図の生成 (ASCII)
     |
     v
Phase 2: ヒアリングループ (最大 5 ラウンド)
     |   └─ 1 ラウンドにつき質問 1 問
     |   └─ EARS 要素 (GIVEN/WHEN/WHILE/NOT DO) を確認
     |   └─ 終了条件: ユーザーが "OK" / 5 要件確認済み
     |
     v
Phase 3: ドキュメント生成
     |   └─ generate-doc.sh を実行
     |
     v
Phase 4: レビューループ (最大 3 ラウンド)
     |   └─ セルフレビュー → ユーザー確認 → 必要なら再生成
     |   └─ 承認で終了
     |
     v
requirements/requirements.md 生成
     |
     v
session.json 更新 (current_step: "req")
```

### 入出力

```text
 入力: ユーザーの目標・制約（自由記述）
       └─ 例: "HTTP クライアントにリトライ機能を追加したい"

 出力: docs/.deckrd/<ns>/<mod>/requirements/requirements.md
       └─ 機能要件 (REQ-F-xxx)
       └─ 非機能要件 (REQ-NF-xxx)
       └─ ユーザーストーリー
       └─ 受け入れ基準 (Gherkin 形式)
```

---

## spec — 仕様導出

```bash
/deckrd spec
```

### 実行フロー

```text
/deckrd spec
     |
     v
requirements.md を読み込み
     |
     v
コードベース調査 (既存実装の確認)
     |
     v
設計方針のドラフト提示
     |
     v
ユーザーレビュー・確定
     |
     v
specifications/specifications.md 生成
     |
     v
session.json 更新 (current_step: "spec")
```

### 入出力

```text
 入力: requirements/requirements.md

 出力: docs/.deckrd/<ns>/<mod>/specifications/specifications.md
       └─ インターフェース定義
       └─ 振る舞い仕様
       └─ 制約・前提条件
       └─ エラーハンドリング仕様
```

---

## impl — 実装計画導出

```bash
/deckrd impl
```

### 実行フロー

```text
/deckrd impl
     |
     v
specifications.md を読み込み
     |
     v
実装フェーズの分割
┌───────────────────────────────┐
│ Phase 1: インターフェース定義  │
│ Phase 2: コア実装             │
│ Phase 3: エラー処理           │
│ Phase 4: テスト               │
└───────────────────────────────┘
     |
     v
コミット単位への分解
     |
     v
ユーザー確認
     |
     v
implementation/implementation.md 生成
     |
     v
session.json 更新 (current_step: "impl")
```

> 注意:
> `impl` はコードを書かない。設計の文書化のみ (コード実装は `/deckrd-coder` が担当します)。

---

## tasks — タスクリスト生成

```bash
/deckrd tasks
/deckrd tasks update   # implementation-checklist.md のみ再生成
```

### 実行フロー

```text
/deckrd tasks
     |
     v
implementation.md + specifications.md を読み込み
     |
     v
BDD スタイルのタスクに分解
┌────────────────────────────────────────┐
│ T-01: [Target] - [Scenario] - [Case]  │
│ T-02: ...                             │
│ T-03: ...                             │
└────────────────────────────────────────┘
     |
     v
tasks/tasks.md 生成
tasks/implementation-checklist.md 生成
     |
     v
session.json 更新 (current_step: "tasks")
```

### 出力ファイル

```text
tasks/
├── tasks.md
│   └─ タスク一覧 (ID, 目的, 受け入れ基準)
└── implementation-checklist.md
    └─ BDD 実装用チェックリスト
```

### タスク ID 形式

```text
T-<Target>-<Scenario>-<Case>
例: T-01-01-01 (RetryClient, 正常リトライ, 3回成功)
```

---

## review — ドキュメントレビュー

```bash
/deckrd review                              # ヘルプ表示
/deckrd review <doc_phase> [--phase <p>]    # ドキュメントをレビュー
/deckrd review --phase <p> @<path>          # パス直接指定
```

### 3 つのレビューフェーズ

```text
┌─────────────────────────────────────────────────────────┐
│  explore (デフォルト)                                    │
│  ├─ ペルソナ: 設計レビュアー                             │
│  ├─ 目的: ギャップ・曖昧点・代替案の発見                 │
│  └─ 言語: SHOULD / MAY のみ（MUST / SHALL は禁止）       │
├─────────────────────────────────────────────────────────┤
│  harden                                                 │
│  ├─ ペルソナ: 規範的要件レビュアー                       │
│  ├─ 目的: SHOULD → MUST へ昇格・設計決定の確定           │
│  └─ 副作用: DR (Decision Record) を自動生成・追記        │
├─────────────────────────────────────────────────────────┤
│  fix                                                    │
│  ├─ ペルソナ: Spec 監査人                                │
│  ├─ 目的: 用語統一・テスト可能性確認・整合性チェック     │
│  └─ 言語: 新規要件追加は禁止（整理のみ）                 │
└─────────────────────────────────────────────────────────┘
```

### レビューフェーズの使い分け

```text
 req 直後 ─────────────────→ review req --phase explore
                               └─ 抜け漏れ・曖昧点を発見

 spec 前  ─────────────────→ review req --phase harden
                               └─ MUST/SHALL に昇格 + DR 生成

 spec 後  ─────────────────→ review spec --phase explore
                               └─ 仕様の網羅性を確認

 impl 前  ─────────────────→ review spec --phase fix
                               └─ 用語・整合性を統一してから次へ
```

### 実行例

```bash
/deckrd review req                            # 要件を explore でレビュー
/deckrd review req --phase harden             # 要件を harden (DR 生成)
/deckrd review spec --phase fix               # 仕様を fix でクリーンアップ
/deckrd review --phase explore @requirements/requirements.md
```

---

## dr — 決定記録 (Decision Records)

```bash
/deckrd dr --add
```

### 位置づけ

```text
 req / spec / impl / tasks の「任意のタイミング」で実行可能

 /deckrd req
      |
      ├──→ /deckrd dr --add  ← 設計判断が発生したときに随時追記
      |
 /deckrd spec
      |
      ├──→ /deckrd dr --add
      |
 /deckrd impl
      |
      ├──→ /deckrd dr --add
```

### 出力

```text
docs/.deckrd/<ns>/<mod>/decision-records.md (追記形式)
└─ DR-001: タイトル
└─ DR-002: タイトル
└─ ...
```

> 注意:
> `tasks` 完了後の追加には確認が必要です。

---

## status — 進捗確認

```bash
/deckrd status
```

### 表示内容

```text
┌────────────────────────────────────────┐
│ Active module: http/retry-client       │
│                                        │
│ Progress:                              │
│   [x] init                             │
│   [x] module                           │
│   [x] req      → requirements.md       │
│   [x] spec     → specifications.md     │
│   [ ] impl                             │
│   [ ] tasks                            │
│                                        │
│ Current step: impl                     │
└────────────────────────────────────────┘
```

---

## rev — リバースエンジニアリング

```bash
/deckrd rev [--from code] [--to req|spec|impl|tasks]
```

### 用途

既存コードや PoC があり、ドキュメントが存在しない場合に使います。

### フロー

```text
既存コード
     |
     v
/deckrd rev --to req
     |
     v
コードを静的解析・調査
     |
     v
requirements/requirements.md を生成
     |
     v  (通常のフローに合流)
/deckrd spec
/deckrd impl
/deckrd tasks
```

### rev の対象フェーズ選択

```text
コード → req のみ逆引き     : /deckrd rev --to req
コード → spec まで逆引き    : /deckrd rev --to spec
コード → impl まで逆引き    : /deckrd rev --to impl  (req+spec が必要)
```

---

## ゲートルール（コマンド順序の制約）

deckrd のコマンドは、順序通りに実行してください。スキップはできません。

```text
init → module → req → [dr] → spec → impl → tasks → deckrd-coder
 ↑必須   ↑必須    ↑必須  ↑任意    ↑必須   ↑必須   ↑必須
```

| 現在のステップ | 次に実行できるコマンド    |
| -------------- | ------------------------- |
| (none)         | `init`                    |
| init 完了      | `module`                  |
| module 完了    | `req`                     |
| req 完了       | `spec`（または `dr`）     |
| spec 完了      | `impl`（または `dr`）     |
| impl 完了      | `tasks`（または `dr`）    |
| tasks 完了     | `/deckrd-coder <task-id>` |
| 任意           | `review`, `status`, `dr`  |

---

## ワークフロー選択ガイド

### 新規機能開発

```text
/deckrd init <project> <type>
/deckrd module <ns>/<mod>
/deckrd req
/deckrd spec
/deckrd impl
/deckrd tasks
/deckrd-coder <task-id>
```

### 既存コードからドキュメント生成

```text
/deckrd init <project> <type>
/deckrd module <ns>/<mod>
/deckrd rev --to req          ← ここから開始
/deckrd spec
/deckrd impl
/deckrd tasks
/deckrd-coder <task-id>
```

### ドキュメント品質を高めてから次フェーズへ

```text
/deckrd req
/deckrd review req                  ← explore で抜け漏れチェック
/deckrd review req --phase harden   ← MUST/SHALL 昇格 + DR 生成
/deckrd spec
/deckrd review spec --phase fix     ← 用語・整合性の統一
/deckrd impl
/deckrd tasks
```

---

## 関連ドキュメント

- [クイックスタートガイド](01-quickstart.ja.md)
- [アーキテクチャ概要](../developer-guides/architecture.md)
- [開発ワークフロー](../developer-guides/workflow.md)
- [deckrd コマンドリファレンス](../developer-guides/deckrd-commands.md)
