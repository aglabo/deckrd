---
title: "Role: comment-refiner"
description: "Procedure for reviewing existing code comments against the comment guideline and rewriting them without changing any code. Canonical steps for the comment-refiner agent"
version: 1.0.0
---

## Role: comment-refiner

<!-- textlint-disable
  ja-technical-writing/sentence-length,
  ja-technical-writing/max-comma -->
<!-- markdownlint-disable line-length -->

This Role is the **canonical procedure** for refining existing code comments.

- In Claude Code, the `comment-refiner` agent (`agents/comment-refiner.md` at the plugin root) loads this Role and runs it in a sub-context.
- Where agents are not available, the main session follows this Role step by step itself.

All paths below are relative to the bdd-coder skill directory unless they start with `.local/` or are target file paths.

## Responsibility

Review the comments in the target files against the [comment guideline](../guidelines/code-comments.md), and delete, move, or rewrite them.
**Only comments may change. Code MUST NOT change**, not even whitespace inside code lines.

The Role does **not**: decide whether the user approves the draft, commit, or edit code or tests. The caller does those.

## Inputs

| Parameter    | Mode         | Description                                                                    |
| ------------ | ------------ | ------------------------------------------------------------------------------ |
| `mode`       | both         | `draft` or `apply`                                                             |
| `paths`      | draft        | Files, directories, or globs to review. Directories are searched recursively   |
| `answers`    | draft (redo) | User's answers to the `ask` questions of a previous run, keyed by finding ID   |
| `feedback`   | draft (redo) | User's correction requests for a previous draft, such as "keep F03" (optional) |
| `draft_file` | apply        | Path of the approved draft written by `draft`                                  |

## Mode: draft

1. Read the guideline: `references/guidelines/code-comments.md` (all sections).
2. Resolve the targets.
   - Expand `paths` to source files tracked by git (`git ls-files`), plus untracked files given by exact path.
   - Skip test fixtures, generated files (guideline section 4), vendored code, and files with no comments.
   - Detect each file's language and its comment syntax (line comments, block comments, doc comments). Language notes are in `assets/languages/<lang>.md` when present.
   - If no target remains, return `status: no-change`.
3. For each target file, collect the context needed to judge each comment.
   - The code each comment refers to (the next statement or block for C-2).
   - Callers of commented functions (`git grep -n <name>`) for C-4 and C-8.
   - Tests that name the behavior (search test directories for the function name) for C-10.
4. Review every comment in every target file, in file order, against rules C-1 to C-10 and section 3 (doc comments). Skip the protected comments of section 4.
   - Evaluate every rule for every comment. Do not stop at the first finding.
   - Give each finding an ID (`F01`, `F02`, … across the whole run), the rule ID, the file and line, and a quote of the comment. A finding without a quote is not recorded.
5. Classify each finding.

   | Class     | Meaning                                                                                       |
   | --------- | --------------------------------------------------------------------------------------------- |
   | `delete`  | Remove the comment (C-1, C-3, C-8, C-9, C-10, redundant doc lines)                            |
   | `move`    | Move the comment to the code it explains, or to the caller (C-2, C-4)                         |
   | `rewrite` | Change the wording, using only facts found in the code, tests, or other comments (C-5, C-6)   |
   | `ask`     | A fix needs a fact the agent cannot verify, such as the reason in C-7 or a fact change in C-6 |

   - Never invent a reason. When the "why" is not found in the code, tests, commit messages (`git log -L` / `git log -S`), or nearby docs, use `ask`.
   - A finding with a usable answer in `answers` becomes `rewrite`.
   - A finding excluded by `feedback` is reported as `excluded` and left untouched.
6. Build the refined text of each file in memory by applying `delete`, `move`, and `rewrite` findings only.
   - Keep the comment language of the file (do not translate) and its comment style (marker, indentation, doc-tag format).
   - When a deletion leaves a doc block with only its comment markers, remove the empty block. When it leaves two blank lines in a row where the file had one, keep one.
7. Check the invariant for each file: **every changed line, in both the original and the refined text, is a comment line or a blank line**.
   - A comment line is a line whose first non-blank characters start a comment in the file's language, or a line inside a block comment.
   - A trailing comment on a code line may change only if the code part before the comment marker is byte-identical.
   - If a file breaks the invariant, discard all changes to that file and report it as `invariant-failed` with the line.
8. Decide the status.
   - Any `ask` finding without an answer → `status: questions`. Still write the draft with the changes done so far.
   - No file changed → `status: no-change`. Do not write a draft.
   - Otherwise → `status: drafted`.
9. Write the draft to `.local/deckrd/temp/bdd-coder/comment-refine.md` in the format below.
10. Return a summary (at most 200 words): `status`, `draft_file`, changed files, finding counts per class, and the questions (with finding IDs) if `status` is `questions`.

Draft mode MUST NOT touch any target file or any file outside `.local/deckrd/temp/bdd-coder/`.

### Draft File Format

````markdown
# Comment Refine Draft

- created: <ISO 8601>
- files:
  - <path> sha256=<SHA-256 of the original file>

# <path> Findings

| ID  | Rule | Class  | Line | Quote                | Note              |
| --- | ---- | ------ | ---- | -------------------- | ----------------- |
| F01 | C-1  | delete | 12   | `# return the total` | restates the code |
| F02 | C-7  | ask    | 30   | `# not used from UI` | why is it kept?   |

# <path> Diff

```diff
<unified diff of the original and the refined text, 3 lines of context>
```

# EOF
````

Repeat the `Findings` and `Diff` blocks per changed file, in path order. List files with only `ask` findings too, with an empty diff.

## Mode: apply

Run only after the caller got the user's approval of `draft_file`.

1. Parse the draft. If `# EOF` is missing, or a file has a `Diff` block that is not a valid unified diff, return `status: malformed`.
2. Take a snapshot of every file in the draft: read its current content and compare its SHA-256 with the `sha256` in the draft. On any mismatch, stop and return `status: conflict`. Do not merge silently.
   - A matching hash means the snapshot is the draft-time content. Use the snapshot as the only base for the invariant check and for restoring files. Do not use `HEAD`: the target may have uncommitted code changes made before the draft.
3. Build every result before writing any file. For each file, apply its diff to the snapshot in memory, or to a copy under `.local/deckrd/temp/bdd-coder/`.
   - If a hunk does not apply, or a result breaks the invariant of draft step 7 against its snapshot, return `status: malformed` and write nothing.
4. Write all results to the target files. If a write fails, restore every file already written from its snapshot and return `status: malformed`.
5. Run the project's lint and test scripts for the changed files, through the project's scripts only (for example `pnpm run ...`). Never call the underlying tools directly. Report the results. Do not fix code to make them pass.
6. Delete the draft file after a successful apply.
7. Return: `status: applied`, the changed files, finding counts per class, and the lint and test results.

## Failure Handling

| Condition                                    | Action                                              |
| -------------------------------------------- | --------------------------------------------------- |
| No target file, or no comment to change      | `status: no-change`; no draft                       |
| An `ask` finding has no answer               | `status: questions`; partial draft is kept          |
| A file breaks the comment-only rule (draft)  | Discard that file; report it                        |
| File changed between draft and apply         | `status: conflict`; no write                        |
| Draft cannot be parsed, applied, or verified | `status: malformed`; no write                       |
| A write fails during apply                   | `status: malformed`; restore all files to snapshots |
| Lint or tests fail after apply               | Report the output; do not change code               |

## Constraints

- Never change code, tests, or configuration. Only comments.
- Never touch the protected comments of guideline section 4.
- Never invent reasons, history, or facts. Missing information becomes an `ask` question.
- Never add lint disable comments.
- Do not commit. Git operations belong to the user.
