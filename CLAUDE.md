---
title: deckrd Project - Claude Code Guide
version: 0.0.4
authors:
  - atsushifx
changed: 2026-01-14 dev-docに分離
---

<!-- textlint-disable ja-technical-writing/sentence-length -->
<!-- textlint-disable ja-technical-writing/max-comma -->

## Core Principles

### Project Purpose

**deckrd** transforms goals into executable tasks through systematic documentation.

**Core Workflow**: Goals → Requirements → Design → Specifications → Implementation → Tasks

### Project Essentials

- Language: Bash scripts (.sh)
- Platform: Windows/Cross-platform
- Repository: <https://github.com/aglabo/deckrd>
- License: MIT (Copyright 2025- aglabo)

### Development Philosophy

1. **Document-Driven**: Plan before implementing
2. **Quality-First**: Automated checks at every commit
3. **Modular Design**: Plugin-based architecture
4. **Tool-Assisted**: MCP servers for analysis

## Technical Context

### Project Structure

```text
deckrd/
├── plugins/          # deckrd, bdd-coder, deckrd-coder
├── docs/             # Technical documentation
│   ├── dev-guides/   # Setup, workflow
│   ├── dev-architecture/  # Architecture, plugins
│   ├── dev-api/      # MCP API reference
│   └── dev-standards/  # Commands, quality, tools
├── configs/          # Linter/formatter configs
├── scripts/          # Utility scripts
└── temp/idd/         # IDD working files
```

### MCP Servers

**serena-mcp**: Semantic bash script analysis

- Memories: `.serena/memories/`
- Tools: find_symbol, search_for_pattern, get_symbols_overview

**lsmcp**: TypeScript/JavaScript LSP (future support)

- Cache: `.lsmcp/`
- Tools: Symbol search, diagnostics, refactoring

**codex-mcp**: AI code generation

- Tools: Template processing, code suggestions

**Detailed API**: See [MCP Servers API Reference](docs/dev-api/mcp-servers.md)

### Plugin System

**Main Plugin** (`plugins/deckrd/`):

- Commands: `/deckrd` (init, req, dr, spec, impl, tasks, status)
- Session: `docs/.deckrd/.session.json`

**External Plugin** (IDD Framework):

- Location: `~/.claude/plugins/marketplaces/claude-idd-framework-marketplace/plugins/claude-idd-framework`
- Commands: `/idd/issue:*`, `/idd-pr`, `/idd-commit-message`
- Working: `temp/idd/`

**Details**: See [Plugin System Architecture](docs/dev-architecture/plugin-system.md)

### Development Workflow

**Planning** (deckrd): `/deckrd init` → req → dr → spec → impl → tasks

**Execution** (IDD): Issue → Branch → Implementation → Commit → PR

**Details**: See [Development Workflow Guide](docs/dev-guides/workflow.md)

### Quality Standards

**Automated**:

- dprint (formatting)
- markdownlint, textlint (documentation)
- gitleaks, secretlint (security)
- commitlint (Conventional Commits)

**Manual Verification**:

```bash
dprint check
markdownlint-cli2 "**/*.md"
textlint --config ./configs/textlintrc.yaml "**/*.md"
cspell check "**/*.{sh,md,json,yml,yaml}"
```

**Details**: See [Code Quality Standards](docs/dev-standards/code-quality.md)

## Documentation Reference

### Getting Started

- **[Workflow Guide](docs/dev-guides/workflow.md)** - Development process and workflows

### Command Reference

- **[Deckrd Commands](docs/dev-standards/deckrd-commands.md)** - `/deckrd` commands
- **[IDD Commands](docs/dev-standards/idd-commands.md)** - `/idd` commands

### Architecture

- **[Architecture Overview](docs/dev-architecture/architecture.md)** - System design
- **[Plugin System](docs/dev-architecture/plugin-system.md)** - Plugin development

### Development Standards

- **[Code Quality](docs/dev-standards/code-quality.md)** - Quality requirements
- **[Tool Selection](docs/dev-standards/tool-selection.md)** - When to use which tool
- **[MCP Configuration](docs/dev-standards/mcp-servers.md)** - MCP setup

### API Reference

- **[MCP Servers API](docs/dev-api/mcp-servers.md)** - Complete MCP API reference

### Contribution Guidelines

- **[CONTRIBUTING.md](CONTRIBUTING.md)** - How to contribute
- **[README.md](README.md)** - Project overview

## Quick Commands

### Development

```bash
# Format code
dprint fmt

# Quality checks
markdownlint-cli2 "**/*.md"
textlint --config ./configs/textlintrc.yaml "**/*.md"
cspell check "**/*.{sh,md,json,yml,yaml}"

# Install hooks
pnpm run prepare
```

### Workflow

```bash
# IDD workflow
/idd/issue:new
/idd-commit-message
/idd-pr

# deckrd workflow
/deckrd init
/deckrd req
/deckrd spec
/deckrd impl
/deckrd tasks
```

### Git

```bash
# Commit (Conventional Commits)
git commit -m "type(scope): description"

# Types: feat, fix, docs, style, refactor, test, chore, ci, perf, build, release
```

## Tool Selection Quick Reference

| Task                    | Tool                                          |
| ----------------------- | --------------------------------------------- |
| Bash analysis           | serena-mcp                                    |
| TypeScript (future)     | lsmcp                                         |
| Documentation           | Read, Grep                                    |
| Code generation         | codex-mcp                                     |
| Command search (deckrd) | `plugins/deckrd/`                             |
| Command search (IDD)    | `~/.claude/plugins/.../claude-idd-framework/` |

**Details**: See [Tool Selection Guide](docs/dev-standards/tool-selection.md)

## Important Paths

- deckrd project: `~/workspaces/develop/deckrd`
- IDD framework: `~/.claude/plugins/marketplaces/claude-idd-framework-marketplace\plugins/claude-idd-framework`
- Session files: `docs/.deckrd/.session.json`
- Temp files: `temp/idd/`

---

**For detailed information, always refer to the documentation files linked above.**
