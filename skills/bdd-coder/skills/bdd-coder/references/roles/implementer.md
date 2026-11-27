---
title: "Role: implementer"
description: "Procedure for strict BDD implementation of a single task: Red-Green-Refactor per assertion, append-first test grouping, quality gates. Canonical steps for the bdd-coder agent"
version: 1.0.0
---

## Role: implementer

<!-- textlint-disable
  ja-technical-writing/no-exclamation-question-mark,
  ja-technical-writing/sentence-length -->
<!-- markdownlint-disable line-length -->

This Role is the **canonical procedure** for implementing one checklist task. It is language-agnostic.

The unit of one invocation is a **Target** (`T-XX`): the caller hands over one Target with all its Scenarios and Cases.
Every Case still runs its own RED → GREEN → REFACTOR cycle. Cases are never merged into one cycle.
A caller may hand over part of a Target only when it splits the Target at a Case boundary (see [Target Splitting](#target-splitting)).

- In Claude Code, the `bdd-coder` agent (`agents/bdd-coder.md` at the plugin root) loads this Role and runs it in a sub-context.
- Where agents are not available, the main session follows this Role step by step itself.

Paths are resolved as follows:

- Bundled resources (`assets/`, `references/`) are relative to `skill_dir`, the bdd-coder skill directory passed by the caller.
- Everything else is relative to the project root and stays under it: project files, `docs/...`, and paths given by the caller. The skill may be installed outside the project, so never resolve these against the skill directory.
- Local data is under `local_dir`, an absolute path passed by the caller. Write `<local_dir>/session.json` and `<local_dir>/temp/...`, never a literal `.local/deckrd`. `temp` is always `<local_dir>/temp`.

Progress is tracked in `bdd-todo.md` at `progress_path`, passed by the caller as
`<local_dir>/temp/bdd-coder/<scope>/<Target ID>/bdd-todo.md` (see Core Principles).
`<scope>` is the module (`<ns>/<module>`) of the task list, or the task list's file name when it has no module,
so `T-01` of one module never shares a file with `T-01` of another.
Never use a path shared with another Target: bdd-coder instances may run in parallel.

## Core Principles

1. 1 invocation = 1 Target, 1 RGR cycle per Case — Phase 2 splits the Target into Cases and assertions.
   Each goes through its own RED-GREEN-REFACTOR cycle. Setup (role file, checklist, ENV PROFILE and target files)
   is read once per invocation, not once per Case.

2. `bdd-todo.md` at `progress_path` is the single source of truth — created in Phase 2,
   updated at every step. Resume capability depends entirely on this file.
   Every progress update writes BOTH the `state:` word and the checkbox marker;
   a `state: done` item left as `- [ ]` is an incomplete update.

3. Strict RED → GREEN → REFACTOR → next assertion — no skipping, no parallelization.

4. Append-first — 2nd+ assertions in the same Given/When context MUST append to the
   existing test block (via `it.each` or additional expects), not create a new one.
   Exception: new block only if Given/When differs, intent changes, or naming breaks.

5. Language-agnostic auto-detection — Phase 1 detects framework, language, toolchain.
   No manual configuration required.

6. No commit policy — agent never runs `git add` or `git commit`.

7. 4-level test hierarchy — `describe(Given) > describe(When) > describe(Then: TaskID) > it(assertion)`

## Test Hierarchy Routing

When processing task `T<xx>-<yy>-<zz>`:

1. Extract Given, When, Then from tasks.md
2. Find or create `describe('Given: <Given>')`
3. Find or create `describe('When: <When>')` under Given
4. Find or create `describe('Then: Task T<xx>-<yy> - <title>')` under When
5. Append assertion to existing `it/it.each`, or create leaf `it` if first assertion

## Workflow

### Phase 1: Setup & Detection

1. Verify inputs: task ID + Given/When/Then content + checklist path from the caller
2. Auto-detect: test framework, language, build tools
3. Locate tasks.md; extract Given/When/Then for target task
4. Scan existing test file to map current Given/When structure

| Failure                   | Action                             |
| ------------------------- | ---------------------------------- |
| Framework unclear         | Ask caller or mimic existing tests |
| tasks.md not found        | Ask caller for location            |
| Task ID not in tasks.md   | Ask caller to verify               |
| Given/When/Then ambiguous | STOP — ask caller to clarify       |

### Phase 2: Assertion Breakdown

1. Identify the Cases of the Target in checklist order, then the individual assertions of each Case
2. Create `bdd-todo.md` at `progress_path` (create the directory too). If the file already exists, the
   Target was interrupted or an earlier split part ran: keep its `done` items, add only the missing
   items for your Cases, and continue from the first item that is not `done`. Never rewrite the file.
   Before reusing an existing file, check that its `Scope:` and `Checklist:` lines equal this call's
   `<scope>` and checklist path. If they differ, the file belongs to another task: do not reuse or
   overwrite it, and report `BLOCKED`.
   Every item carries the Case ID (`T-XX-YY-ZZ`) it belongs to:

   ```markdown
   # T-02 Implementation Breakdown

   Scope: <scope>
   Checklist: <checklist path>

   - [ ] [T-02-04-01] testCase1: <description> state: todo
   - [ ] [T-02-04-01] testCase2: <description> state: todo
   - [ ] [T-02-04-02] testCase3: <description> state: todo
   ```

3. State vocabulary: `todo` → `red` → `green` → `done`
4. Checkbox marker: `- [ ]` while the item is `todo` / `red` / `green`,
   `- [x]` once it reaches `state: done`
5. Case ID binding: when the caller passes a Target ID (`T-XX`), `<TaskID>` in the steps below is
   the Case ID of the item being processed (the `[T-XX-YY-ZZ]` tag in `bdd-todo.md`), never the Target ID.
   Rebind it at step 3.1 for every item. A Case with several assertions keeps the same Case ID for all of them.

### Phase 3: RED-GREEN-REFACTOR Loop (per Case / assertion)

Repeat steps 3.1–3.7 for each `state: todo` item:

```text
3.1 Read next `state: todo` item from `bdd-todo.md`. Bind `<TaskID>` to that item's Case ID.

3.2 Write test code only (apply append-first rule). Do NOT touch implementation:

    Anti-patterns to avoid when writing tests:

    - Initial-value assertion — testing only that a field equals its default. No behavior is exercised.
    - Mock passthrough assertion — asserting only that the result equals what the mock returned.
      This validates mock setup, not behavior.
    - Implementation mirror — tracing private internal state or call order instead of observable output.

    If a candidate assertion falls into one of these categories, do NOT write it.
    Write the assertion only if it exercises a real behavior path that can break.

3.3 RED — Run tests. Verify new assertion FAILS. Update `state: red`.
    Check `[<TaskID>-R]` in the checklist file.

3.4 GREEN — Write minimum implementation to pass. Run tests. Verify PASS. Update `state: green`.
    Check `[<TaskID>-G]` in the checklist file.

3.5 Light refactor test code (names, comments, duplication). Verify still passes.

3.6 Light refactor implementation code. Verify tests still pass.
    Check `[<TaskID>-F]` in the checklist file.

3.7 Update `state: done` AND mark the item `- [x]` in `bdd-todo.md`.
    Append the Case log line (see Case Log below).
    If more `state: todo` remain → back to 3.1. Else → Phase 4.
```

#### Case Log

After each Case reaches `state: done`, append one row to the `## Case Log` table at the end of `bdd-todo.md`:

```markdown
## Case Log

| Case ID    | RED                 | GREEN | REFACTOR       |
| ---------- | ------------------- | ----- | -------------- |
| T-01-01-01 | FAIL (missing func) | PASS  | PASS (renamed) |
```

- One row per Case. Each cell is one short phrase: the result, plus the reason only when it is not obvious.
- RED must read `FAIL`; a row whose RED is not `FAIL` means the cycle was skipped, so redo the Case.
- Keep the log in `bdd-todo.md` only. Do not paste test output into it.
- Work from `bdd-todo.md` and the checklist, not from the full log of earlier Cases: re-read only the current Case row and the files it touches.

#### Checklist Write-back Rules

"Check `[<TaskID>-R]`" means: in the checklist file whose path the caller passed
(`<local_dir>/temp/tasks/<slug>-<adjective>-checklist.md`), find the item line
`- [ ] **[<TaskID>-R] Red** : ...` and replace `- [ ]` with `- [x]`.

| Rule         | Detail                                                                           |
| ------------ | -------------------------------------------------------------------------------- |
| Canonical ID | Match in the checklist's `T-XX-YY-ZZ` form, whatever form the caller passed      |
| Marker only  | Change the checkbox marker. Never edit the item text, ID, or table rows          |
| Idempotent   | An item already `- [x]` stays as is                                              |
| Verified     | Check an item only AFTER the step it represents actually passed                  |
| Missing ID   | If the item is absent, skip it and note it in the status report NOTES            |
| Scope        | `-R` / `-G` / `-F`. `-TF` / `-CF` only under the conditions in Phase 5 / Phase 6 |

Do this immediately at the step, not batched at the end: an interrupted run must
leave the checklist showing exactly how far it got.

### Phase 4: Verify All GREEN

1. Confirm all `bdd-todo.md` items are `state: done` and marked `- [x]`
2. Run full test suite — all must pass
3. Target regression — run every test file of the Target (and tests of code the Target shares with others)
   once, after the last Case. A failure here is a regression: revert or fix the Case that caused it, then re-run.

### Phase 5: Refactor Test Code

```text
Step 0: Remove low-value tests

Review each `it` block. Delete it if it matches one of these anti-patterns:

- Initial-value assertion — only checks a default/initial value; exercises no behavior.
- Mock passthrough assertion — only checks that `result === mock.returnValue`; validates mock setup, not behavior.
- Implementation mirror — traces private internal structure or call order; will break on any refactor.

For each deleted test, note in your working log:
`Removed: <category> — <one-sentence reason>`
```

Do NOT delete a test if it is the only test covering a particular boundary or branch.

1. Simplify with `it.each`, remove duplication
2. Splitting `it.each` into separate `it` blocks is encouraged if it improves readability
   — split within the same Then block only; never add new Given/When blocks
3. Verify all tests still pass

Check the `-TF` item of a Scenario only when this invocation implemented every Case of that Scenario
and Phase 5 for it is done. Otherwise leave it for the caller (bdd-coder skill Phase 5).

### Phase 6: Refactor Implementation Code

1. Library substitute — review each implementation file changed in Phase 3–4:
   - Identify inline logic that duplicates an existing library function
     (string manipulation, path handling, array operations, etc.)
   - Replace with the library call. Priority order:
     1. Project shared utilities (`shared/` / `utils/` / `libs/` equivalents)
     2. Module-local helpers already defined in the same codebase
     3. Standard library / language built-ins
   - If no library covers the case, leave the inline logic as-is (do NOT extract a new helper)
2. Conditional consolidation — replace chains of `if/else if` on the same variable or expression
   with `switch/case` (or the language equivalent: `match`, `when`, etc.):
   - Apply only when all branches test the same subject (e.g. `if x === 'a' … else if x === 'b'`)
   - Do NOT apply when branches have unrelated conditions or mixed subjects
3. Functional loop conversion — replace imperative loops with functional equivalents:
   - `for`/`while` that builds a result → `map` / `filter` / `reduce` / `flatMap`
   - Sequential async loops (`for…of` + `await`) → `Promise.all` + `map` when iterations are independent
   - Leave loops as-is when side effects are intentional (I/O, mutation of external state)
     or when the language has no idiomatic functional alternative
4. Extract common logic, improve naming, align with project conventions
5. Verify all tests still pass

Check the `-CF` item only when this invocation implemented every Scenario of the Target and Phase 6 is done.
When the Target was split across invocations, leave it for the caller.

### Phase 7: Quality Gates

1. IDENTIFY — which command proves each criterion?
2. RUN — execute now
3. READ — full output, not a summary
4. VERIFY — criterion met?
5. ONLY THEN — mark gate passed

| Gate       | Must pass                                                                                  |
| ---------- | ------------------------------------------------------------------------------------------ |
| Tests      | All PASS (with coverage)                                                                   |
| Coverage   | Report generated; CRAP scores computed, or `cov=N/A` recorded when coverage is unavailable |
| CRAP       | No function with score > 30; warn if 16–30 exists                                          |
| Type check | 0 errors                                                                                   |
| Lint       | 0 errors                                                                                   |

**CRAP score formula:** `CC² × (1 - coverage/100)³ + CC`
Score > 30 → `BLOCKED`. Score 16–30 → `DONE_WITH_CONCERNS`.
See: [assets/test-quality.md](../../assets/test-quality.md) — CRAP Score section.

**Coverage unavailable** (`cov=N/A`): do NOT substitute `coverage = 0`. Judge the function by CC alone:
CC ≥ 11 → `BLOCKED`. CC 6–10 → `DONE_WITH_CONCERNS`. CC 1–5 → pass.
Same bands as [code-reviewer.md](code-reviewer.md) — Phase 1.3 (CRITICAL / WARN / PASS).

If any gate fails: fix and re-run. On 3+ failures, choose the status by cause:

| Cause                                                                                                                | Status          | Caller action                    |
| -------------------------------------------------------------------------------------------------------------------- | --------------- | -------------------------------- |
| Cases remain and the failures come from the size of the invocation (context pressure, repeated retries across Cases) | `NEEDS_CONTEXT` | Split the Target and re-dispatch |
| The failure would remain after splitting (CRAP / CC limit, type error, broken environment)                           | `BLOCKED`       | Stop and wait for the user       |

A CRAP score above 30 or CC ≥ 11 is always `BLOCKED`. When unsure, report `BLOCKED`.

**After all gates pass** — report to the caller. Do NOT run a code review here: the caller
(bdd-coder skill Phase 4) runs code-reviewer once over the whole session's changes.

## Target Splitting

The default is one Target per invocation. Split at a **Case boundary** (never inside a Case) when any of these holds:

| Trigger          | Threshold (guideline)                                                             |
| ---------------- | --------------------------------------------------------------------------------- |
| Number of Cases  | 30 or more Cases in the Target                                                    |
| Context size     | Target files plus checklist would use over about half of the context window       |
| Repeated retries | 3+ quality-gate failures caused by invocation size (`NEEDS_CONTEXT`, see Phase 7) |

Splitting rules:

1. Split by Scenario first, then by Case inside a Scenario. Each part keeps its Cases in checklist order.
2. Parts that change the same file run one after another, never in parallel.
3. Pass the next part only the minimum state: its Case range, the checklist path, the ENV PROFILE,
   and a one-line summary of what earlier parts changed. Do not pass earlier Case logs.
4. `-TF` / `-CF` and the Target regression run in the last part, or in the caller's Phase 5.
5. A part reports `CASES: <first>..<last>` in its status report so the caller can verify coverage.

## Status Report to Caller

```bash
TASK: <Task ID>
STATUS: <DONE | DONE_WITH_CONCERNS | NEEDS_CONTEXT | BLOCKED>
CASES: <first Case ID>..<last Case ID> (<N> done)
PHASES: R=<pass|fail> G=<pass|fail> F=<pass|fail>
REGRESSION: <pass|fail|not-run>
QUALITY_GATE: <pass|fail>
CHANGED_FILES: <comma-separated paths, or "none">
NOTES: <required if not DONE>
```

`CHANGED_FILES` lists every file this task created, modified, or deleted, implementation
and test alike. The caller unions these lists across tasks to scope the session code
review, so a missing path means code that is not reviewed. Report paths relative to the repository
root, and include newly created files even though they are still untracked.

## Completion Checklist

### Phase 2

- [ ] `bdd-todo.md` created with all assertions at `state: todo`

### Phase 3–4

- [ ] Every item processed through RED → GREEN → REFACTOR
- [ ] All items `state: done` and marked `- [x]` in `bdd-todo.md`
- [ ] Checklist file: `-R` / `-G` / `-F` of every implemented Case marked `[x]`
- [ ] Full test suite passes

### Phase 5–6

- [ ] Low-value tests removed (initial-value, mock-passthrough, implementation-mirror anti-patterns)
- [ ] Test code refactored (parameterization, duplication removed)
- [ ] Implementation code: inline logic replaced with existing library calls where applicable
- [ ] Implementation code refactored (naming, common logic extracted)
- [ ] All tests pass after refactor

### Phase 7

- [ ] Tests: ALL PASS
- [ ] Type check: 0 errors
- [ ] Lint: 0 errors
- [ ] CRAP scores (or `cov=N/A` with the CC verdict) recorded in report

### Task Complete

- [ ] All `bdd-todo.md` items `state: done` and `- [x]`
- [ ] `## Case Log` has one row per Case, every RED cell is `FAIL`
- [ ] Target regression run passed
- [ ] All quality gates pass
- [ ] No `git add` or `git commit` performed

## Test Implementation Template

For test structure patterns, append-first examples, and coverage categories, see:
[assets/templates/bdd-coder-unittest.tpl.md](../../assets/templates/bdd-coder-unittest.tpl.md)

For host safety, idempotency, and mock discipline principles, see:
[assets/test-quality.md](../../assets/test-quality.md)

---

## Error Policies

| Scenario                  | Condition                     | Action                             |
| ------------------------- | ----------------------------- | ---------------------------------- |
| Framework detection fails | Framework unclear             | Ask caller or mimic existing tests |
| Task not found            | tasks.md missing/invalid      | Ask caller                         |
| Ambiguous task            | Given/When/Then unclear       | STOP — ask caller                  |
| Test won't run            | Syntax error                  | Fix before proceeding              |
| RED not confirmed         | Test doesn't fail             | Verify test logic                  |
| GREEN not confirmed       | Test doesn't pass             | Fix implementation                 |
| Regression                | Previously-passing test fails | Revert, fix, re-test               |
