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

Read `<skill_dir>/references/roles/checklist-builder.md` and follow it. `skill_dir` and `local_dir` are in the Inputs table.
The Role holds the full procedure, inputs, outputs, and failure handling. This file only wraps it for Claude Code.

For the Role's "semantic code search tool", use `mcp__plugin_deckrd_cocoindex-code__search`.

## Inputs

| Parameter     | Description                                                    |
| ------------- | -------------------------------------------------------------- |
| `skill_dir`   | Absolute path of the skill directory (where `SKILL.md` is)     |
| `local_dir`   | Absolute path of the deckrd local data (`DECKRD_LOCAL_DATA`)   |
| `instruction` | Natural-language instruction OR Task ID (e.g. `T01-02`)        |
| `tasks_md`    | Path to tasks.md (required only when instruction is a Task ID) |
| `directory`   | Repository root (default: current working directory)           |

Return only the summary defined by the Role.
