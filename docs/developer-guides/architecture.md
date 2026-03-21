---
title: "Architecture Overview"
description: "High-level architecture and design principles of the deckrd project"
category: "developer-guides"
tags: ["architecture", "design", "overview"]
created: "2026-01-14"
version: "0.0.4"
authors:
  - atsushifx <https://github.com/atsushifx>
changes:
  - 0.0.4   2026-01-14  Initial version
  - 0.1.0   2026-03-21  Update schema, update Layer 3 MCP servers to cocoindex-code/filesystem, add lang/ai_model fields to session schema
copyright:
  - Copyright (c) 2026- atsushifx <https://github.com/atsushifx>
  - This software is released under the MIT License.
  - https://opensource.org/licenses/MIT
status: "published"
---

<!-- textlint-disable ja-technical-writing/sentence-length -->
<!-- markdownlint-disable line-length -->

## Architecture Overview

## System Architecture

deckrd is a plugin-based framework that provides document-driven development workflow for Claude Code. The architecture follows modular design principles with clear separation of concerns.

### Core Components

```text
deckrd/
├── Plugins/                  # Plugin modules
│   ├── deckrd/              # Main workflow plugin
│   ├── bdd-coder/           # BDD methodology
│   └── deckrd-coder/        # Coding helpers
├── Configuration/            # Tool configs
│   ├── .mcp.json           # MCP servers
│   ├── lefthook.yml        # Git hooks
│   └── configs/            # Linter/formatter configs
└── Documentation/            # Developer docs
    └── docs/               # Technical documentation
```

## Design Principles

### 1. Modularity

Each plugin is self-contained with:

- Own command implementations
- Own agent definitions
- Own documentation
- Own configuration

### 2. Composability

Plugins work together:

- deckrd provides planning workflow
- IDD framework provides execution workflow
- MCP servers provide analysis tools

### 3. Extensibility

Easy to add new plugins:

- Follow `.claude-plugin/` structure
- Implement command scripts
- Add agent definitions
- Update documentation

## Architectural Layers

### Layer 1: Claude Code CLI

**Purpose**: Runtime environment for Claude Code

**Components**:

- Plugin loader
- Command dispatcher
- Agent execution engine
- MCP client

### Layer 2: Plugins

**Purpose**: Provide domain-specific workflows

**deckrd Plugin**:

- Document generation workflow
- Session state management
- Template processing

**IDD Framework Plugin** (External):

- GitHub integration
- Issue/PR management
- Commit message generation

### Layer 3: MCP Servers

**Purpose**: Provide specialized analysis tools

**serena-mcp**:

- Semantic code search
- Natural language query-based code exploration
- Used by: root, deckrd-coder

**lsmcp**:

- File system access
- File read/write operations
- Used by: deckrd, deckrd-coder

### Layer 4: Configuration & Quality Gates

**Purpose**: Enforce code quality standards

**Pre-commit Hooks**:

- gitleaks (secret detection)
- secretlint (sensitive data)
- commitlint (message validation)

**Formatters/Linters**:

- dprint (code formatting)
- markdownlint (markdown quality)
- textlint (text quality)
- cspell (spell checking)

## Data Flow

### Document-Driven Workflow (deckrd)

```text
User Request
    ↓
/deckrd init
    ↓
Session State (.session.json)
    ↓
/deckrd req → requirements.md
    ↓
/deckrd dr → design-review.md
    ↓
/deckrd spec → specifications.md
    ↓
/deckrd impl → implementation.md
    ↓
/deckrd tasks → tasks.md
```

### Issue-Driven Workflow (IDD Framework)

```text
/idd/issue:new
    ↓
Issue Draft (temp/idd/issues/)
    ↓
Push to GitHub
    ↓
Create Branch
    ↓
Implementation
    ↓
/idd-commit-message → Staged Changes Analysis
    ↓
Git Commit
    ↓
/idd-pr → PR Draft (temp/idd/pr/)
    ↓
Create GitHub PR
```

## Plugin System

See [Plugin System Architecture](plugin-system.md) for detailed information about:

- Plugin structure
- Command implementation
- Agent definitions
- Configuration format

## MCP Integration

See [MCP Servers Reference](../specs/mcp-servers.md) for detailed information about:

- Server configuration
- Available tools
- Usage patterns
- Performance considerations

## State Management

### Session State (deckrd)

**Location**: `docs/.deckrd/.session.json`

**Purpose**: Track document workflow progress

**Format**:

```json
{
  "module": "feature-name",
  "phase": "implementation",
  "completed": ["requirements", "design-review"],
  "documents": {
    "requirements": "docs/feature-name/requirements.md"
  }
}
```

### Working Files (IDD Framework)

**Location**: `temp/idd/`

**Purpose**: Temporary files for issue/PR drafts

**Structure**:

- `issues/` - Issue drafts
- `pr/` - PR drafts
- `todo.md` - Task tracking

## Quality Assurance

### Automated Checks

1. **Pre-commit Hooks** (lefthook)
   - Secret detection
   - Commit message format
   - File staging validation

2. **Code Formatters**
   - dprint for all supported formats
   - Auto-fix on commit

3. **Linters**
   - markdownlint for documentation
   - textlint for Japanese text
   - shellcheck for bash scripts

### Manual Verification

Developers can run:

```bash
dprint check               # Formatting
markdownlint-cli2 "**/*.md"  # Markdown
textlint "**/*.md"         # Text quality
cspell check "**/*"        # Spelling
```

## Technology Stack

### Primary Language

- **Bash** - Plugin scripts and commands
- **Markdown** - Documentation
- **JSON/JSONC/YAML** - Configuration

### Tools & Libraries

- **dprint** - Code formatter
- **lefthook** - Git hooks manager
- **gitleaks** - Secret scanner
- **markdownlint-cli2** - Markdown linter
- **textlint** - Text quality checker
- **cspell** - Spell checker

### External Dependencies

- **Claude Code CLI** - Plugin runtime
- **MCP Servers** - Analysis tools
- **GitHub CLI (gh)** - GitHub integration

## Performance Considerations

### Token Usage

- Use MCP memories to cache project context
- Prefer symbolic search over full file reads
- Use grep/glob for quick searches

### Execution Speed

- Parallel tool execution where possible
- Lazy loading of MCP servers
- Cached analysis results

## Security

### Secret Protection

- gitleaks scans on every commit
- secretlint pattern matching
- Pre-commit hook blocking

### Access Control

- No credentials in repository
- Environment-based configuration
- User-specific settings in `.local.json`

## Future Architecture

### Planned Additions

1. **TypeScript Support**
   - Add TypeScript implementation
   - Full lsmcp integration
   - Enhanced code intelligence

2. **Plugin Marketplace**
   - Distribute via Claude marketplace
   - Version management
   - Automatic updates

3. **Web Dashboard** (Optional)
   - Visual workflow tracking
   - Document preview
   - Quality metrics

## Related Documentation

- [Plugin System](plugin-system.md) - Detailed plugin architecture
- [MCP Servers](../specs/mcp-servers.md) - MCP API reference
- [Code Quality](../contributing/code-quality.md) - Quality standards
- [Development Workflow](./workflow.md) - Development process
