---
title: update Command
description: List or refresh deployed deckrd assets that are older than the bundled source
---

<!-- cspell:words undeployed -->

## update Command

List deployed deckrd assets that are older than the plugin's bundled source.
With `--update`, overwrite them.

`init` only copies files that do not exist yet. Use `update` to pick up asset changes
shipped by a newer plugin version, without re-running `init`.

## Usage

```bash
/deckrd update [--update]
```

## Options

| Option         | Description                                                 |
| -------------- | ----------------------------------------------------------- |
| (none)         | List outdated deployed files. No file is modified           |
| `--update`     | Apply the listed changes from the bundled source and report |
| `-h`, `--help` | Show usage information                                      |

## Targets

The same source / destination pairs as `init` Phase 0, checked in this order.
Both `init` and `update` read them from `init_asset_dirs` in `scripts/libs/asset-diff.lib.sh`.

| Label                | Source (`assets/inits/`) | Destination                   |
| -------------------- | ------------------------ | ----------------------------- |
| `deckrd-rules`       | `deckrd-rules/`          | `docs/.deckrd/rules/`         |
| `claude-rules`       | `claude-rules/`          | `.claude/rules/claude-rules/` |
| `deckrd-rules-index` | `deckrd-rules-index/`    | `.claude/rules/deckrd-rules/` |
| `docs`               | `docs/`                  | `docs/.deckrd/`               |
| `local-deckrd`       | `local-deckrd/`          | `.local/deckrd/`              |
| `local-workspaces`   | `local-workspaces/`      | `.local/deckrd/workspaces/`   |

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

`.local/deckrd/workspaces/README.md` is also managed by the plugin. It explains the shared
notes layer and is not meant to be edited. `--update` overwrites it like a rule. Put your own
notes in separate files under `workspaces/`.

`.gitignore` (shipped as `.gitignore.org`) is copied by `init` only. `update` never
overwrites it, because users are expected to edit it.

An older deckrd version may have left a `.local/deckrd/.gitignore` without the
workspaces rule (`!/workspaces/`). `update` reports such a file as
`[local-deckrd] .gitignore (workspaces rule)`. `--update` appends the workspaces rule
block of the template to it. The existing lines are kept.

A project initialized before the workspaces directory existed has no
`.local/deckrd/workspaces/README.md`. `update` reports it as
`[local-workspaces] README.md (missing)`. `--update` creates the directory and copies the
README. Any existing entry at that path, even a directory, counts as deployed and is left
untouched.

## Output Example

```bash
$ /deckrd update
[deckrd-rules] deckrd-rule-workflow.md
[deckrd-rules-index] deckrd-rules-index.md
[local-deckrd] .gitignore (workspaces rule)
[local-workspaces] README.md (missing)

$ /deckrd update --update
Updated: [deckrd-rules] deckrd-rule-workflow.md
Updated: [deckrd-rules-index] deckrd-rules-index.md
Updated: [local-deckrd] .gitignore (workspaces rule)
Updated: [local-workspaces] README.md (missing)

$ /deckrd update
Assets are up to date.
```

## Error Messages

| Error             | Cause                                | Solution                                   |
| ----------------- | ------------------------------------ | ------------------------------------------ |
| session not found | `init` has not been run              | Run `deckrd init <project> <project-type>` |
| Unknown option    | Unsupported option passed            | Run `deckrd update --help`                 |
| failed to update  | A destination path cannot be written | Fix the path or its permissions and rerun  |

## Script

Execute: [scripts/update.sh](../../scripts/update.sh)

```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/update.sh [--update]
```
