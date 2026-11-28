---
title: "deckrd v0.10.0 Release Note"
description: "Release Note: v0.10.0"
version: "0.10.0"
date: "2026-11-28"
summary:
  - bdd-coder のテスト ID チェックが言語別プラグインに対応 (sh / ts / js / dart / go)
  - テスト対象の略語の重複チェックを check-test-abbrs.sh に分離
  - bdd-coder の共有ライブラリと辞書を、シンボリックリンクから実ファイルのコピーに変更
breaking: true
---

<!-- textlint-disable
  ja-technical-writing/sentence-length,
  ja-technical-writing/max-comma,
  -->

## deckrd v0.10.0 - 2026-11-28

v0.10.0 では、bdd-coder のテスト ID チェックを多言語対応にし、bdd-coder の手順書を Phase ごとに分割しました。
`check-test-ids.sh` のオプションに破壊的変更があるため、Migration を確認してください。

## Highlights

### 言語別のテスト ID チェック (bdd-coder)

- `check-test-ids.sh` が、言語ごとのプラグインでテスト ID をチェックする
  - `--lang` で `sh`、`ts`、`js`、`dart`、`go` を選ぶ。カンマ区切りで複数指定でき、省略時は `sh`
  - ID のないテストケース、グループに合わないケース ID、重複した ID を検出する
  - 言語の追加は、プラグインファイルと `check-ids/languages.sh` の 1 行で行う
- 使い方は `references/test-id-check.md` を参照

### テスト対象の略語チェック (bdd-coder)

- `check-test-abbrs.sh` を追加した
  - 全モジュール定義 (`module.md`) を読み、テスト対象の略語が 1 回だけ宣言されていることを確認する
  - 略語表とテストコードの照合はしない
- 使い方は `references/test-abbr-check.md` を参照

### スキル単体インストールへの対応 (bdd-coder)

- `scripts/libs/` と `assets/dic/` を、deckrd へのシンボリックリンクから実ファイルのコピーに変更した
  - `gh skill` と `npx skills` はシンボリックリンクをたどらないため
- 正本は deckrd 側のファイル。コピーが一致しない場合は結合テストが失敗する

### Phase ごとの手順書 (bdd-coder)

- `SKILL.md` と `workflow.md` を Phase の一覧表にまとめ、手順を `references/phases/` に分割した
- セッションの記録と再開のルールを `references/session-resume.md` に分離した
- `faq.md`、`implementation.md`、`troubleshooting.md`、`write-back-format.md` を削除した

## Other Changes

- deckrd に共有ライブラリ `frontmatter.lib.sh`、`glob.lib.sh`、`module-decl.lib.sh` を追加し、`module.sh` で利用するようにした
- `module.md` が読めない場合、`module.sh` は「cannot read module declaration」で失敗する
- テストと lint の対象から `node_modules` を除外した。`run-shellcheck.sh` は `.local` と `temp` も除外する
- テストのルール (`deckrd-rule-testing-guidelines.md`) を 3.0.0 に更新し、テスト宣言の書き方を追加した
- explorer ロールが、`session.json` の `prog` を読めるようにした
- 各 `SKILL.md` の `license` を、`metadata` から frontmatter の直下に移動した
- `deckrd/lib`、`deckrd/subcommands`、`bdd-coder/shared-copies` のモジュール定義を追加した
- 公開前のスキルチェック用に、`pnpm run check:skills` を追加した
- ci-platform の再利用ワークフローを `v0.9.0` に更新した

## Migration

- `check-test-ids.sh` の `--scopes`、`--module`、`--targets`、`--all` は廃止されました。`--lang` を使ってください。
- 引数なしで実行すると、`sh` (`*.spec.sh`) のテストだけをチェックします。他の言語は `--lang` で指定してください。
- 略語の重複チェックは `check-test-abbrs.sh` を実行してください。
- `check-test-ids.sh` はモジュール定義を読まなくなりました。`test_scope` や担当ファイルのチェック、略語表とテストの照合は行いません。
- テスト宣言は、行頭のキーワードとタイトルを 1 行で書いてください。`it.each(` などの派生形はチェック対象外です。
