---
name: comment-review
description: >
  Review and simplify the comments in existing code by spawning the comment-refiner agent.
  Finds comments that restate the code, sit in the wrong place, keep change history,
  describe callers, or use terms that do not match the code, then deletes, moves, or
  rewrites them after the user approves a diff. Use when the user says "review the comments",
  "コメントをレビューして", "コメントを整理して", "simplify the shdoc", or "clean up comments".
  Changes comments only — never code. Never commits.
metadata:
  author: aglabo
  version: 0.6.1
  license: MIT
argument-hint: "[--branch [<base>] | <paths...>]"
---

<!-- textlint-disable
  ja-technical-writing/sentence-length -->

# /bdd-coder:comment-review — Comment Review via comment-refiner

## Overview

Spawn the **comment-refiner** agent on existing code, show its findings and diff, and apply
the diff only after the user approves it.

This skill is a thin dispatcher: it resolves the target paths, runs the draft → approval → apply
loop, and presents the results. It MUST NOT judge comments itself, restate the comment rules,
or edit any file.

- Comment rules: [comment guideline](../bdd-coder/references/guidelines/code-comments.md)
- Procedure, draft format, and invariants: [comment-refiner Role](../bdd-coder/references/roles/comment-refiner.md)
- Agent definition: [agents/comment-refiner.md](../../agents/comment-refiner.md)

## Usage

```bash
/bdd-coder:comment-review [--branch [<base>] | <paths...>]
```

### Arguments

| Argument     | Required | Description                                                                    |
| ------------ | -------- | ------------------------------------------------------------------------------ |
| `<paths...>` | No       | Files, directories, or globs to review. Directories are searched recursively   |
| `--branch`   | No       | Review the files changed on the branch (`<base>...HEAD`). Optional base branch |

With no argument, the uncommitted changes are reviewed.

## Execution Steps

### Step 1: Resolve targets

| Condition            | Targets                                                                                                             |
| -------------------- | ------------------------------------------------------------------------------------------------------------------- |
| Explicit paths given | Use them as is. The agent expands directories and globs                                                             |
| `--branch`           | `git diff <base>...HEAD --name-only --diff-filter=d`                                                                |
| Default              | `git diff --name-only`, `git diff --name-only --cached`, and `git ls-files --others --exclude-standard`, all merged |

- Deduplicate the list and drop paths that no longer exist. A deleted file has no comments to refine.
- Resolve `<base>` for `--branch` the same way as
  [bdd-coder-review: Resolving `<base>`](../bdd-coder-review/SKILL.md#resolving-base-for---branch). Never guess.
- If the list is empty, report `No files to review` with the resolution method used, and stop.

### Step 2: Draft

Spawn **comment-refiner** with `skill_dir`, `local_dir`, `mode: draft` and `paths` from Step 1.
`skill_dir` is the bdd-coder skill directory (`../bdd-coder/` from this file), as an absolute path.
The Role lives there, not in this skill.
`local_dir` is the value of `DECKRD_LOCAL_DATA`, as an absolute path.

Handle the result:

| `status`    | Action                                                                                            |
| ----------- | ------------------------------------------------------------------------------------------------- |
| `no-change` | Report that no comment needs a change, and stop. No file changes                                  |
| `questions` | Ask the user the questions, each with its finding ID. Re-run Step 2 with the answers in `answers` |
| `drafted`   | Continue to Step 3                                                                                |

The user may answer a question with `skip`. That finding stays as it is and is listed in the final report.

### Step 3: Show the draft

Read `draft_file` and show, per changed file:

```text
── Comment Review ────────────────────────────────
Scope: <uncommitted | branch <base>...HEAD | explicit paths>
Files: <n> changed   Findings: delete <n> / move <n> / rewrite <n> / ask <n>
──────────────────────────────────────────────────
```

Then the findings table and the diff of each file, as written in the draft.
Also list files reported as `invariant-failed` and findings left unresolved.

### Step 4: Get approval

Ask: `Apply comment changes? (yes / edit / no):`

| Answer | Action                                                                                                                  |
| ------ | ----------------------------------------------------------------------------------------------------------------------- |
| `yes`  | Continue to Step 5                                                                                                      |
| `edit` | Collect the corrections (for example "keep F03", "exclude libs/kv-store.lib.sh"), re-run Step 2 with them in `feedback` |
| `no`   | Delete the draft file and stop. No file changes                                                                         |

### Step 5: Apply

Spawn **comment-refiner** with `skill_dir`, `local_dir`, `mode: apply` and `draft_file`.

| `status`    | Action                                               |
| ----------- | ---------------------------------------------------- |
| `applied`   | Continue to Step 6                                   |
| `conflict`  | A target file changed after the draft. Re-run Step 2 |
| `malformed` | Report the error. Do not fix files automatically     |

### Step 6: Report

Show the changed files, the finding counts per class, and the lint and test results returned by
the agent. If lint or tests fail, show the output and stop; do not change code to make them pass.

End with a note that the changes are not committed. Never run `git add` or `git commit`.

## Fallback

Where agents are not available, the main session runs the
[comment-refiner Role](../bdd-coder/references/roles/comment-refiner.md) itself, with the same
approval step between draft and apply.

## Reference

呼び出し例と使いどころは [usage.md](references/usage.md) にあります。
どの引数形式で呼ぶか迷ったときに読んでください。
