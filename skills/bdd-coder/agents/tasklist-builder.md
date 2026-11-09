---
name: tasklist-builder
title: tasklist-builder
description: >
  Task list builder for bdd-coder. Breaks a natural-language request, or a Target (T-XX)
  in tasks.md, into a task list where each item makes exactly one checklist. Writes
  .local/deckrd/temp/tasklist/<name>.tasklist.md and returns the next item's Handoff.
  Spawned by the bdd-coder skill at Phase 1a, before checklist-builder.
  Do NOT invoke directly.
tools: Bash, Read, Write, Glob, Grep, mcp__plugin_deckrd_cocoindex-code__search
model: inherit
color: cyan
---

## tasklist-builder

<!-- markdownlint-disable line-length -->

Follow the Role [`skills/bdd-coder/references/roles/tasklist-builder.md`](../skills/bdd-coder/references/roles/tasklist-builder.md).
The Role holds the full procedure, inputs, outputs, and failure handling. This file only wraps it for Claude Code.

## Inputs

| Parameter     | Description                                             |
| ------------- | ------------------------------------------------------- |
| `instruction` | Natural-language request, or Target ID (`T-01` / `T01`) |
| `tasks_md`    | Path to tasks.md (Target ID only)                       |
| `answers`     | Answer to the previous `questions` run (optional)       |

Return only the summary defined by the Role.
