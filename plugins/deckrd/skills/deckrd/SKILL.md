---
name: deckrd
description: "Use when structuring requirements, specifications, or tasks. Enforces stepwise derivation and phase integrity."
---

<!-- textlint-disable
  ja-technical-writing/sentence-length,
  ja-technical-writing/max-comma -->
<!-- markdownlint-disable line-length -->

# Deckrd - Your Goals to Tasks framework

Deckrd is a document-centered framework for structuring and refining ideas through iterative discussion with AI.
It guides the creation of requirements, decisions, specifications, and implementation plans as derived documents, not final outputs.
Each document captures reasoning at a specific stage, preserving context and intent.
Through a strict, state-driven workflow, these documents are progressively shaped into executable development tasks.
Deckrd enables documentation to function as a practical engine for action, not just description.

## Commands

| Command                                      | Description                                                                              |
| -------------------------------------------- | ---------------------------------------------------------------------------------------- |
| `init <project> <project-type>`              | Bootstrap project, write profile.json, init session                                      |
| `module <ns>/<mod>`                          | Create module directories, set active module                                             |
| `module <ns>/<mod> --force`                  | Re-initialize module (existing files preserved)                                          |
| `module create <ns>/<mod>`                   | Create module with `.profile.json`, set active                                           |
| `module create <mod>`                        | Same; subdomain auto-resolved from git remote name                                       |
| `req`                                        | Derive requirements from goals                                                           |
| `dr`                                         | Manage Decision Records (req step only)                                                  |
| `dr --add`                                   | Append a new Decision Record                                                             |
| `spec`                                       | Derive specifications from requirements                                                  |
| `impl`                                       | Derive implementation plan from specifications                                           |
| `tasks`                                      | Derive executable tasks from implementation; auto-generate `implementation-checklist.md` |
| `tasks update`                               | Regenerate `implementation-checklist.md` from existing `tasks.md`                        |
| `status`                                     | Display current workflow progress and status                                             |
| `review`                                     | Show review command usage                                                                |
| `review <doc> [--phase <p>]`                 | Review document with phase-specific analysis                                             |
| `profile --project <name> --language <lang>` | Configure project profile (language, project name)                                       |

## Skill Announcement (REQUIRED)

YOU MUST announce at the start of every command execution:

> "I am executing /deckrd [COMMAND] for module [MODULE_NAME]."

No announcement = violation. Restart with announcement.

---

## Session Resolution

Session state is stored in `docs/.deckrd/.session.json`.

```text
[/deckrd init <project> <project-type>]
     |  Bootstrap + profile.json + session.json
     v
[/deckrd module <ns>/<mod>]
     |  Create module dirs, set active module
     v
Goals/Ideas
     |
     v
[/deckrd req] -> requirements.md
     |
     v
[/deckrd spec] -> specifications.md
     |
     v
[/deckrd impl] -> implementation.md
     |
     v
[/deckrd tasks] -> tasks.md
     |              -> implementation-checklist.md (auto)
     |
     v
[/deckrd tasks update] -> implementation-checklist.md (regenerate)
     |
     v
[/deckrd-coder TX-XX] -> Implementation

Gate Rule: Each command REQUIRES the previous command's document.
           YOU MUST NOT skip commands. No exceptions.
```

YOU MUST execute ALL of the following before every command:

1. Read `.session.json` — YOU MUST confirm active module and current step
2. Validate command order — if out of order, STOP and report
3. Load the reference — NEVER proceed without loading it

> **Note**: The `profile` command is project-scoped and does not interact with session state.
> It can be run at any time, before or after `init`.
> Reference: [commands/profile.md](references/commands/profile.md)

**Reference selection:**

| Current State    | Next Command | Load Reference                                      |
| ---------------- | ------------ | --------------------------------------------------- |
| (none)           | init         | [commands/init.md](references/commands/init.md)     |
| init completed   | module       | [commands/module.md](references/commands/module.md) |
| module completed | req          | [commands/req.md](references/commands/req.md)       |
| req completed    | spec         | [commands/spec.md](references/commands/spec.md)     |
| spec completed   | impl         | [commands/impl.md](references/commands/impl.md)     |
| impl completed   | tasks        | [commands/tasks.md](references/commands/tasks.md)   |
| any              | review       | [commands/review.md](references/commands/review.md) |

**For workflow overview:** [workflow.md](references/workflow.md)
**For session management details:** [session.md](references/session.md)
**For status command:** [commands/status.md](references/commands/status.md)
