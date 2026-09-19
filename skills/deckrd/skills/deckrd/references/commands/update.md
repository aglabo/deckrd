---
title: update Command
description: List or refresh deployed rules assets that are older than the bundled source
---

<!-- cspell:words undeployed -->

## update Command

List deployed deckrd assets that are older than the plugin's bundled source.
With `--update`, overwrite them.

`init` only copies files that do not exist yet. Use `update` to pick up rule changes
shipped by a newer plugin version, without re-running `init`.

## Usage

```bash
/deckrd update [--update]
```

## Options

| Option         | Description                                                   |
| -------------- | ------------------------------------------------------------- |
| (none)         | List outdated deployed files. No file is modified             |
| `--update`     | Overwrite the listed files with the bundled source and report |
| `-h`, `--help` | Show usage information                                        |

## Targets

The same source / destination pairs as `init` Phase 0, checked in this order.
They are defined by `init_asset_dirs` in `scripts/libs/asset-diff.lib.sh`.

| Label                | Source (`assets/inits/`) | Destination                   |
| -------------------- | ------------------------ | ----------------------------- |
| `deckrd-rules`       | `deckrd-rules/`          | `docs/.deckrd/rules/`         |
| `claude-rules`       | `claude-rules/`          | `.claude/rules/claude-rules/` |
| `deckrd-rules-index` | `deckrd-rules-index/`    | `.claude/rules/deckrd-rules/` |
| `docs`               | `docs/`                  | `docs/.deckrd/`               |
| `local-deckrd`       | `local-deckrd/`          | `.local/deckrd/`              |

## Detection Rule

A deployed file is reported only when all of the following hold:

- It already exists in the destination (undeployed files are never copied)
- The source is newer than the deployed file (mtime)
- The contents differ

A deployed file newer than its source is treated as edited by the user. It is neither
reported nor overwritten, even with `--update`.

Deployed rules are managed by the plugin and are not meant to be edited. Put project
customizations in separate files. `--update` may overwrite a deployed rule edited before
a plugin upgrade.

`.gitignore` (shipped as `.gitignore.org`) is copied by `init` only. `update` never
reports or overwrites it, because users are expected to edit it.

## Output Example

```bash
$ /deckrd update
[deckrd-rules] deckrd-rule-workflow.md
[deckrd-rules-index] deckrd-rules-index.md

$ /deckrd update --update
Updated: [deckrd-rules] deckrd-rule-workflow.md
Updated: [deckrd-rules-index] deckrd-rules-index.md

$ /deckrd update
Rules are up to date.
```

## Error Messages

| Error             | Cause                     | Solution                                   |
| ----------------- | ------------------------- | ------------------------------------------ |
| session not found | `init` has not been run   | Run `deckrd init <project> <project-type>` |
| Unknown option    | Unsupported option passed | Run `deckrd update --help`                 |

## Script

Execute: [scripts/update.sh](../../scripts/update.sh)

```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/update.sh [--update]
```
