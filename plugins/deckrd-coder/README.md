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

deckrd-coder is a **task implementation skill** that takes tasks defined in a Deckrd session and implements them following a strict Red-Green-Refactor cycle. It extracts tasks from `tasks.md`, manages implementation through a structured 8-step workflow, and ensures code quality through automated testing and linting.

Rather than manual implementation, deckrd-coder ensures each task is tested first, implemented with minimal code, and refactored systematically—guaranteeing high-quality, traceable changes.

## Key Features

- BDD Strict Process: Red-Green-Refactor cycle for every task ensures quality
- Automatic Task Extraction: Extracts task definitions from `tasks.md`
- 8-Step Workflow: Structured implementation pipeline from quality gates to completion
- Quality Assurance: Automated testing, linting, and type checking at every stage
- Token Efficiency: Project memory & serena-mcp integration reduces unnecessary processing
- Internal bdd-coder Agent: Handles Red-Green-Refactor phases automatically
- Progress Tracking: TodoWrite integration for detailed step management
- 1 Message = 1 Task: Maintains focus and code quality (no multi-tasking)

## Getting Started

### Installation

The deckrd-coder plugin is included with deckrd. Once enabled through:

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

MIT
