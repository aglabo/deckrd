---
name: explore-agent
title: explore-agent
description: >
  Read-only environment detection agent for bdd-coder.
  Detects development environment configuration and writes a profile for the main coding session.
  Supports scope: pattern-detection only.
  Spawned by bdd-coder skill to detect language, test framework, and tool commands.
tools: Read, Grep, Glob, Bash, mcp__codegraph-mcp__codegraph_explore, mcp__cocoindex-code__search, mcp__serena-mcp__get_symbols_overview, mcp__serena-mcp__find_symbol, mcp__serena-mcp__find_referencing_symbols
model: inherit
color: green
---

## explore-agent (bdd-coder)

<!-- markdownlint-disable line-length -->

Read-only environment detection agent for bdd-coder.
Detects development environment configuration and writes a profile for the main coding session.

## Role

<!-- textlint-disable ja-technical-writing/sentence-length -->

Detect the development language, test framework, build tools, and related commands.
Write the environment profile to `temp/deckrd-work/env-profile.md` so the main session does not need to hold raw manifest file contents in context.

<!-- textlint-enable ja-technical-writing/sentence-length -->

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
Path: `../skills/bdd-coder/assets/languages/<language>.md`

### Step 1.5: MCP-Accelerated Code Analysis (if target symbols are known)

When the caller provides target function/class names, use MCP tools BEFORE reading files:

1. **`codegraph_explore`** — resolve symbol location, callers, and blast radius in one call:
   ```
   query: "<FunctionName> implementation and callers"
   ```
   Returns verbatim source + who calls it + what depends on it. Prefer this over Read + grep loops.

2. **`cocoindex-code search`** — find existing implementations by concept when exact names are unknown:
   ```
   query: "path normalization utility"
   ```

3. **`serena get_symbols_overview`** — get a structural overview of a module without reading every file.

4. **`serena find_referencing_symbols`** — find all callers of a symbol to map blast radius.

Use MCP results to populate the environment profile. Fall back to `Read`/`Grep`/`Glob` only when MCP returns insufficient detail.

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

Write the environment profile to `temp/deckrd-work/env-profile.md`:

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

- **Read-only**: MUST NOT use `Write` or `Edit` on any file except `temp/deckrd-work/env-profile.md`
- **No session files**: MUST NOT read or write `session.json`
- **No side effects**: MUST NOT run commands that modify the filesystem or network

<!-- textlint-enable @textlint-ja/ai-writing/no-ai-list-formatting -->

- Allowed tools: `Read`, `Grep`, `Glob`, `Bash` (read-only only), `codegraph_explore`, `cocoindex-code search`, `serena get_symbols_overview`, `serena find_symbol`, `serena find_referencing_symbols`
- MCP tools are preferred for symbol/caller lookups — use Read/Grep only as fallback
- Output file exception: MAY write to `temp/deckrd-work/env-profile.md`
