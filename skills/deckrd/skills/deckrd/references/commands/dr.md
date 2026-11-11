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
The only exception to append-only is `--refine`, which rewrites the wording of existing DRs
without changing what was decided.

## Usage

```bash
/deckrd dr                       # Display help and current module status
/deckrd dr --add                 # Append a new Decision Record
/deckrd dr --refine              # Review and rewrite every DR for readability
/deckrd dr --refine DR-03 DR-05  # Review and rewrite only the given DRs
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
  deckrd dr                     Show this help
  deckrd dr --add               Append a new Decision Record
  deckrd dr --refine [DR-ID..]  Rewrite existing DRs for readability (decisions unchanged)

Note: DRs can be added during any step (req, spec, impl, tasks).
      For 'tasks' step, confirmation will be requested.
      DRs can be refined during any step.
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

### Refine Mode

```bash
/deckrd dr --refine [DR-ID ...]
```

Reviews existing DRs against the [DR authoring guideline](../guidelines/decision-record-authoring.md),
including its readability rules (H), and rewrites them so that a reader who was not part of the
decision can follow them. **What was decided does not change.** Guideline section 7 defines what
may and may not change.

**Preconditions (STRICT):**

- Session must exist at `.local/deckrd/session.json`
- `session.active` must be set
- `session.modules[active]` must exist
- `<modulePath>/decision-records.md` must exist
- `current_step` is not checked. DRs can be refined during any step

**Arguments:**

- No DR-ID → every DR section in the file is a target
- One or more DR-IDs (`DR-03`, `DR-3`, and `dr-03` are accepted and normalized to `DR-03`) → only those DRs
- A DR-ID with no `## DR-<number>` heading → error, no file ops:

  ```bash
  Error: DR-07 not found in <modulePath>/decision-records.md
  ```

- A DR-ID listed in `## Deleted Decision Records` → error, no file ops:

  ```bash
  Error: DR-04 was deleted and cannot be refined
  ```

When the preconditions pass, follow [Refine Mode Flow](#refine-mode-flow).
The rewrite is done by the **dr-refiner** agent, not by the main session.

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

| Asset                                                                                              | Role                                |
| -------------------------------------------------------------------------------------------------- | ----------------------------------- |
| [references/guidelines/decision-record-authoring.md](../guidelines/decision-record-authoring.md)   | Rules A–H, self-check, refine rules |
| [assets/templates/decision-record.template.md](../../assets/templates/decision-record.template.md) | File skeleton and DR section format |
| [assets/prompts/decision-record.prompt.md](../../assets/prompts/decision-record.prompt.md)         | Drafting prompt for one DR section  |
| [references/roles/dr-writer.md](../roles/dr-writer.md)                                             | Canonical procedure for `--add`     |
| [references/roles/dr-refiner.md](../roles/dr-refiner.md)                                           | Canonical procedure for `--refine`  |

## Add Mode Flow

After the preconditions pass (and the tasks-step confirmation, if any):

1. Collect the decision. Ask the user what was decided, why, which alternatives were
   considered, and which REQ / SPEC / DR it relates to. Use only what the user states
   (or explicitly points to). Do NOT summarize the chat history on your own.
2. Draft. Spawn **dr-writer** with:
   - `skill_dir`, `local_dir`: absolute paths, see "Path arguments" in SKILL.md
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
5. Apply. Spawn **dr-writer** with `skill_dir`, `local_dir`, `mode: apply`, `module_id`, `module_path`, and `draft_file`.
   - `status: id-conflict` → re-run step 2 (the file changed meanwhile)
   - `status: malformed` → report the error; do not fix the file automatically
6. Report the DR-ID, the file path, the version change, and any warnings. dr-writer runs
   [Format and Lint](#format-and-lint) as part of apply: show its result, each lint fix as before → after,
   and any lint error left outside the new DR.

Where agents are not available, the main session runs the same steps of the
[dr-writer Role](../roles/dr-writer.md) itself, in the same order.

## Refine Mode Flow

After the preconditions and the argument check pass:

1. Draft. Spawn **dr-refiner** with:
   - `skill_dir`, `local_dir`: absolute paths, see "Path arguments" in SKILL.md
   - `mode`: `draft`
   - `module_id`, `module_path`: from the session
   - `targets`: the normalized DR-IDs (empty for all)
   - `lang`: the project's document language (default: language of existing DRs)
   - Agent definition: [`agents/dr-refiner.md`](../../../../agents/dr-refiner.md)
2. Handle the result.
   - `status: no-change` → report that nothing needs rewriting, list any `supersede` findings, and exit. No file changes
   - `status: questions` → ask the user those questions. Re-run step 1 with the answers in `answers`. The user may also answer "skip"; that finding stays unresolved and is reported, not rewritten
   - `status: drafted` → continue
3. Show the result to the user, per refined DR:
   - a diff between the original section and the refined section
   - the findings table (rule ID, class, note)

   Then list the `supersede` findings. These are not rewritten. Suggest `/deckrd dr --add` for each,
   to record the changed decision as a new DR that supersedes the old one.
4. Get approval. Ask: `Apply refinements? (yes / edit / no):`
   - `edit` → collect the corrections (including "exclude DR-NN") and re-run step 1 with `feedback`
   - `no` → delete the draft file and exit without touching `decision-records.md`
   - `yes` → continue
5. Apply. Spawn **dr-refiner** with `skill_dir`, `local_dir`, `mode: apply`, `module_id`, `module_path`, and `draft_file`.
   - `status: conflict` → the file changed after the draft; re-run step 1
   - `status: malformed` → report the error; do not fix the file automatically
6. Report the refined DR-IDs, the file path, the version change, and the `supersede` findings again.
   dr-refiner runs [Format and Lint](#format-and-lint) as part of apply: show its result, each lint fix
   as before → after, and any lint error left outside the target DRs.

Where agents are not available, the main session runs the same steps of the
[dr-refiner Role](../roles/dr-refiner.md) itself, in the same order.

## Draft File Format

dr-writer and dr-refiner write their drafts in this Markdown format, and read them back in apply mode
by these rules only. Both agents MUST follow it exactly.

- **Level-1 headings (lines starting with `#` and a space) are the only delimiters.** A DR section never contains a level-1 heading,
  so this split is safe. Do not use `---` or `###` as delimiters: DR sections contain both
  (the template ends a section with `---`, and `### Context` and the others are level-3 headings)
- The file starts with `# Draft: <mode> <module_id>` (`<mode>` is `add` or `refine`), followed by a
  metadata list, and ends with `# EOF`. A file without `# EOF` is incomplete; apply returns `status: malformed`
- Each block runs from its level-1 heading up to, not including, the next level-1 heading.
  Trim blank lines at both ends of a block
- A `# DR-NN Refined` or `# DR-NN Draft` block holds exactly one DR section, verbatim: it starts with
  `## DR-NN:` and contains no other level-2 DR heading. Apply copies this block as is

`--add` (dr-writer, `dr-draft-<module>-<DR_ID>.md`):

```markdown
# Draft: add <module_id>

- dr_id: DR-NN
- supersedes: DR-NN (scope)

# DR-NN Draft

## DR-NN: <title>

...

# EOF
```

`--refine` (dr-refiner, `dr-refine-<module>.md`), one `Findings` block and one `Refined` block per refined DR, in file order:

```markdown
# Draft: refine <module_id>

- base_version: 2.2.1
- targets: DR-03, DR-12
- original_sha256: DR-03=<hash>, DR-12=<hash>
- supplements: DR-12 <what was supplemented> (<rule ID>)

# DR-03 Findings

| Rule | Class   | Note |
| ---- | ------- | ---- |
| F-4  | rewrite | ...  |

# DR-03 Refined

## DR-03: <title>

...

# EOF
```

Omit a metadata line that has no value (`supersedes`, `supplements`).
`Findings` blocks are for the user only; apply never copies them into `decision-records.md`.

## Format and Lint

A DR MUST NOT leave document lint errors in the text it wrote (guideline F-4).
After every successful write to `decision-records.md`, the writing agent (dr-writer apply step 7,
dr-refiner apply step 6) runs the project's document formatter and document linters on that file,
and fixes the lint errors inside **the range this run wrote**:

| Mode       | Range this run wrote                                                               |
| ---------- | ---------------------------------------------------------------------------------- |
| `--add`    | The new DR section, the new Change History row, the Status line of a superseded DR |
| `--refine` | The target DR sections and the new Change History row                              |

1. Find the commands. Use the "フォーマット修正" and "リント（文書）" rows of
   `docs/.deckrd/rules/deckrd-rule-runners.md`. If the rows are empty, look them up in the
   project's task definitions (`package.json` scripts, `Makefile`, `justfile`, `Taskfile`, and so on),
   as that rule requires. Never call the underlying tools or `runners/run-*.sh` directly.
   - Example (this repository): `dprint fmt <file>`, then `pnpm run lint:markdown <file>` and `pnpm run lint:text <file>`
2. Format first. Run the formatter on `decision-records.md` only. It fixes layout, such as
   the column widths of the Change History table.
3. Then lint. Run every document linter on `decision-records.md` only.
4. Fix the errors inside the range this run wrote.
   - Change the wording only: split a long sentence, move items into a list, match the file's style.
     What was decided MUST NOT change (for `--refine`, R-1 to R-7 of guideline 7.1 still hold)
   - Keep the role of each sentence: a fact stays a fact, a reference stays a reference, a decision stays a decision.
     Never introduce decision wording (`〜とする`, `〜しなければならない`, `MUST`) that the approved text did not have.
     For example, "the string is defined in the spec table" MUST NOT become "the string is `X`" with `〜とする`
   - Never add lint disable comments, and never change the project's lint settings
   - Re-run the formatter and the linters after each round. Stop after 3 rounds
5. Report the result to the caller.
   - All pass → `format: done, lint: pass`, with each fix as before → after
   - Errors remain inside the range after 3 rounds → `lint: errors remain`, with each error (rule and location).
     The caller shows them to the user, who decides whether to run `--refine` or edit by hand
   - Errors outside the range (other DRs, older rows) → report them only. Do not touch text this run did not write
   - No formatter or linter is defined for the project → skip that step and report it as a warning
     (`format/lint not run: no command defined`). Do not treat it as a failure

The write itself is already done at this point. A remaining lint error does not roll back the DR,
the version, or the Change History row.

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
  - `--refine` may rewrite the body of existing DRs within guideline section 7: wording only.
    The decisions and the `**Phase**`, `**Status**`, and `**Supersedes**` lines never change
- A `Proposed` DR is finalized by adding a new `Accepted` DR that supersedes it, never by editing it (guideline G-1)
- One DR per run
- Capture only finalized decisions. Unresolved items make the DR `Proposed` (guideline G-1)

## Version Bump

Bump only when `decision-records.md` existed before this run.

**File created in this run** — no bump. It stays at `1.0.0` with the initial row
seeded at creation. Bumping here would start the document at `1.1.0` and
contradict the rule that the initial release is `1.0.0`.

**File already existed:**

| Change                                       | Bump  | Change History row                           |
| -------------------------------------------- | ----- | -------------------------------------------- |
| Add a DR (including a `Proposed` DR)         | MINOR | `Add DR-<ID>: <title>`                       |
| Add an `Accepted` DR that supersedes another | MAJOR | `Add DR-<ID>: <title> (supersedes DR-<NN>)`  |
| Refine one or more DRs (`--refine`)          | PATCH | `Refine DR-<NN>[, DR-<NN>]: clarify wording` |

Add exactly one Change History row and keep frontmatter `version` equal to it.
`--refine` bumps PATCH once per run, however many DRs it rewrites. A run that changes nothing does not bump.
See docs/.deckrd/rules/deckrd-rule-document-versioning.md.

**One bump per commit (guideline E-4).** Before bumping, both agents compare the file with its committed state:

1. Read the committed file with `git show HEAD:<path to decision-records.md>`. If git is not available or the file is not tracked, skip this procedure and bump as above
2. File not in `HEAD` (created but not yet committed) → keep `1.0.0` and add this change to the initial row
   (for example `Initial release with DR-01, DR-02`). Do not bump
3. Working-tree `version` equals the committed one → no pending bump; bump as above
4. Working-tree `version` is higher → a bump is pending. Do not add a row. Take the largest of the pending
   increment and this run's increment, apply it once to the committed version, and replace every row after
   the committed last row with exactly one row that describes both changes:

   | Pending row                    | This run       | Result                                                    |
   | ------------------------------ | -------------- | --------------------------------------------------------- |
   | `2.2.1 Refine DR-03..DR-16: …` | Refine DR-01.. | `2.2.1 Refine DR-01..DR-16: clarify wording`              |
   | `2.3.0 Add DR-17: <title>`     | Refine DR-05   | `2.3.0 Add DR-17: <title>; refine DR-05: clarify wording` |
   | `2.2.1 Refine DR-05: …`        | Add DR-17      | `2.3.0 Add DR-17: <title>; refine DR-05: clarify wording` |

List DR-IDs in file order and merge duplicates. Never remove a committed row.

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
| `--refine` and no `decision-records.md`     | Error, no file ops                      |
| `--refine` with an unknown or deleted DR-ID | Error with message, no file ops         |
| Refine would change a decision              | Not rewritten; reported as `supersede`  |
| File changed between refine draft and apply | Re-draft, no partial write              |
| Lint errors in the text this run wrote      | The agent fixes the wording (3 rounds)  |
| Lint errors in text this run did not write  | Report them only                        |
| No formatter or linter defined              | Warning only; skip that step            |

**Error Philosophy:**

- Fail fast
- No partial writes
- No silent fallbacks
- Prefer explicit errors over guessing

## Non-Goals

- Do NOT auto-summarize chat history
- Do NOT generate DRs implicitly
- Do NOT support DR deletion
- Do NOT edit existing DRs except: frontmatter `version`, Change History, the Status line of a
  superseded DR, and wording-only rewrites by `--refine`
- Do NOT change a decision with `--refine`. Record a changed decision as a new DR with `--add`
- Do NOT skip confirmation for tasks step
- Do NOT skip the user's approval of the draft (both `--add` and `--refine`)

## Workflow Integration

DRs can be created during any step when explicitly requested.
Confirmation is required for the `tasks` step.

```bash
init ──> req (DR allowed) ──> spec (DR allowed) ──> impl (DR allowed) ──> tasks (DR allowed with confirmation)
```
