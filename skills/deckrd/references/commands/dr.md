# dr Command
<!-- textlint-disable ja-technical-writing/sentence-length -->
<!-- markdownlint-disable line-length -->

Manage Decision Records (DR) for the active module.

Decision Records are non-normative, append-only records of decisions.
made during the requirements definition phase.

## Usage

```bash
/deckrd dr           # Display help and current module status
/deckrd dr --add     # Append a new Decision Record
```

## Command Modes

### Help Mode (no flags)

```bash
/deckrd dr
```

**Behavior:**

- Display current active module and step
- Show usage information
- **DO NOT create or modify any files**

**Output Example:**

```bash
Decision Records (DR) - deckrd

Active Module: agtKind/isSingleValue
Current Step: req

Usage:
  deckrd dr         Show this help
  deckrd dr --add   Append a new Decision Record

Note: DRs can only be added during the 'req' step.
```

### Add Mode

```bash
/deckrd dr --add
```

**Preconditions (STRICT):**

- Session must exist at `docs/.deckrd/.session.json`
- `session.active` must be set
- `session.modules[active]` must exist
- `session.modules[active].current_step` MUST equal `"req"`

**`If current_step !== "req":`**

```bash
Error: DR can only be added during the 'req' step.
Current step: <current_step>
```

Exit with error. Do NOT create or modify files.

## Session Resolution

**Session file location:**

```bash
docs/.deckrd/.session.json
```

**Required fields:**

```json
{
  "active": "<moduleId>",
  "modules": {
    "<moduleId>": {
      "current_step": "req",
      "path": "docs/.deckrd/<namespace>/<module>"
    }
  }
}
```

**Path resolution:**

- moduleId = `session.active`
- modulePath = `session.modules[moduleId].path`
- Decision Records file = `<modulePath>/decision-records.md`

## Decision Records File

**Location:**

```bash
<modulePath>/decision-records.md
```

**If file does NOT exist**, create with front matter:

```yaml
---
title: Decision Records
module: <moduleId>
status: Active
created: <ISO-8601 date>
---
```

**If file exists**, parse and validate front matter:

- If `front_matter.module !== moduleId`: emit WARNING only, do NOT auto-fix

## DR-ID Strategy

DR-IDs are sequential per module: DR-01, DR-02, ...

**Procedure:**

1. Scan existing `decision-records.md`
2. Find all headings matching: `## DR-<number>`
3. Determine max number
4. New DR-ID = max + 1

## Prompt & Template

Use prompt and template for generating DR content:

```bash
deckrd/assets/
       ├── prompts/decision-record.prompt.md
       └── templates/decision-record.template.md
```

## Append Rules

- **Append only** - no edits, no rewrites
- Append to the **END** of the file
- Use the established DR template structure
- Do NOT include implementation code
- Do NOT restate requirements
- Capture only finalized decisions

**DR Section Format:**

```markdown
## DR-<ID>: <Decision Title> - <YYYY-MM-DD HH:MM:SS>

**Status**: Accepted

### Context

<why this decision was needed>

### Decision

<what was decided>

### Alternatives Considered

- Option A: ...
- Option B: ...

### Rationale

<why this option was chosen>

### Consequences

- Positive:
  - ...

- Negative:
  - ...

---
```

## Error Handling

| Condition                     | Action                          |
| ----------------------------- | ------------------------------- |
| No session file               | Error, exit with non-zero       |
| No active module              | Error, exit with non-zero       |
| `current_step !== "req"`      | Error with message, no file ops |
| Module path mismatch in front | Warning only, proceed           |

**Error Philosophy:**

- Fail fast
- No partial writes
- No silent fallbacks
- Prefer explicit errors over guessing

## Non-Goals

- Do NOT auto-summarize chat history
- Do NOT generate DRs implicitly
- Do NOT allow DR creation in spec/impl steps
- Do NOT support DR editing or deletion

## Workflow Integration

DRs are created ONLY during the `req` step when explicitly requested.

```bash
init ──> req (DR allowed here) ──> spec ──> impl ──> tasks
```

## AI Interaction Engine

Deckrd commands rely on an AI interaction engine to derive documents
from user input and interaction logs.

The provided scripts invoke this engine and are required for normal
Deckrd operation, rather than serving as optional reference implementations.

Execute: [run_prompt.sh](../../scripts/run-prompt.sh)

For `--add` mode:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/run_prompt.sh decision-record <user_context> [--lang <lang>] --output "decision-records.md" --append
```
