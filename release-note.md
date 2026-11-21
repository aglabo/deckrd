---
title: "deckrd v0.8.1 Release Note"
description: "Release Note: v0.8.1"
version: "0.8.1"
date: "2026-11-21"
previous: "0.8.0"
summary:
  - Universal Dictionary の ID を章コード付きの UD-<CODE>-NNN 形式に変更
  - betterleaks の runner を追加し、lint とシークレットスキャンの設定を整理
  - シェルスクリプトの書式を統一
breaking: false
---

<!-- textlint-disable
  ja-technical-writing/sentence-length,
  ja-technical-writing/max-comma,
  -->

## deckrd v0.8.1 - 2026-11-21

v0.8.1 では、Universal Dictionary の ID に章コードを加え、開発ツールの設定と
シェルスクリプトの書式を整理しました。
新しい ID 形式を使うため、既存の辞書がある場合は Migration を確認してください。

## Highlights

### 章コード付きの UD-ID

Universal Dictionary の ID を `UD-NNN` から `UD-<章コード>-NNN` に変更しました。
例: `UD-ST-003`

- 章コード: 英大文字で始まる 2〜6 文字の英大文字・数字。モジュール内で重複不可
  - 辞書の `Chapter Codes` 表 (テンプレートの 1.5) に、章との対応を記載
- NNN: 章コードごとの 3 桁連番。次の番号は、その章コードの最大番号の次
- 新しい ID は「章の選択 → 章コードの使用 → NNN の決定」の順に発行
  - 既存の章に合わない用語は、新しい章と章コードを立てる
- 用語を別の章へ移しても ID は変えない。廃止した ID は再利用しない
- 重複・参照切れの検出パターンを `UD-[A-Z][A-Z0-9]{1,5}-[0-9]{3}` に変更
- 更新したファイル
  - ルール `deckrd-rule-document-model.md` を 1.8.0 に更新
  - プロンプト `specifications` / `universal-dictionary`
  - テンプレート `specifications` / `universal-dictionary`
  - `spec-phases/09-dictionary.md`、`spec-phases/11-spec-review.md`

### 開発ツールの整理

- `runners/run-betterleaks.sh` を追加し、ステージ済みファイルとディレクトリをスキャン
  - lefthook は `run-betterleaks.sh --staged` と `secretlint {staged_files}` を実行
  - `configs/betterleaks.toml` と `configs/secretlint.config.yaml` を削除
- `run-shellcheck.sh` と `run-shfmt.sh` の設定解決を改善
  - `shfmt` は `.editorconfig` の設定を使う
- `package.json` の lint スクリプトを `cross-env MSYS=NOGLOB` 経由に変更
- pnpm を 12.15.0 から 12.21.0 に更新
- `commit-message-generator` エージェントを 0.10.0 に更新
  - ヘッダは 76 文字、本文は 96 文字で折り返す

### シェルスクリプトの書式統一

`runners/`、`scripts/`、`skills/deckrd/skills/deckrd/scripts/` の書式を揃えました。
動作は変わりません。

- 関数の開き括弧 `{` を次の行に移動
- `[[ ]]` の変数をクォートせず、内側に空白を入れる
- `case` の分岐を 1 段インデント
- リダイレクトの前後に空白を入れる

## Other Changes

- `.gitignore` を整理し、`skills/.gitignore` を追加
  - marketplace 用に `/.claude-plugin/*.json` を許可
- `run-shellcheck.sh` の除外ディレクトリ一覧を `find_shell_files` に集約
- cspell のテスト ID 辞書を `test-target-dic` から `test-id-dic` に改名
- `configs/cliff.toml` を整理

## Migration

破壊的変更はありません。ただし、既存の Universal Dictionary は旧形式の `UD-NNN` を使っています。

- 新しく発行する ID から `UD-<章コード>-NNN` 形式を使います。
- 既存の ID を新形式に直す場合は、辞書に `Chapter Codes` 表を追加し、
  参照元の仕様書も同時に更新してください。
