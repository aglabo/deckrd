---
title: module Command
description: Initialize a DECKRD module directory structure and set it as active, or switch to an existing module
---

## module Command

Initialize a DECKRD module directory structure and set it as the active module.
When the module already exists, switch the active module to it and keep its progress.

## Usage

```bash
/deckrd module <namespace>/<module> [--force] [--test-scope <SCOPE>]
/deckrd module <module> [--force] [--test-scope <SCOPE>]
/deckrd module create <namespace>/<module> [--force] [--test-scope <SCOPE>]
/deckrd module create <module> [--force] [--test-scope <SCOPE>]
```

## Subcommands

| Subcommand | Description                                                            |
| ---------- | ---------------------------------------------------------------------- |
| (none)     | Create module dirs and update session, or switch to an existing module |
| `create`   | Same as (none) (namespace auto-resolved if omitted)                    |

## Arguments

| Argument               | Required | Description                                             |
| ---------------------- | -------- | ------------------------------------------------------- |
| `<namespace>/<module>` | Yes*     | Module path (e.g. `agt-kind/is-collection`)             |
| `<module>`             | Yes*     | Module name only; namespace auto-resolved (see Actions) |

\* One of the two forms is required.

## Options

| Option                 | Description                                                                                                                                                                                                                                                                                                                                                                                                      |
| ---------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `--force`              | Re-initialize an existing module instead of switching to it. Its session entry is reset: progress (`current_step` / `completed` / `documents`) is lost                                                                                                                                                                                                                                                           |
| `--test-scope <SCOPE>` | Test scope for the module: 2-4 uppercase letters or digits (e.g. `NOR`). Written to `module.md` and the session (`test_scope`). When omitted, the existing `module.md` value is kept, or one is derived from the module name. Errors if it differs from the scope already declared in `module.md` or conflicts with another module. Errors when the module already exists and is switched to (without `--force`) |
| `--help`               | Show usage information                                                                                                                                                                                                                                                                                                                                                                                           |

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
**before** calling the script. Do NOT let the script fall back to its default namespace silently.

### Inference procedure

1. List existing modules: `ls docs/.deckrd/` → collect all `<namespace>/` directories
2. Read `.local/deckrd/.project.json` → check the `project` field if present
3. Apply semantic matching rules (see table below)
4. Confirm with user — present the inferred path and ask for approval before executing

### Semantic matching rules

| Signal                                                | Action                                      |
| ----------------------------------------------------- | ------------------------------------------- |
| Module name matches domain of an existing namespace   | Use that namespace                          |
| Only one namespace exists in `docs/.deckrd/`          | Use it                                      |
| `.project.json` has a `project` field                 | Use that value                              |
| Module name contains a keyword hinting at a subdomain | Infer from keyword (e.g. `auth-*` → `auth`) |
| No signal found                                       | Fall back to the git repository root name   |

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
   - `<module>` form: auto-resolve namespace from `.local/deckrd/.project.json` (`project`).
     If unavailable, use the git repository root directory name.
3. Check characters: both parts must match `a-z`, `-`, `_` (starting with `a-z`). Uppercase is rejected, not converted
4. If the directory exists and `--force` is not given, switch to it and stop.
   See [Switching to an existing module](#switching-to-an-existing-module)
5. Create module directory structure under `docs/.deckrd/`
6. Update `.local/deckrd/session.json`

### With `create` subcommand

1. If `<module>` only: AI infers namespace (see AI Pre-resolution above), confirms with user
2. Validate module path:
   - `<namespace>/<module>` form: validate both parts
   - `<module>` form: auto-resolve namespace from `.local/deckrd/.project.json` (`project`).
     If unavailable, use the git repository root directory name.
3. Check characters: both parts must match `a-z`, `-`, `_` (starting with `a-z`). Uppercase is rejected, not converted
4. Create module directory structure under `docs/.deckrd/`:

   ```bash
   docs/.deckrd/<namespace>/<module>/
   ├── requirements/
   ├── specifications/
   ├── implementation/
   ├── tasks/
   └── workspaces/
       └── module/
           └── module.md   # test_scope / owns declaration
   ```

   - Without `--force`: if the directory exists, switches to it instead (see below)
   - With `--force`: recreates directories
     - Existing files are preserved
     - An existing `module.md` keeps its `test_scope`
   - A legacy `<module>/module.md` directly under the module directory is not read
     - Move it to `workspaces/module/module.md`

5. Update `.local/deckrd/session.json`:
   - Set `active` to the validated module path
   - Set `current_step` to `"module"`, `completed` to `["module"]`, `documents` to `{}`
   - Set `test_scope` to the resolved test scope

### Switching to an existing module

Runs when the module directory exists and `--force` is not given.

- Only `active` and `updated_at` in `.local/deckrd/session.json` are written.
  The module's own progress and `test_scope` are kept (`current_step`, `completed`, `documents`).
  Every other module's entry is kept too.
- The module directory and `module.md` are not touched.
- Prints `Switched active module: <namespace>/<module>` and exits 0.
- `--test-scope` cannot be combined with switching: it exits 1.
- It exits 1 when `session.json` does not exist or has no entry for the module.
  Register the module with `--force` (this resets its progress).

## Session Schema (after module)

```json
{
  "active": "<namespace>/<module>",
  "prog": "<language>",
  "ai_model": "<model>",
  "modules": {
    "<namespace>/<module>": {
      "current_step": "module",
      "completed": ["module"],
      "documents": {},
      "test_scope": "<SCOPE>"
    }
  },
  "created_at": "<ISO8601>",
  "updated_at": "<ISO8601>"
}
```

## Error Messages

<!-- markdownlint-disable line-length -->

| Error                                         | Cause                                    | Solution                                   |
| --------------------------------------------- | ---------------------------------------- | ------------------------------------------ |
| `namespace '...' contains invalid characters` | Invalid chars in namespace               | Use only `a-z`, hyphen `-`, underscore `_` |
| `no module entry for ... (use --force ...)`   | Directory exists, no session entry       | Add `--force` to register the module       |
| `session not found ... (use --force ...)`     | Directory exists, no `session.json`      | Run `init`, or add `--force`               |
| `--test-scope cannot be changed ...`          | `--test-scope` given when switching      | Drop `--test-scope`, or add `--force`      |
| `Cannot resolve default namespace`            | No `.project.json` and not in a git repo | Run `init`, or pass `<namespace>/<module>` |
| `Cannot extract repository name`              | Git root directory name is empty         | Pass `<namespace>/<module>` explicitly     |

<!-- markdownlint-enable -->

## Script

Execute: [scripts/module.sh](../../scripts/module.sh)

```bash
bash "<DECKRD_SKILL_DIR>/scripts/module.sh" <namespace>/<module> [--force]
bash "<DECKRD_SKILL_DIR>/scripts/module.sh" <module> [--force]
```

## Next Step

Module is ready. Run `/deckrd req` to start requirements definition.
