---
title: "spec Phase 1: Requirements Reading & Codebase Investigation"
description: Read the requirements document and survey the codebase before drafting a design
---

<!-- textlint-disable
    ja-technical-writing/no-exclamation-question-mark,
    ja-technical-writing/sentence-length,
    ja-technical-writing/max-comma -->
<!-- markdownlint-disable line-length -->

## Phase 1: Requirements Reading & Codebase Investigation

## Standalone Invocation

```bash
/deckrd spec --phase read-requirements
```

## Preconditions

| 必要な入力                     | 生成元 | 欠けているとき       |
| ------------------------------ | ------ | -------------------- |
| `requirements/requirements.md` | `req`  | `req` を先に実行する |

## Steps

### Step 1-1: Read Requirements

Read `requirements/requirements.md` in full and extract:

- Feature overview and goals
- All Functional Requirements (FR-xx) and their intent
- Non-Functional Requirements and constraints
- Stakeholders and usage scenarios
- Open Questions inherited from the req phase
- Frontmatter `version` (three-part; required)

Store extracted summary as **REQ SUMMARY** and the version as **REQ VERSION**.

### Step 1-2: Investigate Codebase (explore-agent 委譲)

Spawn **explore-agent** (non-blocking) with:

- `scope`: `codebase-survey`
- `directory`: project root
- `focus`: feature keywords from REQ SUMMARY
- Agent definition: [`plugins/deckrd/agents/explore-agent.md`](../../../../../agents/explore-agent.md)

The agent writes findings to `temp/deckrd-work/codebase-context.md`.
Proceed to Phase 2 immediately in parallel — do NOT wait for this agent.

Store the agent Summary as **CODEBASE CONTEXT** when it completes:

```text
CODEBASE CONTEXT:
- Relevant modules: ...
- Existing patterns: ...
- Integration points: ...
- Partially implemented: ...
```

## Output

Append **REQ SUMMARY**, **REQ VERSION**, and **CODEBASE CONTEXT** to the Context Ledger.

## Next Phase

[Phase 2: PoC / Reference PR Check](02-prior-art.md)
