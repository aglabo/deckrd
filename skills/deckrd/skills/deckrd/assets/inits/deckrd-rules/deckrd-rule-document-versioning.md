# Deckrd Rule: Document Versioning

<!-- cspell:words desynchronizes -->
<!-- textlint-disable
    ja-technical-writing/sentence-length
    -->

Deckrd documents that carry a Change History must be versioned with SemVer.

Applies to:

requirements.md
specifications.md
implementation.md
decision-records.md

## Format

Versions must be `MAJOR.MINOR.PATCH` — always three parts.

```yaml
---
version: 1.0.0
---
```

`version: 1.0` is invalid. A two-part version desynchronizes the frontmatter
from the Change History table and must be corrected to three parts.

Initial release is `1.0.0`.

## Increment Rules

The question is: **does what gets built change?**

| Part  | Example       | When                                                                 |
| ----- | ------------- | -------------------------------------------------------------------- |
| MAJOR | 1.4.2 → 2.0.0 | Requirement removed, decided approach discarded, scope redefined     |
| MINOR | 1.4.2 → 1.5.0 | Requirement / AC / DR added, decision fixes an implementation target |
| PATCH | 1.4.2 → 1.4.3 | Clarification, rationale, Open Question, typo — substance unchanged  |

A review pass that only records findings is PATCH.
Resolving those findings into a decision is MINOR.

## Synchronization

The frontmatter `version` must equal the newest row of the Change History table.
Every version bump must add exactly one Change History row.

Regeneration during a command's review loop does not bump. A document stays at
`1.0.0` until the user approves it; bumps apply to changes made after approval.

```markdown
| Date       | Version | Description       |
| ---------- | ------- | ----------------- |
| 2026-08-12 | 1.0.0   | Initial release   |
| 2026-08-12 | 1.0.1   | Clarify REQ-F-003 |
| 2026-08-12 | 1.1.0   | Add REQ-F-004     |
```

## Cross-Document References

Downstream documents reference upstream versions in frontmatter:

```yaml
based-on: requirements.md v1.2.0
```

Referenced versions must be three-part and must exist in the upstream
document's Change History.

## Common Rationalizations

| Rationalization                          | Reality                                                                            |
| ---------------------------------------- | ---------------------------------------------------------------------------------- |
| "It's a small edit, bump the patch"      | Size is not the criterion. Adding one requirement is MINOR even if it is one line. |
| "Lots of edits, so bump the minor"       | A hundred clarifications that add no requirement is still PATCH.                   |
| "The version is just a label"            | Downstream documents pin to it. A wrong version breaks traceability.               |
| "I'll reconcile the history table later" | An unrecorded bump makes it impossible to tell which version a reference means.    |
