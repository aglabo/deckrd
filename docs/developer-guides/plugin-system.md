---
title: "Plugin System Architecture"
description: "Detailed documentation of the deckrd plugin architecture and implementation"
category: "developer-guides"
tags: ["plugins", "skills", "architecture", "modular"]
created: "2026-01-14"
version: "0.6.1"
authors:
  - atsushifx <https://github.com/atsushifx>
changes:
  - 0.0.4   2026-01-14  Initial version
  - 0.1.0   2026-03-21  Update Integration Points to cocoIndex-code/filesystem, update plugin.json/bootstrap.sh/session.sh/directory structure to match actual implementation
  - 0.4.0   2026-06-19  Rename deckrd-coder to bdd-coder, update paths from plugins/ to skills/
  - 0.5.0   2026-09-06  Correct per-plugin MCP table, add codex-mcp and scoped tool naming
  - 0.6.0   2026-09-24  Remove codex-mcp from the per-plugin MCP table
  - 0.6.1   2026-11-10  Fix session example, bootstrap path, set options, version examples; gitleaks to betterleaks
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
├── agents/               # Thin wrappers for Claude Code (no procedure)
│   └── {agent-name}.md
└── skills/
    └── {skill-name}/
        ├── SKILL.md      # Skill entrypoint (orchestrator)
        ├── references/   # Documentation
        │   ├── commands/ # Command docs
        │   ├── roles/    # Canonical agent procedures (Roles)
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
  "version": "0.6.1"
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
  "version": "0.6.1"
}
```

## Skill Types

### 1. Main Skill (deckrd)

**Location**: `skills/deckrd/`

**Purpose**: Core document-driven workflow

**Components**:

- Skills: `/deckrd` commands (init, req, dr, spec, impl, tasks, status, review)
- Scripts: dedicated scripts for init / module / project / status / update
- Document commands (req, spec, impl, tasks, dr) go through `subcommands/generate-doc.sh`
- Templates: Document templates
- Prompts: AI prompts for generation

### 2. Methodology Skill (bdd-coder)

**Location**: `skills/bdd-coder/`

**Purpose**: BDD implementation with strict Red-Green-Refactor cycle

**Components**:

- Skills:
  - bdd-coder (`/bdd-coder:bdd-coder`)
  - bdd-coder-review (`/bdd-coder:bdd-coder-review`)
  - comment-review (`/bdd-coder:comment-review`)
- Agents:
  - tasklist-builder, checklist-builder, bdd-coder
  - code-reviewer, comment-refiner, explore-agent
- Templates: Test templates per language
- References: BDD cycle documentation

### 3. Shared Runtime

**Location**: `skills/deckrd/skills/deckrd/scripts/libs/`

**Purpose**: Shared libraries used by both deckrd and bdd-coder.
bdd-coder links them via the `skills/bdd-coder/skills/bdd-coder/scripts/libs` symlink.

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

set -eo pipefail

# Source bootstrap
. "${DECKRD_ROOT}/scripts/libs/bootstrap.lib.sh"

# Functions
main() {
  # Implementation
}

# Entry point
main "$@"
```

### Command Lifecycle

1. User invokes command: `/deckrd {command}`
2. Claude Code dispatches: Calls corresponding skill
3. Script executes: Reads session, performs operations
4. Script updates state: Writes to session file
5. Script returns result: Claude shows output to user

### Session Management

Commands read/write session state:

```bash
# Read session
get_current_module() {
  jq -r '.active // empty' "$SESSION_FILE"
}

# Write session
update_session() {
  local module=$1
  local step=$2
  jq --arg mod "$module" --arg step "$step" \
    '.active = $mod | .modules[$mod].current_step = $step' \
    "$SESSION_FILE" > "$SESSION_FILE.tmp"
  mv "$SESSION_FILE.tmp" "$SESSION_FILE"
}
```

## Agent Definitions

### Role, Wrapper, Orchestrator

The canonical procedure of an agent lives in a **Role file** inside the skill.
`agents/*.md` is a thin wrapper that loads the Role.
`gh skill` and `npx skills` copy only the directory that holds `SKILL.md`.
A Role inside the skill therefore survives every distribution method.

#### Role file (`skills/{skill}/references/roles/{name}.md`)

- Holds the whole procedure: steps, inputs, outputs, and failure handling. Never put procedure in a wrapper.
- Stays client-neutral:
  - Point to scripts and reference files by a path relative to the skill directory.
    This is the Agent Skills way.
    Do not write Claude Code variables such as `${CLAUDE_PLUGIN_ROOT}`.
  - Write the action, not the tool name. Write "record it in the checklist file", not "record it with `TodoWrite`".
  - Never require MCP. Write "use a semantic code search tool if available; otherwise use Grep / Glob".
- A Role contains neither a `${CLAUDE_` variable nor an `mcp__` tool name.

#### Wrapper (`agents/{name}.md`)

- Holds only three things:
  - the frontmatter (`name` / `description` / `tools` / `model`)
  - the instruction to read and follow the Role
  - an Inputs table
- Claude Code–specific information goes in the wrapper only.
  Examples are `mcp__plugin_...` tool names and a Role path built with `${CLAUDE_PLUGIN_ROOT}`.

```markdown
---
name: { agent-name }
description: { agent description }
tools: [Read, Write, Edit, Bash, Grep, Glob]
model: inherit
---

Read `<skill_dir>/references/roles/{agent-name}.md` and follow it.
`skill_dir` and `local_dir` come from the Inputs table below.
This file only wraps the Role for Claude Code.

## Inputs

| Parameter   | Description                                              |
| ----------- | -------------------------------------------------------- |
| `skill_dir` | Absolute path of the skill directory (has `SKILL.md`)    |
| `local_dir` | Absolute path of the deckrd local data (`.local/deckrd`) |
```

#### Path arguments (`skill_dir` / `local_dir`)

A subagent knows neither where its wrapper file sits nor where the project root is.
The orchestrator therefore passes two absolute paths on every delegation.
The Role and the wrapper resolve every path from these two values and never guess.

| Argument    | Value                                                                   | Use                                                                                                              |
| ----------- | ----------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------- |
| `skill_dir` | The skill directory (where `SKILL.md` is), as an absolute path          | Base of every "path relative to the skill directory". The wrapper reads `<skill_dir>/references/roles/<name>.md` |
| `local_dir` | The value of `DECKRD_LOCAL_DATA` (`.local/deckrd`), as an absolute path | Replaces `.local/deckrd` in a Role: write `<local_dir>/session.json`, `<local_dir>/temp/...`                     |

- A Role never hard-codes `.local/deckrd`. It writes `<local_dir>/...`.
- `temp` is always `<local_dir>/temp`. A Role does not read `DECKRD_LOCAL_TEMP`.
  Overriding `DECKRD_LOCAL_TEMP` moves only what the Bash scripts write.
- The orchestrator knows `skill_dir` when it loads the skill.
  It takes `local_dir` from `DECKRD_LOCAL_DATA` (`bootstrap.lib.sh`).
- A Role stays client-neutral. It names the two arguments and never a Claude Code variable.
- When no subagent is available, the orchestrator follows the Role itself with the same two values.

#### Orchestrator (`SKILL.md` and command references)

Write each phase that uses a Role like this:

> If you can start a subagent, hand it `skill_dir` and `local_dir` and let it run the Role.
> If you cannot, follow the same Role file yourself with the same two values, step by step.

### Agent Types in deckrd

#### explore-agent

**Purpose**: Read-only codebase investigation — protects main context window

**Scope**: codebase-extraction, codebase-survey, prior-art, pattern-detection

Steps live in the Role file `references/roles/explorer.md`.

### Agent Types in bdd-coder

#### tasklist-builder

**Purpose**: Breaks a request or a tasks.md Target (`T-XX`) into a task list. Each item makes one checklist

**Entry point**: bdd-coder skill Phase 1a, before checklist-builder.
Writes `<local_dir>/temp/tasklist/<ns>/<module>/<name>.tasklist.md`.
Example: `<local_dir>/temp/tasklist/deckrd/libs/T-01.tasklist.md`.
A natural-language request goes under the active module's directory.
With no active module, it goes directly under `<local_dir>/temp/tasklist/`.
Only the selected item's `Handoff` goes to checklist-builder, never the task list file.
Steps live in the Role file `references/roles/tasklist-builder.md`. Never invoked directly by the user.

#### checklist-builder

**Purpose**: Converts natural-language instructions into BDD implementation checklists

Steps live in the Role file `references/roles/checklist-builder.md`.

#### bdd-coder

**Purpose**: Strict BDD implementation — 1 message = 1 test, Red-Green-Refactor per assertion

Steps live in the Role file `references/roles/implementer.md`.

#### code-reviewer

**Purpose**: Post-implementation review — CC/CRAP scoring + Codex second opinion

**Entry points**: bdd-coder skill Phase 4 (automatic), or `/bdd-coder:bdd-coder-review` (on demand).
Reviews the session's changes in aggregate. Never invoked directly by the user.
Steps live in the Role file `references/roles/code-reviewer.md`.

#### comment-refiner

**Purpose**: Comment cleanup by the comment guideline (C-1 to C-10). Never changes code.

**Entry point**: `/bdd-coder:comment-review`. Works in two modes, draft (findings and diff) and apply (after user approval).
Steps live in the Role file `references/roles/comment-refiner.md`. Never invoked directly by the user.

#### explore-agent

**Purpose**: Environment detection — detects language, test framework, and tool commands

Steps live in the Role file `references/roles/explorer.md` of the bdd-coder skill.

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

Independent Codex review is not an MCP server.
The deckrd-review skill and bdd-coder's code-reviewer call `codex exec` over Bash.

MCP server configuration per plugin:

| Plugin    | MCP config file         | Declared servers                       |
| --------- | ----------------------- | -------------------------------------- |
| deckrd    | skills/deckrd/.mcp.json | filesystem, cocoindex-code             |
| bdd-coder | (none)                  | uses the servers other plugins provide |

Servers declared by a plugin expose their tools under a scoped name.
The form is `mcp__plugin_<plugin>_<server>__<tool>`, not the bare `mcp__<server>__<tool>`.
See [MCP Servers Reference](../specs/mcp-servers.md) for the naming rules,
the deduplication caveat, and the Codex CLI options.

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
set -eo pipefail  # -u is intentionally not used (see #276)

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
. "${DECKRD_ROOT}/scripts/libs/bootstrap.lib.sh"
```

### Secret Handling

- Never hardcode secrets
- Use environment variables
- Check with betterleaks before commit

## Related Documentation

- [Architecture Overview](architecture.md) - System architecture
- [Development Workflow](./workflow.md) - Development process
- [Deckrd Commands](./deckrd-commands.md) - Command reference
- [Code Quality](../contributing/code-quality.md) - Quality standards
