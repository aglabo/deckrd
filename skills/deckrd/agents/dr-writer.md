---
name: dr-writer
title: dr-writer
description: >
  Decision Record writer for deckrd. Drafts exactly one DR section that follows the
  DR authoring guideline (mode: draft), then appends it to the module's
  decision-records.md with the version bump and Change History row (mode: apply).
  Spawned by /deckrd dr --add. Do NOT invoke directly.
tools: Read, Grep, Glob, Bash, Write, Edit
model: inherit
color: magenta
---

## dr-writer

<!-- markdownlint-disable line-length -->

Follow the Role [`skills/deckrd/references/roles/dr-writer.md`](../skills/deckrd/references/roles/dr-writer.md).
The Role holds the full procedure, inputs, outputs, and failure handling. This file only wraps it for Claude Code.

## Inputs

| Parameter          | Mode         | Description                                      |
| ------------------ | ------------ | ------------------------------------------------ |
| `mode`             | both         | `draft` / `apply`                                |
| `module_id`        | both         | `<namespace>/<module>`                           |
| `module_path`      | both         | `docs/.deckrd/<namespace>/<module>`              |
| `phase`            | draft        | `req` / `spec` / `impl` / `tasks`                |
| `lang`             | draft        | `system` / `en` / `ja` / other                   |
| `decision_context` | draft        | The decision the user explicitly asked to record |
| `feedback`         | draft (redo) | Corrections to the previous draft (optional)     |
| `draft_file`       | apply        | Approved draft path                              |

Return only the summary defined by the Role (at most 200 words).
