<!-- textlint-disable
  ja-technical-writing/sentence-length,
  ja-technical-writing/max-comma -->

# Phase 1: Tasklist Resolve and Checklist Build

Pick exactly one task and get its checklist. Read [session-resume.md](../session-resume.md)
before you write the session entry, handle `--resume`, or restore a selected item.

## Input routing

| Input                             | Phase 1a: tasklist-builder   | Phase 1b: checklist-builder input                                    |
| --------------------------------- | ---------------------------- | -------------------------------------------------------------------- |
| Natural-language                  | Run                          | `Handoff` of the selected item                                       |
| Target ID (`T01`)                 | Run                          | `Handoff` of the selected item (`T01-02`)                            |
| Range (`T01-01..03`)              | Run with the Target ID `T01` | `Handoff` of each item in the range, in order                        |
| All under a Target (`T01-*`)      | Run with the Target ID `T01` | `Handoff` of each `pending` item, in order                           |
| Scenario ID (`T01-02`)            | Skip                         | The Task ID as given                                                 |
| `--tasklist <path> [--item L-02]` | Skip                         | `Handoff` of the given item, or first `pending`                      |
| `--checklist <path>`              | Skip                         | Skip checklist-builder; use the file                                 |
| `--resume`                        | Skip                         | Restored from `session.json` ([Resume](../session-resume.md#resume)) |

For a range or `T01-*`, follow [multi-task-run.md](multi-task-run.md).

## Phase 1a: Tasklist Build

Spawn **tasklist-builder** ([Role](../roles/tasklist-builder.md)) with `skill_dir`, `local_dir`,
`instruction`, and `tasks_md` for a Target ID.
Task lists stay under `<local_dir>/temp`; do not pass a `DECKRD_LOCAL_TEMP` override to the Role.

| Returned status                  | Handling                                                         |
| -------------------------------- | ---------------------------------------------------------------- |
| `questions`                      | Ask the user the returned question, then re-run with `answers`   |
| `invalid-input`                  | Report `DETAIL` to the user and end the session (Phase 6)        |
| `created` / `reused` / `updated` | Select one item, and keep the returned path as **TASKLIST PATH** |

Select the item:

- Exactly one `pending` item: use it without asking.
- Two or more `pending` items: show the list (ID / Title / Status) and ask which one to run.
  Default: the first `pending` item whose `Depends-on` items are all `done`.
- `needs-split`, `done`, and `removed` items cannot be selected. For `needs-split`, tell the user to split
  the Case in tasks.md via `/deckrd tasks`, then run the same Target ID again.
- On `updated`, show the `CHANGED` line before selecting.
- No `pending` item: report it and end the session (Phase 6).

Then write the [session entry](../session-resume.md#session-entry).

Pass **only the selected item's `Handoff`** to Phase 1b. Never pass the task list file to checklist-builder
or bdd-coder: it lists other tasks, which breaks "1 delegation = 1 task"
(`docs/.deckrd/rules/deckrd-rule-bdd-cycle.md`). "Pass the list and say to do only `L-02`" breaks it too.

## Phase 1b: Checklist Build

Spawn **checklist-builder** ([Role](../roles/checklist-builder.md)) with `skill_dir`, `local_dir`, the routed input,
`tasks_md` for a Task ID, and `directory` (repository root).
It writes `<local_dir>/temp/tasks/<slug>-<adjective>-checklist.md`.

When the path is returned (or given by `--checklist`), keep it as **CHECKLIST PATH**
and write the [session entry](../session-resume.md#session-entry).

If checklist-builder reports `BLOCKED` (a Case lists more than one input), no checklist exists:

1. Report the `BLOCKED` line verbatim, with the remedy: split the Case via `/deckrd tasks`,
   then re-run bdd-coder with the Task ID.
2. End the session (Phase 6). Do NOT expand the inputs yourself or fall back to a natural-language checklist.
