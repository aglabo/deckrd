---
title: FAQ - /deckrd-coder スキル よくある質問
---

<!--textlint-disable ja-technical-writing/no-exclamation-question-mark -->

## Q1: 複数タスクを同時に実装できる？

**A**: **いいえ。1 message = 1 task が原則です。**

```bash
(NG) /deckrd-coder T01-02 T01-03 T01-04

(OK) /deckrd-coder T01-02          # 完了待ち
(OK) /deckrd-coder T01-03          # 完了待ち
(OK) /deckrd-coder T01-04          # 完了待ち
```

複数タスクを同時指定するとメモリ制約により品質が低下します。

---

## Q2: 実装完了後、コミットしてもいい？

**A**: **いいえ。コミットはユーザーが手動で実施してください。**

実装が完了したら、ユーザーが以下を確認したうえで手動コミット:

- テストが PASS
- Lint・型チェック合格
- コード品質

このスキルは **実装までしか行いません**。

---

## Q3: Green フェーズで複数メンバー定義できる？

**A**: **いいえ。テスト合格に必要な最小限のみです。**

```typescript
// 悪い例
enum Status {
  ACTIVE, // 次のテストで必要
  INACTIVE, // さらに次のテストで必要
  PENDING,
}

// 良い例 (Task 1 の場合)
enum Status {
  ACTIVE, // Task 1 のテストのみ必須
}
```

過剰実装は Refactor フェーズで統合的に改善。詳細は [IMPLEMENTATION.md](./implementation.md#step-3-最小実装) を参照。

---

## Q4: Step 5 で品質ゲート失敗した。どこへ戻る？

**A**: エラーの種類で判定:

| エラー                | 戻り先         | 詳細                             |
| --------------------- | -------------- | -------------------------------- |
| Lint 失敗 (様式違反)  | Step 5 再実行  | TROUBLESHOOTING.md「逸脱 6」参照 |
| 型チェック失敗        | Step 5 再実行  | TROUBLESHOOTING.md「逸脱 6」参照 |
| テスト失敗 (実装バグ) | Step 3 へ戻る  | IMPLEMENTATION.md「Step 3」参照  |
| 3 回以上失敗          | ユーザーに相談 | TROUBLESHOOTING.md 全体参照      |

詳細は [TROUBLESHOOTING.md](./troubleshooting.md#逸脱-6-step-5-での失敗対応の混乱) の「逸脱 6: Step 5 での失敗対応の混乱」参照。

---

## Q5: Task ID の指定形式は？

**A**: 以下の 2 形式が使用可能:

| ID 形式       | 例          | 説明                              |
| ------------- | ----------- | --------------------------------- |
| セクション ID | `T01-02`    | **推奨** (単一テストケース対応)   |
| 詳細 ID       | `T01-02-01` | **非推奨** (テストケース詳細指定) |

通常はセクション ID での指定を推奨します。

---

## Q6: bdd-coder エージェントは何をするの？

**A**: このスキルの **Step 3** (単一タスクの実装) で自動起動:

- Red フェーズ: テスト実装 → テスト失敗確認
- Green フェーズ: 最小実装 → テスト合格確認
- Refactor フェーズ: 軽微な整理 (ユーザー相談なし)
- 品質ゲート確認: Lint・型チェック合格確認
- 進捗管理: TodoWrite で詳細ステップ管理

詳細は [bdd-coder.md](../agents/bdd-coder.md) を参照。

---

## Q7: 品質ゲートコマンドは何？

**A**: Lint、型チェック、テストを実行するコマンド:

- Lint: `npm run lint`（例）
- 型チェック: `npm run type-check`（例）
- テスト: `npm test`（例）

プロジェクトメモリ `suggested_commands` から自動取得されます。詳細は [IMPLEMENTATION.md](./implementation.md#step-1-品質ゲートコマンド取得) を参照。

---

## Q8: 3 回以上品質ゲート失敗したらどうする？

**A**: ユーザーに相談し、以下の対応を検討:

1. **ロールバック**: 現在の実装をクリアし、別のアプローチで再開
2. **マニュアル修正**: ユーザーが手動でコード修正
3. **ステップの見直し**: 実装タスクリストを再細分化

詳細は [TROUBLESHOOTING.md](./troubleshooting.md) の「品質ゲート失敗への対応」参照。

---

## さらに詳しく

| 質問内容             | 参照ドキュメント                           |
| -------------------- | ------------------------------------------ |
| スキルの全体フロー   | [WORKFLOW.md](./workflow.md)               |
| 実装ステップの詳細   | [IMPLEMENTATION.md](./implementation.md)   |
| 問題発生時の対応     | [TROUBLESHOOTING.md](./troubleshooting.md) |
| bdd-coder の詳細仕様 | [bdd-coder.md](../agents/bdd-coder.md)     |
