---
title: "Design Specification: {{FEATURE_NAME}}"
Based on: requirements.md v{{REQ_VERSION}}
Status: Draft
---

## 1. Overview

### 1.1 Purpose

{{WHAT_THIS_SPEC_DEFINES}}

### 1.2 Scope

This specification defines the **behavioral rules** and
**classification semantics** of {{FEATURE_NAME}}.

Implementation details are explicitly out of scope.

---

## 2. Design Principles

### 2.1 Classification Philosophy

{{DESIGN_PHILOSOPHY}}

### 2.2 Design Assumptions

{{DESIGN_ASSUMPTIONS}}

### 2.3 Non-Goals

- {{NON_GOAL_1}}
- {{NON_GOAL_2}}
<!-- Add more non-goals as needed -->

---

## 3. Behavioral Specification

### 3.1 Input Domain

- Input Type: {{INPUT_TYPE}}
- Assumptions: {{INPUT_ASSUMPTIONS}}

### 3.2 Output Semantics

- Output Meaning: {{OUTPUT_MEANING}}
- Possible Outcomes:
  - {{OUTCOME_1}}
  - {{OUTCOME_2}}

---

## 4. Decision Rules

Evaluation MUST follow this order:

| Step | Condition       | Outcome      |
| ---: | --------------- | ------------ |
|    1 | {{CONDITION_1}} | {{RESULT_1}} |
|    2 | {{CONDITION_2}} | {{RESULT_2}} |
|    3 | {{CONDITION_3}} | {{RESULT_3}} |

<!-- Add or remove steps as required -->
No reordering is permitted.

---

## 5. Edge Cases

| Input      | Classification | Rationale |
| ---------- | -------------- | --------- |
| {{EDGE_1}} | {{RESULT_1}}   | {{WHY_1}} |
| {{EDGE_2}} | {{RESULT_2}}   | {{WHY_2}} |

---

## 6. Requirements Traceability

| Requirement ID | Covered By        |
| -------------- | ----------------- |
| {{FR_1}}       | {{SECTION_REF_1}} |
| {{FR_2}}       | {{SECTION_REF_2}} |

---

## 7. Open Questions (Optional)

- {{OPEN_QUESTION_1}}

---

## 8. Change History

| Date     | Version | Description           |
| -------- | ------- | --------------------- |
| {{DATE}} | 1.0     | Initial specification |
