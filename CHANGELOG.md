# CHANGELOG

<!-- textlint-disable ja-technical-writing/sentence-length -->

## [0.1.0] - 2026-03-22

### 🚀 Features

- *(deckrd/core)* Introduce bootstrap-based environment initialization and centralized runtime variables
- *(deckrd/libs)* Add core libraries:
  - session.sh (state management)
  - config.sh (configuration abstraction)
  - ai-runner.sh (multi-provider AI execution and validation)
- *(deckrd/workflow)* Establish phase-based review system:
  - review-explore / review-harden / review-fix
- *(deckrd/templates)* Add BDD implementation checklist template with hierarchical task IDs
- *(deckrd/commands)* Introduce profile/project configuration command and structured workflow commands
- *(runners)* Add unified runner scripts for lint, format, and test execution
- *(tests)* Integrate ShellSpec testing framework with multi-layer test structure

---

### 💥 Breaking Changes

- Rename `profile` → `project` (config file: `.local/deckrd/project.json`)
- Replace `run-prompt.sh` with `generate-doc.sh`
- Remove `--phase` option in favor of phase-specific doc-types (`review-explore`, etc.)
- Rename environment variables:
  - `DECKRD_LOCAL` → `DECKRD_LOCAL_DATA`
- Normalize doc-type arguments to `@<type>` format

---

### 🐛 Bug Fixes

- Stabilize AI execution by disabling MCP during Claude invocation
- Fix commit message generation hang issues
- Improve fallback behavior when `jq` is not available
- Fix session path inconsistencies across scripts

---

### ♻️ Refactor

- Extract script logic into reusable libraries (session/config/ai-runner)
- Centralize environment resolution via bootstrap
- Simplify generate-doc execution flow and remove global state variables
- Reorganize ShellSpec tests into layered structure (unit/functional/integration/system)

---

### 📚 Documentation

- Add comprehensive command references (review, module, profile, status)
- Document phase-based review workflow and decision record integration
- Update requirements/spec/implementation workflows with multi-phase execution models
- Add rules for traceability, naming conventions, and commit linkage

---

### ⚙️ Miscellaneous Tasks

- Split CI workflows into focused pipelines (secrets scan / workflow QA)
- Add runner scripts for textlint, markdownlint, shellcheck, and shellspec
- Normalize project configuration and dictionary entries (cspell, commitlint)

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
