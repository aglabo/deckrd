# init Command

Bootstrap and initialize a DECKRD project.

## Usage

```bash
/deckrd init <project> <project-type> [OPTIONS]
```

## Arguments

| Argument         | Required | Description                                       |
| ---------------- | -------- | ------------------------------------------------- |
| `<project>`      | Yes      | Project name (e.g. `myapp`)                       |
| `<project-type>` | Yes      | Project type (e.g. `webapp`, `lib`, `cli`, `api`) |

## Options

<!-- markdownlint-disable line-length -->

| Option                        | Default      | Description                                                      |
| ----------------------------- | ------------ | ---------------------------------------------------------------- |
| `--language <lang>`, `--lang` | `typescript` | Programming language: `typescript`, `go`, `python`, `rust`       |
| `--ai-model <model>`          | `sonnet`     | AI model: `gpt-*`, `o1-*`, `claude-*`, `haiku`, `sonnet`, `opus` |
| `-h`, `--help`                | —            | Show usage information                                           |

<!-- markdownlint-enable line-length -->

## Example

```bash
# Minimum (defaults: typescript, sonnet)
/deckrd init myapp webapp

# Specify language
/deckrd init myapp lib --language go

# Specify both language and AI model
/deckrd init voift webapp --language typescript --ai-model claude-sonnet-4-5
```

## Actions

### Phase 0: Bootstrap (always runs, no overwrite)

Copies deckrd assets into the project on first run. Existing files are never overwritten.

1. **deckrd-rules** → `.claude/rules/`

   ```bash
   assets/inits/deckrd-rules/*.md  →  .claude/rules/  (skip if exists)
   ```

2. **docs templates** → `docs/.deckrd/`

   ```bash
   assets/inits/docs/*  →  docs/.deckrd/  (skip if exists)
   ```

### Phase 1: Create base directory structure

```bash
docs/.deckrd/
├── notes/
└── temp/
```

### Phase 2: Write profile.json

Creates or updates `.local/deckrd/profile.json`:

```json
{
  "project": "<project>",
  "project_type": "<project-type>",
  "language": "<language>",
  "ai_model": "<ai-model>",
  "created_at": "<ISO8601>",
  "updated_at": "<ISO8601>"
}
```

- Existing file: `created_at` is preserved, all other fields updated.

### Phase 3: Initialize session.json

Creates `.local/deckrd/session.json` if it does not exist:

```json
{
  "current_step": "init",
  "completed": ["init"],
  "documents": {},
  "created_at": "<ISO8601>",
  "updated_at": "<ISO8601>"
}
```

- Existing session file is preserved as-is.

## Script

Execute: [scripts/init-dirs.sh](../../scripts/init-dirs.sh)

```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/init-dirs.sh <project> <project-type> [OPTIONS]
```

## Next Step

Profile and session are ready. Run `/deckrd req` to start requirements definition.
