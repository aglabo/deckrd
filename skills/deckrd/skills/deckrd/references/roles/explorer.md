---
title: "Role: explorer"
description: "Procedure for read-only codebase investigation for deckrd commands (scopes: codebase-extraction, codebase-survey, prior-art, pattern-detection). Canonical steps for the explore-agent"
version: 1.0.0
---

## Role: explorer

<!-- textlint-disable ja-technical-writing/max-comma, ja-technical-writing/sentence-length -->
<!-- markdownlint-disable line-length -->

This Role is the **canonical procedure** for investigating the project without filling the main context.

- In Claude Code, the `explore-agent` agent (`agents/explore-agent.md` at the plugin root) loads this Role and runs it in a sub-context.
- Where agents are not available, the main session follows this Role step by step itself.

Paths are resolved as follows:

- Bundled resources (`assets/`, `references/`) are relative to `skill_dir`, the deckrd skill directory passed by the caller.
- Everything else is relative to the project root and stays under it: project files, `<modulePath>` (`docs/.deckrd/<namespace>/<module>`), and paths given by the caller. The skill may be installed outside the project, so never resolve these against the skill directory.
- Local data is under `local_dir`, an absolute path passed by the caller. Write `<local_dir>/session.json` and `<local_dir>/temp/...`, never a literal `.local/deckrd`. `temp` is always `<local_dir>/temp`.

## Responsibility

Investigate the codebase and project documentation, then write findings to a temp file.
The main session reads the summary and proceeds without holding raw file contents in context.

## Inputs

| Parameter   | Values                                                                          | Description                             |
| ----------- | ------------------------------------------------------------------------------- | --------------------------------------- |
| `skill_dir` | Absolute path                                                                   | Skill directory (where `SKILL.md` is)   |
| `local_dir` | Absolute path                                                                   | Deckrd local data (`DECKRD_LOCAL_DATA`) |
| `directory` | Path string                                                                     | Root directory to investigate           |
| `scope`     | `codebase-extraction` / `codebase-survey` / `prior-art` / `pattern-detection`   | Investigation mode                      |
| `focus`     | Comma-separated keywords (optional)                                             | Narrow the investigation to these areas |
| `module`    | `<namespace>/<module>` (required for `codebase-extraction` / `codebase-survey`) | Active module, resolved by the caller   |

## Scope Definitions

### `codebase-extraction`

Extract and analyze existing code for reverse engineering:

1. Use the `module` input (`<namespace>/<module>`) passed by the caller as the active module
2. Use `Glob` to enumerate all source files, test files, and existing documentation
3. Use `Read` to scan source files and extract behavioral patterns:
   - Entry points and public interfaces
   - Observable behaviors (inputs, outputs, side effects)
   - Error handling patterns
   - Configuration and constraints
4. Use `Grep` to find patterns relevant to `focus` keywords across the codebase
5. Use `Bash` (`git log --oneline`, `git diff --stat`) to identify historical change units
6. Identify items that can be directly traced vs. items that must be inferred

Output file: `<local_dir>/temp/deckrd-work/codebase-extraction.md`

### `codebase-survey`

Survey the module and surrounding codebase:

1. Use the `module` input (`<namespace>/<module>`) passed by the caller as the active module
2. Use `Glob` to map the module directory structure
3. Use `Read` to scan existing documentation files (requirements, specifications, etc.)
4. Use `Grep` to locate source files relevant to `focus` keywords
5. Identify existing patterns, naming conventions, and integration points

Output file: `<local_dir>/temp/deckrd-work/codebase-context.md`

### `prior-art`

Search for prior experiments and related work:

1. Check `temp/`, `docs/`, `examples/` for PoC or prototype code
2. Run `git log --oneline --all` to find branches with related work
3. Note any decisions already made in prior experiments

Output file: `<local_dir>/temp/deckrd-work/prior-art.md`

### `pattern-detection`

Detect development environment configuration (used by bdd-coder):

1. Locate repository root or sub-package root
2. Detect language from manifest files
   (e.g., `package.json`, `Cargo.toml`, `setup.py`, `go.mod`)
3. Identify tool configurations: build, lint, type-check, test, formatter
4. Read `<local_dir>/.project.json` if present

Output file: `<local_dir>/temp/deckrd-work/env-profile.md`

## Output Format

Write findings to the designated output file using this structure:

```markdown
# Explore Agent Report

scope: <scope>
focus: <focus keywords or "none">
directory: <directory>
generated: <timestamp>

## Summary

<≤ 200 words summary of findings for the main session>

## Details

<Full investigation details>
```

Return the **Summary section only** to the main session.
The main session reads the full output file only when needed.

## Constraints

- Read-only: MUST NOT use `Write` or `Edit` tools on any file except the designated output file
- No session files: MUST NOT read or write `session.json`
- No side effects: MUST NOT run commands that modify the filesystem or network

- Allowed tools: `Read`, `Grep`, `Glob`, `Bash` (read-only commands only, e.g., `git log --oneline`), `Write` (output file only)

- Output file exception: MAY write to `<local_dir>/temp/deckrd-work/*.md`

## Agent Invocation Pattern

The main session spawns this agent as follows:

```yaml
Spawn explore-agent:
  directory: <project root>
  scope: codebase-survey
  focus: <feature keywords>
  module: <namespace>/<module> # caller reads <local_dir>/session.json
```

The main session then:

1. Continues with non-blocking work while the agent runs
2. Reads the Summary from the agent result
3. Reads `<local_dir>/temp/deckrd-work/codebase-context.md` only when deeper context is needed
