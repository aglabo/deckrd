---
title: "deckrd v0.8.0 Release Note"
description: "Release Note: v0.8.0"
version: "0.8.0"
date: "2026-11-16"
previous: "0.7.0"
summary:
  - spec に Universal Dictionary フェーズ (Phase 9) を追加
  - 仕様項目を Contract / Guarantee / Extension に分類
  - プログラミング言語 (--prog) とドキュメント言語 (--lang) を分離
  - 引数解析を宣言型の args.lib.sh に移行し、JSON 書き込みをアトミック化
  - bdd-coder のディスパッチ単位を Case から Target に変更
breaking: true
---

<!-- textlint-disable
  ja-technical-writing/sentence-length,
  ja-technical-writing/max-comma,
  -->

## deckrd v0.8.0 - 2026-11-16

v0.8.0 では、用語を一元管理する Universal Dictionary の追加、仕様項目の分類、
プログラミング言語とドキュメント言語の分離を中心に改善しました。
`--lang` の意味が変わるため、既存プロジェクトでは Migration を確認してください。

## Highlights

### Universal Dictionary

`/deckrd spec` に、用語辞書を作成・更新する Phase 9 を追加しました。
以降のフェーズは番号が 1 つずつ後ろにずれています。

| Phase | 内容                           |
| ----- | ------------------------------ |
| 9     | Universal Dictionary (新規)    |
| 10    | 仕様書の生成                   |
| 11    | 外部仕様レビュー               |
| 12    | 版上げ (辞書 → 仕様書の順)     |
| 13    | Second Opinion                 |

- 用語をカテゴリ別に整理し、UD-ID で参照
  - 状態 (status)、廃止理由と置換先の UD-ID、根拠、DR との衝突を記録
- 仕様書のプロンプトとテンプレートが辞書を参照
  - frontmatter に辞書を追加し、UD-ID 付きの用語表を出力
  - 辞書がない場合は辞書セクションを省略
  - 仕様レビューで辞書との整合性を検証
- 版上げは辞書を先に行い、仕様書が辞書の最終版を参照
- `generate-doc.sh` が `universal-dictionary` (エイリアス `dict`) を受け付ける
- ルール `deckrd-rule-document-model.md` を 1.6.0 に更新
  - UD-ID の採番、重複検出、配置、版管理、廃止用語の扱いを定義

### 仕様項目の分類

仕様書の各項目を `Contract` / `Guarantee` / `Extension` に分類し、`Class` 列に記載します。

- 仕様テンプレートのセクション 3〜5 に `Class` 列を追加
- 仕様レビューで、未分類・誤分類・出典のない `Extension` を指摘
- `Class = Extension` の行は `impl` の対象と `tasks` のタスク化から除外
  - `tasks` の Coverage Check には `Extension (out of scope)` と記載

### プログラミング言語とドキュメント言語の分離

これまで 1 つだった言語設定を、2 つに分けました。

```sh
/deckrd init <project> <type> --prog rust --lang ja
```

- `--prog` (エイリアス `--language`): プログラミング言語。`prog` として保存
  - `bash` は `shell` に正規化
- `--lang`: ドキュメント言語 (`DOC_LANG`)。指定したときだけ `session.json` に保存
- `.project.json` のキー `language` を `prog` に変更
- 旧 `session.json` の `lang` (プログラミング言語) は、`init` と `/deckrd update --update` で `prog` に移行
- `status` に Program と Language を表示
- bdd-coder は `session.json` の `prog` からプログラミング言語を読み込む

### 引数解析の共通化とアトミックな JSON 書き込み

- 宣言型の引数パーサー `libs/args.lib.sh` を追加
  - `init.sh` / `module.sh` / `update.sh` / `project.sh` が移行
  - `module --test-scope=XY` のインライン形式に対応
- `write_json_file` で JSON を一時ファイル経由で書き込み
  - ディレクトリ、およびディレクトリへのシンボリックリンクへの書き込みを拒否
  - `init` / `project` / `module` は書き込み失敗時にエラーを出力し、終了ステータス 1 で終了

### bdd-coder: Target 単位のディスパッチ

- ディスパッチ単位を Case から Target に変更し、エージェント起動回数を削減
  - Target 内では Case ごとに RED → GREEN → REFACTOR を実行
  - Target 完了後に回帰テストと変更ファイルの確認を実行
  - 品質ゲートに失敗した場合は、`NEEDS_CONTEXT` / `BLOCKED` を判定して Target を分割
- 進捗ファイル `bdd-todo.md` を Target ごとの `progress_path` に変更
  - 独立した Target は並列実行でき、分割した Target は順番に実行

## Fixes

- `prepare-commit-msg.sh` の既定 AI モデルを `gpt-5.6-luna` に修正
- `init` / `project` / `module` の JSON 書き込み失敗を検出して報告

## Other Changes

- ガイド、コマンドリファレンス、プロンプト、Role を言語オプションの分離に合わせて更新
- DR の保存先の説明を、モジュールごとの `decision-records.md` に変更
- Claude Rule `claude-rule-command-execute.md` を追加
  - slash command の引数をスキルにそのまま渡し、明示フラグと発話が矛盾したらユーザーに確認
- cspell 辞書にテスト対象の略語を追加
- `aglabo.github.io` の `@astrojs/node` を 11.1.12 に更新

## Migration

v0.8.0 には、次の破壊的変更があります。

- `init` の `--lang` はドキュメント言語を表します。プログラミング言語には `--prog` (または `--language`) を使ってください。
- `project` は `--lang` を受け付けません。`--prog` を使ってください。
- `.project.json` の `language` は `prog` に変わります。

既存プロジェクトでは、新しいアセットとセッションの移行を次のコマンドで確認・適用してください。

```sh
/deckrd update
/deckrd update --update
```

`spec` を途中まで進めている場合は、Phase 9 以降の番号が変わっている点に注意してください。
