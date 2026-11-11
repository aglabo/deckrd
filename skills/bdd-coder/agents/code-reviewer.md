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

Read `<skill_dir>/references/roles/code-reviewer.md` and follow it. `skill_dir` and `local_dir` are in the Inputs table.
The Role holds the full procedure, inputs, outputs, and failure handling. This file only wraps it for Claude Code.

## Inputs

| Parameter       | Description                                                       |
| --------------- | ----------------------------------------------------------------- |
| `skill_dir`     | Absolute path of the skill directory (where `SKILL.md` is)        |
| `local_dir`     | Absolute path of the deckrd local data (`DECKRD_LOCAL_DATA`)      |
| `task_id`       | Task ID being reviewed (e.g. `T-01-02-01`)                        |
| `changed_files` | List of files created, modified, or deleted during implementation |
| `test_files`    | List of test files added, modified, or deleted                    |
| `env_profile`   | Path to env-profile.md (language, quality gate cmds)              |
| `coverage_cmd`  | Command that produces per-function coverage report                |

Return only the report defined by the Role.
