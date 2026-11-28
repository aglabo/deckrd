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
/bdd-coder:bdd-coder T01-02

# 範囲指定 (終端は Scenario 番号だけ)。1 項目ずつ順に実行し、最初の失敗で止まる
/bdd-coder:bdd-coder T01-01..03

# Target 配下の全 Scenario を順に実行 (glob 展開を避けるため引用符で囲む)
/bdd-coder:bdd-coder 'T01-*'

# 止まった項目から再開
/bdd-coder:bdd-coder --resume

# 自然言語で指示
"グリーティング関数を実装して"
"implement config file parser"

# 既存チェックリストを使用
/bdd-coder:bdd-coder T01-02 --checklist .local/deckrd/temp/tasks/my-checklist.md
```

## 実行フェーズ

| Phase | 内容                                                                                                          | 担当エージェント                     |
| ----- | ------------------------------------------------------------------------------------------------------------- | ------------------------------------ |
| 0     | 開発環境検出 (言語・テストフレームワーク・ツールコマンド)                                                     | explore-agent                        |
| 1     | タスクリスト生成 (自然言語・Target ID を 1 項目 = 1 チェックリストに分解) → 選んだ 1 項目のチェックリスト生成 | tasklist-builder + checklist-builder |
| 2     | タスク依存関係分析 (直列/並列グループ分類)                                                                    | bdd-coder                            |
| 3     | BDD 実装 (Red → Green → Refactor を1アサーションずつ)                                                         | bdd-coder                            |
| 4     | グローバル品質ゲート (Lint・型チェック・テスト・CRAP・コードレビュー)                                         | bdd-coder + code-reviewer            |
| 5     | 完了確認                                                                                                      | bdd-coder                            |
| 6     | セッション終了 (コミットはユーザーが手動実施)                                                                 | bdd-coder                            |

## 構成

```text
skills/bdd-coder/skills/bdd-coder/
├── SKILL.md                          # スキル定義
├── README.md                         # このファイル
├── assets/
│   ├── dic/                          # 辞書 (hackers.dic)
│   ├── languages/                    # 言語別ルール (TypeScript/Go/Rust/Shell)
│   ├── templates/
│   │   ├── implementation-checklist.tpl.md
│   │   ├── tasklist.tpl.md
│   │   └── shell-header.tpl.sh
│   ├── test-quality.md               # テスト品質原則 (Host Safety/Idempotency/CRAP)
│   ├── testing-anti-patterns.md      # BDD を破壊するアンチパターン集
│   └── pressure-scenarios.md        # BDD 規律を試すプレッシャーシナリオ
├── scripts/
│   └── libs/                         # 共通 Shell ライブラリ
└── references/
    ├── workflow.md                   # Phase の遷移と Phase 0 / 2 / 6
    ├── phases/                       # Phase ごとの手順
    │   ├── tasklist-checklist.md     # Phase 1
    │   ├── multi-task-run.md         # 範囲指定 / 全指定の順次実行
    │   ├── dispatch.md               # Phase 3
    │   ├── quality-gate.md           # Phase 4
    │   └── write-back.md             # Phase 5
    ├── session-resume.md             # session.json の書き込みと再開の手順
    ├── test-id-check.md              # テスト ID の機械検査 (実行とエラー)
    ├── test-id-check-syntax.md       # 同: 文法と制限 (参照用)
    ├── test-id-check-extending.md    # 同: 言語の追加 (必要なときに読む)
    ├── test-abbr-check.md            # テスト対象略号の機械検査
    ├── guidelines/
    │   └── code-comments.md          # コードコメント ガイドライン (C-1〜C-10)
    └── roles/                        # 各エージェントの手順 (Role)
```

関連スキル (`skills/bdd-coder/skills/` 配下):

- `bdd-coder-review/SKILL.md` — `/bdd-coder:bdd-coder-review`。code-reviewer を任意のタイミングで起動する
- `comment-review/SKILL.md` — `/bdd-coder:comment-review`。comment-refiner で既存コメントを見直し、承認後に書き直す

関連エージェント (手順の正典は `references/roles/` 配下の Role。`skills/bdd-coder/agents/` は Claude Code 用の入れ物):

- `implementer.md` — Red-Green-Refactor 実装エージェント
- `tasklist-builder.md` — 自然言語・Target ID をタスクリストに分解するエージェント
- `checklist-builder.md` — BDD チェックリスト生成エージェント
- `explorer.md` — 開発環境検出エージェント
- `code-reviewer.md` — CC/CRAP 算出・codex CLI コードレビューエージェント
- `comment-refiner.md` — コメントだけを書き直すエージェント（手順は `references/roles/comment-refiner.md`）

## ライセンス

MIT License - Copyright (c) 2025 atsushifx
