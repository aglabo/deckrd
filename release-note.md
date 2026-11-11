---
title: "deckrd v0.7.0 Release Note"
description: "Release Note: v0.7.0"
version: "0.7.0"
date: "2026-11-11"
previous: "0.6.1"
summary:
  - スキルを npx skills / gh skill で単体インストール可能に
  - dr-writer / dr-refiner を追加 (dr --add / dr --refine)
  - comment-review スキルと comment-refiner を追加
  - tasklist-builder を追加し、bdd-coder に Phase 1a を新設
  - エージェント手順を Role に集約し、skill_dir / local_dir を引数渡しに変更
  - generate-doc が canonical な doc type からプロンプトを解決するよう修正
breaking: false
---

<!-- textlint-disable
  ja-technical-writing/sentence-length,
  ja-technical-writing/max-comma,
  -->

## deckrd v0.7.0 - 2026-11-11

v0.7.0 では、スキルの単体インストール対応、エージェント手順の Role への集約、
Decision Record・コードコメント・タスクリスト向けの新エージェント追加を中心に改善しました。

## Highlights

### スキルを単体でインストール可能に

`npx skills` と `gh skill` で、スキルを単体でインストールできるようになりました。

```sh
gh skill install aglabo/deckrd
```

- スクリプト実行例のパスを `<DECKRD_SKILL_DIR>` プレースホルダーに統一
  - `SKILL.md` が置かれたディレクトリの絶対パスを指す
  - スクリプトは `BASH_SOURCE` からルートを解決する
- `skills/deckrd/skills/deckrd/` 内でのシンボリックリンク使用を禁止
- リリース手順 (GitHub Release の作成、リリース前のスキル検証) を開発者ガイドに追加

### Decision Record の作成・整理エージェント (`dr-writer` / `dr-refiner`)

DR を書く作業と整える作業を、それぞれ専用エージェントに分けました。

```sh
/deckrd dr --add
/deckrd dr --refine [DR-ID ...]
```

- `dr-writer`: DR を 1 件ドラフトし、承認後に `decision-records.md` へ追記
  - DR-ID の採番、Supersede、版更新、Change History を処理
- `dr-refiner`: 決定内容を変えずに、既存 DR を DR 作成ガイドラインに沿って書き直す
  - 承認した節のみを置き換え、PATCH を 1 回だけ上げる
- DR 作成ガイドライン (`references/guidelines/decision-record-authoring.md`) を追加
- `decision-record` プロンプトを単一 DR セクションの生成に変更

### コメント整理 (`comment-review` / `comment-refiner`)

既存コードのコメントを、コードを変えずに整理できます。

```sh
/bdd-coder:comment-review
```

- `comment-refiner` が、コメントガイドライン (C-1〜C-10) に沿って削除・移動・書き換えの差分を作成
- 差分を承認してから適用 (draft → apply)
- 「なぜ」だけを書く、直前に置く、履歴や呼び出し元の情報を書かない、といった判断基準を `code-comments.md` に追加

### タスクリスト生成 (`tasklist-builder`)

bdd-coder が、実装依頼をタスクリストに分解してから 1 項目ずつ実装します。

- 自然言語の依頼または `tasks.md` の Target ID (T-XX) を、1 項目 = 1 checklist のタスクリストに変換
- 出力先は `<local_dir>/temp/tasklist/<ns>/<module>/<name>.tasklist.md`
- 同じ Target ID を再実行すると、新規作成せず既存のタスクリストを返す
- Phase 1a として `checklist-builder` の前に実行

### エージェントの手順を Role に集約

エージェント定義を薄いラッパーにし、手順の正典を Role ファイルへ移しました。

- 手順は `references/roles/*.md` に集約
  - deckrd: `explorer` / `dr-writer` / `dr-refiner`
  - bdd-coder: `implementer` / `explorer` / `checklist-builder` / `code-reviewer` / `tasklist-builder` / `comment-refiner`
- サブエージェントを起動できない環境では、呼び出し元が Role の手順を自分で実行
- `skill_dir` と `local_dir` を引数として Role に渡す方式へ変更
  - `assets/` と `references/` は `skill_dir` 基準
  - セッション・一時ファイルなどのローカルデータは `local_dir` 基準
  - `.local/deckrd` の固定パスを廃止

## Fixes

- `generate-doc.sh` が、`@impl` / `@rev` / `@decision-record` などの canonical な doc type からプロンプトを解決するように修正 (#283)
- `normalize-doc-type` に `rev` と `decision-record` を追加し、phase なしの `review` を unknown doc-type として拒否

## Other Changes

- コマンドリファレンス、README、ユーザーガイド、開発者ガイドを実装に合わせて更新
  - `project` / `review` コマンド、`module --test-scope`、`status` の出力例
  - セッションスキーマ、ディレクトリ構成、ツール名
- 古いパス参照と explore-agent の記述を整理
- Gitleaks から Betterleaks への表記統一
- `deckrd-coder` の参照を `bdd-coder` に置換
- CHANGELOG に v0.6.0 の破壊的変更 (`codex-mcp` 設定の削除、`module.md` の配置先) を追記

## Migration

v0.7.0 に破壊的変更はありません。
既存プロジェクトでは、新しいアセットを次のコマンドで確認・適用してください。

```sh
/deckrd update
/deckrd update --update
```

スキルを単体でインストールして使う場合は、参照ファイル内の `<DECKRD_SKILL_DIR>` を `SKILL.md` が置かれたディレクトリの絶対パスに置き換えて実行してください。
