---
title: "spec Phase 7: Public Function Interface Decision Loop"
description: Confirm the public functions this module exposes as its external API
---

<!-- textlint-disable
    ja-technical-writing/no-exclamation-question-mark,
    ja-technical-writing/sentence-length,
    ja-technical-writing/max-comma -->
<!-- markdownlint-disable line-length -->

## Phase 7: Public Function Interface Decision Loop (max 3 rounds)

## Standalone Invocation

```bash
/deckrd spec --phase function-decisions
```

## Preconditions

| 必要な入力            | 生成元  | 欠けているとき                                       |
| --------------------- | ------- | ---------------------------------------------------- |
| CONFIRMED DESIGN      | Phase 4 | Context Ledger から読む。無ければ Phase 4 を実行する |
| EXTERNAL DESIGN NOTES | Phase 5 | Context Ledger から読む。無ければ Phase 5 を実行する |

## Steps

Before generating specifications, identify and confirm the public functions.
this module exposes as its external API.

### Step 7-1: Extract Public Function Candidates

Based on CONFIRMED DESIGN and Phase 5 (Component Boundary Analysis), identify:

- Entry points called by other modules or users
- Command/subcommand handlers exposed as CLI
- Callback or event handler signatures required by callers
- Functions that form the module's contract boundary

### Step 7-2: Ask Function Interface Questions

For each candidate, ask the user to confirm or decide:

**Rules**:

- Ask **at most 3 questions per round**
- Prefer concrete naming proposals or Yes/No
- Accumulate confirmed decisions as **FUNCTION DECISIONS**

Example question patterns:

```bash
[Function Interface] The spec identifies one main entry point for processing.
Q1. What should the public function be named?
    A) process_input  B) run  C) execute  D) Let me name it myself

Q2. Should the function accept options as a separate parameter?
    Yes (options object) / No (embed in main parameter)

Q3. What should the function return on success?
    A) Result object  B) Exit code (integer)  C) Boolean
```

**Termination conditions** (stop as soon as either is met):

1. User responds with "十分", "以上です", "OK", "done", or equivalent
2. All identified entry points have confirmed names and signatures

### Step 7-3: Summarize Function Decisions

Compile confirmed decisions as **FUNCTION DECISIONS** block:

```text
FUNCTION DECISIONS:
- process_requirements(input_path, options): entry point for processing; returns Result
- validate_input(content): validates raw input; returns ValidationResult or error
- format_output(result, lang): formats result for display; non-fatal on unsupported lang
```

## Output

Append **FUNCTION DECISIONS** to the Context Ledger.

## Next Phase

[Phase 8: Split Assessment](08-split-assessment.md)
