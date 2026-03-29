---
title: "Implementation Checklist"
source: "natural-language instruction"
status: Active
created: "{{ YYYY-MM-DD HH:MM:SS }}"
---

<!-- markdownlint-disable line-length -->

> This checklist is derived from a natural-language implementation request.
> Each test case expands into Red-Green-Refactor cycle check items with unique task IDs.

---

## 1. Overview

### 1.1 Task Hierarchy

| Level    | ID Format    | Definition                                                           |
| -------- | ------------ | -------------------------------------------------------------------- |
| Target   | `T-01`       | Function or class under test                                         |
| Scenario | `T-01-01`    | Specification behavior group (e.g. "Trim whitespace")                |
| Case     | `T-01-01-01` | Concrete input-output example (e.g. `" Alice "` → `"Hello, Alice!"`) |

### 1.2 BDD サイクル凡例

| フェーズ      | 記号  | 意味                                              |
| ------------- | ----- | ------------------------------------------------- |
| Red           | `-R`  | テストを先に書き、失敗することを確認する          |
| Green         | `-G`  | テストが通る最小限の実装を行う                    |
| Refactor      | `-F`  | 動作を変えずに実装コードを整理する                |
| Test Refactor | `-TF` | Scenario 内の全 Case 完了後にテストを最適化       |
| Code Refactor | `-CF` | Target 内の全 Scenario 完了後に実装コードを最適化 |

---

## 2. Task Structure

```text
T-01: {{TEST_TARGET_NAME}}
  T-01-01: [正常] {{SCENARIO_BEHAVIOR_1}}
    T-01-01-01: {{CASE_DESCRIPTION}}  (R/G/F)
    T-01-01-TF: Scenario テストリファクタリング

  T-01-02: [異常] {{SCENARIO_ERROR_BEHAVIOR}}
    T-01-02-01: {{CASE_ERROR_DESCRIPTION}}  (R/G/F)
    T-01-02-TF: 異常系テストリファクタリング

  T-01-03: [エッジケース] {{SCENARIO_EDGE_BEHAVIOR}}
    T-01-03-01: {{CASE_EDGE_DESCRIPTION}}  (R/G/F)
    T-01-03-TF: エッジケーステストリファクタリング

  T-01-CF: 実装コードリファクタリング
```

---

## 3. Implementation Checklist

### T-01-01: [正常] {{SCENARIO_BEHAVIOR_1}}

#### T-01-01-01 — {{CASE_DESCRIPTION}}

| Input                | Expected                |
| -------------------- | ----------------------- |
| `{{INPUT_EXAMPLE}}`  | `{{EXPECTED_EXAMPLE}}`  |

- [ ] **[T-01-01-01-R] Red** : `{{FUNCTION_NAME}}({{INPUT_EXAMPLE}})` のテストを書き、失敗を確認する
- [ ] **[T-01-01-01-G] Green** : テストが通る最小限の実装をする
- [ ] **[T-01-01-01-F] Refactor** : 実装を整理し、テストが引き続き通ることを確認する

#### T-01-01-TF — {{SCENARIO_BEHAVIOR_1}} テストリファクタリング

> T-01-01 の全 Case 完了後に実施する

- [ ] **[T-01-01-TF] Test Refactor**: テストケースの重複・冗長性を排除し、可読性を高める

---

### T-01-02: [異常] {{SCENARIO_ERROR_BEHAVIOR}}

#### T-01-02-01 — {{CASE_ERROR_DESCRIPTION}}

| Input                      | Expected                      |
| -------------------------- | ----------------------------- |
| `{{INPUT_ERROR_EXAMPLE}}`  | `{{EXPECTED_ERROR_EXAMPLE}}`  |

- [ ] **[T-01-02-01-R] Red** : `{{FUNCTION_NAME}}({{INPUT_ERROR_EXAMPLE}})` のテストを書き、失敗を確認する
- [ ] **[T-01-02-01-G] Green** : エラー処理を実装し、テストが通ることを確認する
- [ ] **[T-01-02-01-F] Refactor** : エラー処理の実装を整理する

#### T-01-02-TF — 異常系テストリファクタリング

> T-01-02 の全 Case 完了後に実施する

- [ ] **[T-01-02-TF] Test Refactor**: 異常系テストケースの重複・冗長性を排除し、可読性を高める

---

### T-01-03: [エッジケース] {{SCENARIO_EDGE_BEHAVIOR}}

#### T-01-03-01 — {{CASE_EDGE_DESCRIPTION}}

| Input                      | Expected                      |
| -------------------------- | ----------------------------- |
| `{{INPUT_EDGE_EXAMPLE}}`   | `{{EXPECTED_EDGE_EXAMPLE}}`   |

- [ ] **[T-01-03-01-R] Red** : `{{FUNCTION_NAME}}({{INPUT_EDGE_EXAMPLE}})` のテストを書き、失敗を確認する
- [ ] **[T-01-03-01-G] Green** : エッジケースが正しく処理されることを確認する
- [ ] **[T-01-03-01-F] Refactor** : エッジケース処理を整理する

#### T-01-03-TF — エッジケーステストリファクタリング

> T-01-03 の全 Case 完了後に実施する

- [ ] **[T-01-03-TF] Test Refactor**: エッジケース系テストケースの重複・冗長性を排除し、可読性を高める

---

### T-01-CF — 実装コードリファクタリング

> 全 Scenario (T-01-01 〜 T-01-03) の完了後に実施する

- [ ] **[T-01-CF] Code Refactor**: 実装コード全体を見直し、重複排除・命名改善・構造最適化を行う。全テストが引き続き通ることを確認する

---

## 4. Task ID Mapping

| Task ID    | Category            | Input                     | Expected                     |
| ---------- | ------------------- | ------------------------- | ---------------------------- |
| T-01-01-01 | 正常                | `{{INPUT_EXAMPLE}}`       | `{{EXPECTED_EXAMPLE}}`       |
| T-01-01-TF | 正常 (テスト整理)   | —                         | テスト最適化                 |
| T-01-02-01 | 異常                | `{{INPUT_ERROR_EXAMPLE}}` | `{{EXPECTED_ERROR_EXAMPLE}}` |
| T-01-02-TF | 異常 (テスト整理)   | —                         | テスト最適化                 |
| T-01-03-01 | エッジケース        | `{{INPUT_EDGE_EXAMPLE}}`  | `{{EXPECTED_EDGE_EXAMPLE}}`  |
| T-01-03-TF | エッジ (テスト整理) | —                         | テスト最適化                 |
| T-01-CF    | 実装コード整理      | —                         | 実装コード最適化             |

---

<!--
Task ID Format: T-<Target>-<Scenario>-<Case>[-Phase]

Levels:
  Target   (T-01)        : function or class under test
  Scenario (T-01-01)     : specification behavior group
  Case     (T-01-01-01)  : concrete input-output example
  Phase    (-R/-G/-F)    : BDD cycle phase (checklist items only)

Special suffixes:
  -TF  = Test Refactor  (after all Cases in a Scenario are done)
  -CF  = Code Refactor  (after all Scenarios in a Target are done)
-->
