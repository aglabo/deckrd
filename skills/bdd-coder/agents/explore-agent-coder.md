---
name: explore-agent
title: explore-agent
description: >
  Read-only environment detection agent for bdd-coder.
  Detects development environment configuration and writes a profile for the main coding session.
  Supports scope: pattern-detection only.
  Spawned by bdd-coder skill to detect language, test framework, and tool commands.
tools: Read, Grep, Glob, Bash, mcp__plugin_deckrd_cocoindex-code__search
model: inherit
color: green
---

## explore-agent (bdd-coder)

<!-- markdownlint-disable line-length -->

Follow the Role [`skills/bdd-coder/references/roles/explorer.md`](../skills/bdd-coder/references/roles/explorer.md).
The Role holds the full procedure, inputs, outputs, and failure handling. This file only wraps it for Claude Code.

For the Role's "semantic code search tool", use `mcp__plugin_deckrd_cocoindex-code__search`.

## Inputs

| Parameter   | Values                             | Description                               |
| ----------- | ---------------------------------- | ----------------------------------------- |
| `directory` | Path string                        | Repository root to investigate            |
| `scope`     | `pattern-detection`                | Always `pattern-detection` for this agent |
| `focus`     | e.g., `test-framework,build-tools` | Comma-separated areas to detect           |

Return only the summary defined by the Role.
