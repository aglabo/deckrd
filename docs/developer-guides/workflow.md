---
title: "Development Workflow Guide"
description: "Document-driven and issue-driven development workflow for deckrd project"
category: "developer-guides"
tags: ["workflow", "deckrd", "idd-framework", "development"]
created: "2026-01-14"
version: "0.1.0"
authors:
  - atsushifx <https://github.com/atsushifx>
changes:
  - 0.0.4   2026-01-14  Initial version
  - 0.1.0   2026-03-21  Fix session path and schema, fix IDD/deckrd workflow order, add lang/ai_model fields to session schema
copyright:
  - Copyright (c) 2026- atsushifx <https://github.com/atsushifx>
  - This software is released under the MIT License.
  - https://opensource.org/licenses/MIT
status: "published"
---

<!-- textlint-disable ja-technical-writing/sentence-length,
  no-duplicate-heading -->

## Development Workflow Guide

## Overview

The deckrd project uses a two-layer development workflow:

1. **deckrd workflow** - Planning and documentation (Goals → Tasks)
2. **IDD Framework workflow** - Execution and GitHub integration (Issues → PRs → Commits)

## deckrd Workflow: Planning and Documentation

### Purpose

Transform initial goals and ideas into structured specifications and executable tasks through systematic documentation.

### Workflow Stages

Goals/Ideas → Requirements → Specifications → Implementation → Tasks

### Commands Reference

See [Deckrd Commands Reference](./deckrd-commands.md) for detailed command documentation.

#### 1. Initialize New Feature

```bash
# Start a new deckrd module
/deckrd init

# Creates session file: docs/.deckrd/.session.json
# Tracks: module name, active phase, completion status
```

#### 2. Define Requirements

```bash
# Create requirements document
/deckrd req

# Output: docs/{module}/requirements.md
# Contains: goals, user stories, constraints
```

#### 3. Write Specifications

```bash
# Create detailed specifications
/deckrd spec

# Output: docs/{module}/specifications.md
# Contains: technical details, API contracts, data models
```

#### 4. Plan Implementation

```bash
# Generate implementation guide
/deckrd impl

# Output: docs/{module}/implementation.md
# Contains: step-by-step implementation plan
```

#### 5. Generate Tasks

```bash
# Break down into executable tasks
/deckrd tasks

# Output: docs/{module}/tasks.md
# Contains: actionable task list, acceptance criteria
```

#### 6. Check Status

```bash
# View current progress
/deckrd status

# Shows: active module, completed phases, next steps
```

### Session Management

**Session file**: `docs/.deckrd/.session.json`

```json
{
  "module": "feature-name",
  "phase": "implementation",
  "completed": ["requirements", "design-review", "specifications"],
  "documents": {
    "requirements": "docs/feature-name/requirements.md",
    "specifications": "docs/feature-name/specifications.md"
  }
}
```

## IDD Framework Workflow: Execution and GitHub Integration

### Purpose

Execute planned tasks with GitHub integration for issues, branches, commits, and pull requests.

### Commands Reference

See [IDD Framework Commands Reference](./idd-commands.md) for detailed command documentation.

### Workflow Stages

Issue Creation → Branch → Implementation → Commit → PR

#### 1. Create Issue

```bash
# Create new GitHub issue
/idd/issue:new

# Interactive prompts for:
# - Issue type (feature/bug/docs/etc.)
# - Title and description
# - Labels and milestones
```

#### 2. Load Existing Issue

```bash
# Load issue from GitHub
/idd/issue:load

# Downloads issue to: temp/idd/issues/{number}-{slug}.md
# Converts to working format
```

#### 3. Create Branch

```bash
# Auto-create branch from issue
git checkout -b {type}-{number}/{slug}

# Example: feature-123/add-status-command
```

#### 4. Implement Changes

Follow the implementation plan from deckrd specifications:

- Make code changes
- Write tests
- Update documentation

#### 5. Commit Changes

```bash
# Generate conventional commit message
/idd-commit-message

# Analyzes staged changes
# Suggests: type(scope): description
# Includes: Co-Authored-By: Claude

# Commit with generated message
git add .
git commit -m "{generated-message}"
```

#### 6. Create Pull Request

```bash
# Generate PR description
/idd-pr

# Analyzes commits and changes
# Generates: Summary, Test Plan, Links
# Includes: Claude Code badge

# Create PR via gh cli
gh pr create --title "{title}" --body "{generated-body}"
```

## Combined Workflow Example

### Scenario: Adding New Feature

#### Planning Phase (deckrd)

```bash
# 1. Initialize
/deckrd init
# → Enter module name: "status-command"

# 2. Define requirements
/deckrd req
# → Creates: docs/status-command/requirements.md

# 3. Review design
/deckrd dr
# → Creates: docs/status-command/design-review.md

# 4. Write specifications
/deckrd spec
# → Creates: docs/status-command/specifications.md

# 5. Plan implementation
/deckrd impl
# → Creates: docs/status-command/implementation.md

# 6. Generate tasks
/deckrd tasks
# → Creates: docs/status-command/tasks.md
```

#### Execution Phase (IDD Framework)

```bash
# 1. Create issue
/idd/issue:new
# → Type: feature
# → Title: "Add /deckrd status command"
# → Creates: GitHub issue #42

# 2. Create branch
git checkout -b feature-42/add-status-command

# 3. Implement (following tasks.md)
# - Write status.sh script
# - Add command handler
# - Write tests
# - Update documentation

# 4. Commit
git add .
/idd-commit-message
# → Suggests: "feat(deckrd): add status command support"
git commit -m "feat(deckrd): add status command support

Implements /deckrd status to show current module progress.

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"

# 5. Push and create PR
git push origin feature-42/add-status-command
/idd-pr
# → Generates PR description
gh pr create --title "feat: Add /deckrd status command" --body "{generated}"
```

## Workflow Tips

### When to Use deckrd Workflow

- New feature planning
- Complex refactoring
- Architecture changes
- Multi-step implementations

### When to Use IDD Framework

- Bug fixes (quick issue → fix → PR)
- Documentation updates
- Simple enhancements
- Routine maintenance

### Combining Both

For complex features:

1. Use deckrd for planning and documentation
2. Use IDD for execution and GitHub integration
3. Reference deckrd docs in IDD issues/PRs

## Working Directory Structure

### deckrd Documents

```text
docs/
├── .deckrd/
│   └── .session.json          # Active session state
└── {module-name}/
    ├── requirements.md        # Requirements document
    ├── design-review.md       # Design review
    ├── specifications.md      # Technical specifications
    ├── implementation.md      # Implementation guide
    └── tasks.md               # Actionable tasks
```

### IDD Framework Files

```text
temp/idd/
├── issues/
│   └── {number}-{slug}.md     # Issue working copy
├── pr/
│   └── {number}-pr.md         # PR draft
└── todo.md                    # Task tracking
```

## Quality Assurance

### Before Committing

```bash
# Format code
dprint fmt

# Lint markdown
markdownlint-cli2 "**/*.md"

# Check text quality
textlint --config ./configs/textlintrc.yaml "**/*.md"

# Spell check
cspell check "**/*.{sh,md,json,yml,yaml}"
```

### Pre-commit Hooks (Automatic)

- gitleaks - Secret detection
- secretlint - Sensitive data patterns
- commitlint - Commit message validation
- prepare-commit-msg - Auto-formatting

### Pre-PR Checklist

- [ ] All deckrd documents created (if applicable)
- [ ] All tasks from tasks.md completed
- [ ] Tests written and passing
- [ ] Documentation updated
- [ ] Code formatted and linted
- [ ] Commits follow Conventional Commits
- [ ] PR description includes test plan

## Common Patterns

### Feature Development

1. Plan with deckrd (init → req → dr → spec → impl → tasks)
2. Create issue with IDD (/idd/issue:new)
3. Implement following tasks.md
4. Commit with /idd-commit-message
5. Create PR with /idd-pr

### Bug Fix

1. Create issue with IDD (/idd/issue:new, type: fix)
2. Investigate and fix
3. Commit with /idd-commit-message
4. Create PR with /idd-pr
5. (Optional) Document in deckrd if complex

### Documentation Update

1. Create issue with IDD (/idd/issue:new, type: docs)
2. Update documentation
3. Verify with markdownlint/textlint
4. Commit with /idd-commit-message
5. Create PR with /idd-pr

## Troubleshooting

### deckrd session lost

```bash
# Check session file
cat docs/.deckrd/.session.json

# Reinitialize if needed
/deckrd init
```

### IDD files not found

```bash
# Verify temp/idd/ directory exists
ls temp/idd/

# Reload issue if needed
/idd/issue:load
```

### Commit message rejected

```bash
# Follow Conventional Commits format
# type(scope): description

# Valid types:
# feat, fix, docs, style, refactor, test, chore, ci, perf, build, release
```

## Additional Resources

- [Deckrd Commands Reference](./deckrd-commands.md)
- [IDD Framework Commands Reference](./idd-commands.md)
- [Code Quality Standards](../contributing/code-quality.md)
- [Architecture Overview](./architecture.md)
