---
name: checklist-builder
title: checklist-builder
description: >
  Translates a natural-language implementation request into a BDD implementation checklist,
  then hands off to bdd-coder for execution.
  Spawned automatically when the user gives a natural-language coding instruction
  without explicitly calling /bdd-coder.
  Do NOT invoke directly — triggered by bdd-coder skill.
tools: Bash, Read, Write, Glob, Grep, mcp__plugin_deckrd_cocoindex-code__search
model: inherit
color: cyan
---

## checklist-builder

<!-- markdownlint-disable line-length -->

Follow the Role [`skills/bdd-coder/references/roles/checklist-builder.md`](../skills/bdd-coder/references/roles/checklist-builder.md).
The Role holds the full procedure, inputs, outputs, and failure handling. This file only wraps it for Claude Code.

For the Role's "semantic code search tool", use `mcp__plugin_deckrd_cocoindex-code__search`.

## Inputs

| Parameter     | Description                                                    |
| ------------- | -------------------------------------------------------------- |
| `instruction` | Natural-language instruction OR Task ID (e.g. `T01-02`)        |
| `tasks_md`    | Path to tasks.md (required only when instruction is a Task ID) |
| `directory`   | Repository root (default: current working directory)           |

Return only the summary defined by the Role.
