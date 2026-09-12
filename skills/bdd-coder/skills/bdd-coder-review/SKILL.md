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
  version: 0.5.0
  license: MIT
argument-hint: "[task_id] [--branch [<base>] | <paths...>] [--coverage-cmd <cmd>]"
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

Inside `/bdd-coder:bdd-coder`, Phase 4 already runs this review; invoking it manually is unnecessary there.

## Usage

```bash
/bdd-coder:bdd-coder-review [task_id] [--branch [<base>] | <paths...>] [--coverage-cmd <cmd>]
```

### Arguments

| Argument         | Required | Description                                                                          |
| ---------------- | -------- | ------------------------------------------------------------------------------------ |
| `task_id`        | No       | Task ID for the report header (e.g. `T-01-02-01`). Resolved automatically if omitted |
| `--branch`       | No       | Review the whole branch (`<base>...HEAD`). Takes an optional base branch name        |
| `<paths...>`     | No       | Explicit file paths to review. Overrides git-diff resolution                         |
| `--coverage-cmd` | No       | Coverage command to use when ENV PROFILE has none                                    |

## Execution Steps

### Step 1: Resolve review targets

| Condition            | Command                                                                                                             |
| -------------------- | ------------------------------------------------------------------------------------------------------------------- |
| Explicit paths given | Use them as is                                                                                                      |
| `--branch`           | `git diff <base>...HEAD --name-only`, where `<base>` is resolved below                                              |
| Default              | `git diff --name-only`, `git diff --name-only --cached`, and `git ls-files --others --exclude-standard`, all merged |

The default merges three sources so nothing is silently under-reviewed:

| Source                                     | Covers                                             |
| ------------------------------------------ | -------------------------------------------------- |
| `git diff --name-only`                     | Unstaged edits                                     |
| `git diff --name-only --cached`            | Staged edits (a partially staged tree needs both)  |
| `git ls-files --others --exclude-standard` | New, not-yet-added files, ignoring gitignored ones |

The third source matters most: right after `/bdd-coder:bdd-coder`, a brand-new
implementation or test file is untracked, and the first two commands do not list it.

Deduplicate the merged list. **Keep deleted paths.** A deletion is a substantive change —
removed validation or removed test coverage — and code-reviewer inspects its patch with
`git diff -- <path>` instead of reading the file. Never filter a path just because it is
gone from disk.

#### Resolving `<base>` for `--branch`

Do not hard-code `main`. Resolve in this order and stop at the first hit:

| Order | Source                                                                                  |
| ----- | --------------------------------------------------------------------------------------- |
| 1     | A base branch given by the user on the command line                                     |
| 2     | `git symbolic-ref --quiet --short refs/remotes/origin/HEAD`, minus the `origin/` prefix |
| 3     | `git config --get init.defaultBranch`                                                   |
| 4     | The first of `main`, `master`, `develop` that `git rev-parse --verify` resolves         |

`origin/HEAD` is unset in many repositories, so steps 3 and 4 are the normal path, not a
rare fallback. If no candidate resolves, report the failure and ask the user for the base
branch — never guess.

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
Scope: <uncommitted | branch <base>...HEAD | explicit paths>
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

## Reference

呼び出し例・使いどころ・関連ドキュメントは [usage.md](references/usage.md) にあります。
どの引数形式で呼ぶか迷ったときに読んでください。
