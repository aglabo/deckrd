---
title: dr Command
description: Manage Decision Records for the active module
---

## dr Command

<!-- textlint-disable
  ja-technical-writing/sentence-length,
  ja-technical-writing/max-comma -->
<!-- markdownlint-disable line-length -->

Manage Decision Records (DR) for the active module.

Decision Records are non-normative, append-only records of decisions
made during any phase of the development process (req, spec, impl, tasks).

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

Note: DRs can be added during any step (req, spec, impl, tasks).
      For 'tasks' step, confirmation will be requested.
```

### Add Mode

```bash
/deckrd dr --add
```

**Preconditions (STRICT):**

- Session must exist at `.local/deckrd/session.json`
- `session.active` must be set
- `session.modules[active]` must exist
- `session.modules[active].current_step` must be one of: `"req"`, `"spec"`, `"impl"`, `"tasks"`

**If `current_step === "tasks"`:**

Prompt user for confirmation:

```bash
You are in the 'tasks' step.
Do you want to record this decision? (yes/no):
```

- If user responds `no` (or n, N, NO): Exit without creating or modifying files
- If user responds `yes` (or y, Y, YES): Proceed with DR creation

**If `current_step` is invalid (not req/spec/impl/tasks):**

```bash
Error: Invalid step '<current_step>'.
DR can be added during: req, spec, impl, tasks
```

Exit with error. Do NOT create or modify files.

## Session Resolution

**Session file location:**

```bash
.local/deckrd/session.json
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
version: 1.0.0
created: <ISO-8601 date>
---
```

Also seed a `## Change History` section with the `1.0.0` initial row
(see `decision-record.template.md`).

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

- **Append only** for DR sections - no edits, no rewrites
- Exception: frontmatter `version` and the Change History table MUST be updated
  (adding a DR is MINOR — see deckrd-rule-document-versioning.md)
- Append after the **LAST DR section**, above `## Change History`
- Use the established DR template structure
- Do NOT include implementation code
- Do NOT restate requirements
- Capture only finalized decisions

**DR Section Format:**

```markdown
## DR-<ID>: <Decision Title> - <YYYY-MM-DD HH:MM:SS>

**Phase**: <current_step>
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

## Version Bump

Adding a DR is MINOR. After appending the DR section:

1. Bump frontmatter `version` MINOR (e.g. 1.2.0 → 1.3.0)
2. Add exactly one Change History row: `| <date> | <new version> | Add DR-<ID>: <title> |`

See deckrd-rule-document-versioning.md.

## Error Handling

| Condition                                   | Action                          |
| ------------------------------------------- | ------------------------------- |
| No session file                             | Error, exit with non-zero       |
| No active module                            | Error, exit with non-zero       |
| `current_step` not in (req/spec/impl/tasks) | Error with message, no file ops |
| User declines in tasks step                 | Exit gracefully, no file ops    |
| Module path mismatch in front               | Warning only, proceed           |

**Error Philosophy:**

- Fail fast
- No partial writes
- No silent fallbacks
- Prefer explicit errors over guessing

## Non-Goals

- Do NOT auto-summarize chat history
- Do NOT generate DRs implicitly
- Do NOT support DR editing or deletion (frontmatter `version` and Change History excepted)
- Do NOT skip confirmation for tasks step

## Workflow Integration

DRs can be created during any step when explicitly requested.
Confirmation is required for the `tasks` step.

```bash
init ──> req (DR allowed) ──> spec (DR allowed) ──> impl (DR allowed) ──> tasks (DR allowed with confirmation)
```

## AI Interaction Engine

Deckrd commands rely on an AI interaction engine to derive documents
from user input and interaction logs.

The provided scripts invoke this engine and are required for normal
Deckrd operation, rather than serving as optional reference implementations.

Execute: [generate-doc.sh](../../scripts/generate-doc.sh)

For `--add` mode:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/generate-doc.sh @decision-record <user_context> [--lang <lang>] --output "decision-records.md" --append
```
