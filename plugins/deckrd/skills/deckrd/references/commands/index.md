---
title: Command Index
description: Reference table of all deckrd commands
---

## Command Index

<!-- markdownlint-disable line-length -->

## Standard Flow

| Command                         | Description                                                                     |
| ------------------------------- | ------------------------------------------------------------------------------- |
| `init <project> <project-type>` | Bootstrap project, write project.json, init session                             |
| `module <ns>/<mod>`             | Create module directories, set active module                                    |
| `module <ns>/<mod> --force`     | Re-initialize module (existing files preserved)                                 |
| `module create <ns>/<mod>`      | Create module dirs and update session, set active                               |
| `module create <mod>`           | Same; subdomain auto-resolved from git remote name                              |
| `req`                           | Derive requirements from goals                                                  |
| `dr`                            | Manage Decision Records (any step)                                              |
| `dr --add`                      | Append a new Decision Record                                                    |
| `spec`                          | Derive specifications from requirements                                         |
| `impl`                          | Derive implementation plan from specifications                                  |
| `tasks`                         | Derive executable tasks from implementation; with `implementation-checklist.md` |
| `tasks update`                  | Regenerate `implementation-checklist.md` from existing `tasks.md`               |

## Alternative Paths

| Command                                           | Description                                                        |
| ------------------------------------------------- | ------------------------------------------------------------------ |
| `rev [--from code] [--to req\|spec\|impl\|tasks]` | Reverse-engineer existing code into deckrd documentation artifacts |

## Utility

| Command                                      | Description                                  |
| -------------------------------------------- | -------------------------------------------- |
| `status`                                     | Display current workflow progress and status |
| `review`                                     | Show review command usage                    |
| `review <doc> [--phase <p>]`                 | Review document with phase-specific analysis |
| `project --project <name> --language <lang>` | Configure project settings                   |
