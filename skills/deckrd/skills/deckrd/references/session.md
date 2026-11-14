---
title: Session Management
description: Session file location, schema, and state transition rules
---

## Session Management

## Session File Location

```bash
.local/deckrd/session.json
```

> **Note**: The `DECKRD_LOCAL_DATA` environment variable overrides the default location.
> Default: `<repo-root>/.local/deckrd`

## Session Schema

```json
{
  "active": "<namespace>/<module>",
  "lang": "ja",
  "prog": "typescript",
  "ai_model": "sonnet",
  "created_at": "2025-01-01T00:00:00Z",
  "updated_at": "2025-01-01T00:00:00Z",
  "modules": {
    "<namespace>/<module>": {
      "current_step": "spec",
      "completed": ["module", "req"],
      "documents": {
        "requirements": "requirements.md",
        "specifications": "specifications.md"
      },
      "test_scope": "NOR"
    }
  }
}
```

## Fields

| Field                    | Type   | Description                                    |
| ------------------------ | ------ | ---------------------------------------------- |
| `active`                 | string | Currently active module path                   |
| `prog`                   | string | Programming language (e.g. `typescript`, `go`) |
| `lang`                   | string | Document language (optional, default `system`) |
| `ai_model`               | string | AI model identifier (e.g. `sonnet`)            |
| `modules`                | object | Per-module session states                      |
| `modules.*.current_step` | string | Last completed step                            |
| `modules.*.completed`    | array  | All completed steps                            |
| `modules.*.documents`    | object | Generated document paths                       |
| `modules.*.test_scope`   | string | Test scope set by `module` (2-4 `A-Z0-9`)      |
| `bdd_coder`              | object | bdd-coder work in progress (optional)          |

### `prog` and `lang`

`prog` holds the programming language that `init` received with `--language`.
bdd-coder reads it to choose its language rules.
`lang` holds the document language that `generate-doc.sh` passes to the AI as `LANG:`.
When `lang` is absent, `system` is used.

Older session files stored the programming language in `lang`.
`init` (when the session already exists) and `update` move such a value to `prog`.
They do this only when `prog` is absent and `lang` is a supported programming language.
The supported values are the same as `init --language` (`bash` included).
Every other key is kept.

### `bdd_coder` (written by bdd-coder)

The bdd-coder skill adds this entry when it builds a task list or a checklist.
`/bdd-coder:bdd-coder --resume` reads it to restore an interrupted session.
deckrd commands do not read or write it. They must keep it when they rewrite `session.json`.

```json
{
  "bdd_coder": {
    "tasklist": "<local_dir>/temp/tasklist/deckrd/libs/T-01.tasklist.md",
    "item": "L-02",
    "checklist": "<local_dir>/temp/tasks/parse-config-calm-checklist.md",
    "status": "in-progress",
    "updated_at": "2026-11-09T00:00:00Z"
  }
}
```

| Field                  | Type           | Description                                  |
| ---------------------- | -------------- | -------------------------------------------- |
| `bdd_coder.tasklist`   | string \| null | Task list in use (starts with `<local_dir>`) |
| `bdd_coder.item`       | string \| null | Selected task list item (`L-XX`)             |
| `bdd_coder.checklist`  | string \| null | Checklist in use (starts with `<local_dir>`) |
| `bdd_coder.status`     | string         | `in-progress` or `done`                      |
| `bdd_coder.updated_at` | string         | UTC timestamp of the last write              |

Write rules and the resume procedure: bdd-coder `SKILL.md`, "Session entry" and "Resume".

## State Transitions

```bash
# init is a prerequisite (not a tracked step)
(none) ──module──> module ──req──> req ──spec──> spec ──impl──> impl ──tasks──> tasks
                                    │            │            │            │
                                    └────────────┴─────dr─────┴────────────┘
                                         (stays in the current step, append-only DRs)
```

Note: The `dr` command does NOT advance the step.
`dr --add` appends Decision Records while remaining in the current step.
It is allowed in `req`, `spec`, `impl` and `tasks`.

## Session Operations

### Create Session (init command)

```json
{
  "active": null,
  "prog": "typescript",
  "ai_model": "sonnet",
  "modules": {},
  "created_at": "2025-01-01T00:00:00Z",
  "updated_at": "2025-01-01T00:00:00Z"
}
```

### After module command

```json
{
  "active": "agt-kind/is-collection",
  "prog": "typescript",
  "ai_model": "sonnet",
  "modules": {
    "agt-kind/is-collection": {
      "current_step": "module",
      "completed": ["module"],
      "documents": {},
      "test_scope": "IC"
    }
  }
}
```

### Update Session (after each command)

After `req` command:

```json
{
  "active": "agt-kind/is-collection",
  "prog": "typescript",
  "ai_model": "sonnet",
  "modules": {
    "agt-kind/is-collection": {
      "current_step": "req",
      "completed": ["module", "req"],
      "documents": {
        "requirements": "requirements.md"
      }
    }
  }
}
```

### Switch Active Module

To work on a different module:

```bash
/deckrd module <other-namespace>/<other-module>
```

`module` creates a new module and makes it active.
It fails if the module directory already exists.

`module --force` is not a way to resume a module.
It resets the module's session entry, so the recorded progress is lost:

- `current_step` becomes `"module"`
- `completed` becomes `["module"]`
- `documents` becomes `{}`

The existing files and `module.md` are kept.
There is no command that only switches `active` without resetting the module.

## Document Path Resolution

For the active module, documents are located at:

```bash
${DECKRD_DOCS_DIR}/<namespace>/<module>/<document-type>/<filename>
```

`DECKRD_DOCS_DIR` is exported by `bootstrap.lib.sh`. `DECKRD_DOCS` remains a
backward-compatible override. When set and non-empty, it wins over `DECKRD_DOCS_DIR`.

Default (`DECKRD_DOCS_DIR` = `<repo-root>/docs/.deckrd`):

```bash
docs/.deckrd/agt-kind/is-collection/requirements/requirements.md
docs/.deckrd/agt-kind/is-collection/specifications/specifications.md
```

## Error Handling

| Condition                  | Action                             |
| -------------------------- | ---------------------------------- |
| No session file            | Prompt to run `init` first         |
| No active module           | Prompt to run `module`             |
| Step out of order          | Warn and suggest correct next step |
| dr --add outside req-tasks | Error, do NOT modify files         |
