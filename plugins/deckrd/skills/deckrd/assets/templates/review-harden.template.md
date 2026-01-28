---
title: "Review: {{DOCUMENT_NAME}}"
phase: harden
persona: Normative Requirements Reviewer
document: "{{DOCUMENT_PATH}}"
date: "{{DATE}}"
status: draft
---

> **Harden Review Report**
> Persona: Normative Requirements Reviewer
> Purpose: Harden requirements, make definitive decisions

## 1. Summary

- Document Reviewed: {{DOCUMENT_PATH}}
- Document Type: {{DOCUMENT_TYPE}}
- Promotions: {{PROMOTION_COUNT}}
- WHEN Extractions: {{WHEN_COUNT}}
- Gap Fills: {{GAP_FILL_COUNT}}
- Decision Records Generated: {{DR_COUNT}}

## 2. SHOULD to MUST Promotions

Requirements promoted from SHOULD to MUST with justification.

### P-01: {{REQUIREMENT_ID}} Promotion

- Original: SHOULD {{ORIGINAL_TEXT}}
- Promoted: MUST {{PROMOTED_TEXT}}
- Justification: {{JUSTIFICATION}}
- Evidence: {{EVIDENCE}}
- DR Reference: DR-{{DR_NUMBER}}

{{ADDITIONAL_PROMOTIONS}}

## 3. WHEN Condition Extractions

Conditions extracted from ambiguous statements.

### W-01: {{REQUIREMENT_ID}} Condition

- Original: {{ORIGINAL_TEXT}}
- Extracted condition: WHEN {{CONDITION}}
- Revised: WHEN {{CONDITION}}, {{REQUIREMENT}} {{MODAL}} {{ACTION}}
- Rationale: {{RATIONALE}}

{{ADDITIONAL_WHEN_EXTRACTIONS}}

## 4. Gap-Filling Requirements

New requirements added to fill identified gaps.

### GF-01: New Requirement

- Gap identified: {{GAP_DESCRIPTION}}
- New requirement: {{NEW_REQUIREMENT_ID}}: {{MODAL}} {{REQUIREMENT_TEXT}}
- Category: {{CATEGORY}}
- Rationale: {{RATIONALE}}
- DR Reference: DR-{{DR_NUMBER}}

{{ADDITIONAL_GAP_FILLS}}

## 5. Decision Records

### DR-XX: {{DECISION_TITLE}}

**Phase**: review-harden
**Status**: Accepted

### Context

{{DR_CONTEXT}}

### Decision

{{DR_DECISION}}

### Alternatives Considered

- Option A: {{OPTION_A}}
- Option B: {{OPTION_B}}

### Rationale

{{DR_RATIONALE}}

### Consequences

- Positive:
  - {{POSITIVE_CONSEQUENCE}}
- Negative:
  - {{NEGATIVE_CONSEQUENCE}}

---

{{ADDITIONAL_DR_ENTRIES}}

## 6. Review Metadata

- Reviewer: AI (deckrd review --phase harden)
- Review Phase: harden
- Review Date: {{DATE}}
- Document Version Reviewed: {{DOCUMENT_VERSION}}
- Total DRs Generated: {{DR_COUNT}}
