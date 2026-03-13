---
title: spec Command
description: Derive technically verifiable behavioral specifications from requirements
---

## spec Command

<!-- textlint-disable
    ja-technical-writing/no-exclamation-question-mark,
    ja-technical-writing/max-comma -->
<!-- markdownlint-disable line-length -->

Derive technically verifiable behavioral goals and constraints from requirements.

## Usage

```bash
/deckrd spec
```

## Preconditions

- Session must exist with active module
- `req` must be completed for active module
- `requirements/requirements.md` must exist

## Execution Flow

```bash
Phase A: Requirements Reading & Codebase Investigation
Phase B: PoC / Reference PR Check
Phase C: Design Direction Drafting
Phase D: User Review & Feedback Loop        ← interactive with user
Phase E: External Design Dialogue           ← AI internal reasoning dialogue
Phase 0: External API Decision Loop         ← interactive with user
Phase 0-F: Public Function Interface Loop   ← interactive with user
Phase 1: Split Assessment                   ← interactive with user (if needed)
Phase 2: Document Generation
Phase 3: External Spec Review & Cleanup     ← interactive with user
```

---

### Phase A: Requirements Reading & Codebase Investigation

#### Step A-1: Read Requirements

Read `requirements/requirements.md` in full and extract:

- Feature overview and goals
- All Functional Requirements (FR-xx) and their intent
- Non-Functional Requirements and constraints
- Stakeholders and usage scenarios
- Open Questions inherited from the req phase

Store extracted summary as **REQ SUMMARY**.

#### Step A-2: Investigate Codebase (explore-agent 委譲)

Spawn **explore-agent** (non-blocking) with:

- `scope`: `codebase-survey`
- `directory`: project root
- `focus`: feature keywords from REQ SUMMARY
- Agent definition: [`plugins/deckrd/agents/explore-agent.md`](../../../../agents/explore-agent.md)

The agent writes findings to `temp/deckrd-work/codebase-context.md`.
Proceed to Phase B immediately in parallel — do NOT wait for this agent.

Store the agent Summary as **CODEBASE CONTEXT** when it completes:

```text
CODEBASE CONTEXT:
- Relevant modules: ...
- Existing patterns: ...
- Integration points: ...
- Partially implemented: ...
```

---

### Phase B: PoC / Reference PR Check (explore-agent 委譲)

Spawn **explore-agent** (non-blocking, parallel with A-2) with:

- `scope`: `prior-art`
- `directory`: project root
- `focus`: feature keywords from REQ SUMMARY
- Agent definition: [`plugins/deckrd/agents/explore-agent.md`](../../../../agents/explore-agent.md)

The agent writes findings to `temp/deckrd-work/prior-art.md`.

Store the agent Summary as **PRIOR ART** when it completes:

```text
PRIOR ART:
- PoC found: <path or "none">
- Related branches: <list or "none">
- Key decisions from prior work: ...
```

If nothing is found, record `PRIOR ART: none` and continue.

> **Note**: Proceed to Phase C only after **both** A-2 and B agents have completed.

---

### Phase C: Design Direction Drafting

Using REQ SUMMARY + CODEBASE CONTEXT + PRIOR ART, draft a design direction:

1. **Feature decomposition** — break the requirements into distinct behavioral units
2. **Architecture fit** — how the feature maps onto the existing structure
3. **Interface design** — what inputs, outputs, and side effects each unit has
4. **Constraint mapping** — which NFRs / DRs constrain the design
5. **Risk / ambiguity list** — unclear points that need user input
6. **ASCII diagram** — draw an initial component diagram showing unit relationships:

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

---

### Phase D: User Review & Feedback Loop (max 3 rounds)

Present the DESIGN DRAFT to the user and collect feedback.

#### Step D-1: Present Summary

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

#### Step D-2: Collect Feedback

If the user provides feedback:

- Identify which part of DESIGN DRAFT needs revision
- Ask EXACTLY 1 clarifying question per round. No exceptions.
- Update DESIGN DRAFT with confirmed changes
- Return to Step D-1

**Termination conditions** (stop as soon as either is met):

1. User approves with "Y", "OK", "承認", "done", or equivalent
2. 3 rounds completed — record remaining disagreements in Open Questions

Store final user-confirmed state as **CONFIRMED DESIGN**.

---

### Phase E: External Design Dialogue

Conduct an internal design reasoning session to formalize the external specification.
This phase is a structured self-dialogue: reason through each question explicitly.

#### E-1: Component Boundary Analysis

For each behavioral unit in CONFIRMED DESIGN, reason through:

- What is the single responsibility of this unit?
- What must it receive as input (type, format, constraints)?
- What must it produce as output (type, format, success/failure semantics)?
- What observable side effects does it have?

#### E-2: Interface Contract Definition

For each unit, define the external contract:

```bash
Unit: <name>
  Pre-conditions:  <what must be true before invocation>
  Post-conditions: <what is guaranteed after successful invocation>
  Invariants:      <what never changes>
  Error cases:     <what triggers failure and what is returned/thrown>
```

#### E-3: Cross-Unit Interaction Analysis

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

#### E-4: Edge Case Enumeration

For each unit, enumerate edge cases:

- Boundary values (empty input, maximum size, null)
- Concurrent access (if applicable)
- Partial failure scenarios
- State inconsistency scenarios

#### E-5: External Design Summary

Compile the dialogue results into **EXTERNAL DESIGN NOTES**:

```text
EXTERNAL DESIGN NOTES:
- Unit contracts: [structured list from E-2]
- Interaction map: [data flow and ordering from E-3]
- Edge cases: [enumerated list from E-4]
- Unresolved: [items that could not be determined without user input]
```

---

### Phase 0: External API Decision Loop (max 3 rounds)

Before generating specifications, identify and confirm all external interfaces.

#### Step 0-1: Extract API Candidates

Read `requirements/requirements.md` and identify candidates:

- External services called (REST API, GraphQL, gRPC, message queue, etc.)
- External services that call this module (webhooks, callbacks)
- Shared data stores accessed by multiple modules (DB, cache, file storage)
- CLI / SDK interfaces exposed to end users or other tools

#### Step 0-2: Ask API Clarification Questions

For each candidate, ask the user to confirm or decide:

**Rules**:

- Ask **at most 3 questions per round**
- Prefer concrete choices (A/B/C) or Yes/No over open-ended questions
- Accumulate confirmed decisions as **API DECISIONS**

Example question patterns:

```bash
[External API] The requirements mention sending email notifications.
Q1. Which service will you use?
    A) SendGrid  B) AWS SES  C) SMTP (self-hosted)  D) Not decided yet

Q2. Is the API key management in scope for this spec?
    Yes / No

Q3. Should failure to send email be fatal (block the operation) or non-fatal?
    A) Fatal  B) Non-fatal (log and continue)
```

**Termination conditions** (stop as soon as either is met):

1. User responds with "十分", "以上です", "OK", "done", or equivalent
2. All extracted API candidates have a confirmed decision (service, protocol, error handling policy)

#### Step 0-3: Summarize API Decisions

Compile confirmed decisions as **API DECISIONS** block:

```text
API DECISIONS:
- Email notification: SendGrid REST API; non-fatal on failure
- User data store: PostgreSQL via existing DB module; read-only from this spec
- CLI interface: exposed as subcommand `deckrd spec`; no SDK
```

---

### Phase 0-F: Public Function Interface Decision Loop (max 3 rounds)

Before generating specifications, identify and confirm the public functions.
this module exposes as its external API.

#### Step 0-F-1: Extract Public Function Candidates

Based on CONFIRMED DESIGN and Phase E (Component Boundary Analysis), identify:

- Entry points called by other modules or users
- Command/subcommand handlers exposed as CLI
- Callback or event handler signatures required by callers
- Functions that form the module's contract boundary

#### Step 0-F-2: Ask Function Interface Questions

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

#### Step 0-F-3: Summarize Function Decisions

Compile confirmed decisions as **FUNCTION DECISIONS** block:

```text
FUNCTION DECISIONS:
- process_requirements(input_path, options): entry point for processing; returns Result
- validate_input(content): validates raw input; returns ValidationResult or error
- format_output(result, lang): formats result for display; non-fatal on unsupported lang
```

---

### Phase 1: Split Assessment

Estimate the volume of specifications before generating.

#### Step 1-1: Count Specification Units

From `requirements.md` count:

| Item                                  | Count |
| ------------------------------------- | ----- |
| Functional Requirements (FR-xx)       | N     |
| External API endpoints / integrations | N     |
| Distinct user-facing behaviors        | N     |
| Edge case groups                      | N     |

#### Step 1-2: Apply Split Threshold

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

#### Step 1-3: Determine Output Files

Record the final file plan as **SPLIT PLAN**:

```text
SPLIT PLAN:
- specifications-auth.md      covers FR-01, FR-02, FR-03, FR-04
- specifications-notify.md    covers FR-05, FR-06, FR-07, FR-08
- specifications-admin.md     covers FR-09, FR-10
```

---

### Phase 2: Document Generation

Build the combined prompt context from all prior phases:

```text
REQ SUMMARY:          <Phase A>
CODEBASE CONTEXT:     <Phase A>
PRIOR ART:            <Phase B>
CONFIRMED DESIGN:     <Phase D>
EXTERNAL DESIGN NOTES:<Phase E>
API DECISIONS:        <Phase 0>
FUNCTION DECISIONS:   <Phase 0-F>
SPLIT PLAN:           <Phase 1>
REQUIREMENTS:         @requirements/requirements.md
```

For **each file** in SPLIT PLAN, execute:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/run-prompt.sh specifications \
  @requirements/requirements.md \
  [--lang <lang>] \
  --output "specifications/<filename>"
```

Pass all accumulated context so the AI can produce a well-grounded specification.
This ensures the output reflects the actual codebase and confirmed design decisions.

---

### Phase 3: External Spec Review & Cleanup (max 2 rounds)

After all specification files are written, review each file.
Ensure each file contains **only external specification content**.

#### Step 3-1: Self-Scan

Read each generated file and flag every passage that matches a removal criterion:

| Criterion                | Examples                                                                   | Action                            |
| ------------------------ | -------------------------------------------------------------------------- | --------------------------------- |
| Implementation detail    | Function names, type signatures, file paths, class names                   | Remove or rewrite                 |
| Requirements restatement | Sentences copied verbatim from `requirements.md`; FR/NFR bullet re-listing | Remove                            |
| Notes / impl hints       | `<!-- impl: ... -->`, `> Note for impl:` comments                          | **Keep** (pass-through to `impl`) |

**Do NOT remove:**

- Behavioral rules expressed in declarative form
- Edge cases and invariants
- Interface contracts (pre/post-conditions without code)
- Cross-unit interaction ordering
- Notes explicitly marked as implementation hints

#### Step 3-2: Present Findings to User

For each flagged passage, present a concise diff-style summary:

```bash
[Spec Review] specifications-auth.md

REMOVE (implementation detail):
  Line 42: "calls authenticate() function and checks return value"
  → Suggest: "performs authentication and evaluates the result"
  Accept? (Y / keep / custom)

REMOVE (requirements restatement):
  Line 67: "FR-03: The system SHALL validate email format"
  → This duplicates requirements.md FR-03. Remove?
  Accept? (Y / keep)
```

If no issues found:

```bash
[Spec Review] No external-spec violations found in <filename>.
```

#### Step 3-3: Apply Changes

For each accepted removal or rewrite:

1. Edit the file in-place
2. If a passage was rewritten, append the original as an impl note:

   ```yaml
   <!-- impl-note: original said "calls authenticate() function" -->
   ```

3. After all files are cleaned, show a final summary:

   ```bash
   [Cleanup Complete]
   - specifications-auth.md: 2 removed, 1 rewritten
   - specifications-notify.md: no changes
   ```

**Termination conditions:**

1. User approves all changes with "Y", "OK", "承認", or equivalent
2. 2 rounds completed — record any remaining disputed items in Section 7 (Open Questions)

---

## Input

Read requirements document from session's active module:

```bash
docs/.deckrd/<namespace>/<module>/requirements/requirements.md
```

The `@` prefix indicates file reference:

```bash
specifications @requirements/requirements.md
```

## Output

**Single file** (≤ 7 FRs):

```bash
docs/.deckrd/<namespace>/<module>/specifications/specifications.md
```

**Split files** (≥ 8 FRs or user choice):

```bash
docs/.deckrd/<namespace>/<module>/specifications/specifications-<area>.md
```

An index file is always created when split:

```bash
docs/.deckrd/<namespace>/<module>/specifications/specifications-index.md
```

## Prompt & Documents

Use prompt and template for writing specifications.md

> Note:
> Specifications define **technical behavioral contracts**.
> They bridge requirements to implementation planning, without prescribing code structure.

```bash
deckrd/assets/
       ├── prompts/specifications.prompt.md
       └── templates/specifications.template.md
```

## Script

Execute: [run-prompt.sh](../../scripts/run-prompt.sh)

```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/run-prompt.sh specifications @requirements/requirements.md [--lang <lang>] --output "specifications/specifications.md"
```

> **Note**:
> The `@` prefix resolves to the active module's document path:
> `docs/.deckrd/<namespace>/<module>/requirements/requirements.md`

## Session Update

After Phase 3 cleanup is approved, update `.session.json`:

```json
{
  "current_step": "spec",
  "completed": ["init", "req", "spec"],
  "documents": {
    "requirements": "requirements.md",
    "specifications": "specifications.md"
  }
}
```

When split, record the index file as the `specifications` entry.
List each split file under `specifications_files`:

```json
{
  "documents": {
    "requirements": "requirements.md",
    "specifications": "specifications-index.md",
    "specifications_files": [
      "specifications-auth.md",
      "specifications-notify.md"
    ]
  }
}
```

## Next Step

Run `impl` to derive implementation plan from specifications.
