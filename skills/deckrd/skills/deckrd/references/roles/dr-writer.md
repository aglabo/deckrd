---
title: "Role: dr-writer"
description: "Procedure for drafting and appending one Decision Record. Canonical steps for /deckrd dr --add"
version: 1.0.0
---

## Role: dr-writer

<!-- textlint-disable
  ja-technical-writing/sentence-length,
  ja-technical-writing/max-comma -->
<!-- markdownlint-disable line-length -->

This Role is the **canonical procedure** for writing a Decision Record (DR).

- In Claude Code, the `dr-writer` agent (`agents/dr-writer.md` at the plugin root) loads this Role and runs it in a sub-context.
- Where agents are not available, the main session follows this Role step by step itself.

Paths are resolved as follows:

- Bundled resources (`assets/`, `references/`) are relative to the deckrd skill directory.
- Everything else is relative to the project root and stays under it: project files, `<modulePath>` (`docs/.deckrd/<namespace>/<module>`), `.local/...`, and paths given by the caller. The skill may be installed outside the project, so never resolve these against the skill directory.

## Responsibility

Turn one decision that the user explicitly asked to record into one DR section that
satisfies the [DR authoring guideline](../guidelines/decision-record-authoring.md),
and append it to `<modulePath>/decision-records.md` without breaking the append-only rule.

The Role does **not**: check the session or the current step, ask the tasks-step
confirmation, or decide whether the user approves the draft. The caller
([dr command](../commands/dr.md)) does that.

## Inputs

| Parameter          | Mode         | Description                                                                                                                        |
| ------------------ | ------------ | ---------------------------------------------------------------------------------------------------------------------------------- |
| `mode`             | both         | `draft` or `apply`                                                                                                                 |
| `module_id`        | both         | `<namespace>/<module>` (the caller reads it from the session)                                                                      |
| `module_path`      | both         | `docs/.deckrd/<namespace>/<module>` (`session.modules[active].path`)                                                               |
| `phase`            | draft        | `req` / `spec` / `impl` / `tasks` (`current_step`)                                                                                 |
| `lang`             | draft        | `system` / `en` / `ja` / other. Default: language of existing DRs, else `system`                                                   |
| `decision_context` | draft        | The decision the user stated: what was decided, why, alternatives, related IDs. Never a summary of the whole chat made on your own |
| `feedback`         | draft (redo) | User's correction requests for a previous draft (optional)                                                                         |
| `draft_file`       | apply        | Path of the approved draft written by `draft`                                                                                      |

## Mode: draft

1. Read the sources.
   - `references/guidelines/decision-record-authoring.md`
   - `assets/templates/decision-record.template.md`
   - `assets/prompts/decision-record.prompt.md`
2. Read the module documents.
   - `<module_path>/decision-records.md` if it exists
   - every `.md` file under `<module_path>/requirements/` and `<module_path>/specifications/` (aggregate files such as `requirements.md` and split `req-NNN-*.md` files alike), if the directories exist
   - the project's document lint settings (markdownlint and textlint configuration files, wherever the project keeps them), to learn the limits on sentence length, line length, and style (guideline F-4)
3. Assign the DR-ID (guideline E-2).
   - Collect every number from headings matching `## DR-<number>` and from the ID column of the `## Deleted Decision Records` table, if present. Ignore any other text (such as Change History descriptions).
   - New ID = max + 1, zero-padded to 2 digits (`DR-01`, `DR-02`, …). No file or no DR → `DR-01`.
4. Collect related IDs (guideline E-3). List REQ / SPEC / DR IDs whose content the decision touches, each with the file that defines it (relative to the module directory). Add the GitHub Issues and PRs that `decision_context` names as the origin of the decision. If the decision replaces part of an existing DR, note that DR and the replaced scope as a Supersede candidate (E-1).
5. Verify facts (C-1, E-5). When the decision context makes claims about the code or the current behavior, confirm them by searching and reading the code. Read every REQ / SPEC passage the draft will refer to, and make sure the draft's targets, scopes, and numbers match them; ask the user when they conflict. Use a semantic code search tool if one is available, otherwise plain text search. Mark anything that cannot be confirmed as unverified, or ask.
6. Draft the section by following the prompt with `DR_ID`, `PHASE`, `LANG`, and `TIMESTAMP` (current local time). If `feedback` is given, apply it to the previous draft.
7. Self-check against section 6 of the guideline, using the items whose timing is `draft` or `両方` (both). Treat `apply` items as not yet run, not as failures. Fix what you can.
   - Evaluate **every** such row, in table order. Do not stop at the first failure.
   - For each item that still fails, quote the sentence or line that triggers it in the summary. A failure without a quote is not reported. This keeps the result the same from run to run. If a MUST item still fails because information is missing, produce the Questions block instead of a section.
8. Write the result to `.local/deckrd/temp/deckrd-work/dr-draft-<module>-<DR_ID>.md`, where `<module>` is `module_id` with `/` replaced by `-`, in the [Draft File Format](../commands/dr.md#draft-file-format) exactly: the metadata list (`dr_id`, and `supersedes: DR-NN (scope)` if there is a Supersede candidate), then a `# <DR_ID> Draft` block with the section, then `# EOF`. Do not lint the draft file or a merged copy, and never call the underlying lint tools directly (the project's scripts may exclude `.local/`; that is not a reason to bypass them). Lint errors are caught and fixed in apply step 7.
9. Return a summary (at most 200 words):
   - `status`: `drafted` or `questions`
   - `draft_file`, `dr_id`, `title`
   - self-check result: MUST failures (should be none), SHOULD items not met with reasons
   - Supersede candidate, if any
   - questions for the user, if `status` is `questions`

Draft mode MUST NOT touch `decision-records.md` or any file outside `.local/deckrd/temp/deckrd-work/`.

## Mode: apply

Run only after the caller got the user's approval of `draft_file`.

1. Re-check the ID. Re-read `decision-records.md` and recompute max + 1. If it differs from the draft's ID (the file changed meanwhile), stop and return `status: id-conflict`. Do not renumber silently.
   - Parse the draft by the [Draft File Format](../commands/dr.md#draft-file-format) rules only. If `# EOF` is missing, or the `# <DR_ID> Draft` block does not hold exactly one `## <DR_ID>:` section, return `status: malformed`. The section to insert is the content of that block.
2. Build the new file content in memory.
   - File does not exist: build the skeleton from the template. Frontmatter: `title: "Decision Records: <module_id>"`, `module`, `status: Active`, `version: 1.0.0`, `created: <today>`. Add the header blockquote, the DR section, and a Change History with exactly one row: `| <today> | 1.0.0 | Initial release with DR-01: <title> |`. Do not bump the version.
   - File exists: insert the DR section after the last DR section, immediately above `## Deleted Decision Records` if that section exists, otherwise immediately above `## Change History`. If there is no `## Change History`, stop and return `status: malformed` (do not create one silently). If the last DR section does not end with `---`, add it there (A-3). Then bump the version (see below) and add exactly one Change History row.
   - If frontmatter `module` differs from `module_id`, keep going but report a warning. Do not fix it.
3. Supersede: only if the approved draft has `**Supersedes**:` **and** its Status is `Accepted`. A `Proposed` DR never changes the old DR. In the replaced DR, change only its `**Status**:` line, following the formats in guideline E-1:
   - full replacement → `Superseded by <DR_ID>`
   - partial replacement → `Partially superseded by <DR_ID>（<scope>）`. If the line already lists earlier partial replacements, keep them and append the new one; when the last remaining decision is replaced, switch the prefix to `Superseded by` and keep all entries.

   Change nothing else in that DR. This is the only allowed edit to an existing DR section.
4. Version bump (existing file only), following the versioning rule:
   - First apply "One bump per commit" in [dr command: Version Bump](../commands/dr.md#version-bump). If a bump is pending, or the file is not committed yet, merge into that row instead of adding the rows below.
   - New DR only, or a new `Proposed` DR → MINOR. Row: `Add <DR_ID>: <title>`
   - New `Accepted` DR that supersedes another → MAJOR. Row: `Add <DR_ID>: <title> (supersedes DR-NN)`
   - Frontmatter `version` MUST equal the new row's version.
5. Final check: run the `apply` and `両方` (both) items of the guideline's self-check list on the content built in memory (A-2, E-1, E-2, E-4). If one fails, return `status: malformed` with the reason and write nothing.
   - E-2 is checked against the **pre-append** state. Compare `<DR_ID>` with the max + 1 computed in step 1 from the file before the insert (`DR-01` when the file did not exist). Do not recompute the max from the in-memory content: it already contains `<DR_ID>`, so max + 1 would never match.
   - In the in-memory content, `<DR_ID>` MUST appear exactly once as a `## DR-<number>` heading (the new section) and MUST NOT appear in the `## Deleted Decision Records` table.
6. Write once. Write the whole new content in a single write. If any step failed, write nothing.
7. Format and lint (guideline F-4). Follow [dr command: Format and Lint](../commands/dr.md#format-and-lint). The range this run wrote is the new DR section and the new Change History row (and the Status line of a superseded DR, if any).
8. Delete the draft file after a successful write.
9. Return: `status: applied`, the file path, `dr_id`, old → new version, the format and lint result (with each lint fix shown as before → after), and warnings.

## Failure Handling

| Condition                                | Action                                    |
| ---------------------------------------- | ----------------------------------------- |
| Missing information for a MUST rule      | `status: questions`; no draft section     |
| `decision_context` is empty              | `status: questions`; ask what was decided |
| ID changed between draft and apply       | `status: id-conflict`; no write           |
| Existing file has no `## Change History` | `status: malformed`; no write             |
| Frontmatter `module` mismatch            | Warning only; proceed                     |

## Constraints

- Never edit the body of an existing DR. Only the Status line of a superseded DR may change.
- After the single write, the only further edits are those of the formatter and the lint fixes inside the range this run wrote.
- Never add lint disable comments to `decision-records.md`.
- Never touch `.local/deckrd/session.json`.
- Never create files in the module directory other than `decision-records.md`.
- Never write more than one DR per run.
- Do not commit. Git operations belong to the user.
