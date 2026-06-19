# v0.4.0

## Overview

BDD 実装コマンドを `deckrd-coder` から `bdd-coder` にリネームしたリリースです。
機能・動作はそのままに、コマンド名がより目的を明確に表す `bdd-coder` に変わりました。
また、codex を使ったドキュメントのクリティカルレビュー機能 `deckrd-review` を新たに追加しました。

---

## What's New

### `deckrd-coder` が `bdd-coder` にリネームされました

BDD 実装を行うコマンドが `/deckrd-coder` から `/bdd-coder:bdd-coder` に変わりました。
機能・動作の変更はありません。コマンド名がより直感的になりました。

```bash
# 旧コマンド（v0.3.0 まで）
/deckrd-coder

# 新コマンド（v0.4.0 以降）
/bdd-coder:bdd-coder
```

### `deckrd-review` スキルを追加

`/deckrd:deckrd-review` コマンドで、codex を独立したクリティカルレビュアーとして呼び出せるようになりました。
`/deckrd review` が Claude による一次レビューなのに対し、`deckrd-review` は codex が異なる視点から仮定に挑戦し、見落とした盲点を洗い出します。

```bash
# 要件ドキュメントを codex でレビュー
/deckrd:deckrd-review req

# リスクにフォーカスして仕様をレビュー
/deckrd:deckrd-review spec --focus risk
```

`--focus` オプションで `completeness` / `risk` / `consistency` / `feasibility` の観点を指定できます。

### マーケットプレイス設定を本番値に更新

インストール用の GitHub URL が正式に設定されました。`gh skills` / `npx skills` / `claude plugin` のいずれでもインストールできます。

```bash
# gh skills
gh skills install aglabo/deckrd

# npx skills
npx skills add aglabo/deckrd

# claude plugin
claude plugin marketplace add aglabo/deckrd
```

---

## Breaking Changes

### コマンド名の変更

`deckrd-coder` コマンドが `bdd-coder` にリネームされました。

| 旧（v0.3.0 まで） | 新（v0.4.0 以降）      |
| ----------------- | ---------------------- |
| `/deckrd-coder`   | `/bdd-coder:bdd-coder` |

機能の変更はありません。スクリプトや設定ファイルでコマンド名を参照している場合は更新してください。
