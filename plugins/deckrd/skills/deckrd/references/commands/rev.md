---
title: rev Command
description: Reverse-engineer existing code into deckrd documentation artifacts
---

<!-- textlint-disable
  ja-technical-writing/sentence-length -->

## rev Command

<!-- textlint-disable
    ja-technical-writing/no-exclamation-question-mark,
    ja-technical-writing/max-comma -->
<!-- markdownlint-disable line-length -->

Reverse-engineer existing code into deckrd documentation artifacts.
Supports legacy codebases, post-PoC documentation, and applying deckrd to existing projects.

## Usage

```bash
/deckrd rev [--from code] [--to req|spec|impl|tasks]
```

## Options

| Option                | Values                         | Default  | Description                            |
| --------------------- | ------------------------------ | -------- | -------------------------------------- |
| `--from`              | `code`                         | `code`   | Source artifact type                   |
| `--to`                | `req`, `spec`, `impl`, `tasks` | `req`    | Target document to generate            |
| `--module <ns>/<mod>` | path string                    | (active) | Override active module for output path |

## Preconditions

- Session must exist
- `init` must be completed
- `module` must be set (active module required)

For `--to spec`: existing `requirements.md` must exist, or `--to req` must be run first.
For `--to impl`: existing `requirements.md` and `specifications.md` must exist.
For `--to tasks`: existing `implementation.md` must exist.

## Commitment Declaration (REQUIRED)

Before Phase 0, YOU MUST output:

> "I am executing /deckrd rev for module [MODULE_NAME].
> Target document: [TARGET]. I will complete phases in order: 0 -> 1 -> 2 -> 3. I will NOT skip phases."

---

## Execution Flow

```text
Phase 0: Codebase Extraction (explore-agent 委譲)
Phase 1: Extraction Review & Gap Detection
Phase 2: Document Generation
Phase 3: Review Loop
```

---

### Phase 0: Codebase Extraction (explore-agent 委譲)

Delegate deep codebase extraction to explore-agent:

1. Read `docs/.deckrd/.session.json` to confirm active module
2. Spawn **explore-agent** with:
   - `scope`: `codebase-extraction`
   - `directory`: project root
   - `focus`: module name + target document type (e.g., `requirements`, `specifications`)
   - Agent definition: [`plugins/deckrd/agents/explore-agent.md`](../../../../agents/explore-agent.md)
3. The agent writes findings to `temp/deckrd-work/codebase-extraction.md`
4. Read the **Summary** returned by the agent and store as **EXTRACTION CONTEXT**

---

### Phase 1: Extraction Review & Gap Detection

Review the EXTRACTION CONTEXT and identify gaps:

#### Step 1-1: Present Extraction Summary

Show the user what was extracted:

```text
[Reverse Engineering Scan]

Detected artifacts:
  - Source files: <count> files
  - Existing docs: <list or "none">
  - Detected patterns: <list>
  - Detectable requirements: <count> inferred FRs

Gaps that need user input:
  - <gap-1>: <what could not be inferred>
  - <gap-2>: <what could not be inferred>

Proceed to generate [TARGET] document? (Y / add more context)
```

#### Step 1-2: Gap-Filling Loop (max 3 rounds)

If the user provides additional context:

- Ask EXACTLY 1 question per round. No exceptions.
- Accumulate answers as **GAP NOTES**

**Termination conditions** (stop as soon as either is met):

1. User responds with "十分", "以上です", "OK", "done", or equivalent
2. 3 rounds completed

---

### Phase 2: Document Generation

Build the combined prompt context:

```text
EXTRACTION CONTEXT: <Phase 0 findings>
GAP NOTES:          <Phase 1 accumulated answers>
TARGET:             <--to value>
```

Execute based on `--to` value:

**`--to req`**:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/generate-doc.sh rev \
  --mode req \
  --output "requirements/requirements.md"
```

**`--to spec`**:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/generate-doc.sh rev \
  --mode spec \
  --output "specifications/specifications.md"
```

**`--to impl`**:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/generate-doc.sh rev \
  --mode impl \
  --output "implementation/implementation.md"
```

**`--to tasks`**:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/generate-doc.sh rev \
  --mode tasks \
  --output "tasks/tasks.md"
```

Pass EXTRACTION CONTEXT and GAP NOTES as additional context.

---

### Phase 3: Review Loop (max 3 rounds)

After the document is generated, conduct a review loop.

#### Step 3-1: Self-Review

Read the generated document and evaluate:

| Check Item                    | Pass Criteria                                   |
| ----------------------------- | ----------------------------------------------- |
| Reflects actual code behavior | Each item traceable to a source file or pattern |
| No fabricated requirements    | Only documented behaviors are normative         |
| Gaps clearly marked           | Inferred items labeled `[INFERRED]`             |
| Open Questions present        | Unverifiable items listed as open questions     |

#### Step 3-2: Present Review Findings

**If issues found**: List each issue and ask user to confirm:

```toml
[Review Finding]
- FR-03 marked [INFERRED] — no direct source found
  Accept as inferred, or remove? (keep / remove / custom)
```

**If no issues**:

```toml
[Review Summary] No critical issues found.
Approve [TARGET] document? (Y / revise)
```

#### Step 3-3: Rewrite (if needed)

If the user requests revisions:

1. Collect revision instructions as **REVIEW NOTES**
2. Re-execute Phase 2 with `REVIEW NOTES` appended to context
3. Return to Step 3-1

**Termination conditions**:

1. User approves with "Y", "承認", "OK", "done", or equivalent
2. 3 review rounds completed — present document as-is for explicit approval

---

## Input

Existing source code, tests, and documentation in the project root.

## Output

Depends on `--to` value:

| `--to`  | Output Path                                                          |
| ------- | -------------------------------------------------------------------- |
| `req`   | `docs/.deckrd/<namespace>/<module>/requirements/requirements.md`     |
| `spec`  | `docs/.deckrd/<namespace>/<module>/specifications/specifications.md` |
| `impl`  | `docs/.deckrd/<namespace>/<module>/implementation/implementation.md` |
| `tasks` | `docs/.deckrd/<namespace>/<module>/tasks/tasks.md`                   |

## Prompt & Documents

```bash
deckrd/assets/
       ├── prompts/rev.prompt.md
       └── templates/rev.template.md
```

## Session Update

After Phase 3 approval, update `.session.json` to mark the target step as completed:

**`--to req`**:

```json
{
  "current_step": "req",
  "completed": ["init", "req"],
  "documents": {
    "requirements": "requirements.md"
  }
}
```

**`--to spec`** (also marks `req` as completed if not already):

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

## Relationship to Standard Flow

`rev` is a bootstrap command. It generates the same document types as the standard flow,
but derives them from existing code rather than from user goals.

After `rev` completes, the standard flow commands (`spec`, `impl`, `tasks`) can continue
from the generated document.

```text
[existing code]
     |
     v
[/deckrd rev --to req]   → requirements.md
     |
     v
[/deckrd spec]           → specifications.md  (standard flow resumes)
     |
     v
[/deckrd impl]           → implementation.md
```

## Next Step

After `--to req`: Run `spec` to derive specifications.
After `--to spec`: Run `impl` to derive implementation plan.
After `--to impl`: Run `tasks` to derive executable tasks.
After `--to tasks`: Run `/deckrd-coder` to implement.
