---
title: "spec Phase 10: External Spec Review & Cleanup"
description: Strip implementation detail and requirements restatement from each generated file
---

<!-- textlint-disable
    ja-technical-writing/no-exclamation-question-mark,
    ja-technical-writing/sentence-length,
    ja-technical-writing/max-comma -->
<!-- markdownlint-disable line-length -->

## Phase 10: External Spec Review & Cleanup (max 2 rounds)

## Standalone Invocation

```bash
/deckrd spec --phase spec-review
```

## Preconditions

| 必要な入力                 | 生成元  | 欠けているとき         |
| -------------------------- | ------- | ---------------------- |
| `specifications/` の生成物 | Phase 9 | Phase 9 を先に実行する |

## Steps

After all specification files are written, review each file.
Ensure each file contains **only external specification content**.

### Step 10-1: Self-Scan

Read each generated file and flag every passage that matches a removal criterion:

| Criterion                | Examples                                                                   | Action                            |
| ------------------------ | -------------------------------------------------------------------------- | --------------------------------- |
| Implementation detail    | Function names, type signatures, file paths, class names                   | Remove or rewrite                 |
| Requirements restatement | Sentences copied verbatim from `requirements.md`; FR/NFR bullet re-listing | Remove                            |
| Notes / impl hints       | `<!-- impl: ... -->`, `> Note for impl:` comments                          | **Keep** (pass-through to `impl`) |

**Do NOT remove:**

- Behavioral rules expressed in declarative form
- Edge cases and invariants
- Interface contracts (pre/post-conditions without code)
- Cross-unit interaction ordering
- Notes explicitly marked as implementation hints

### Step 10-2: Present Findings to User

For each flagged passage, present a concise diff-style summary:

```bash
[Spec Review] specifications-auth.md

REMOVE (implementation detail):
  Line 42: "calls authenticate() function and checks return value"
  → Suggest: "performs authentication and evaluates the result"
  Accept? (Y / keep / custom)

REMOVE (requirements restatement):
  Line 67: "FR-03: The system SHALL validate email format"
  → This duplicates requirements.md FR-03. Remove?
  Accept? (Y / keep)
```

If no issues found:

```bash
[Spec Review] No external-spec violations found in <filename>.
```

### Step 10-3: Apply Changes

For each accepted removal or rewrite:

1. Edit the file in-place
2. If a passage was rewritten, append the original as an impl note:

   ```yaml
   <!-- impl-note: original said "calls authenticate() function" -->
   ```

3. After all files are cleaned, show a final summary:

   ```bash
   [Cleanup Complete]
   - specifications-auth.md: 2 removed, 1 rewritten
   - specifications-notify.md: no changes
   ```

**Termination conditions:**

1. User approves all changes with "Y", "OK", "承認", or equivalent
2. 2 rounds completed — record any remaining disputed items in Section 7 (Open Questions)

## Output

Cleaned specification files, and the user's approval that gates Phase 11.

## Next Phase

[Phase 11: Version Bump](11-version-bump.md)
