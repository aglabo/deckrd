---
name: bdd-coder
description: >
  Implements code with strict BDD (Red-Green-Refactor).
  - Use for any coding instruction: natural language, Task ID (T01-02), or a task list
  - One task per delegation; a range (T01-01..03) or all Scenarios of a Target (T01-*) runs its tasks one by one
  - Never commits or pushes
license: MIT
metadata:
  author: aglabo
  version: 0.10.1
---

<!-- textlint-disable
  ja-technical-writing/sentence-length,
  ja-technical-writing/max-comma -->

# bdd-coder

Orchestrates strict BDD (Red → Green → Refactor) for any coding instruction:
resolve one task, build its checklist, delegate the implementation, verify, and write the results back.

## Skill Announcement (REQUIRED)

Before every phase, YOU MUST output:

> "I am executing /bdd-coder:bdd-coder [TASK_ID] — Phase [N]: [Phase Name]."

No announcement = violation. Restart with announcement.

## Before You Begin (REQUIRED)

Before Phase 0, ask all questions in one message if any of these are unclear:
task scope or acceptance criteria, specs, implementation approach, or dependencies.

Once Phase 1 starts, stop asking scope questions.
Choosing which task-list item to run is not a scope question and is asked in Phase 1a.

## Execution Flow

Phases run in this order. No skipping.
Read [workflow.md](references/workflow.md) first, then **Read a phase's file before you enter it**.
Do not run a phase from memory.

| Phase | Name                               | Agent                                | Procedure                                                        |
| ----- | ---------------------------------- | ------------------------------------ | ---------------------------------------------------------------- |
| 0     | Environment                        | explore-agent                        | [workflow.md](references/workflow.md)                            |
| 1     | Tasklist Resolve + Checklist Build | tasklist-builder + checklist-builder | [tasklist-checklist.md](references/phases/tasklist-checklist.md) |
| 2     | Dependency Map                     | (this skill)                         | [workflow.md](references/workflow.md)                            |
| 3     | bdd-coder Dispatch                 | bdd-coder                            | [dispatch.md](references/phases/dispatch.md)                     |
| 4     | Quality Gate                       | code-reviewer                        | [quality-gate.md](references/phases/quality-gate.md)             |
| 5     | Done Check + Write-back            | (this skill)                         | [write-back.md](references/phases/write-back.md)                 |
| 6     | Session End                        | (this skill)                         | [workflow.md](references/workflow.md)                            |

- Range (`T01-01..03`) or `T01-*`: [multi-task-run.md](references/phases/multi-task-run.md)
- Writing the session entry, or `--resume`: [session-resume.md](references/session-resume.md).
  Do not write `session.json` from memory.

## Spawning a Role

Each agent's procedure is a Role file:

- explore-agent → [explorer.md](references/roles/explorer.md)
- tasklist-builder → [tasklist-builder.md](references/roles/tasklist-builder.md)
- checklist-builder → [checklist-builder.md](references/roles/checklist-builder.md)
- bdd-coder → [implementer.md](references/roles/implementer.md)
- code-reviewer → [code-reviewer.md](references/roles/code-reviewer.md)

On every "Spawn", also pass two absolute paths. The Role resolves every path from them (`temp` is `<local_dir>/temp`).

- `skill_dir`: this skill directory, the one that holds this `SKILL.md`.
- `local_dir`: the value of `DECKRD_LOCAL_DATA` (`.local/deckrd` under the project root).

If you can start a subagent, hand it these paths and the Role file. If you cannot, follow the same Role file
yourself, step by step.

## Invariants

- One task per delegation. Several tasks in one invocation run one after another, one delegation each.
- The dispatch unit is one Target; each Case keeps its own RED → GREEN → REFACTOR cycle.
- All tests MUST pass at Phase 4. No exceptions.
- Never commit or push. The user commits manually.
- Branches are prepared by the caller: one task branch per Target (`T-XX`), cut from the integration branch.

## Test ID checks

```bash
bash "<BDD_CODER_SKILL_DIR>/scripts/check-test-ids.sh" --lang <lang>[,<lang>...]
```

`<lang>` is each language of the target repository's tests (`sh` / `dart` / `ts` / `js` / `go`);
without `--lang`, only `sh` is checked. See [test-id-check.md](references/test-id-check.md).
Check the target abbreviations with `check-test-abbrs.sh` ([test-abbr-check.md](references/test-abbr-check.md)).

## Related

The same review as Phase 4 is available on demand: [bdd-coder-review](../bdd-coder-review/SKILL.md).
