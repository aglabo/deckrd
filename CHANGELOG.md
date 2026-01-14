# CHANGELOG

## [0.0.4] - 2026-01-14

### 🚀 Features

- *(plugins)* Add bdd-coder methodology agent to marketplace (BDD-driven implementation support)

### 🐛 Bug Fixes

- *(deckrd)* Fix inconsistent plugin setup and stabilize usage agent initialization
- *(deckrd)* Improve init command base directory initialization

### 💼 Other

- *(deckrd)* Clean up plugin settings and improve release script
- *(plugins)* Clean up plugin configuration and marketplace entries
- *(deckrd)* Bump version to 0.0.4

### 📚 Documentation

- *(dev)* Add developer documentation set

### ⚙️ Miscellaneous Tasks

- *(config)* Update configs and stabilize commit hooks for development workflow

## [0.0.3] - 2026-01-02

### 🚀 Features

- *(deckrd)* Complete documentation and automation for goals-to-tasks framework
- *(deckrd)* Add ai model configuration with session-based workflow

### 🐛 Bug Fixes

- *(scripts)* Create-release.sh のリリース生成を安定化
- *(scripts/run-prompt)* Normalize document types and stabilize initialization

### 💼 Other

- Set up marketplace infrastructure and reorganize skills structure
- *(plugin)* Marketplace.json の plugins を配列形式に変更
- Add release infrastructure and project metadata
- Merge (#14): fix(scripts): harden jq handling and improve agent execution stability

This change improves robustness and portability of deckrd-related scripts,
especially in environments where jq may be missing and scripts are executed
by agents.

- skills/deckrd/scripts/init-dirs.sh:
  - Require jq only when updating session data and fail fast if missing
  - Remove `set -u` to stabilize error handling during agent execution
  - Add script metadata and license header

- skills/deckrd/scripts/run-prompt.sh:
  - Load session settings via jq when available, with grep/sed fallback
  - Emit a clear warning when fallback parsing is used
  - Disable `set -u` to avoid unintended aborts in agent runs

- scripts/create-release.sh:
  - Safely manage TZ by exporting UTC temporarily and restoring afterward
  - Normalize command existence checks for zip, jq, and rsync
  - Make LICENSE* detection robust against unexpanded globs
- Bump version to 0.0.2 and update documentation

### 🚜 Refactor

- Move deckrd skill to plugins directory structure

### 📚 Documentation

- *(readme)* Rewrite README as deckrd documentation
- *(release)* Add changelog and improve release tooling for v0.0.2
- Restructure and clarify documentation for usage and plugins

### ⚙️ Miscellaneous Tasks

- Move deckrd-coder plugin to plugins directory and register in marketplace

### 🛡️ Security

- Consolidate repository configurations and remove obsolete templates
