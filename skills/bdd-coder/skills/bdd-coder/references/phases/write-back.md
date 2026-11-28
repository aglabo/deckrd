<!-- textlint-disable
  ja-technical-writing/sentence-length -->

# Phase 5: Done Check and Write-back

Start only when every bdd-coder reported `DONE` / `DONE_WITH_CONCERNS` and Phase 4 passed.

## Step 1: Completion per Case

The source of truth is the **Phase 3 status report**, not any file's checkbox state:
nothing updates `tasks.md` before this phase, and a checklist can lag behind an interrupted run.

| Phase 3 status                 | Case result                 |
| ------------------------------ | --------------------------- |
| `DONE` / `DONE_WITH_CONCERNS`  | completed — check it        |
| `BLOCKED` / `SKIPPED` / absent | not completed — leave as is |

Checklist items (`[T-XX-YY-ZZ-R]`, `-G`, `-F`) may corroborate but MUST NOT override the report.

## Step 2: Case checkboxes in tasks.md (Task ID input only)

In `docs/.deckrd/<namespace>/<module>/tasks/tasks.md`:

1. Normalize each completed Case ID to `T-XX-YY-ZZ` and find `- [ ] **T-XX-YY-ZZ**: <description>`.
   An invocation-form ID (`T01-02`) names a Scenario: it covers every Case line under `T-01-02`.
2. Replace only the marker `- [ ]` with `- [x]`. Leave the description and the
   `Target` / `Scenario` / `Expected` lines untouched. A line already checked stays as is.
3. Report in Step 5 any completed Case that has no matching line.

## Step 3: Task Summary

Recalculate the Status column **only** for the Test Targets implemented in this invocation,
by counting their `**T-XX-YY-ZZ**` Case lines.

| Checked Cases | Status                                                            |
| ------------- | ----------------------------------------------------------------- |
| all           | `done`                                                            |
| some          | `in progress`                                                     |
| none          | leave unchanged (never regress an `in progress` row to `pending`) |

Change nothing else in `tasks.md`.

## Step 4: Checklist file (all inputs)

1. For every completed Case, confirm its `-R` / `-G` / `-F` items are `[x]`. Check any that were left,
   and list them in the Step 5 report.
2. Check the refactor gates here, not in bdd-coder (a split Target hides parts of a Scenario from each instance):
   - `[T-XX-YY-TF]` when every Case of the Scenario has `-R` / `-G` / `-F` checked
   - `[T-XX-CF]` when every Scenario of the Target has `-TF` checked
   - A gate that does not hold yet stays unchecked; that is not an error
3. Set the Test Target status: update the per-target status field if the file has one;
   otherwise add `<!-- status: done -->` or `<!-- status: in-progress -->` below the target heading.

## Step 4b: Task list (only when TASKLIST PATH was used)

1. If every Case of this invocation is completed, set the selected item to `- [x]` and `Status: done`.
   Do not touch other items.
2. Add `NEXT: <next pending item ID> → <Handoff>` (or `NEXT: none`) to the report, with
   `/bdd-coder:bdd-coder --tasklist <TASKLIST PATH>`.

## Step 4c: Session entry

If every Case of this invocation is completed, set `status: done` in the
[session entry](../session-resume.md#session-entry). Otherwise leave `in-progress` and add
`/bdd-coder:bdd-coder --resume` to the report.

In a [multi-task run](multi-task-run.md), "this invocation" means the current item. While later items remain
in `queue`, advance `index` and `item` instead; set `status: done` only after the last one.

## Step 5: Report

Output both blocks:

```text
STATUS WRITE-BACK (tasks.md):
  T-01-01-01  [x]
  T-01-01-02  [x]
  T-01: done        (2/2 cases checked)
  T-02: in progress (1/3 cases checked — 2 cases remain)
  T-03-01-01  not found in tasks.md — skipped

CHECKLIST BACKFILL:
  T-01-01-02-F  [x]  (left unchecked by the bdd-coder instance)
```
