---
title: module Command
description: Initialize a DECKRD module directory structure and set it as active
---

## module Command

Initialize a DECKRD module directory structure and set it as the active module.

## Usage

```bash
/deckrd module <namespace>/<module> [--force]
/deckrd module <module> [--force]
/deckrd module create <namespace>/<module> [--force]
/deckrd module create <module> [--force]
```

## Subcommands

| Subcommand | Description                                                                |
| ---------- | -------------------------------------------------------------------------- |
| (none)     | Create module dirs and update session (namespace auto-resolved if omitted) |
| `create`   | Create module dirs and update session (subdomain auto-resolved if omitted) |

## Arguments

| Argument               | Required | Description                                                    |
| ---------------------- | -------- | -------------------------------------------------------------- |
| `<namespace>/<module>` | Yes*     | Module path (e.g. `agt-kind/is-collection`)                    |
| `<module>`             | Yes*     | Module name only; namespace auto-resolved from git remote name |

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

| Input                    | Result                                       |
| ------------------------ | -------------------------------------------- |
| `agt-kind/is-collection` | valid                                        |
| `my-ns/my-mod`           | valid                                        |
| `my-feature`             | AI infers namespace, confirms before running |
| `AGTKind/isCollection`   | error (uppercase not allowed)                |
| `MyNS/MyMod`             | error (uppercase not allowed)                |

## AI Pre-resolution (when `<module>` only is given)

When the user provides only `<module>` (no `/` separator), YOU (the AI) MUST infer the namespace.
**before** calling the script. Do NOT let the script fall back to `get_repo_name`.

### Inference procedure

1. List existing modules: `ls docs/.deckrd/` → collect all `<namespace>/` directories
2. Read `project.json` → check `namespace` field if present
3. Apply semantic matching rules (see table below)
4. **Confirm with user** — present the inferred path and ask for approval before executing

### Semantic matching rules

| Signal                                                | Action                                      |
| ----------------------------------------------------- | ------------------------------------------- |
| Module name matches domain of an existing namespace   | Use that namespace                          |
| Only one namespace exists in `docs/.deckrd/`          | Use it                                      |
| `project.json` has a `namespace` field                | Use that value                              |
| Module name contains a keyword hinting at a subdomain | Infer from keyword (e.g. `auth-*` → `auth`) |
| No signal found                                       | Fall back to `get_repo_name` (git remote)   |

### Example

```bash
User: /deckrd module user-login
AI scans docs/.deckrd/ → finds: auth/session, auth/token
AI infers: "auth" namespace (existing auth-related modules)
AI: "Inferred namespace: auth/user-login — proceed? (y/n)"
User: y
AI runs: bash module.sh auth/user-login
```

## Actions

### Without `create` subcommand

1. If `<module>` only: AI infers namespace (see AI Pre-resolution above), confirms with user
2. Validate module path:
   - `<namespace>/<module>` form: validate both parts
   - `<module>` form: auto-resolve namespace from `git remote get-url origin`
3. Normalize to lowercase
4. Create module directory structure under `docs/.deckrd/`
5. Update `.local/deckrd/session.json`

### With `create` subcommand

1. If `<module>` only: AI infers namespace (see AI Pre-resolution above), confirms with user
2. Validate module path:
   - `<subdomain>/<module>` form: validate both parts
   - `<module>` form: auto-resolve subdomain from `git remote get-url origin`
3. Normalize to lowercase
4. Create module directory structure under `docs/.deckrd/`:

   ```bash
   docs/.deckrd/<namespace>/<module>/
   ├── requirements/
   ├── specifications/
   ├── implementation/
   └── tasks/
   ```

   - Without `--force`: exits with error if directory already exists
   - With `--force`: recreates directories (existing files are preserved)

5. Update `.local/deckrd/session.json`:
   - Set `active` to normalized module path
   - Set `current_step` to `"module"`, `completed` to `["module"]`, `documents` to `{}`

## Session Schema (after module)

```json
{
  "active": "<namespace>/<module>",
  "lang": "<language>",
  "ai_model": "<model>",
  "modules": {
    "<namespace>/<module>": {
      "current_step": "module",
      "completed": ["module"],
      "documents": {}
    }
  },
  "created_at": "<ISO8601>",
  "updated_at": "<ISO8601>"
}
```

## Error Messages

<!-- markdownlint-disable line-length -->

| Error                                         | Cause                            | Solution                                   |
| --------------------------------------------- | -------------------------------- | ------------------------------------------ |
| `namespace '...' contains invalid characters` | Invalid chars in namespace       | Use only `a-z`, hyphen `-`, underscore `_` |
| `Module directory already exists`             | Directory exists, no `--force`   | Add `--force` to re-initialize             |
| `Cannot get git remote origin URL`            | No git remote origin configured  | Run inside a git repo with `origin`        |
| `Cannot extract repository name`              | Remote URL has no parseable name | Set a valid `git remote origin` URL        |

<!-- markdownlint-enable -->

## Script

Execute: [scripts/module.sh](../../scripts/module.sh)

```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/module.sh <namespace>/<module> [--force]
bash ${CLAUDE_PLUGIN_ROOT}/scripts/module.sh <module> [--force]
```

## Next Step

Module is ready. Run `/deckrd req` to start requirements definition.
