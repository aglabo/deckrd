---
title: "spec Phase 9: Document Generation"
description: Generate each specification file from the accumulated phase context
---

<!-- textlint-disable
    ja-technical-writing/no-exclamation-question-mark,
    ja-technical-writing/sentence-length,
    ja-technical-writing/max-comma -->
<!-- markdownlint-disable line-length -->

## Phase 9: Document Generation

## Standalone Invocation

```bash
/deckrd spec --phase generate
```

## Preconditions

| 必要な入力       | 生成元    | 欠けているとき                                          |
| ---------------- | --------- | ------------------------------------------------------- |
| 下表の全ブロック | Phase 1-8 | Context Ledger から読む。無ければ該当フェーズを実行する |

## Steps

Build the combined prompt context from all prior phases:

```text
REQ SUMMARY:          <Phase 1>
REQ VERSION:          <Phase 1>
CODEBASE CONTEXT:     <Phase 1>
PRIOR ART:            <Phase 2>
CONFIRMED DESIGN:     <Phase 4>
EXTERNAL DESIGN NOTES:<Phase 5>
API DECISIONS:        <Phase 6>
FUNCTION DECISIONS:   <Phase 7>
SPLIT PLAN:           <Phase 8>
REQUIREMENTS:         @requirements/requirements.md
```

In the generated file, `based-on` MUST read `requirements.md v<REQ VERSION>` —
replace the `{{REQ_VERSION}}` placeholder. Never leave it literal.

For **each file** in SPLIT PLAN, execute:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/generate-doc.sh @specifications \
  @requirements/requirements.md \
  [--lang <lang>] \
  --output "specifications/<filename>"
```

Pass all accumulated context so the AI can produce a well-grounded specification.
This ensures the output reflects the actual codebase and confirmed design decisions.

## Output

Specification files written under `specifications/` per SPLIT PLAN.

## Next Phase

[Phase 10: External Spec Review & Cleanup](10-spec-review.md)
