---
title: "Requirements: {{FEATURE_NAME}}"
module: "{{ MODULE_OR_DOMAIN }}"
status: Draft
version: 1.0
created: "{{ DATE }}"
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

**Out of Scope**: {{OUT_OF_SCOPE}}

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

<!--
REQ-ID format:
  REQ-F-NNN  Functional Requirement
  REQ-NF-NNN Non-Functional Requirement
  REQ-C-NNN  Constraint
-->

### REQ-F-001: {{REQUIREMENT_TITLE_1}}

SHALL {{REQUIREMENT_STATEMENT_1}}

**Rationale**: {{RATIONALE_1}}

**Acceptance Criteria**:

| AC ID  | Scenario                |
| ------ | ----------------------- |
| AC-001 | {{AC_SCENARIO_TITLE_1}} |
| AC-002 | {{AC_SCENARIO_TITLE_2}} |

### REQ-F-002: {{REQUIREMENT_TITLE_2}}

SHALL {{REQUIREMENT_STATEMENT_2}}

**Rationale**: {{RATIONALE_2}}

**Acceptance Criteria**:

| AC ID  | Scenario                |
| ------ | ----------------------- |
| AC-003 | {{AC_SCENARIO_TITLE_3}} |

## 5. Non-Functional Requirements

### REQ-NF-001: Maintainability

Implementation SHOULD be maintainable.

### REQ-NF-002: Testability

Implementation MUST be testable.

### REQ-NF-003: Portability

Implementation MUST support UTF-8 input.

## 6. Constraints

### REQ-C-001: {{CONSTRAINT_TITLE_1}}

{{CONSTRAINT_STATEMENT_1}}

## 7. Acceptance Criteria

```gherkin
# AC-001: {{AC_SCENARIO_TITLE_1}}
# Requirement: REQ-F-001
Scenario: {{AC_SCENARIO_TITLE_1}}
  Given {{PRECONDITION_1}}
  When  {{ACTION_1}}
  Then  {{EXPECTED_RESULT_1}}

# AC-002: {{AC_SCENARIO_TITLE_2}}
# Requirement: REQ-F-001
Scenario: {{AC_SCENARIO_TITLE_2}}
  Given {{PRECONDITION_2}}
  When  {{ACTION_2}}
  Then  {{EXPECTED_RESULT_2}}

# AC-003: {{AC_SCENARIO_TITLE_3}}
# Requirement: REQ-F-002
Scenario: {{AC_SCENARIO_TITLE_3}}
  Given {{PRECONDITION_3}}
  When  {{ACTION_3}}
  Then  {{EXPECTED_RESULT_3}}
```

## 8. Traceability

| REQ ID     | AC IDs         | Type           |
| ---------- | -------------- | -------------- |
| REQ-F-001  | AC-001, AC-002 | Functional     |
| REQ-F-002  | AC-003         | Functional     |
| REQ-NF-001 | —              | Non-Functional |
| REQ-NF-002 | —              | Non-Functional |
| REQ-NF-003 | —              | Non-Functional |
| REQ-C-001  | —              | Constraint     |

## 9. Open Questions

| Question       | Type       | Impact Area  | Owner       |
| -------------- | ---------- | ------------ | ----------- |
| {{QUESTION_1}} | {{TYPE_1}} | {{IMPACT_1}} | {{OWNER_1}} |

## 10. Change History

| Date     | Version | Description     |
| -------- | ------- | --------------- |
| {{DATE}} | 1.0     | Initial release |
