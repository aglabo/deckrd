---
title: "Deckrd Rules: Index"
description: "Deckrd ルールの目次。本体は docs/.deckrd/rules/ にあり、必要なときに Read する"
version: 1.0.0
---

## Deckrd Rules: Index

Deckrd のルール本体は `docs/.deckrd/rules/` 配下にある。このファイルは目次であり、
ルールの中身は含まない。

**下表の「読むタイミング」欄を見て、該当する作業を始める前に
`docs/.deckrd/rules/<ファイル名>` から Read すること。**
記憶や推測でルールを満たしたと見なしてはならない。

## ルール一覧

| ファイル名                           | 内容                                                                | 読むタイミング                             |
| ------------------------------------ | ------------------------------------------------------------------- | ------------------------------------------ |
| `deckrd-rule-workflow.md`            | コマンド順序ゲート、BDD ファースト原則、ブランチ・コミット規約      | 作業開始時（常に最初に読む）               |
| `deckrd-rule-bdd-cycle.md`           | BDD RGR サイクルの適用トリガー・免除条件、bdd-coder への委譲ルール  | コードを書く・直す・動かす前               |
| `deckrd-rule-coding-guidelines.md`   | ライブラリ優先・簡潔さ・関数型優先・fail-first の共通規約           | 実装コードを書く前                         |
| `deckrd-rule-testing-guidelines.md`  | グループ/ケースの階層原則、テーブル駆動テスト、テストデータ定義場所 | テストコードを書く前                       |
| `deckrd-rule-runners.md`             | テスト・リンタは必ず pnpm スクリプト経由で実行する                  | テスト／リント／フォーマットを実行する前   |
| `deckrd-rule-commit-linkage.md`      | 1 コミット 1 実装ドキュメント、設計 ID の参照義務                   | コミットメッセージを作る前                 |
| `deckrd-rule-traceability.md`        | REQ → SPEC → TASK → IMPL → TEST → COMMIT の依存フロー               | 設計ドキュメントを書く・参照する前         |
| `deckrd-rule-id-system.md`           | 識別子の書式、名前空間、重複検出                                    | REQ / SPEC / TASK などの ID を採番する前   |
| `deckrd-rule-document-naming.md`     | Deckrd ドキュメントの命名規則                                       | ドキュメントファイルを新規作成する前       |
| `deckrd-rule-file-structure.md`      | ドキュメントルート配下のモジュール別ディレクトリ構成                | モジュールのディレクトリを作る前           |
| `deckrd-rule-document-versioning.md` | SemVer 採番と Change History の同期                                 | ドキュメントの version を上げる前          |
| `deckrd-rule-second-opinion.md`      | codex への独立レビュー依頼のタイミングと指摘の扱い                  | フェーズ移行前、設計判断に決め手がないとき |

## Common Rationalizations

| 言い訳                               | 反論                                                                   |
| ------------------------------------ | ---------------------------------------------------------------------- |
| ルール名から中身は察しがつく         | 目次は要約であり規範ではない。免除条件や手順は本体にしか書かれていない |
| 毎回 Read するのは無駄               | 常時ロードをやめた分の余裕を、必要な 1 本を正確に読むことに使う        |
| 前のセッションで読んだから覚えている | ルールは更新される。参照した内容が現行版である保証はない               |
