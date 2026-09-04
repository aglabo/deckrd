---
title: "Deckrd Rule: ワークフロー"
description: "コマンド順序ゲート、BDD ファースト原則、ブランチ・コミット規約"
version: 2.0.0
---

<!-- textlint-disable
  ja-technical-writing/sentence-length,
  ja-technical-writing/max-comma,
  -->

## Deckrd Rule: ワークフロー

## コマンド順序（ゲートルール）

各ステップは順番に実行する。飛ばしてはならない。

```text
init → module → req → [dr] → spec → impl → tasks
```

- `init <project> <type>` — プロジェクトを 1 度だけ初期化する。`.project.json` とセッションを作る
- `module <ns>/<mod>` — モジュールディレクトリを作り、アクティブにする。機能ごとに実行する
- `req` → `spec` → `impl` → `tasks` — ドキュメントを順に導出する

### セッション

アクティブなセッション: `.local/deckrd/session.json`

すべてのコマンドの前にセッションを読み、アクティブなモジュールと現在のステップを確認する。

### 経路の選択

| 状況                               | 経路                                                 |
| ---------------------------------- | ---------------------------------------------------- |
| 新規機能                           | 標準フロー (`init` → `module` → `req` → … → `tasks`) |
| 既存コードがありドキュメントがない | `rev --to req` の後、`req` から標準フロー            |
| ドキュメントの品質を確認する       | `review <doc>`（任意のタイミング）                   |

### impl はコードではない

`impl` が記録するのは判断基準だけであり、実際のコードではない。
コードは `tasks` の後に `/bdd-coder:bdd-coder` で書く。

## BDD ファースト原則

**すべてのコード変更作業は BDD/RGR サイクルに従う。**

適用トリガー・免除条件・各フェーズの手順とゲート条件は
[BDD 開発サイクル](deckrd-rule-bdd-cycle.md) が定める。コードを書く・直す・動かす前に
必ずそちらを読み、作業が適用対象かを判断する。

## ブランチ戦略

- ブランチ名: `<type>-<issue-number>/<scope>/<description>`
  - 例: `feat-42/auth/add-oauth`, `fix-55/api/fix-encoding`
- `main` への直接 push 禁止

## コミット

### 粒度

**実装ドキュメント 1 本 = コミット 1 個。**

### メッセージ書式

Conventional Commits に準拠する: `type(scope): description`

使用可能な type: `feat`, `fix`, `refactor`, `test`, `docs`, `chore`

### 設計 ID の参照

Deckrd ドキュメントに対応するコミットは、本文で設計 ID を参照する。

```text
feat(cli): add configuration parser

Implements: IMPL-001
Spec: SPEC-001
Req: REQ-001
Test: TEST-001
```

ID の書式は [ドキュメントモデル](deckrd-rule-document-model.md) に従う。

## Git 操作ルール

- `git add` / `git commit` / `git push` はユーザーが行う
- Claude はコードの編集・テスト・フォーマット確認までを担当する
- コミットが必要な状態になったら、その旨をユーザーに伝えて止まる

## タスク完了時チェックリスト

1. BDD RGR サイクルを完了している（[BDD 開発サイクル](deckrd-rule-bdd-cycle.md)）
2. フォーマットを確認した（[Runners](deckrd-rule-runners.md) の経路で実行する）
3. ユニットテストが全てパスする（同上）
4. ユーザーに完了を伝え、コミットはユーザーに委ねる

## Common Rationalizations

| 言い訳                                 | 反論                                                                                   |
| -------------------------------------- | -------------------------------------------------------------------------------------- |
| この変更は単純なので spec は要らない   | 単純な変更にも受け入れ基準は要る。spec は短くできるが、省略はできない                  |
| spec は実装した後に書く                | それはドキュメントであって spec ではない。spec の価値はコード前に明確化を強制すること  |
| どうせ要件は変わるので今書く意味がない | だから req / spec は生きたドキュメントにする。古いドキュメントでも無いよりはましである |
| 機能が完成してからまとめてコミットする | 巨大な単一コミットはレビュー・デバッグ・切り戻しが不可能に近くなる                     |
| コミットメッセージの中身はどうでもいい | メッセージは将来の自分・他のエージェントへのドキュメントになる                         |
