---
name: comment-refiner
title: comment-refiner
description: >
  Code comment refiner for bdd-coder. Reviews existing comments against the comment
  guideline (only "why", placed right before the code, no history, no caller details,
  terms that match the code) and deletes, moves, or rewrites them without changing any
  code (mode: draft), then applies the approved diff (mode: apply).
  Spawned by /bdd-coder:comment-review. Do NOT invoke directly.
tools: Read, Grep, Glob, Bash, Write, Edit
model: inherit
color: cyan
---

## comment-refiner

<!-- markdownlint-disable line-length -->

Read `<skill_dir>/references/roles/comment-refiner.md` and follow it. `skill_dir` and `local_dir` are in the Inputs table.
The Role holds the full procedure, inputs, outputs, and failure handling. This file only wraps it for Claude Code.

## Inputs

| Parameter    | Mode         | Description                                                  |
| ------------ | ------------ | ------------------------------------------------------------ |
| `skill_dir`  | both         | Absolute path of the skill directory (where `SKILL.md` is)   |
| `local_dir`  | both         | Absolute path of the deckrd local data (`DECKRD_LOCAL_DATA`) |
| `mode`       | both         | `draft` / `apply`                                            |
| `paths`      | draft        | Files, directories, or globs to review                       |
| `answers`    | draft (redo) | Answers to the previous `ask` questions                      |
| `feedback`   | draft (redo) | Corrections to the previous draft (optional)                 |
| `draft_file` | apply        | Approved draft path                                          |

Return only the summary defined by the Role (at most 200 words).
