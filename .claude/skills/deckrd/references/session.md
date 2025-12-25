# Session Management

## Session File Location

```bash
docs/.deckrd/.session.json
```

## Session Schema

```json
{
  "active": "<namespace>/<module>",
  "created_at": "2025-01-01T00:00:00Z",
  "updated_at": "2025-01-01T00:00:00Z",
  "modules": {
    "<namespace>/<module>": {
      "current_step": "spec",
      "completed": ["init", "req"],
      "documents": {
        "requirements": "requirements.md",
        "specifications": "specifications.md"
      }
    }
  }
}
```

## Fields

| Field                    | Type   | Description                  |
| ------------------------ | ------ | ---------------------------- |
| `active`                 | string | Currently active module path |
| `modules`                | object | Per-module session states    |
| `modules.*.current_step` | string | Last completed step          |
| `modules.*.completed`    | array  | All completed steps          |
| `modules.*.documents`    | object | Generated document paths     |

## State Transitions

```bash
(none) ──init──> init ──req──> req ──spec──> spec ──impl──> impl ──tasks──> tasks
                               │
                               └──dr──> (stays in req, append-only DRs)
```

Note: The `dr` command does NOT advance the step. It appends Decision Records
while remaining in the `req` step.

## Session Operations

### Create Session (init command)

```json
{
  "active": "AGTKind/isCollection",
  "modules": {
    "AGTKind/isCollection": {
      "current_step": "init",
      "completed": ["init"],
      "documents": {}
    }
  }
}
```

### Update Session (after each command)

After `req` command:

```json
{
  "active": "AGTKind/isCollection",
  "modules": {
    "AGTKind/isCollection": {
      "current_step": "req",
      "completed": ["init", "req"],
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
docs/.deckrd/<namespace>/<module>/<document-type>/<filename>
```

Example:

```bash
docs/.deckrd/AGTKind/isCollection/requirements/requirements.md
docs/.deckrd/AGTKind/isCollection/specifications/specifications.md
```

## Error Handling

| Condition                 | Action                             |
| ------------------------- | ---------------------------------- |
| No session file           | Prompt to run `init` first         |
| No active module          | Prompt to run `init` or `resume`   |
| Step out of order         | Warn and suggest correct next step |
| dr --add outside req step | Error, do NOT modify files         |
