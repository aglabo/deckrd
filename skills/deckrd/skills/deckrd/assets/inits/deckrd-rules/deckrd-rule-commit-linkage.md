---
title: "Deckrd Rule: Commit Linkage"
description: "One implementation document per commit, with required design identifier references"
version: 1.0.0
---

## Deckrd Rule: Commit Linkage

Each implementation document corresponds to exactly one commit.

Commit messages must reference design identifiers.

Required references:

Implements: IMPL-XXX
Spec: SPEC-XXX
Req: REQ-XXX
Test: TEST-XXX

Example:

feat(cli): add configuration parser

Implements: IMPL-001
Spec: SPEC-001
Req: REQ-001
Test: TEST-001
