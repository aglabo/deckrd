# impl Command

<!-- markdownlint-disable line-length -->

Derive an implementation plan (phase decomposition and commit decomposition)
from specifications through an interactive wall-hitting workflow.

```bash
DECKRD_ROOT="./docs/"
```

<!-- textlint-disable ja-technical-writing/no-exclamation-question-mark -->

## Usage

```bash
/deckrd impl [<spec-path>]
```

`<spec-path>` is optional. When omitted, defaults to
`@specifications/specifications.md`.

## Preconditions

- Session must exist with active module
- `spec` must be completed for active module
- At least one `specifications/specifications*.md` must exist

## Execution Flow

```
Phase A: Spec Reading & Codebase Investigation
Phase B: PoC / Reference PR Check
Phase C: Implementation Direction Drafting
Phase D: User Review & Feedback Loop        ← interactive（無制限ループ）
Phase E: Phase Decomposition Loop           ← interactive（フェーズ分解壁打ち）
Phase F: Commit Decomposition Loop          ← interactive（commit分解壁打ち）
Phase G: Document Generation
```

---

### Phase A: Spec Reading & Codebase Investigation

#### Step A-1: Read Specifications

Read the full specifications document (or all split files if multiple exist)
and extract:

- Feature overview and goals
- All Functional Requirements and their behavioral constraints
- Non-Functional Requirements and design constraints
- Open Questions inherited from the spec phase

Store extracted summary as **SPEC SUMMARY**.

#### Step A-2: Investigate Codebase

Use `Glob`, `Read`, and `Grep` to survey the codebase:

1. Locate modules and directories related to the feature
2. Identify existing patterns and conventions:
   - File/module structure
   - Naming conventions
   - Error handling style
3. Find code already partially implementing the feature
4. Map integration points the new feature must connect with

Store findings as **CODEBASE CONTEXT**:

```text
CODEBASE CONTEXT:
- Relevant modules: ...
- Existing patterns: ...
- Integration points: ...
- Partially implemented: ...
```

---

### Phase B: PoC / Reference PR Check

Search for prior art before planning:

1. Check `temp/`, `docs/`, `examples/` for PoC or prototype code
2. Run `git log --oneline --all` to find branches with related work
3. If a GitHub repository is accessible, search for related PRs or issues
4. Note any decisions already made in prior experiments

Store findings as **PRIOR ART**:

```text
PRIOR ART:
- PoC found: <path or "none">
- Related branches: <list or "none">
- Key decisions from prior work: ...
```

If nothing is found, record `PRIOR ART: none` and continue.

---

### Phase C: Implementation Direction Drafting

Using SPEC SUMMARY + CODEBASE CONTEXT + PRIOR ART, draft an implementation
direction:

1. **Implementation unit decomposition** — break the feature into distinct
   implementation units
2. **Architecture fit** — how the units map onto the existing codebase
3. **Technical approach** — what patterns and techniques to apply
4. **Dependency order** — which units must be built before others
5. **Risk / ambiguity list** — unclear points that need user input

Store as **IMPLEMENTATION DRAFT**:

```text
IMPLEMENTATION DRAFT:
- Implementation units: [unit-1, unit-2, ...]
- Architecture fit: ...
- Technical approach: ...
- Dependency order: ...
- Risks / ambiguities: [list]
```

---

### Phase D: User Review & Feedback Loop

Present the IMPLEMENTATION DRAFT to the user and collect feedback.

#### Step D-1: Present Summary

Show a structured summary:

```
[Implementation Review]

Implementation units:
  1. <unit-1>: <one-line description>
  2. <unit-2>: <one-line description>

Architecture fit:
  <brief description>

Technical approach:
  <brief description>

Risks / open questions:
  - <risk-1>
  - <risk-2>

Does this direction look correct? (Y / feedback)
```

#### Step D-2: Collect Feedback

If the user provides feedback:

- Identify which part of IMPLEMENTATION DRAFT needs revision
- Ask targeted clarifying questions (max 3 per round)
- Update IMPLEMENTATION DRAFT with confirmed changes
- Return to Step D-1

**Termination condition** (no round limit):

User declares "十分", "以上です", "OK", "承認", "done", or equivalent.
Unlike spec Phase D (max 3 rounds), this loop continues **without limit**
until the user explicitly approves.

Store final user-confirmed state as **CONFIRMED IMPLEMENTATION**.

---

### Phase E: Phase Decomposition Loop

Present a phase decomposition proposal and confirm with the user.

#### Step E-1: Propose Phases

Break CONFIRMED IMPLEMENTATION into implementation phases using these criteria:

- Group units that can be integrated and tested together into one phase
- Consider separating a phase into its own PR if it stands alone
- Build lower-layer components (foundations) in earlier phases

Present as:

```
[Phase Decomposition]

Phase 1: <title>
  <one-line description of what this phase delivers>

Phase 2: <title>
  <one-line description>

Does this phase breakdown look correct? (Y / feedback)
```

#### Step E-2: Collect Feedback

If the user provides feedback:

- Revise the phase breakdown
- Return to Step E-1

**Termination condition**: User approves with "Y", "OK", "承認", "done",
or equivalent.

Store confirmed phases as **PHASE PLAN**.

---

### Phase F: Commit Decomposition Loop

For each phase in PHASE PLAN, present a commit decomposition and confirm.

#### Step F-1: Propose Commits

Break each phase into commits using these criteria:

- Respect layer order (lower layers first within a phase)
- One concept = one commit
- Tests and their corresponding implementation go in the same commit

Present as:

```
[Commit Decomposition] Phase 1: <title>

Commit 1: <commit message>
  - <what this commit does>
  - <what this commit does>

Commit 2: <commit message>
  - <what this commit does>

Does this commit breakdown look correct? (Y / feedback)
```

Repeat for each phase, sequentially.

#### Step F-2: Collect Feedback

If the user provides feedback on any phase's commits:

- Revise that phase's commit breakdown
- Re-present the revised phase

**Termination condition per phase**: User approves with "Y", "OK",
"承認", "done", or equivalent.

Store confirmed commits for all phases as **COMMIT PLAN**.

---

### Phase G: Document Generation

#### Step G-1: Determine Output File

Determine whether the implementation should be split into multiple files:

- **Single file** (default): Use `implementation.md` (no number suffix)
- **Multiple files**: Use `implementation-<n>.md` only when the specification
  is large and the implementation must be split across multiple files.
  In that case, number sequentially: `implementation-1.md`, `implementation-2.md`, ...

Use numbered files only when the user or Phase E explicitly identifies
multiple independent implementation phases that warrant separate documents.

#### Step G-2: Generate Document

Build the combined prompt context from all prior phases:

```text
SPEC SUMMARY:              <Phase A>
CODEBASE CONTEXT:          <Phase A>
PRIOR ART:                 <Phase B>
CONFIRMED IMPLEMENTATION:  <Phase D>
PHASE PLAN:                <Phase E>
COMMIT PLAN:               <Phase F>
SPECIFICATIONS:            @specifications/specifications.md
```

Execute:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/run-prompt.sh impl \
  @specifications/specifications.md \
  [--lang <lang>] \
  --output "implementation/implementation.md"
# When split: use implementation-1.md, implementation-2.md, ...
```

Pass all accumulated context so the AI can produce an implementation plan
grounded in the actual codebase and confirmed decisions.

---

## Input

Read specifications document from session's active module:

```bash
docs/.deckrd/<namespace>/<module>/specifications/specifications.md
```

The `@` prefix indicates file reference:

```bash
/deckrd impl @specifications/specifications.md
```

When split specifications exist, read all split files:

```bash
/deckrd impl @specifications/specifications-<area>.md
```

## Output

Create: `docs/.deckrd/<namespace>/<module>/implementation/implementation.md`

When the implementation is explicitly split across multiple files,
use numbered files: `implementation-1.md`, `implementation-2.md`, ...

## Prompt & Documents

Use prompt and template for writing implementation plan.

> Note:
> Implementation plan defines **phase and commit decomposition**.
> It bridges specifications to executable tasks.

```bash
deckrd/assets/
       ├── prompts/implementation.prompt.md
       └── templates/implementation.template.md
```

## Script

Execute: [run-prompt.sh](../../scripts/run-prompt.sh)

```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/run-prompt.sh impl @specifications/specifications.md [--lang <lang>] --output "implementation/implementation.md"
```

> **Note**: The `@` prefix resolves to the active module's document path:
> `docs/.deckrd/<namespace>/<module>/specifications/specifications.md`

## Session Update

After completion, update `.session.json`:

```json
{
  "current_step": "impl",
  "completed": ["init", "req", "spec", "impl"],
  "documents": {
    "requirements": "requirements.md",
    "specifications": "specifications.md",
    "implementation": "implementation.md",
    "implementation_files": ["implementation.md"]
  }
}
```

When the implementation is split into multiple files, list all files
in `implementation_files` and set `implementation` to the latest:

```json
{
  "implementation": "implementation-2.md",
  "implementation_files": ["implementation-1.md", "implementation-2.md"]
}
```

## Next Step

Run `tasks` to derive executable tasks from implementation plan.
