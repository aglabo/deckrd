<!-- textlint-disable
  ja-technical-writing/sentence-length -->

# Phase 4: Quality Gate

Run the global gates, then the code review. All must pass before Phase 5.
Run each command now and read its full output; a remembered or summarized result does not count.

| Gate       | Must pass                                            |
| ---------- | ---------------------------------------------------- |
| Lint       | 0 errors                                             |
| Type check | 0 errors                                             |
| Tests      | ALL PASS (with coverage)                             |
| Review     | code-reviewer returns `PASS` or `PASS_WITH_WARNINGS` |

On failure, analyze, fix, and re-run. After 3 failures, ask the user instead of continuing.

## Code review

After the first three gates pass, spawn **code-reviewer** ([Role](../roles/code-reviewer.md)) **ONCE**:
one aggregate review over every file changed in Phase 3, not one per task.
In a [multi-task run](multi-task-run.md), run Phase 4 once per item, over that item's files.

| Input           | Value                                                                          |
| --------------- | ------------------------------------------------------------------------------ |
| `skill_dir`     | This skill directory (absolute path)                                           |
| `local_dir`     | `DECKRD_LOCAL_DATA` (absolute path)                                            |
| `task_id`       | The Task ID of this invocation, or `N/A` for multiple tasks                    |
| `changed_files` | Implementation files from the session scope                                    |
| `test_files`    | Test files from that same scope, split by the ENV PROFILE test-file convention |
| `env_profile`   | `<local_dir>/temp/deckrd-work/env-profile.md`                                  |
| `coverage_cmd`  | Coverage command from ENV PROFILE                                              |

CRAP thresholds are defined in the Role. The per-task CRAP gate in [implementer.md](../roles/implementer.md)
and this aggregate one are intentionally separate; do not remove either as a duplicate.

## Session scope

Resolve in this order:

1. The union of the `CHANGED_FILES` lists that Phase 3 collected.
2. Only if those lists are unavailable: every working-tree change minus the SESSION BASELINE of Phase 0.
   "Every working-tree change" is `git diff --name-only`, `git diff --name-only --cached`, and
   `git ls-files --others --exclude-standard`, merged and deduplicated (the third lists new files).
   Keep deleted paths.

Never send the raw working-tree diff: unrelated edits of the user would be reviewed and could block the session.

## Verdict

| Verdict              | Handling                                                                                                                               |
| -------------------- | -------------------------------------------------------------------------------------------------------------------------------------- |
| `PASS`               | Proceed to Phase 5                                                                                                                     |
| `PASS_WITH_WARNINGS` | Proceed and include the findings in the Phase 5 report. Do NOT rewrite Phase 3 statuses or `tasks.md` checkboxes                       |
| `BLOCKED`            | Do NOT proceed. Present the CRITICAL findings and follow the Phase 3 [`BLOCKED`](dispatch.md#blocked) handling. Reduce CC or add tests |
