---
title: "Tool Selection Guide"
description: "Guide for selecting the right tool for each development task in deckrd project"
category: "developer-guides"
tags: ["tools", "mcp", "selection-guide", "cocoindex-code"]
created: "2026-01-14"
version: "0.1.0"
authors:
  - atsushifx <https://github.com/atsushifx>
changes:
  - 0.0.4   2026-01-14  Initial version
  - 0.1.0   2026-03-21  Update from serena-mcp/lsmcp/codex-mcp to cocoindex-code/filesystem
copyright:
  - Copyright (c) 2026- atsushifx <https://github.com/atsushifx>
  - This software is released under the MIT License.
  - https://opensource.org/licenses/MIT
status: "published"
---

<!-- textlint-disable ja-technical-writing/sentence-length -->
<!-- markdownlint-disable line-length -->

## Tool Selection Guide

## Overview

The deckrd project uses multiple tools and MCP servers for different tasks. This guide helps you choose the right tool for each situation.

## Quick Reference

| Task                  | Tool           | Why                   |
| --------------------- | -------------- | --------------------- |
| Semantic code search  | cocoindex-code | Meaning-aware search  |
| Read a file           | Read tool      | Direct access         |
| Pattern search        | Grep tool      | Fast keyword search   |
| List files            | Glob tool      | Pattern matching      |
| File operations       | filesystem     | Read/write operations |
| Format code           | dprint         | Consistent formatting |
| Check commit messages | commitlint     | Conventional Commits  |
| Detect secrets        | gitleaks       | Security scanning     |

## For Bash Script Analysis

### Use serena-mcp

**When**:

- Analyzing bash scripts
- Finding functions/symbols
- Understanding code structure
- Searching code patterns

**Tools**:

#### get_symbols_overview

**Use for**: Getting high-level overview of a bash script

```bash
serena-mcp get_symbols_overview --relative-path "scripts/init.sh"
```

**Returns**: List of functions and symbols

#### find_symbol

**Use for**: Finding specific functions or symbols

```bash
serena-mcp find_symbol --name-path-pattern "main" --include-body true
```

**Returns**: Symbol definition with body

- Searching for code using natural language
- Function name or keyword is unknown
- Looking for semantically related code

## For Documentation

### Use Read Tool

**When**:

- Reading specific files
- Known file paths
- Need exact content

**Examples**:

```bash
# Read entire file
Read README.md

# Read specific range
Read setup.md --offset 10 --limit 50
```

### Use Grep Tool

**When**:

- Quick keyword search
- Multiple files
- Pattern matching

**Examples**:

```bash
# Search for keyword
Grep "installation" --path docs/

# With context
Grep "error" --path logs/ -C 3
```

### Use serena-mcp search_for_pattern

**When**:

- Complex regex patterns
- Need structured results
- Searching code and docs

**Example**:

```bash
serena-mcp search_for_pattern --substring-pattern "## Overview" \
  --paths-include-glob "**/*.md"
```

## For Configuration Files

### YAML/TOML/JSON

**Option 1: Read Tool** (Simple)

```bash
# Direct read
Read .mcp.json
Read lefthook.yml
```

**Option 2: serena-mcp** (Complex)

```bash
# Pattern matching in config
serena-mcp search_for_pattern --substring-pattern "serena-mcp" \
  --relative-path ".mcp.json"
```

## For TypeScript/JavaScript (Future)

### Use lsmcp

**When**:

- TypeScript project added
- Need IDE-like features
- Refactoring TypeScript code

**Tools**:

#### search_symbols

**Use for**: Finding classes, interfaces, functions

```bash
lsmcp search_symbols --query "MyClass" --kind "Class"
```

#### lsp_get_definitions

**Use for**: Jump to definition

```bash
lsmcp lsp_get_definitions --root /path/to/project \
  --relativePath "src/index.ts" --line 10 --symbolName "MyClass"
```

#### lsp_rename_symbol

**Use for**: Refactoring

```bash
lsmcp lsp_rename_symbol --root /path/to/project \
  --relativePath "src/index.ts" --textTarget "OldName" --newName "NewName"
```

#### lsp_get_diagnostics

**Use for**: Finding errors and warnings

```bash
lsmcp lsp_get_diagnostics --root /path/to/project \
  --relativePath "src/index.ts"
```

## For Code Generation

### Use codex-mcp

**When**:

- Need AI-powered generation
- Template processing
- Code suggestions

**Use Cases**:

- Generate boilerplate code
- Fill in templates
- Create documentation from code
- Suggest improvements

## For Command/Plugin Search

### deckrd Commands

**Location**: `plugins/deckrd/skills/deckrd/`

**Tools**:

```bash
# Option 1: Glob (list files)
Glob "plugins/deckrd/skills/deckrd/scripts/*.sh"

# Option 2: Grep (search commands)
Grep "deckrd init" --path plugins/deckrd/

# Option 3: cocoindex-code (semantic search)
# query: "deckrd init command implementation"
```

### IDD Framework Commands (External)

**Location**: `C:\Users\atsushifx\.claude\plugins\marketplaces\claude-idd-framework-marketplace\plugins\claude-idd-framework`

**Important**: Always search in this external path for IDD commands

**Tools**:

```bash
# Option 1: lsmcp (for external plugin directory navigation)
lsmcp list_dir --relativePath "." --recursive false

# Option 2: Glob (list files)
Glob "~/.claude/plugins/marketplaces/**/commands/**/*.md"
```

## Decision Tree

### For Code Analysis

```text
Do you know the search keyword?
  ├─ Yes → Do you know the file path?
  │   ├─ Yes → Read tool
  │   └─ No  → Grep tool
  │
  └─ No → cocoindex-code (natural language query)
```

### For File Operations

```text
What do you need?
  ├─ Specific file? → Read tool
  ├─ Find files by pattern? → serena-mcp find_file or Glob
  ├─ List directory? → serena-mcp list_dir
  ├─ Search content? → Grep or serena-mcp search_for_pattern
  └─ Generate code? → codex-mcp
```

### For Project Understanding

```text
What do you want to know?
  ├─ Project structure? → serena-mcp list_dir (recursive)
  ├─ Available commands? → Search plugin directories
  ├─ Configuration? → Read .mcp.json, lefthook.yml
  ├─ Documentation? → Read docs/*.md
  └─ Code patterns? → serena-mcp search_for_pattern
```

## Performance Considerations

### Token Usage

**Minimize**:

1. Use the Read tool directly for known file paths
2. Use Glob / Grep for pattern-based searches
3. Read only the required range (offset/limit)
4. Read only what you need

**Example** (Good):

```bash
# Efficient: read known path directly
Read plugins/deckrd/skills/deckrd/scripts/init.sh --limit 50
```

**Example** (Bad):

```bash
# Inefficient: reads beyond what is needed
Read plugins/deckrd/skills/deckrd/scripts/init.sh  # reads entire file
```

### Execution Speed

**Fast**:

- Read (known path)
- Grep (simple pattern)
- Glob (list files)

**Medium**:

- cocoindex-code (semantic search)

**Optimization**:

1. Narrow the search scope (specify directory with `--path`)
2. Use specific patterns (minimize wildcards)
3. Run independent queries in parallel

## Common Scenarios

### Scenario 1: Understanding a New Bash Script

```bash
# Step 1: Read the file
Read plugins/deckrd/skills/deckrd/scripts/new-script.sh

# Step 2: Search for a specific function
Grep "function main" --path plugins/deckrd/skills/deckrd/scripts/new-script.sh -C 5
```

### Scenario 2: Finding Command Implementation

```bash
# Step 1: Find the file
Glob "plugins/deckrd/skills/deckrd/scripts/*init*"

# Step 2: Read the implementation
Read plugins/deckrd/skills/deckrd/scripts/init.sh
```

### Scenario 3: Searching Documentation

```bash
# Step 1: Find related documents
Grep "MCP servers" --path docs/ --output-mode files_with_matches

# Step 2: Read the document
Read docs/specs/mcp-servers.md
```

### Scenario 4: Analyzing External Plugin

```bash
# Semantic search with cocoindex-code
# query: "session initialization function"
# lang: "bash"
```

## Anti-Patterns

### ❌ Don't Do

1. **Using Bash commands for file operations**

   ```bash
   # Bad
   Bash cat scripts/init.sh
   Bash find . -name "*.sh"
   ```

2. **Searching a wider scope than necessary**

   ```bash
   # Bad: searching the entire project
   Grep "function" --path .
   ```

3. **Searching when the file path is already known**

   ```bash
   # Bad: searching when path is known
   Grep "mcp-servers" --path docs/
   # Good: read directly
   Read docs/specs/mcp-servers.md
   ```

### ✅ Do Instead

1. **Use dedicated tools**

   ```bash
   # Good
   Read scripts/init.sh
   Glob "**/*.sh"
   ```

2. **Narrow the scope**

   ```bash
   # Good
   serena-mcp search_for_pattern --substring-pattern "function" \
     --relative-path "scripts/"
   ```

3. **Read known paths directly**

   ```bash
   # Good
   Read docs/specs/mcp-servers.md
   ```

## Related Documentation

- [MCP Servers API Reference](../specs/mcp-servers.md) - Detailed API docs
- [MCP Server Configuration](mcp-servers.md) - Setup and configuration
- [Architecture](./architecture.md) - System design
- [Development Workflow](./workflow.md) - Workflow integration
