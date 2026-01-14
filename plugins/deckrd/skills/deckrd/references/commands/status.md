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

## Session Resolution

**Session file location:**

```bash
docs/.deckrd/.session.json
```

**Required fields:**

```json
{
  "active": "<namespace>/<module>",
  "lang": "system",
  "ai_model": "sonnet",
  "created_at": "<ISO-8601 date>",
  "updated_at": "<ISO-8601 date>",
  "modules": {
    "<namespace>/<module>": {
      "current_step": "req",
      "completed": ["init"],
      "documents": {}
    }
  }
}
```

## Output Format

### Success Output

```bash
DECKRD Status
=============

Active Module: <namespace>/<module>
Current Step:  <current_step>
Completed:     <completed_steps>

Module Path:   docs/.deckrd/<namespace>/<module>

Configuration:
  Language:    <lang>
  AI Model:    <ai_model>

Session Info:
  Created:     <created_at>
  Updated:     <updated_at>

Workflow Progress:
  [✓] init
  [✓] req     (if in completed)
  [•] spec    (if current_step)
  [ ] impl    (if not started)
  [ ] tasks   (if not started)
```

**Legend:**

- `[✓]` = Completed
- `[•]` = Current (in progress)
- `[ ]` = Not started

### Example Output

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

## Error Handling

### No Session File

```bash
Error: No session file found.
  Expected: docs/.deckrd/.session.json

Run 'deckrd init <namespace>/<module>' to initialize.
```

Exit code: 1

### No Active Module

```bash
Error: No active module set in session.

Run 'deckrd init <namespace>/<module>' to set active module.
```

Exit code: 1

### Invalid Session Format

```bash
Error: Invalid session file format.
  File: docs/.deckrd/.session.json

Session file may be corrupted. Please check the JSON format.
```

Exit code: 1

## Implementation Notes

### Workflow Steps

The workflow follows this sequence:

```
init → req → spec → impl → tasks
```

- init: Directory structure created
- req: Requirements defined
- spec: Specifications written
- impl: Implementation planned
- tasks: Tasks broken down

### Step Status Determination

```javascript
// Pseudo-code
for each step in [init, req, spec, impl, tasks]:
  if step in completed:
    mark as [✓]
  else if step == current_step:
    mark as [•]
  else:
    mark as [ ]
```

### Display Priority

1. Show active module and current step (most important)
2. Show progress indicators (visual feedback)
3. Show configuration (context)
4. Show session metadata (reference)

## Non-Goals

- Do NOT modify any files
- Do NOT change session state
- Do NOT execute any workflow steps
- Do NOT validate module directory existence

## Script Integration

This command is informational only and does not require AI interaction.

Execute: Direct bash/shell script or skill implementation

**Suggested implementation:**

```bash
#!/usr/bin/env bash
# status.sh - Display deckrd status

SESSION_FILE="docs/.deckrd/.session.json"

if [[ ! -f "$SESSION_FILE" ]]; then
  echo "Error: No session file found."
  echo "  Expected: $SESSION_FILE"
  echo ""
  echo "Run 'deckrd init <namespace>/<module>' to initialize."
  exit 1
fi

# Use jq to parse session
if ! command -v jq >/dev/null 2>&1; then
  echo "Error: jq is not installed."
  exit 1
fi

# Extract fields
active=$(jq -r '.active // empty' "$SESSION_FILE")
lang=$(jq -r '.lang // "system"' "$SESSION_FILE")
ai_model=$(jq -r '.ai_model // "unknown"' "$SESSION_FILE")
created=$(jq -r '.created_at // "unknown"' "$SESSION_FILE")
updated=$(jq -r '.updated_at // "unknown"' "$SESSION_FILE")
current_step=$(jq -r ".modules[\"$active\"].current_step // empty" "$SESSION_FILE")
completed=$(jq -r ".modules[\"$active\"].completed | join(\", \") // \"none\"" "$SESSION_FILE")

# Display status
echo "DECKRD Status"
echo "============="
echo ""
echo "Active Module: $active"
echo "Current Step:  $current_step"
echo "Completed:     $completed"
echo ""
echo "Module Path:   docs/.deckrd/$active"
echo ""
echo "Configuration:"
echo "  Language:    $lang"
echo "  AI Model:    $ai_model"
echo ""
echo "Session Info:"
echo "  Created:     $created"
echo "  Updated:     $updated"
echo ""
echo "Workflow Progress:"

# Display progress
for step in init req spec impl tasks; do
  if echo "$completed" | grep -q "$step"; then
    echo "  [✓] $step"
  elif [[ "$step" == "$current_step" ]]; then
    echo "  [•] $step"
  else
    echo "  [ ] $step"
  fi
done
```
