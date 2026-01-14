# deckrd-coder

deckrd マーケットプレイスの BDD コーディングプラグイン

## 概要

Deckrd ワークフローの tasks.md から指定したタスク（例：`T01-02`）を読み込み、BDD（Behavior-Driven Development）厳格プロセスで実装を自動化するdeckrd専用プラグインです。

## 特徴

- deckrd 前提: deckrd ワークフローと完全統合
- Red-Green-Refactor 厳密実装: テスト駆動開発の原則を厳守
- マルチ言語対応: TypeScript/Vitest、Python/pytest など、任意の言語とテストフレームワークに対応
- TodoWrite 統合: タスク進捗を自動追跡
- 品質ゲート統合: 型チェック、リント、テスト、ビルドの自動実行

## 使用方法

### 基本構文

```bash
/deckrd-coder <TASK_ID>
```

### 実行例

```bash
/deckrd-coder T01-02
/deckrd-coder T01-03
/deckrd-coder T01-10
```

## 含まれるコンポーネント

### エージェント

- bdd-coder: Red-Green-Refactor サイクルで実装を推進するエージェント

### スキル

- deckrd-coder: deckrd タスク解析と BDD 実装自動化スキル

## インストール

このプラグインは deckrd マーケットプレイスに組み込まれています。

### Claude Code での利用

```bash
# deckrd-coder スキルを使用
/deckrd-coder <TASK_ID>
```

## 構成

```
deckrd-coder/
├── SKILL.md                 # 実装スキル定義
├── manifest.json            # プラグインメタデータ
├── README.md               # このファイル
├── assets/                 # アセット（テンプレートなど）
├── references/             # リファレンスドキュメント
└── scripts/                # ユーティリティスクリプト
```

## 実行フェーズ

スキル内で以下のフェーズを自動管理：

1. **Phase 1**: セッション・タスク情報取得
   - deckrd session.json からアクティブセッション確認
   - tasks.md から指定タスク ID のテストケース一覧を抽出

2. **Phase 2**: プロジェクト情報・コード規約参照
   - code_style_conventions.md で命名規約・ファイル配置ルール確認
   - project_overview.md で技術スタック・プロジェクト構造確認

3. **Phase 3**: Red-Green-Refactor サイクル実装（各テストケースごとに繰り返し）
   - [Red] テストを書く
   - テスト失敗確認（エラーメッセージを確認）
   - [Green] 最小限の実装追加
   - テスト成功確認
   - [Refactor] 必要に応じてコード整理
   - Todo を更新
   - 次のテストケースへ

4. **Phase 4**: 品質保証チェック実行
   - ユニットテスト実行
   - シークレット検出
   - 型チェック
   - コード整形確認

5. **Phase 5**: 実装完了
   - 全テスト PASS、型エラーなし確認
   - tasks.md の該当タスクをチェック
   - コミットは実行しない（ユーザーが手動で実施）

## 関連リソース

- [deckrd マーケットプレイス](https://github.com/atsushifx/deckrd)
- [親プロジェクト: aglabo-command-runner](https://github.com/atsushifx/aglabo-command-runner)

## ライセンス

MIT License - Copyright (c) 2025 atsushifx

## サポート

問題報告や機能リクエストは以下をご利用ください：

- GitHub Issues: https://github.com/atsushifx/deckrd/issues
