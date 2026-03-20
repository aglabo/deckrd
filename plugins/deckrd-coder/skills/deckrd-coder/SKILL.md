---
name: deckrd-coder
description: >
  BDD-style task implementation agent for Deckrd sessions.
  Implements one task at a time using Red-Green-Refactor cycle.
  Use when user says "implement task", "code this task", "run deckrd-coder",
  or provides a Task ID (e.g. T01-02) after /deckrd tasks has been completed.
  Also use when user says "implement the checklist" or "start BDD implementation".
  Do NOT use before /deckrd tasks is complete — tasks.md and implementation-checklist.md must exist.
  Do NOT commit or push — implementation only, no git operations.
  Do NOT implement multiple tasks in one invocation — one task per call.
metadata:
  author: aglabo
  version: 0.1.0
  license: MIT
---

# deckrd-coder

Implements one Deckrd task per call using strict BDD: Red → Green → Refactor.

## Skill Announcement (REQUIRED)

Before every phase, YOU MUST output:

> "I am executing /deckrd-coder [TASK_ID] — Phase [N]: [Phase Name]."

No announcement = violation. Restart with announcement.

## Before You Begin (REQUIRED)

Raise ALL questions before writing any code. Ask NOW if any of the following are unclear:

- Task scope or acceptance criteria
- Ambiguous specs in tasks.md
- Implementation approach or dependencies

Once Phase 3 (BDD Implementation) starts, stop asking scope questions.
Questions after Phase 3 = Before You Begin was skipped = restart from top.

## Usage

```bash
/deckrd-coder T01-02                        # default checklist
/deckrd-coder T01-02 --checklist <path>     # explicit checklist path
```

Default checklist: `tasks/implementation-checklist.md`

## Execution Flow

deckrd-coder is an orchestration layer. BDD implementation (Red → Green → Refactor) is
delegated to the **bdd-coder** agent per task.

| Phase | Name               | What happens                                            |
| ----- | ------------------ | ------------------------------------------------------- |
| 0     | Environment        | Detect language, test framework, lint, type-check setup |
| 1     | Task Info          | Read session, tasks.md, checklist for target task       |
| 2     | Dependency Map     | Classify tasks into serial / parallel execution groups  |
| 3     | bdd-coder Dispatch | Spawn bdd-coder per task; collect status reports        |
| 4     | Quality Gate       | Global lint + type-check + all tests pass               |
| 5     | Done Check         | Confirm all checklist items complete                    |
| 6     | Session End        | Reset state; remind user to commit manually             |

Gate Rule: phases must run in order. No skipping.

All tests MUST pass at Phase 4. No exceptions.
Do NOT commit after completion — user commits manually.

### bdd-coder Dispatch (Phase 3)

Pass the following context to each bdd-coder instance:

| Item              | Content                             |
| ----------------- | ----------------------------------- |
| Task ID           | e.g. `T-01-02-01`                   |
| Task description  | Full Given/When/Then from tasks.md  |
| Quality gate cmds | Commands table from ENV PROFILE     |
| Checklist path    | Path to implementation-checklist.md |

Do NOT pass: session-wide context, other tasks' info, or session.json.

If bdd-coder reports `BLOCKED`: stop, report to user, wait for instruction.

## References

- Full phase details: [workflow.md](references/workflow.md)
- Error recovery: [troubleshooting.md](references/troubleshooting.md)
- Q&A: [faq.md](references/faq.md)
- BDD sub-agent: [agents/bdd-coder.md](../../agents/bdd-coder.md)

## Examples

**Implement a single task:**

> "Implement T01-02."
> → `/deckrd-coder T01-02`

**Explicit checklist:**

> "Use the sprint checklist for T02-01."
> → `/deckrd-coder T02-01 --checklist docs/.deckrd/my-project/sprint/tasks/implementation-checklist.md`

## Troubleshooting

**tasks.md or checklist not found**
Cause: `/deckrd tasks` has not been run yet.
Solution: Complete the full deckrd flow first: `req` → `spec` → `impl` → `tasks`.

**Tests failing at Phase 4**
Cause: bdd-coder implementation is incomplete or incorrect.
Solution: Return to Phase 3, re-dispatch bdd-coder for the failing task. Do not skip Phase 4.

**Phase skipped accidentally**
Cause: Announcement not made before a phase.
Solution: Restart from the beginning with proper announcements.
