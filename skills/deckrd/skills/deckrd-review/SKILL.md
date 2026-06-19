---
name: deckrd-review
description: >
  Get an independent second opinion from codex on any document or deckrd phase.
  Codex acts as a critical reviewer — challenging assumptions and surfacing blind spots
  from a different angle than Claude's primary analysis.
  Use after /deckrd review, before phase transitions, or when a design decision is unclear.
metadata:
  author: aglabo
  version: 0.4.0
  license: MIT
allowed-tools:
  - mcp__codex-mcp__codex
  - mcp__codex-mcp__codex-reply
  - Read
  - Bash(jq:*)
argument-hint: "<file_or_phase> [--focus completeness|risk|consistency|feasibility]"
---

# /deckrd:deckrd-review — Second Opinion via Codex

## Overview

Invoke codex as an **independent critical reviewer** on any document.

Codex challenges assumptions and surfaces blind spots that the primary analysis may miss.
The final judgment always stays with the user (accept / reject / follow-up).

## Usage

```bash
/deckrd:deckrd-review <target> [--focus <area>]
```

### Arguments

| Argument   | Required | Description                                                            |
| ---------- | -------- | ---------------------------------------------------------------------- |
| `<target>` | Yes      | File path (`@path/to/file.md`) or deckrd phase (`req/spec/impl/tasks`) |
| `--focus`  | No       | `completeness` / `risk` / `consistency` / `feasibility` (default: all) |

### Focus Areas

| Focus          | Codex Persona          | Key Questions                                       |
| -------------- | ---------------------- | --------------------------------------------------- |
| `completeness` | Coverage Auditor       | Missing scenarios? Uncovered edge cases?            |
| `risk`         | Devil's Advocate       | Dangerous assumptions? Failure modes?               |
| `consistency`  | Consistency Checker    | Terminology drift? Contradictions between sections? |
| `feasibility`  | Implementation Realist | Ambiguous requirements? Conflicting constraints?    |
| (none)         | Critical Reviewer      | All of the above, balanced                          |

---

## Execution Steps

### Step 1: Resolve target document

**If `<target>` is a deckrd phase** (`req` / `spec` / `impl` / `tasks`):

1. Read `.local/deckrd/session.json`
2. Resolve `session.active` to get active module path
3. Map phase to file:

   | Phase | File                             |
   | ----- | -------------------------------- |
   | req   | requirements/requirements.md     |
   | spec  | specifications/specifications.md |
   | impl  | implementation/implementation.md |
   | tasks | tasks/tasks.md                   |

4. Full path: `docs/.deckrd/<active>/<file>`

**If `<target>` starts with `@`**: use the path directly (strip `@` prefix).

**If the file does not exist**: report error and stop.

### Step 2: Read the document

Read the resolved file content in full.

### Step 3: Build codex prompt

Select prompt template based on `--focus`:

**no focus (balanced):**

```
You are an independent critical reviewer. Analyze this document and provide a concise
second opinion that challenges assumptions and surfaces blind spots.

Be direct. Identify:
1. Top 3 risks or concerns not addressed
2. Missing scenarios or edge cases
3. Assumptions that should be made explicit
4. One alternative approach worth considering

Respond in the same language as the document.
Document type: <target>
---
<document content>
```

**completeness:**

```
You are a Coverage Auditor. Review this document for missing scenarios.

Identify:
1. User scenarios not covered
2. Error and edge cases absent from the document
3. Boundary conditions not specified
4. Unhappy paths not addressed

Respond in the same language as the document.
Document type: <target>
---
<document content>
```

**risk:**

```
You are a Devil's Advocate. Challenge every major assumption and identify failure modes.

Identify:
1. The 3 most dangerous assumptions in this document
2. What could cause this design to fail
3. External dependencies that are underspecified

Respond in the same language as the document.
Document type: <target>
---
<document content>
```

**consistency:**

```
You are a Consistency Checker. Review for internal contradictions and terminology drift.

Identify:
1. Terms used with inconsistent meaning across sections
2. Requirements or statements that contradict each other
3. Sections that make incompatible assumptions

Respond in the same language as the document.
Document type: <target>
---
<document content>
```

**feasibility:**

```
You are an Implementation Realist. Review for feasibility issues.

Identify:
1. Requirements that are ambiguous or unimplementable as written
2. Constraints that conflict with each other
3. Missing technical prerequisites

Respond in the same language as the document.
Document type: <target>
---
<document content>
```

### Step 4: Call codex and display result

Call `mcp__codex-mcp__codex` with the constructed prompt.
Display codex's findings clearly, preceded by:

```
── Codex Second Opinion ──────────────────────────
Focus: <focus or "balanced">   Target: <resolved file>
──────────────────────────────────────────────────
```

### Step 5: Interactive loop

After displaying findings, show the choice prompt and wait for user input:

```
What would you like to do?
  a  Accept   — note findings to act on
  r  Reject   — dismiss (reason required)
  q  Ask      — follow-up question to codex
  d  Done     — exit

Choice (a/r/q/d):
```

#### a — Accept

Ask: `Which findings will you act on? (brief description):`
Output summary to user. Done.

#### r — Reject

Ask: `Reason for dismissal:`
Acknowledge the dismissal with the reason. Done.

#### q — Ask follow-up

Ask: `Your follow-up question for codex:`
Call `mcp__codex-mcp__codex-reply` with the follow-up question and prior conversation context.
Display codex's answer.
Return to the choice prompt.

#### d — Done

Exit silently.

---

## Examples

```bash
# Second opinion on current requirements (deckrd active module)
/deckrd:deckrd-review req

# Risk-focused review of specifications
/deckrd:deckrd-review spec --focus risk

# Completeness check on any file
/deckrd:deckrd-review @docs/design/architecture.md --focus completeness

# Consistency check on tasks
/deckrd:deckrd-review tasks --focus consistency
```

## When to Use

| Trigger                                       | Recommended focus |
| --------------------------------------------- | ----------------- |
| After `/deckrd review req` or `spec`          | `risk`            |
| Before transitioning to the next deckrd phase | (none — balanced) |
| Unclear design decision                       | `consistency`     |
| Implementation feels underspecified           | `feasibility`     |
| Edge cases feel missing                       | `completeness`    |
| An approach has failed twice                  | `feasibility`     |
