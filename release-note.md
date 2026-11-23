---
title: "deckrd v0.9.0 Release Note"
description: "Release Note: v0.9.0"
version: "0.9.0"
date: "2026-11-24"
summary:
  - /deckrd rev を、コードから req へ遡る逆方向のチェーンに再設計
  - rev の --from と --to tasks を廃止し、既定の --to を impl に変更
  - タスクブランチ運用と、Target あたり 40 Scenario の上限を追加
breaking: true
---

<!-- textlint-disable
  ja-technical-writing/sentence-length,
  ja-technical-writing/max-comma,
  -->

## deckrd v0.9.0 - 2026-11-24

v0.9.0 では、`/deckrd rev` を「コード → impl → spec → req」の逆チェーンに作り直しました。
`rev` のオプションが変わるため、Migration を確認してください。

## Highlights

### rev の逆チェーン化 (破壊的変更)

- `--to` は `req` / `spec` / `impl`。既定は `impl`
  - `impl`: 既存コードから生成。事前の準備は不要
  - `spec`: モジュールの `implementation.md` から生成
  - `req`: モジュールの `specifications.md` から生成
- `--from` と `--to tasks` は廃止。生成元は `--to` で決まる
- `--path <パス>` を追加。`--to impl` で調査範囲を絞る。複数回指定可
- `rev.template.md` を削除。TARGET に対応する標準テンプレートを使う

### タスクブランチ運用

- 機能ごとに統合ブランチを 1 本、Target (`T-XX`) ごとに短命のタスクブランチを切る
- bdd-coder は git を実行しない。ブランチの作成・マージ・削除は呼び出し側が行う

### Target あたりの Scenario 上限

- 1 つの Target は最大 40 Scenario。超える場合は振る舞いのまとまりごとに分割する

## Other Changes

- skill と agent の description を簡潔にした

## Migration

- `rev --from code` は `--from` を外してください。
- `rev --to tasks` は使えません。タスクは通常どおり `/deckrd tasks` で生成してください。
- `--to` を省略した `rev` は `impl` を生成します。従来の `req` が必要な場合は、
  `--to impl` → `--to spec` → `--to req` の順に実行してください。
