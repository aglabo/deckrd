---
title: WORKFLOW - Phase の遷移
description: bdd-coder の Phase ごとの実行内容、遷移条件、参照先
---

## WORKFLOW

手順は参照先が定める。**Phase の開始前に参照先を Read する。** 全体に効く規則は [SKILL.md](../SKILL.md)。

## Usage

```bash
/bdd-coder:bdd-coder "implement config file parser"  # 自然言語
/bdd-coder:bdd-coder T01                             # Target ID: Scenario ごとの項目から 1 件選ぶ
/bdd-coder:bdd-coder T01-02                          # Scenario ID
/bdd-coder:bdd-coder T01-02 --checklist <path>       # 既存チェックリストを使う
/bdd-coder:bdd-coder T01-01..03                      # 範囲指定 (順に実行、fail-fast)
/bdd-coder:bdd-coder 'T01-*'                         # Target 配下の全 Scenario
/bdd-coder:bdd-coder --tasklist <path> [--item L-02] # 既存タスクリストを使う
/bdd-coder:bdd-coder --resume                        # 中断した作業を再開
```

## Flow

| Phase | 実行内容                     | 次へ進む条件              | 分岐                                           | 手順                                                  |
| ----- | ---------------------------- | ------------------------- | ---------------------------------------------- | ----------------------------------------------------- |
| 0     | 環境検出と SESSION BASELINE  | ENV PROFILE を取得        | —                                              | 下の Phase 0                                          |
| 1     | 項目選択とチェックリスト生成 | CHECKLIST PATH がある     | `invalid-input` / `BLOCKED` / 実行対象なし → 6 | [tasklist-checklist.md](phases/tasklist-checklist.md) |
| 2     | Target の依存関係分析        | 直列 / 並列グループを決定 | —                                              | 下の Phase 2                                          |
| 3     | bdd-coder に委譲             | 全 Target が完了          | `BLOCKED` → ユーザー判断                       | [dispatch.md](phases/dispatch.md)                     |
| 4     | 品質ゲートとコードレビュー   | 全ゲート合格              | 失敗は修正して再実行。3 回でユーザーに相談     | [quality-gate.md](phases/quality-gate.md)             |
| 5     | 完了判定と書き戻し           | レポート出力              | 複数タスク実行で次の項目がある → 1b            | [write-back.md](phases/write-back.md)                 |
| 6     | セッション終了               | —                         | —                                              | 下の Phase 6                                          |

- 範囲指定と `T01-*`: [multi-task-run.md](phases/multi-task-run.md)
- session.json の保存と `--resume`: [session-resume.md](session-resume.md)

よくある停止:

- Task ID を指定したが tasks.md がない: `/deckrd tasks` までを実行するか、自然言語で指示する
- Phase 4 でテストが失敗する: Phase 3 に戻って該当タスクを再委譲する。Phase 4 は飛ばさない
- アナウンスなしで Phase を飛ばした: アナウンスして最初からやり直す

## Phase 0: 環境検出

1. コードを書く前に **SESSION BASELINE** を記録する (Phase 4 のフォールバックで使う)。
   `git status --porcelain=v1 --untracked-files=all` の各行からパス (3 文字目以降) を取り出す。
   リネーム行は旧パスと新パスの両方を入れる。空でもよい。
2. **explore-agent** ([Role](roles/explorer.md)) を Spawn する。
   渡す値: `skill_dir`, `local_dir`, `scope: pattern-detection`,
   `directory` (リポジトリルート。monorepo はサブパッケージルート),
   `focus: test-framework,build-tools,lint,type-check`
3. 返された Commands 表を **ENV PROFILE** として保持する
   (`<local_dir>/temp/deckrd-work/env-profile.md`)。

## Phase 2: 依存関係分析

1. 各 Target が変更するファイルを特定する。
2. ファイルを共有する、または前段の出力に依存する Target は直列、それ以外は並列グループにする。
3. 同じファイルを変更する Case は並列にしない。Target 内の Case は常に直列とする。

## Phase 6: セッション終了

- メモリ上のセッション情報 (ENV PROFILE、TASKLIST PATH など) を破棄する。
- session.json の `bdd_coder` は消さない。途中終了なら `in-progress` のまま残す (`--resume` で再開)。
- コミットはユーザーが行うよう伝える。
