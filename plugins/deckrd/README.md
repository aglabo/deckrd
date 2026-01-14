---
name: deckrd
description: your goal to tasks framework
meta:
  author: atsushifx
---

<!-- textlint-disable ja-technical-writing/sentence-length -->
<!-- textlint-disable ja-technical-writing/no-exclamation-question-mark -->
<!-- markdownlint-disable line-length  -->

# deckrd

A Claude Code plugin providing structured document-derivation workflows that guide you from goals to executable tasks.

## What is deckrd?

deckrd is a **goals-to-tasks framework** designed for thoughtful project planning and development. It breaks down project ambitions into clear requirements, specifications, and executable tasks through iterative discussion with Claude AI.

Rather than jumping directly to implementation, deckrd ensures you capture reasoning at each stage—understanding *why* decisions are made, not just *what* gets built.

## What deckrd does NOT do

- It does not manage source code repositories
- It does not execute or modify code automatically
- It does not replace developer judgment

## Key Features

- Stepwise Workflow: Goals → Requirements → Specifications → Implementation → Tasks
- Document-Centered: Each stage produces a derived document that preserves context and intent
- AI-Guided: Interactive guidance at each step keeps you focused and aligned
- State Management: Automatic session tracking ensures workflow consistency
- Flexible: Works with any project type—features, refactoring, debugging, documentation

## Implementation (in deckrd)

In deckrd, "implementation" does not mean writing production code.
It refers to deriving implementation-ready decisions, constraints,
and structural outlines that make coding straightforward and unambiguous.

## The Output: tasks.md

The final output of deckrd is **tasks.md**—a document that serves as your **direct starting point for coding**.

Unlike planning documents that capture intent and reasoning, tasks.md is your actionable blueprint:

- Concrete Tasks: Specific, prioritized development tasks derived from your implementation plan
- Acceptance Criteria: Clear definitions of what "done" means for each task
- Implementation Constraints: Technical decisions and patterns established during earlier phases
- Ready-to-Code Format: Structured in a way that developers can immediately begin implementation

This means when you finish the deckrd workflow, you're not just ready to start coding—you have a detailed roadmap that eliminates ambiguity and reduces rework. Each task in tasks.md flows directly into your development cycle.

## Getting Started

### Installation

The deckrd plugin is available in the Claude Code Marketplace. Enable it through:

```bash
Claude Code → Settings → Plugins → Enable deckrd
```

## First Use

Once enabled, start a new workflow with:

```bash
/deckrd init <namespace>/<module>
```

deckrd then guides you through a stepwise workflow,
deriving documents from goals to executable tasks.

## Where documents are stored

deckrd manages all generated documents and workflow state under `docs/.deckrd/` in your project.

You can browse the derived requirements, specifications, and tasks at any time using your editor or file explorer.

## Use Cases

deckrd works well for:

- New Features: Clarify requirements before coding
- Refactoring: Document the why before restructuring
- Bug Fixes: Understand root causes and plan solutions
- System Design: Capture architectural decisions
- Documentation: Trace decision-making and rationale

## Documentation

For detailed guides and command reference, see the included skill documentation or visit the deckrd repository.

## License

The MIT License
Copyright (C) 2025- aglabo
