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
  version: 0.6.1
  license: MIT
---

<!-- markdownlint-disable line-length -->

# Deckrd

Goals → Requirements → Specifications → Implementation → Tasks

`<DECKRD_SKILL_DIR>` is a placeholder.
It is neither a shell variable nor an agent-specific substitution.
It means the absolute path of the directory containing this `SKILL.md`.
Use the path you loaded this file from.

Reference files run scripts as `bash "<DECKRD_SKILL_DIR>/scripts/..."`.
Replace the placeholder with that absolute path first.
No environment variable is needed.
The scripts resolve their own root from `BASH_SOURCE`.

## Roles and Subagents

Reference files say "Spawn **explore-agent**".
Its procedure is the Role [`references/roles/explorer.md`](references/roles/explorer.md).
The Role sits inside this skill directory.
A standalone install (`npx skills add`, `gh skill install`) therefore keeps it.

- If you can start a subagent, hand it the Role file and let it run.
- If you cannot, follow the same Role file yourself, step by step, in the main session:

1. Read `references/roles/explorer.md`.
   Use the `scope`, `directory`, `module` and `focus` given in the reference file.
2. Survey the project with Read, Grep and Glob (read-only).
3. Write the findings to the output file the reference file names.
   Example: `.local/deckrd/temp/deckrd-work/codebase-context.md`.
   Then use its Summary as usual.
4. Where the reference file says "non-blocking", finish the survey first.
   There is no background agent.

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
| req–tasks        | dr --add     | [commands/dr.md](references/commands/dr.md)         |
| any (DRs exist)  | dr --refine  | [commands/dr.md](references/commands/dr.md)         |
| init completed   | rev          | [commands/rev.md](references/commands/rev.md)       |
| any              | status       | [commands/status.md](references/commands/status.md) |

Gate Rule: each command requires the previous command's document. No skipping.

> `spec --phase <slug>` re-runs a single spec phase and is exempt from the order gate. See [commands/spec.md](references/commands/spec.md).
> `project` is project-scoped and can run any time. See [commands/project.md](references/commands/project.md).
> `update` refreshes deployed assets and can run any time after `init`. See [commands/update.md](references/commands/update.md).
> Full command list: [commands/index.md](references/commands/index.md)
> Workflow overview: [workflow.md](references/workflow.md) — 経路を選ぶとき、呼び出し例を見たいとき
> Session management: [session.md](references/session.md)
> DR writing guideline: [guidelines/decision-record-authoring.md](references/guidelines/decision-record-authoring.md) — DR を書く・レビューするとき
> Troubleshooting: [troubleshooting.md](references/troubleshooting.md) — コマンドが失敗した / 順序ゲートに弾かれたとき
