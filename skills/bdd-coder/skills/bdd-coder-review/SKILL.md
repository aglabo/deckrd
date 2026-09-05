---
name: bdd-coder-review
description: >
  Run an independent code review on already-implemented code by spawning the code-reviewer agent.
  Computes CC / CRAP scores per function and gets a codex second opinion on correctness,
  test quality, and design. Use when the user says "review the code", "コードレビューして",
  "review what bdd-coder implemented", "check CRAP scores", or wants a review after
  /bdd-coder:bdd-coder finished. Read-only — never edits code, never commits.
metadata:
  author: aglabo
  version: 0.1.0
  license: MIT
argument-hint: "[task_id] [--branch | <paths...>] [--coverage-cmd <cmd>]"
---

<!-- textlint-disable
  ja-technical-writing/sentence-length -->

# /bdd-coder:bdd-coder-review — Code Review via code-reviewer

## Overview

Spawn the **code-reviewer** agent against already-written code.

This skill is a thin dispatcher: it resolves the five inputs code-reviewer requires,
spawns the agent, and presents the returned report. It MUST NOT compute CRAP itself,
redefine review criteria, or fix any finding.

Review criteria, CRAP formula, thresholds, and the report format live in the agent
definition: [agents/code-reviewer.md](../../agents/code-reviewer.md).

Scope is **aggregate**: the whole resolved diff is reviewed in a single invocation.
This skill does not loop per task.

## Usage

```bash
/bdd-coder:bdd-coder-review [task_id] [--branch | <paths...>] [--coverage-cmd <cmd>]
```

### Arguments

| Argument         | Required | Description                                                                          |
| ---------------- | -------- | ------------------------------------------------------------------------------------ |
| `task_id`        | No       | Task ID for the report header (e.g. `T-01-02-01`). Resolved automatically if omitted |
| `--branch`       | No       | Review the whole branch (`main...HEAD`) instead of uncommitted changes               |
| `<paths...>`     | No       | Explicit file paths to review. Overrides git-diff resolution                         |
| `--coverage-cmd` | No       | Coverage command to use when ENV PROFILE has none                                    |

## Execution Steps

### Step 1: Resolve review targets

| Condition            | Command                                                            |
| -------------------- | ------------------------------------------------------------------ |
| Explicit paths given | Use them as is                                                     |
| `--branch`           | `git diff main...HEAD --name-only`                                 |
| Default              | `git diff --name-only` merged with `git diff --name-only --cached` |

The default merges staged and unstaged output so a partially staged working tree is not
silently under-reviewed. Deduplicate the merged list, and drop paths that no longer exist
(deleted files have nothing to review).

If the resolved list is empty: report `No changes to review` with the resolution method used, and stop.

### Step 2: Split into `changed_files` and `test_files`

If `temp/deckrd-work/env-profile.md` exists, follow its test-file convention.

If it does not, fall back to the common conventions below and **state in the report which rule was used**:

| Language   | Test file pattern                      |
| ---------- | -------------------------------------- |
| TypeScript | `*.spec.*` / `*.test.*` / `__tests__/` |
| Go         | `*_test.go`                            |
| Rust       | `tests/` / `#[cfg(test)]` in-file      |
| Shell      | `*_spec.sh` / `spec/`                  |

### Step 3: Resolve `task_id`

Argument → `temp/bdd-coder/bdd-todo.md` → `N/A`, in that order.

`N/A` is normal, not an error: an aggregate review spanning several tasks has no single task ID.

### Step 4: Resolve `env_profile` and `coverage_cmd`

| Input          | Resolution                                                          |
| -------------- | ------------------------------------------------------------------- |
| `env_profile`  | `temp/deckrd-work/env-profile.md` if present, else `N/A`            |
| `coverage_cmd` | `--coverage-cmd` argument → coverage command in ENV PROFILE → `N/A` |

Do NOT spawn explore-agent and do NOT define degraded behaviour here. When coverage is
unavailable, code-reviewer applies its own fallback: CC-only classification reported as `cov=N/A`
(never `coverage = 0`). See [agents/code-reviewer.md](../../agents/code-reviewer.md) — Phase 1.3.

### Step 5: Spawn code-reviewer

Spawn **code-reviewer** with:

- `task_id`: resolved in Step 3
- `changed_files`: implementation files from Step 2
- `test_files`: test files from Step 2
- `env_profile`: resolved in Step 4
- `coverage_cmd`: resolved in Step 4

Agent definition: [../../agents/code-reviewer.md](../../agents/code-reviewer.md)

### Step 6: Present the report

Display the agent's `CODE REVIEW REPORT` verbatim, preceded by:

```text
── Code Review ───────────────────────────────────
Scope: <uncommitted | branch main...HEAD | explicit paths>
Task:  <task_id>   Coverage: <coverage_cmd or "N/A">
──────────────────────────────────────────────────
```

Then state the next action for the verdict:

| Verdict              | Next action                                                   |
| -------------------- | ------------------------------------------------------------- |
| `PASS`               | Nothing to do                                                 |
| `PASS_WITH_WARNINGS` | List the warnings; the user decides whether to act on them    |
| `BLOCKED`            | Present the CRITICAL findings and ask the user how to proceed |

Never fix findings automatically, and never run `git add` or `git commit`.

## Examples

```bash
# Review uncommitted changes (most common — right after /bdd-coder:bdd-coder)
/bdd-coder:bdd-coder-review

# Review the whole branch before opening a PR
/bdd-coder:bdd-coder-review --branch

# Review specific files
/bdd-coder:bdd-coder-review src/parser.ts src/parser.spec.ts

# Review with an explicit task ID and coverage command
/bdd-coder:bdd-coder-review T-01-02-01 --coverage-cmd "pnpm run test:coverage"
```

## When to Use

| Trigger                                        | Recommended form |
| ---------------------------------------------- | ---------------- |
| `/bdd-coder:bdd-coder` finished, before commit | (no arguments)   |
| Before opening a PR                            | `--branch`       |
| A specific file feels over-complex             | explicit paths   |

Inside `/bdd-coder:bdd-coder`, Phase 4 already runs this review; invoking it manually is unnecessary there.

## Reference

- Agent definition: [agents/code-reviewer.md](../../agents/code-reviewer.md)
- CRAP formula and thresholds: [bdd-coder/assets/test-quality.md](../bdd-coder/assets/test-quality.md)
- Phase 4 in the BDD flow: [bdd-coder/references/workflow.md](../bdd-coder/references/workflow.md)
