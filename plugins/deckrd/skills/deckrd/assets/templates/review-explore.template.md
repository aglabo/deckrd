---
title: "Review: {{DOCUMENT_NAME}}"
phase: explore
persona: Design Reviewer
document: "{{DOCUMENT_PATH}}"
date: "{{DATE}}"
status: draft
---

<!-- textlint-disable ja-technical-writing/sentence-length -->
<!-- textlint-disable ja-technical-writing/no-exclamation-question-mark -->

> **Explore Review Report**
> Persona: Design Reviewer
> Purpose: Initial exploration, identify gaps and alternatives

## 1. Summary

- Document Reviewed: {{DOCUMENT_PATH}}
- Document Type: {{DOCUMENT_TYPE}}
- Total Questions: {{TOTAL_QUESTIONS}}
- Total Concerns: {{TOTAL_CONCERNS}}

## 2. Questions & Concerns

Questions and observations raised during exploration.

### 2.1 Completeness

Are all scenarios covered?

{{COMPLETENESS_QUESTIONS}}

### 2.2 Ambiguity

Are terms clearly defined?

{{AMBIGUITY_QUESTIONS}}

### 2.3 Alternatives

What other approaches exist?

{{ALTERNATIVES_QUESTIONS}}

### 2.4 Assumptions

Are implicit assumptions stated?

{{ASSUMPTIONS_QUESTIONS}}

## 3. Ambiguous Terms

| Term     | Context     | Clarification Needed |
| -------- | ----------- | -------------------- |
| {{TERM}} | {{CONTEXT}} | {{CLARIFICATION}}    |

{{AMBIGUOUS_TERMS_TABLE}}

## 4. Alternatives to Explore

### ALT-01: {{ALTERNATIVE_TITLE}}

- Current approach: {{CURRENT_APPROACH}}
- Alternative: {{ALTERNATIVE_DESCRIPTION}}
- Trade-offs: {{TRADE_OFFS}}
- Consider exploring: {{EXPLORATION_SUGGESTION}}

{{ADDITIONAL_ALTERNATIVES}}

## 5. Implicit Assumptions

Assumptions identified that should be made explicit.

### A-01: {{ASSUMPTION_TITLE}}

- Assumption: {{ASSUMPTION_DESCRIPTION}}
- Location: {{SECTION_REFERENCE}}
- Risk if incorrect: {{RISK_DESCRIPTION}}
- Suggestion: Consider stating explicitly

{{ADDITIONAL_ASSUMPTIONS}}

## 6. Gaps Identified

Areas where coverage may be incomplete.

### G-01: {{GAP_TITLE}}

- Area: {{GAP_AREA}}
- Missing: {{MISSING_DESCRIPTION}}
- Impact: {{IMPACT_DESCRIPTION}}
- Suggestion: {{GAP_SUGGESTION}}

{{ADDITIONAL_GAPS}}

## 7. Review Metadata

- Reviewer: AI (deckrd review --phase explore)
- Review Phase: explore
- Review Date: {{DATE}}
- Document Version Reviewed: {{DOCUMENT_VERSION}}
