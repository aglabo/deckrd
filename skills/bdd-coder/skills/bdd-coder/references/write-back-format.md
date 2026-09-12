---
title: WRITE-BACK FORMAT - Phase 5 書き戻しの書式
description: tasks.md のケース行、Task Summary 表、Step 5 レポートの書式サンプル
---

## WRITE-BACK FORMAT - Phase 5 書き戻しの書式

Phase 5 の各 Step が書き出す形の見本。手順とゲート条件は
[SKILL.md](../SKILL.md) の Phase 5 が定める。ここは書式だけを示す。

## Step 2: tasks.md のケース行

チェックボックスのマーカーだけを書き換える。説明文と
`Target` / `Scenario` / `Expected` の行は触らない。

```markdown
- [x] **T-01-01-01**: <description>
  - Target: `<function>`
  - Scenario: Given <precondition>, When <action>
  - Expected: Then <assertion>
```

## Step 3: Task Summary 表

今回実装した Test Target の Status 列のみ再計算する。

```markdown
## Task Summary

| Test Target  | Scenarios | Cases | Status      |
| ------------ | --------- | ----- | ----------- |
| T-01: <name> | N         | M     | done        |
| T-02: <name> | N         | M     | in progress |
```

## Step 5: ユーザーへのレポート

```text
STATUS WRITE-BACK (tasks.md):
  T-01-01-01  [x]
  T-01-01-02  [x]
  T-01: done        (2/2 cases checked)
  T-02: in progress (1/3 cases checked — 2 cases remain)
  T-03-01-01  not found in tasks.md — skipped

CHECKLIST BACKFILL:
  T-01-01-02-F  [x]  (left unchecked by the bdd-coder instance)
```
