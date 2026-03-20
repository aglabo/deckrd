---
title: module Command
description: Initialize a DECKRD module directory structure and set it as active
---

## module Command

Initialize a DECKRD module directory structure and set it as the active module.

## Usage

```bash
/deckrd module <namespace>/<module> [--force]
/deckrd module create <namespace>/<module> [--force]
/deckrd module create <module> [--force]
```

## Subcommands

| Subcommand | Description                                                   |
| ---------- | ------------------------------------------------------------- |
| (none)     | Create module dirs and update session (legacy form)           |
| `create`   | Create module dirs, write `.project.json`, and update session |

## Arguments

| Argument               | Required | Description                                                               |
| ---------------------- | -------- | ------------------------------------------------------------------------- |
| `<namespace>/<module>` | Yes*     | Module path (e.g. `agt-kind/is-collection`)                               |
| `<module>`             | Yes*     | Module name only; subdomain auto-resolved from git remote name (`create`) |

\* One of the two forms is required.

## Options

| Option    | Description                                               |
| --------- | --------------------------------------------------------- |
| `--force` | Re-initialize even if the module directory already exists |
| `--help`  | Show usage information                                    |

## Naming Rules

| Rule               | Detail                                          |
| ------------------ | ----------------------------------------------- |
| Allowed characters | `a-z`, hyphen `-`, underscore `_`               |
| Case sensitivity   | Lowercase only — uppercase letters are rejected |
| Format             | Must contain exactly one `/` separator          |

### Examples

| Input                    | Result                        |
| ------------------------ | ----------------------------- |
| `agt-kind/is-collection` | valid                         |
| `my-ns/my-mod`           | valid                         |
| `AGTKind/isCollection`   | error (uppercase not allowed) |
| `MyNS/MyMod`             | error (uppercase not allowed) |

## Actions

### Without `create` subcommand (legacy)

1. Validate `<namespace>/<module>` format and characters
2. Normalize to lowercase
3. Create module directory structure under `docs/.deckrd/`
4. Update `.local/deckrd/session.json`

### With `create` subcommand

1. Validate module path:
   - `<subdomain>/<module>` form: validate both parts
   - `<module>` form: auto-resolve subdomain from `git remote get-url origin`
2. Normalize to lowercase
3. Create module directory structure under `docs/.deckrd/`:

   ```bash
   docs/.deckrd/<namespace>/<module>/
   ├── requirements/
   ├── specifications/
   ├── implementation/
   ├── tasks/
   └── .project.json
   ```

   - Without `--force`: exits with error if directory already exists
   - With `--force`: recreates directories (existing files are preserved)

4. Write `.project.json`:

   ```json
   {
     "name": "<module-name>",
     "description": "",
     "created_at": "<ISO8601>",
     "updated_at": "<ISO8601>"
   }
   ```

5. Update `.local/deckrd/session.json`:
   - Set `active` to normalized module path
   - Set `current_step` to `"module"`, `completed` to `["module"]`, `documents` to `{}`

## Session Schema (after module)

```json
{
  "active": "<namespace>/<module>",
  "modules": {
    "<namespace>/<module>": {
      "current_step": "module",
      "completed": ["module"],
      "documents": {}
    }
  },
  "updated_at": "<ISO8601>"
}
```

## Error Messages

<!-- markdownlint-disable line-length -->

| Error                                         | Cause                            | Solution                            |
| --------------------------------------------- | -------------------------------- | ----------------------------------- |
| `Path must be in format <namespace>/<module>` | Missing `/` separator (legacy)   | Use `namespace/module` format       |
| `namespace '...' contains invalid characters` | Invalid chars in namespace       | Use only `a-z A-Z 0-9 - _`          |
| `Module directory already exists`             | Directory exists, no `--force`   | Add `--force` to re-initialize      |
| `Cannot get git remote origin URL`            | No git remote origin configured  | Run inside a git repo with `origin` |
| `Cannot extract repository name`              | Remote URL has no parseable name | Set a valid `git remote origin` URL |

<!-- markdownlint-enable -->

## Script

Execute: [scripts/module.sh](../../scripts/module.sh)

```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/module.sh <namespace>/<module> [--force]
```

## Next Step

Module is ready. Run `/deckrd req` to start requirements definition.
