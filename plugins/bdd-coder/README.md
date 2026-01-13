# bdd-coder

<!-- textlint-disable ja-technical-writing/sentence-length -->

**bdd-coder** is a methodology-level agent that defines
*how to structure, group, and evolve test cases* in strict BDD-style development.

This repository does not provide a CLI, generator, or executable workflow.
It provides **decision rules**.

---

## What This Is

bdd-coder formalizes **test design judgment**.

It exists to make the following decisions explicit and repeatable:

- how to break tasks into assertion-level tests
- when to append assertions vs when to split tests
- how to enforce strict RED → GREEN → REFACTOR sequencing
- how to derive test hierarchy from Given / When / Then
- how to track progress without ambiguity

---

## What This Is Not

bdd-coder is **not**:

- a test generator
- a framework-specific tool
- a coding assistant
- a workflow or automation script

It is meant to be **consulted and obeyed**, not executed.

---

## Repository Structure

'''text
bdd-coder/
├─ README.md # Entry point (this file)
├─ agents/
│ └─ bdd-coder.md # Core specification (normative)
├─ docs/ # Design rationale, scope, boundaries
└─ examples/ # Minimal input/output examples
'''

- **agents/bdd-coder.md is the single source of truth**
- docs/ explains *why* the rules exist
- examples/ shows *what correct structure looks like*
- No skills/, scripts/, or workflows exist by design

---

## How to Read This Repository

1. Read agents/bdd-coder.md to understand the rules
2. Read docs/ to understand the intent and boundaries
3. Check examples/ to see expected outcomes

If you skip step 1, you will misunderstand the project.

---

## Relationship to Other Projects

bdd-coder may be hosted inside another repository (e.g. deckrd),
but it is **not project-specific**.

It is a standalone methodology.

---

## License

MIT License
Copyright (c) 2025–2026 atsushifx
