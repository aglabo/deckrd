---
title: init Command
description: Bootstrap and initialize a DECKRD project
---

## init Command

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

<!-- markdownlint-disable line-length MD060 -->

| Option                        | Default      | Description                                                                         |
| ----------------------------- | ------------ | ----------------------------------------------------------------------------------- |
| `--language <lang>`, `--lang` | `typescript` | Programming language: `typescript`, `go`, `python`, `rust`, `shell` (alias: `bash`) |
| `--ai-model <model>`          | `sonnet`     | AI model: `gpt-*`, `o1-*` or `<provider>`/`<model>`                                 |
| `-h`, `--help`                | —            | Show usage information                                                              |

<!-- markdownlint-enable line-length MD060 -->

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

1. **deckrd-rules (bodies)** → `docs/.deckrd/rules/`

   ```bash
   assets/inits/deckrd-rules/*  →  docs/.deckrd/rules/  (skip if exists)
   ```

2. **claude-rules** → `.claude/rules/claude-rules/`

   The one exception to "no rule bodies under `.claude/rules/`". A rule belongs
   here only when its trigger fires *before* the rule could be read on demand:
   `claude-rule-command-execute.md` governs how a slash command is dispatched,
   so reading it after the command was already mis-dispatched is too late.
   Keep every file here short — it is injected verbatim into every session.
   Any rule whose trigger is "before writing code" belongs in `deckrd-rules/`.

   It gets its own subdirectory for the same reason the index does: everything
   deckrd installs stays separable from rules the target project writes itself
   directly under `.claude/rules/`.

   ```bash
   assets/inits/claude-rules/*  →  .claude/rules/claude-rules/  (skip if exists)
   ```

3. **deckrd-rules index** → `.claude/rules/deckrd-rules/`

   Only the index goes under `.claude/rules/deckrd-rules/`. Claude Code discovers
   every `.md` there recursively and injects it into the session context verbatim.
   Rule bodies stay out of it and are read on demand from `docs/.deckrd/rules/`.

   ```bash
   assets/inits/deckrd-rules-index/deckrd-rules-index.md
     →  .claude/rules/deckrd-rules/  (skip if exists)
   ```

   This asset dir intentionally carries no `.gitignore.org`, unlike
   `deckrd-rules/`: the index is meant to be tracked by the target project.

4. **docs templates** → `docs/.deckrd/`

   ```bash
   assets/inits/docs/*  →  docs/.deckrd/  (skip if exists)
   ```

### Phase 1: Create base directory structure

```bash
docs/.deckrd/
├── notes/
└── temp/
```

### Phase 2: Write project.json

Creates or updates `.local/deckrd/project.json`:

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
  "active": null,
  "modules": {},
  "created_at": "<ISO8601>",
  "updated_at": "<ISO8601>"
}
```

- No active module is set — run `module` next to initialize a module.
- Existing session file is preserved as-is.

## Script

Execute: [scripts/init.sh](../../scripts/init.sh)

```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/init.sh <project> <project-type> [OPTIONS]
```

## Next Step

Profile and session are ready. Run `/deckrd module <namespace>/<module>` to create a module.
