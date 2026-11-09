---
title: Session Management
description: Session file location, schema, and state transition rules
---

## Session Management

## Session File Location

```bash
.local/deckrd/session.json
```

> **Note**: The `DECKRD_LOCAL` environment variable overrides the default location.
> Default: `<repo-root>/.local/deckrd`

## Session Schema

```json
{
  "active": "<namespace>/<module>",
  "lang": "typescript",
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
      }
    }
  }
}
```

## Fields

| Field                    | Type   | Description                                    |
| ------------------------ | ------ | ---------------------------------------------- |
| `active`                 | string | Currently active module path                   |
| `lang`                   | string | Programming language (e.g. `typescript`, `go`) |
| `ai_model`               | string | AI model identifier (e.g. `sonnet`)            |
| `modules`                | object | Per-module session states                      |
| `modules.*.current_step` | string | Last completed step                            |
| `modules.*.completed`    | array  | All completed steps                            |
| `modules.*.documents`    | object | Generated document paths                       |
| `bdd_coder`              | object | bdd-coder work in progress (optional)          |

### `bdd_coder` (written by bdd-coder)

The bdd-coder skill adds this entry when it builds a task list or a checklist.
`/bdd-coder:bdd-coder --resume` reads it to restore an interrupted session.
deckrd commands do not read or write it. They must keep it when they rewrite `session.json`.

```json
{
  "bdd_coder": {
    "tasklist": ".local/deckrd/temp/tasklist/deckrd/libs/T-01.tasklist.md",
    "item": "L-02",
    "checklist": ".local/deckrd/temp/tasks/parse-config-calm-checklist.md",
    "status": "in-progress",
    "updated_at": "2026-11-09T00:00:00Z"
  }
}
```

| Field                  | Type           | Description                                 |
| ---------------------- | -------------- | ------------------------------------------- |
| `bdd_coder.tasklist`   | string \| null | Task list in use (repository-root relative) |
| `bdd_coder.item`       | string \| null | Selected task list item (`L-XX`)            |
| `bdd_coder.checklist`  | string \| null | Checklist in use (repository-root relative) |
| `bdd_coder.status`     | string         | `in-progress` or `done`                     |
| `bdd_coder.updated_at` | string         | UTC timestamp of the last write             |

Write rules and the resume procedure: bdd-coder `SKILL.md`, "Session entry" and "Resume".

## State Transitions

```bash
# init is a prerequisite (not a tracked step)
(none) ──module──> module ──req──> req ──spec──> spec ──impl──> impl ──tasks──> tasks
                                    │
                                    └──dr──> (stays in req, append-only DRs)
```

Note: The `dr` command does NOT advance the step. It appends Decision Records
while remaining in the `req` step.

## Session Operations

### Create Session (init command)

```json
{
  "active": null,
  "lang": "typescript",
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
  "lang": "typescript",
  "ai_model": "sonnet",
  "modules": {
    "agt-kind/is-collection": {
      "current_step": "module",
      "completed": ["module"],
      "documents": {}
    }
  }
}
```

### Update Session (after each command)

After `req` command:

```json
{
  "active": "agt-kind/is-collection",
  "lang": "typescript",
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
/deckrd init <other-namespace>/<other-module>
```

Or resume existing module:

```bash
/deckrd resume <namespace>/<module>
```

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

| Condition                 | Action                             |
| ------------------------- | ---------------------------------- |
| No session file           | Prompt to run `init` first         |
| No active module          | Prompt to run `init` or `resume`   |
| Step out of order         | Warn and suggest correct next step |
| dr --add outside req step | Error, do NOT modify files         |
