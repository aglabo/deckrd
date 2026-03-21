---
title: deckrd ユーザーガイド インデックス
description: deckrd フレームワークの概要とユーザーガイド一覧
type: userguide
scope: deckrd, deckrd-coder
audience:
  - すべてのユーザー
purpose:
  - deckrd とは何かを理解する
  - 目的に合ったガイドを見つける
meta:
  author: atsushifx
  version: 0.1.0
---

<!--textlint-disable
  ja-technical-writing/sentence-length -->
<!-- markdownlint-disable line-length -->

## deckrd ユーザーガイド

---

## 概要

**deckrd** は、アイデア・目標を **実行可能なタスクリスト** へと段階的に変換する
**ドキュメント駆動開発フレームワーク**です。Claude Code のプラグインとして動作し、
AI との対話を通じて要件・仕様・実装計画を自動導出します。

コードを書く前に「何を作るか」「どう動くべきか」を文書として固めることで、
手戻りを減らし、設計判断を記録に残します。

### deckrd を構成する 3 つの要素

| 要素              | コマンド                  | 役割                                               |
| ----------------- | ------------------------- | -------------------------------------------------- |
| **deckrd**        | `/deckrd <command>`       | 要件・仕様・実装計画・タスクの導出（設計フェーズ） |
| **deckrd-coder**  | `/deckrd-coder <task-id>` | BDD スタイルでの実装（実装フェーズ）               |
| **IDD Framework** | `/idd/issue:new` など     | GitHub Issue / PR 管理（実行フェーズ）             |

### 開発フローの全体像

```text
  課題定義             設計・計画               実装・リリース
┌──────────┐      ┌──────────────────┐      ┌──────────────────┐
│   IDD    │      │     deckrd       │      │deckrd-coder + IDD│
│          │      │                  │      │                  │
│issue:new │─────▶│ req→spec→impl    │─────▶│ BDD 実装         │
│          │      │       →tasks     │      │ commit → PR      │
└──────────┘      └──────────────────┘      └──────────────────┘
```

---

## 目次

### はじめに

- **[オーバービュー](00-overview.ja.md)**
  全体構成・ワークフロー・コマンド順序を図解で一覧する

- **[クイックスタート](01-quickstart.ja.md)**
  `init` から `deckrd-coder` まで、最短で動かすためのステップバイステップガイド

### コマンドリファレンス

- **[コマンドガイド](02-commands.ja.md)**
  全コマンドの役割・入出力・実行フローを図解で詳説する

---

## 関連ドキュメント

| ドキュメント                                                          | 内容                          |
| --------------------------------------------------------------------- | ----------------------------- |
| [アーキテクチャ概要](../developer-guides/architecture.md)             | システム構成・設計原則        |
| [プラグインシステム](../developer-guides/plugin-system.md)            | プラグイン構造の詳細          |
| [開発ワークフロー](../developer-guides/workflow.md)                   | IDD+deckrd の統合ワークフロー |
| [deckrd コマンドリファレンス](../developer-guides/deckrd-commands.md) | 全コマンドの仕様              |
