---
title: "Deckrd Commands Reference"
description: "Complete reference for deckrd document-driven workflow commands"
category: "developer-guides"
tags: ["deckrd", "commands", "reference", "cli"]
created: "2026-01-14"
version: "0.1.0"
authors:
  - atsushifx <https://github.com/atsushifx>
changes:
  - 0.0.4   2026-01-14  Initial version
  - 0.1.0   2026-03-21  Fix session path and schema, add command list, add lang/ai_model fields to session schema
copyright:
  - Copyright (c) 2026- atsushifx <https://github.com/atsushifx>
  - This software is released under the MIT License.
  - https://opensource.org/licenses/MIT
status: "published"
---

<!-- textlint-disable ja-technical-writing/sentence-length -->
<!-- markdownlint-disable line-length -->

## Deckrd Commands Reference

## Overview

Deckrd provides a document-driven workflow that transforms goals and ideas into executable development tasks through systematic documentation at each stage.

**Core Workflow**: Goals/Ideas → Requirements → Specifications → Implementation → Tasks

## Plugin Location

**Main Plugin**: `plugins/deckrd/`

**Command Implementation**:

- Commands: `plugins/deckrd/skills/deckrd/references/commands/`
- Scripts: `plugins/deckrd/skills/deckrd/scripts/`
- Templates: `plugins/deckrd/skills/deckrd/assets/templates/`
- Prompts: `plugins/deckrd/skills/deckrd/assets/prompts/`

## Session Management

**Session File**: `docs/.deckrd/.session.json`

The session file tracks:

- Active module
- Completion status per step
- Document paths
- Multiple concurrent modules

## Commands

### /deckrd init

**Usage**: `/deckrd init <namespace>/<module>`

**Purpose**: Initialize a new module directory and session

**Output**: Creates `docs/.deckrd/<namespace>/<module>/` directory structure

**Example**:

```bash
/deckrd init myProject/authentication
```

Creates:

```bash
docs/.deckrd/myProject/authentication/
├── requirements/
├── specifications/
├── implementation/
└── tasks/
```

### /deckrd req

**Usage**: `/deckrd req`

**Purpose**: Derive requirements from goals and ideas

**Prerequisites**: Module must be initialized with `/deckrd init`

**Output**: `requirements/requirements.md`

**Workflow Step**: 2 of 6

### /deckrd dr

**Usage**: `/deckrd dr --add`

**Purpose**: Add decision records during requirements phase

**Prerequisites**: Requirements phase must be active

**Output**: `decision-records.md`

**Workflow Step**: 2a (optional)

**Note**: Decision records capture architectural decisions and their rationale.

### /deckrd spec

**Usage**: `/deckrd spec`

**Purpose**: Derive specifications from requirements

**Prerequisites**: Requirements must be completed

**Output**: `specifications/specifications.md`

**Workflow Step**: 3 of 6

### /deckrd impl

**Usage**: `/deckrd impl`

**Purpose**: Derive implementation plan from specifications

**Prerequisites**: Specifications must be completed

**Output**: `implementation/implementation.md`

**Workflow Step**: 4 of 6

**Note**: Implementation layer records decision criteria, not actual code.

### /deckrd tasks

**Usage**: `/deckrd tasks`

**Purpose**: Derive executable tasks from implementation

**Prerequisites**: Implementation must be completed

**Output**: `tasks/tasks.md` (actionable blueprint)

**Workflow Step**: 5 of 6

**Note**: This is the final step. tasks.md serves as your direct starting point for coding.

### /deckrd status

**Usage**: `/deckrd status`

**Purpose**: Check current workflow progress

**Output**: Shows completion status for all workflow steps

**Example Output**:

```bash
Module: myProject/authentication
Status:
  ✓ Requirements
  ✓ Specifications
  ✓ Implementation
  → Tasks (in progress)
```

## Workflow Details

### Complete Workflow

```bash
1. /deckrd init <namespace>/<module>
   → Creates docs/.deckrd/<namespace>/<module>/

2. /deckrd req
   → Generates requirements/requirements.md

2a. /deckrd dr --add (optional)
   → Creates decision-records.md

3. /deckrd spec
   → Generates specifications/specifications.md

4. /deckrd impl
   → Generates implementation/implementation.md

5. /deckrd tasks
   → Generates tasks/tasks.md (actionable blueprint)

6. /deckrd status
   → Shows current workflow state
```

### Step Progression

- Linear: Steps must be completed in order
- State-driven: Session tracks completion status
- Document-centered: Each step produces a derived document
- Incremental: Build understanding through iterations

## Document Types

### Requirements (Step 2)

- User-facing goals and constraints
- What needs to be achieved
- Stakeholder needs

### Decision Records (Step 2a)

- Architecture decisions with rationale
- Why specific choices were made
- Alternative options considered

### Specifications (Step 3)

- Technical constraints, rules, and examples
- How requirements will be satisfied
- Detailed technical specifications

### Implementation (Step 4)

- Decision criteria and structural guidelines
- Implementation strategies and rationale
- Not actual code, but decision-making guidance

### Tasks (Step 5)

- BDD-style executable tasks
- Actionable blueprint for coding
- Concrete tasks with acceptance criteria
- Ready-to-code format

## Related Plugins

### bdd-coder

- Purpose: BDD methodology agent
- Features: Red-Green-Refactor cycle enforcement
- Integration: TodoWrite integration for progress tracking

### deckrd-coder

- Purpose: Optional coding helper plugin
- Features: Task execution assistance

## Best Practices

1. **Follow the workflow order**: Don't skip steps
2. **Use /deckrd status frequently**: Track your progress
3. **Iterate as needed**: Revisit earlier steps if requirements change
4. **Keep documents focused**: Each document has a specific purpose
5. **Use decision records**: Capture important architectural decisions

## Integration with IDD Framework

Deckrd complements the IDD framework:

- Deckrd: Planning and documentation (Goals → Tasks)
- IDD Framework: Execution and GitHub integration (Issues, PRs, Commits)

Use both together for a complete development cycle:

1. Plan with deckrd (`/deckrd init` → `tasks`)
2. Create issue with IDD (`/idd/issue:new`)
3. Implement with BDD (`bdd-coder` agent)
4. Generate PR with IDD (`/idd-pr`)

## Additional Documentation

- Plugin README: `plugins/deckrd/README.md`
- Command References: `plugins/deckrd/skills/deckrd/references/commands/`
- Workflow Guide: `plugins/deckrd/skills/deckrd/references/workflow.md`
- Session Management: `plugins/deckrd/skills/deckrd/references/session.md`

## Notes

- Deckrd is purely assistive - it doesn't generate or execute code
- Documents are derivation artifacts, not final deliverables
- The workflow ensures thoughtful planning before implementation
- tasks.md is the bridge between planning and coding
- Workflow Guide: `docs/developer-guides/workflow.md`
- Quickstart: `docs/user-guides/01-quickstart.ja.md`
