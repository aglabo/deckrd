---
title: "deckrd v0.9.1 Release Note"
description: "Release Note: v0.9.1"
version: "0.9.1"
date: "2026-11-24"
summary:
  - bdd-coder にテストケース ID チェッカーを追加
  - bdd-coder で範囲指定 (T01-01..03) と Target 配下一括 (T01-*) の複数タスク実行に対応
  - /deckrd module が既存モジュールへの切り替えに対応
breaking: false
---

<!-- textlint-disable
  ja-technical-writing/sentence-length,
  ja-technical-writing/max-comma,
  -->

## deckrd v0.9.1 - 2026-11-24

v0.9.1 では、bdd-coder のテスト ID チェックと複数タスク実行、deckrd のモジュール切り替えを追加しました。
破壊的変更はありませんが、`module --force` の扱いは Migration を確認してください。

## Highlights

### テストケース ID チェッカー (bdd-coder)

- `check-test-ids.sh` を `runners/` から bdd-coder に移動し、チェック内容を拡張した
  - 欠落・配置誤り・重複したテストケース ID を検出する
  - 分岐展開された ID と、数字を含む略称に対応する
  - Target 略称がモジュールをまたいで一意であることを確認する
- ファイル探索は `rg` を使い、なければ `find` にフォールバックする。awk は `gawk` を優先し、`AWK` で上書きできる
- 使い方は `references/test-id-check.md` を参照

### 複数タスク実行 (bdd-coder)

- 範囲指定 (`T01-01..03`) と Target 配下一括 (`'T01-*'`) で、タスクを 1 件ずつ順に実行する
  - シェルのグロブ展開を防ぐため、`T01-*` は引用符で囲む
  - BLOCKED で停止し (fail-fast)、`--resume` で `queue[index]` から再開する
  - コミットとプッシュは行わない
- 範囲と `T01-*` は呼び出し側が展開する。`tasklist-builder` に渡すと `invalid-input` を返す

### 既存モジュールへの切り替え (deckrd)

- 既存モジュールに対する `/deckrd module <namespace>/<module>` は、失敗せずアクティブモジュールを切り替える
  - 書き換えるのは `session.json` の `active` と `updated_at` のみ。進捗と `test_scope` は保持する
  - 切り替え時に `--test-scope` は指定できない
  - `session.json` またはモジュールのエントリがない場合は、`module <namespace>/<module> --force` で再初期化する
- `--force` は再初期化であり、切り替えではない。セッション上の進捗をリセットする

### rev の順序ゲート免除

- `rev` はコードから遡るため、順序ゲートの対象外。必要なのは `init` の完了のみ
- `rev --to impl --path <パス>` はモジュール不要で、モジュールを推定する

## Other Changes

- テストケース ID のルール (`deckrd-rule-testing-guidelines.md`) を整理した
  - 「ケース ID」を「テストケース ID」に統一
  - テーブル駆動・フィクスチャのテスト ID は、リテラル ID と可変の分岐サフィックス (2 桁) で表す
- `scripts/bump-version.sh` の更新対象を、`package.json`、`deckrd.json`、`marketplace*.json`、各 `plugin.json`、各 `SKILL.md` に変更した
- `.claude-plugin/` とその JSON を Git の追跡対象にした
- pnpm を 12.23.0 に、`@dprint/typescript` を 0.101.0 に更新した
- ci-platform の参照を、コミット SHA からタグ `v0.8.1` に変更した
- 未使用の設定、runner の単体テスト、`run-check-test-ids.sh` を削除した

## Migration

- 既存モジュールに `module <namespace>/<module>` を実行すると、以前のエラーではなく切り替えになります。
- 既存モジュールを再初期化したい場合は `--force` を付けてください。進捗 (`current_step` / `completed` / `documents`) はリセットされます。
- `runners/run-check-test-ids.sh` は削除されました。テストケース ID のチェックは bdd-coder の `check-test-ids.sh` を使ってください。
