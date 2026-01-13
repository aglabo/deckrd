---
name: deckrd-coder
description: BDD厳格プロセスに従ってdeckrdタスクを自動実装するスキル
meta:
  author: atsushifx
---

<!-- textlint-disable ja-technical-writing/sentence-length -->
<!-- textlint-disable ja-technical-writing/no-exclamation-question-mark -->
<!-- textlint-disable ja-technical-writing/max-comma -->
<!-- markdownlint-disable line-length  -->

# deckrd-coder

A Claude Code skill that automatically implements Deckrd tasks using a strict BDD (Behavior-Driven Development) process, with integrated quality gates and project memory optimization.

## What is deckrd-coder?

deckrd-coder is a **completely optional companion plugin** that automates the implementation of Deckrd-generated tasks using a strict BDD (Behavior-Driven Development) workflow.

**It works like this:**

1. You complete a Deckrd session and generate `tasks.md`
2. You invoke `/deckrd-coder <TASK_ID>` to implement a task
3. deckrd-coder automatically runs the entire Red-Green-Refactor cycle for you

**Why it's optional:** Deckrd itself is a complete planning framework that works independently. deckrd-coder is purely a helper for automating implementation. You can use Deckrd alone to generate tasks, then implement them manually at your own pace—or use deckrd-coder to accelerate the process with BDD-style automation.

**What makes it different:** Rather than writing code first, deckrd-coder ensures each task follows TDD principles:

1. **Red**: Write tests that fail
2. **Green**: Write minimal code to pass tests
3. **Refactor**: Clean and optimize

This guarantees high-quality, fully-tested, traceable changes—with every implementation decision captured and justified.

## Key Features

- BDD Strict Process: Red-Green-Refactor cycle for every task ensures quality
- Automatic Task Extraction: Extracts task definitions from `tasks.md`
- 8-Step Workflow: Structured implementation pipeline from quality gates to completion
- Quality Assurance: Automated testing, linting, and type checking at every stage
- Token Efficiency: Project memory & serena-mcp integration reduces unnecessary processing
- Internal bdd-coder Agent: Handles Red-Green-Refactor phases automatically
- Progress Tracking: TodoWrite integration for detailed step management
- 1 Message = 1 Task: Maintains focus and code quality (no multi-tasking)

## Prerequisites

deckrd-coder requires an existing Deckrd workflow and a generated `tasks.md`.

- deckrd must be used first to derive tasks
- deckrd-coder operates exclusively on tasks defined in `tasks.md`
- Without deckrd and its derived tasks, deckrd-coder has no standalone use

## Getting Started

### Installation

deckrd-coder is available as an optional plugin for deckrd users.

```bash
Claude Code → Settings → Plugins → Enable deckrd
```

The skill becomes available in your Deckrd sessions.

## First Use

To implement a task in your Deckrd session:

```bash
/deckrd-coder T01-02
```

Where `T01-02` is your task ID extracted from `tasks.md`.

The skill automatically:

1. Validates quality gate commands
2. Extracts the task definition
3. Creates implementation subtasks
4. Runs Red-Green-Refactor cycle (via bdd-coder agent)
5. Executes quality gates
6. Records progress and completes

## Troubleshooting

### Skill not found error

If you get an "Unknown skill: deckrd" error when trying to use `/deckrd`:

1. **Check marketplace installation**:

   ```bash
   ls ~/.claude/plugins/marketplaces/deckrd-tools/
   ```

2. Verify plugin structure:
   ls ~/.claude/plugins/marketplaces/deckrd-tools/plugins/deckrd/skills/

3. Manual skill discovery:
   If the Skill tool doesn't recognize deckrd, search all marketplaces:
   ls ~/.claude/plugins/marketplaces/

### For each marketplace found

ls {marketplace}/plugins/*/skills/
4. Report to Claude:
Show Claude the marketplace structure and ask it to use the skill directly from the discovered path.

Note for AI assistants: When a user says "use agent skill" or "use skill" and the skill is not found via the Skill
tool, automatically search marketplace directories as shown above before asking the user for guidance.

Where documents are stored

## Workflow Overview

The implementation follows a 6-phase workflow:

```nash
Phase 0: Development Environment Initialization
    ↓
Phase 1: Deckrd Session & Task Information Extraction
    ↓
Phase 2: Task Breakdown (Fine-grained Subtasks)
    ↓
Phase 3: Red-Green-Refactor Implementation (via bdd-coder)
    ↓
Phase 4: Quality Gates (Lint, Type Check, Tests)
    ↓
Phase 5: Completion Verification
```

### The 8-Step Implementation Process

1. **Step 1**: Retrieve quality gate commands
2. **Step 2**: Extract implementation task list
3. **Step 3-4**: BDD cycle (Red-Green-Refactor)
4. **Step 5**: Execute quality gates
5. **Step 6**: Record progress
6. **Step 7**: Refactor phase (code cleanup)
7. **Step 8**: Completion check

For detailed implementation steps, see `IMPLEMENTATION.md` in the skill documentation.

## Important Notes

### ✅ What deckrd-coder Does

- Implements tasks up to completion
- Runs all tests and quality checks
- Records changes and progress
- Updates project memory with implementation details

### ❌ What deckrd-coder Does NOT Do

- Does not commit: Manual git commit required after verification
- Does not push: Push to remote is user's responsibility
- Does not support options: `--debug` and `--refresh-memory` are not currently implemented

## Task ID Format

Two formats are supported:

| Format     | Example     | Notes                         |
| ---------- | ----------- | ----------------------------- |
| Section ID | `T01-02`    | **Recommended** (single task) |
| Detail ID  | `T01-02-01` | Not recommended (task detail) |

Use Section ID format for single task implementation.

## Documentation

Comprehensive documentation is included:

- SKILL.md: Command reference and feature overview
- WORKFLOW.md: 6-phase workflow details
- IMPLEMENTATION.md: Step-by-step implementation guide
- TROUBLESHOOTING.md: Error handling and recovery
- FAQ.md: Common questions and answers
- bdd-coder.md: Internal agent specification

All documentation is located in `skills/deckrd-coder/references/`

## Common Patterns

### Single Task Implementation

```bash
/deckrd-coder T01-02          # Implement task T01-02
# Wait for completion
# Verify changes
# Manual git commit
```

### Multiple Tasks (Sequential)

```bash
/deckrd-coder T01-02          # Complete T01-02
/deckrd-coder T01-03          # Then implement T01-03
/deckrd-coder T01-04          # Then implement T01-04
```

> **Important**: Implement one task at a time (1 message = 1 task principle)

## Integration with Deckrd

deckrd-coder is designed to work seamlessly within Deckrd sessions:

1. Start a Deckrd session with `/deckrd init`
2. Work through phases to define tasks in `tasks.md`
3. Use `/deckrd-coder <TASK_ID>` to implement each task
4. All implementations are automatically tracked in project memory

## License

The MIT License
Copyright (C) 2025- aglabo
