# tasks Command

Derive executable implementation tasks from specifications.
Each task corresponds to a single unit test case (`it()` block) in a BDD-style testing workflow.

## Usage

```bash
/deckrd tasks
```

## Preconditions

- Session must exist with active module
- `spec` must be completed for active module
- `specifications.md` must exist

## Input

Read: `docs/.deckrd/<namespace>/<module>/specifications/specifications.md`

## Output

Create: `docs/.deckrd/<namespace>/<module>/tasks/tasks.md`

## Prompt & Template

Use prompt and template for generating tasks:

```bash
deckrd/assets/
       ├── prompts/tasks.prompt.md
       └── templates/tasks.template.md
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
    "tasks": "tasks.md"
  }
}
```

## Script

Execute: [run_prompt.sh](../../scripts/run-prompt.sh)

```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/run_prompt.sh tasks [--lang <lang>] --output "tasks/tasks.md"
```

## Next Step

Workflow complete.
You can now execute tasks using:

- TodoWrite tool for task tracking
- BDD coding workflow for implementation

You can program by BDD based on the generated tasks.
