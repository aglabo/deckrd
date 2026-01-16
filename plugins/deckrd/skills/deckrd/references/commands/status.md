# status Command

Display the current status of the active module and workflow progress.

## Usage

```bash
/deckrd status
```

## Overview

The `status` command shows:

- Current active module (`<namespace>/<module>`)
- Current workflow step (req, spec, impl, tasks)
- Completed steps
- Module path
- Session metadata

## Output Example

```bash
DECKRD Status
=============

Active Module: AGTKind/isCollection
Current Step:  spec
Completed:     init, req

Module Path:   docs/.deckrd/AGTKind/isCollection

Configuration:
  Language:    ja
  AI Model:    claude-sonnet-4-5

Session Info:
  Created:     2025-01-15T10:00:00Z
  Updated:     2025-01-15T14:30:00Z

Workflow Progress:
  [✓] init
  [✓] req
  [•] spec
  [ ] impl
  [ ] tasks
```

**Legend:**

- `[✓]` = Completed
- `[•]` = Current (in progress)
- `[ ]` = Not started

## Error Messages

| Error | Cause | Solution |
|-------|-------|----------|
| No session file found | Session not initialized | Run `deckrd init <namespace>/<module>` |
| No active module set | Session exists but no active module | Run `deckrd init <namespace>/<module>` |
| jq is not installed | jq command not available | Install jq |

## Script

Execute: `.claude/skills/deckrd/scripts/status.sh`

```bash
bash .claude/skills/deckrd/scripts/status.sh
```
