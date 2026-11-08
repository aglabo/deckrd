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

All paths below are relative to the deckrd skill directory unless they start with `<modulePath>` or `.local/`.

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
3. Assign the DR-ID (guideline E-2).
   - Collect every number from headings matching `## DR-<number>` and from the ID column of the `## Deleted Decision Records` table, if present. Ignore any other text (such as Change History descriptions).
   - New ID = max + 1, zero-padded to 2 digits (`DR-01`, `DR-02`, …). No file or no DR → `DR-01`.
4. Collect related IDs. List REQ / SPEC / DR IDs whose content the decision touches. If the decision replaces part of an existing DR, note that DR and the replaced scope as a Supersede candidate (E-1).
5. Verify facts (C-1). When the decision context makes claims about the code or the current behavior, confirm them by searching and reading the code. Use a semantic code search tool if one is available, otherwise plain text search. Mark anything that cannot be confirmed as unverified, or ask.
6. Draft the section by following the prompt with `DR_ID`, `PHASE`, `LANG`, and `TIMESTAMP` (current local time). If `feedback` is given, apply it to the previous draft.
7. Self-check against section 6 of the guideline, using the items whose timing is `draft` or `両方` (both). Treat `apply` items as not yet run, not as failures. Fix what you can. If a MUST item still fails because information is missing, produce the Questions block instead of a section.
8. Write the result to `.local/deckrd/temp/deckrd-work/dr-draft-<module>-<DR_ID>.md`, where `<module>` is `module_id` with `/` replaced by `-`. Put the draft section first. After it, add an HTML comment that records the Supersede candidate, if any, as `supersedes: DR-NN (scope)`.
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
2. Build the new file content in memory.
   - File does not exist: build the skeleton from the template. Frontmatter: `title: "Decision Records: <module_id>"`, `module`, `status: Active`, `version: 1.0.0`, `created: <today>`. Add the header blockquote, the DR section, and a Change History with exactly one row: `| <today> | 1.0.0 | Initial release with DR-01: <title> |`. Do not bump the version.
   - File exists: insert the DR section after the last DR section, immediately above `## Deleted Decision Records` if that section exists, otherwise immediately above `## Change History`. If there is no `## Change History`, stop and return `status: malformed` (do not create one silently). Then bump the version (see below) and add exactly one Change History row.
   - If frontmatter `module` differs from `module_id`, keep going but report a warning. Do not fix it.
3. Supersede: only if the approved draft has `**Supersedes**:` **and** its Status is `Accepted`. A `Proposed` DR never changes the old DR. In the replaced DR, change only its `**Status**:` line, following the formats in guideline E-1:
   - full replacement → `Superseded by <DR_ID>`
   - partial replacement → `Partially superseded by <DR_ID>（<scope>）`. If the line already lists earlier partial replacements, keep them and append the new one; when the last remaining decision is replaced, switch the prefix to `Superseded by` and keep all entries.

   Change nothing else in that DR. This is the only allowed edit to an existing DR section.
4. Version bump (existing file only), following the versioning rule:
   - New DR only, or a new `Proposed` DR → MINOR. Row: `Add <DR_ID>: <title>`
   - New `Accepted` DR that supersedes another → MAJOR. Row: `Add <DR_ID>: <title> (supersedes DR-NN)`
   - Frontmatter `version` MUST equal the new row's version.
5. Final check: run the `apply` and `両方` (both) items of the guideline's self-check list on the content built in memory (A-2, E-1, E-2, E-4). If one fails, return `status: malformed` with the reason and write nothing.
6. Write once. Write the whole new content in a single write. If any step failed, write nothing.
7. Delete the draft file after a successful write.
8. Return: `status: applied`, the file path, `dr_id`, old → new version, and warnings.

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
- Never touch `.local/deckrd/session.json`.
- Never create files in the module directory other than `decision-records.md`.
- Never write more than one DR per run.
- Do not commit. Git operations belong to the user.
