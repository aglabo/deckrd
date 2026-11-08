---
title: "Decision Records: {{MODULE_ID}}"
module: "{{MODULE_ID}}"
status: Active
version: 1.0.0
created: "{{DATE}}"
---

> This document records architectural and design decisions.
> It is non-normative and exists to preserve rationale.

<!-- textlint-disable ja-technical-writing/sentence-length -->
<!-- textlint-disable ja-technical-writing/max-comma -->
<!-- markdownlint-disable no-duplicate-heading line-length  -->

<!--
Writing rules: references/guidelines/decision-record-authoring.md (the single source of truth).
Optional frontmatter: `based-on: requirements.md vX.Y.Z` when the DRs depend on a specific requirements version.
Keep it equal to the latest upstream version, after checking the DRs against it (guideline E-6).
Every DR section, including the last one, ends with `---` (guideline A-3).
-->

---

## DR-01: {{DECISION_TITLE}} - {{YYYY-MM-DD HH:MM:SS}}

**Phase**: {{PHASE}}
**Status**: Accepted

<!-- Phase:  req | spec | impl | tasks | review-harden -->
<!-- Status: Proposed | Accepted | Deprecated | Partially superseded by DR-NN (scope) | Superseded by DR-NN -->
<!-- Optional, only when this DR replaces another one (guideline E-1):
**Supersedes**: DR-NN (scope that is replaced)
-->

### Context

{{CONTEXT}}

<!-- Facts of this project, verified against code or primary sources. Why decide now? (C-1, C-3) -->

### Decision

{{DECISION}}

<!-- Use definitive statements (D-6). For several decisions on one theme, number them:
1. 決定 1: ...
2. 決定 2: ...
Keep it at a level that survives swapping the implementation (D-4). -->

### Scope

- Applies to: {{SCOPE}}
- Not decided here:
  - {{NOT_DECIDED}} → {{DELEGATED_TO}}

### Alternatives Considered

- {{OPTION_A}}. {{REJECTION_REASON_A}}
- {{OPTION_B}}. {{REJECTION_REASON_B}}

<!-- Every alternative ends with why it was rejected (D-7). -->

### Rationale

{{RATIONALE}}

### Consequences

- Positive:
  - {{POSITIVE_1}}
- Negative:
  - {{NEGATIVE_1}}
- Revisit Trigger:
  - {{REVISIT_TRIGGER}}

<!-- Optional. If present, Status MUST be Proposed (G-1).
### Open Questions

- {{OPEN_QUESTION}}
-->

### Related

- {{RELATED_FILE}}: {{RELATED_ID}}
- GitHub Issue: {{ISSUE_REF}}

---

<!--
Append new DR sections right after the last DR (above `## Deleted Decision Records` if present,
otherwise above `## Change History`).
IDs are sequential and never reused: DR-01, DR-02, ... Deleted IDs are listed in a
`## Deleted Decision Records` table (| ID | Title | Reason |) placed above `## Change History`.

Versioning (SemVer, see docs/.deckrd/rules/deckrd-rule-document-versioning.md):
  MINOR — a new DR is added
  PATCH — an existing DR's wording or rationale is clarified
  MAJOR — an accepted DR is superseded, reversed, or deleted

Keep frontmatter `version` equal to the newest Change History row below.
One version bump per commit: if an uncommitted bump already exists, merge into that row
instead of adding another one (guideline E-4).
-->

## Change History

| Date     | Version | Description                           |
| -------- | ------- | ------------------------------------- |
| {{DATE}} | 1.0.0   | Initial release with DR-01: {{TITLE}} |
