# CHANGELOG

<!-- textlint-disable ja-technical-writing/sentence-length -->

## [0.2.1] - 2026-06-18

### 🚀 Features

- *(deckrd/prompts)* `tasks` prompt: accept Decision Records (DR) as input — DR entries are converted to observable behavior coverage items automatically
- *(deckrd/prompts)* `tasks` prompt: add source coverage verification — blocks output if any spec section or DR entry is uncovered
- *(deckrd/prompts)* `tasks` prompt: add category balance verification — reports missing Normal / Error / Edge categories per test target
- *(deckrd-coder/checklist-builder)* Add Phase 3.5 Spec Coverage Review — validates all spec sections are represented in the checklist
- *(deckrd-coder/checklist-builder)* Add Phase 3.6 Category Balance Review — detects missing Error / Edge test cases and reports gaps in the completion summary

---

### ⚙️ Miscellaneous Tasks

- *(configs)* Set Claude default mode to `plan` and restrict git write commands via permission settings
- *(configs)* Improve CHANGELOG generation: include commit body, remove emoji prefixes from parsers

---

## [0.2.0] - 2026-06-08

### 🚀 Features

- *(deckrd-coder)* Introduce `checklist-builder` agent — converts natural-language instructions into BDD implementation checklists automatically
- *(deckrd-coder)* `/deckrd-coder` now accepts natural-language instructions in addition to Task IDs
- *(deckrd-coder)* Add `code-reviewer` agent — computes CC / CRAP scores per function and delegates a full code review to Codex after Phase 7
- *(deckrd/commands)* `req` command: add Phase 5 Codex second-opinion step (required for external interfaces; recommended otherwise)
- *(deckrd/commands)* `spec` command: add Phase 4 Codex second-opinion step
- *(deckrd/prompts)* `tasks` prompt: support split-file implementation mode and add EARS-to-BDD mapping table
- *(runtime/libs/naming)* Add `adjective_random()` function for random adjective generation in checklist filenames
- *(runtime/libs/naming)* Rewrite filename generation with atomic cache to prevent duplicate filenames under concurrent execution
- *(runtime/libs)* Add `jq_read` utility for CRLF normalization on Windows

---

### 🐛 Bug Fixes

- *(ai-runner)* Increase `run_ai` default timeout from 5 s to 120 s — prevents premature timeout on slow AI responses
- *(mcp)* Replace `pnpx` with `npx -y` in filesystem MCP configuration

---

### ♻️ Refactor

- *(runtime/libs)* Consolidate shared libraries under `plugins/_runtime/libs/` — single source of truth for bootstrap, kv-store, naming, and utils
- *(validate-env)* Add `jaq` support as an alternative to `jq`
- *(scripts/libs)* Unify all error output to stderr across ai-runner, kv-store, naming, normalize-doc-type, and validate-env
- *(deckrd-coder)* Move all deckrd-coder assets into the deckrd plugin for unified management

---

### ⚙️ Miscellaneous Tasks

- Migrate pre-commit secret scanning from `gitleaks` to `betterleaks`
- Switch MCP server from `serena-mcp` to `@modelcontextprotocol/server-filesystem`

---

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
