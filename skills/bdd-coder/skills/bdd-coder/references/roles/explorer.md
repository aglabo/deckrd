---
title: "Role: explorer (bdd-coder)"
description: "Procedure for read-only detection of the development environment (language, test framework, tool commands). Canonical steps for the bdd-coder explore-agent"
version: 1.0.0
---

## Role: explorer

<!-- textlint-disable
  ja-technical-writing/max-comma,
  ja-technical-writing/sentence-length,
  -->
<!-- markdownlint-disable line-length -->

This Role is the **canonical procedure** for detecting the development environment. It is read-only.

- In Claude Code, the `explore-agent` agent (`agents/explore-agent-coder.md` at the plugin root) loads this Role and runs it in a sub-context.
- Where agents are not available, the main session follows this Role step by step itself.

All paths below are relative to the bdd-coder skill directory unless they start with `.local/` or `docs/`.

## Responsibility

Detect the development language, test framework, build tools, and related commands.
Write the environment profile to `.local/deckrd/temp/deckrd-work/env-profile.md` so the main session does not need to hold raw manifest file contents in context.

## Inputs

| Parameter   | Values                             | Description                               |
| ----------- | ---------------------------------- | ----------------------------------------- |
| `directory` | Path string                        | Repository root to investigate            |
| `scope`     | `pattern-detection`                | Always `pattern-detection` for this agent |
| `focus`     | e.g., `test-framework,build-tools` | Comma-separated areas to detect           |

## Detection Steps

### Step 1: Read Profile (if exists)

Read `.deckrd/profile.json`:

- `project`: project name
- `language`: primary language

If found, load the corresponding language rule file.
Path: `assets/languages/<language>.md`

### Step 1.5: Semantic Code Search (if target symbols are known)

When the caller provides target function/class names, use a semantic code search tool, if one is available, BEFORE reading files:

1. Search by concept to find existing implementations when exact names are unknown:

   ```bash
   query: "path normalization utility"
   ```

Use the results to populate the environment profile. When no such tool is available, or its results lack detail, use `Read` / `Grep` / `Glob`.

### Step 2: Dynamic Detection

If profile is absent or incomplete, detect from manifest files:

| File                          | Language / Tool      |
| ----------------------------- | -------------------- |
| `package.json`                | Node.js / TypeScript |
| `Cargo.toml`                  | Rust                 |
| `setup.py` / `pyproject.toml` | Python               |
| `go.mod`                      | Go                   |
| `build.gradle`                | Java / Kotlin        |
| `*.sh` / `.shellcheckrc`      | Shell (Bash)         |

> **Note:** `bash` is treated as an alias for `shell`. When the profile specifies `language: bash`, load `languages/shell.md` instead.

### Step 3: Tool Command Detection

For each detected language, identify:

| Tool        | Detection method                                            |
| ----------- | ----------------------------------------------------------- |
| Test runner | `vitest`, `jest`, `pytest`, `cargo test`, `shellspec`       |
| Lint        | `eslint`, `clippy`, `flake8`, `golangci-lint`, `shellcheck` |
| Type check  | `tsc --noEmit`, `mypy`, `bash -n` (syntax check)            |
| Build       | `tsc`, `cargo build`, `go build`, `bash -n`                 |
| Format      | `prettier`, `rustfmt`, `black`, `shfmt`                     |

Read config files to confirm exact commands and configuration.
Examples: `vitest.config.*`, `.eslintrc.*`, `pyproject.toml`

### Step 4: Write Output

Write the environment profile to `.local/deckrd/temp/deckrd-work/env-profile.md`:

```markdown
# Environment Profile

generated: <timestamp>
directory: <directory>

## Project

- Language: <language>
- Project: <name>

## Commands

| Tool       | Command   |
| ---------- | --------- |
| test       | <command> |
| lint       | <command> |
| type-check | <command> |
| build      | <command> |
| format     | <command> |

## Notes

<Any relevant observations about the environment>
```

Return the **Commands table** and language name to the main session.

## Constraints

<!-- textlint-disable @textlint-ja/ai-writing/no-ai-list-formatting -->

- **Read-only**: MUST NOT use `Write` or `Edit` on any file except `.local/deckrd/temp/deckrd-work/env-profile.md`
- **No session files**: MUST NOT read or write `session.json`
- **No side effects**: MUST NOT run commands that modify the filesystem or network

<!-- textlint-enable @textlint-ja/ai-writing/no-ai-list-formatting -->

- Allowed actions: read files, search (Grep / Glob), run read-only shell commands, and a semantic code search tool if available
- Prefer the semantic code search tool for symbol/caller lookups — use Read/Grep only as fallback
- Output file exception: MAY write to `.local/deckrd/temp/deckrd-work/env-profile.md`
