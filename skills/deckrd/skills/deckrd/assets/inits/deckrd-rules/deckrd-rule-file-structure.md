---
title: "Deckrd Rule: File Structure"
description: "Per-module directory layout for Deckrd artifacts under the document root"
version: 1.0.0
---

## Deckrd Rule: File Structure

Deckrd artifacts live under the initialized document root, `docs/.deckrd/`.
Documents are stored per module, one directory level per namespace and module.

```text
docs/.deckrd/
  .session.json
  <namespace>/
    <module>/
      requirements/
      specifications/
      implementation/
      tasks/
      decision-records.md
```

`docs/.deckrd/` is the default root.
A project may override it via the `deckrd_base` session setting.
Every rule that names this path means the configured root.

Example:

```text
docs/.deckrd/chatlog/normalize/
  requirements/requirements.md
  specifications/specifications.md
  implementation/implementation.md
  tasks/tasks.md
  decision-records.md
```

When a specification is split, the directory holds one file per area.
An index file is always added (see the spec command):

```text
specifications/specifications-index.md
specifications/specifications-auth.md
specifications/specifications-notify.md
```
