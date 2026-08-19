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

```text
---
id: REQ-001
title: CLI Input Support
status: approved
---
```

Downstream documents must reference upstream IDs.

## Uniqueness Verification

"IDs must be unique" is unenforceable by reading alone. Derive the check from the
documents themselves. Do not maintain a hand-written ledger of allocated IDs.

Deckrd artifacts live under the initialized document root,
`docs/.deckrd/<namespace>/<module>/`. The commands below search that root.
Substitute the configured root if the project overrides it.

### Namespacing

Do not reuse a base ID when the same subject appears in more than one module.
Add a namespace segment to the later one. Do not renumber the original.

```text
REQ-001      base
REQ-F-001    functional namespace
REQ-NF-001   non-functional namespace
```

Referencing an ID from another document's prose is always allowed. Only the
frontmatter `id:` declaration counts as an allocation.

Before introducing a new namespace segment, confirm it is unused.

```bash
grep -rl "REQ-<new-namespace>-" --include=*.md docs/.deckrd/
```

### Duplicate Detection

Extract every declared ID and report any allocated more than once. Output must be empty.

```bash
grep -rhoE "^id:[[:space:]]*\S+" --include=*.md docs/.deckrd/ \
  | tr -c 'A-Za-z0-9-' '\n' \
  | grep -xE "(REQ|SPEC|TASK|IMPL|TEST)(-[A-Z0-9]+)*-[0-9]{3}" \
  | sort | uniq -d
```

If an ID is reported, locate its declarations.

```bash
grep -rn "<reported ID>" --include=*.md docs/.deckrd/
```

Three details are load-bearing. Dropping any one causes missed duplicates or false positives.

1. **Restrict to the declaration site** (`^id:`). Scanning whole documents mistakes a
   downstream cross-reference for an allocation.
2. **Match on token boundaries** (`tr -c` to split, `grep -x` to compare). Substring
   matching reports the `001` inside `REQ-F-001` as colliding with `REQ-001`.
3. **Count occurrences across all files.** A per-file `sort -u` hides in-document duplicates.
