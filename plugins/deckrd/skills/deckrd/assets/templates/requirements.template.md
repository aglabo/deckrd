---
title: "Requirements: {{FEATURE_NAME}}"
Module: "{{ MODULE_OR_DOMAIN }}"
Status: Draft
Version: 1.0
Created: "{{ DATE }}"
---

> **Normative Statement**
> This document defines binding requirements.
> Implementations MUST conform to this document.
> RFC 2119 keywords apply to this document only.

## 1. Overview

### 1.1 Purpose

{{PURPOSE}}

### 1.2 Scope

{{IN_SCOPE}}

**Out of Scope**:
{{OUT_OF_SCOPE}}

## 2. Context

- Target Environment: {{ENVIRONMENT}}
- Related Components: {{RELATED_COMPONENTS}}
- Assumptions: {{ASSUMPTIONS}}

## 3. Design Decisions (Summary)

| ID    | Decision               | Linked Record            |
| ----- | ---------------------- | ------------------------ |
| DR-01 | {{DECISION_SUMMARY_1}} | decision-record.md#DR-01 |
| DR-02 | {{DECISION_SUMMARY_2}} | decision-record.md#DR-02 |

## 4. Functional Requirements

- FR-01: SHALL {{REQUIREMENT_1}}
- FR-02: SHALL {{REQUIREMENT_2}}

## 5. Non-Functional Requirements

### 5.1 Quality

- Maintainability
- Testability
- Portability

### 5.2 Constraints

{{CONSTRAINTS}}

## 6. Change History

| Date     | Version | Description     |
| -------- | ------- | --------------- |
| {{DATE}} | 1.0     | Initial release |

## 7. User Stories

| ID    | Role        | Goal                   | Reason                |
| ----- | ----------- | ---------------------- | --------------------- |
| US-01 | {{ROLE_1}}  | {{GOAL_1}}             | {{REASON_1}}          |
| US-02 | {{ROLE_2}}  | {{GOAL_2}}             | {{REASON_2}}          |
| US-03 | {{ROLE_3}}  | {{GOAL_3}}             | {{REASON_3}}          |

## 8. Acceptance Criteria

```gherkin
Scenario: {{SCENARIO_TITLE_1}}
  Given {{PRECONDITION_1}}
  When  {{ACTION_1}}
  Then  {{EXPECTED_RESULT_1}}

Scenario: {{SCENARIO_TITLE_2}}
  Given {{PRECONDITION_2}}
  When  {{ACTION_2}}
  Then  {{EXPECTED_RESULT_2}}

Scenario: {{SCENARIO_TITLE_3}}
  Given {{PRECONDITION_3}}
  When  {{ACTION_3}}
  Then  {{EXPECTED_RESULT_3}}

Scenario: {{EXCEPTION_SCENARIO_TITLE_1}}
  Given {{EXCEPTION_PRECONDITION_1}}
  When  {{EXCEPTION_ACTION_1}}
  Then  {{EXCEPTION_EXPECTED_RESULT_1}}

Scenario: {{EXCEPTION_SCENARIO_TITLE_2}}
  Given {{EXCEPTION_PRECONDITION_2}}
  When  {{EXCEPTION_ACTION_2}}
  Then  {{EXCEPTION_EXPECTED_RESULT_2}}
```

## 9. Open Questions

| Question         | Type              | Impact Area      | Owner       |
| ---------------- | ----------------- | ---------------- | ----------- |
| {{QUESTION_1}}   | {{TYPE_1}}        | {{IMPACT_1}}     | {{OWNER_1}} |
| {{QUESTION_2}}   | {{TYPE_2}}        | {{IMPACT_2}}     | {{OWNER_2}} |
