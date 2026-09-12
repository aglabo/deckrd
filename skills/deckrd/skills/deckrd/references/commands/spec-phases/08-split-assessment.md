---
title: "spec Phase 8: Split Assessment"
description: Estimate specification volume, decide the output file plan, and capture version baselines
---

<!-- textlint-disable
    ja-technical-writing/no-exclamation-question-mark,
    ja-technical-writing/sentence-length,
    ja-technical-writing/max-comma -->
<!-- markdownlint-disable line-length -->

## Phase 8: Split Assessment

## Standalone Invocation

```bash
/deckrd spec --phase split-assessment
```

## Preconditions

| 必要な入力                     | 生成元 | 欠けているとき       |
| ------------------------------ | ------ | -------------------- |
| `requirements/requirements.md` | `req`  | `req` を先に実行する |

## Steps

Estimate the volume of specifications before generating.

### Step 8-1: Count Specification Units

From `requirements.md` count:

| Item                                  | Count |
| ------------------------------------- | ----- |
| Functional Requirements (FR-xx)       | N     |
| External API endpoints / integrations | N     |
| Distinct user-facing behaviors        | N     |
| Edge case groups                      | N     |

### Step 8-2: Apply Split Threshold

| Total FR count | Action                                  |
| -------------- | --------------------------------------- |
| ≤ 7            | Single file: `specifications.md`        |
| 8–14           | Consider split; ask user for preference |
| ≥ 15           | Split required                          |

**When asking the user (8–14 range)**:

```bash
[Split Assessment] This spec covers 10 FRs across 3 feature areas.
Recommended split:
  A) Single file  specifications.md  (all 10 FRs)
  B) Split by area:
       specifications-auth.md      (FR-01–04)
       specifications-notify.md    (FR-05–08)
       specifications-admin.md     (FR-09–10)
Which do you prefer? (A/B/custom)
```

### Step 8-3: Determine Output Files

Record the final file plan as **SPLIT PLAN**:

```text
SPLIT PLAN:
- specifications-auth.md      covers FR-01, FR-02, FR-03, FR-04
- specifications-notify.md    covers FR-05, FR-06, FR-07, FR-08
- specifications-admin.md     covers FR-09, FR-10
```

### Step 8-4: Capture Version Baselines

`generate-doc.sh` overwrites each output file. The generated document therefore
always carries the template value `version: 1.0.0` and an empty Change History.

For **each file** in SPLIT PLAN that already exists on disk — including
`specifications-index.md`, which is generated from the same versioned template:

- Copy its frontmatter `version` and its entire `## Change History` table
- Store them per file as **BASELINE VERSION** and **BASELINE HISTORY**

Files absent from disk are first generations and have no baseline.

## Output

Append **SPLIT PLAN**, **BASELINE VERSION**, and **BASELINE HISTORY** to the Context Ledger.

## Next Phase

[Phase 9: Document Generation](09-generate.md)
