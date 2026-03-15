---
title: tasks Command
description: Derive executable BDD-style implementation tasks from specifications
---

## tasks Command

Derive executable implementation tasks from specifications.
Each task corresponds to a single unit test case (`it()` block) in a BDD-style testing workflow.

## Usage

```bash
/deckrd tasks           # Generate tasks.md and implementation-checklist.md
/deckrd tasks update    # Regenerate implementation-checklist.md from existing tasks.md
```

## Preconditions

- Session must exist with active module
- `spec` must be completed for active module
- `specifications.md` must exist

## Subcommands

| Subcommand | Description                                                          |
| ---------- | -------------------------------------------------------------------- |
| (none)     | Generate `tasks.md` then auto-generate `implementation-checklist.md` |
| `update`   | Regenerate `implementation-checklist.md` from existing `tasks.md`    |

---

## Execution Flow

### `/deckrd tasks` (default)

#### Phase 0: Codebase Investigation (explore-agent 委譲)

Before generating tasks, delegate document reading to explore-agent:

1. Spawn **explore-agent** with:
   - `scope`: `codebase-survey`
   - `directory`: project root
   - `focus`: `specifications,implementation`
   - Agent definition: [`plugins/deckrd/agents/explore-agent.md`](../../../../agents/explore-agent.md)
2. The agent reads `specifications/specifications.md` and `implementation/implementation.md`.
   Then writes a summary to `temp/deckrd-work/codebase-context.md`
3. Read the **Summary** returned by the agent
4. Proceed to task generation using the summary as context

#### Phase 1: Task Generation

Using the explore-agent summary, generate `tasks.md` via the prompt script.

#### Phase 2: Checklist Generation

After `tasks.md` is verified, automatically generate `implementation-checklist.md`:

1. Read the generated `tasks.md`
2. Expand each test case into Red-Green-Refactor check items
3. Assign unique task IDs with `-R`/`-G`/`-F` suffixes
4. Add `-TF` (Test Refactor) per scenario and `-CF` (Code Refactor) per target
5. Write `tasks/implementation-checklist.md`

### `/deckrd tasks update`

Regenerate `implementation-checklist.md` from the existing `tasks.md`:

1. Verify `tasks.md` exists
2. Read current `tasks.md`
3. Regenerate `implementation-checklist.md` (overwrite)

Use when `tasks.md` has been manually edited after initial generation.

---

## Input

Read: `docs/.deckrd/<namespace>/<module>/specifications/specifications.md`

## Output

| Subcommand | Creates                                                |
| ---------- | ------------------------------------------------------ |
| (none)     | `tasks/tasks.md` + `tasks/implementation-checklist.md` |
| `update`   | `tasks/implementation-checklist.md` (overwrite only)   |

## Prompt & Template

```bash
deckrd/assets/
       ├── prompts/tasks.prompt.md
       ├── templates/tasks.template.md
       └── templates/implementation-checklist.template.md
```

## Task ID Strategy

Task IDs follow a hierarchical structure mapping to BDD test structure:

```bash
T-<TestTarget>-<Scenario>-<Case>
```

| Component  | Format  | Description                   |
| ---------- | ------- | ----------------------------- |
| TestTarget | 2-digit | Test target sequence (01, 02) |
| Scenario   | 2-digit | Given/When scenario (01, 02)  |
| Case       | 2-digit | Specific test case (01, 02)   |

### Examples

```bash
T-01-01-01  → detectValueKind, Primitive input, returns Primitive
T-01-02-01  → detectValueKind, Array input, returns Array
T-02-01-01  → isSingleValue, Single value, returns true
```

## BDD Structure Mapping

Tasks map to the following test structure:

```typescript
// T-XX: Test Target (describe level 1)
describe('<TestTarget>', () => {
  // T-XX-YY: Given/When Scenario (describe level 2)
  describe('[正常] <Scenario>', () => {
    // T-XX-YY-ZZ: Test Case (it level)
    it('Given X, When Y, Then Z', () => {
      // test implementation
    });
  });
});
```

## Category Prefixes

Use category prefixes in scenarios:

| Category  | Prefix         | Description         |
| --------- | -------------- | ------------------- |
| Normal    | [正常]         | Expected behavior   |
| Error     | [異常]         | Error handling      |
| Edge Case | [エッジケース] | Boundary conditions |

## Document Structure

```markdown
---
title: "Implementation Tasks"
module: <namespace>/<module>
status: Active
created: <YYYY-MM-DD HH:MM:SS>
source: specifications.md
---

## Task Summary

| Test Target  | Scenarios | Cases | Status      |
| ------------ | --------- | ----- | ----------- |
| T-01: <name> | N         | M     | in progress |

---

## T-01: <TestTarget>

### [正常] Normal Cases

#### T-01-01: <Given/When Scenario>

- [ ] **T-01-01-01**: <Brief description>
  - Target: `<function>`
  - Scenario: Given <precondition>, When <action>
  - Expected: Then <assertion>

### [異常] Error Cases

#### T-01-02: <Error Scenario>

- [ ] **T-01-02-01**: <Error case description>
      ...

### [エッジケース] Edge Cases

#### T-01-03: <Edge Case Scenario>

- [ ] **T-01-03-01**: <Edge case description>
      ...
```

---

## Verification Gate (REQUIRED before Session Update)

YOU MUST verify both output files by reading them directly — not from memory.

### tasks.md checks

| Check                                  | Method                          | Pass Criteria            |
| -------------------------------------- | ------------------------------- | ------------------------ |
| Task IDs are unique                    | Scan all T-XX-YY-ZZ IDs in file | No duplicates            |
| Each task has Target/Scenario/Expected | Read each entry                 | All 3 fields present     |
| Normal / Error / Edge cases all exist  | Count by category               | >=1 each                 |
| Tasks trace to specifications          | Cross-ref spec sections         | Each task maps to a spec |

### implementation-checklist.md checks

| Check                                      | Method                   | Pass Criteria                        |
| ------------------------------------------ | ------------------------ | ------------------------------------ |
| Every task in tasks.md has R/G/F items     | Cross-ref task IDs       | No task missing any phase            |
| TF exists per scenario, CF per test target | Scan -TF and -CF entries | Each scenario has TF, each target CF |
| Task IDs are unique (including -R/-G/-F)   | Scan all IDs             | No duplicates                        |

If any check fails: YOU MUST regenerate the failing section. No partial approval.
ONLY after all checks pass: proceed to Session Update.

---

## Session Update

After completion, update `.session.json`:

```json
{
  "current_step": "tasks",
  "completed": ["init", "req", "spec", "impl", "tasks"],
  "documents": {
    "requirements": "requirements.md",
    "specifications": "specifications.md",
    "implementation": "implementation.md",
    "tasks": "tasks.md",
    "implementation-checklist": "implementation-checklist.md"
  }
}
```

> **Note**: `tasks update` does NOT change `current_step` or `completed`. It only regenerates `implementation-checklist.md`.

## Script

Execute: [generate-doc.sh](../../scripts/generate-doc.sh)

<!-- markdownlint-disable line-length -->

```bash
# Default: generate both tasks.md and implementation-checklist.md
bash ${CLAUDE_PLUGIN_ROOT}/scripts/generate-doc.sh @tasks [--lang <lang>] --output "tasks/tasks.md"
bash ${CLAUDE_PLUGIN_ROOT}/scripts/generate-doc.sh @implementation-checklist [--lang <lang>] --input "tasks/tasks.md" --output "tasks/implementation-checklist.md"

# Update: regenerate implementation-checklist.md only
bash ${CLAUDE_PLUGIN_ROOT}/scripts/generate-doc.sh @implementation-checklist [--lang <lang>] --input "tasks/tasks.md" --output "tasks/implementation-checklist.md"
```

<!-- markdownlint-enable -->

## Next Step

Workflow complete.
You can now execute tasks using:

- `implementation-checklist.md` for BDD Red-Green-Refactor cycle tracking
- TodoWrite tool for task tracking
- BDD coding workflow for implementation
