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
  version: 0.4.0
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

| Phase | Name               | Agent             | What happens                                                          |
| ----- | ------------------ | ----------------- | --------------------------------------------------------------------- |
| 0     | Environment        | explore-agent     | Detect language, test framework, lint, type-check setup               |
| 1     | Checklist Build    | checklist-builder | Generate checklist from instruction or Task ID                        |
| 2     | Dependency Map     | bdd-coder         | Classify checklist tasks into serial / parallel groups                |
| 3     | bdd-coder Dispatch | bdd-coder         | Spawn bdd-coder per task; collect status reports                      |
| 4     | Quality Gate       | bdd-coder         | Global lint + type-check + all tests pass                             |
| 5     | Done Check         | bdd-coder         | Confirm all checklist items complete; write back status to task files |
| 6     | Session End        | bdd-coder         | Reset state; remind user to commit manually                           |

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
   - **Fix and retry**: user provides guidance → re-run bdd-coder Phase 3–7 for the same task.
   - **Skip task**: user decides to defer → mark task as `SKIPPED` and continue with the next task.
   - **Abort session**: user stops work → end the session and summarize open blockers.

Do NOT proceed to the next task while any task remains `BLOCKED`.

### Phase 5: Done Check — Task Status Write-back

After all bdd-coder instances in Phase 3 report `DONE` or `DONE_WITH_CONCERNS`,
and Phase 4 quality gate passes, write the implementation status back to the task files.

#### Step 1: Check each Test Target

For each Test Target (T-01, T-02, ...) that was implemented in this session:

1. Read the checklist file at `temp/tasks/<slug>-checklist.md`
2. Locate all checklist items under the Test Target (T-XX):
   - In tasks.md: all Case checkboxes `- [ ] **T-XX-YY-ZZ**`
   - In checklist file: all phase items `[T-XX-YY-ZZ-R]`, `[T-XX-YY-ZZ-G]`, `[T-XX-YY-ZZ-F]`,
     `[T-XX-YY-ZZ-TF]` (per Scenario), and `[T-XX-CF]`
3. Determine status:
   - All items checked (`[x]`) → status = `done`
   - Any item unchecked (`[ ]`) → status = `in-progress`

#### Step 2: Write back to tasks.md (Task ID input only)

If the session was started with a Task ID (e.g. `T01-02`), update `tasks.md`:

1. Locate the **Task Summary** table at the top of `tasks.md`
2. Find the row for the implemented Test Target (e.g. `T-01`)
3. Update the `Status` column:
   - `done` → write `done`
   - `in-progress` → write `in-progress`

```markdown
## Task Summary

| Test Target  | Scenarios | Cases | Status      |
| ------------ | --------- | ----- | ----------- |
| T-01: <name> | N         | M     | done        |
| T-02: <name> | N         | M     | in-progress |
```

Do NOT modify any other part of `tasks.md`.

#### Step 3: Write back to checklist file (all inputs)

Regardless of input type, also update the checklist file header:

1. Open `temp/tasks/<slug>-checklist.md`
2. In the frontmatter, set `status` of the corresponding Test Target:
   - If the file has a per-target status field, update it
   - If not, add a comment line below the target heading:
     `<!-- status: done -->` or `<!-- status: in-progress -->`

#### Step 4: Report to user

After all write-backs complete, output:

```text
STATUS WRITE-BACK:
  T-01: done        (N/N items checked)
  T-02: in-progress (M/N items checked — K items remain)
```

## References

- Full phase details: [workflow.md](references/workflow.md)
- Error recovery: [troubleshooting.md](references/troubleshooting.md)
- Q&A: [faq.md](references/faq.md)
- BDD sub-agent: [agents/bdd-coder.md](../../agents/bdd-coder.md)
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

> `/bdd-coder:bdd-coder T01-02 --checklist temp/tasks/my-checklist.md`
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
