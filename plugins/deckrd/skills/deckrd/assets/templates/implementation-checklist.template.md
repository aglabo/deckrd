---
title: "Implementation Checklist"
module: "{{ MODULE }}"
status: Active
created: "{{ YYYY-MM-DD HH:MM:SS }}"
source: tasks.md
spec: specifications.md
---

<!-- textlint-disable
  ja-technical-writing/sentence-length,
  ja-technical-writing/max-comma -->
<!-- markdownlint-disable line-length -->

> This document is the BDD execution checklist derived from tasks.md.
> Each test case expands into Red-Green-Refactor cycle check items with unique task IDs.

---

## 1. Overview

### 1.1 Task Hierarchy

| Level    | ID Format    | Definition                                                           |
| -------- | ------------ | -------------------------------------------------------------------- |
| Target   | `T-01`       | Function or class under test                                         |
| Scenario | `T-01-01`    | Specification behavior group (e.g. "Trim whitespace")                |
| Case     | `T-01-01-01` | Concrete input-output example (e.g. `" Alice "` → `"Hello, Alice!"`) |

> **Scenario** = a group of cases sharing the same behavioral contract from the specification.
> **Case** = one concrete input-output pair that exercises that behavior.

### 1.2 BDD サイクル凡例

| フェーズ      | 記号  | 意味                                              |
| ------------- | ----- | ------------------------------------------------- |
| Red           | `-R`  | テストを先に書き、失敗することを確認する          |
| Green         | `-G`  | テストが通る最小限の実装を行う                    |
| Refactor      | `-F`  | 動作を変えずに個別実装コードを整理する            |
| Test Refactor | `-TF` | Scenario 内の全 Case 完了後にテストを最適化       |
| Code Refactor | `-CF` | Target 内の全 Scenario 完了後に実装コードを最適化 |

---

## 2. Task Structure

```text
T-01: {{TEST_TARGET_NAME}}
  T-01-01: [正常] {{SCENARIO_BEHAVIOR_1}}
    T-01-01-01: {{CASE_INPUT_EXAMPLE_1}}  (R/G/F)
    T-01-01-02: {{CASE_INPUT_EXAMPLE_2}}  (R/G/F)
    T-01-01-TF: Scenario テストリファクタリング

  T-01-02: [正常] {{SCENARIO_BEHAVIOR_2}}
    T-01-02-01: {{CASE_INPUT_EXAMPLE_1}}  (R/G/F)
    T-01-02-TF: Scenario テストリファクタリング

  T-01-03: [異常] {{SCENARIO_ERROR_BEHAVIOR}}
    T-01-03-01: {{CASE_ERROR_INPUT_EXAMPLE}}  (R/G/F)
    T-01-03-TF: 異常系テストリファクタリング

  T-01-04: [エッジケース] {{SCENARIO_EDGE_BEHAVIOR}}
    T-01-04-01: {{CASE_EDGE_INPUT_EXAMPLE}}  (R/G/F)
    T-01-04-TF: エッジケーステストリファクタリング

  T-01-CF: 実装コードリファクタリング
```

---

## 3. Implementation Checklist

### T-01-01: [正常] {{SCENARIO_BEHAVIOR_1}}

> Requirement: {{REQ_F_NNN}} <!-- e.g. REQ-F-001 -->

#### T-01-01-01 — {{CASE_DESCRIPTION_STRING_1}}

| Input                        | Expected                        |
| ---------------------------- | ------------------------------- |
| `{{INPUT_STRING_EXAMPLE_1}}` | `{{EXPECTED_STRING_EXAMPLE_1}}` |

- [ ] **[T-01-01-01-R] Red** : `{{FUNCTION_NAME}}({{INPUT_STRING_EXAMPLE_1}})` のテストを書き、失敗を確認する
- [ ] **[T-01-01-01-G] Green** : テストが通る最小限の実装をする
- [ ] **[T-01-01-01-F] Refactor** : 実装を整理し、テストが引き続き通ることを確認する

#### T-01-01-02 — {{CASE_DESCRIPTION_STRING_2}}

| Input                        | Expected                        |
| ---------------------------- | ------------------------------- |
| `{{INPUT_STRING_EXAMPLE_2}}` | `{{EXPECTED_STRING_EXAMPLE_2}}` |

- [ ] **[T-01-01-02-R] Red** : `{{FUNCTION_NAME}}({{INPUT_STRING_EXAMPLE_2}})` のテストを書き、失敗を確認する
- [ ] **[T-01-01-02-G] Green** : テストが通る最小限の実装をする
- [ ] **[T-01-01-02-F] Refactor** : 実装を整理し、テストが引き続き通ることを確認する

#### T-01-01-TF — {{SCENARIO_BEHAVIOR_1}} テストリファクタリング

> T-01-01 の全 Case 完了後に実施する

- [ ] **[T-01-01-TF] Test Refactor**: {{SCENARIO_BEHAVIOR_1}} テストケースの重複・冗長性を排除し、可読性を高める

---

### T-01-02: [正常] {{SCENARIO_BEHAVIOR_2}}

> Requirement: {{REQ_F_NNN}} <!-- e.g. REQ-F-001 -->

#### T-01-02-01 — {{CASE_DESCRIPTION_STRING_1}}

| Input                        | Expected                        |
| ---------------------------- | ------------------------------- |
| `{{INPUT_STRING_EXAMPLE_1}}` | `{{EXPECTED_STRING_EXAMPLE_1}}` |

- [ ] **[T-01-02-01-R] Red** : `{{FUNCTION_NAME}}({{INPUT_STRING_EXAMPLE_1}})` のテストを書き、失敗を確認する
- [ ] **[T-01-02-01-G] Green** : テストが通る最小限の実装をする
- [ ] **[T-01-02-01-F] Refactor** : 実装を整理し、テストが引き続き通ることを確認する

#### T-01-02-TF — {{SCENARIO_BEHAVIOR_2}} テストリファクタリング

> T-01-02 の全 Case 完了後に実施する

- [ ] **[T-01-02-TF] Test Refactor**: {{SCENARIO_BEHAVIOR_2}} テストケースの重複・冗長性を排除し、可読性を高める

---

### T-01-03: [異常] {{SCENARIO_ERROR_BEHAVIOR}}

> Requirement: {{REQ_F_NNN}} <!-- e.g. REQ-F-001 -->

#### T-01-03-01 — {{CASE_ERROR_DESCRIPTION_STRING}}

| Input                            | Expected                            |
| -------------------------------- | ----------------------------------- |
| `{{INPUT_ERROR_STRING_EXAMPLE}}` | `{{EXPECTED_ERROR_STRING_EXAMPLE}}` |

- [ ] **[T-01-03-01-R] Red** : `{{FUNCTION_NAME}}({{INPUT_ERROR_STRING_EXAMPLE}})` のテストを書き、失敗を確認する
- [ ] **[T-01-03-01-G] Green** : エラー処理を実装し、テストが通ることを確認する
- [ ] **[T-01-03-01-F] Refactor** : エラー処理の実装を整理する

#### T-01-03-TF — 異常系テストリファクタリング

> T-01-03 の全 Case 完了後に実施する

- [ ] **[T-01-03-TF] Test Refactor**: 異常系テストケースの重複・冗長性を排除し、可読性を高める

---

### T-01-04: [エッジケース] {{SCENARIO_EDGE_BEHAVIOR}}

> Requirement: {{REQ_F_NNN}} <!-- e.g. REQ-F-001 -->

#### T-01-04-01 — {{CASE_EDGE_DESCRIPTION_STRING}}

| Input                           | Expected                           |
| ------------------------------- | ---------------------------------- |
| `{{INPUT_EDGE_STRING_EXAMPLE}}` | `{{EXPECTED_EDGE_STRING_EXAMPLE}}` |

- [ ] **[T-01-04-01-R] Red** : `{{FUNCTION_NAME}}({{INPUT_EDGE_STRING_EXAMPLE}})` のテストを書き、失敗を確認する
- [ ] **[T-01-04-01-G] Green** : エッジケースが正しく処理されることを確認する
- [ ] **[T-01-04-01-F] Refactor** : エッジケース処理に特別な分岐がないことを確認し、整理する

#### T-01-04-TF — エッジケーステストリファクタリング

> T-01-04 の全 Case 完了後に実施する

- [ ] **[T-01-04-TF] Test Refactor**: エッジケース系テストケースの重複・冗長性を排除し、可読性を高める

---

### T-01-CF — 実装コードリファクタリング

> 全 Scenario (T-01-01 〜 T-01-04) の完了後に実施する

- [ ] **[T-01-CF] Code Refactor**: 実装コード全体を見直し、重複排除・命名改善・構造最適化を行う。全テストが引き続き通ることを確認する

---

## 4. Task ID Mapping

| Task ID    | Category            | Input                            | Expected                            | Requirement   |
| ---------- | ------------------- | -------------------------------- | ----------------------------------- | ------------- |
| T-01-01-01 | 正常                | `{{INPUT_STRING_EXAMPLE_1}}`     | `{{EXPECTED_STRING_EXAMPLE_1}}`     | {{REQ_F_NNN}} |
| T-01-01-02 | 正常                | `{{INPUT_STRING_EXAMPLE_2}}`     | `{{EXPECTED_STRING_EXAMPLE_2}}`     | {{REQ_F_NNN}} |
| T-01-01-TF | 正常 (テスト整理)   | —                                | テスト最適化                        | —             |
| T-01-02-01 | 正常                | `{{INPUT_STRING_EXAMPLE_1}}`     | `{{EXPECTED_STRING_EXAMPLE_1}}`     | {{REQ_F_NNN}} |
| T-01-02-TF | 正常 (テスト整理)   | —                                | テスト最適化                        | —             |
| T-01-03-01 | 異常                | `{{INPUT_ERROR_STRING_EXAMPLE}}` | `{{EXPECTED_ERROR_STRING_EXAMPLE}}` | {{REQ_F_NNN}} |
| T-01-03-TF | 異常 (テスト整理)   | —                                | テスト最適化                        | —             |
| T-01-04-01 | エッジケース        | `{{INPUT_EDGE_STRING_EXAMPLE}}`  | `{{EXPECTED_EDGE_STRING_EXAMPLE}}`  | {{REQ_F_NNN}} |
| T-01-04-TF | エッジ (テスト整理) | —                                | テスト最適化                        | —             |
| T-01-CF    | 実装コード整理      | —                                | 実装コード最適化                    | —             |

---

## 5. Traceability

| Requirement ID | AC ID  | Covered By             |
| -------------- | ------ | ---------------------- |
| REQ-F-001      | AC-001 | T-01-01-01, T-01-01-02 |
| REQ-F-001      | AC-002 | T-01-02-01             |
| REQ-F-002      | AC-003 | T-01-03-01, T-01-04-01 |

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

Variable naming convention:
  {{INPUT_STRING_EXAMPLE_N}}    : concrete string input example
  {{EXPECTED_STRING_EXAMPLE_N}} : concrete string expected output
  {{INPUT_ERROR_STRING_EXAMPLE}}: concrete error-case input
  {{INPUT_EDGE_STRING_EXAMPLE}} : concrete edge-case input
  {{REQ_F_NNN}}                 : Functional Requirement ID from requirements.md (e.g. REQ-F-001, stable)
  AC-NNN                        : Acceptance Criteria ID — child of REQ-F (e.g. AC-001)
  {{FUNCTION_NAME}}             : exact function/method name from implementation.md

Examples:
  T-01-02-03    = Target 01, Scenario 02, Case 03
  T-01-02-03-R  = Red phase of Case 03
  T-01-02-03-G  = Green phase of Case 03
  T-01-02-03-F  = Refactor phase of Case 03
  T-01-02-TF    = Test Refactor for Scenario 02
  T-01-CF       = Code Refactor for Target 01
-->
