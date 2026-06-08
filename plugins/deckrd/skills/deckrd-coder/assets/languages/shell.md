---
language: shell
aliases:
  - bash
---

<!-- markdownlint-disable line-length -->

# Shell Language Rules

## Build & Run

| Task  | Command                              |
| ----- | ------------------------------------ |
| Run   | `bash <script.sh>`                   |
| Check | `bash -n <script.sh>` (syntax check) |

## Quality Gates

| Gate       | Command                                       |
| ---------- | --------------------------------------------- |
| Lint       | `shellcheck **/*.sh`                          |
| Format     | `shfmt -w **/*.sh`                            |
| Test       | `shellspec --format documentation` (required) |
| Coverage   | included in the above command                 |

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

## Test Quality (Shell-specific)

For canonical host-safety, idempotency, and mock discipline principles, see:
[../test-quality.md](../test-quality.md)

### Tempdir Isolation

Never write to `$HOME` or project root in tests. Use `mktemp -d` and clean up in `AfterEach`:

```bash
BeforeEach
  TEST_DIR="$(mktemp -d)"
End

AfterEach
  rm -rf "$TEST_DIR"
End
```

### Date / Time Injection

Never call `date` directly inside tested functions. Accept a timestamp as a parameter:

```bash
# Bad: non-idempotent — result changes depending on when the test runs
get_timestamp() { date +%s; }

# Good: inject timestamp as argument; fall back to date only in production entry point
get_timestamp() { echo "${1:-$(date +%s)}"; }

It "returns injected timestamp"
  When call get_timestamp "1704067200"
  The output should equal "1704067200"
End
```

### Environment Variable Isolation

Save and restore any environment variable changed during a test:

```bash
BeforeEach
  _SAVED_HOME="$HOME"
  export HOME="$TEST_DIR"
End

AfterEach
  export HOME="$_SAVED_HOME"
End
```

## Project Detection

Identifying files for Shell projects:

- `*.sh` source files (required)
- `.shellcheckrc` — ShellCheck configuration
- `shellspec.json` or `.shellspec` — ShellSpec configuration
- `pnpm-lock.yaml` — if using pnpm for test runner
