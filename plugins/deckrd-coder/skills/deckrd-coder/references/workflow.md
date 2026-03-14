---
title: WORKFLOW - 内部フロー詳細
description: deckrd-coder マネジメント層の内部フロー
---

<!-- textlint-disable
  ja-technical-writing/max-comma,
  ja-technical-writing/no-exclamation-question-mark -->

## WORKFLOW - deckrd-coder マネジメント層

deckrd-coder はオーケストレーション専用レイヤーです。
BDD サイクル (テスト・実装・リファクタ) は bdd-coder エージェントに委譲します。

deckrd-coder の責務:

- 開発環境の把握と管理
- チェックリストの読み込みとタスク管理
- bdd-coder のディスパッチ (順次 or 並列)
- ステータス収集と進捗記録
- グローバル品質ゲートの実行
- エスカレーション (BLOCKED 時のユーザー相談)

## ワークフロー全体マップ

```bash
Phase 0: 開発環境の取得・設定 (explore-agent 委譲)
    ↓
Phase 1: タスクリスト取得 (session + checklist 読み込み)
    ↓
Phase 2: タスク分析・依存関係マッピング
    ↓
Phase 3: bdd-coder ディスパッチ (独立タスクは並列実行可能)
    ↓
Phase 4: グローバル品質ゲート (Lint + 型チェック + テスト)
    ↓
Phase 5: チェックリスト確認と完了判定
    ↓
Phase 6: ワークフロー終了
```

| Phase   | 目的                 | 出力                           |
| ------- | -------------------- | ------------------------------ |
| Phase 0 | 開発言語・環境を把握 | ENV PROFILE (env-profile.md)   |
| Phase 1 | 対象タスクを特定     | タスクID、Given/When/Then 一覧 |
| Phase 2 | 依存関係を分析       | 実行グループ (直列 / 並列)     |
| Phase 3 | bdd-coder に委譲     | 各タスクのステータスレポート   |
| Phase 4 | 全体品質を検証       | 品質ゲート合格確認             |
| Phase 5 | 完了状態を確認       | セッション終了前の最終確認     |
| Phase 6 | セッション終了       | 開発ツール・状態をリセット     |

## Before You Begin (MANDATORY — Phase 0 の前に実行)

対象タスクの tasks.md を読む。
以下が不明な場合:

1. 対象の関数/クラス/メソッドが明確か？
2. Given/When/Then 条件がすべて定義されているか？
3. 未実装の依存タスクが存在しないか？

質問はすべて **1 メッセージにまとめて** Phase 0 開始前に行う。
Phase 0 開始後はスコープ質問禁止。

## Phase 0: 初期化フェーズ (explore-agent 委譲)

**explore-agent** を起動して環境検出を委譲する。

### Step 0-1: explore-agent の起動

Spawn **explore-agent** with:

- `scope`: `pattern-detection`
- `directory`: repository root (or sub-package root for monorepos)
- `focus`: `test-framework,build-tools,lint,type-check`
- Agent definition: [`plugins/deckrd-coder/agents/explore-agent.md`](../../../../agents/explore-agent.md)

The agent:

1. Reads `.deckrd/profile.json` if present (`project`, `language`)

2. Loads the language rule file if language is found:
   `plugins/deckrd-coder/skills/deckrd-coder/assets/languages/<language>.md`

3. Detects language from manifest files
   (`package.json`, `Cargo.toml`, `setup.py`, etc.)

4. Identifies tool commands (build, run, lint, type-check, test, formatter)

5. Writes the environment profile to `temp/deckrd-work/env-profile.md`

### Step 0-2: ENV PROFILE の取得

Read the **Commands table** returned by the agent.
Store as **ENV PROFILE** for use in Phase 3 (bdd-coder への渡し), Phase 4, Phase 5。

出力: `temp/deckrd-work/env-profile.md`

## Phase 1: タスクリスト取得

アクティブなセッション情報から、コーディング対象のタスク定義を取得する。

実行内容:

- `docs/.deckrd/.session.json` の `active` フィールドから現在セッションを取得
- 指定されたタスク ID のセクションを抽出
- チェックリストファイルを読み込み (`tasks/implementation-checklist.md` or `--checklist` 指定)
- 未完了 (`[ ]`) の `-R` / `-G` / `-F` 項目を把握

出力: タスク ID、Given/When/Then 一覧、未完了チェックリスト項目。

## Phase 2: タスク分析・依存関係マッピング

deckrd-coder から bdd-coder エージェントへ効率的に情報を受け渡すため、タスク間の依存関係を分析する。

実行内容:

1. 各タスクが変更するファイルを特定
2. ファイル競合の有無でタスクを分類:
   - 直列実行グループ: 共有ファイルがある、または前段タスクの出力に依存する
   - 並列実行グループ: 独立したファイル群を変更する (競合なし)
3. 実行順序・グループを決定

出力: 実行グループ定義 (例: Group-A: 並列[T-01-01, T-01-02], Group-B: 直列[T-01-03])

## Phase 3: bdd-coder ディスパッチ

Phase 2 の実行グループに従って bdd-coder を起動する。

### ディスパッチ方式

**直列実行 (依存関係あり) :**

```bash
bdd-coder(T-01-01) → 完了待ち → bdd-coder(T-01-02) → 完了待ち → ...
```

**並列実行 (独立タスク) :**

```bash
bdd-coder(T-01-01) ┐
bdd-coder(T-01-02) ├→ 全完了待ち → 次グループへ
bdd-coder(T-01-03) ┘
```

### bdd-coder に渡す情報 (Context Isolation)

各 bdd-coder インスタンスに渡す情報:

| 項目              | 内容                             |
| ----------------- | -------------------------------- |
| Task ID           | 例: `T-01-02-01`                 |
| Task description  | tasks.md の Given/When/Then 全文 |
| Quality gate cmds | ENV PROFILE のコマンド表         |
| Checklist path    | チェックリストファイルパス       |

**渡さないもの**: セッション全体コンテキスト、他タスクの情報、session.json。

### ステータス収集

各 bdd-coder から受け取ったレポートを記録:

| Task ID    | Status             | Notes                   |
| ---------- | ------------------ | ----------------------- |
| T-01-02-01 | DONE               |                         |
| T-01-02-02 | DONE_WITH_CONCERNS | 既存テスト 2 件が失敗中 |
| T-01-02-03 | BLOCKED            | 型エラーが 3 回以上発生 |

### BLOCKED 時のエスカレーション

いずれかの bdd-coder が `BLOCKED` を報告した場合:

1. 現在のグループの他タスクが完了している場合、それらを先に記録
2. ユーザーに問題タスクと詳細を報告
3. ユーザーの指示を待つ (先へ進まない)

### DONE_WITH_CONCERNS 時の対応

1. concerns の内容をユーザーに明示
2. Phase 4 完了後に改めて報告
3. ユーザーが続行可否を判断

## Phase 4: グローバル品質ゲート

全タスク完了後、プロジェクト全体の品質を検証する。

実行内容:

1. IDENTIFY — 各基準を証明するコマンドはどれか？
2. RUN      — 今すぐ実行
3. READ     — 完全な出力を読む (要約不可)
4. VERIFY   — 出力が基準を満たしているか確認
5. ONLY THEN — 品質ゲート合格とみなす

チェック項目:

- [ ] Lint チェック: 合格
- [ ] 型チェック: 合格
- [ ] テスト実行: すべてグリーン

失敗時:

- 失敗回数 1–2: 分析・修正・再実行
- 失敗回数 3+: ユーザーに相談 (先へ進まない)

## Phase 5: 完了確認

実行内容:

- 全テスト PASS 確認: Run[test command], read FULL output
- 型エラーなし確認: Run[type check command], read FULL output
- チェックリストがすべて `[x]` 済み確認: Read checklist directly, count checked items
- Refactor が完了したか確認 (Step 7 グローバルリファクタ)

出力: コーディング完了状態。

## Phase 6: ワークフロー終了

実行内容:

- 開発ツール・状態をリセット
- セッション情報をクリア
- コミットはユーザーが手動実施 (deckrd-coder は git 操作禁止)

出力: セッション終了。
