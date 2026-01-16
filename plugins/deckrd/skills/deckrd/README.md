---
title: deckrd skill specification
type: skill-documentation
scope: deckrd skill
audience:
  - claude
  - skill users
  - maintainers
purpose:
  - define the contract and invariants of the deckrd skill
  - describe the stepwise derivation workflow and its commands
non_goals:
  - plugin installation instructions
  - internal MCP server implementation details
  - project-specific usage examples
meta:
  author: atsushifx
  version: 0.0.4
---

<!--textlint-disable ja-technical-writing/sentence-length -->
<!--textlint-disable ja-technical-writing/no-exclamation-question-mark -->
<!-- markdownlint-disable line-length -->

## deckrd skill

This skill guides a stepwise derivation workflow: **goals → requirements → specifications → executable tasks**.

## Purpose

The deckrd skill enables systematic requirement engineering and task derivation through a structured, narrowly-focused workflow. It enforces a discipline of deep analysis at each stage, ensuring specifications are precise and tasks are actionable.

## How To Use

The deckrd workflow transforms vague goals into concrete, executable tasks through a systematic derivation process:

```bash
      Your Goals
         │
         ▼
  ┌─────────────────┐
  │  init: Define   │  Clarify goals & scope
  │  Goals & Scope  │
  └────────┬────────┘
           │  dr: record & validate changes
           ▼
  ┌──────────────────┐
  │  req:            │ derive requirements
  │  (Requirements)  │
  └────────┬─────────┘
           │  dr: record & validate changes
           ▼
  ┌──────────────────┐
  │  spec:           │ define specifications
  │  (Specification) │
  └────────┬─────────┘
           │  dr: record & validate changes
           ▼
  ┌───────────────────┐
  │  impl: Plan       │ plan implementation (not coding)
  │  (Implementation) │
  └────────┬──────────┘
           │  dr: record & validate changes
           ▼
  ┌─────────────────┐
  │  tasks:         │
  │  Executable     │    generate executable tasks
  │  Task List      │
  └────────┬────────┘
           │
           ▼
  Executable Tasks
(Ready for Development)
```

### Principles

deckrd enforces a strict, stepwise workflow.
Each step deepens understanding before moving forward.

## Commands

| Command                      | Description                                    |
| ---------------------------- | ---------------------------------------------- |
| `init`                       | Initialize `deckrd` direcory                   |
| `init <ns>/<mod>`            | Initialize module directory and session        |
| `req`                        | Derive requirements from goals                 |
| `dr`                         | Manage Decision Records                        |
| `dr --add`                   | Append a new Decision Record                   |
| `spec`                       | Derive specifications from requirements        |
| `impl`                       | Derive implementation plan from specifications |
| `tasks`                      | Derive executable tasks from implementation    |
| `status`                     | Display current workflow progress and status   |
| `review`                     | Show review command usage                      |
| `review <doc> [--phase <p>]` | Review document with phase-specific analysis   |

## Review Command

The `review` command supports document analysis with three review phases:

### Usage

```bash
/deckrd review                    # Show usage
/deckrd review req                # Review requirements (explore phase)
/deckrd review req --phase harden # Review requirements (harden phase)
/deckrd review spec --phase fix   # Review specifications (fix phase)
```

### Review Phases

| Phase   | Persona                         | Purpose                            |
| ------- | ------------------------------- | ---------------------------------- |
| explore | Design Reviewer                 | Identify gaps, raise questions     |
| harden  | Normative Requirements Reviewer | Promote to MUST/SHALL, generate DR |
| fix     | Spec Auditor                    | Normalize, verify consistency      |

### Document Phases

| Doc Phase | Target Document                  |
| --------- | -------------------------------- |
| req       | requirements/requirements.md     |
| spec      | specifications/specifications.md |
| impl      | implementation/implementation.md |
| tasks     | tasks/tasks.md                   |
