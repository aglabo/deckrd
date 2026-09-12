---
title: "spec Phase 2: PoC / Reference PR Check"
description: Survey prior art — proof-of-concept code, related branches, and earlier decisions
---

<!-- textlint-disable
    ja-technical-writing/no-exclamation-question-mark,
    ja-technical-writing/sentence-length,
    ja-technical-writing/max-comma -->
<!-- markdownlint-disable line-length -->

## Phase 2: PoC / Reference PR Check (explore-agent 委譲)

## Standalone Invocation

```bash
/deckrd spec --phase prior-art
```

## Preconditions

| 必要な入力  | 生成元  | 欠けているとき                                       |
| ----------- | ------- | ---------------------------------------------------- |
| REQ SUMMARY | Phase 1 | Context Ledger から読む。無ければ Phase 1 を実行する |

## Steps

Spawn **explore-agent** (non-blocking, parallel with Step 1-2) with:

- `scope`: `prior-art`
- `directory`: project root
- `focus`: feature keywords from REQ SUMMARY
- Agent definition: [`plugins/deckrd/agents/explore-agent.md`](../../../../../agents/explore-agent.md)

The agent writes findings to `temp/deckrd-work/prior-art.md`.

Store the agent Summary as **PRIOR ART** when it completes:

```text
PRIOR ART:
- PoC found: <path or "none">
- Related branches: <list or "none">
- Key decisions from prior work: ...
```

If nothing is found, record `PRIOR ART: none` and continue.

> **Note**: Proceed to Phase 3 only after **both** the Step 1-2 agent and this agent have completed.

## Output

Append **PRIOR ART** to the Context Ledger.

## Next Phase

[Phase 3: Design Direction Drafting](03-design-draft.md)
