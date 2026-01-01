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
  version: 0.0.3
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
