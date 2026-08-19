---
title: "Deckrd Rule: Traceability"
description: "Required REQ to SPEC to TASK to IMPL to TEST to COMMIT dependency flow"
version: 1.0.0
---

## Deckrd Rule: Traceability

Deckrd projects must maintain traceability across the design chain.

Required dependency flow:

REQ → SPEC → TASK → IMPL → TEST → COMMIT

Definitions:

Requirement (REQ)
Defines system capability.

Specification (SPEC)
Defines system behavior and constraints.

Task (TASK)
Defines implementation design work.

Implementation (IMPL)
Defines a commit-sized implementation unit.

Test (TEST)
Defines verification criteria.
Test code implementing these criteria follows deckrd-rule-testing-guidelines.md.

Each document must reference upstream IDs.
