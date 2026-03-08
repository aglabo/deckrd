# req Command

<!-- textlint-disable ja-technical-writing/no-exclamation-question-mark -->
<!-- markdownlint-disable line-length -->

Derive a normative requirements document from the user's goals, ideas, and constraints.

## Usage

```bash
/deckrd req <your requirements or goals by free-form text>
```

## Preconditions

- Session must exist with active module
- `init` must be completed for active module

## Execution Flow

### Phase 0: Codebase Investigation

Before collecting user input, investigate the codebase context:

1. Read `docs/.deckrd/.session.json` to confirm the active module
2. Check for existing `requirements.md` under the active module path
   - If found: treat this session as a **revision** of existing requirements
3. Use `Glob` and `Read` to survey:
   - Module directory structure
   - Existing documentation files
4. Summarize findings as **CODEBASE CONTEXT** (≤ 200 words) for use in Phase 3

### Phase 1: Initial Input Collection

Prompt the user:

- What problem are you trying to solve?
- What are your goals?
- Any constraints or preferences?

Accept free-form text. Store as **USER INPUT**.

### Phase 2: Hearing Loop (max 5 rounds)

Conduct an interactive Q&A loop to fill information gaps.

**Rules**:

- Ask **at most 3 questions per round**
- Prefer Yes/No or multiple-choice (A/B/C) questions over open-ended ones
- Accumulate answers as **HEARING NOTES**

**Termination conditions** (stop as soon as either is met):

1. User responds with "十分", "以上です", "OK", "done", or equivalent
2. All 5 items below are confirmed:
   1. Purpose (what problem to solve)
   2. Scope (in-scope and out-of-scope)
   3. Key functional requirements (at least 3)
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
bash ${CLAUDE_PLUGIN_ROOT}/scripts/run_prompt.sh requirements \
  "<USER_INPUT>" \
  [--lang <lang>] \
  --output "requirements/requirements.md"
```

Pass `CODEBASE CONTEXT` and `HEARING NOTES` as additional context so the AI
generates richer output including User Stories, Acceptance Criteria, and Open
Questions.

### Phase 4: Review Loop (max 3 rounds)

After `requirements.md` is generated, conduct a review loop before finalizing.

#### Step 4-1: Self-Review

Read the generated `requirements.md` and evaluate against the following checklist:

| Check Item                                  | Pass Criteria                                        |
| ------------------------------------------- | ---------------------------------------------------- |
| Purpose is clearly stated                   | One sentence, unambiguous                            |
| Scope and Out-of-Scope are explicit         | Both present, no overlap                             |
| Functional Requirements are normative       | Each uses SHALL / SHOULD / MAY; no vague verbs       |
| Non-Functional Requirements are measurable  | Quantified where possible (e.g., response < 2 s)    |
| User Stories cover all stakeholders         | 3–7 stories; each maps to at least one FR            |
| Acceptance Criteria are testable            | 5 Gherkin scenarios; Given/When/Then are concrete    |
| Open Questions are catalogued               | All unresolved items listed with owner and impact    |
| No contradictions between sections          | FR ↔ NFR ↔ User Stories are consistent               |

#### Step 4-2: Present Review Findings

Present findings to the user in one of two ways:

**If issues found**: List each issue with a suggested fix, asking the user to confirm or override:

```
[Review Finding]
- FR-02 uses vague verb "handle" → Suggest: "SHALL process X and return Y within Z ms"
  Accept suggestion? (Y/n/custom)

- NFR: no measurable target for performance
  Suggested value: < 2 s for 95th percentile. Accept? (Y/n/custom)
```

**If no issues**: Show a summary and ask for final approval:

```
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

Execute: [run_prompt.sh](../../scripts/run-prompt.sh)

```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/run_prompt.sh requirements <user_input> [--lang <lang>] --output "requirements/requirements.md"
```

## Session Update

After Phase 4 approval, update `.session.json`:

```json
{
  "current_step": "req",
  "completed": ["init", "req"],
  "documents": {
    "requirements": "requirements.md"
  }
}
```

## Next Step

Run `spec` to derive specifications from requirements.
