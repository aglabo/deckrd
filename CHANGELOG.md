---
title: "CHANGELOG"
description: "ChangeLog: 0.9.1"
version: "0.9.1"
date: "2026-11-24"
summary:
  - "0.9.1: test case ID checker in bdd-coder, range and all-under-Target multi-task runs, switching to an existing module, rev exempt from the order gate"
---

<!-- textlint-disable
  ja-technical-writing/sentence-length,
  ja-technical-writing/max-comma,
  -->
<!-- markdownlint-disable line-length -->

## CHANGELOG

## 0.9.1 - 2026-11-24

### Features

- Add the test case ID checker `check-test-ids.sh` to `bdd-coder` (moved from `runners/`). It
  detects missing, misplaced, and duplicate test case IDs, supports branch-expanded IDs and
  abbreviations containing digits, and checks that target abbreviations are unique across modules.
  File discovery uses `rg` with a `find` fallback, and `gawk` is preferred with an `AWK` override.
- Document the checker in `SKILL.md` and `references/test-id-check.md` (modes, exit codes,
  configuration, table-driven and fixture ID formats).
- Add range (`T01-01..03`) and all-under-Target (`'T01-*'`) multi-task runs to `bdd-coder`. Tasks
  run one by one through a Target ID tasklist, with `queue` and `index` stored in the session. A
  BLOCKED task stops the run (fail-fast) and `--resume` continues from `queue[index]`. Phase 4 runs
  once per item, `status: done` is set after the last item, and nothing is committed or pushed.
- Make `tasklist-builder` (1.1.0 to 1.2.0) return `status: invalid-input` for a range or `T01-*`,
  because the caller resolves them and passes the Target ID.
- Switch to an existing module with `/deckrd module <namespace>/<module>` instead of failing. Only
  `active` and `updated_at` are written to `session.json`; the module's progress and `test_scope`
  are kept. `--test-scope` cannot be given when switching, and `--force` re-initializes the module
  and resets its session progress.
- Add `switch_session` to `module.sh`. It fails when `session.json` or the module entry is missing,
  or when the write fails.
- Retarget `scripts/bump-version.sh` to the plugin JSON and `SKILL.md` files. It now updates the
  version in `package.json`, `deckrd.json`, `.claude-plugin/marketplace*.json`,
  `skills/*/.claude-plugin/plugin.json`, and `skills/*/skills/*/SKILL.md` (the frontmatter
  `version:` line), and no longer touches `.github/workflows/`.

### Docs

- Refine the test case ID rules in `deckrd-rule-testing-guidelines.md`: rename "ケース ID" to
  "テストケース ID", add rules for table-driven and fixture test IDs (literal IDs with variable
  branch suffixes, unique two-digit branch numbers), allow digits in abbreviations, and require
  target abbreviations to be unique across the repository.
- Document module switching in the command references, `session.md`, the developer guide
  (`deckrd-commands.md`), and the user guide (`02-commands.ja.md`), and add the `MSS`, `MUM`,
  `MUS`, `MSW`, and `STR` prefixes to the module test table.
- Document range and all-under-Target runs in the `bdd-coder` README, `SKILL.md`, `faq.md`,
  `troubleshooting.md`, and `workflow.md`, and state that the caller resolves task ID ranges in
  `tasklist-builder`.
- Exempt `rev` from the order gate: it requires only `init`, and `rev --to impl --path <path>`
  needs no module. Route undocumented code through `rev --to impl`, `spec`, `req` in
  `deckrd-rule-workflow.md`.

### Tooling

- Track `.claude-plugin/` and its JSON files in `.gitignore`, and refine the allow and ignore rules
  (`skills/`, `aglabo.github.io/`, Beads / Dolt files).
- Remove the `blume` exclude patterns from `dprint.jsonc` and bump `@dprint/typescript` from 0.99.1
  to 0.101.0.
- Bump `packageManager` from pnpm 12.21.0 to 12.23.0 and remove the `starter` keyword from
  `package.json`.
- Simplify the scope regex of `headerPattern` in `configs/commitlint.config.mjs`, and condense the
  header comments of `.shellspec`.
- Remove unused ignore patterns from `.textlintignore`.
- Remove `runners/run-check-test-ids.sh` and the runner unit tests, and inline shell file discovery
  in `run-shellcheck.sh` (excluding `node_modules`, `.tools`, and `*.spec.sh`).
- Replace the `ci-platform` commit SHA pins in the `ci-docs-qa`, `ci-scan-secrets`, and
  `ci-workflows-qa` workflows with the `v0.8.1` tag.

## 0.9.0 - 2026-11-24

### Breaking Changes

- Redesign `/deckrd rev` as a reverse chain: code → impl → spec → req. The target decides the
  source (`impl` from code, `spec` from `implementation.md`, `req` from `specifications.md`).
- Remove the `--from` option and the `--to tasks` target. Change the default of `--to` from `req`
  to `impl`.
- Delete `rev.template.md`. `rev` now uses the standard template of its TARGET.

### Features

- Add `--path <path>` (repeatable) to `rev --to impl` to limit the investigation to files or
  directories.
- Add `resolve_rev_template` to `generate-doc.sh`: it reads the `TARGET:` line of the context and
  selects the requirements, specifications, or implementation template (default `implementation`).
- Update `rev.prompt.md`, the explorer role, `explore-agent.md`, and the command references and
  user guides for the reverse chain.

### Docs

- Add the task branch workflow: one integration branch per feature and one short-lived task branch
  per Target (`T-XX`), with the caller owning all git operations.
- Add the 40 Scenarios per Target limit to `tasks`; a larger Target is split by behavior group.
- Condense the descriptions of the skills and agents.

## 0.8.1 - 2026-11-21

### Refactor

- Change Universal Dictionary IDs from `UD-NNN` to chapter-coded `UD-<CODE>-NNN`. A chapter code
  is 2 to 6 characters starting with an uppercase letter, unique within the module, and the
  serial number is a 3-digit sequence per chapter code.
- Keep the ID when a term moves to another chapter, never reuse a deprecated ID, and add a new
  chapter and chapter code when no existing chapter fits.
- Update `deckrd-rule-document-model.md` (1.7.0 to 1.8.0) with the chapter code rules, and split
  the ID issuance steps into a numbered list.
- Update `specifications.prompt.md`, `universal-dictionary.prompt.md`,
  `specifications.template.md`, and `universal-dictionary.template.md` to the new ID format, and
  add a Chapter Codes section (1.5) to the dictionary template.
- Change the UD-ID duplicate and broken-reference detection patterns in
  `spec-phases/09-dictionary.md` and `spec-phases/11-spec-review.md` to
  `UD-[A-Z][A-Z0-9]{1,5}-[0-9]{3}`.

### Tooling

- Add `runners/run-betterleaks.sh` for staged and directory scans, and improve config resolution
  in `run-shellcheck.sh` and `run-shfmt.sh` (`shfmt` now reads `.editorconfig`).
- Run betterleaks through `run-betterleaks.sh --staged` and secretlint with `{staged_files}` in
  `lefthook.yml`, and route the lint scripts in `package.json` through `cross-env MSYS=NOGLOB`.
- Bump `packageManager` from pnpm 12.15.0 to 12.21.0 and `argue-cli` from 3.2.0 to 3.2.1.
- Remove `configs/betterleaks.toml` and `configs/secretlint.config.yaml`, and clean up
  `configs/cliff.toml`.
- Restructure the `.gitignore` allowlist, add `skills/.gitignore`, and allow
  `/.claude-plugin/*.json` for the marketplace.
- Move the excluded directory list of `run-shellcheck.sh` into `find_shell_files`.
- Rename the cspell dictionary `test-target-dic` to `test-id-dic`.
- Update the `commit-message-generator` agent to 0.10.0 with a 76-character header limit, a
  96-character body wrap, and a type priority order.
- Unify the shell style in `runners/`, `scripts/`, and `skills/deckrd/skills/deckrd/scripts/`:
  function braces on the next line, unquoted and padded `[[ ]]` operands, indented `case`
  branches, and spaces around redirections.

## 0.8.0 - 2026-11-16

### Features

- Add the Universal Dictionary phase to `/deckrd spec` as Phase 9. The later phases move to Phase 10 (generate), Phase 11 (spec review), Phase 12 (version bump), and Phase 13 (second opinion).
- Add the `universal-dictionary` prompt and template: terms are grouped by category, carry UD-IDs, and record status, deprecation with replacement UD-IDs, evidence, and DR conflicts.
- Add the `universal-dictionary` document type (alias `dict`) to `normalize-doc-type.lib.sh` and `generate-doc.sh`.
- Let the specification prompt and template reference the dictionary (frontmatter and a terminology table with UD-IDs), and check terminology consistency in the spec review. Dictionary sections are omitted when no dictionary exists.
- Bump the Universal Dictionary version before the specification so that the specification references the dictionary's final version.
- Classify specification items as `Contract`, `Guarantee`, or `Extension` with a `Class` column in the specification template, and add the classification criteria to the spec review. An `Extension` row needs a source.
- Exclude `Class = Extension` rows from implementation plan phases and commits, and from `tasks` generation (reported as `Extension (out of scope)` in the Coverage Check).
- Separate the programming language from the document language. `--prog` (alias `--language`) sets the programming language stored as `prog`; `--lang` sets the document language (`DOC_LANG`) and is written to `session.json` only when specified.
- Normalize the programming language `bash` to `shell`, and rename the `.project.json` key `language` to `prog`.
- Migrate legacy `session.json` `lang` values for programming languages to `prog` in `init` and `/deckrd update --update`, and show `Program` and `Language` in `status`.
- Add the declarative argument parser `libs/args.lib.sh` (`args_init`, `args_flag`, `args_value`, `args_positional`, `parse_args`).
- Support the inline `--test-scope=XY` form in `module.sh`.

### Bug Fixes

- Write JSON files atomically through `write_json_file`, which uses a `mktemp` temporary file and rejects directories and symbolic links to directories before running `jq`.
- Report write failures in `init`, `project`, and `module` with an error message and exit status 1, and stop `init` before `session.json` is created when `.project.json` cannot be written.
- Fix the default AI model of `prepare-commit-msg.sh` from `gpt-6-luna` to `gpt-5.6-luna`.

### Refactor

- Migrate argument parsing in `init.sh`, `module.sh`, `update.sh`, and `project.sh` to `args.lib.sh` and remove their local parsers.
- Move the atomic JSON write helper into `utils.lib.sh` as `write_json_file` and use it from `init.sh`, `module.sh`, `project.sh`, and `session.lib.sh`.
- Split `init.sh` into `_run_init_steps` and `_init_session_preserve`, and add a `main` function to `project.sh`.

### Performance

- Dispatch one `bdd-coder` agent per Target instead of per Case. Each Case still runs its own Red-Green-Refactor cycle inside the Target, and the Target gets a regression run, a changed-file check, and split conditions.
- Clarify Case IDs and the `NEEDS_CONTEXT` / `BLOCKED` status for quality gate failures when a Target is split.

### Documentation

- Document scoped per-Target `progress_path` for `bdd-todo.md` in `bdd-coder`, including how `<scope>` is determined, parallel execution of independent Targets, and sequential execution of split Targets.
- Make `bdd-coder-review` use the scoped per-Target `bdd-todo.md` paths and set the task ID to `N/A` when several files exist.
- Document that `bdd-coder` reads the programming language from `prog` in `session.json`, falling back to `.deckrd/profile.json`.
- Document the `--prog` and `--lang` options, the document language resolution order, and the `lang` to `prog` migration in the command references, `SKILL.md`, prompts, roles, developer guides, and user guides.
- Define the Universal Dictionary rules (UD-ID numbering, location, authority, status, versioning) in `deckrd-rule-document-model.md` (1.5.2 to 1.6.0) and add them to `deckrd-rules-index.md`.
- Point the Decision Record location in `docs/.deckrd/README.md` to the per-module `decision-records.md`.
- Add the `init_session` and `write_project` entries to the `module` workspace document.

### Tooling

- Add the Claude rule `claude-rule-command-execute.md`: pass slash command arguments to the skill unchanged, and ask the user when an explicit flag conflicts with later natural language.
- Add test target abbreviations (`MAINI`, `UPDA`, `UPDI`) to the cspell dictionary.
- Upgrade `@astrojs/node` to 11.1.12 in `aglabo.github.io` and pin the minimum version with a pnpm override (Dependabot #6).

## 0.7.0 - 2026-11-11

### Features

- Support standalone skill installation through `npx skills` and `gh skill install`.
- Add the `dr-writer` agent and the `/deckrd dr --add` flow: draft exactly one Decision Record, then append it to `decision-records.md` after approval with DR-ID numbering, Supersede handling, a version bump, and a Change History row.
- Add the `dr-refiner` agent and `/deckrd dr --refine [DR-ID ...]`: rewrite existing Decision Records without changing what was decided, replacing only the approved sections with one PATCH bump and Change History row.
- Add the Decision Record authoring guideline (`references/guidelines/decision-record-authoring.md`) and rewrite the `decision-record` prompt to generate a single DR section.
- Add the `comment-review` skill and the `comment-refiner` agent to delete, move, or rewrite code comments without changing code (draft, then apply the approved diff).
- Add the code comment guideline (`code-comments.md`, rules C-1 to C-10).
- Add the `tasklist-builder` agent and `tasklist.tpl.md`: break a natural-language request or a `tasks.md` Target ID into a task list in which each item makes one checklist. Re-running the same Target ID returns the existing task list.
- Run `tasklist-builder` as Phase 1a of `bdd-coder`, before `checklist-builder`.
- Add `rev` and `decision-record` document types to `normalize-doc-type.lib.sh`.

### Bug Fixes

- Resolve `generate-doc.sh` prompts from canonical document types (`@impl`, `@rev`, `@decision-record`) and report unknown document types as errors (#283).
- Reject `review` without a phase as an unknown document type in `normalize-doc-type.lib.sh`.
- Correct role reference links and paths in the Deckrd and bdd-coder agent definitions.
- Resolve explorer project paths from the input `directory`.

### Refactor

- Move agent procedures into role files under `references/roles/` and reduce the agent definitions to thin wrappers.
- Add canonical roles: Deckrd `explorer`, `dr-writer`, and `dr-refiner`; bdd-coder `implementer`, `explorer`, `checklist-builder`, `code-reviewer`, `tasklist-builder`, and `comment-refiner`.
- Let callers run a role themselves when subagents cannot be launched.
- Pass `skill_dir` and `local_dir` to roles and agents as arguments instead of using fixed `.local/deckrd` paths.
- Resolve bundled resources (`assets/`, `references/`) from `skill_dir` and local data (session, temp files, task lists, checklists) from `local_dir`.
- Replace the `<DECKRD_SKILL_DIR>` placeholder in command reference script paths and `generate-doc.sh` instructions.
- Remove obsolete workspace documents under `docs/.deckrd/`.

### Documentation

- Document the role and thin-wrapper structure and the `skill_dir` and `local_dir` arguments in the developer guides.
- Sync the command references, README files, and user guides with the implementation: `project` and `review` commands, `module --test-scope`, `status` output, session schema, and `tasks` output.
- Document `/deckrd update` behavior for existing files and `.gitignore` handling.
- Add a Release section to the workflow guide, and forbid symbolic links inside `skills/deckrd/skills/deckrd/`.
- Document the explore-agent fallback when subagents are unavailable.
- Fix stale path references, session schema, layout, and tool names in the developer guides.
- Replace gitleaks with betterleaks and correct the textlint config lookup order in the contributing guide.
- Use `npx -y` in the filesystem MCP server example.
- Replace `deckrd-coder` references with `bdd-coder` and correct related documentation links.
- Document the v0.6.0 breaking changes in this changelog (`codex-mcp` removal and the `workspaces/module/module.md` location).

### Tooling

- Add `shdoc` to the project spelling dictionary and a cspell `noqa` directive to the code comment guideline.
- Correct test and library script path comments.
- Inline the `allowed-tools` list in the `deckrd-review` skill.

## 0.6.1 - 2026-11-10

### Bug Fixes

- Show the project config path as `.local/deckrd/.project.json` in the `project.sh` help text and result summary.
- Make the `rev` prompt read its target from the `TARGET` line of the input context instead of a `--mode` option that `generate-doc.sh` does not have.

### Documentation

- Correct the command references: the `.local/deckrd/.project.json` path, the `generate-doc.sh @implementation` and `@rev` invocations, and the `init <project> <project-type> --force` form.
- Correct the session location override variable to `DECKRD_LOCAL_DATA`.
- Correct the v0.6.0 changelog and release note descriptions of `init --force`, `/deckrd update --update`, the AI timeout, and the commit-message hook model.

### Tooling

- Skip `.tools` and `node_modules` directories at any depth when `run-shellcheck.sh` looks for shell files.
- Ignore everything under `node_modules` in `.editorconfig`.
- Add test target abbreviations to the cspell dictionary.

## 0.6.0 - 2026-10-04

### Features

- Add `/deckrd update` to list and apply missing or outdated bundled assets.
- Add `init <project> <project-type> --force` to redeploy every bundled asset. It overwrites `.gitignore` files and user-edited files, and preserves only `session.json`.
- Keep normal `init` re-runs non-destructive across nested asset directories: only missing files are installed.
- Add recursive asset deployment with `.org` suffix handling, source mtime preservation, and protected asset support.
- Add shared asset copy and diff helpers for `init` and `update`.
- Add migration support for legacy `.local/deckrd/.gitignore` workspace rules.
- Create `.local/deckrd/temp/` and `.local/deckrd/workspaces/` during initialization.
- Add `workspaces/` directories for persistent project and module working files.
- Move module metadata to `workspaces/module/module.md`.
- Add Windows ShellSpec execution through WSL.
- Add `fable` model support to `prepare-commit-msg.sh`.
- Add module input and writable output support to the Deckrd `explore-agent`.
- Add the `DECKRD_AI_TIMEOUT` environment variable and raise the default AI timeout from 120 to 300 seconds.

### Bug Fixes

- Send command and validation errors to stderr instead of stdout.
- Stop initialization immediately when directory creation or asset deployment fails.
- Fix session and document path resolution across Deckrd commands.
- Fix `generate-doc` session validation, path resolution, and verbose configuration output.
- Harden `run_ai` stdin validation, timeout handling, empty response detection, and stdout/stderr separation.
- Preserve `run_ai` exit status correctly under `errexit`.
- Isolate Codex execution from user MCP configuration.
- Fix ShellSpec runner PATH propagation for integration and system tests.
- Preserve all ShellSpec spec targets and argument order.
- Improve project root resolution inside and outside Git repositories.
- Prevent asset deployment into Deckrd's own asset source tree through symlinks, hard links, or nested paths.
- Preserve UNC path prefixes during path normalization.
- Fix shared `SKILL_ROOT` and Deckrd library path resolution.
- Prevent computed skill paths from leaking into child process environments.
- Reduce parallel naming collisions.
- Preserve dangling workspace README symlinks during updates.

### Refactor

- Move temporary and regeneratable working files under `.local/deckrd/temp/`.
- Define separate temporary, shared workspace, and module workspace layers.
- Split the specification workflow into 12 phase-specific reference documents.
- Separate detailed usage and examples from `SKILL.md` files into reference documents.
- Enforce one input per generated BDD test case.
- Split test IDs into group IDs and case IDs.
- Rebuild `run-check-test-ids.sh` with separate declaration indexes and cached lookups.
- Centralize `init` command options in an associative array.
- Reorganize shared asset deployment helpers and path utilities.

### AI and Review

- Migrate Codex integrations from `codex-mcp` to the Codex CLI.
- Remove the Codex MCP server configuration.
- Use `codex exec` for Deckrd review, bdd-coder review, and related agent workflows.
- Add Codex CLI availability and login checks.
- Add metrics-only fallback when Codex review is unavailable.
- Distinguish unavailable Codex review output from a clean review.
- Add deterministic commit message generation rules.
- Change the commit-message model passed by the `prepare-commit-msg` hook in `lefthook.yml` to `gpt-5.6-luna` (the script default stays `sonnet`).
- Improve coverage-unavailable handling with `cov=N/A` and `CRAP=N/A` instead of assuming zero coverage.

### Testing

- Add system tests for `generate-doc` and AI runner execution.
- Add stderr leak detection for generated document content.
- Expand asset deployment regression and end-to-end coverage.
- Add Windows and WSL ShellSpec runner tests.
- Add coverage for workspace paths, session paths, bootstrap behavior, and asset migration.
- Add group and case test IDs across CLI, library, runner, and subcommand tests.

### Security

- Change the repository `.gitignore` to an allowlist-based policy.
- Add explicit tracking rules for Deckrd workspace files.
- Replace Gitleaks with Betterleaks in quality gates and CI.
- Update reusable Actionlint and Ghalint workflows and pin their revisions.

### Documentation

- Document `/deckrd update`, `init --force`, and recursive asset deployment.
- Document `.local/deckrd/.project.json` and `.local/deckrd/session.json`.
- Document the new temporary, shared workspace, and module workspace layout.
- Document module metadata migration to `workspaces/module/module.md`.
- Document Codex CLI installation, login, and troubleshooting.
- Document Windows ShellSpec execution through WSL.
- Update Deckrd, bdd-coder, review, workflow, and developer guides for the new paths and command behavior.
- Add troubleshooting and scenario reference documents.

### Tooling

- Add `check:dprint:diff` and report differing files from dprint checks.
- Update cspell dictionaries for new test IDs and project terms.
- Move the hackers dictionary into the shared Deckrd assets directory.
- Share Deckrd libraries and dictionary assets with bdd-coder through symlinks.

### Breaking Changes

- The `codex-mcp` server configuration is removed. Codex review now runs through `codex exec`, so the Codex CLI must be on `PATH` and logged in.
- Module metadata is read only from `workspaces/module/module.md`. Move an existing `module.md` there by hand: `/deckrd update` does not move it, and the old location is no longer read.

## 0.5.0 - 2026-09-12

### 🚀 Features

- *(deckrd/rules)* Consolidate 5 rules (traceability / id-system / document-naming / file-structure / commit-linkage) into `deckrd-rule-document-model.md` and `deckrd-rule-workflow.md`
- *(deckrd/rules)* Add `bdd-cycle`, `coding-guidelines`, `testing-guidelines`, `document-versioning`, `runners`, and `second-opinion` rules — the rule set is now 8 files
- *(deckrd/rules)* Separate rule bodies from the index — bodies install under `docs/.deckrd/rules/`, the index under `.claude/rules/deckrd-rules/`
- *(deckrd/init)* Install Claude command rules into `.claude/rules/claude-rules/` during initialization
- *(deckrd/init)* Strip the `.org` suffix when copying init assets — allows shipping `.gitignore.org` templates
- *(deckrd/module)* Derive and record the module test scope in `module.md`, rejecting conflicting explicit scopes
- *(bdd-coder)* Add `bdd-coder-review` skill — runs `code-reviewer` on demand via `/bdd-coder:bdd-coder-review`; supports `--branch [base]` and `--coverage-cmd`
- *(bdd-coder)* Scope code review to session-changed files instead of the whole working tree
- *(bdd-coder)* Add Phase 5 Done Check — writes results back to `tasks.md` checkboxes and status
- *(runners)* Add a test case ID checker (`check:test-ids`) — verifies ID scope declarations, coverage, abbreviation tables, and unidentified cases
- *(scripts/bump-version)* Add `package.json` and `deckrd.json` to the version bump targets

### 🐛 Bug Fixes

- *(mcp)* Use plugin-scoped MCP tool names (`mcp__plugin_<plugin>_<server>__<tool>`) across agents and skills
- *(scripts)* Unify error output to stderr
- *(scripts)* Remove the dead `validate_env` capture and guard `status.sh`
- *(runners/run-shellspec)* Fix the shellcheck source directive and restrict test type filtering to `tests/${test_type}`
- *(tests)* Fix garbled Japanese text in test descriptions

### ♻️ Refactor

- *(runtime)* Relocate runtime libraries from `skills/_runtime/` into the deckrd plugin
- *(libs)* Rename library scripts from `*.sh` to `*.lib.sh` and update all source paths
- *(scripts)* Prefer `jq` over `jaq` and route all JSON reads through `jq_read`
- *(runners)* Centralize variable initialization in `runners/libs/init-vars.lib.sh`

### 📚 Documentation

- *(deckrd/tasks)* Add WBS / MECE task decomposition guidance
- *(deckrd,bdd-coder)* Apply SemVer versioning to documents, templates, and commands
- *(deckrd/rules)* Add frontmatter (title / description / version) to all rule assets
- *(specs/mcp-servers)* Rewrite the MCP reference for the actual 3-server layout (cocoindex-code / filesystem / codex-mcp) and drop the obsolete serena-mcp and lsmcp sections
- *(user-guides)* Document the new rule layout and add migration steps for existing projects

### ⚙️ Miscellaneous Tasks

- *(config)* Move the package to ESM and switch the markdownlint / textlint CLIs
- *(config)* Update dprint — bump the json plugin to 0.23.0 and add the toml plugin (0.8.0)
- *(release)* Unify all plugin and skill versions to 0.5.0
- *(marketplace)* Rename the marketplace to `deckrd` and set the owner URL to `https://github.com/aglabo/deckrd`

### 💥 Breaking Changes

- *(deckrd/rules)* Rule files are consolidated and relocated — projects initialized before this release must re-run `/deckrd init` first, then delete the 5 legacy rule files, the old index, and the legacy `.claude/rules/.gitignore` (see the migration steps in `docs/user-guides/02-commands.ja.md`)
- *(runtime)* Runtime libraries move out of `skills/_runtime/` into the deckrd plugin
- *(libs)* Library scripts are renamed from `*.sh` to `*.lib.sh`
- *(config)* `package.json` is now `"type": "module"` — config files must be ESM

---

## 0.4.0 - 2026-06-19

### ♻️ Refactor

- *(plugins)* Rename `deckrd-coder` to `bdd-coder` — command changes from `/deckrd-coder` to `/bdd-coder:bdd-coder`; functionality is unchanged
- *(bootstrap)* Update path detection in `bootstrap.lib.sh` from `*/deckrd-coder/*` to `*/bdd-coder/*`

### 🚀 Features

- *(deckrd/commands)* Add `deckrd-review` skill — calls codex as an independent critical reviewer via `/deckrd:deckrd-review`; supports `--focus` option (`completeness` / `risk` / `consistency` / `feasibility`)
- *(scripts)* Add `bump-version.sh` — automates semver updates across `plugin.json`, `SKILL.md`, and `marketplace*.json` files

### ⚙️ Miscellaneous Tasks

- *(marketplace)* Update marketplace name to `deckrd` and owner URL to production GitHub URL (`https://github.com/aglabo/deckrd`)
- *(release)* Bump all plugin and skill versions to 0.4.0

### 💥 Breaking Changes

- *(plugins)* Rename command `/deckrd-coder` → `/bdd-coder:bdd-coder`

---

## 0.3.0 - 2026-06-19

### ♻️ Refactor

- *(plugins)* Migrate `deckrd` and `deckrd-coder` assets from `plugins/` to `skills/` directory — aligns with Agent Skills standard structure and enables installation via `gh skills` and `npx skills`
- *(plugins)* Split `deckrd-coder` into an independent plugin — can now be installed and managed separately from `deckrd`
- *(runtime/libs)* Move shared runtime libraries to `skills/_runtime/libs/` — single source of truth across both plugins
- *(scripts)* Update all bootstrap paths and test spec paths from `plugins/_runtime/` to `skills/_runtime/`

---

## 0.2.1 - 2026-06-18

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

## 0.2.0 - 2026-06-08

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

## 0.1.0 - 2026-03-22

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

## 0.0.4 - 2026-01-14

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

## 0.0.3 - 2026-01-02

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
