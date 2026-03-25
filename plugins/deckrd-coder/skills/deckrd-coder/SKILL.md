---
name: deckrd-coder
description: >
  BDD-style task implementation agent for Deckrd sessions.
  Use when the user gives ANY coding instruction — natural-language or explicit Task ID.
  Always spawns checklist-builder first to generate a checklist, then runs BDD implementation.
  Examples: "implement X", "add function Y", "create Z", "write code for W",
  "implement task T01-02", "run deckrd-coder", "start BDD implementation".
  Do NOT commit or push — implementation only, no git operations.
  Do NOT implement multiple tasks in one invocation — one task per call.
metadata:
  author: aglabo
  version: 0.1.0
  license: MIT
---

# deckrd-coder

Implements tasks using strict BDD: Red → Green → Refactor.
Always generates a checklist first via checklist-builder, then delegates BDD implementation to bdd-coder.

## Skill Announcement (REQUIRED)

Before every phase, YOU MUST output:

> "I am executing /deckrd-coder [TASK_ID] — Phase [N]: [Phase Name]."

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
/deckrd-coder T01-02
/deckrd-coder T01-02 --checklist <path>   # skip checklist-builder, use existing checklist
```

## Execution Flow

deckrd-coder is an orchestration layer with the following fixed phase order:

| Phase | Name               | Agent             | What happens                                            |
| ----- | ------------------ | ----------------- | ------------------------------------------------------- |
| 0     | Environment        | explore-agent     | Detect language, test framework, lint, type-check setup |
| 1     | Checklist Build    | checklist-builder | Generate checklist from instruction or Task ID          |
| 2     | Dependency Map     | deckrd-coder      | Classify checklist tasks into serial / parallel groups  |
| 3     | bdd-coder Dispatch | bdd-coder         | Spawn bdd-coder per task; collect status reports        |
| 4     | Quality Gate       | deckrd-coder      | Global lint + type-check + all tests pass               |
| 5     | Done Check         | deckrd-coder      | Confirm all checklist items complete                    |
| 6     | Session End        | deckrd-coder      | Reset state; remind user to commit manually             |

Gate Rule: phases must run in order. No skipping.

All tests MUST pass at Phase 4. No exceptions.
Do NOT commit after completion — user commits manually.

### Phase 1: Checklist Build

Always spawn **checklist-builder** with the user's instruction or Task ID.

| Input type           | checklist-builder behavior                                      |
| -------------------- | --------------------------------------------------------------- |
| Natural-language     | Analyze instruction, decompose into BDD tasks, generate file    |
| Task ID (e.g. T01-02) | Read tasks.md entry, expand into BDD checklist, generate file  |
| `--checklist <path>` | Skip checklist-builder, use the specified existing file         |

Output: `temp/tasks/<slug>-<adjective>-checklist.md`

### Phase 3: bdd-coder Dispatch

Pass the following context to each bdd-coder instance:

| Item              | Content                                      |
| ----------------- | -------------------------------------------- |
| Task ID           | e.g. `T-01-02-01`                            |
| Task description  | Full Given/When/Then from checklist          |
| Quality gate cmds | Commands table from ENV PROFILE              |
| Checklist path    | Path to generated checklist file             |

Do NOT pass: session-wide context, other tasks' info, or session.json.

If bdd-coder reports `BLOCKED`: stop, report to user, wait for instruction.

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

> `/deckrd-coder T01-02 --checklist temp/tasks/my-checklist.md`
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
