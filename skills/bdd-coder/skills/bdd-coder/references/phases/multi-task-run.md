<!-- textlint-disable
  ja-technical-writing/sentence-length -->

# Multi-task run

Runs several Scenarios in one invocation, one after another. Each Scenario is still one task and one delegation.

| Form               | Pattern                              | Selects                                                                            |
| ------------------ | ------------------------------------ | ---------------------------------------------------------------------------------- |
| Range              | `^T-?[0-9]{2}-[0-9]{2}\.\.[0-9]{2}$` | Scenarios `YY` to `ZZ` of the Target (`T01-01..03` = `T01-01`, `T01-02`, `T01-03`) |
| All under a Target | `^T-?[0-9]{2}-\*$`                   | Every Scenario of the Target                                                       |

Quote `T01-*` in a shell so that it is not expanded as a glob.

## Resolve the selection (before any code is written)

1. Run [Phase 1a](tasklist-checklist.md#phase-1a-tasklist-build) with the Target ID (`T01`). It gives one item per Scenario.
2. Pick the items by `Handoff`, in Scenario number order. For `T01-*`, pick every item.
3. If any check fails, report it and end the session (Phase 6). Nothing runs.

   | Condition                                            | Error                                                                |
   | ---------------------------------------------------- | -------------------------------------------------------------------- |
   | End number is less than the start number             | Bad range: the end is before the start                               |
   | A Scenario in the range has no item in the task list | The Scenario does not exist in `tasks.md`                            |
   | A selected item is `needs-split` or `removed`        | Name the item; for `needs-split`, split the Case via `/deckrd tasks` |

4. Drop the `done` items and tell the user which ones were skipped.
   If no item is left, report "nothing to run" and end the session (Phase 6).
5. Write the [session entry](../session-resume.md#session-entry) with `queue` (remaining item IDs, in order),
   `index: 0`, and `item: queue[0]`.

## Run the queue

- Phase 0 runs once. For each item, run Phase 1b to Phase 5 as a full pass, with that item's `Handoff` only.
  Quality gate, code review, and write-backs belong to the item.
- An item is complete when every Case is `DONE` / `DONE_WITH_CONCERNS` and Phase 4 passed.
  Then advance `index` and `item`. After the last item, set `status: done` and end the session (Phase 6).
- **Fail-fast.** Stop at the first item that does not complete: a `BLOCKED` report, a failed quality gate,
  or an unfinished Case. Do not run the remaining items, and do not offer "skip":
  later Scenarios may depend on the failed one.
- Also stop before the next item when `git status --short` / `git diff --stat` shows files this item should not touch.
- On a stop, keep `status: in-progress`, `queue`, and `index`. Report the stopped item and its cause,
  the completed items, and the items not run. Tell the user to fix the cause and run
  `/bdd-coder:bdd-coder --resume`, which runs Phase 1b again from `queue[index]`.
- Never commit or push, not even between items. All changes stay in the working tree.
