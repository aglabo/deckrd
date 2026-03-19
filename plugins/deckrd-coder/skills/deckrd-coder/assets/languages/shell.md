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

| Item            | Value                                    |
| --------------- | ---------------------------------------- |
| Extension       | `.sh`                                    |
| Shebang         | `#!/usr/bin/env bash`                    |
| Strict mode     | `set -euo pipefail` or `set -o pipefail` |
| Config files    | `.shellcheckrc`, `.editorconfig`         |
| Package manager | `pnpm` (for ShellSpec runner scripts)    |

## Project Detection

Identifying files for Shell projects:

- `*.sh` source files (required)
- `.shellcheckrc` — ShellCheck configuration
- `shellspec.json` or `.shellspec` — ShellSpec configuration
- `pnpm-lock.yaml` — if using pnpm for test runner
