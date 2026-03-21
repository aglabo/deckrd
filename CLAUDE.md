---
title: deckrd Project - Claude Code Guide
version: 0.1.0
---

<!-- textlint-disable
  ja-technical-writing/sentence-length -->
<!-- markdownlint-disable line-length -->

## Project

**deckrd** — Goals → Requirements → Specifications → Implementation → Tasks

- Language: Bash (.sh) / Platform: Windows + Cross-platform
- Repo: <https://github.com/aglabo/deckrd> / License: MIT

## Structure

```text
deckrd/
├── plugins/deckrd/          # Main plugin (skills, scripts, assets)
├── plugins/deckrd-coder/    # BDD coding helper plugin
├── docs/                    # user-guides, developer-guides, specs, contributing, onboarding
├── configs/                 # Linter/formatter configs
└── temp/idd/                # IDD framework working files
```

## Plugins

| Plugin                   | Commands                                                          | Session                      |
| ------------------------ | ----------------------------------------------------------------- | ---------------------------- |
| `plugins/deckrd/`        | `/deckrd` (init, module, req, dr, spec, impl, tasks, status, rev) | `.local/deckrd/session.json` |
| `plugins/deckrd-coder/`  | `/deckrd-coder <task-id>`                                         | —                            |
| IDD Framework (external) | `/idd/issue:*`, `/idd-pr`, `/idd-commit-message`                  | `temp/idd/`                  |

IDD Framework location: `~/.claude/plugins/marketplaces/claude-idd-framework-marketplace/plugins/claude-idd-framework`

## Workflow

**Planning (deckrd)**:
`/deckrd init <project> <type>` → `module <ns>/<mod>` → `req` → `dr` (opt) → `spec` → `impl` → `tasks`

**Execution (IDD)**:
`/idd/issue:new` → branch → implement → `/idd-commit-message` → `/idd-pr`

> Details: [Workflow Guide](docs/developer-guides/workflow.md) | [Deckrd Commands](docs/developer-guides/deckrd-commands.md)

## Quality Gates

| Tool                  | Purpose          | Run via                       |
| --------------------- | ---------------- | ----------------------------- |
| dprint                | Formatting       | `dprint fmt` / `dprint check` |
| markdownlint          | Markdown         | `pnpm run lint:markdown`      |
| textlint              | Text quality     | `pnpm run lint:text`          |
| shellcheck            | Bash scripts     | automatic                     |
| gitleaks + secretlint | Secret detection | pre-commit hook               |
| commitlint            | Commit message   | pre-commit hook               |

**DO NOT** invoke `runners/run-*.sh` directly — always use `pnpm run` scripts.

## Tool Selection

| Task                 | Tool                                                |
| -------------------- | --------------------------------------------------- |
| Bash code analysis   | serena-mcp                                          |
| Code generation      | codex-mcp                                           |
| Documentation search | Read, Grep                                          |
| deckrd commands      | `plugins/deckrd/skills/deckrd/references/commands/` |
| IDD commands         | IDD Framework path above                            |

## Key Docs

- [Architecture](docs/developer-guides/architecture.md)
- [Plugin System](docs/developer-guides/plugin-system.md)
- [Code Quality](docs/contributing/code-quality.md)
- [Tool Selection](docs/developer-guides/tool-selection.md)
- [MCP Servers API](docs/specs/mcp-servers.md)
