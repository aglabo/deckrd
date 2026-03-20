---
title: req Command
description: Derive a normative requirements document from goals and constraints
---

<!-- textlint-disable
  ja-technical-writing/sentence-length -->

## req Command

<!-- textlint-disable
    ja-technical-writing/no-exclamation-question-mark,
    ja-technical-writing/max-comma -->
<!-- markdownlint-disable line-length -->

Derive a normative requirements document from the user's goals, ideas, and constraints.

## Usage

```bash
/deckrd req <your requirements or goals by free-form text>
```

## Preconditions

- Session must exist with active module
- `init` must be completed for active module

## Commitment Declaration (REQUIRED)

Before Phase 0, YOU MUST output:

> "I am executing /deckrd req for module [MODULE_NAME].
> I will complete phases in order: 0 -> 1 -> 2 -> 3 -> 4. I will NOT skip phases."

---

## Execution Flow

### Phase 0: Codebase Investigation (explore-agent 委譲)

Before collecting user input, delegate codebase investigation to explore-agent:

<!-- textlint-disable ja-technical-writing/sentence-length -->

1. Read `docs/.deckrd/.session.json` to confirm the active module
2. Check for existing `requirements.md` under the active module path
   - If found: treat this session as a **revision** of existing requirements
3. Spawn **explore-agent** with:
   - `scope`: `codebase-survey`
   - `directory`: project root
   - `focus`: module name and feature keywords from user input (if available)
   - Agent definition: [`plugins/deckrd/agents/explore-agent.md`](../../../../agents/explore-agent.md)
4. The agent writes findings to `temp/deckrd-work/codebase-context.md`
5. Read the **Summary** returned by the agent and store as **CODEBASE CONTEXT** for Phase 3
6. Proceed to Phase 1 immediately — do NOT wait for the agent to complete Phase 0 before starting Phase 1

<!-- textlint-enable ja-technical-writing/sentence-length -->

### Phase 1: Initial Input Collection

Prompt the user:

- What problem are you trying to solve?
- What are your goals?
- Any constraints or preferences?

Accept free-form text. Store as **USER INPUT**.

### Phase 1-D: Generate System Context Diagram

After collecting USER INPUT, generate a system context diagram in ASCII art
to visualize the system boundary and external relationships identified in Phase 1.

```text
[External Actor] --> +------------------+ --> [External System]
                     |   Target System  |
[External Actor] <-- +------------------+ <-- [External System]
```

Rules:

- Use `+--+` for the system boundary box, `|` for vertical sides
- Use `[Name]` for external actors and systems
- Use `-->` for outgoing data/control flow, `<--` for incoming
- ASCII diagrams ONLY — Mermaid, PlantUML, and SVG are PROHIBITED

Present the diagram to the user during Phase 2 for confirmation.
Add "Is the system boundary correct?" as a Hearing Loop question.

Store as **CONTEXT DIAGRAM** for inclusion in requirements.md Section 2.

---

### Phase 2: Hearing Loop (max 5 rounds)

Conduct an interactive Q&A loop to fill information gaps.
**Priority: fill missing EARS elements first**, then fill remaining scope gaps.

**Rules**:

- Ask EXACTLY 1 question per round. No exceptions.
- YOU MUST wait for the user's answer before asking the next question.
- Asking multiple questions simultaneously = violation. Ask 1 question.
- Prefer Yes/No or multiple-choice (A/B/C) questions over open-ended ones
- Accumulate answers as **HEARING NOTES**

**Question priority order** (ask in this order, skip if already known):

1. **EARS/GIVEN** — For each FR candidate, ask: "Under what condition does this apply?"
   Example: "This behavior — is it available to all users, or only authenticated ones?"
2. **EARS/type** — For each FR candidate without a type, ask which fits:
   Example: "Does this trigger on a specific user action (WHEN), or hold continuously
   during a system state (WHILE), or is it something the system must never do (NOT DO)?"
3. **Scope** — In-scope vs out-of-scope boundary
4. **Constraints** — Technical or business constraints
5. **Stakeholders** — Who will use the system

**Termination conditions** (stop as soon as either is met):

1. User responds with "十分", "以上です", "OK", "done", or equivalent
2. All items below are confirmed:
   1. Purpose (what problem to solve)
   2. Scope (in-scope and out-of-scope)
   3. Key functional requirements (at least 3) — each with GIVEN and type confirmed
   4. Constraints (technical or business)
   5. Stakeholders (who will use it)

### Phase 3: Document Generation

Build the combined prompt context:

```text
CODEBASE CONTEXT: <Phase 0 findings>
HEARING NOTES:    <Phase 2 accumulated answers>
USER INPUT:       <Phase 1 initial text>
```

Then execute:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/generate-doc.sh @requirements \
  "<USER_INPUT>" \
  [--lang <lang>] \
  --output "requirements/requirements.md"
```

Pass `CODEBASE CONTEXT` and `HEARING NOTES` as additional context so the AI.
generates richer output including User Stories, Acceptance Criteria, and Open Questions.

### Phase 4: Review Loop (max 3 rounds)

After `requirements.md` is generated, conduct a review loop before finalizing.

#### Step 4-1: Self-Review

Read the generated `requirements.md` and evaluate against the following checklist:

| Check Item                                 | Pass Criteria                                                    |
| ------------------------------------------ | ---------------------------------------------------------------- |
| Purpose is clearly stated                  | One sentence, unambiguous                                        |
| Scope and Out-of-Scope are explicit        | Both present, no overlap                                         |
| Functional Requirements use EARS syntax    | Each REQ-F has GIVEN + (WHEN/WHILE/NOT DO/WHERE) + THEN          |
| EARS type is labeled per REQ-F             | Each REQ-F declares its EARS type (event/state/unwanted/feature) |
| Non-Functional Requirements are measurable | Quantified where possible (e.g., response < 2 s)                 |
| User Stories cover all stakeholders        | 3–7 stories; each maps to at least one FR                        |
| Acceptance Criteria are testable           | 5 Gherkin scenarios; Given/When/Then are concrete                |
| Open Questions are catalogued              | All unresolved items listed with owner and impact                |
| No contradictions between sections         | FR ↔ NFR ↔ User Stories are consistent                           |

#### Step 4-2: Present Review Findings

Present findings to the user in one of two ways:

**If issues found**: List each issue with a suggested fix, asking the user to confirm or override:

```toml
[Review Finding]
- REQ-F-002 missing EARS structure (plain SHALL statement) →
  Suggest EARS rewrite:
    GIVEN <condition>
      WHEN <event>
    THEN the system SHALL process X and return Y within Z ms.
  Accept suggestion? (Y/n/custom)

- REQ-F-003 EARS type not labeled →
  Suggest: add "EARS Type: event-driven" above the code block.
  Accept? (Y/n/custom)

- NFR: no measurable target for performance
  Suggested value: < 2 s for 95th percentile. Accept? (Y/n/custom)
```

**If no issues**: Show a summary and ask for final approval:

```toml
[Review Summary] No critical issues found.
- 5 FRs, 2 NFRs, 4 User Stories, 5 Acceptance Criteria, 2 Open Questions
Approve requirements.md? (Y/revise)
```

#### Step 4-3: Rewrite (if needed)

If the user requests revisions (or accepts any suggestion):

1. Collect all revision instructions as **REVIEW NOTES**
2. Re-execute Phase 3 with `REVIEW NOTES` appended to the prompt context
3. Return to Step 4-1 for the next review round

**Termination conditions** (stop as soon as either is met):

1. User approves with "Y", "承認", "OK", "done", or equivalent
2. 3 review rounds completed — present the document as-is and ask for explicit approval

## Input

User provides goals, ideas, or problem description in free-form text.

## Output

Create: `docs/.deckrd/<namespace>/<module>/requirements/requirements.md`

## Prompt & Documents

use prompt,template for write requirements.md

> Note:
> Requirements documents define **normative intent and constraints**.
> Only stated requirements and constraints are normative; examples and explanations are illustrative.

```bash
deckrd/assets/
       ├── prompts/requirements.prompt.md
       └── templates/requirements.template.md
```

## Script

Execute: [generate-doc.sh](../../scripts/generate-doc.sh)

```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/generate-doc.sh @requirements <user_input> [--lang <lang>] --output "requirements/requirements.md"
```

## Session Update

After Phase 4 approval, update `.session.json`:

```json
{
  "current_step": "req",
  "completed": ["module", "req"],
  "documents": {
    "requirements": "requirements.md"
  }
}
```

## Next Step

Run `spec` to derive specifications from requirements.
