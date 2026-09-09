---
title: WORKFLOW - 内部フロー詳細
description: bdd-coder マネジメント層の内部フロー
---

<!-- textlint-disable
  ja-technical-writing/max-comma,
  ja-technical-writing/no-exclamation-question-mark -->

## WORKFLOW - bdd-coder マネジメント層

bdd-coder はオーケストレーション専用レイヤーです。
BDD サイクル (テスト・実装・リファクタ) は bdd-coder エージェントに委譲します。

bdd-coder の責務:

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
Phase 1: チェックリスト作成 (checklist-builder 委譲)
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

| Phase   | 目的                 | Agent             | 出力                                         |
| ------- | -------------------- | ----------------- | -------------------------------------------- |
| Phase 0 | 開発言語・環境を把握 | explore-agent     | ENV PROFILE (env-profile.md)                 |
| Phase 1 | チェックリストを生成 | checklist-builder | `temp/tasks/<slug>-<adjective>-checklist.md` |
| Phase 2 | 依存関係を分析       | bdd-coder         | 実行グループ (直列 / 並列)                   |
| Phase 3 | bdd-coder に委譲     | bdd-coder         | 各タスクのステータスレポート                 |
| Phase 4 | 全体品質を検証       | bdd-coder         | 品質ゲート合格確認                           |
| Phase 5 | 完了状態を確認       | bdd-coder         | セッション終了前の最終確認                   |
| Phase 6 | セッション終了       | bdd-coder         | 開発ツール・状態をリセット                   |

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
- Agent definition: [`plugins/deckrd/agents/explore-agent-coder.md`](../../../../agents/explore-agent-coder.md)

The agent:

1. Reads `.deckrd/profile.json` if present (`project`, `language`)

2. Loads the language rule file if language is found:
   `plugins/deckrd/skills/bdd-coder/assets/languages/<language>.md`

3. Detects language from manifest files
   (`package.json`, `Cargo.toml`, `setup.py`, etc.)

4. Identifies tool commands (build, run, lint, type-check, test, formatter)

5. Writes the environment profile to `temp/deckrd-work/env-profile.md`

### Step 0-2: ENV PROFILE の取得

Read the **Commands table** returned by the agent.
Store as **ENV PROFILE** for use in Phase 3 (bdd-coder への渡し), Phase 4, Phase 5。

出力: `temp/deckrd-work/env-profile.md`

### Step 0-3: SESSION BASELINE の記録

explore-agent の起動前後を問わず、**コードを 1 行も書く前に** 作業ツリーの汚れを記録する。

```bash
git status --porcelain=v1 --untracked-files=all
```

各行は先頭 2 文字がステータスコード、3 文字目以降がパスを表す。パス部分だけを取り出して
集合にし、**SESSION BASELINE** として保持する。リネーム行 (`R  old -> new`) は
`old` と `new` の両方を登録する。空集合なら正常な状態とみなす。

用途は Phase 4 のフォールバックに限る。ユーザーがセッション開始時点で無関係な未コミット
変更を抱えていた場合、それらをレビュー対象から外すために使う。

## Phase 1: チェックリスト作成 (checklist-builder 委譲)

**checklist-builder** エージェントを起動してチェックリストを生成する。

### 入力タイプ別の動作

| 入力タイプ                | checklist-builder の動作                                 |
| ------------------------- | -------------------------------------------------------- |
| 自然言語の指示            | 指示を解析してタスク分解、チェックリストを生成           |
| Task ID (例: T01-02)      | tasks.md の該当エントリを展開してチェックリストを生成    |
| `--checklist <path>` 指定 | checklist-builder をスキップ、既存ファイルをそのまま使用 |

### Step 1-1: checklist-builder の起動

Spawn **checklist-builder** with:

- `instruction`: ユーザーの指示 or Task ID
- `tasks_md`: tasks.md のパス (Task ID 入力時のみ)
- `directory`: リポジトリルート

The agent:

1. 入力を解析してタスクを分解
2. チェックリストを `temp/tasks/<slug>-<adjective>-checklist.md` に書き込む
3. チェックリストのパスをメインセッションに返却

### Step 1-2: チェックリストの取得

返却されたチェックリストパスを **CHECKLIST PATH** として保存。
Phase 2 以降で使用する。

出力: `temp/tasks/<slug>-<adjective>-checklist.md`

## Phase 2: タスク分析・依存関係マッピング

bdd-coder から bdd-coder エージェントへ効率的に情報を受け渡すため、タスク間の依存関係を分析する。

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

| Task ID    | Status             | Changed files                         | Notes                   |
| ---------- | ------------------ | ------------------------------------- | ----------------------- |
| T-01-02-01 | DONE               | `src/parser.ts`, `src/parser.spec.ts` |                         |
| T-01-02-02 | DONE_WITH_CONCERNS | `src/lexer.ts`                        | 既存テスト 2 件が失敗中 |
| T-01-02-03 | BLOCKED            | (なし)                                | 型エラーが 3 回以上発生 |

Changed files 列は bdd-coder の Status Report の `CHANGED_FILES` 行をそのまま転記する。
この列の和集合が Phase 4 のレビュー対象になるため、空欄のまま次へ進まない。

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
2. RUN — 今すぐ実行
3. READ — 完全な出力を読む (要約不可)
4. VERIFY — 出力が基準を満たしているか確認
5. ONLY THEN — 品質ゲート合格とみなす

チェック項目:

- [ ] Lint チェック: 合格
- [ ] 型チェック: 合格
- [ ] テスト実行: すべてグリーン (カバレッジ付き)
- [ ] **code-reviewer** 起動: 全変更ファイルを対象に CRAP 算出、および、コードをレビュー
- [ ] CRAP 判定: スコア > 30 の関数がないこと (16–30 は DONE_WITH_CONCERNS)
- [ ] コードレビュー判定: `PASS` または `PASS_WITH_WARNINGS` であること

**CRAP 計算式:** `CC² × (1 - coverage/100)³ + CC`
詳細は [../assets/test-quality.md](../assets/test-quality.md) — CRAP Score セクションを参照。

code-reviewer は **セッション全体で 1 回だけ** 起動する (タスクごとのループはしない)。起動パラメータ:

- `task_id`: 単一タスク起動ならその ID。複数タスクにまたがる場合は `N/A`
- `changed_files`: セッションスコープ (下記) のうち実装ファイル
- `test_files`: 同じセッションスコープのうちテストファイル (ENV PROFILE のテストファイル規約で振り分け)
- `env_profile`: `temp/deckrd-work/env-profile.md`
- `coverage_cmd`: ENV PROFILE のカバレッジコマンド

セッションスコープの解決順序は次のとおり。

1. Phase 3 の表の `Changed files` 列 (各 bdd-coder の `CHANGED_FILES`) の和集合
2. その列が得られない場合に限り、作業ツリー全体の変更から Step 0-3 の
   **SESSION BASELINE** を差し引いた集合

作業ツリー全体の変更とは、次の 3 つを併合し重複を除いた集合を指す。

- `git diff --name-only`
- `git diff --name-only --cached`
- `git ls-files --others --exclude-standard`

3 つ目を必ず含める。bdd-coder が作成したばかりのファイルは untracked のため、
前 2 つに現れない。削除されたパスも除外しない (code-reviewer が
`git diff -- <path>` でパッチを読む)。

作業ツリーの差分をそのまま渡してはならない。セッション開始時点で無関係な
未コミット変更を抱えていた場合、それらがレビュー対象に入り、無関係な指摘で
セッションがブロックされる。

同じレビューは `/bdd-coder:bdd-coder-review` で任意のタイミングでも実行できる。

Agent definition: [../../../../agents/code-reviewer.md](../../../../agents/code-reviewer.md)

失敗時:

- 失敗回数 1–2: 分析・修正・再実行
- 失敗回数 3+: ユーザーに相談 (先へ進まない)
- CRAP > 30 または code-reviewer `BLOCKED`: リファクタリング (CC 削減) またはテスト追加後に再実行

## Phase 5: 完了確認

実行内容:

- 全テスト PASS 確認: Run[test command], read FULL output
- 型エラーなし確認: Run[type check command], read FULL output
- チェックリストがすべて `[x]` 済み確認: Read checklist directly, count checked items
- Refactor が完了したか確認 (Step 7 グローバルリファクタ)
- Task ID 起動時: tasks.md の該当ケースのチェックボックスを `[x]` に更新
  (判定源は Phase 3 のステータスレポート)
- 今回実装した Test Target のみ、Task Summary の Status を
  チェックボックスの充足率から再計算

書き戻しの詳細な手順は [SKILL.md](../SKILL.md) の Phase 5 を参照。

出力: コーディング完了状態。

## Phase 6: ワークフロー終了

実行内容:

- 開発ツール・状態をリセット
- セッション情報をクリア
- コミットはユーザーが手動実施 (bdd-coder は git 操作禁止)

出力: セッション終了。
