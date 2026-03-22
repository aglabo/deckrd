---
title: "IDD Framework Commands Reference"
description: "Complete reference for Issue-Driven Development framework commands"
category: "developer-guides"
tags: ["idd-framework", "commands", "reference", "github"]
created: "2026-01-14"
version: "0.1.0"
authors:
  - atsushifx <https://github.com/atsushifx>
changes:
  - 0.0.4   2026-01-14  Initial version
  - 0.1.0   2026-03-22  Version update
copyright:
  - Copyright (c) 2026- atsushifx <https://github.com/atsushifx>
  - This software is released under the MIT License.
  - https://opensource.org/licenses/MIT
status: "published"
---

<!-- textlint-disable ja-technical-writing/sentence-length --
<!-- markdownlint-disable line-length -->>

## IDD Framework Commands Reference

## Overview

The claude-idd-framework plugin provides Issue-Driven Development (IDD) tools for managing the complete development lifecycle from issues to pull requests.

**Integration**: Complements deckrd (deckrd for planning, IDD for execution)

## Plugin Location

**External Plugin**: `C:\Users\atsushifx\.claude\plugins\marketplaces\claude-idd-framework-marketplace\plugins\claude-idd-framework`

**Important**: When searching for IDD commands, always check this external plugin path.

**Command Implementation**:

- Commands: `commands/` subdirectory
- Agents: `agents/` subdirectory
- Helpers: `commands/_helpers/`
- Libraries: `commands/_libs/`

## Working Directory

**Temp Directory**: `temp/idd/`

Structure:

```bash
temp/idd/
├── issues/              # Issue drafts
│   ├── issue_draft_*.md
│   └── .last-issue
├── pr/                  # PR drafts
│   ├── pr_current_draft.md
│   └── .last-draft
└── todo.md             # BDD task tracking
```

## Issue Management Commands

### /idd/issue:new

**Usage**: `/idd/issue:new [title] [--type=feature|bug|chore]`

**Purpose**: Create a new GitHub issue draft

**Output**: `temp/idd/issues/issue_draft_<timestamp>.md`

**Example**:

```bash
/idd/issue:new "Add user authentication" --type=feature
```

**Agent**: Uses `issue-generator` agent

### /idd/issue:list

**Usage**: `/idd/issue:list`

**Purpose**: List all issue drafts

**Output**: Displays list of draft files in `temp/idd/issues/`

### /idd/issue:edit

**Usage**: `/idd/issue:edit`

**Purpose**: Edit existing issue draft

**Prerequisites**: Must have draft file in `temp/idd/issues/`

### /idd/issue:load

**Usage**: `/idd/issue:load <issue-number>`

**Purpose**: Load GitHub issue and save as draft

**Example**:

```bash
/idd/issue:load 123
```

**Prerequisites**: GitHub CLI (`gh`) must be authenticated

### /idd/issue:push

**Usage**: `/idd/issue:push`

**Purpose**: Push draft to GitHub as new issue

**Prerequisites**: Draft must exist and `gh` must be authenticated

**Output**: Creates issue on GitHub and returns issue number

### /idd/issue:branch

**Usage**: `/idd/issue:branch`

**Purpose**: Create branch from issue

**Prerequisites**: Issue must be pushed to GitHub

**Branch Naming**: Follows pattern `<type>/<issue-number>-<title>`

## Pull Request Commands

### /idd-pr new

**Usage**: `/idd-pr [--output=<filename>]`

**Purpose**: Generate PR draft using pr-generator agent

**Default Output**: `temp/idd/pr/pr_current_draft.md`

**Agent**: Uses `pr-generator` agent

**Process**:

1. Analyzes Git commits
2. Reviews file changes
3. Reads `.github/PULL_REQUEST_TEMPLATE.md`
4. Generates Conventional Commit format title
5. Creates structured PR draft

**Example**:

```bash
/idd-pr
/idd-pr --output=feature-123.md
```

### /idd-pr view

**Usage**: `/idd-pr view`

**Purpose**: View current PR draft

**Output**: Displays content of `temp/idd/pr/pr_current_draft.md`

### /idd-pr edit

**Usage**: `/idd-pr edit`

**Purpose**: Edit PR draft in editor

**Editor**: Uses `$EDITOR` environment variable (default: `code`)

### /idd-pr push

**Usage**: `/idd-pr push`

**Purpose**: Create PR on GitHub

**Prerequisites**:

- Draft must exist
- Changes must be committed
- Branch must be pushed to remote
- `gh` must be authenticated

**Process**:

1. Extracts title from draft (H1 heading)
2. Detects base branch (parent branch)
3. Creates PR using `gh pr create`
4. Cleans up draft files

## Commit Message Command

### /idd-commit-message

**Usage**: `/idd-commit-message`

**Purpose**: Generate Conventional Commits format message from staged changes

**Agent**: Uses `commit-message-generator` agent

**Prerequisites**: Must have staged changes (`git add`)

**Process**:

1. Analyzes staged changes with `git diff --staged`
2. Reviews recent commit messages for project conventions
3. Generates Conventional Commits format message

**Output**: Suggested commit message

**Example Output**:

```bash
feat(auth): add user authentication with JWT

- Implement login endpoint
- Add JWT token generation
- Create auth middleware
```

## Spec-Driven Development

### /sdd

**Usage**: `/sdd`

**Purpose**: Spec-Driven Development workflow with MCP integration

**Features**:

- Requirements definition to implementation
- Consistent development support
- MCP (serena-mcp, codex-mcp, lsmcp) integration

**Use Case**: Efficient workflow from requirements to implementation

## Serena Integration

### /serena

**Usage**: `/serena`

**Purpose**: serena-mcp integrated structured application development

**Features**:

- Structured problem-solving
- Semantic code analysis
- Symbol-based code navigation

**Use Case**: Complex codebase navigation and refactoring

## Validation & Debug

### /validate-debug

**Usage**: `/validate-debug`

**Purpose**: 6-stage comprehensive quality validation and debugging workflow

**Stages**:

1. Code quality checks
2. Test execution
3. Linting and formatting
4. Security scanning
5. Dependency validation
6. Integration testing

**Use Case**: Comprehensive pre-commit validation

## Available Agents

### bdd-coder

**Purpose**: Strict BDD Red-Green-Refactor cycle implementation

**Features**:

- 1 message = 1 test principle
- TodoWrite integration with `temp/idd/todo.md`
- Staged implementation with quality gates

**Use Case**: Test-driven development with strict methodology

### commit-message-generator

**Purpose**: Generate Conventional Commits format messages

**Features**:

- Analyzes project conventions
- Staged changes analysis
- Standard format compliance

**Use Case**: Consistent commit messages

### issue-generator

**Purpose**: Generate GitHub issue drafts from title/type/summary

**Features**:

- Template-based generation
- Codex-mcp delegation
- Markdown output

**Use Case**: Structured issue creation

### pr-generator

**Purpose**: Generate comprehensive PR drafts

**Features**:

- Git history analysis
- File change review
- Template integration
- Conventional Commit title generation

**Use Case**: Professional PR documentation

## Workflow Integration

### Complete Development Cycle

```bash
1. Plan with deckrd
   /deckrd init → req → spec → impl → tasks

2. Create issue
   /idd/issue:new "Feature title" --type=feature
   /idd/issue:push

3. Create branch
   /idd/issue:branch

4. Implement with BDD
   Use bdd-coder agent or manual implementation

5. Commit with proper messages
   git add <files>
   /idd-commit-message
   git commit -m "<generated-message>"

6. Generate PR
   /idd-pr new
   /idd-pr push

7. Validate (optional)
   /validate-debug
```

## GitHub CLI Integration

Most IDD commands require GitHub CLI (`gh`):

**Installation**: See <https://cli.github.com/>

**Authentication**:

```bash
gh auth login
```

**Verify**:

```bash
gh auth status
```

## Best Practices

1. **Use issue workflow**: Create issues before branches
2. **Generate commit messages**: Use `/idd-commit-message` for consistency
3. **Review PR drafts**: Always review before pushing
4. **Validate before commit**: Use `/validate-debug` for quality assurance
5. **Follow Conventional Commits**: Maintain consistent message format

## Integration with Deckrd

**Complementary Usage**:

- Deckrd: Strategic planning (Goals → Tasks)
- IDD Framework: Tactical execution (Issues → PRs)

**Recommended Flow**:

1. Plan feature with deckrd
2. Create implementation tasks with `/deckrd tasks`
3. Create GitHub issue with `/idd/issue:new`
4. Implement according to tasks
5. Generate PR with `/idd-pr`

## Notes

- IDD framework is bash-based (analyze with serena-mcp)
- Temp directory (`temp/idd/`) stores working files
- All commands integrate with GitHub via `gh` CLI
- Agents use Task tool for complex multi-step workflows
- Compatible with deckrd workflow (use in parallel)

## External Resources

- Plugin location: See "Plugin Location" section above
- GitHub CLI: <https://cli.github.com/>
- Conventional Commits: <https://www.conventionalcommits.org/>
