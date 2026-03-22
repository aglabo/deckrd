---
title: deckrd - "Your Goals to Task" framework
description: 目標を実行可能なタスクに変換する、ドキュメント駆動型ワークフロー。
---

<!-- markdownlint-disable first-line-h1 MD024 MD025 line-length -->
<!-- textlint-disable ja-technical-writing/ja-no-mixed-period -->

|[English](README.md)|日本語|

# deckrd - "Your Goals to Task" framework

## deckrd について

deckrd は、要件定義から実装判断までを **段階的に文書化・整理するためのドキュメント駆動ワークフロー**です。

以下のドキュメントを明確に分離して管理します。

- requirements (要求・要件)
- decision-records (設計上の判断履歴)
- specifications (仕様)
- implementation (実装時の判断・方針)
- tasks (実装タスク)

> 前提条件: AI 実行環境 (Claude Code など) と対応する LLM へのアクセス権

## 3 つの構成要素

deckrd は、開発ライフサイクル全体をカバーする 3 つの統合コンポーネントで構成されています。

| 要素              | コマンド                  | 役割                                               |
| ----------------- | ------------------------- | -------------------------------------------------- |
| **deckrd**        | `/deckrd <command>`       | 要件・仕様・実装計画・タスクの導出（設計フェーズ） |
| **deckrd-coder**  | `/deckrd-coder <task-id>` | BDD スタイルでの実装（実装フェーズ）               |
| **IDD Framework** | `/idd/issue:new` など     | GitHub Issue / PR 管理（実行フェーズ）             |

## 完全なワークフロー

```text
フェーズ 1: 課題定義（IDD）
  /idd/issue:new → GitHub Issue 作成 → ブランチ作成

フェーズ 2: 設計・計画（deckrd）
  /deckrd init → module → req → [dr] → spec → impl → tasks

フェーズ 3: 実装・リリース（deckrd-coder + IDD）
  /deckrd-coder T01 → BDD 実装 → /idd-commit-message → /idd-pr → PR
```

## インストール

### Claude Code の plugins として利用する場合

```bash
# 必要に応じて marketplace を追加
claude plugin marketplace add aglabo/deckrd

# deckrd をインストール
claude plugin install deckrd@deckrd
```

### Agent Skills (codex など ) の場合

1. [deckrd - release](https://github.com/aglabo/deckrd/releases) から zip をダウンロード
2. 展開したディレクトリを Agent Skills ディレクトリ下にコピー

## クイックスタート

```bash
# フェーズ 1: Issue 作成（IDD）
/idd/issue:new

# フェーズ 2: deckrd で設計・計画
/deckrd init myProject shell
/deckrd module myProject/feature
/deckrd req
/deckrd spec
/deckrd impl
/deckrd tasks

# フェーズ 3: 実装とリリース（deckrd-coder + IDD）
/deckrd-coder T01-01    # タスク T01-01 を実装
/deckrd-coder T01-02    # タスク T01-02 を実装
# ... (タスクごとに実行)
/idd-commit-message
git commit -m "..."
/idd-pr
```

## 主要コマンド

| コマンド                        | 説明                                             |
| ------------------------------- | ------------------------------------------------ |
| `init <project> <project-type>` | プロジェクトを初期化 (プロジェクトごとに1回のみ) |
| `module <namespace>/<module>`   | モジュールディレクトリを作成してアクティブ化     |
| `req`                           | 要件定義書を作成                                 |
| `spec`                          | 仕様書を作成                                     |
| `impl`                          | 実装判断基準を作成                               |
| `tasks`                         | 実装用タスクリストを作成                         |
| `dr --add`                      | Decision Records を記録 (オプション)             |
| `status`                        | ワークフロー進捗を確認                           |

> 詳細は各ドキュメントを参照してください：
>
> - [deckrd プラグイン](plugins/deckrd/README.md)
> - [deckrd-coder プラグイン](plugins/deckrd-coder/README.md)
> - [ユーザーガイド](docs/user-guides/index.ja.md)

## 注意事項

### implementation について

implementation は、**コードそのものを書く場所ではありません**。
実装時の以下の内容を記録するドキュメントです。

- 実装方針や戦略の選択理由
- 複数案が存在した場合の判断根拠
- 制約条件 (互換性、パフォーマンス、依存関係など )
- 意図的に「実装しない」と決めた事項

### deckrd がやらないこと

deckrd は以下を目的としません。

- コードの自動生成
- 実装詳細の強制
- 単一の開発手法 (TDD / BDD など ) の押し付け

deckrd は、**思考と判断を整理するための補助フレームワーク**です。

---

## deckrd-coder プラグイン

### deckrd-coder について

`deckrd-coder` は、deckrd 利用者向けに提供される **オプションのプラグイン**です。
deckrd で `tasks.md` を生成した後、自動実装が必要な場合は個別にインストールできます。

### インストール

`deckrd-coder` は、deckrd マーケットプレイスからインストールできます。

```bash
claude plugin install deckrd-coder@deckrd
```

### 基本的な使い方

```bash
# Step 1: deckrd で計画・ドキュメント化
/deckrd init myProject shell
/deckrd module myProject/feature
/deckrd req
/deckrd spec
/deckrd impl
/deckrd tasks

# Step 2: deckrd-coder で自動実装 (オプション )
/deckrd-coder T01-01    # タスク T01-01 を実装
/deckrd-coder T01-02    # タスク T01-02 を実装
# ... (タスクごとに実行)

# Step 3: コミットと PR 作成（IDD）
/idd-commit-message
git commit -m "..."
/idd-pr
```

### 注意事項

- 前提条件: deckrd の `tasks.md` が必須です。deckrd を先に実行してください
- 実装の流れ: 自動的に Red-Green-Refactor サイクル (テスト → 実装 → リファクタリング) を実行
- 品質ゲート: テスト、リント、型チェックを自動検証
- コミット: 手動で実行してください (自動コミットはしません)

> 詳細は [deckrd-coder プラグイン](plugins/deckrd-coder/README.md) を参照してください

---

## ドキュメント

### ユーザーガイド

- [ユーザーガイド インデックス](docs/user-guides/index.ja.md)
- [オーバービュー（図解）](docs/user-guides/00-overview.ja.md)
- [クイックスタート](docs/user-guides/01-quickstart.ja.md)
- [コマンドガイド](docs/user-guides/02-commands.ja.md)

### 開発者ガイド

- [アーキテクチャ概要](docs/developer-guides/architecture.md)
- [開発ワークフロー](docs/developer-guides/workflow.md)
- [deckrd コマンドリファレンス](docs/developer-guides/deckrd-commands.md)
- [IDD コマンドリファレンス](docs/developer-guides/idd-commands.md)
- [プラグインシステム](docs/developer-guides/plugin-system.md)
- [ツール選択ガイド](docs/developer-guides/tool-selection.md)

### コントリビューション

- [コントリビューションガイド](CONTRIBUTING.ja.md)
- [コード品質基準](docs/contributing/code-quality.md)

### 変更履歴

- [CHANGELOG](CHANGELOG.md)
