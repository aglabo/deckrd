---
title: "Tool Selection Guide"
description: "Guide for selecting the right tool for each development task in deckrd project"
category: "developer-guides"
tags: ["tools", "mcp", "selection-guide", "cocoindex-code"]
created: "2026-01-14"
version: "0.4.0"
authors:
  - atsushifx <https://github.com/atsushifx>
changes:
  - 0.0.4   2026-01-14  Initial version
  - 0.1.0   2026-03-21  Update from serena-mcp/lsmcp/codex-mcp to cocoindex-code/filesystem
  - 0.4.0   2026-06-19  Update skill paths from plugins/ to skills/, rename deckrd-coder to bdd-coder
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
| File operations       | filesystem MCP | Read/write operations |
| Code generation       | codex-mcp      | AI-powered generation |
| Format code           | dprint         | Consistent formatting |
| Check commit messages | commitlint     | Conventional Commits  |
| Detect secrets        | gitleaks       | Security scanning     |

## For Bash Script Analysis

### Use cocoindex-code

**When**:

- Searching for code using natural language
- Function name or keyword is unknown
- Looking for semantically related code

### Use Grep / Glob

**When**:

- Known keyword or file pattern
- Fast keyword search across files
- Listing files by pattern

```bash
# Find function definition
Grep "function _resolve_deckrd_root" --path skills/_runtime/

# List all scripts
Glob "skills/deckrd/skills/deckrd/scripts/*.sh"
```

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
Read docs/developer-guides/architecture.md --offset 10 --limit 50
```

### Use Grep Tool

**When**:

- Quick keyword search
- Multiple files
- Pattern matching

**Examples**:

```bash
# Search for keyword
Grep "bdd-coder" --path docs/

# With context
Grep "installation" --path docs/ -C 3
```

## For Configuration Files

### YAML/TOML/JSON

**Option 1: Read Tool** (Simple)

```bash
# Direct read
Read .mcp.json
Read lefthook.yml
Read .claude-plugin/marketplace.json
```

**Option 2: Grep** (Search within config)

```bash
# Search for specific key
Grep "bdd-coder" --path .claude-plugin/
```

## For Code Generation

### Use codex-mcp

**When**:

- Need AI-powered generation
- Template processing
- Code suggestions
- Independent second opinion on documents

**Use Cases**:

- Generate boilerplate code
- Fill in templates
- Critical review via `/deckrd:deckrd-review`

## For Command/Skill Search

### deckrd Commands

**Location**: `skills/deckrd/skills/deckrd/`

**Tools**:

```bash
# Option 1: Glob (list files)
Glob "skills/deckrd/skills/deckrd/scripts/*.sh"

# Option 2: Grep (search commands)
Grep "deckrd init" --path skills/deckrd/

# Option 3: cocoindex-code (semantic search)
# query: "deckrd init command implementation"
```

### bdd-coder Commands

**Location**: `skills/bdd-coder/skills/bdd-coder/`

**Tools**:

```bash
# List skill files
Glob "skills/bdd-coder/skills/bdd-coder/**/*.md"

# Search for agent definitions
Grep "checklist-builder" --path skills/bdd-coder/agents/
```

### IDD Framework Commands (External)

**Location**: `C:\Users\atsushifx\.claude\plugins\marketplaces\claude-idd-framework-marketplace\plugins\claude-idd-framework`

**Important**: Always search in this external path for IDD commands

**Tools**:

```bash
# Option 1: Glob (list files)
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
  ├─ Find files by pattern? → Glob
  ├─ Search content? → Grep or cocoindex-code
  └─ Generate code? → codex-mcp
```

### For Project Understanding

```text
What do you want to know?
  ├─ Project structure? → Glob (recursive pattern)
  ├─ Available commands? → Search skills/ directories
  ├─ Configuration? → Read .mcp.json, lefthook.yml
  ├─ Documentation? → Read docs/*.md
  └─ Code patterns? → Grep or cocoindex-code
```

## Performance Considerations

### Token Usage

**Minimize**:

1. Use the Read tool directly for known file paths
2. Use Glob / Grep for pattern-based searches
3. Read only the required range (offset/limit)

**Example** (Good):

```bash
# Efficient: read known path directly
Read skills/deckrd/skills/deckrd/scripts/init.sh --limit 50
```

**Example** (Bad):

```bash
# Inefficient: reads beyond what is needed
Read skills/deckrd/skills/deckrd/scripts/init.sh  # reads entire file
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
Read skills/deckrd/skills/deckrd/scripts/new-script.sh

# Step 2: Search for a specific function
Grep "main()" --path skills/deckrd/skills/deckrd/scripts/new-script.sh -C 5
```

### Scenario 2: Finding Command Implementation

```bash
# Step 1: Find the file
Glob "skills/deckrd/skills/deckrd/scripts/*init*"

# Step 2: Read the implementation
Read skills/deckrd/skills/deckrd/scripts/init.sh
```

### Scenario 3: Searching Documentation

```bash
# Step 1: Find related documents
Grep "MCP servers" --path docs/ --output-mode files_with_matches

# Step 2: Read the document
Read docs/specs/mcp-servers.md
```

### Scenario 4: Finding bdd-coder Agent Logic

```bash
# Semantic search with cocoindex-code
# query: "checklist builder phase 3 spec coverage"
# lang: "markdown"
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

4. **Using old plugins/ paths**

   ```bash
   # Bad: outdated path
   Read plugins/deckrd/skills/deckrd/scripts/init.sh
   # Good: current path
   Read skills/deckrd/skills/deckrd/scripts/init.sh
   ```

### ✅ Do Instead

1. **Use dedicated tools**

   ```bash
   # Good
   Read skills/deckrd/skills/deckrd/scripts/init.sh
   Glob "skills/**/*.sh"
   ```

2. **Narrow the scope**

   ```bash
   # Good
   Grep "function" --path skills/deckrd/skills/deckrd/scripts/
   ```

3. **Use current skill paths**

   ```bash
   # Good
   Read skills/deckrd/skills/deckrd/references/commands/init.md
   Read skills/bdd-coder/skills/bdd-coder/SKILL.md
   ```

## Related Documentation

- [MCP Servers API Reference](../specs/mcp-servers.md) - Detailed API docs
- [Architecture](./architecture.md) - System design
- [Development Workflow](./workflow.md) - Workflow integration
