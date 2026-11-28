<!-- textlint-disable
  ja-technical-writing/sentence-length -->

# Session entry and resume

How the orchestrator saves and restores the work in progress.

## Session entry

The work in progress is the `bdd_coder` entry of `<local_dir>/session.json`. Stored paths start with `<local_dir>`.

```json
{
  "bdd_coder": {
    "tasklist": "<local_dir>/temp/tasklist/deckrd/libs/T-01.tasklist.md",
    "item": "L-02",
    "checklist": "<local_dir>/temp/tasks/parse-config-calm-checklist.md",
    "queue": null,
    "index": null,
    "status": "in-progress",
    "updated_at": "2026-11-09T00:00:00Z"
  }
}
```

| Field        | Value                                                                                                          |
| ------------ | -------------------------------------------------------------------------------------------------------------- |
| `tasklist`   | TASKLIST PATH, or `null` when Phase 1 used no task list                                                        |
| `item`       | Item selected in Phase 1a (in a multi-task run, the item being run), or `null` without a task list             |
| `checklist`  | CHECKLIST PATH, or `null` until Phase 1b returns it                                                            |
| `queue`      | Multi-task run only: the item IDs to run, in order (`["L-01","L-02","L-03"]`). `null` otherwise                |
| `index`      | Multi-task run only: the 0-based position in `queue` of the item being run. `null` otherwise                   |
| `status`     | `in-progress` from Phase 1 on; `done` when Phase 5 completes every case (every queue item in a multi-task run) |
| `updated_at` | UTC timestamp of the last write                                                                                |

Rules:

- Only the orchestrator reads or writes `bdd_coder`.
  tasklist-builder, checklist-builder, and the bdd-coder agent never see it.
- Replace the `bdd_coder` value as a whole, leave every other key untouched, and write through a temporary file:

  ```bash
  jq --arg tl "$TASKLIST" --arg item "$ITEM" --arg cl "$CHECKLIST" --arg st "$STATUS" \
     --argjson queue "$QUEUE" --argjson index "$INDEX" \
     --arg now "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
     'def nz: if . == "" then null else . end;
      .bdd_coder = {tasklist: ($tl | nz), item: ($item | nz), checklist: ($cl | nz),
                    queue: $queue, index: $index,
                    status: $st, updated_at: $now}' \
     <local_dir>/session.json > <local_dir>/session.json.tmp &&
    mv <local_dir>/session.json.tmp <local_dir>/session.json
  ```

  Pass an empty string for a `null` string field. Pass `null` for `QUEUE` and `INDEX` in a single-task run,
  and a JSON array (`'["L-01","L-02"]'`) and a number in a multi-task run. Do not use `select(. != "")` instead of `nz`:
  an empty value inside `{...}` makes jq output nothing, and the `mv` then empties `session.json`.
  `jaq` accepts the same filter.
- If `<local_dir>/session.json` does not exist, do not create it. Warn that the session cannot be
  saved (`/deckrd init` has not run) and continue without it.

| When                                    | Write                                                                                                             |
| --------------------------------------- | ----------------------------------------------------------------------------------------------------------------- |
| Phase 1a: an item is selected           | `tasklist`, `item`, `checklist: null`, `status: in-progress`                                                      |
| Phase 1b: CHECKLIST PATH is returned    | Keep `tasklist` / `item` (or `null`), set `checklist`, `status: in-progress`                                      |
| Phase 5 Step 4c: every case is complete | `status: done` (single-task run), or move to the next queue item (see [multi-task run](phases/multi-task-run.md)) |

A session that ends early (`BLOCKED`, abort) keeps `status: in-progress`, so it can be resumed.

## Resume

`--resume` continues the work recorded in `bdd_coder`:

| `bdd_coder` state                                         | Action                                                                      |
| --------------------------------------------------------- | --------------------------------------------------------------------------- |
| Missing, or `status: done`                                | Report "nothing to resume" and end the session (Phase 6)                    |
| `queue` set                                               | Continue the [multi-task run](phases/multi-task-run.md) from `queue[index]` |
| `checklist` set and the file exists                       | Use it as `--checklist`; restore TASKLIST PATH and the item                 |
| `checklist` is `null`, `tasklist` set and the file exists | Run as `--tasklist <tasklist> --item <item>`                                |
| A recorded file does not exist                            | Report the missing path and end the session. Do not rebuild it              |

A Target ID or `--tasklist` also restores the selected item. After Phase 1a (or after reading `--tasklist`),
select the recorded item without asking, and tell the user, if all of these hold:

- `bdd_coder.tasklist` equals TASKLIST PATH
- `status` is `in-progress`
- the recorded `item` is still `pending` in the task list
- `--item` is not given, or names the recorded `item` (an explicit `--item` always wins)

Run Phase 1b for the restored item even when the recorded checklist exists: tasks.md may have changed since
it was built. Only `--resume` reuses the checklist as is; if tasks.md has changed, run the Target ID instead.
