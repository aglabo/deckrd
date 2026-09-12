---
name: deckrd
description: >
  Document-driven framework that derives requirements, specifications, implementation plans,
  and executable tasks from goals through structured AI dialogue.
  Use when user says "write requirements", "create spec", "plan implementation",
  "derive tasks", "structure this feature", "break down into tasks", or "document this module".
  Also use for reverse engineering existing code into docs (/deckrd rev).
  Do NOT use for direct code writing — use /deckrd-coder after tasks are generated.
  Do NOT use when the user only wants to run or fix existing code without planning.
metadata:
  author: aglabo
  version: 0.5.0
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

> `spec --phase <slug>` re-runs a single spec phase and is exempt from the order gate. See [commands/spec.md](references/commands/spec.md).
> `project` is project-scoped and can run any time. See [commands/project.md](references/commands/project.md).
> Full command list: [commands/index.md](references/commands/index.md)
> Workflow overview: [workflow.md](references/workflow.md) — 経路を選ぶとき、呼び出し例を見たいとき
> Session management: [session.md](references/session.md)
> Troubleshooting: [troubleshooting.md](references/troubleshooting.md) — コマンドが失敗した / 順序ゲートに弾かれたとき
