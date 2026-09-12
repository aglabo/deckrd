<!-- textlint-disable
  ja-technical-writing/sentence-length,
  ja-technical-writing/max-comma,
  -->

# deckrd v0.5.0

v0.5.0 reorganizes the deckrd rule system, strengthens the BDD workflow, and simplifies the internal runtime and test infrastructure.

This release includes **breaking changes for existing projects**.
If you are upgrading from an earlier version, see the migration section below.

## Highlights

### Reorganized deckrd rules

The deckrd rule set has been consolidated and reorganized into **8 focused rule files**.

Related rules for traceability, IDs, document naming, file structure, and commit linkage have been merged
into the new document model and workflow rules. New rules cover:

- BDD cycles
- coding guidelines
- testing guidelines
- document versioning
- runners
- second-opinion reviews

Rule bodies and Claude-facing indexes are now installed separately:

- `docs/.deckrd/rules/` — deckrd rule definitions
- `.claude/rules/deckrd-rules/` — Claude rule index
- `.claude/rules/claude-rules/` — Claude command rules

This keeps project documentation separate from the rules Claude needs to load directly.

### Improved BDD workflow

The BDD workflow now provides stronger review and completion checks.

A new `/bdd-coder:bdd-coder-review` command runs `code-reviewer` on demand
and supports branch-based review and custom coverage commands.

Code review is now scoped to files changed during the current session instead of the entire working tree.

Phase 5 also gains a **Done Check** that verifies completion and writes the results back to `tasks.md`,
including task status and checkboxes.

### Test scope and test ID validation

deckrd can now derive a module's test scope automatically and record it in `module.md`.
Conflicting explicit scopes are rejected.

A new `check:test-ids` runner validates test case IDs, including:

- declared ID scopes
- test coverage
- abbreviation tables
- unidentified test cases

This makes the relationship between specifications, tasks, and tests easier to verify mechanically.

### Cleaner runtime and tooling

Internal runtime libraries have moved from `skills/_runtime/` into the deckrd plugin.

Shell libraries now use the `*.lib.sh` naming convention, JSON handling is standardized on `jq`,
and runner initialization has been centralized.

The package has also moved to ESM, and the linting and formatting configuration has been updated.

### MCP configuration cleanup

Agents and skills now use plugin-scoped MCP tool names.

The MCP documentation has also been updated to match the current three-server setup:

- `cocoindex-code`
- `filesystem`
- `codex-mcp`

Obsolete `serena-mcp` and `lsmcp` references have been removed.

## Documentation improvements

This release expands the documentation around the development workflow:

- WBS / MECE guidance for task decomposition
- SemVer versioning for deckrd and bdd-coder documents
- versioned frontmatter for rule assets
- updated MCP server documentation
- migration guidance for the new rule layout

## Upgrading from an earlier release

The rule layout has changed and requires migration for existing projects.

Before running the new initialization:

1. Delete the five legacy deckrd rule files.
2. Delete the old deckrd rule index.
3. Run `/deckrd init` again.

The initialization process will install the new rule layout under `docs/.deckrd/rules/` and `.claude/rules/`.

There are also internal compatibility changes to be aware of:

- runtime libraries moved out of `skills/_runtime/`
- shell libraries were renamed from `*.sh` to `*.lib.sh`
- `package.json` now uses `"type": "module"`

Projects or extensions that directly reference these internal paths or CommonJS configuration files must be updated.

## Other changes

This release also includes several smaller fixes and maintenance improvements, including corrected
ShellSpec filtering, standardized stderr handling, fixed Japanese test descriptions, updated dprint
plugins, and improved version-bump handling for `package.json` and `deckrd.json`.

All deckrd plugin and skill versions are now aligned at **0.5.0**.
