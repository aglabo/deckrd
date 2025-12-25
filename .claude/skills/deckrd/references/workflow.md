/deckrdDeckrd# Deckrd Workflow

## Overview

Deckrd follows a linear document derivation workflow:

```bash
Goals/Ideas → Requirements → Specifications → Implementation → Tasks
```

## Workflow Steps

### 1. init

Initialize the module directory and session.

- **Input:** namespace/module name
- **Output:** Directory structure + session entry
- **Next:** req

### 2. req (Requirements)

Derive clear requirements from initial goals.

- **Input:** User's goals, ideas, or problem description
- **Output:** `requirements/requirements.md`
- **Source:** User input (free-form)
- **Next:** spec (or dr to add Decision Records)

### 2a. dr (Decision Records) - Optional

Append Decision Records during requirements phase.

- **Input:** Decision context from user
- **Output:** `decision-records.md` (append-only)
- **Precondition:** current_step === "req"
- **Note:** DRs are non-normative records of architectural Decisions

### 3. spec (Specifications)

Derive technically verifiable behavioral goals from requirements.

- **Input:** Requirements document
- **Output:** `specifications/specifications.md`
- **Source:** `requirements/requirements.md`
- **Next:** impl

### 4. impl (Implementation)

code example for write constraint:

#### Constraint: <観点名>

- Rule:
  <必ず満たすべき制約を一文で断定的に書く>
- Rationale
  <なぜこの制約が必要か。仕様・安全性・一貫性など>
- Notes
  - <補足条件>
  - <例外があれば明示>
- Example (Non-normative)

  ```typescript
  // 制約を説明するための最小例 (実装ではない)
  ```

例:

```markdown
#### Constraint: Primitive value handling

- Rule:
  null および undefined は Primitive 値として扱う。
- Rationale:
  JavaScript では `typeof null === "object"` という仕様上の例外があり、
  これを特別扱いしないと分類結果が不安定になるため。
- Notes:
  - NaN, Infinity も number として Primitive に含める。
  - object 判定より前に評価される必要がある。
```

### 5. tasks

create task lists for coding. use BDD coding style.

- **Input:** Implementation document
- **Output:** `tasks/tasks.md`
- **Source:** `implementation/implementation.md`
- **Next:** (complete)

## Directory Structure

```bash
docs/.deckrd/
├── .session.json                    # Session state
└── <namespace>/
    └── <module>/
        ├── requirements/
        │   └── requirements.md
        ├── decision-records.md      # Optional: DR records (append-only)
        ├── specifications/
        │   └── specifications.md
        ├── implementation/
        │   └── implementation.md
        └── tasks/
            └── tasks.md
```

## Usage Example

```bash
# Start new module
/deckrd init AGTKind/isCollection

# User provides goals, then derive requirements
/deckrd req
# → Creates requirements/requirements.md

# (Optional) Add Decision Records during req phase
/deckrd dr --add
# → Appends to Decision-records.md (only allowed during req step)

# Derive specifications from requirements
/deckrd spec
# → Reads requirements.md, creates specifications.md

# Derive implementation plan
/deckrd impl
# → Reads requirements.md, specifications.md, creates implementation.md

# Derive executable tasks
/deckrd tasks
# → Reads specifications.md, creates tasks.md
```
