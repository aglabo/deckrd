---
title: project Command
description: Configure project settings including name and development language
---

<!-- markdownlint-disable line-length-->

## project Command

Configure project settings (project name and development language).

## Usage

```bash
/deckrd project --project <name> --language <lang>
```

## Parameters

| Parameter                     | Required | Description                                                                                                 |
| ----------------------------- | -------- | ----------------------------------------------------------------------------------------------------------- |
| `--project <name>`            | Yes      | Project name                                                                                                |
| `--language <lang>`, `--lang` | No       | Development language (default: `typescript`): `go`, `typescript`, `python`, `rust`, `shell` (alias: `bash`) |
| `-h`, `--help`                | No       | Show usage information                                                                                      |

## Actions

1. Validate `--project` and `--language` parameters (exit 1 if missing or unsupported)
2. Create `.local/deckrd/` directory if it does not exist
3. Write or update `.local/deckrd/project.json`:
   - New file: write all fields including `created_at` and `updated_at`
   - Existing file: preserve `created_at`, update `updated_at` only

## Project Schema

```json
{
  "project": "<project-name>",
  "project_type": "<project-type>",
  "language": "<language>",
  "ai_model": "<ai-model>",
  "created_at": "<ISO8601 timestamp>",
  "updated_at": "<ISO8601 timestamp>"
}
```

> **Note**: `project_type` and `ai_model` are set by `/deckrd init` and updated by `/deckrd project`.

## Output

```bash
Deckrd project configured.

Project : <project>
Language: <language>
Project : .local/deckrd/project.json
```

## Script

Execute: [scripts/project.sh](../../scripts/project.sh)

```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/project.sh --project <name> --language <lang>
```

> **Note**: `${CLAUDE_PLUGIN_ROOT}` resolves to the plugin installation directory.

## Error Messages

| Error Message                                             | Cause                        | Solution                                                  |
| --------------------------------------------------------- | ---------------------------- | --------------------------------------------------------- |
| `Error: --project is required`                            | `--project` not specified    | Add `--project <name>`                                    |
| `Error: Unsupported language: <lang>. Supported: go, ...` | Language not in allowed list | Use one of: `go`, `typescript`, `python`, `rust`, `shell` |

## Notes

- Project settings are stored at `.local/deckrd/project.json`, together with `.local/deckrd/session.json`
- This command is project-scoped and does not interact with session state
- Can be run at any time, before or after `init`
- `deckrd-coder` reads this project settings in Phase 0 to load language-specific rules
