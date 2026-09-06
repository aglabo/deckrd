---
title: "MCP Servers API Reference"
description: "Complete API reference for MCP servers used in deckrd project"
category: "specs"
tags: ["api", "mcp", "cocoindex-code", "filesystem", "codex-mcp"]
created: "2026-01-14"
version: "0.2.0"
authors:
  - atsushifx <https://github.com/atsushifx>
changes:
  - 0.0.4   2026-01-14  Initial version
  - 0.1.0   2026-03-21  Update to cocoindex-code / filesystem
  - 0.1.1   2026-09-06  Fix stale plugins/ paths to skills/
  - 0.2.0   2026-09-06  Remove serena-mcp / lsmcp sections, add cocoindex-code and tool naming
copyright:
  - Copyright (c) 2026- atsushifx <https://github.com/atsushifx>
  - This software is released under the MIT License.
  - https://opensource.org/licenses/MIT
status: "published"
---

<!-- textlint-disable
  ja-technical-writing/sentence-length,
  ja-technical-writing/no-exclamation-question-mark,
  ja-technical-writing/max-comma -->
<!-- markdownlint-disable line-length -->

## MCP Servers API Reference

## Overview

This document provides the API reference for the three MCP servers used in the deckrd project.
All three are declared by the deckrd plugin in `skills/deckrd/.mcp.json`.

| Server           | Purpose                    | Declared in               |
| ---------------- | -------------------------- | ------------------------- |
| `cocoindex-code` | Semantic code search       | `skills/deckrd/.mcp.json` |
| `filesystem`     | File system access         | `skills/deckrd/.mcp.json` |
| `codex-mcp`      | Independent AI code review | `skills/deckrd/.mcp.json` |

The `bdd-coder` plugin declares no MCP server of its own; it uses the servers provided by
whichever plugins are installed alongside it.

See also: [MCP Server Configuration](./mcp-servers-config.md) for setup instructions.

## Tool Naming

Tool names differ depending on where the server is declared. Getting this wrong is silent:
the call simply never resolves.

| Declared in                | Tool name                               |
| -------------------------- | --------------------------------------- |
| Project `.mcp.json` (root) | `mcp__<server>__<tool>`                 |
| A plugin's `.mcp.json`     | `mcp__plugin_<plugin>_<server>__<tool>` |

Because deckrd declares its servers inside the plugin, the scoped form is the only valid one:

```text
mcp__plugin_deckrd_cocoindex-code__search
mcp__plugin_deckrd_filesystem__read_text_file
mcp__plugin_deckrd_codex-mcp__codex
```

Two caveats when writing an agent's `tools:` or a skill's `allowed-tools:`:

- **Deduplication.** When two installed plugins declare the same server command, only one
  connects. The IDD framework also ships `codex mcp-server` as `codex-mcp`, so on a machine
  with both plugins the live name may be `mcp__plugin_idd_codex-mcp__codex` instead.
  List both scoped names; the one that does not resolve is ignored.
- **Verify, do not guess.** Run `claude mcp list` to see which servers actually connected.

## cocoindex-code

**Purpose**: Semantic code search across the codebase.

**Command**: `ccc mcp`

### search

Finds code by meaning rather than by text match. Accepts a natural language query or a
code snippet, and returns matching chunks with file paths, line numbers, and relevance scores.

**Tool name**: `mcp__plugin_deckrd_cocoindex-code__search`

**Parameters**:

- `query` (string, required) - Natural language query or code snippet
- `limit` (integer, optional, default 5) - Maximum results, 1-100
- `offset` (integer, optional, default 0) - Results to skip, for pagination
- `languages` (string[], optional) - Language filter, e.g. `["python", "typescript"]`
- `paths` (string[], optional) - Path filter using GLOB wildcards, e.g. `["src/utils/*"]`
- `refresh_index` (boolean, optional, default true) - Incrementally update the index before searching

Start with a small `limit`; if most results look relevant, paginate with `offset`.
Set `refresh_index: false` for consecutive queries when the codebase has not changed.

## filesystem

**Purpose**: File system access, scoped to allowed directories.

**Command**: `npx -y @modelcontextprotocol/server-filesystem .`

**Tool name prefix**: `mcp__plugin_deckrd_filesystem__`

### Read APIs

| Tool                        | Purpose                               | Parameters                                      |
| --------------------------- | ------------------------------------- | ----------------------------------------------- |
| `read_text_file`            | Read a file as text                   | `path` (required), `head`, `tail`               |
| `read_media_file`           | Read an image or audio file as base64 | `path` (required)                               |
| `read_multiple_files`       | Read several files in one call        | `paths` (required)                              |
| `list_directory`            | List directory entries                | `path` (required)                               |
| `list_directory_with_sizes` | List entries with file sizes          | `path` (required), `sortBy`                     |
| `directory_tree`            | Recursive tree as JSON                | `path` (required), `excludePatterns`            |
| `search_files`              | Recursive glob search                 | `path`, `pattern` (required), `excludePatterns` |
| `get_file_info`             | Size, timestamps, permissions         | `path` (required)                               |
| `list_allowed_directories`  | Directories the server may access     | none                                            |

`read_file` also exists but is deprecated in favor of `read_text_file`.

### Write APIs

| Tool               | Purpose                                    | Parameters                           |
| ------------------ | ------------------------------------------ | ------------------------------------ |
| `write_file`       | Create or overwrite a file                 | `path`, `content` (required)         |
| `edit_file`        | Line-based edits, returns a git-style diff | `path`, `edits` (required), `dryRun` |
| `create_directory` | Create a directory, including parents      | `path` (required)                    |
| `move_file`        | Move or rename                             | `source`, `destination` (required)   |

Each entry in `edits` is `{ oldText, newText }`, and `oldText` must match exactly.
Use `dryRun: true` to preview the diff before applying.

## codex-mcp

**Purpose**: Run an independent Codex session for second-opinion review and code generation.

**Command**: `codex mcp-server`

Used by `/deckrd:deckrd-review` and by the `code-reviewer` agent of `bdd-coder`.

### codex

Starts a Codex session.

**Tool name**: `mcp__plugin_deckrd_codex-mcp__codex`
(or `mcp__plugin_idd_codex-mcp__codex` when the IDD framework wins deduplication)

**Parameters**:

- `prompt` (string, required) - Initial user prompt
- `model` (string, optional) - Model override, e.g. `gpt-5.2-codex`
- `cwd` (string, optional) - Working directory for the session
- `sandbox` (string, optional) - `read-only`, `workspace-write`, or `danger-full-access`
- `approval-policy` (string, optional) - `untrusted`, `on-request`, or `never`
- `base-instructions` / `developer-instructions` (string, optional) - Instruction overrides
- `config` (object, optional) - Settings that override `CODEX_HOME/config.toml`

For review use, pass `sandbox: "read-only"` so the reviewer cannot modify the working tree.

### codex-reply

Continues an existing Codex conversation.

**Tool name**: `mcp__plugin_deckrd_codex-mcp__codex-reply`

**Parameters**:

- `prompt` (string, required) - Next user prompt
- `threadId` (string, required in practice) - Thread id returned by the `codex` call

## Usage Patterns

### Locating existing code before implementing

```text
mcp__plugin_deckrd_cocoindex-code__search
  query: "function that handles session initialization"
  paths: ["skills/deckrd/**"]
  limit: 5
```

### Independent review of a change

```text
mcp__plugin_deckrd_codex-mcp__codex
  prompt: "Review the following implementation for correctness and test quality: ..."
  sandbox: "read-only"
```

## Performance Tips

### Token Usage

1. Search before reading. Use `cocoindex-code` to narrow down which files matter.
2. Bound every read. Use `head` / `tail` on `read_text_file` instead of reading whole files.
3. Batch reads. `read_multiple_files` costs one round trip instead of several.

### Search Optimization

1. `cocoindex-code` finds related code even when the exact keyword is unknown.
2. Narrow the scope with `languages` and `paths` to cut irrelevant matches.
3. Set `refresh_index: false` for repeated queries on an unchanged tree.

## Error Handling

| Symptom                          | Cause and remedy                                                              |
| -------------------------------- | ----------------------------------------------------------------------------- |
| The tool call never resolves     | Wrong tool name. Use the scoped form and confirm with `claude mcp list`       |
| A codex tool is missing          | Deduplicated against another plugin. List both scoped names in `tools:`       |
| `cocoindex-code` returns nothing | Rephrase the query, or drop the `languages` / `paths` filters                 |
| `filesystem` access denied       | The path is outside the allowed directories; check `list_allowed_directories` |

## Related Documentation

- [MCP Server Configuration](./mcp-servers-config.md) - Setup guide
- [Tool Selection Guide](../developer-guides/tool-selection.md) - When to use which tool
- [Architecture](../developer-guides/architecture.md) - System architecture
- [Development Workflow](../developer-guides/workflow.md) - Workflow integration
