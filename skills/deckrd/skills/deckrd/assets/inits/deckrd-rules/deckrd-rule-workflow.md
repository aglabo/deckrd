# Deckrd Rule: Workflow

<!-- textlint-disable
  ja-technical-writing/sentence-length,
  ja-technical-writing/max-comma,
  -->

## Command Order (Gate Rule)

Steps must run in order. No skipping.

```text
init → module → req → [dr] → spec → impl → tasks
```

- `init <project> <type>` — bootstrap project once. Creates project.json + session.
- `module <ns>/<mod>` — create module directory and set active. Run per feature.
- `req` → `spec` → `impl` → `tasks` — derive documents in sequence.

## Common Rationalizations

| Rationalization                                         | Reality                                                                                  |
| ------------------------------------------------------- | ---------------------------------------------------------------------------------------- |
| "This change is simple, no spec needed"                 | Even simple changes need acceptance criteria. A spec can be short — it can't be skipped. |
| "I'll write the spec after implementing"                | That's documentation, not a spec. The spec's value is forcing clarity before code.       |
| "Requirements will change anyway, no point writing now" | That's why req/spec are living documents. An outdated doc still beats no doc.            |

## Session

Active session: `.local/deckrd/session.json`
Read session before every command to confirm active module and current step.

## Path Selection

| Situation               | Path                                            |
| ----------------------- | ----------------------------------------------- |
| New feature             | Standard flow (init → module → req → … → tasks) |
| Existing code, no docs  | `rev --to req` then standard from req           |
| Review document quality | `review <doc>` (any time)                       |

## Implementation vs Code

`impl` records decision criteria only — NOT actual code.
Code is written after `tasks` using `/bdd-coder:bdd-coder`.

## BDD/RGR ファースト原則

**すべてのコード変更作業は BDD/RGR サイクルに従う。**

- コードを書く前に必ず `deckrd-rule-bdd-cycle.md` を確認し、作業が BDD サイクルの適用トリガーに該当するか判断する
- 適用トリガーに該当する場合は `bdd-coder` エージェントを呼び出し、Red → Green → Refactor の各フェーズを確実に回す
- 各フェーズの終わりに必ずテストを実行し、FAIL / PASS を確認してから次フェーズに進む
- テストを実行せずに複数フェーズをまたいで実装を進めることは禁止する

### フェーズごとの確認ゲート

| フェーズ | 実施内容         | 次フェーズへの条件                     |
| -------- | ---------------- | -------------------------------------- |
| Red      | テストを書く     | テストが FAIL であることを確認         |
| Green    | 最小実装をする   | テストが PASS になることを確認         |
| Refactor | コードを整理する | テストが引き続き PASS であることを確認 |

## ブランチ戦略

- ブランチ名: `<type>-<issue-number>/<scope>/<description>`
  - 例: `feat-42/auth/add-oauth`, `fix-55/api/fix-encoding`
- `main` への直接 push 禁止

## コミットメッセージ

- Conventional Commits 準拠: `type(scope): description`
- 使用可能な type: `feat`, `fix`, `refactor`, `test`, `docs`, `chore`
- 例: `feat(export): add noise filter for system logs`
- Deckrd ドキュメント関連のコミットは [Commit Linkage](deckrd-rule-commit-linkage.md) の参照ルールにも従う

## Git 操作ルール

- `git add` / `git commit` / `git push` はユーザーが行う
- Claude はコードの編集・テスト・フォーマット確認までを担当する
- コミットが必要な状態になったら、その旨をユーザーに伝えて止まる

## タスク完了時チェックリスト

0. BDD RGR サイクルを完了している（`deckrd-rule-bdd-cycle.md` 参照）
1. フォーマット確認（プロジェクトのフォーマッタでチェック）
2. ユニットテスト実行（全テストがパスすることを確認）
3. ユーザーに完了を伝え、コミットはユーザーに委ねる

## Common Rationalizations（追加項目）

| 言い訳                                 | 反論                                                               |
| -------------------------------------- | ------------------------------------------------------------------ |
| 機能が完成してからまとめてコミットする | 巨大な単一コミットはレビュー・デバッグ・切り戻しが不可能に近くなる |
| コミットメッセージの中身はどうでもいい | メッセージは将来の自分・他のエージェントへのドキュメントになる     |
