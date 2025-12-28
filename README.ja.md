<!-- textlint-disable ja-technical-writing/ja-no-mixed-period -->
<!-- markdownlint-disable first-line-h1 -->

|[English](README.md)|日本語|

# deckrd - "Your Goals to Task" framework

<!-- textlint-enable -->
<!-- markdownlint-enable -->

## deckrd について

deckrd は、要件定義から実装判断までを **段階的に文書化・整理するためのドキュメント駆動ワークフロー**です。

以下のドキュメントを明確に分離して管理します。

- requirements (要求・要件)
- decision-records (設計上の判断履歴)
- specifications (仕様)
- implementation (実装時の判断・方針)
- tasks (実装タスク)

特に implementation は、
「なぜこの実装方針を選んだのか」「どこまでを実装対象とするのか」
といった **コードに直接書かれない判断**を残すためのドキュメントです。

このテンプレートでは、deckrd を
**設計と実装の間にある思考の断絶を防ぐための補助ツール**として利用することを想定しています。

> 前提条件 (利用環境):
>
> - AI 実行環境 (Claude Code / codex cli など)
> - 対応する LLM へのアクセス権

## インストール

### Claude Code の plugins として利用する場合

Claude Code では、deckrd を plugins として利用できます。

```bash
# 必要に応じて marketplace を追加
claude plugin marketplace add aglabo/deckrd

# deckrd をインストール
claude plugin install deckrd@deckrd
```

> 注意
>
> Windows 環境では、TEMP/TMP が plugins キャッシュと
> 異なるドライブを指している場合、
> インストールに失敗することがあります。
> その場合は TEMP/TMP を同一ドライブに設定してください。

### Agent Skills

`codex`などの場合:

`deckrd`は`Agent Skills`で実装されいます。そのため、次の手順でインストールできます。

1. `zip`アーカイブのダウンロード:
   [deckrd - release](https://github.com/aglabo/deckrd/releases) から、zip アーカイブをダウンロード

2. ファイルのコピー:
   zip を展開したファイル内の`deckrd`ディレクトリを Agent Skills ディレクトリ下にコピー

   例 (Unix 系環境):

   ```bash
   cp -fr deckrd ~/.codex/skills
   ```

## 基本的な使い方

### ドキュメント作成の流れ

`deckrd`では、次の順番でドキュメントを作成します。

```bash
Goals / Ideas
|
v
requirements
|
v
decision-records (必要に応じて随時)
|
v
specifications
|
v
implementation
|
v
tasks
|
v
Code / Tests
```

### `deckrd`のサブコマンド

`deckrd`はサブコマンドを使ってドキュメントを作成します。
`deckrd`には、以下のサブコマンドがあります。

- `init`: ドキュメント作成用にディレクトリを準備する
- `req`: `requirements` (要件定義書 )を作成する
- `spec`: `specification` (仕様書) を作成する
- `impl`: `implementation` (実装要判断基準書) を作成する
- `tasks`: `tasks.md` 実装用タスクリスト (BDD におけるテスト定義) を作成する
- `dr`: `Decision Records`を作成する
- `status`: 現在のワークフロー進捗と状態を表示する

コマンドを上から順番に実行していくことで、実装用のタスクリストを作成します。
`status`コマンドは任意のタイミングで実行でき、現在のモジュールとワークフロー進捗を確認できます。

> 補足:
>
> - requirements / specifications / implementation は往復可能です
> - tasks は実装フェーズへの入口であり、原則として後戻りしません

### ディレクトリ構成

`deckrd`は、プロジェクトルートに`docs/.deckrd`ディレクトリを作成します。
ディレクトリ構成は、次のようになります。

```bash
/docs/.deckrd/<namespace>/<module>>/
  |-- decision-records.md
  |-- implementation
  |   `-- implementation.md
  |-- requirements
  |   `-- requirements.md
  |-- specifications
  |   `-- specifications.md
  `-- tasks
      `-- tasks.md
```

\<namespace>, \<module>は`init`コマンドの引数で指定します。

### `dr`コマンド (`Decision Records`)

`deckrd`では、ドキュメントを作って終わりではありません。
AI と議論しながら、ドキュメントをさらにブラッシュアップします。

`dr`コマンドは、このときの議論の結果を`Decision Records`として記録に残すコマンドです。
必要な議論だけ残すため、フールプルーフとして`--add`オプションを付ける必要があります。

```bash
/deckrd dr --add
```

## implementation (実装時の判断基準)

deckrd では、仕様(specifications)と実装(tasks)の間に
**implementation (実装時の判断基準)** というドキュメント層を設けます。

implementation には、以下のような内容を記録します。

- 実装方針や戦略の選択理由
- 複数案が存在した場合の判断根拠
- 制約条件 (互換性、パフォーマンス、依存関係など)
- 意図的に「実装しない」と決めた事項
- 仕様には現れないが、実装に強く影響する前提条件

implementation は、**コードそのものを書く場所ではありません**。
また、コピー可能な実装例を提供することを目的としません。

このドキュメントの役割は、
「なぜこの実装になっているのか」を後から追跡できるようにし、
設計(specifications)と実装(tasks)の間に生じる思考の断絶を防ぐことです。

実装に関する最終的な成果物は tasks およびコードに反映されますが、
その判断過程は implementation に残されます。

## deckrd がやらないこと

deckrd は、以下を目的としません。

- コードの自動生成
- 実装詳細の強制
- 単一の開発手法 (TDD / BDD など) の押し付け

deckrd は、あくまで**思考と判断を整理するための補助フレームワーク**です。
