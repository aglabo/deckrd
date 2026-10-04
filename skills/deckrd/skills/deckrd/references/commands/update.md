---
title: update Command
description: List or refresh deployed deckrd assets that are missing or older than the bundled source
---

## update Command

List deckrd assets that are missing from the project or older than the plugin's bundled
source. With `--update`, copy or overwrite them.

`update` and `init` share the same routines. `list_asset_files` in `scripts/libs/asset-diff.lib.sh`
picks the files to copy. `copy_assets` in `scripts/libs/asset-copy.lib.sh` copies them.
Without `--update`, `update` prints that list and changes nothing.

## Usage

```bash
/deckrd update [--update]
```

## Options

| Option         | Description                                                 |
| -------------- | ----------------------------------------------------------- |
| (none)         | List missing or outdated files. No file is modified         |
| `--update`     | Apply the listed changes from the bundled source and report |
| `-h`, `--help` | Show usage information                                      |

## Targets

The same source / destination pairs as `init` Phase 0, checked in this order.
Both `init` and `update` read them from `init_asset_dirs` in `scripts/libs/asset-diff.lib.sh`.
Each source directory is checked recursively.
A file in a subdirectory is reported by its relative path, e.g. `[docs] rules/a.md`.

| Label                | Source (`assets/inits/`) | Destination                   |
| -------------------- | ------------------------ | ----------------------------- |
| `claude-rules`       | `claude-rules/`          | `.claude/rules/claude-rules/` |
| `deckrd-rules-index` | `deckrd-rules-index/`    | `.claude/rules/deckrd-rules/` |
| `docs`               | `docs/` (incl. `rules/`) | `docs/.deckrd/`               |
| `local-deckrd`       | `local-deckrd/`          | `.local/deckrd/`              |

`local-deckrd/` includes `workspaces/README.md`.

## Detection Rule

A `.org` suffix is dropped from the source file name first (`.gitignore.org` → `.gitignore`).
A file is reported (and copied with `--update`) when either of the following holds:

- It does not exist in the destination
- It exists, the source is newer than the deployed file (mtime), and the contents differ

A deployed file newer than its source is treated as edited by the user. It is neither
reported nor overwritten, even with `--update`.

A copied file keeps the mtime of its source. A deployed file older than its source with
the same contents is not reported and its contents are kept. `--update` only sets its
mtime to the source's.

Deployed rules are managed by the plugin and are not meant to be edited. Put project
customizations in separate files. `--update` may overwrite a deployed rule edited before
a plugin upgrade.

`.local/deckrd/workspaces/README.md` is also managed by the plugin. It explains the shared
notes layer and is not meant to be edited. `--update` overwrites it like a rule. Put your own
notes in separate files under `workspaces/`.

An existing `.gitignore` at any depth is never overwritten. Users are expected to edit it.
A missing one is deployed like any other file.
An existing entry that is not a regular file (e.g. a directory or a dangling symlink) is
left untouched.

An older deckrd version may have left a `.local/deckrd/.gitignore` without the
workspaces rule (`!/workspaces/`). `update` reports such a file as
`[local-deckrd] .gitignore (workspaces rule)`. `--update` appends the workspaces rule
block of the template to it. The existing lines are kept.

A project initialized before the workspaces directory existed has no
`.local/deckrd/workspaces/README.md`. Like any missing file, `update` reports it as
`[local-deckrd] workspaces/README.md`. `--update` creates the directory and copies it.
This README path is fixed to where `init` deploys it.
Overriding `DECKRD_LOCAL_WORKSPACES` does not move it.

## Output Example

```bash
$ /deckrd update
[deckrd-rules-index] deckrd-rules-index.md
[docs] rules/deckrd-rule-workflow.md
[local-deckrd] workspaces/README.md
[local-deckrd] .gitignore (workspaces rule)

$ /deckrd update --update
Updated: [deckrd-rules-index] deckrd-rules-index.md
Updated: [docs] rules/deckrd-rule-workflow.md
Updated: [local-deckrd] workspaces/README.md
Updated: [local-deckrd] .gitignore (workspaces rule)

$ /deckrd update
Assets are up to date.
```

## Error Messages

| Error               | Cause                                                                                   | Solution                                                                   |
| ------------------- | --------------------------------------------------------------------------------------- | -------------------------------------------------------------------------- |
| session not found   | `init` has not been run, or (outside git) the current directory is not the project root | Run `deckrd init <project> <project-type>`, or rerun from the project root |
| Unknown option      | Unsupported option passed                                                               | Run `deckrd update --help`                                                 |
| failed to update    | A destination path cannot be written                                                    | Fix the path or its permissions and rerun                                  |
| failed to copy file | An asset cannot be copied to its destination                                            | Fix the path or its permissions and rerun                                  |

## Script

Execute: [scripts/update.sh](../../scripts/update.sh)

```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/update.sh [--update]
```
