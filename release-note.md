---
title: "deckrd v0.10.1 Release Note"
description: "Release Note: v0.10.1"
version: "0.10.1"
date: "2026-11-28"
summary:
  - bdd-coder のテスト ID チェックが、折り返したテストタイトルに対応 (ts / js / dart)
  - for ブロック内のケース ID に、分岐番号を続ける末尾の `-` を必須化 (ts / js / dart)
  - テスト ID チェックの参照ドキュメントを、実行・書式・拡張の 3 本に分割
breaking: false
---

<!-- textlint-disable
  ja-technical-writing/sentence-length,
  ja-technical-writing/max-comma,
  -->

## deckrd v0.10.1 - 2026-11-28

v0.10.1 では、bdd-coder のテスト ID チェックが、折り返したテストタイトルと `for` ループ内のケース ID に対応しました。
`for` ループ内のケース ID は末尾の `-` が必須になったため、Migration を確認してください。

## Highlights

### 折り返したテストタイトルの読み取り (bdd-coder)

- `check-test-ids.sh` が、次の行から始まるテストタイトルを読むようになった
  - 対象は `ts`、`js` の `it(` / `test(` と、`dart` の `test(` / `testWidgets(`
  - 宣言の行が `(` で終わる場合に、次の行をタイトルとして読む。間に空行がある場合は読まない
- `go` と `sh` では、折り返したテスト宣言は引き続きエラーになる

### `for` ループ内のケース ID チェック (bdd-coder)

- `ts`、`js`、`dart` の `for` ブロック内にあるケース ID は、末尾の `-` を必須にした
  - `-` の後ろに分岐番号を続ける
  - `-` がない場合は「case ID without a variable branch in a loop」のエラーになる
- チェックするのは末尾の `-` のみで、その後ろの変数は確認しない
- `while`、`do`、`forEach` などのループは対象外
- `for` ブロックは行単位で判定する。判定できない書き方は `references/test-id-check-syntax.md` を参照

## Other Changes

- テスト ID チェックの参照ドキュメントを分割した
  - `test-id-check.md`: 実行方法とエラー
  - `test-id-check-syntax.md`: ID の書式と制限
  - `test-id-check-extending.md`: 言語の追加方法
- テストのルール (`deckrd-rule-testing-guidelines.md`) を 3.1.2 に更新し、折り返したタイトルと `for` ループ内の ID の書き方を追加した
- `bdd-coder/test-ids` のモジュール定義に、略語 `LBR` と `TLB` を追加した

## Migration

- `ts`、`js`、`dart` の `for` ブロック内にあるケース ID は、末尾を `-` にして分岐番号を続けてください (例: `T-CFG-GI-03-${n}`)。
