---
title: "MCP Server Configuration"
description: "Configuration and usage guide for MCP servers in deckrd project"
category: "specs"
tags: ["mcp", "servers", "configuration", "cocoindex-code", "filesystem"]
created: "2026-01-14"
version: "0.1.2"
authors:
  - atsushifx <https://github.com/atsushifx>
changes:
  - 0.0.4   2026-01-14  Initial version
  - 0.1.0   2026-03-21  Update configuration to cocoindex-code / filesystem
  - 0.1.1   2026-09-06  Correct .mcp.json table to actual layout, add codex-mcp
  - 0.1.2   2026-09-09  Convert bold-label lists to tables for textlint
copyright:
  - Copyright (c) 2026- atsushifx <https://github.com/atsushifx>
  - This software is released under the MIT License.
  - https://opensource.org/licenses/MIT
status: "published"
---

<!-- textlint-disable  ja-technical-writing/sentence-length -->
<!-- markdownlint-disable line-length -->

## MCP Server Configuration

## Overview

deckrd uses three Model Context Protocol (MCP) servers to provide specialized development tools for Claude Code.

## Configuration File

MCP servers are configured per-plugin in separate `.mcp.json` files:

| File                      | Plugin                | Active servers                        |
| ------------------------- | --------------------- | ------------------------------------- |
| `.mcp.json`               | Root (entire project) | (none)                                |
| `skills/deckrd/.mcp.json` | deckrd plugin         | filesystem, cocoindex-code, codex-mcp |

## MCP Servers

### cocoindex-code

**Purpose**: Semantic code search.

**Configuration**:

```json
{
  "mcpServers": {
    "cocoindex-code": {
      "type": "stdio",
      "command": "ccc",
      "args": ["mcp"]
    }
  }
}
```

**Capabilities**:

- Code search using natural language queries
- Related code exploration based on semantic understanding
- Finds relevant code even when the exact keyword is unknown

**Used by**: deckrd.

**Usage**:

```text
# Search code using natural language
query: "function that handles session initialization"

# Search with language filter
query: "error handling pattern"
lang: "bash"
```

### filesystem

**Purpose**: File system access.

**Configuration**:

```json
{
  "mcpServers": {
    "filesystem": {
      "command": "pnpx",
      "args": ["@modelcontextprotocol/server-filesystem", "."]
    }
  }
}
```

**Capabilities**:

- File read/write operations
- Directory listing
- File pattern search

**Used by**: deckrd

### codex-mcp

**Purpose**: AI-powered code generation and template processing.

**Configuration**:

```json
{
  "mcpServers": {
    "codex-mcp": {
      "type": "stdio",
      "command": "codex",
      "args": ["mcp-server"]
    }
  }
}
```

**Capabilities**:

- Code generation from a prompt
- Independent second-opinion review

**Used by**: deckrd

## Tool Selection

### For Bash Script Analysis

**Use Read / Grep / cocoindex-code**:

- File path is already known → Read tool
- Pattern-based search → Grep tool
- Semantic understanding required → cocoindex-code

### For Documentation

**Use Grep or Read**: Standard text search and file reading.

### For Configuration Files

**Use Read**: Read the file directly.

### For File Operations

**Use filesystem**: When file read/write is required.

## Best Practices

| Practice                               | Reason                                       |
| -------------------------------------- | -------------------------------------------- |
| Use Read for known paths               | Read is fastest when the file path is known  |
| Use Grep for pattern search            | Grep is efficient for keyword-based searches |
| Use cocoindex-code for semantic search | Use it when the keyword is unknown           |
| Narrow the search scope                | Avoid searching unnecessary areas            |
| Choose the right tool for the task     | Select the tool that best fits the operation |

## Troubleshooting

| Issue                     | Solution                                                                    |
| ------------------------- | --------------------------------------------------------------------------- |
| MCP server not starting   | Verify the command exists (ccc, pnpx)                                       |
| cocoindex-code no results | Rephrase the query and retry; remove the `lang` filter to broaden the scope |
| filesystem access denied  | Check permissions of the target directory                                   |
| Plugin not loading MCP    | Verify the corresponding `.mcp.json` file configuration                     |

## References

- MCP Documentation: <https://modelcontextprotocol.io/>
- cocoindex-code: Semantic code search MCP server
- filesystem: File system access MCP server (@modelcontextprotocol/server-filesystem)
- [MCP Servers API Reference](./mcp-servers.md) - Detailed API documentation
