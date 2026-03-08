# profile Command

Configure project profile (project name and development language).

## Usage

```bash
/deckrd profile --project <name> --language <lang>
```

## Parameters

<!-- markdownlint-disable line-length -->

| Parameter                     | Required | Description                                                                        |
| ----------------------------- | -------- | ---------------------------------------------------------------------------------- |
| `--project <name>`            | Yes      | Project name                                                                       |
| `--language <lang>`, `--lang` | No       | Development language (default: `typescript`): `go`, `typescript`, `python`, `rust` |
| `-h`, `--help`                | No       | Show usage information                                                             |

<!-- markdownlint-disable enable -->

## Actions

1. Validate `--project` and `--language` parameters (exit 1 if missing or unsupported)
2. Create `.local/deckrd/` directory if it does not exist
3. Write or update `.local/deckrd/profile.json`:
   - New file: write all fields including `created_at` and `updated_at`
   - Existing file: preserve `created_at`, update `updated_at` only

## Profile Schema

```json
{
  "project": "<project-name>",
  "language": "<language>",
  "created_at": "<ISO8601 timestamp>",
  "updated_at": "<ISO8601 timestamp>"
}
```

## Output

```bash
Deckrd profile configured.

Project : <project>
Language: <language>
Profile : .local/deckrd/profile.json
```

## Script

Execute: [scripts/profile.sh](../../scripts/profile.sh)

```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/profile.sh --project <name> --language <lang>
```

> **Note**: `${CLAUDE_PLUGIN_ROOT}` resolves to the plugin installation directory.

## Error Messages

| Error Message                                             | Cause                        | Solution                                         |
| --------------------------------------------------------- | ---------------------------- | ------------------------------------------------ |
| `Error: --project is required`                            | `--project` not specified    | Add `--project <name>`                           |
| `Error: Unsupported language: <lang>. Supported: go, ...` | Language not in allowed list | Use one of: `go`, `typescript`, `python`, `rust` |

## Notes

- Profile is stored at `.local/deckrd/profile.json`, together with `.local/deckrd/session.json`
- This command is project-scoped and does not interact with session state
- Can be run at any time, before or after `init`
- `deckrd-coder` reads this profile in Phase 0 to load language-specific rules
