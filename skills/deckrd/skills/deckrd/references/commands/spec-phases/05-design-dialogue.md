---
title: "spec Phase 5: External Design Dialogue"
description: Formalize the external specification through a structured internal design dialogue
---

<!-- textlint-disable
    ja-technical-writing/no-exclamation-question-mark,
    ja-technical-writing/sentence-length,
    ja-technical-writing/max-comma -->
<!-- markdownlint-disable line-length -->

## Phase 5: External Design Dialogue

## Standalone Invocation

```bash
/deckrd spec --phase design-dialogue
```

## Preconditions

| 必要な入力       | 生成元  | 欠けているとき                                       |
| ---------------- | ------- | ---------------------------------------------------- |
| CONFIRMED DESIGN | Phase 4 | Context Ledger から読む。無ければ Phase 4 を実行する |

## Steps

Conduct an internal design reasoning session to formalize the external specification.
This phase is a structured self-dialogue: reason through each question explicitly.

### Step 5-1: Component Boundary Analysis

For each behavioral unit in CONFIRMED DESIGN, reason through:

- What is the single responsibility of this unit?
- What must it receive as input (type, format, constraints)?
- What must it produce as output (type, format, success/failure semantics)?
- What observable side effects does it have?

### Step 5-2: Interface Contract Definition

For each unit, define the external contract:

```bash
Unit: <name>
  Pre-conditions:  <what must be true before invocation>
  Post-conditions: <what is guaranteed after successful invocation>
  Invariants:      <what never changes>
  Error cases:     <what triggers failure and what is returned/thrown>
```

### Step 5-3: Cross-Unit Interaction Analysis

Identify how the units interact:

- Data flow between units (output of A → input of B)
- Ordering constraints (B must run after A)
- Shared state or resources
- Failure propagation (if A fails, what happens to B?)

Express cross-unit interactions as an ASCII component diagram:

```text
+----------+     +----------+     +----------+
|  Unit A  | --> |  Unit B  | --> |  Unit C  |
+----------+     +----------+     +----------+
                      |
                      v
                 +----------+
                 |  Unit D  |
                 +----------+
```

- Use `+--+` for box corners, `|` for vertical sides, `-` for horizontal sides
- Use `-->` for directed data flow
- Branch vertically with `|` pipe and `v` arrow
- ASCII diagrams ONLY — Mermaid, PlantUML, and SVG are PROHIBITED

### Step 5-4: Edge Case Enumeration

For each unit, enumerate edge cases:

- Boundary values (empty input, maximum size, null)
- Concurrent access (if applicable)
- Partial failure scenarios
- State inconsistency scenarios

### Step 5-5: External Design Summary

Compile the dialogue results into **EXTERNAL DESIGN NOTES**:

```text
EXTERNAL DESIGN NOTES:
- Unit contracts: [structured list from Step 5-2]
- Interaction map: [data flow and ordering from Step 5-3]
- Edge cases: [enumerated list from Step 5-4]
- Unresolved: [items that could not be determined without user input]
```

## Output

Append **EXTERNAL DESIGN NOTES** to the Context Ledger.

## Next Phase

[Phase 6: External API Decision Loop](06-api-decisions.md)
