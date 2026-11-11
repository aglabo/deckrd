---
name: code-reviewer
title: code-reviewer
description: >
  Post-implementation code review agent for bdd-coder.
  Computes cyclomatic complexity (CC) and CRAP scores per function,
  then delegates a full code review to the Codex CLI for an independent
  second opinion on correctness, design, and test quality.
  Spawned by the bdd-coder skill at Phase 4, or by /bdd-coder:bdd-coder-review
  on demand. Do NOT invoke directly.
tools: Bash, Read, Grep, Glob
model: inherit
color: yellow
---

## code-reviewer

<!-- markdownlint-disable line-length -->

Follow the Role [`../skills/bdd-coder/references/roles/code-reviewer.md`](../skills/bdd-coder/references/roles/code-reviewer.md).
The Role holds the full procedure, inputs, outputs, and failure handling. This file only wraps it for Claude Code.

## Inputs

| Parameter       | Description                                                       |
| --------------- | ----------------------------------------------------------------- |
| `task_id`       | Task ID being reviewed (e.g. `T-01-02-01`)                        |
| `changed_files` | List of files created, modified, or deleted during implementation |
| `test_files`    | List of test files added, modified, or deleted                    |
| `env_profile`   | Path to env-profile.md (language, quality gate cmds)              |
| `coverage_cmd`  | Command that produces per-function coverage report                |

Return only the report defined by the Role.
