---
title: "Deckrd Rule: ドキュメントのバージョニング"
description: "Deckrd ドキュメントの SemVer 採番規則と Change History の同期"
version: 1.0.1
---

<!-- textlint-disable
  ja-technical-writing/sentence-length,
  ja-technical-writing/max-comma,
  -->

## Deckrd Rule: ドキュメントのバージョニング

Change History を持つ Deckrd ドキュメントは SemVer でバージョン管理する。

対象:

- `requirements.md`
- `specifications.md`
- `implementation.md`
- `decision-records.md`

## 書式

バージョンは `MAJOR.MINOR.PATCH` の 3 部構成でなければならない。

```yaml
---
version: 1.0.0
---
```

`version: 1.0` は不正とする。2 部構成のバージョンは frontmatter と Change History テーブルの
対応を崩すため、3 部構成に修正する。

初版は `1.0.0` とする。

## 増分の規則

判断基準は「**作られるものが変わるか**」の一点だけとする。

| 部    | 例            | 該当する変更                                                  |
| ----- | ------------- | ------------------------------------------------------------- |
| MAJOR | 1.4.2 → 2.0.0 | 要件の削除、採用済み方針の破棄、スコープの再定義              |
| MINOR | 1.4.2 → 1.5.0 | 要件・受け入れ基準・DR の追加、実装対象を確定させる決定       |
| PATCH | 1.4.2 → 1.4.3 | 明確化、根拠の補足、Open Question、誤字。実質が変わらないもの |

指摘を記録しただけのレビューは PATCH。その指摘を決定に落とし込んだ時点で MINOR。

## 同期

frontmatter の `version` は、Change History テーブルの最新行と一致しなければならない。
バージョンを上げるたびに、Change History に必ず 1 行追加する。

コマンドのレビューループ中の再生成では上げない。ユーザーが承認するまでドキュメントは
`1.0.0` のままとし、承認後の変更からバージョンを上げる。

```markdown
| Date       | Version | Description       |
| ---------- | ------- | ----------------- |
| 2026-08-12 | 1.0.0   | Initial release   |
| 2026-08-12 | 1.0.1   | Clarify REQ-F-003 |
| 2026-08-12 | 1.1.0   | Add REQ-F-004     |
```

## ドキュメント間の参照

下流ドキュメントは、上流のバージョンを frontmatter で参照する。

```yaml
based-on: requirements.md v1.2.0
```

参照するバージョンは 3 部構成であり、かつ上流ドキュメントの Change History に
実在しなければならない。

## Common Rationalizations

| 言い訳                                   | 反論                                                              |
| ---------------------------------------- | ----------------------------------------------------------------- |
| 小さな編集だから PATCH でいい            | 基準は大きさではない。要件を 1 つ追加すれば 1 行でも MINOR である |
| 編集が多いから MINOR に上げる            | 要件を 1 つも追加しない明確化が 100 個あっても PATCH のままである |
| バージョンは単なるラベルだ               | 下流ドキュメントがこれを指して固定している。誤ると追跡が壊れる    |
| 履歴テーブルは後でまとめて辻褄を合わせる | 記録のないバージョン更新は、参照がどの版を指すのか判別不能にする  |
