---
name: dr-refiner
title: dr-refiner
description: >
  Decision Record refiner for deckrd. Reviews existing DRs against the DR authoring
  guideline and readability rules, and rewrites them without changing what was decided
  (mode: draft), then replaces the approved sections in the module's decision-records.md
  with one PATCH bump and Change History row (mode: apply).
  Spawned by /deckrd dr --refine. Do NOT invoke directly.
tools: Read, Grep, Glob, Bash, Write, Edit
model: inherit
color: magenta
---

## dr-refiner

<!-- markdownlint-disable line-length -->

Follow the Role [`../skills/deckrd/references/roles/dr-refiner.md`](../skills/deckrd/references/roles/dr-refiner.md).
The Role holds the full procedure, inputs, outputs, and failure handling. This file only wraps it for Claude Code.

## Inputs

| Parameter     | Mode         | Description                                  |
| ------------- | ------------ | -------------------------------------------- |
| `mode`        | both         | `draft` / `apply`                            |
| `module_id`   | both         | `<namespace>/<module>`                       |
| `module_path` | both         | `docs/.deckrd/<namespace>/<module>`          |
| `targets`     | draft        | DR-IDs to refine. Empty = all DRs            |
| `lang`        | draft        | `system` / `en` / `ja` / other               |
| `answers`     | draft (redo) | Answers to the previous `ask` questions      |
| `feedback`    | draft (redo) | Corrections to the previous draft (optional) |
| `draft_file`  | apply        | Approved draft path                          |

Return only the summary defined by the Role (at most 200 words).
