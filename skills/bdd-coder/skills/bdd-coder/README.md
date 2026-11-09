# bdd-coder

deckrd ワークフローと統合された BDD コーディングスキルです。
`tasks.md` から指定タスクを読み込み、Red-Green-Refactor の厳格プロセスで実装を自動化します。

## 特徴

- deckrd 統合: `req → spec → impl → tasks` ワークフローと完全統合
- BDD 厳格プロセス: Red → Green → Refactor の各フェーズを 1 アサーションずつ確実に実施
- マルチ言語対応: TypeScript/Vitest、Go、Rust、Shell/ShellSpec など任意の言語に対応
- 品質ゲート統合: 型チェック・Lint・テスト・カバレッジ・CRAP スコア算出を自動実行
- 独立コードレビュー: codex CLI による実装者とは独立したコードレビュー

## 使用方法

```bash
# Task ID を指定して実装
/bdd-coder T01-02

# 自然言語で指示
"グリーティング関数を実装して"
"implement config file parser"

# 既存チェックリストを使用
/bdd-coder T01-02 --checklist .local/deckrd/temp/tasks/my-checklist.md
```

## 実行フェーズ

| Phase | 内容                                                                  | 担当エージェント          |
| ----- | --------------------------------------------------------------------- | ------------------------- |
| 0     | 開発環境検出 (言語・テストフレームワーク・ツールコマンド)             | explore-agent-coder       |
| 1     | チェックリスト生成 (Task ID または自然言語から BDD タスクに分解)      | checklist-builder         |
| 2     | タスク依存関係分析 (直列/並列グループ分類)                            | bdd-coder                 |
| 3     | BDD 実装 (Red → Green → Refactor を1アサーションずつ)                 | bdd-coder                 |
| 4     | グローバル品質ゲート (Lint・型チェック・テスト・CRAP・コードレビュー) | bdd-coder + code-reviewer |
| 5     | 完了確認                                                              | bdd-coder                 |
| 6     | セッション終了 (コミットはユーザーが手動実施)                         | bdd-coder                 |

## 構成

```text
skills/bdd-coder/
├── SKILL.md                          # スキル定義
├── README.md                         # このファイル
├── assets/
│   ├── languages/                    # 言語別ルール (TypeScript/Go/Rust/Shell)
│   ├── templates/
│   │   ├── implementation-checklist.tpl.md
│   │   └── shell-header.tpl.sh
│   ├── test-quality.md               # テスト品質原則 (Host Safety/Idempotency/CRAP)
│   ├── testing-anti-patterns.md      # BDD を破壊するアンチパターン集
│   └── pressure-scenarios.md        # BDD 規律を試すプレッシャーシナリオ
└── references/
    ├── workflow.md                   # 内部フロー詳細
    ├── faq.md                        # よくある質問
    ├── troubleshooting.md            # トラブルシューティング
    ├── implementation.md             # 実装フローリファレンス
    ├── guidelines/
    │   └── code-comments.md          # コードコメント ガイドライン (C-1〜C-10)
    └── roles/
        └── comment-refiner.md        # comment-refiner の手順 (Role)
```

関連スキル (`skills/bdd-coder/skills/` 配下):

- `bdd-coder-review/SKILL.md` — `/bdd-coder:bdd-coder-review`。code-reviewer を任意のタイミングで起動する
- `comment-review/SKILL.md` — `/bdd-coder:comment-review`。comment-refiner で既存コメントを見直し、承認後に書き直す

関連エージェント (`skills/bdd-coder/agents/` 配下):

- `bdd-coder.md` — Red-Green-Refactor 実装エージェント
- `checklist-builder.md` — BDD チェックリスト生成エージェント
- `explore-agent-coder.md` — 開発環境検出エージェント
- `code-reviewer.md` — CC/CRAP 算出・codex CLI コードレビューエージェント
- `comment-refiner.md` — コメントだけを書き直すエージェント（手順は `references/roles/comment-refiner.md`）

## ライセンス

MIT License - Copyright (c) 2025 atsushifx
