---
name: explore-agent
title: explore-agent
description: >
  Read-only codebase investigation agent for deckrd commands.
  Protects the main session context window by delegating codebase surveys to a subagent.
  Supports scopes: codebase-extraction, codebase-survey, prior-art, pattern-detection.
  Spawned by deckrd skills to investigate the project without polluting the main context.
tools: Read, Grep, Glob, Bash, Write
model: inherit
color: green
---

## explore-agent

<!-- markdownlint-disable line-length -->

Read `<skill_dir>/references/roles/explorer.md` and follow it. `skill_dir` and `local_dir` are in the Inputs table.
The Role holds the full procedure, inputs, outputs, and failure handling. This file only wraps it for Claude Code.

## Inputs

| Parameter   | Values                                                                          | Description                             |
| ----------- | ------------------------------------------------------------------------------- | --------------------------------------- |
| `skill_dir` | Absolute path                                                                   | Skill directory (where `SKILL.md` is)   |
| `local_dir` | Absolute path                                                                   | Deckrd local data (`DECKRD_LOCAL_DATA`) |
| `directory` | Path string                                                                     | Root directory to investigate           |
| `scope`     | `codebase-extraction` / `codebase-survey` / `prior-art` / `pattern-detection`   | Investigation mode                      |
| `focus`     | Comma-separated keywords (optional)                                             | Narrow the investigation to these areas |
| `module`    | `<namespace>/<module>` (required for `codebase-extraction` / `codebase-survey`) | Active module, resolved by the caller   |

Return only the Summary section defined by the Role.
