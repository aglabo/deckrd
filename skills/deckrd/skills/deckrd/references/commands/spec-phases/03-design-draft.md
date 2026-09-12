---
title: "spec Phase 3: Design Direction Drafting"
description: Draft a design direction from requirements, codebase context, and prior art
---

<!-- textlint-disable
    ja-technical-writing/no-exclamation-question-mark,
    ja-technical-writing/sentence-length,
    ja-technical-writing/max-comma -->
<!-- markdownlint-disable line-length -->

## Phase 3: Design Direction Drafting

## Standalone Invocation

```bash
/deckrd spec --phase design-draft
```

## Preconditions

| 必要な入力       | 生成元  | 欠けているとき                                       |
| ---------------- | ------- | ---------------------------------------------------- |
| REQ SUMMARY      | Phase 1 | Context Ledger から読む。無ければ Phase 1 を実行する |
| CODEBASE CONTEXT | Phase 1 | Context Ledger から読む。無ければ Phase 1 を実行する |
| PRIOR ART        | Phase 2 | Context Ledger から読む。無ければ Phase 2 を実行する |

`temp/deckrd-work/codebase-context.md` と `prior-art.md` は全モジュール共有のため読まない。
アクティブモジュールを切り替えた後は、前モジュールの調査結果が残っている。

## Steps

Using REQ SUMMARY + CODEBASE CONTEXT + PRIOR ART, draft a design direction:

1. Feature decomposition — break the requirements into distinct behavioral units
2. Architecture fit — how the feature maps onto the existing structure
3. Interface design — what inputs, outputs, and side effects each unit has
4. Constraint mapping — which NFRs / DRs constrain the design
5. Risk / ambiguity list — unclear points that need user input
6. ASCII diagram — draw an initial component diagram showing unit relationships:

   ```text
   +----------+     +----------+
   |  Unit A  | --> |  Unit B  |
   +----------+     +----------+
         |
         v
   +----------+
   |  Unit C  |
   +----------+
   ```

   ASCII diagrams ONLY — Mermaid, PlantUML, and SVG are PROHIBITED.

Store as **DESIGN DRAFT**:

```text
DESIGN DRAFT:
- Behavioral units: [unit-1, unit-2, ...]
- Architecture fit: ...
- Interface sketch: ...
- Constraints: ...
- Risks / ambiguities: [list]
```

## Output

Append **DESIGN DRAFT** to the Context Ledger.

## Next Phase

[Phase 4: User Review & Feedback Loop](04-user-review.md)
