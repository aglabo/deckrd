---
name: deckrd
description: >
  Document-driven framework that derives requirements, specifications, implementation plans,
  and executable tasks from goals through structured AI dialogue.
  Use when user says "write requirements", "create spec", "plan implementation",
  "derive tasks", "structure this feature", "break down into tasks", or "document this module".
  Also use for reverse engineering existing code into docs (/deckrd rev)
  or for lightweight quick changes (/deckrd quick).
  Do NOT use for direct code writing — use /deckrd-coder after tasks are generated.
  Do NOT use when the user only wants to run or fix existing code without planning.
metadata:
  author: aglabo
  version: 0.1.0
  license: MIT
---

<!-- markdownlint-disable line-length -->

# Deckrd

Goals → Requirements → Specifications → Implementation → Tasks

## Skill Announcement (REQUIRED)

Before every command, YOU MUST output:

> "I am executing /deckrd [COMMAND] for module [MODULE_NAME]."

No announcement = violation. Restart with announcement.

## Before Every Command (REQUIRED)

1. Read `.local/deckrd/session.json` — confirm active module and current step
2. Validate command order — if out of order, STOP and report
3. Load the reference listed below — NEVER proceed without it

**Reference selection:**

| Current State    | Next Command | Reference                                           |
| ---------------- | ------------ | --------------------------------------------------- |
| (none)           | init         | [commands/init.md](references/commands/init.md)     |
| init completed   | module       | [commands/module.md](references/commands/module.md) |
| module completed | req          | [commands/req.md](references/commands/req.md)       |
| req completed    | spec         | [commands/spec.md](references/commands/spec.md)     |
| spec completed   | impl         | [commands/impl.md](references/commands/impl.md)     |
| impl completed   | tasks        | [commands/tasks.md](references/commands/tasks.md)   |
| any              | review       | [commands/review.md](references/commands/review.md) |
| init completed   | rev          | [commands/rev.md](references/commands/rev.md)       |

Gate Rule: each command requires the previous command's document. No skipping.

> `project` is project-scoped and can run any time. See [commands/project.md](references/commands/project.md).
> Full command list: [commands/index.md](references/commands/index.md)
> Workflow overview: [workflow.md](references/workflow.md)
> Session management: [session.md](references/session.md)

## Examples

**New feature from goals:**

> "I want to add a retry mechanism to the HTTP client."
> → `/deckrd init my-project/http-retry` → `req` → `spec` → `impl` → `tasks`

**Existing code, no docs:**

> "This module has no documentation. Reverse-engineer it."
> → `/deckrd rev --to req` → `spec` → `impl` → `tasks`

**Small bug fix:**

> "Fix the off-by-one error in the pagination logic."
> → `/deckrd quick "Fix off-by-one in pagination"`

## Troubleshooting

**Session not found**
Cause: `init` has not been run, or wrong directory.
Solution: Run `/deckrd init <project> <project-type>` first.

**Command out of order**
Cause: Trying to run `spec` before `req`, etc.
Solution: Check `/deckrd status` to see the current step, then run the correct next command.

**Gate Rule violation**
Cause: Required document from previous step is missing.
Solution: Complete the missing step before proceeding. Use `/deckrd status` to confirm.
