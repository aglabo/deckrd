---
title: "Role: dr-refiner"
description: "Procedure for reviewing existing Decision Records and rewriting them for readability without changing what was decided. Canonical steps for /deckrd dr --refine"
version: 1.0.0
---

## Role: dr-refiner

<!-- textlint-disable
  ja-technical-writing/sentence-length,
  ja-technical-writing/max-comma -->
<!-- markdownlint-disable line-length -->

This Role is the **canonical procedure** for refining existing Decision Records (DR).

- In Claude Code, the `dr-refiner` agent (`agents/dr-refiner.md` at the plugin root) loads this Role and runs it in a sub-context.
- Where agents are not available, the main session follows this Role step by step itself.

Paths are resolved as follows:

- Bundled resources (`assets/`, `references/`) are relative to `skill_dir`, the deckrd skill directory passed by the caller.
- Everything else is relative to the project root and stays under it: project files, `<modulePath>` (`docs/.deckrd/<namespace>/<module>`), and paths given by the caller. The skill may be installed outside the project, so never resolve these against the skill directory.
- Local data is under `local_dir`, an absolute path passed by the caller. Write `<local_dir>/session.json` and `<local_dir>/temp/...`, never a literal `.local/deckrd`. `temp` is always `<local_dir>/temp`.

## Responsibility

Review the target DRs in `<modulePath>/decision-records.md` against the
[DR authoring guideline](../guidelines/decision-record-authoring.md), and rewrite them so that a
reader who was not part of the decision can follow them. **What was decided MUST NOT change.**
Section 7 of the guideline (the refine rules) defines what may and may not change; this Role does not restate it.

The Role does **not**: check the session, validate the DR-IDs given on the command line,
or decide whether the user approves the result. The caller ([dr command](../commands/dr.md)) does that.

## Inputs

| Parameter     | Mode         | Description                                                                              |
| ------------- | ------------ | ---------------------------------------------------------------------------------------- |
| `skill_dir`   | both         | Absolute path of the skill directory (where `SKILL.md` is)                               |
| `local_dir`   | both         | Absolute path of the deckrd local data (`DECKRD_LOCAL_DATA`)                             |
| `mode`        | both         | `draft` or `apply`                                                                       |
| `module_id`   | both         | `<namespace>/<module>` (the caller reads it from the session)                            |
| `module_path` | both         | `docs/.deckrd/<namespace>/<module>` (`session.modules[active].path`)                     |
| `targets`     | draft        | DR-IDs to refine (already validated by the caller). Empty = every DR section in the file |
| `lang`        | draft        | `system` / `en` / `ja` / other. Default: language of existing DRs                        |
| `answers`     | draft (redo) | User's answers to the `ask` questions of a previous run, keyed by DR-ID and rule ID      |
| `feedback`    | draft (redo) | User's correction requests for a previous draft, such as "exclude DR-03" (optional)      |
| `draft_file`  | apply        | Path of the approved draft written by `draft`                                            |

## Mode: draft

1. Read the sources.
   - `references/guidelines/decision-record-authoring.md` (sections 4, 6, and 7 in particular)
   - `assets/templates/decision-record.template.md`
2. Read the module documents.
   - `<module_path>/decision-records.md`
   - every `.md` file under `<module_path>/requirements/` and `<module_path>/specifications/`, if the directories exist (for term consistency, F-3, to resolve references, B-2, and to find the file that defines each Related ID, E-3)
   - the project's document lint settings (markdownlint and textlint configuration files, wherever the project keeps them), to learn the limits on sentence length, line length, and style (F-4)
3. Review each target DR. Run the self-check items of guideline section 6 whose timing is `draft` or `両方` (both), including the readability rules H-1 to H-4 and the Related format of E-3. Record every finding with its rule ID.
   - Evaluate **every** such row for **every** target DR, in table order. Do not stop at the first finding in a DR, and do not skip a row because an earlier run did not flag it.
   - For each finding, quote the sentence or line that triggers it in the Note column. A finding without a quote is not recorded. This keeps the result the same from run to run.
   - E-5 and C-4: open every REQ / SPEC passage the DR refers to (by ID or section) and compare the targets, scopes, and numbers. Quote both sides in the Note: the DR sentence and the passage it conflicts with.
   - C-5: compare each item list in Decision with the lists in the other subsections that name the same targets (Consequences in particular).
   - File-level checks (guideline 7.4): compare `based-on` in the frontmatter with the latest version of the upstream document (E-6). Report a mismatch in the summary; do not change `based-on`.
   - Also run the project's document linters on `decision-records.md` as it is now (read-only; find the commands as described in [dr command: Format and Lint](../commands/dr.md#format-and-lint)). Record each lint error inside a target DR as an F-4 finding. If no linter is defined, skip this and note it in the summary.
   - Lint only `decision-records.md` itself, and only through the project's scripts. Never lint the draft file or a merged copy, and never call the underlying tools directly (the project's scripts may exclude `.local/`; that is not a reason to bypass them). Lint errors in the refined text are caught and fixed in apply step 6.
4. Classify each finding as `rewrite`, `ask`, or `supersede` (guideline 7.3). When unsure, choose `supersede`.
   - A finding listed in `answers` with a usable answer becomes `rewrite` (a supplement under guideline 7.2).
   - A DR excluded by `feedback` is left untouched and reported as `excluded`.
5. Rewrite. For each target DR with at least one `rewrite` finding, build the refined section by applying only those findings. Keep the language and the style (敬体／常体) of the file (F-1). If `feedback` is given, apply it to the previous draft.
   - Stay within the lint limits read in step 2 (F-4). When a definition or a reference makes a sentence too long, split the sentence or move the item into a list. Never add lint disable comments.
6. Check invariants. For each refined section, extract the items R-1 to R-7 of guideline 7.1 from the original and the refined text and compare them.
   - R-1, R-2, R-6: compare as exact strings.
   - R-3, R-4, R-7: compare the sets (decision numbers, alternative entries, open questions), then confirm that each decision states the same thing.
   - R-5: every ID in the original Related MUST still be there. Added entries are allowed only as listed in guideline 7.2 (file names in front of IDs, Issue / PR numbers found in that DR or in Change History rows that name it, answers).
   - If any item differs, discard the rewrite of that DR, keep the original, and turn the finding that caused it into `supersede`.
7. Decide the status.
   - Any `ask` finding without an answer → `status: questions`. Still write the draft file with the rewrites done so far, so the next run can build on it.
   - No refined section (every target unchanged, excluded, or `supersede` only) → `status: no-change`. Do not write a draft file.
   - Otherwise → `status: drafted`.
8. Write the draft to `<local_dir>/temp/deckrd-work/dr-refine-<module>.md`, where `<module>` is `module_id` with `/` replaced by `-`, in the [Draft File Format](../commands/dr.md#draft-file-format) exactly.
   - Metadata list:
     - `base_version`: frontmatter version of `decision-records.md`
     - `targets`: the refined DRs only
     - `original_sha256`: per refined DR, the SHA-256 of the original section text (from its `## DR-NN` heading up to, not including, the next level-2 heading)
     - `supplements`: per DR that received content from `answers` (guideline 7.2). Omit the line when nothing was supplemented. Apply mode uses it to word the Change History row
   - Per refined DR, in file order: a `# DR-NN Findings` block with the table `| Rule | Class | Note |` (one row per finding, including `ask` and `supersede`), then a `# DR-NN Refined` block with the refined section
9. Return a summary (at most 200 words):
   - `status`: `drafted`, `questions`, or `no-change`
   - `draft_file` (if written)
   - refined DRs, unchanged DRs, excluded DRs
   - `supersede` findings per DR (rule ID and one-line reason), to hand to `/deckrd dr --add`
   - questions for the user, if `status` is `questions`, each tagged with DR-ID and rule ID
   - file-level findings (E-6 `based-on` mismatch)

Draft mode MUST NOT touch `decision-records.md` or any file outside `<local_dir>/temp/deckrd-work/`.

## Mode: apply

Run only after the caller got the user's approval of `draft_file`.

1. Re-check the base. Re-read `decision-records.md`. If its frontmatter `version` differs from `base_version`, or the SHA-256 of any target section differs from `original_sha256`, stop and return `status: conflict`. Do not merge silently.
   - Parse the draft by the [Draft File Format](../commands/dr.md#draft-file-format) rules only. If `# EOF` is missing, or a `# DR-NN Refined` block does not hold exactly one `## DR-NN:` section, return `status: malformed`.
2. Build the new file content in memory. Replace each target section (from its `## DR-NN` heading up to, not including, the next level-2 heading) with the content of its `# DR-NN Refined` block. Never copy a `Findings` block. Leave every other byte unchanged: other DRs, `## Deleted Decision Records`, and the header blockquote.
3. Version bump: PATCH, once per run, regardless of how many DRs were refined (versioning rule; guideline E-4).
   - First apply "One bump per commit" in [dr command: Version Bump](../commands/dr.md#version-bump). If a bump is pending, merge into it instead of adding the row below.
   - Add exactly one Change History row: `| <today> | <new version> | Refine DR-NN[, DR-NN]: clarify wording |`. List the refined DR-IDs in file order.
   - If the draft has `supplements:` lines, write `clarify wording and supplement <what>` instead of `clarify wording`, built from those lines (for example, `supplement DR-02 rejection reason for the deny-list alternative`). Without `supplements:` lines, never write `supplement`.
   - Frontmatter `version` MUST equal the new row's version.
   - Do not realign the table columns by hand. The formatter in step 6 does it.
4. Final check on the content built in memory. If one fails, return `status: malformed` with the reason and write nothing.
   - R-1 to R-7 (guideline 7.1) hold between the file read in step 1 and the new content, for every DR.
   - Sections other than the targets and the frontmatter (except `version`) are byte-identical.
   - Change History rows that are in the committed file (`git show HEAD:<path>`) are byte-identical. Rows after the committed last row are a pending bump; step 3 may replace them with its single merged row. If git is not available or the file is not tracked, every row that existed before is byte-identical.
   - E-4: frontmatter `version` equals the last Change History row.
5. Write once. Write the whole new content in a single write. If any step failed, write nothing.
6. Format and lint (guideline F-4). Follow [dr command: Format and Lint](../commands/dr.md#format-and-lint). The range this run wrote is the target DR sections and the new Change History row. After any lint fix, check R-1 to R-7 again for the fixed DR; a fix that would break one is not made, and the error is reported instead.
7. Delete the draft file after a successful write.
8. Return: `status: applied`, the file path, refined DR-IDs, old → new version, the format and lint result (with each lint fix shown as before → after), and warnings.

## Failure Handling

| Condition                                  | Action                                         |
| ------------------------------------------ | ---------------------------------------------- |
| `decision-records.md` does not exist       | `status: malformed`; nothing to refine         |
| An `ask` finding has no answer             | `status: questions`; partial draft is kept     |
| A rewrite breaks an invariant (R-1 to R-7) | Discard that rewrite; report it as `supersede` |
| Nothing to rewrite                         | `status: no-change`; no draft, no write        |
| File changed between draft and apply       | `status: conflict`; no write                   |
| Existing file has no `## Change History`   | `status: malformed`; no write                  |
| Final check fails                          | `status: malformed`; no write                  |

## Constraints

- Never change what was decided. Never change a `**Phase**`, `**Status**`, or `**Supersedes**` line.
- Never add, delete, renumber, or reorder DR sections.
- Never invent rationale, alternatives, scope, or evidence. Missing information becomes an `ask` question.
- After the single write, the only further edits are those of the formatter and the lint fixes inside the range this run wrote.
- Never add lint disable comments to `decision-records.md`.
- Never touch `<local_dir>/session.json`.
- Never create files in the module directory other than `decision-records.md`.
- Do not commit. Git operations belong to the user.
