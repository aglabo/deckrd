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

`prog` holds the programming language that `init` received with `--prog` (alias `--language`).
bdd-coder reads it to choose its language rules.
`lang` holds the document language that `init` received with `--lang`.
`generate-doc.sh` passes it to the AI as `LANG:` unless `--lang` is given on the command.
When `lang` is absent, `system` is used.
In every deckrd command and script, `--lang` means the document language only.

Older session files stored the programming language in `lang`.
`init` (when the session already exists) and `update` move such a value to `prog`.
They do this only when `prog` is absent and `lang` is a supported programming language.
The supported values are the same as `init --prog` (`bash` included).
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

Write rules and the resume procedure: bdd-coder `references/session-resume.md`.

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

If the module directory does not exist, `module` creates it and makes it active.
If the directory already exists, `module` only switches `active` to it:

- `active` and `updated_at` are the only fields written
- the module's `current_step`, `completed`, `documents` and `test_scope` are kept
- other modules' entries, the module directory and `module.md` are not touched
- `--test-scope` cannot be given: the scope of an existing module cannot be changed by switching

Switching fails with exit 1 if `session.json` does not exist.
It also fails if `session.json` has no entry for the module.
An example is a module directory created by hand.
Register the module with `/deckrd module <namespace>/<module> --force`.

`module --force` is not a way to switch.
It re-initializes the module's session entry, so the recorded progress is lost:

- `current_step` becomes `"module"`
- `completed` becomes `["module"]`
- `documents` becomes `{}`

The existing files and `module.md` are kept.

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

| Condition                   | Action                                    |
| --------------------------- | ----------------------------------------- |
| No session file             | Prompt to run `init` first                |
| No active module            | Prompt to run `module`                    |
| Module has no session entry | Prompt to run `module <ns>/<mod> --force` |
| Step out of order           | Warn and suggest correct next step        |
| dr --add outside req-tasks  | Error, do NOT modify files                |
