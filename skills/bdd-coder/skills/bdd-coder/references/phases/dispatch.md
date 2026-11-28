<!-- textlint-disable
  ja-technical-writing/sentence-length,
  ja-technical-writing/max-comma -->

# Phase 3: bdd-coder Dispatch

**The dispatch unit is a Target (`T-XX`).** Spawn one bdd-coder ([Role](../roles/implementer.md)) per Target.
It runs every Case of the Target in order, and each Case keeps its own RED → GREEN → REFACTOR cycle.
Do not spawn per Case: tokens and time grow with the number of Cases.

Follow the Phase 2 groups. Targets whose write sets do not overlap may run in parallel.

## Splitting a large Target

Split only when one of these holds:

| Condition        | Threshold                                                                                                       |
| ---------------- | --------------------------------------------------------------------------------------------------------------- |
| Number of Cases  | 30 or more in one Target                                                                                        |
| Context size     | Target files plus checklist near half the context window                                                        |
| Repeated failure | 3 or more quality gate failures caused by the size (`NEEDS_CONTEXT`; if splitting cannot help, it is `BLOCKED`) |

- Split at a Case boundary, Scenario first. Split inside a Scenario only when it is large.
- Parts change the same files: run them one after another. They share one `progress_path`.
- Run `-TF` / `-CF` and the Target regression in the last part, or in Phase 5.
- Each part reports `CASES: <first>..<last>`. Check that no Case is missing.

## Context to pass

| Item              | Content                                                                          |
| ----------------- | -------------------------------------------------------------------------------- |
| `skill_dir`       | This skill directory (absolute path)                                             |
| `local_dir`       | `DECKRD_LOCAL_DATA` (absolute path)                                              |
| Target ID         | e.g. `T-01` (plus a Case range when the Target is split)                         |
| Task description  | Full Given/When/Then of the Target's Cases from the checklist                    |
| Quality gate cmds | Commands table from ENV PROFILE                                                  |
| Checklist path    | CHECKLIST PATH                                                                   |
| `progress_path`   | `<local_dir>/temp/bdd-coder/<scope>/<Target ID>/bdd-todo.md` (one per Target)    |
| Prior state       | Split parts only: one-line summary of files changed so far. No earlier Case logs |

`<scope>` is the `<ns>/<module>` directory of the task list under `<local_dir>/temp/tasklist/`;
for a task list with no module it is the task list's file name without `.tasklist.md`.

Do NOT pass session-wide context, other Targets' information, Case logs of finished Cases, or session.json.
"1 delegation = 1 task" (`docs/.deckrd/rules/deckrd-rule-bdd-cycle.md`) holds with the Target as the task:
the checklist handed over contains that Target only.

## After each Target

- Verify the changed files with `git status --short` / `git diff --stat`, not from the self-report.
- Record Status, Cases (done/total), `REGRESSION`, `CHANGED_FILES`, and notes.
  Copy `CHANGED_FILES` as reported and never leave it empty: it defines the Phase 4 review scope.
- Per-Case results stay in the `## Case Log` table of `progress_path`.

## `DONE_WITH_CONCERNS`

Show the concerns to the user, repeat them after Phase 4, and let the user decide whether to continue.

## `BLOCKED`

1. Record the Targets of the current group that finished.
2. Report the exact CRITICAL findings and the affected task ID.
3. In a [multi-task run](multi-task-run.md), stop here, keep the session entry, and tell the user to run `--resume`.
   Otherwise wait for the user to choose:
   - Fix and retry: re-run Phases 3 to 6 for the same task with the user's guidance.
   - Skip task: mark it `SKIPPED` and continue with the next task.
   - Abort session: stop and summarize the open blockers.

Do NOT proceed to the next task while any task remains `BLOCKED`.
