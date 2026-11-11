---
name: bdd-coder
description: >
  BDD-style implementation agent. Use when the user gives ANY coding instruction —
  natural-language, explicit Task ID, or custom task list.
  Breaks large requests into a task list via tasklist-builder, then always spawns
  checklist-builder for one task to generate a checklist, then runs BDD implementation.
  Examples: "implement X", "add function Y", "create Z", "write code for W",
  "implement task T01-02", "run bdd-coder", "start BDD implementation".
  Do NOT commit or push — implementation only, no git operations.
  Do NOT implement multiple tasks in one invocation — one task per call.
metadata:
  author: aglabo
  version: 0.6.1
  license: MIT
---

<!-- textlint-disable
  ja-technical-writing/sentence-length -->

# bdd-coder

Implements tasks using strict BDD: Red → Green → Refactor.
Breaks the input into a task list via tasklist-builder when needed,
generates a checklist for one task via checklist-builder,
then delegates BDD implementation to bdd-coder.

## Skill Announcement (REQUIRED)

Before every phase, YOU MUST output:

> "I am executing /bdd-coder:bdd-coder [TASK_ID] — Phase [N]: [Phase Name]."

No announcement = violation. Restart with announcement.

## Before You Begin (REQUIRED)

Raise ALL questions before writing any code. Ask NOW if any of the following are unclear:

- Task scope or acceptance criteria
- Ambiguous specs
- Implementation approach or dependencies

Once Phase 1 (Tasklist Resolve + Checklist Build) starts, stop asking scope questions.
Choosing which task-list item to run (Phase 1a) is not a scope question and is still asked there.

## Execution Flow

bdd-coder is an orchestration layer with the following fixed phase order:

| Phase | Name                               | Agent                                | What happens                                                                                  |
| ----- | ---------------------------------- | ------------------------------------ | --------------------------------------------------------------------------------------------- |
| 0     | Environment                        | explore-agent                        | Detect language, test framework, lint, type-check setup                                       |
| 1     | Tasklist Resolve + Checklist Build | tasklist-builder + checklist-builder | Build or restore the task list, pick one item, generate its checklist, save the session entry |
| 2     | Dependency Map                     | bdd-coder                            | Classify checklist tasks into serial / parallel groups                                        |
| 3     | bdd-coder Dispatch                 | bdd-coder                            | Spawn bdd-coder per task; collect status reports                                              |
| 4     | Quality Gate                       | bdd-coder + code-reviewer            | Global lint + type-check + all tests pass, then code review                                   |
| 5     | Done Check                         | bdd-coder                            | Confirm all checklist items complete; write back tasks.md, task list, session                 |
| 6     | Session End                        | bdd-coder                            | Reset state; remind user to commit manually                                                   |

### Roles and subagents

The procedure of each agent lives in a Role file under [references/roles/](references/roles/):

- explore-agent → [explorer.md](references/roles/explorer.md)
- tasklist-builder → [tasklist-builder.md](references/roles/tasklist-builder.md)
- checklist-builder → [checklist-builder.md](references/roles/checklist-builder.md)
- bdd-coder → [implementer.md](references/roles/implementer.md)
- code-reviewer → [code-reviewer.md](references/roles/code-reviewer.md)

On every "Spawn", also pass two absolute paths:

- `skill_dir`: this skill directory, the one that holds this `SKILL.md`.
- `local_dir`: the value of `DECKRD_LOCAL_DATA` (`.local/deckrd` under the project root, as an absolute path).

The Role resolves every path from these two values. `temp` is always `<local_dir>/temp`.

Wherever a phase says "Spawn", do this:

- If you can start a subagent, hand it `skill_dir`, `local_dir` and the Role file, and let it run.
- If you cannot, follow the same Role file yourself with the same two values, step by step.

Gate Rule: phases must run in order. No skipping.

All tests MUST pass at Phase 4. No exceptions.
Do NOT commit after completion — user commits manually.

### Phase 1: Tasklist Resolve + Checklist Build

Route the input first. Only natural language and Target IDs go through tasklist-builder.

| Input                             | Phase 1a: tasklist-builder | Phase 1b: checklist-builder input                    |
| --------------------------------- | -------------------------- | ---------------------------------------------------- |
| Natural-language                  | Run                        | `Handoff` of the selected item                       |
| Target ID (e.g. `T01`)            | Run                        | `Handoff` of the selected item (`T01-02`)            |
| Scenario ID (e.g. `T01-02`)       | Skip                       | The Task ID as given                                 |
| `--tasklist <path> [--item L-02]` | Skip                       | `Handoff` of the given item, or first `pending`      |
| `--checklist <path>`              | Skip                       | Skip checklist-builder; use the file                 |
| `--resume`                        | Skip                       | Restored from `session.json` (see [Resume](#resume)) |

#### Session entry

The skill keeps the work in progress in the `bdd_coder` entry of `.local/deckrd/session.json`,
so an interrupted session can be resumed. Paths are relative to the repository root.

```json
{
  "bdd_coder": {
    "tasklist": ".local/deckrd/temp/tasklist/deckrd/libs/T-01.tasklist.md",
    "item": "L-02",
    "checklist": ".local/deckrd/temp/tasks/parse-config-calm-checklist.md",
    "status": "in-progress",
    "updated_at": "2026-11-09T00:00:00Z"
  }
}
```

| Field        | Value                                                                   |
| ------------ | ----------------------------------------------------------------------- |
| `tasklist`   | TASKLIST PATH, or `null` when Phase 1 used no task list                 |
| `item`       | Item ID selected in Phase 1a, or `null` when there is no task list      |
| `checklist`  | CHECKLIST PATH, or `null` until Phase 1b returns it                     |
| `status`     | `in-progress` from Phase 1 on; `done` when Phase 5 completes every case |
| `updated_at` | UTC timestamp of the last write (`date -u +"%Y-%m-%dT%H:%M:%SZ"`)       |

Rules:

- Only this skill (the orchestrator) reads or writes `bdd_coder`. tasklist-builder, checklist-builder,
  and the bdd-coder agent never see it (Phase 3: "Do NOT pass ... session.json").
- Replace the `bdd_coder` value as a whole and leave every other key untouched.
  Write through a temporary file, as `module.sh` does:

  ```bash
  jq --arg tl "$TASKLIST" --arg item "$ITEM" --arg cl "$CHECKLIST" --arg st "$STATUS" \
     --arg now "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
     'def nz: if . == "" then null else . end;
      .bdd_coder = {tasklist: ($tl | nz), item: ($item | nz), checklist: ($cl | nz),
                    status: $st, updated_at: $now}' \
     .local/deckrd/session.json > .local/deckrd/session.json.tmp &&
    mv .local/deckrd/session.json.tmp .local/deckrd/session.json
  ```

  Pass an empty string for a `null` field. Do not use `select(. != "")` instead of `nz`:
  an empty value inside `{...}` makes jq output nothing, and the `mv` then empties `session.json`.
  `jaq` accepts the same filter.
- If `.local/deckrd/session.json` does not exist, do not create it. Warn that the session cannot be
  saved (`/deckrd init` has not run) and continue without it.

| When                                    | Write                                                                        |
| --------------------------------------- | ---------------------------------------------------------------------------- |
| Phase 1a: an item is selected           | `tasklist`, `item`, `checklist: null`, `status: in-progress`                 |
| Phase 1b: CHECKLIST PATH is returned    | Keep `tasklist` / `item` (or `null`), set `checklist`, `status: in-progress` |
| Phase 5 Step 4c: every case is complete | `status: done`                                                               |

A session that ends early (`BLOCKED`, abort) keeps `status: in-progress`, so it can be resumed.

#### Resume

`--resume` continues the work recorded in `bdd_coder`:

| `bdd_coder` state                                         | Action                                                         |
| --------------------------------------------------------- | -------------------------------------------------------------- |
| Missing, or `status: done`                                | Report "nothing to resume" and end the session (Phase 6)       |
| `checklist` set and the file exists                       | Use it as `--checklist`; restore TASKLIST PATH and the item    |
| `checklist` is `null`, `tasklist` set and the file exists | Run as `--tasklist <tasklist> --item <item>`                   |
| A recorded file does not exist                            | Report the missing path and end the session. Do not rebuild it |

A Target ID or `--tasklist` also restores the selected item. After Phase 1a (or after reading `--tasklist`),
check the `bdd_coder` entry against these conditions:

- `bdd_coder.tasklist` equals TASKLIST PATH
- `status` is `in-progress`
- the recorded `item` is still `pending` in the task list
- `--item` is not given, or names the recorded `item`

If all of them hold, select that item without asking and tell the user which item was restored.
Otherwise select the item as usual. An explicit `--item` always wins over the recorded item.

Run Phase 1b for the restored item even when the recorded checklist still exists.
tasks.md may have changed since the checklist was built (a Case added or changed in the Scenario),
and reconciliation keeps the item's ID and its `pending` status, so the old checklist cannot be trusted.
Only `--resume` reuses the recorded checklist as is. If tasks.md has changed, run the Target ID instead of `--resume`.

#### Phase 1a: Tasklist Build

Spawn **tasklist-builder** with `skill_dir`, `local_dir`, `instruction`, and `tasks_md` for a Target ID.
Role: [roles/tasklist-builder.md](references/roles/tasklist-builder.md).

| Returned status              | Handling                                                                   |
| ---------------------------- | -------------------------------------------------------------------------- |
| `questions`                  | Ask the user the returned question, then re-run with `answers`             |
| `invalid-input`              | Report `DETAIL` to the user and end the session (Phase 6)                  |
| `created`/`reused`/`updated` | Select one item as below, and keep the task list path as **TASKLIST PATH** |

Select the item:

- Exactly one `pending` item → use it without asking.
- Two or more `pending` items → show the list (ID / Title / Status) and ask which one to run.
  Default: the first `pending` item whose `Depends-on` items are all `done`.
- `needs-split`, `done`, and `removed` items cannot be selected.
  For `needs-split`, tell the user to split the Case in tasks.md via `/deckrd tasks`,
  then run the same Target ID again. tasklist-builder reconciles the list with tasks.md
  (`STATUS: updated`) and keeps the `done` items.
- On `updated`, show the `CHANGED` line to the user before selecting.
- No `pending` item → report it and end the session (Phase 6).

After selecting the item, write the [session entry](#session-entry).

Pass **only the selected item's `Handoff`** to Phase 1b.
Never pass the task list file to checklist-builder or bdd-coder: it lists other tasks.
The rule "1 delegation = 1 task" (`docs/.deckrd/rules/deckrd-rule-bdd-cycle.md`)
forbids handing over material that contains other tasks.
The task list is orchestrator state only. Shortcuts such as "pass the task list and say
'do L-02 only'" break this rule: the agent sees the other items and may implement them.

Output (under `<local_dir>/temp`):

- Target ID: `<local_dir>/temp/tasklist/<ns>/<module>/T-XX.tasklist.md`
  (for example `<local_dir>/temp/tasklist/deckrd/libs/T-01.tasklist.md`).
  Re-running the same Target ID reuses this file (`reused` / `updated`); it is never created twice.
- Natural language: `<local_dir>/temp/tasklist/<active module>/<name>.tasklist.md`
- Natural language, no active module: `<local_dir>/temp/tasklist/<name>.tasklist.md`

#### Phase 1b: Checklist Build

Spawn **checklist-builder** with `skill_dir`, `local_dir`, and the routed input.
Role: [roles/checklist-builder.md](references/roles/checklist-builder.md).

| Input type            | checklist-builder behavior                                    |
| --------------------- | ------------------------------------------------------------- |
| Natural-language      | Analyze instruction, decompose into BDD tasks, generate file  |
| Task ID (e.g. T01-02) | Read tasks.md entry, expand into BDD checklist, generate file |
| `--checklist <path>`  | Skip checklist-builder, use the specified existing file       |

Output: `.local/deckrd/temp/tasks/<slug>-<adjective>-checklist.md`

When the checklist path is returned (or given by `--checklist`), keep it as **CHECKLIST PATH**
and write the [session entry](#session-entry).

If checklist-builder reports `BLOCKED` (a Task ID's Case lists more than one input):

1. Do NOT proceed to Phase 2 — no checklist was written.
2. Report the `BLOCKED` line to the user verbatim, with the remediation:
   split the Case in tasks.md via `/deckrd tasks`, then re-run bdd-coder with the Task ID.
3. End the session (Phase 6). Do NOT expand the inputs yourself or fall back to a natural-language checklist.

### Phase 3: bdd-coder Dispatch

Pass the following context to each bdd-coder instance:

| Item              | Content                              |
| ----------------- | ------------------------------------ |
| `skill_dir`       | This skill directory (absolute path) |
| `local_dir`       | `DECKRD_LOCAL_DATA` (absolute path)  |
| Task ID           | e.g. `T-01-02-01`                    |
| Task description  | Full Given/When/Then from checklist  |
| Quality gate cmds | Commands table from ENV PROFILE      |
| Checklist path    | Path to generated checklist file     |

Do NOT pass: session-wide context, other tasks' info, or session.json.

If bdd-coder reports `BLOCKED`:

1. Collect the blocking issues from the bdd-coder report.
2. Report to the user with the exact CRITICAL findings and the affected task ID.
3. Wait for one of the following user instructions:
   - Fix and retry: user provides guidance → re-run bdd-coder Phase 3–7 for the same task.
   - Skip task: user decides to defer → mark task as `SKIPPED` and continue with the next task.
   - Abort session: user stops work → end the session and summarize open blockers.

Do NOT proceed to the next task while any task remains `BLOCKED`.

### Phase 4: Quality Gate

Run the global gates, then the code review. Both must be satisfied before Phase 5.

| Gate       | Must pass                                            |
| ---------- | ---------------------------------------------------- |
| Lint       | 0 errors                                             |
| Type check | 0 errors                                             |
| Tests      | ALL PASS (with coverage)                             |
| Review     | code-reviewer returns `PASS` or `PASS_WITH_WARNINGS` |

After the first three gates pass, spawn **code-reviewer ONCE** for the whole session — an
aggregate review over every file changed in Phase 3, not one invocation per task.

| Input           | Value                                                                          |
| --------------- | ------------------------------------------------------------------------------ |
| `skill_dir`     | This skill directory (absolute path)                                           |
| `local_dir`     | `DECKRD_LOCAL_DATA` (absolute path)                                            |
| `task_id`       | The Task ID of this invocation, or `N/A` for multiple tasks                    |
| `changed_files` | Implementation files from the session scope resolved below                     |
| `test_files`    | Test files from that same scope, split by the ENV PROFILE test-file convention |
| `env_profile`   | `.local/deckrd/temp/deckrd-work/env-profile.md` (Phase 0 output)               |
| `coverage_cmd`  | Coverage command from ENV PROFILE                                              |

**Session scope**, in this order:

1. The union of the `CHANGED_FILES` lists that Phase 3 collected from each bdd-coder.
2. If those lists are unavailable, every working-tree change minus the SESSION BASELINE
   captured in Phase 0.

Never send the raw working-tree diff.
理由と "every working-tree change" の定義: [workflow.md](references/workflow.md) — Phase 4。

The per-task CRAP gate and the Phase 4 CRAP gate are intentionally separate.
Do not remove either as a duplicate. 理由: [workflow.md](references/workflow.md) — Phase 4。

Checklist items, CRAP thresholds, and failure handling: [workflow.md](references/workflow.md) — Phase 4.
Role: [roles/code-reviewer.md](references/roles/code-reviewer.md).

The same review is available on demand as `/bdd-coder:bdd-coder-review`; inside this flow it runs here.

#### Where review findings go

| Verdict              | Handling                                                                                                                                                                                            |
| -------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `PASS`               | Proceed to Phase 5                                                                                                                                                                                  |
| `PASS_WITH_WARNINGS` | Proceed to Phase 5 and include the findings in the Step 5 report block. Do NOT retroactively rewrite Phase 3 statuses or `tasks.md` checkboxes — Phase 5's source of truth stays the Phase 3 report |
| `BLOCKED`            | Do NOT proceed to Phase 5. Present the CRITICAL findings and follow the Phase 3 `BLOCKED` handling (fix and retry / skip / abort)                                                                   |

### Phase 5: Done Check — Task Status Write-back

After all bdd-coder instances in Phase 3 report `DONE` or `DONE_WITH_CONCERNS`,
and Phase 4 quality gate passes, write the implementation status back to the task files.

#### Step 1: Determine per-case completion status

The source of truth is the **Phase 3 status report table** — not the checkbox state of
any file. 理由: [workflow.md](references/workflow.md) — Phase 5。

| Phase 3 status                 | Case result                 |
| ------------------------------ | --------------------------- |
| `DONE` / `DONE_WITH_CONCERNS`  | completed — check it        |
| `BLOCKED` / `SKIPPED` / absent | not completed — leave as is |

Checklist-file items (`[T-XX-YY-ZZ-R]`, `-G`, `-F`) may be read as corroboration,
but MUST NOT override the Phase 3 report: a case reported `DONE` is checked even when
the checklist file still shows `[ ]`.

#### Step 2: Check case checkboxes in tasks.md (Task ID input only)

If the session was started with a Task ID (e.g. `T01-02`), update the `tasks.md`
resolved in Phase 1 (`docs/.deckrd/<namespace>/<module>/tasks/tasks.md`):

1. For each completed case ID from Step 1, normalize it to the canonical
   `T-XX-YY-ZZ` form, then locate its line
   `- [ ] **T-XX-YY-ZZ**: <description>`.
   An invocation-form ID (`T01-02`) names a Scenario, not a case: it covers every
   case line under `T-01-02`.
2. Replace the checkbox marker only: `- [ ]` becomes `- [x]`.
   Leave the description and the `Target` / `Scenario` / `Expected` lines untouched.
3. A line already marked `- [x]` stays as is — the write-back is idempotent.
4. If a completed case ID has no matching line in `tasks.md`, skip it and report it in Step 5.

書式: [write-back-format.md](references/write-back-format.md) — Step 2。

#### Step 3: Recalculate Task Summary from the checkboxes

Update the **Task Summary** table at the top of `tasks.md` for the Test Targets
implemented in this invocation ONLY. Leave every other row untouched — a row set by
hand, or one another session is working on, MUST NOT be recomputed.

For each such Test Target `T-XX`, count its case lines `**T-XX-YY-ZZ**` in `tasks.md`:

| Checked cases | Status                                                    |
| ------------- | --------------------------------------------------------- |
| all           | `done`                                                    |
| some          | `in progress`                                             |
| none          | leave the current Status unchanged (do not write it back) |

書式と `none` 行の意味: [write-back-format.md](references/write-back-format.md) — Step 3、
[workflow.md](references/workflow.md) — Phase 5。

Do NOT modify any part of `tasks.md` other than the case checkbox markers (Step 2)
and the Status column of the affected Test Targets (Step 3).

#### Step 4: Write back to checklist file (all inputs)

Regardless of input type, also update the checklist file:

1. Open `.local/deckrd/temp/tasks/<slug>-<adjective>-checklist.md`
2. For every case reported `DONE` / `DONE_WITH_CONCERNS` in Phase 3, confirm its
   `-R` / `-G` / `-F` items are `[x]`. Check any the bdd-coder instance left behind,
   and list them in the Step 5 report so the gap is visible.
3. Check the Scenario and Target refactor items — these belong to this phase, not to
   the bdd-coder instances, which each see only one Case:
   - `[T-XX-YY-TF]` — when every Case under Scenario `T-XX-YY` has `-R` / `-G` / `-F` at `[x]`
   - `[T-XX-CF]` — when every Scenario under Target `T-XX` has its `-TF` at `[x]`
   - A gate that does not hold yet is normal, not an error: leave the item unchecked
4. In the frontmatter, set `status` of the corresponding Test Target:
   - If the file has a per-target status field, update it
   - If not, add a comment line below the target heading:
     `<!-- status: done -->` or `<!-- status: in-progress -->`

#### Step 4b: Write back to the task list (TASKLIST PATH only)

Run this step only when Phase 1 used a task list (Phase 1a ran, or `--tasklist` was given).

1. Open TASKLIST PATH and find the item selected in Phase 1a.
2. If every case of this invocation is completed in Step 1, change the item checkbox to `- [x]`
   and its `Status:` to `done`. Otherwise leave the item as is.
3. Do not touch any other item.
4. In the Step 5 report, add `NEXT: <next pending item ID> → <Handoff>`, or `NEXT: none`,
   and the command to continue: `/bdd-coder:bdd-coder --tasklist <TASKLIST PATH>`.

#### Step 4c: Update the session entry

If every case of this invocation is completed in Step 1, set `status: done` in the
[session entry](#session-entry). Otherwise leave it `in-progress`, and add the command to continue
to the Step 5 report: `/bdd-coder:bdd-coder --resume`.

#### Step 5: Report to user

After all write-backs complete, output the STATUS WRITE-BACK and CHECKLIST BACKFILL blocks.

書式: [write-back-format.md](references/write-back-format.md) — Step 5。

## References

- Usage and invocation examples: [workflow.md](references/workflow.md) — Usage
- Full phase details: [workflow.md](references/workflow.md)
- Write-back formats: [write-back-format.md](references/write-back-format.md)
- Error recovery: [troubleshooting.md](references/troubleshooting.md)
- Q&A: [faq.md](references/faq.md)
- BDD implementer: [roles/implementer.md](references/roles/implementer.md)
- Code reviewer: [roles/code-reviewer.md](references/roles/code-reviewer.md)
- Environment explorer: [roles/explorer.md](references/roles/explorer.md)
- On-demand review command: [bdd-coder-review/SKILL.md](../bdd-coder-review/SKILL.md)
- Task list builder: [roles/tasklist-builder.md](references/roles/tasklist-builder.md)
- Task list template: [assets/templates/tasklist.tpl.md](assets/templates/tasklist.tpl.md)
- Checklist builder: [roles/checklist-builder.md](references/roles/checklist-builder.md)
- Checklist template: [assets/templates/implementation-checklist.tpl.md](assets/templates/implementation-checklist.tpl.md)
