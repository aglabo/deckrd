---
title: "spec Phase 4: User Review & Feedback Loop"
description: Present the design draft to the user and iterate until it is confirmed
---

<!-- textlint-disable
    ja-technical-writing/no-exclamation-question-mark,
    ja-technical-writing/sentence-length,
    ja-technical-writing/max-comma -->
<!-- markdownlint-disable line-length -->

## Phase 4: User Review & Feedback Loop (max 3 rounds)

## Standalone Invocation

```bash
/deckrd spec --phase user-review
```

## Preconditions

| 必要な入力   | 生成元  | 欠けているとき                                       |
| ------------ | ------- | ---------------------------------------------------- |
| DESIGN DRAFT | Phase 3 | Context Ledger から読む。無ければ Phase 3 を実行する |

## Steps

Present the DESIGN DRAFT to the user and collect feedback.

### Step 4-1: Present Summary

Show a structured summary:

```bash
[Design Review]

Feature decomposition:
  1. <unit-1>: <one-line description>
  2. <unit-2>: <one-line description>

Architecture fit:
  <brief description>

Risks / open questions:
  - <risk-1>
  - <risk-2>

Does this direction look correct? (Y / feedback)
```

### Step 4-2: Collect Feedback

If the user provides feedback:

- Identify which part of DESIGN DRAFT needs revision
- Ask EXACTLY 1 clarifying question per round. No exceptions.
- Update DESIGN DRAFT with confirmed changes
- Return to Step 4-1

**Termination conditions** (stop as soon as either is met):

1. User approves with "Y", "OK", "承認", "done", or equivalent
2. 3 rounds completed — record remaining disagreements in Open Questions

Store final user-confirmed state as **CONFIRMED DESIGN**.

## Output

Append **CONFIRMED DESIGN** to the Context Ledger.

## Next Phase

[Phase 5: External Design Dialogue](05-design-dialogue.md)
