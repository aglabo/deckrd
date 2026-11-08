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

When the preconditions pass, follow [Add Mode Flow](#add-mode-flow).
The DR text is written by the **dr-writer** agent, not by the main session.

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

## Writing Guideline

Every DR MUST follow the [DR authoring guideline](../guidelines/decision-record-authoring.md).
It is the single source of truth for what a DR contains and what it leaves out
(no tasks or progress, no implementation detail, explicit scope and non-decisions,
a rejection reason for every alternative, and so on). Do not restate its rules here.

| Asset                                                                                              | Role                                  |
| -------------------------------------------------------------------------------------------------- | ------------------------------------- |
| [references/guidelines/decision-record-authoring.md](../guidelines/decision-record-authoring.md)   | Rules A–G and the self-check list     |
| [assets/templates/decision-record.template.md](../../assets/templates/decision-record.template.md) | File skeleton and DR section format   |
| [assets/prompts/decision-record.prompt.md](../../assets/prompts/decision-record.prompt.md)         | Drafting prompt for one DR section    |
| [references/roles/dr-writer.md](../roles/dr-writer.md)                                             | Canonical procedure (draft and apply) |

## Add Mode Flow

After the preconditions pass (and the tasks-step confirmation, if any):

1. Collect the decision. Ask the user what was decided, why, which alternatives were
   considered, and which REQ / SPEC / DR it relates to. Use only what the user states
   (or explicitly points to). Do NOT summarize the chat history on your own.
2. Draft. Spawn **dr-writer** with:
   - `mode`: `draft`
   - `module_id`, `module_path`: from the session
   - `phase`: `current_step`
   - `lang`: the project's document language (default: language of existing DRs)
   - `decision_context`: the decision collected in step 1
   - Agent definition: [`agents/dr-writer.md`](../../../../agents/dr-writer.md)
3. Handle the result.
   - `status: questions` → ask the user those questions, then go back to step 2 with the answers added to `decision_context`
   - `status: drafted` → show the draft file content and the self-check summary to the user
4. Get approval. Ask: `Append this DR? (yes / edit / no):`
   - `edit` → collect the corrections and re-run step 2 with `feedback`
   - `no` → delete the draft file and exit without touching `decision-records.md`
   - `yes` → continue
5. Apply. Spawn **dr-writer** with `mode: apply`, `module_id`, `module_path`, and `draft_file`.
   - `status: id-conflict` → re-run step 2 (the file changed meanwhile)
   - `status: malformed` → report the error; do not fix the file automatically
6. Report the DR-ID, the file path, the version change, and any warnings.

Where agents are not available, the main session runs the same steps of the
[dr-writer Role](../roles/dr-writer.md) itself, in the same order.

## Decision Records File

**Location:** `<modulePath>/decision-records.md` (one file per module).

**If the file does NOT exist**, dr-writer creates it from the template in apply mode:
frontmatter `version: 1.0.0` and a Change History with one row,
`Initial release with DR-01: <title>`. A file created in this run does NOT get a version bump.

**If the file exists** and `front_matter.module !== moduleId`: emit WARNING only, do NOT auto-fix.

## DR-ID Strategy

DR-IDs are sequential per module and never reused: DR-01, DR-02, ...

1. Scan the existing `decision-records.md`
2. Collect numbers from headings matching `## DR-<number>` and from the ID column of `## Deleted Decision Records`, if present
3. New DR-ID = max + 1

dr-writer computes the ID in draft mode and re-checks it in apply mode.

## Append Rules

- **Append only** for DR sections: append right after the **LAST DR section**
  (above `## Deleted Decision Records` if present, otherwise above `## Change History`)
- Exceptions (the only edits allowed to existing content):
  - frontmatter `version` and the Change History table MUST be updated
  - when a new **Accepted** DR supersedes an existing one, the `**Status**:` line of the replaced DR is
    updated to `Superseded by DR-<ID>` or `Partially superseded by DR-<ID>（<scope>）`.
    Nothing else in that DR changes (guideline E-1)
- A `Proposed` DR is finalized by adding a new `Accepted` DR that supersedes it, never by editing it (guideline G-1)
- One DR per run
- Capture only finalized decisions. Unresolved items make the DR `Proposed` (guideline G-1)

## Version Bump

Bump only when `decision-records.md` existed before this run.

**File created in this run** — no bump. It stays at `1.0.0` with the initial row
seeded at creation. Bumping here would start the document at `1.1.0` and
contradict the rule that the initial release is `1.0.0`.

**File already existed:**

| Change                                       | Bump  | Change History row                          |
| -------------------------------------------- | ----- | ------------------------------------------- |
| Add a DR (including a `Proposed` DR)         | MINOR | `Add DR-<ID>: <title>`                      |
| Add an `Accepted` DR that supersedes another | MAJOR | `Add DR-<ID>: <title> (supersedes DR-<NN>)` |

Add exactly one Change History row and keep frontmatter `version` equal to it.
See docs/.deckrd/rules/deckrd-rule-document-versioning.md.

## Error Handling

| Condition                                   | Action                                  |
| ------------------------------------------- | --------------------------------------- |
| No session file                             | Error, exit with non-zero               |
| No active module                            | Error, exit with non-zero               |
| `current_step` not in (req/spec/impl/tasks) | Error with message, no file ops         |
| User declines in tasks step                 | Exit gracefully, no file ops            |
| Missing information for the DR              | Ask the user (dr-writer `questions`)    |
| User rejects the draft                      | Delete the draft, no changes to the DRs |
| DR-ID changed between draft and apply       | Re-draft, no partial write              |
| Module path mismatch in front               | Warning only, proceed                   |

**Error Philosophy:**

- Fail fast
- No partial writes
- No silent fallbacks
- Prefer explicit errors over guessing

## Non-Goals

- Do NOT auto-summarize chat history
- Do NOT generate DRs implicitly
- Do NOT support DR editing or deletion (frontmatter `version`, Change History, and the
  Status line of a superseded DR excepted)
- Do NOT skip confirmation for tasks step
- Do NOT skip the user's approval of the draft

## Workflow Integration

DRs can be created during any step when explicitly requested.
Confirmation is required for the `tasks` step.

```bash
init ──> req (DR allowed) ──> spec (DR allowed) ──> impl (DR allowed) ──> tasks (DR allowed with confirmation)
```
