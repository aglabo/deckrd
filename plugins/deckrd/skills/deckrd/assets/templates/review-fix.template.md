---
title: "Review: {{DOCUMENT_NAME}}"
phase: fix
persona: Spec Auditor
document: "{{DOCUMENT_PATH}}"
date: "{{DATE}}"
status: draft
---

> **Fix Review Report**
> Persona: Spec Auditor
> Purpose: Final cleanup, ensure consistency

## 1. Summary

- Document Reviewed: {{DOCUMENT_PATH}}
- Document Type: {{DOCUMENT_TYPE}}
- Terminology Issues: {{TERMINOLOGY_COUNT}}
- Testability Issues: {{TESTABILITY_COUNT}}
- Structure Issues: {{STRUCTURE_COUNT}}
- Cross-Reference Issues: {{CROSSREF_COUNT}}
- Typo/Grammar Fixes: {{TYPO_COUNT}}

## 2. Terminology Inconsistencies

Same concepts should use same terms throughout.

| Current Term | Recommended Term | Occurrences | Locations     |
| ------------ | ---------------- | ----------- | ------------- |
| {{TERM_A}}   | {{TERM_B}}       | {{COUNT}}   | {{LOCATIONS}} |

{{TERMINOLOGY_TABLE}}

### T-01: {{INCONSISTENCY_TITLE}}

- Terms used: {{TERM_VARIANTS}}
- Recommended: {{RECOMMENDED_TERM}}
- Rationale: {{RATIONALE}}
- Locations to fix:
  - {{LOCATION_1}}
  - {{LOCATION_2}}

{{ADDITIONAL_TERMINOLOGY_ISSUES}}

## 3. Testability Issues

Requirements that cannot be objectively verified.

### TS-01: {{REQUIREMENT_ID}}

- Original: {{ORIGINAL_TEXT}}
- Issue: {{TESTABILITY_ISSUE}}
- Suggested revision: {{SUGGESTED_REVISION}}
- Verification method: {{VERIFICATION_METHOD}}

{{ADDITIONAL_TESTABILITY_ISSUES}}

## 4. Structure Normalization

Formatting and organization improvements.

### S-01: {{STRUCTURE_ISSUE_TITLE}}

- Location: {{SECTION_REFERENCE}}
- Issue: {{STRUCTURE_ISSUE}}
- Fix: {{STRUCTURE_FIX}}

{{ADDITIONAL_STRUCTURE_ISSUES}}

## 5. Cross-Reference Validation

Invalid or missing references.

### CR-01: {{CROSSREF_ISSUE_TITLE}}

- Location: {{SECTION_REFERENCE}}
- Reference: {{REFERENCE_TEXT}}
- Issue: {{CROSSREF_ISSUE}}
- Fix: {{CROSSREF_FIX}}

{{ADDITIONAL_CROSSREF_ISSUES}}

## 6. Typo & Grammar Fixes

| Location     | Original     | Corrected     |
| ------------ | ------------ | ------------- |
| {{LOCATION}} | {{ORIGINAL}} | {{CORRECTED}} |

{{TYPO_TABLE}}

## 7. Review Metadata

- Reviewer: AI (deckrd review --phase fix)
- Review Phase: fix
- Review Date: {{DATE}}
- Document Version Reviewed: {{DOCUMENT_VERSION}}
