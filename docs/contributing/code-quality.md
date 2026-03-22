---
title: "Code Quality Standards"
description: "Code quality standards, formatting rules, and quality gates for deckrd project"
category: "contributing"
tags: ["quality", "standards", "formatting", "linting"]
created: "2026-01-14"
version: "0.1.0"
authors:
  - atsushifx <https://github.com/atsushifx>
changes:
  - 0.0.4   2026-01-14  Initial version
  - 0.1.0   2026-03-21  Version update
copyright:
  - Copyright (c) 2026- atsushifx <https://github.com/atsushifx>
  - This software is released under the MIT License.
  - https://opensource.org/licenses/MIT
status: "published"
---

<!-- textlint-disable ja-technical-writing/sentence-length -->
<!-- markdownlint-disable line-length -->

## Code Quality Standards

## Overview

The deckrd project maintains high code quality through automated formatting, linting, and quality gates enforced by pre-commit hooks.

## Formatting Standards

### dprint (Code Formatter)

**Configuration**: `dprint.jsonc`

**Supported Formats**:

- Markdown
- JSON/JSONC
- YAML
- TOML

**Settings**:

```jsonc
{
  "lineWidth": 120,
  "indentWidth": 2,
  "newLineKind": "lf",
  "useTabs": false,
  "markdown": {
    "textWrap": "always",
  },
  "json": {
    "indentWidth": 2,
  },
  "yaml": {
    "indentWidth": 2,
  },
}
```

**Usage**:

```bash
# Format all files
dprint fmt

# Check formatting
dprint check

# Format specific file
dprint fmt README.md
```

### EditorConfig

**Configuration**: `.editorconfig`

**Settings**:

- Charset: utf-8
- Indent: 2 spaces
- End of line: LF
- Trim trailing whitespace: true
- Insert final newline: true

## Linting Standards

### markdownlint-cli2 (Markdown)

**Configuration**: `.markdownlintrc.yaml`

**Key Rules**:

- MD001: Heading levels increment by one
- MD003: Heading style (ATX)
- MD004: List style (dash)
- MD013: Line length max 120
- MD022: Headings surrounded by blank lines
- MD025: Single H1 per document
- MD033: No inline HTML (except specific tags)

**Exceptions**:

```yaml
MD033: # Allow specific HTML tags
  allowed_elements: ["br", "kbd", "details", "summary"]
```

**Usage**:

```bash
# Lint all markdown
markdownlint-cli2 "**/*.md"

# Fix auto-fixable issues
markdownlint-cli2 --fix "**/*.md"

# Lint specific file
markdownlint-cli2 README.md
```

### textlint (Text Quality)

**Configuration**: `configs/.textlintrc.yaml`

**Purpose**: Japanese technical writing quality

**Rules**:

- Terminology consistency
- Technical term usage
- Sentence structure
- Readability

**Usage**:

```bash
# Check all markdown
textlint --config ./configs/textlintrc.yaml "**/*.md"

# Fix auto-fixable issues
textlint --fix --config ./configs/textlintrc.yaml "**/*.md"

# Check specific file
textlint --config ./configs/textlintrc.yaml README.ja.md
```

### cspell (Spell Checker)

**Configuration**: `cspell.json`

**Supported Files**:

- Markdown (.md)
- Shell scripts (.sh)
- JSON/JSONC/YAML
- Configuration files

**Custom Dictionary**:

- Project-specific terms
- Technical jargon
- Tool names

**Usage**:

```bash
# Check all files
cspell check "**/*.{sh,md,json,yml,yaml}"

# Check specific file
cspell check README.md

# Show suggestions
cspell check --show-suggestions README.md
```

## Commit Message Standards

### Conventional Commits

**Format**: `type(scope): description`

**Types**:

- feat: New feature
- fix: Bug fix
- docs: Documentation only
- style: Formatting (no code change)
- refactor: Code refactoring
- test: Adding tests
- chore: Maintenance tasks
- ci: CI/CD changes
- perf: Performance improvement
- build: Build system changes
- release: Version release

**Scope** (Optional):

- Component or module name
- Examples: `deckrd`, `idd-framework`, `mcp`

**Description**:

- Imperative mood ("add" not "added")
- Lowercase first letter
- No period at end
- Max 72 characters

**Examples**:

```bash
feat(deckrd): add status command support
fix(scripts): correct path resolution in init.sh
docs: update setup guide with Windows instructions
refactor: simplify session state management
```

### commitlint

**Configuration**: `commitlint.config.js`

**Enforcement**: Automatic via pre-commit hook

**Usage**:

```bash
# Test commit message
echo "feat(deckrd): add new feature" | commitlint

# Check last commit
commitlint --from HEAD~1
```

## Security Standards

### gitleaks (Secret Detection)

**Configuration**: `configs/gitleaks.toml`

**Purpose**: Detect accidentally committed secrets

**Scans For**:

- API keys
- Passwords
- Private keys
- Access tokens
- Database credentials

**Usage**:

```bash
# Scan staged files
gitleaks protect --config ./configs/gitleaks.toml --staged

# Scan entire repo
gitleaks detect --config ./configs/gitleaks.toml

# Scan specific file
gitleaks detect --config ./configs/gitleaks.toml --file .env
```

### secretlint

**Configuration**: `configs/secretlint.config.yaml`

**Purpose**: Find sensitive data patterns

**Patterns**:

- AWS credentials
- GCP credentials
- API tokens
- Private keys
- Slack tokens

**Usage**:

```bash
# Scan all files
secretlint --config ./configs/secretlint.config.yaml "**/*"

# Scan specific file
secretlint --config ./configs/secretlint.config.yaml .env
```

## Quality Gates

### Pre-commit Hooks (lefthook)

**Configuration**: `lefthook.yml`

**Hooks**:

#### 1. prepare-commit-msg

**Purpose**: Auto-format commit message

**Script**: `scripts/prepare-commit-msg.sh`

**Actions**:

- Formats message to Conventional Commits
- Adds Co-Authored-By if missing
- Preserves merge/rebase messages

#### 2. commit-msg (commitlint)

**Purpose**: Validate commit message format

**Actions**:

- Checks Conventional Commits format
- Validates type and scope
- Ensures proper description

#### 3. pre-commit (gitleaks)

**Purpose**: Detect secrets in staged files

**Actions**:

- Scans staged files
- Blocks commit if secrets found
- Shows detected patterns

#### 4. pre-commit (secretlint)

**Purpose**: Additional secret pattern detection

**Actions**:

- Scans with different patterns
- Complementary to gitleaks
- Blocks commit if found

**Usage**:

```bash
# Install hooks
pnpm run prepare

# Run hooks manually
lefthook run pre-commit

# Skip hooks (not recommended)
git commit --no-verify
```

## Manual Quality Checks

### Before Committing

```bash
# Format code
dprint fmt

# Lint markdown
markdownlint-cli2 "**/*.md"

# Check text quality
textlint --config ./configs/textlintrc.yaml "**/*.md"

# Spell check
cspell check "**/*.{sh,md,json,yml,yaml}"

# Check for secrets
gitleaks protect --config ./configs/gitleaks.toml --staged
```

### Before Creating PR

```bash
# Run all checks
dprint check
markdownlint-cli2 "**/*.md"
textlint --config ./configs/textlintrc.yaml "**/*.md"
cspell check "**/*.{sh,md,json,yml,yaml}"
gitleaks detect --config ./configs/gitleaks.toml

# Verify commit messages
git log --oneline -10  # Check format
```

## Bash Script Standards

### Strict Mode

```bash
#!/usr/bin/env bash
set -euo pipefail
```

**Flags**:

- `-e`: Exit on error
- `-u`: Exit on undefined variable
- `-o pipefail`: Exit on pipe failure

### Constants

```bash
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
```

### Error Handling

```bash
# Check prerequisites
if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "Error: Config file not found" >&2
  exit 1
fi

# Validate inputs
if [[ -z "${MODULE:-}" ]]; then
  echo "Error: MODULE not specified" >&2
  exit 1
fi
```

### Function Style

```bash
# Use descriptive names
get_current_module() {
  local session_file=$1
  jq -r '.module // empty' "$session_file"
}

# Document complex functions
# Initializes session file
# Arguments:
#   $1 - module name
#   $2 - session file path
# Returns:
#   0 on success, 1 on error
initialize_session() {
  local module=$1
  local session_file=$2
  # Implementation
}
```

## Documentation Standards

### Markdown Structure

```markdown
# Document Title

## Overview

Brief description

## Section

Content

### Subsection

Details
```

### Code Blocks

````markdown
```bash
# Command with description
command --flag value
```

```json
{
  "key": "value"
}
```
````

### Links

```markdown
# Internal links (relative)

# External links (absolute)

[GitHub](https://github.com/aglabo/deckrd)

# Anchor links

[Installation](#installation)
```

### Images

```markdown
![Alt text](path/to/image.png)
```

## Quality Metrics

### Target Metrics

- dprint pass rate: 100%
- markdownlint pass rate: 100%
- textlint pass rate: 100%
- cspell pass rate: 100%
- gitleaks violations: 0
- Commit message compliance: 100%

### Monitoring

```bash
# Check all metrics
dprint check && \
markdownlint-cli2 "**/*.md" && \
textlint --config ./configs/textlintrc.yaml "**/*.md" && \
cspell check "**/*.{sh,md,json,yml,yaml}" && \
gitleaks detect --config ./configs/gitleaks.toml && \
echo "All quality checks passed ✓"
```

## Troubleshooting

### dprint Fails

```bash
# Format files
dprint fmt

# Check specific file
dprint fmt path/to/file.md
```

### markdownlint Fails

```bash
# Auto-fix issues
markdownlint-cli2 --fix "**/*.md"

# Check specific rule
markdownlint-cli2 --config "{MD013: false}" README.md
```

### textlint Fails

```bash
# Auto-fix issues
textlint --fix --config ./configs/textlintrc.yaml "**/*.md"

# Disable specific rule
textlint --rule "textlint-rule-max-ten" --config ./configs/textlintrc.yaml file.md
```

### cspell Fails

```bash
# Add to dictionary
echo "deckrd" >> cspell.json

# Ignore in file
<!-- cSpell:disable -->
technical term
<!-- cSpell:enable -->
```

### gitleaks Blocks Commit

1. Remove the secret from file
2. Commit the change
3. Consider rewriting history if secret was committed

```bash
# Remove from history (careful!)
git filter-branch --force --index-filter \
  'git rm --cached --ignore-unmatch path/to/file' \
  --prune-empty --tag-name-filter cat -- --all
```

## Related Documentation

- [Development Workflow](../developer-guides/workflow.md) - Workflow process
- [Tool Selection](tool-selection.md) - Tool usage guide
- [MCP Servers](mcp-servers.md) - MCP configuration
