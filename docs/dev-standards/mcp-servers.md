---
title: "MCP Server Configuration"
description: "Configuration and usage guide for MCP servers in deckrd project"
category: "dev-standards"
tags: ["mcp", "servers", "configuration", "serena", "lsmcp"]
created: "2026-01-14"
version: "0.0.4"
authors:
  - atsushifx <https://github.com/atsushifx>
changes:
  - 0.0.4   2026-01-14  初版作成
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

**Location**: `.mcp.json`

All MCP servers are configured in this file at the project root.

## MCP Servers

### serena-mcp (Primary Analysis Tool)

**Purpose**: Semantic code analysis for bash scripts

**Configuration**:

```json
{
  "mcpServers": {
    "serena-mcp": {
      "command": "uvx",
      "args": ["serena-mcp"],
      "disabled": false
    }
  }
}
```

**Capabilities**:

- Symbol-level code navigation
- Semantic search for bash functions
- Code pattern matching
- File structure overview

**Storage**:

- Memories: `.serena/memories/` directory
- Cache: `.serena/cache/` directory

**Key Memories**:

- `project_overview` - Project purpose, features, and architecture
- `project_structure` - Directory layout and organization
- `code_style_and_conventions` - Coding standards and guidelines
- `suggested_commands` - Common development commands
- `task_completion_checklist` - Quality assurance checklist
- `claude_idd_framework` - External IDD framework plugin information

**Usage**:

```bash
# Find bash functions
serena-mcp__find_symbol

# Search code patterns
serena-mcp__search_for_pattern

# Get file overview
serena-mcp__get_symbols_overview
```

### lsmcp (Language Server Protocol)

**Purpose**: LSP-based code intelligence for TypeScript/JavaScript (future use)

**Configuration**:

```json
{
  "mcpServers": {
    "lsmcp": {
      "command": "npx",
      "args": ["-y", "lsmcp", "-p", "typescript"],
      "disabled": false
    }
  }
}
```

**Capabilities**:

- Symbol search and navigation
- Go to definition
- Find references
- Rename symbol
- Code completion
- Type information

**Storage**:

- Cache: `.lsmcp/` directory
- Memories: `.lsmcp/` directory

**Key Memories**:

- `lsmcp_configuration` - Server setup and capabilities
- `lsmcp_deckrd_project` - Project-specific usage guide
- `claude_idd_framework` - IDD framework plugin context

**Current Status**: Configured but underutilized (bash-based codebase)

**Future Usage**: Full IDE-like support when TypeScript is added to the project

**Usage** (when TypeScript is added):

```bash
# Search symbols
lsmcp__search_symbols

# Jump to definition
lsmcp__lsp_get_definitions

# Refactor
lsmcp__lsp_rename_symbol
```

### codex-mcp

**Purpose**: AI-powered code generation and template processing

**Configuration**:

```json
{
  "mcpServers": {
    "codex-mcp": {
      "command": "npx",
      "args": ["-y", "codex-mcp"],
      "disabled": false
    }
  }
}
```

**Capabilities**:

- Template processing
- Code generation
- AI-powered suggestions

**Usage**:

- Issue template generation (IDD framework)
- Code snippet generation
- Boilerplate creation

## Tool Selection

### For Bash Script Analysis

**Use serena-mcp** - Primary tool for bash codebase

### For Documentation

**Use Grep or Read** - Standard text search and file reading

### For Configuration Files

**Use serena-mcp or Read** - Pattern matching or direct file access

### For Future TypeScript

**Use lsmcp** - Full IDE support with LSP

### For Code Generation

**Use codex-mcp** - Template processing and generation

## Memory Management

### Updating Memories

Memories should be updated when:

- Project structure changes significantly
- New conventions are established
- Major features are added
- Plugin architecture evolves

### Memory Format

All memories are stored as Markdown files with clear section structure.

## Best Practices

1. **Check serena-mcp memories first** before asking questions about the project
2. **Use serena-mcp** for all bash script analysis
3. **Keep lsmcp ready** for future TypeScript integration
4. **Update memories** when project structure or conventions change
5. **Use appropriate tools** based on language and task (see Tool Selection)

## Troubleshooting

| Issue                         | Solution                                 |
| ----------------------------- | ---------------------------------------- |
| MCP server not starting       | Check command availability (uvx, npx)    |
| Memories outdated             | Update manually or regenerate            |
| serena-mcp cache issues       | Clear `.serena/cache/` directory         |
| lsmcp not finding TypeScript  | Wait for TypeScript addition to project  |
| codex-mcp generation failures | Check API availability and configuration |

## References

- MCP Documentation: <https://modelcontextprotocol.io/>
- serena-mcp: Semantic code analysis MCP server
- lsmcp: Language Server Protocol MCP server
- codex-mcp: AI code generation MCP server
