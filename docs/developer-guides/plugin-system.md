---
title: "Plugin System Architecture"
description: "Detailed documentation of the deckrd plugin architecture and implementation"
category: "developer-guides"
tags: ["plugins", "skills", "architecture", "modular"]
created: "2026-01-14"
version: "0.4.0"
authors:
  - atsushifx <https://github.com/atsushifx>
changes:
  - 0.0.4   2026-01-14  Initial version
  - 0.1.0   2026-03-21  Update Integration Points to cocoIndex-code/filesystem, update plugin.json/bootstrap.sh/session.sh/directory structure to match actual implementation
  - 0.4.0   2026-06-19  Rename deckrd-coder to bdd-coder, update paths from plugins/ to skills/
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

deckrd uses Claude Code's Agent Skills system to provide modular, composable workflows. Each skill is self-contained and follows standard structure conventions.

## Skill Structure

### Directory Layout

```text
skills/{skill-name}/
├── .claude-plugin/
│   └── plugin.json       # Skill metadata
├── agents/               # Agent definitions
│   └── {agent-name}.md
└── skills/
    └── {skill-name}/
        ├── SKILL.md      # Skill entrypoint
        ├── references/   # Documentation
        │   ├── commands/ # Command docs
        │   └── workflow.md
        ├── scripts/      # Implementation scripts
        │   ├── libs/     # bootstrap.lib.sh, etc.
        │   ├── subcommands/
        │   └── __tests__/
        └── assets/       # Templates and prompts
            ├── templates/
            └── prompts/
```

### Required Files

#### 1. `.claude-plugin/plugin.json`

**Purpose**: Skill metadata and version

**Format**:

```json
{
  "name": "deckrd",
  "version": "0.4.0"
}
```

#### 2. `skills/{name}/SKILL.md`

**Purpose**: Skill entrypoint — defines the skill's command, system prompt, and tool access

#### 3. `deckrd.json` (Root)

**Purpose**: Marketplace artifact metadata

**Format**:

```json
{
  "name": "deckrd",
  "version": "0.4.0"
}
```

## Skill Types

### 1. Main Skill (deckrd)

**Location**: `skills/deckrd/`

**Purpose**: Core document-driven workflow

**Components**:

- Skills: `/deckrd` commands (init, req, dr, spec, impl, tasks, status, review)
- Scripts: Bash implementation of each command
- Templates: Document templates
- Prompts: AI prompts for generation

### 2. Methodology Skill (bdd-coder)

**Location**: `skills/bdd-coder/`

**Purpose**: BDD implementation with strict Red-Green-Refactor cycle

**Components**:

- Agents: checklist-builder, bdd-coder, code-reviewer, explore-agent
- Templates: Test templates per language
- References: BDD cycle documentation

### 3. Shared Runtime

**Location**: `skills/_runtime/`

**Purpose**: Shared libraries used by both deckrd and bdd-coder

**Components**:

- `libs/bootstrap.lib.sh` — environment initialization
- `libs/kv-store.lib.sh` — key-value state management
- `libs/naming.lib.sh` — filename generation utilities
- `libs/__tests__/` — unit and functional tests

## Command Implementation

### Command Structure

Each command follows this pattern:

```bash
#!/usr/bin/env bash

# Script: {command}.sh
# Purpose: {description}
# Usage: claude /deckrd {command}

set -euo pipefail

# Source bootstrap
. "${DECKRD_ROOT}/skills/deckrd/skills/deckrd/scripts/libs/bootstrap.lib.sh"

# Functions
main() {
  # Implementation
}

# Entry point
main "$@"
```

### Command Lifecycle

1. **User invokes command**: `/deckrd {command}`
2. **Claude Code dispatches**: Calls corresponding skill
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

Agent definitions are stored as Markdown files under `agents/`:

```markdown
---
name: { agent-name }
description: { agent description }
tools: [Read, Write, Edit, Bash, Grep, Glob]
---

{agent system prompt}
```

### Agent Types in deckrd

#### explore-agent

**Purpose**: Read-only codebase investigation — protects main context window

**Scope**: codebase-extraction, codebase-survey, prior-art, pattern-detection

### Agent Types in bdd-coder

#### checklist-builder

**Purpose**: Converts natural-language instructions into BDD implementation checklists

#### bdd-coder

**Purpose**: Strict BDD implementation — 1 message = 1 test, Red-Green-Refactor per assertion

#### code-reviewer

**Purpose**: Post-implementation review — CC/CRAP scoring + Codex second opinion

#### explore-agent

**Purpose**: Environment detection — detects language, test framework, and tool commands

## Integration Points

### With Claude Code

**Skill Installation**:

```bash
# via gh skills
gh skills install aglabo/deckrd

# via claude plugin
claude plugin marketplace add aglabo/deckrd
claude plugin install deckrd@deckrd
claude plugin install bdd-coder@deckrd
```

**Command Invocation**:

```bash
/deckrd init        # deckrd skill
/bdd-coder:bdd-coder T01-01   # bdd-coder skill
/deckrd:deckrd-review req     # deckrd-review skill
```

### With MCP Servers

MCP servers available during Claude Code command execution:

- cocoindex-code: Semantic code search (used by bdd-coder)
- filesystem: File system access (used by deckrd and bdd-coder)

MCP server configuration per skill:

| Skill     | MCP config file            | Available servers          |
| --------- | -------------------------- | -------------------------- |
| deckrd    | skills/deckrd/.mcp.json    | filesystem                 |
| bdd-coder | skills/bdd-coder/.mcp.json | filesystem, cocoindex-code |

### With IDD Framework

**Complementary Workflows**:

- deckrd generates task list
- IDD creates issues from tasks
- bdd-coder implements tasks via BDD cycle
- IDD manages PR lifecycle

## Skill Development

### Creating a New Skill

#### Step 1: Directory Structure

```bash
mkdir -p skills/my-skill/.claude-plugin
mkdir -p skills/my-skill/agents
mkdir -p skills/my-skill/skills/my-skill/{scripts,references,assets}
```

#### Step 2: Configuration

Create `.claude-plugin/plugin.json`:

```json
{
  "name": "my-skill",
  "version": "0.1.0"
}
```

#### Step 3: Skill Entrypoint

Create `skills/my-skill/SKILL.md` with the skill's system prompt and tool access.

#### Step 4: Implement Commands

Create `skills/my-skill/skills/my-skill/scripts/command.sh`:

```bash
#!/usr/bin/env bash
# Your command implementation
```

#### Step 5: Register in Marketplace

Add to `.claude-plugin/marketplace.json`:

```json
{
  "name": "my-skill",
  "description": "My custom skill",
  "source": "./skills/my-skill"
}
```

### Skill Best Practices

#### 1. Self-Contained

- Include all dependencies
- Source shared libraries via bootstrap
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

## Testing Skills

### Running Tests

Always use `pnpm run` scripts — never invoke runners directly:

```bash
pnpm run test:sh        # ShellSpec tests
pnpm run lint:markdown  # Markdown lint
dprint check            # Format check
```

### Test Structure

```text
skills/deckrd/skills/deckrd/scripts/libs/__tests__/
├── unit/                 # Unit tests per library
├── functional/           # Functional tests (real filesystem)
└── spec_helper.sh        # Shared test helpers
```

## Distribution

### Marketplace Distribution

Skills are distributed via the `deckrd` marketplace:

```bash
# Install all skills
gh skills install aglabo/deckrd

# Install individual skill
claude plugin install bdd-coder@deckrd
```

### Release Artifacts

Release zips are in `releases/v{version}/` and contain the full skill tree for offline installation.

## Plugin Lifecycle

### Installation

1. User runs `gh skills install` or `claude plugin install`
2. Claude downloads skill
3. Claude validates structure
4. Claude registers commands
5. Commands available via `/`

### Version Management

Use `scripts/bump-version.sh` to update versions across all files:

```bash
bash scripts/bump-version.sh 0.5.0
```

## Security Considerations

### Input Validation

```bash
# Sanitize user input
sanitize_input() {
  local input=$1
  echo "$input" | tr -dc '[:alnum:] -_.'
}
```

### File Operations

```bash
# Use absolute paths via bootstrap
. "${DECKRD_ROOT}/skills/deckrd/skills/deckrd/scripts/libs/bootstrap.lib.sh"
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
