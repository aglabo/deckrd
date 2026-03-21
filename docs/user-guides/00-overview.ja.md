---
title: deckrd オーバービュー
description: deckrd フレームワークの全体像を図解で示すリファレンス図集
type: userguide
scope: deckrd, deckrd-coder
audience:
  - 初めて deckrd を使うユーザー
  - 全体像を把握したい開発者
purpose:
  - deckrd の構成・ワークフロー・コマンド関係を一目で把握する
meta:
  author: atsushifx
  version: 0.1.0
---

<!--textlint-disable
  ja-technical-writing/sentence-length -->
<!-- markdownlint-disable line-length -->

## deckrd オーバービュー

---

## 図 1: deckrd とは

```text
   アイデア・目標
         │
         ▼
┌────────────────┐
│  /deckrd req   │  → requirements.md   何を作るか
├────────────────┤
│  /deckrd spec  │  → specifications.md どう動くべきか
├────────────────┤
│  /deckrd impl  │  → implementation.md どう作るか
├────────────────┤
│  /deckrd tasks │  → tasks.md          何をするか (BDD)
└────────────────┘
         │
         ▼
/deckrd-coder <task-id>   ← コードを書く
         │
         ▼
      実装完了
```

---

## 図 2: 全体構成

```text
┌─────────────────────────────────────────────────────────────────┐
│                         Claude Code CLI                         │
│                                                                 │
│  ┌──────────────────────┐   ┌────────────────────────────────┐  │
│  │   deckrd             │   │   deckrd-coder                 │  │
│  │                      │   │                                │  │
│  │  init / module       │   │  /deckrd-coder <task-id>       │  │
│  │  req / spec          │   │                                │  │
│  │  impl / tasks        │   │  Red → Green → Refactor        │  │
│  │  review / dr / rev   │   │                                │  │
│  └──────────────────────┘   └────────────────────────────────┘  │
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │  IDD Framework (外部)                                    │   │
│  │  /idd/issue:new   /idd-commit-message   /idd-pr          │   │
│  └──────────────────────────────────────────────────────────┘   │
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │  MCP サーバー                                            │   │
│  │  cocoindex-code (コード検索)   filesystem (ファイル操作) │   │
│  └──────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

---

## 図 3: プラグインの役割分担

```text
           deckrd                        deckrd-coder
┌────────────────────────┐     ┌────────────────────────┐
│                        │     │                        │
│  /deckrd req           │     │  /deckrd-coder T01     │
│  /deckrd spec          │────▶│                        │──▶ 実装完了
│  /deckrd impl          │tasks│  Red   (テスト失敗)    │
│  /deckrd tasks         │     │  Green (実装)          │
│                        │     │  Refactor (整理)       │
└────────────────────────┘     └────────────────────────┘
     設計・文書化                      BDD 実装
```

---

## 図 4: 標準ワークフロー

```text
┌─────────────────────────────────────────────────────────────┐
│ フェーズ 1: IDD — 課題定義                                  │
│   /idd/issue:new  →  GitHub Issue 作成  →  ブランチ作成     │
└───────────────────────────────┬─────────────────────────────┘
                                │
┌───────────────────────────────▼─────────────────────────────┐
│ フェーズ 2: deckrd — 設計・計画                             │
│                                                             │
│  /deckrd init                                               │
│       │                                                     │
│       ▼                                                     │
│  /deckrd module <ns>/<mod>                                  │
│       │                                                     │
│       ▼                                                     │
│  /deckrd req  ──────────────▶  requirements.md              │
│       │  (任意) /deckrd review req                          │
│       │  (任意) /deckrd dr --add                            │
│       ▼                                                     │
│  /deckrd spec  ─────────────▶  specifications.md            │
│       │  (任意) /deckrd review spec                         │
│       ▼                                                     │
│  /deckrd impl  ─────────────▶  implementation.md            │
│       ▼                                                     │
│  /deckrd tasks ─────────────▶  tasks.md                     │
│                               implementation-checklist.md   │
└───────────────────────────────┬─────────────────────────────┘
                                │
┌───────────────────────────────▼─────────────────────────────┐
│ フェーズ 3: deckrd-coder + IDD — 実装・PR                   │
│                                                             │
│  /deckrd-coder T01  →  BDD 実装  →  /idd-commit-message     │
│  /deckrd-coder T02  →  BDD 実装  →  /idd-commit-message     │
│         :                               ▼                   │
│                               /idd-pr  →  GitHub PR 作成    │
└─────────────────────────────────────────────────────────────┘
```

---

## 図 5: rev パス（既存コードから）

```text
既存コード
     │
     ▼
/deckrd init + module
     │
     ▼
/deckrd rev --to req
     │
     ▼  ← 通常フローに合流
/deckrd spec
/deckrd impl
/deckrd tasks
     │
     ▼
/deckrd-coder <task-id>
```

---

## 図 6: ドキュメント生成チェーン

```text
ユーザー入力（目標・制約）
        │
        ▼
┌─────────────┐
│ req         │  → requirements.md
│  (5 rounds) │     REQ-F-xxx / REQ-NF-xxx / Gherkin
└──────┬──────┘
       │ reads requirements.md
       ▼
┌─────────────┐
│ spec        │  → specifications.md
│             │     IF 定義 / 振る舞い仕様
└──────┬──────┘
       │ reads specifications.md
       ▼
┌─────────────┐
│ impl        │  → implementation.md
│             │     フェーズ分割 / コミット単位
└──────┬──────┘
       │ reads implementation.md + specifications.md
       ▼
┌─────────────┐
│ tasks       │  → tasks.md  (T-01-01-01 形式)
│             │  → implementation-checklist.md
└─────────────┘
```

---

## 図 7: ディレクトリ構造

```text
プロジェクトルート/
├── .local/deckrd/
│   ├── project.json          ← プロジェクト設定
│   └── session.json          ← 進捗・アクティブモジュール
│
├── .claude/rules/            ← deckrd ルール (init で配置)
│
└── docs/.deckrd/
    └── <namespace>/<module>/
        ├── requirements/
        │   └── requirements.md
        ├── specifications/
        │   └── specifications.md
        ├── implementation/
        │   └── implementation.md
        ├── tasks/
        │   ├── tasks.md
        │   └── implementation-checklist.md
        └── decision-records.md   (任意)
```

---

## 図 8: アーキテクチャ層

```text
┌──────────────────────────────────────────────────────┐
│  Layer 1: Claude Code CLI  (/deckrd コマンド入力)    │
└──────────────────────┬───────────────────────────────┘
                       │
┌──────────────────────▼───────────────────────────────┐
│  Layer 2: プラグイン                                 │
│   deckrd (設計)   deckrd-coder (実装)   IDD (GitHub) │
└──────────────────────┬───────────────────────────────┘
                       │
┌──────────────────────▼───────────────────────────────┐
│  Layer 3: MCP サーバー                               │
│   cocoindex-code (検索)   filesystem (ファイル操作)  │
└──────────────────────┬───────────────────────────────┘
                       │
┌──────────────────────▼───────────────────────────────┐
│  Layer 4: 品質ゲート                                 │
│   dprint / markdownlint / textlint / shellcheck      │
│   gitleaks / secretlint / commitlint                 │
└──────────────────────────────────────────────────────┘
```

---

## 図 9: ゲートルールとコマンド順序

```text
init → module → req → [dr] → spec → impl → tasks → deckrd-coder
 ↑必須    ↑必須    ↑必須  ↑任意    ↑必須   ↑必須    ↑必須
                                               review / status: 任意
```

---

## 図 10: ワークフロー選択

```text
新しい機能を作りたい
         │
         ├─ 既存コードあり ─▶ /deckrd rev --to req ─┐
         │                                          │
         └─ ゼロから       ─▶ /deckrd req           ┘
                                    │
                                    ▼
                            /deckrd spec → impl → tasks
                                    │
                    ┌───────────────┴───────────────┐
                    │                               │
                複雑な変更                     バグ修正・小変更
                    │                               │
             deckrd-coder で実装             IDD のみ (issue→PR)
```
