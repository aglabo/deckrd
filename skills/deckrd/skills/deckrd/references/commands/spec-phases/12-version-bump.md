---
title: "spec Phase 12: Version Bump"
description: Restore each file's baseline history and bump its version after user approval
---

<!-- textlint-disable
    ja-technical-writing/no-exclamation-question-mark,
    ja-technical-writing/sentence-length,
    ja-technical-writing/max-comma -->
<!-- markdownlint-disable line-length -->

## Phase 12: Version Bump

## Standalone Invocation

```bash
/deckrd spec --phase version-bump
```

## Preconditions

| 必要な入力                             | 生成元   | 欠けているとき                                       |
| -------------------------------------- | -------- | ---------------------------------------------------- |
| Phase 11 のユーザー承認                | Phase 11 | Phase 11 を先に実行する                              |
| BASELINE VERSION / BASELINE HISTORY    | Phase 8  | Context Ledger から読む。無ければ Phase 8 を実行する |
| REQ VERSION                            | Phase 1  | Context Ledger から読む。無ければ Phase 1 を実行する |
| DICTIONARY TERMS / DICTIONARY BASELINE | Phase 9  | Context Ledger から読む。無ければ Phase 9 を実行する |

## Steps

Regeneration during the Phase 11 review loop does not bump.
Restore and bump after the user approves.

Bump the dictionary first, then the specification files. The specifications
cite the dictionary's version, so that version must be final before they are bumped.

### Step 12-1: Universal Dictionary

When Phase 9 created or updated `universal-dictionary.md`:

- No **DICTIONARY BASELINE** (first creation) — keep `1.0.0` and the initial row
- Otherwise write **DICTIONARY BASELINE**'s Change History back, then bump from its
  baseline version with the dictionary table below and add exactly one row

| Change                                           | Bump  |
| ------------------------------------------------ | ----- |
| Meaning of a definition changed, term deprecated | MAJOR |
| Term added, structural change (item added, etc.) | MINOR |
| Clarification, relation / evidence added, typo   | PATCH |

The dictionary's Change History row MUST name the documents whose impact was
checked (from DICTIONARY TERMS) and the result. Skipped in Phase 9 → leave the
dictionary untouched.

### Step 12-2: Specification Files

On approval, run the steps below for **every file** written in Phase 10 — each
split file and `specifications-index.md`, not only an unsuffixed
`specifications.md`. Each file is versioned independently.

**No baseline** (first generation) — keep `1.0.0` and the initial row.

**Baseline captured in Step 8-4**:

1. Write that file's **BASELINE HISTORY** back over its generated Change History table
2. Classify this run's change to that file with the table below
3. Bump from that file's **BASELINE VERSION** — never from the reset `1.0.0`
4. Write the result to frontmatter `version` and add exactly one Change History row

| Change                           | Bump  |
| -------------------------------- | ----- |
| Behavior removed or redefined    | MAJOR |
| Spec rule / DD / edge case added | MINOR |
| Clarification, rationale, typo   | PATCH |

Does `based-on` cite an older version than **REQ VERSION**?
Then update it and treat the refresh as at least PATCH.

Does `dictionary` cite an older version than the dictionary's final version
from Step 12-1? Phase 10 wrote the pre-bump version, so this happens whenever
Step 12-1 bumped the dictionary. Update it to
`universal-dictionary.md v<final version>` and treat the refresh as at least PATCH.
Files without a `dictionary` line need no change.

A split file left unbumped gives downstream documents no way to identify its
revision. Skipping any file is a defect.

See docs/.deckrd/rules/deckrd-rule-document-versioning.md.

## Output

Every specification file carries a bumped `version` and one new Change History row.
Every `dictionary` reference cites the dictionary's final version.

## Next Phase

[Phase 13: Second Opinion via Codex](13-second-opinion.md)

Phase 13 を省略するときは、ここで `spec.md` の Session Update に戻る。
