---
title: "Design Specification: {{FEATURE_NAME}}"
based-on: requirements.md v{{REQ_VERSION}}
status: Draft
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

### 2.3 External Design Summary

> **Source**: Derived from the external design dialogue (Phase E) and user-confirmed design direction (Phase D).

#### Feature Decomposition

| Unit       | Responsibility       | REQ Coverage    |
| ---------- | -------------------- | --------------- |
| {{UNIT_1}} | {{RESPONSIBILITY_1}} | {{REQ_F_REF_1}} |
| {{UNIT_2}} | {{RESPONSIBILITY_2}} | {{REQ_F_REF_2}} |

#### Unit Interaction Map

```text
+------------+     +------------+
|  {{UNIT_1}}| --> |  {{UNIT_2}}|
+------------+     +------------+
      |                   |
      v                   v
+------------+     +------------+
|  {{UNIT_3}}|     |  {{UNIT_4}}|
+------------+     +------------+
```

<!-- If no cross-unit interaction: "Units are independent; no ordering constraints." -->

#### Data Flow Diagram

```text
[{{INPUT}}] --> [{{UNIT_1}}] --> [{{UNIT_2}}] --> [{{OUTPUT}}]
                     |
                     v
                [{{VALIDATION}}]
```

<!-- ASCII diagrams only. Mermaid, PlantUML, and SVG are prohibited. -->

### 2.4 Non-Goals

> **Derivation**: All items below originate from REQUIREMENTS Section "Out of Scope".

- {{NON_GOAL_1}} ← REQ: Out of Scope #1
- {{NON_GOAL_2}} ← REQ: Out of Scope #2

<!-- If REQUIREMENTS has no Out of Scope section: -->
<!-- > "No Non-Goals defined in source REQUIREMENTS." -->

### 2.5 Behavioral Design Decisions

| ID    | Decision | Rationale | Affected Rules | Status |
| ----- | -------- | --------- | -------------- | ------ |
| DD-01 | ...      | ...       | R-01           | Active |

> **Note**: Decisions listed here derive from REQUIREMENTS Design Decisions.
> If promoting to formal Decision Record, use `/deckrd dr --add`.

**Status Values:**

- `Active` — Currently in effect within this specification
- `Promoted → DR-xx` — Elevated to formal Decision Record (see Section 2.6)

<!-- If no DD exists in REQUIREMENTS: -->
<!-- > "No Design Decisions defined in source REQUIREMENTS." -->

### 2.6 Related Decision Records

> **Reference**: This section lists formal DRs that affect this specification.
> DRs are maintained in `decision-records.md` and are authoritative.

| DR-ID | Title        | Phase | Impact on This Spec    |
| ----- | ------------ | ----- | ---------------------- |
| DR-xx | {{DR_TITLE}} | spec  | {{IMPACT_DESCRIPTION}} |

<!-- If no related DRs: -->
<!-- > "No Decision Records currently affect this specification." -->

### 2.7 DD to DR Promotion Criteria

> **Purpose**: Guidelines for determining when a DD should be promoted to a formal DR.
> Promotion is a **human judgment** — these criteria inform, not automate.

**Consider promoting a DD when:**

1. **Cross-specification Impact** — The decision affects multiple specifications or modules
2. **Architectural Significance** — The decision constrains future design choices
3. **Non-trivial Alternatives** — Multiple viable options existed
4. **Stakeholder Visibility Required** — The decision should be reviewable by external parties

**Keep as DD when:**

- Decision is local to this specification only
- No significant alternatives existed
- Rationale is self-evident from context

> **Action**: To promote, run `/deckrd dr --add` with the DD context,
> then update DD Status to `Promoted → DR-xx`.

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

<!--
Rule ID format: R-NNN (sequential, stable)
Rule IDs are referenced in Traceability and Edge Cases.
-->

Evaluation MUST follow this order:

| Rule ID | Step | Condition       | Outcome      |
| ------- | ---: | --------------- | ------------ |
| R-001   |    1 | {{CONDITION_1}} | {{RESULT_1}} |
| R-002   |    2 | {{CONDITION_2}} | {{RESULT_2}} |
| R-003   |    3 | {{CONDITION_3}} | {{RESULT_3}} |

No reordering is permitted.

---

## 5. Edge Cases

| Input      | Classification | REQ           | Rationale |
| ---------- | -------------- | ------------- | --------- |
| {{EDGE_1}} | {{RESULT_1}}   | {{REQ_F_NNN}} | {{WHY_1}} |
| {{EDGE_2}} | {{RESULT_2}}   | {{REQ_F_NNN}} | {{WHY_2}} |

---

## 6. Requirements Traceability

| Requirement ID | Spec Rule | Notes      |
| -------------- | --------- | ---------- |
| {{REQ_F_001}}  | R-001     | {{NOTE_1}} |
| {{REQ_F_002}}  | R-002     | {{NOTE_2}} |
| {{REQ_F_003}}  | Edge 5.1  | {{NOTE_3}} |

---

## 7. Open Questions

> **Status**: [COMPLETE | INCOMPLETE]

| # | Question            | Source  | Impact       |
| - | ------------------- | ------- | ------------ |
| 1 | {{OPEN_QUESTION_1}} | {{REF}} | {{IMPACT_1}} |

<!-- If none: "None identified - all requirements are unambiguous." -->

---

## 8. Change History

| Date     | Version | Description           |
| -------- | ------- | --------------------- |
| {{DATE}} | 1.0.0   | Initial specification |
