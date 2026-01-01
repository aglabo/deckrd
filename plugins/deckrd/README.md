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

## Key Features

- Stepwise Workflow: Goals → Requirements → Specifications → Implementation → Tasks
- Document-Centered: Each stage produces a derived document that preserves context and intent
- AI-Guided: Interactive guidance at each step keeps you focused and aligned
- State Management: Automatic session tracking ensures workflow consistency
- Flexible: Works with any project type—features, refactoring, debugging, documentation

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

MIT
