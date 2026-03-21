---
title: "Plugin System Architecture"
description: "Detailed documentation of the deckrd plugin architecture and implementation"
category: "developer-guides"
tags: ["plugins", "architecture", "modular"]
created: "2026-01-14"
version: "0.0.4"
authors:
  - atsushifx <https://github.com/atsushifx>
changes:
  - 0.0.4   2026-01-14  Initial version
  - 0.1.0   2026-03-21  Update Integration Points to cocoIndex-code/filesystem, update plugin.json/bootstrap.sh/session.sh/directory structure to match actual implementation
copyright:
  - Copyright (c) 2026- atsushifx <https://github.com/atsushifx>
  - This software is released under the MIT License.
  - https://opensource.org/licenses/MIT
status: "published"
---

<!-- textlint-disable ja-technical-writing/max-comma -->
<!-- markdownlint-disable line-length -->

## Plugin System Architecture

## Overview

deckrd uses Claude Code's plugin system to provide modular, composable workflows. Each plugin is self-contained and follows standard structure conventions.

## Plugin Structure

### Directory Layout

```text
plugins/{plugin-name}/
├── .claude-plugin/
│   └── config.json       # Plugin metadata
├── skills/
│   └── {plugin-name}/
│       ├── references/   # Documentation
│       │   ├── commands/ # Command docs
│       │   └── workflow.md
│       ├── scripts/      # Implementation scripts
│       │   ├── libs/     # bootstrap.sh, session.sh, config.sh, etc.
│       │   ├── subcommands/ # generate-doc.sh, etc.
│       │   ├── init.sh
│       │   ├── req.sh
│       │   └── ...
│       └── assets/       # Templates and prompts
│           ├── templates/
│           └── prompts/
├── agents/               # Agent definitions
│   └── {agent-name}.json
└── README.md            # Plugin documentation
```

### Required Files

#### 1. `.claude-plugin/config.json`

**Purpose**: Plugin metadata and configuration

**Format**:

```json
{
  "name": "deckrd",
  "version": "0.0.4",
  "description": "Document-driven development workflow",
  "author": "atsushifx",
  "license": "MIT",
  "repository": "https://github.com/aglabo/deckrd",
  "skills": ["deckrd"],
  "agents": []
}
```

#### 2. `deckrd.json` (Root)

**Purpose**: Plugin artifact metadata

**Format**:

```json
{
  "name": "deckrd",
  "version": "0.0.4",
  "artifact": {
    "path": "plugins/deckrd"
  }
}
```

#### 3. `README.md`

**Purpose**: Plugin documentation

**Content**:

- Installation instructions
- Command reference
- Usage examples
- Troubleshooting

## Plugin Types

### 1. Main Plugin (deckrd)

**Location**: `plugins/deckrd/`

**Purpose**: Core document-driven workflow

**Components**:

- Skills: `/deckrd` commands (init, req, dr, spec, impl, tasks, status)
- Scripts: Bash implementation of each command
- Templates: Document templates
- Prompts: AI prompts for generation

### 2. Methodology Plugins

**Example**: `plugins/bdd-coder/`

**Purpose**: Development methodology support (e.g., BDD)

**Components**:

- Agents: Methodology-specific agents
- Scripts: Test generation, validation
- Templates: Test templates

### 3. Helper Plugins

**Example**: `plugins/deckrd-coder/`

**Purpose**: Optional developer utilities

**Components**:

- Skills: Helper commands
- Scripts: Utility functions
- Tools: Code generation helpers

## Command Implementation

### Command Structure

Each command follows this pattern:

```bash
#!/usr/bin/env bash

# Script: {command}.sh
# Purpose: {description}
# Usage: claude /deckrd {command}

set -euo pipefail

# Constants
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SESSION_FILE="docs/.deckrd/.session.json"

# Functions
main() {
  # Implementation
}

# Entry point
main "$@"
```

### Command Lifecycle

1. **User invokes command**: `/deckrd {command}`
2. **Claude Code dispatches**: Calls corresponding script
3. **Script executes**: Reads session, performs operations
4. **Script updates state**: Writes to session file
5. **Script returns result**: Claude shows output to user

### Session Management

Commands read/write session state:

```bash
# Read session
get_current_module() {
  jq -r '.module // empty' "$SESSION_FILE"
}

# Write session
update_session() {
  local module=$1
  local phase=$2
  jq --arg mod "$module" --arg ph "$phase" \
    '.module = $mod | .phase = $ph' \
    "$SESSION_FILE" > "$SESSION_FILE.tmp"
  mv "$SESSION_FILE.tmp" "$SESSION_FILE"
}
```

## Agent Definitions

### Agent Structure

```json
{
  "name": "{agent-name}",
  "description": "{agent description}",
  "prompt": "{agent system prompt}",
  "tools": ["Read", "Write", "Edit", "Bash"],
  "env": {}
}
```

### Agent Types

#### 1. Workflow Agents

**Purpose**: Execute specific workflow steps

**Example**: requirements-generator

- Analyzes user input
- Generates requirements document
- Updates session state

#### 2. Validation Agents

**Purpose**: Verify document quality

**Example**: document-validator

- Checks document completeness
- Validates format
- Suggests improvements

#### 3. Helper Agents

**Purpose**: Support tasks

**Example**: template-processor

- Fills in template placeholders
- Formats output
- Ensures consistency

## Integration Points

### With Claude Code

**Plugin Loading**:

```bash
claude plugin install deckrd@deckrd
```

**Command Invocation**:

```bash
/deckrd init  # Dispatched to plugins/deckrd/skills/deckrd/scripts/init.sh
```

### With MCP Servers

MCP servers available during Claude Code command execution:

- cocoindex-code: Semantic code search (used by deckrd-coder)
- filesystem: File system access (used by deckrd and deckrd-coder)

MCP server configuration per plugin:

| Plugin       | MCP config file                | Available servers          |
| ------------ | ------------------------------ | -------------------------- |
| deckrd       | plugins/deckrd/.mcp.json       | filesystem                 |
| deckrd-coder | plugins/deckrd-coder/.mcp.json | filesystem, cocoindex-code |

### With IDD Framework

**Complementary Workflows**:

- deckrd generates task list
- IDD creates issues from tasks
- IDD manages PR lifecycle
- deckrd documents decisions

## Plugin Development

### Creating a New Plugin

#### Step 1: Directory Structure

```bash
mkdir -p plugins/my-plugin/.claude-plugin
mkdir -p plugins/my-plugin/skills/my-plugin/{scripts,references,assets}
mkdir -p plugins/my-plugin/agents
```

#### Step 2: Configuration

Create `.claude-plugin/config.json`:

```json
{
  "name": "my-plugin",
  "version": "0.0.1",
  "description": "My custom plugin",
  "author": "yourname",
  "skills": ["my-plugin"]
}
```

#### Step 3: Implement Commands

Create `skills/my-plugin/scripts/command.sh`:

```bash
#!/usr/bin/env bash
# Your command implementation
```

#### Step 4: Documentation

Create `README.md` with:

- Installation
- Commands
- Examples

#### Step 5: Test

```bash
claude plugin install my-plugin@my-plugin
claude /my-plugin command
```

### Plugin Best Practices

#### 1. Self-Contained

- Include all dependencies
- No external file dependencies
- Clear documentation

#### 2. Consistent Structure

- Follow standard layout
- Use conventional naming
- Match existing patterns

#### 3. Error Handling

```bash
set -euo pipefail  # Strict mode

# Validate inputs
if [[ -z "${MODULE:-}" ]]; then
  echo "Error: MODULE not specified" >&2
  exit 1
fi

# Check prerequisites
if [[ ! -f "$SESSION_FILE" ]]; then
  echo "Error: Session not initialized" >&2
  exit 1
fi
```

#### 4. Logging

```bash
# Use stderr for diagnostics
log_info() {
  echo "[INFO] $*" >&2
}

log_error() {
  echo "[ERROR] $*" >&2
}
```

#### 5. Documentation

- Document all commands
- Provide examples
- Include troubleshooting
- Maintain README

## Testing Plugins

### Manual Testing

```bash
# Install plugin locally
claude plugin install my-plugin@my-plugin

# Test commands
claude /my-plugin init
claude /my-plugin status

# Verify output
cat docs/.my-plugin/.session.json
```

### Integration Testing

```bash
# Test with deckrd workflow
/deckrd init
/my-plugin integrate
/deckrd status

# Test with IDD framework
/my-plugin create-issue
/idd/issue:load
```

## Distribution

### Marketplace Distribution

#### 1. Package Plugin

Create `deckrd.json` at root:

```json
{
  "name": "my-plugin",
  "version": "0.0.1",
  "artifact": {
    "path": "plugins/my-plugin"
  }
}
```

#### 2. Publish

```bash
claude plugin publish
```

#### 3. Install

```bash
claude plugin install my-plugin@my-plugin
```

### Local Distribution

```bash
# Copy to Claude plugin directory
cp -r plugins/my-plugin ~/.claude/plugins/my-plugin

# Reload Claude Code
claude plugin list
```

## Plugin Lifecycle

### Installation

1. User runs `claude plugin install`
2. Claude downloads plugin
3. Claude validates structure
4. Claude registers commands
5. Commands available via `/`

### Update

1. User runs `claude plugin update`
2. Claude checks for new version
3. Claude downloads update
4. Claude reloads plugin
5. New commands available

### Uninstall

1. User runs `claude plugin uninstall`
2. Claude removes plugin files
3. Claude unregisters commands
4. Commands no longer available

## Security Considerations

### Input Validation

```bash
# Sanitize user input
sanitize_input() {
  local input=$1
  # Remove dangerous characters
  echo "$input" | tr -dc '[:alnum:] -_.'
}
```

### File Operations

```bash
# Use absolute paths
readonly BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../.." && pwd)"

# Validate paths
if [[ ! "$FILE" =~ ^"$BASE_DIR" ]]; then
  echo "Error: Invalid path" >&2
  exit 1
fi
```

### Secret Handling

- Never hardcode secrets
- Use environment variables
- Check with gitleaks before commit

## Related Documentation

- [Architecture Overview](architecture.md) - System architecture
- [Development Workflow](./workflow.md) - Development process
- [Deckrd Commands](./deckrd-commands.md) - Command reference
- [Code Quality](../contributing/code-quality.md) - Quality standards
