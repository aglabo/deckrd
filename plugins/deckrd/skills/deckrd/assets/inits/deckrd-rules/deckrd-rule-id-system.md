# Deckrd Rule: Identifier System

Design artifacts must use stable identifiers.

Identifier formats:

REQ-XXX
SPEC-XXX
TASK-XXX
IMPL-XXX
TEST-XXX

Rules:

- IDs must be unique.
- IDs must never be reused.
- Documents must declare their ID in frontmatter.

Example:

```yaml
---
id: REQ-001
title: CLI Input Support
status: approved
---
```

Downstream documents must reference upstream IDs.
