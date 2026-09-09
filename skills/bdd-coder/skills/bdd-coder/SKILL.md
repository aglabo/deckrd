---
name: bdd-coder
description: >
  BDD-style implementation agent. Use when the user gives ANY coding instruction —
  natural-language, explicit Task ID, or custom task list.
  Always spawns checklist-builder first to generate a checklist, then runs BDD implementation.
  Examples: "implement X", "add function Y", "create Z", "write code for W",
  "implement task T01-02", "run bdd-coder", "start BDD implementation".
  Do NOT commit or push — implementation only, no git operations.
  Do NOT implement multiple tasks in one invocation — one task per call.
metadata:
  author: aglabo
  version: 0.6.0
  license: MIT
---

<!-- textlint-disable
  ja-technical-writing/sentence-length -->

# bdd-coder

Implements tasks using strict BDD: Red → Green → Refactor.
Always generates a checklist first via checklist-builder, then delegates BDD implementation to bdd-coder.

## Skill Announcement (REQUIRED)

Before every phase, YOU MUST output:

> "I am executing /bdd-coder:bdd-coder [TASK_ID] — Phase [N]: [Phase Name]."

No announcement = violation. Restart with announcement.

## Before You Begin (REQUIRED)

Raise ALL questions before writing any code. Ask NOW if any of the following are unclear:

- Task scope or acceptance criteria
- Ambiguous specs
- Implementation approach or dependencies

Once Phase 1 (Checklist Build) starts, stop asking scope questions.

## Usage

```bash
# Natural-language instruction
"グリーティング関数を実装して"
"implement config file parser"

# Explicit Task ID (from tasks.md)
/bdd-coder:bdd-coder T01-02
/bdd-coder:bdd-coder T01-02 --checklist <path>   # skip checklist-builder, use existing checklist
```

## Execution Flow

bdd-coder is an orchestration layer with the following fixed phase order:

| Phase | Name               | Agent                     | What happens                                                                   |
| ----- | ------------------ | ------------------------- | ------------------------------------------------------------------------------ |
| 0     | Environment        | explore-agent             | Detect language, test framework, lint, type-check setup                        |
| 1     | Checklist Build    | checklist-builder         | Generate checklist from instruction or Task ID                                 |
| 2     | Dependency Map     | bdd-coder                 | Classify checklist tasks into serial / parallel groups                         |
| 3     | bdd-coder Dispatch | bdd-coder                 | Spawn bdd-coder per task; collect status reports                               |
| 4     | Quality Gate       | bdd-coder + code-reviewer | Global lint + type-check + all tests pass, then code review                    |
| 5     | Done Check         | bdd-coder                 | Confirm all checklist items complete; check off tasks.md and write back status |
| 6     | Session End        | bdd-coder                 | Reset state; remind user to commit manually                                    |

Gate Rule: phases must run in order. No skipping.

All tests MUST pass at Phase 4. No exceptions.
Do NOT commit after completion — user commits manually.

### Phase 1: Checklist Build

Always spawn **checklist-builder** with the user's instruction or Task ID.

| Input type            | checklist-builder behavior                                    |
| --------------------- | ------------------------------------------------------------- |
| Natural-language      | Analyze instruction, decompose into BDD tasks, generate file  |
| Task ID (e.g. T01-02) | Read tasks.md entry, expand into BDD checklist, generate file |
| `--checklist <path>`  | Skip checklist-builder, use the specified existing file       |

Output: `temp/tasks/<slug>-<adjective>-checklist.md`

### Phase 3: bdd-coder Dispatch

Pass the following context to each bdd-coder instance:

| Item              | Content                             |
| ----------------- | ----------------------------------- |
| Task ID           | e.g. `T-01-02-01`                   |
| Task description  | Full Given/When/Then from checklist |
| Quality gate cmds | Commands table from ENV PROFILE     |
| Checklist path    | Path to generated checklist file    |

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

| Input           | Value                                                                                          |
| --------------- | ---------------------------------------------------------------------------------------------- |
| `task_id`       | The Task ID of this invocation, or `N/A` for multiple tasks                                    |
| `changed_files` | Implementation files in the working-tree diff (`git diff --name-only`, merged with `--cached`) |
| `test_files`    | Test files from that same diff, split by the ENV PROFILE test-file convention                  |
| `env_profile`   | `temp/deckrd-work/env-profile.md` (Phase 0 output)                                             |
| `coverage_cmd`  | Coverage command from ENV PROFILE                                                              |

Checklist items, CRAP thresholds, and failure handling: [workflow.md](references/workflow.md) — Phase 4.
Agent definition: [agents/code-reviewer.md](../../agents/code-reviewer.md).

The same review is available on demand as `/bdd-coder:bdd-coder-review`; inside this flow it runs here.

The per-task CRAP gate in [agents/bdd-coder.md](../../agents/bdd-coder.md) is the implementer's
own gate over one task. Phase 4 recomputes CRAP across the aggregate diff. The two are
intentionally separate — do not remove either as a duplicate.

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
any file. Nothing updates `tasks.md` before this phase, so deciding completion from its
checkboxes would always yield `in progress`. The checklist file IS updated per step by
each bdd-coder instance, but a run that ended early can leave it behind the reports.

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

```markdown
- [x] **T-01-01-01**: <description>
  - Target: `<function>`
  - Scenario: Given <precondition>, When <action>
  - Expected: Then <assertion>
```

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

The `none` row matters when every case came back `BLOCKED`: a target already marked
`in progress` MUST NOT be regressed to `pending`.

```markdown
## Task Summary

| Test Target  | Scenarios | Cases | Status      |
| ------------ | --------- | ----- | ----------- |
| T-01: <name> | N         | M     | done        |
| T-02: <name> | N         | M     | in progress |
```

Do NOT modify any part of `tasks.md` other than the case checkbox markers (Step 2)
and the Status column of the affected Test Targets (Step 3).

#### Step 4: Write back to checklist file (all inputs)

Regardless of input type, also update the checklist file:

1. Open `temp/tasks/<slug>-<adjective>-checklist.md`
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

#### Step 5: Report to user

After all write-backs complete, output:

```text
STATUS WRITE-BACK (tasks.md):
  T-01-01-01  [x]
  T-01-01-02  [x]
  T-01: done        (2/2 cases checked)
  T-02: in progress (1/3 cases checked — 2 cases remain)
  T-03-01-01  not found in tasks.md — skipped

CHECKLIST BACKFILL:
  T-01-01-02-F  [x]  (left unchecked by the bdd-coder instance)
```

## References

- Full phase details: [workflow.md](references/workflow.md)
- Error recovery: [troubleshooting.md](references/troubleshooting.md)
- Q&A: [faq.md](references/faq.md)
- BDD sub-agent: [agents/bdd-coder.md](../../agents/bdd-coder.md)
- Code reviewer: [agents/code-reviewer.md](../../agents/code-reviewer.md)
- On-demand review command: [bdd-coder-review/SKILL.md](../bdd-coder-review/SKILL.md)
- Checklist builder: [agents/checklist-builder.md](../../agents/checklist-builder.md)
- Checklist template: [assets/templates/implementation-checklist.tpl.md](assets/templates/implementation-checklist.tpl.md)

## Examples

**Natural-language instruction:**

> "グリーティング関数を実装して"
> → checklist-builder が `temp/tasks/add-greeting-function-calm-checklist.md` を生成 → bdd-coder で実装

**Task ID from tasks.md:**

> "T01-02 を実装して"
> → checklist-builder が tasks.md の T01-02 からチェックリストを生成 → bdd-coder で実装

**Existing checklist (skip checklist-builder):**

> `/bdd-coder:bdd-coder T01-02 --checklist temp/tasks/my-happy-checklist.md`
> → 既存チェックリストをそのまま使用 → bdd-coder で実装

## Troubleshooting

**tasks.md not found when Task ID specified**
Cause: `/deckrd tasks` has not been run yet.
Solution: Complete the full deckrd flow first: `req` → `spec` → `impl` → `tasks`.
Or give a natural-language instruction instead — checklist-builder works without tasks.md.

**Tests failing at Phase 4**
Cause: bdd-coder implementation is incomplete or incorrect.
Solution: Return to Phase 3, re-dispatch bdd-coder for the failing task. Do not skip Phase 4.

**Phase skipped accidentally**
Cause: Announcement not made before a phase.
Solution: Restart from the beginning with proper announcements.
