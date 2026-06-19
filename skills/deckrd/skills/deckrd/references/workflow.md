---
title: Deckrd Workflow
description: Linear document derivation workflow from goals to executable tasks
---

## Deckrd Workflow

## Overview

Deckrd follows a linear document derivation workflow:

```bash
Goals/Ideas → Requirements → Specifications → Implementation → Tasks
```

## Prerequisites

### init

Bootstrap the project once per repository. Writes project configuration and creates an empty session file.

- **Command:** `init <project> <project-type>`
- **Input:** Project name and project type (e.g., `webapp`, `lib`, `cli`)
- **Output:** `.local/deckrd/project.json` + `.local/deckrd/session.json` (no active module set)
- **Note:** Run once per project — not part of the per-feature workflow

---

## Workflow Steps

### 1. module

Create module directory structure and set the active module.

- **Command:** `module <namespace>/<module>`
- **Input:** Namespace and module name (e.g., `agt-kind/is-collection`)
- **Output:** `docs/.deckrd/<namespace>/<module>/` directory structure; session updated (active module set)
- **Next:** req

Variants:

- `module <ns>/<mod> --force` — Re-initialize existing module (files preserved)
- `module create <ns>/<mod>` — Create module with `.project.json`

### 2. req (Requirements)

Derive clear requirements from initial goals.

- **Input:** User's goals, ideas, or problem description (free-form)
- **Output:** `requirements/requirements.md`
- **Source:** User input
- **Next:** spec (or dr to add Decision Records)

### dr (Decision Records) — Optional

Append Decision Records at any step.

- **Input:** Decision context from user
- **Output:** `decision-records.md` (append-only)
- **Precondition:** `current_step` must be one of: `req`, `spec`, `impl`, `tasks`
- **Note:** Requires confirmation when `current_step === "tasks"`
- **Note:** DRs are non-normative records of architectural decisions

### 3. spec (Specifications)

Derive technically verifiable behavioral specifications from requirements.

- **Input:** `requirements/requirements.md`
- **Output:** `specifications/specifications.md`
- **Next:** impl

### 4. impl (Implementation)

Derive an implementation plan (phase and commit decomposition) from specifications.

- **Input:** `specifications/specifications.md`
- **Output:** `implementation/implementation.md`
- **Next:** tasks

### 5. tasks

Derive executable BDD-style implementation tasks.

- **Input:** `implementation/implementation.md` + `specifications/specifications.md`
- **Output:** `tasks/tasks.md` + `tasks/implementation-checklist.md`
- **Next:** (complete — use `/deckrd-coder` to implement)

Variants:

- `tasks update` — Regenerate `implementation-checklist.md` from existing `tasks.md`

## Directory Structure

```bash
.local/deckrd/
├── project.json                     # Project configuration
└── session.json                     # Session state

docs/.deckrd/
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
            ├── tasks.md
            └── implementation-checklist.md
```

## Usage Example

```bash
# Bootstrap project (once per project)
/deckrd init myapp webapp

# Create module and set as active
/deckrd module agt-kind/is-collection
# → Creates docs/.deckrd/agt-kind/is-collection/ directory structure

# User provides goals, then derive requirements
/deckrd req
# → Creates requirements/requirements.md

# (Optional) Add Decision Records during any step
/deckrd dr --add
# → Appends to decision-records.md

# Derive specifications from requirements
/deckrd spec
# → Reads requirements.md, creates specifications.md

# Derive implementation plan
/deckrd impl
# → Reads specifications.md, creates implementation.md

# Derive executable tasks
/deckrd tasks
# → Reads implementation.md, creates tasks.md + implementation-checklist.md
```

---

## Alternative Workflow Paths

### Reverse Engineering Path (existing code → documentation)

Use when: existing code or PoC exists and documentation is missing.

```bash
# Bootstrap project and create module
/deckrd init my-project lib
/deckrd module my-project/legacy-module

# Reverse-engineer requirements from code
/deckrd rev --to req
# → Analyzes codebase, creates requirements/requirements.md

# Continue with standard flow from here
/deckrd spec
/deckrd impl
/deckrd tasks
```

Or reverse-engineer directly to a later stage:

```bash
/deckrd rev --to spec   # → Skip req, generate spec from code
/deckrd rev --to impl   # → Generate impl from code (req + spec must exist)
```

## Workflow Selection Guide

| Situation                                    | Recommended Path               |
| -------------------------------------------- | ------------------------------ |
| New feature from scratch                     | Standard flow                  |
| Existing code, no documentation              | `rev` path                     |
| PoC completed, need production documentation | `rev --to req` + standard flow |
| Complex change, new external interfaces      | Standard flow                  |
