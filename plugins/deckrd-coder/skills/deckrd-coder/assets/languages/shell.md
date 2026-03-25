---
language: shell
aliases:
  - bash
---

# Shell Language Rules

## Build & Run

| Task  | Command                              |
| ----- | ------------------------------------ |
| Run   | `bash <script.sh>`                   |
| Check | `bash -n <script.sh>` (syntax check) |

## Quality Gates

| Gate       | Command                            |
| ---------- | ---------------------------------- |
| Lint       | `shellcheck **/*.sh`               |
| Format     | `shfmt -w **/*.sh`                 |
| Test       | `pnpm run test:sh` (ShellSpec)     |
| Test+Cover | `shellspec --format documentation` |

## Test Framework

| Item         | Value                     |
| ------------ | ------------------------- |
| Framework    | `ShellSpec`               |
| File pattern | `*.spec.sh`               |
| Run command  | `pnpm run test:sh`        |
| BDD mapping  | `Describe` / `It` / `The` |

### Test Structure

```bash
Describe "Given <context>"
  It "[Normal] When <action> Then <expected result>"
    When call function_name arg1 arg2
    The status should equal 0
    The output should include "expected"
  End
End
```

## Project Conventions

| Item            | Value                                                    |
| --------------- | -------------------------------------------------------- |
| Extension       | `.sh`                                                    |
| Shebang         | `#!/usr/bin/env bash` (included in File Header Template) |
| Strict mode     | `set -euo pipefail` or `set -o pipefail`                 |
| Config files    | `.shellcheckrc`, `.editorconfig`                         |
| Package manager | `pnpm` (for ShellSpec runner scripts)                    |

## File Header Template

All new Shell scripts MUST begin with the file header.
Apply when creating a new file. Do NOT modify existing files.

Template: [templates/shell-header.tpl.sh](../templates/shell-header.tpl.sh)

### Placeholder Resolution

| Placeholder                           | How to resolve                                                                   |
| ------------------------------------- | -------------------------------------------------------------------------------- |
| `<path/from/project/root>`            | Relative path from the repository root. Use forward slashes.                     |
| `<one-line description of this file>` | Single-line summary from the task description or file purpose. No period at end. |

### Application Rules

- Apply to NEW files only. Never modify existing file headers.
- Place the header at the very beginning of the file (line 1).
- Add `set -euo pipefail` immediately after the header block.
- Do not duplicate the shebang — it is already included in the header.

## Project Detection

Identifying files for Shell projects:

- `*.sh` source files (required)
- `.shellcheckrc` — ShellCheck configuration
- `shellspec.json` or `.shellspec` — ShellSpec configuration
- `pnpm-lock.yaml` — if using pnpm for test runner
