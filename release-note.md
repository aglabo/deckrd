# v0.3.0

## Overview

プラグインアセットを `skills/` ディレクトリ構造に移行し、`gh skills` および `npx skills` による簡単インストールに対応したリリースです。

---

## What's New

### `gh skills` / `npx skills` でインストールできるようになりました

GitHub リポジトリを指定するだけで deckrd と deckrd-coder をインストールできます。

```bash
# gh skills
gh skills install aglabo/deckrd

# npx skills
npx skills add aglabo/deckrd
```

### プラグインを `skills/` ディレクトリに統合

`deckrd` と `deckrd-coder` を `plugins/` から `skills/` へ移動し、Agent Skills の標準ディレクトリ構造に準拠しました。Claude Plugin (`claude plugin marketplace add`) によるインストールも引き続き利用できます。

```bash
claude plugin marketplace add aglabo/deckrd
```

### `deckrd-coder` を独立プラグインとして分離

`deckrd-coder` が `deckrd` から独立したプラグインになりました。それぞれ個別にインストール・管理できます。

---

## Breaking Changes

### プラグインパスの変更

内部ランタイムのパスが `plugins/_runtime/` から `skills/_runtime/` に変更されました。カスタムスクリプトで `plugins/_runtime/libs/bootstrap.lib.sh` を直接参照している場合は `skills/_runtime/libs/bootstrap.lib.sh` に更新してください。

標準の `/deckrd` コマンド・`/deckrd-coder` コマンドはそのまま使用できます。
