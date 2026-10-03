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
| `--force`                     | —            | Overwrite every asset file, including `.gitignore` files and user edits             |
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

# Reset every deployed asset to the bundled version
/deckrd init myapp webapp --force
```

## Actions

### Phase 0: Bootstrap (always runs)

Copies deckrd assets into the project. Each source directory is copied recursively.
`list_asset_files` in `scripts/libs/asset-diff.lib.sh` picks the files to copy.
`copy_assets` in `scripts/libs/asset-copy.lib.sh` copies them. `init` runs them in missing-only
mode (`copy_assets --missing-only`). `update` uses the same routines but also refreshes outdated
files. Each source file is handled as follows:

- A `.org` suffix is dropped from the file name (`.gitignore.org` → `.gitignore`)
- A file missing from the destination is copied (`copied:`)
- A copied file keeps the mtime of its source
- A file that already exists is never overwritten and is not reported. This holds even when the
  file is older than its source, differs from it, was edited by the user, or is a `.gitignore`

Re-running `init` does not refresh outdated files. To refresh them, run
[`/deckrd update --update`](update.md) (outdated files only) or `/deckrd init --force` (every file).

With `--force`, every source file is copied (`copied:`), whether or not it is deployed.
This includes `.gitignore` files and files edited by the user.
`.project.json` is rewritten as usual, and an existing `session.json` is still kept.

Each target ends with `[init/<label>] done: N copied`.
A missing source directory is reported as `source not found, skipping` and is not an error.

1. **claude-rules** → `.claude/rules/claude-rules/`

   The one exception to "no rule bodies under `.claude/rules/`". A rule belongs
   here only when its trigger fires *before* the rule could be read on demand:
   `claude-rule-command-execute.md` governs how a slash command is dispatched,
   so reading it after the command was already mis-dispatched is too late.
   Keep every file here short — it is injected verbatim into every session.
   Any rule whose trigger is "before writing code" belongs in `docs/.deckrd/rules/`.

   It gets its own subdirectory for the same reason the index does. Everything
   deckrd installs stays separable from the rules a target project writes.
   Those live directly under `.claude/rules/`.

   ```bash
   assets/inits/claude-rules/*  →  .claude/rules/claude-rules/  (missing only)
   ```

2. **deckrd-rules index** → `.claude/rules/deckrd-rules/`

   Only the index goes under `.claude/rules/deckrd-rules/`. Claude Code finds
   every `.md` there recursively and injects it into the session verbatim.
   Rule bodies stay out of it and are read on demand from `docs/.deckrd/rules/`.

   ```bash
   assets/inits/deckrd-rules-index/deckrd-rules-index.md
     →  .claude/rules/deckrd-rules/  (missing only)
   ```

   This asset dir intentionally carries no `.gitignore.org`, unlike
   `docs/rules/`: the index is meant to be tracked by the target project.

3. **docs templates and deckrd-rules (bodies)** → `docs/.deckrd/`

   The rule bodies live in `docs/rules/` and land in `docs/.deckrd/rules/`.

   ```bash
   assets/inits/docs/**  →  docs/.deckrd/  (recursive, missing only)
   ```

4. **local data and workspaces README** → `.local/deckrd/`

   The workspaces README lives in `local-deckrd/workspaces/` and lands in
   `.local/deckrd/workspaces/README.md`. This path is fixed. When
   `DECKRD_LOCAL_WORKSPACES` is overridden, `init` only creates that directory and
   does not put the README there.

   ```bash
   assets/inits/local-deckrd/**  →  .local/deckrd/  (recursive, missing only)
   ```

#### Migrating a project initialized before the rule consolidation

Re-running `init` only adds missing files. To refresh outdated files that still exist in the
bundle, run [`/deckrd update --update`](update.md). `/deckrd init --force` also works, but it
overwrites user edits too. Files removed from the bundle are not handled by either. Delete these
first, then re-run `/deckrd init`:

- `docs/.deckrd/rules/deckrd-rule-traceability.md`
- `docs/.deckrd/rules/deckrd-rule-id-system.md`
- `docs/.deckrd/rules/deckrd-rule-document-naming.md`
- `docs/.deckrd/rules/deckrd-rule-file-structure.md`
- `docs/.deckrd/rules/deckrd-rule-commit-linkage.md`
- `.claude/rules/deckrd-rules/deckrd-rules-index.md`

The index must go too. It is the only one of these injected into the session.
An old copy keeps pointing Claude at the five deleted bodies. It never mentions
`deckrd-rule-document-model.md`, even after the new body was copied in.

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
