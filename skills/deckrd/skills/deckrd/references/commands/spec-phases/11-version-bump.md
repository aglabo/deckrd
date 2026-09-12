---
title: "spec Phase 11: Version Bump"
description: Restore each file's baseline history and bump its version after user approval
---

<!-- textlint-disable
    ja-technical-writing/no-exclamation-question-mark,
    ja-technical-writing/sentence-length,
    ja-technical-writing/max-comma -->
<!-- markdownlint-disable line-length -->

## Phase 11: Version Bump

## Standalone Invocation

```bash
/deckrd spec --phase version-bump
```

## Preconditions

| 必要な入力                          | 生成元   | 欠けているとき                                       |
| ----------------------------------- | -------- | ---------------------------------------------------- |
| Phase 10 のユーザー承認             | Phase 10 | Phase 10 を先に実行する                              |
| BASELINE VERSION / BASELINE HISTORY | Phase 8  | Context Ledger から読む。無ければ Phase 8 を実行する |
| REQ VERSION                         | Phase 1  | Context Ledger から読む。無ければ Phase 1 を実行する |

## Steps

Regeneration during the Phase 10 review loop does not bump.
Restore and bump after the user approves.

On approval, run the steps below for **every file** written in Phase 9 — each
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

A split file left unbumped gives downstream documents no way to identify its
revision. Skipping any file is a defect.

See docs/.deckrd/rules/deckrd-rule-document-versioning.md.

## Output

Every specification file carries a bumped `version` and one new Change History row.

## Next Phase

[Phase 12: Second Opinion via Codex](12-second-opinion.md)
