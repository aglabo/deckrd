---
title: "spec Phase 10: Document Generation"
description: Generate each specification file from the accumulated phase context
---

<!-- textlint-disable
    ja-technical-writing/no-exclamation-question-mark,
    ja-technical-writing/sentence-length,
    ja-technical-writing/max-comma -->
<!-- markdownlint-disable line-length -->

## Phase 10: Document Generation

## Standalone Invocation

```bash
/deckrd spec --phase generate
```

## Preconditions

| 必要な入力       | 生成元    | 欠けているとき                                          |
| ---------------- | --------- | ------------------------------------------------------- |
| 下表の全ブロック | Phase 1-9 | Context Ledger から読む。無ければ該当フェーズを実行する |

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
DICTIONARY TERMS:     <Phase 9>
UNIVERSAL DICTIONARY: @universal-dictionary.md
REQUIREMENTS:         @requirements/requirements.md
```

Omit `UNIVERSAL DICTIONARY` only when `universal-dictionary.md` does not exist
(Phase 9 was skipped and no dictionary was created before). When it exists, the
generated file MUST cite terms by UD-ID, fill `1.3 Terminology`, and set the
frontmatter `dictionary` to `universal-dictionary.md v<dictionary version>`.
Without a dictionary, delete the `dictionary` line and section 1.3.

In the generated file, `based-on` MUST read `requirements.md v<REQ VERSION>` —
replace the `{{REQ_VERSION}}` placeholder. Never leave it literal.

For **each file** in SPLIT PLAN, execute:

```bash
bash "<DECKRD_SKILL_DIR>/scripts/subcommands/generate-doc.sh" @specifications \
  @requirements/requirements.md \
  [--lang <lang>] \
  --output "specifications/<filename>"
```

Pass all accumulated context so the AI can produce a well-grounded specification.
This ensures the output reflects the actual codebase and confirmed design decisions.

## Output

Specification files written under `specifications/` per SPLIT PLAN.

## Next Phase

[Phase 11: External Spec Review & Cleanup](11-spec-review.md)
