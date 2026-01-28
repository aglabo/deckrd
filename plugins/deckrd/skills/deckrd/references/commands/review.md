# review Command

<!-- textlint-disable ja-technical-writing/no-exclamation-question-mark -->
<!-- textlint-disable ja-technical-writing/sentence-length -->
<!-- markdownlint-disable line-length -->

Review documents with phase-specific analysis for design maturation.

The `review` command supports three review phases (explore/harden/fix) that control
the reviewer persona and allowed operations, enabling progressive hardening of
requirements and specifications.

## Usage

```bash
/deckrd review                    # Display usage information
/deckrd review usage              # Display usage information

/deckrd review <doc_phase> [--phase <review_phase>]
/deckrd review --phase <review_phase> [@document_path]
```

## Command Modes

### Usage Mode (no args or "usage")

```bash
/deckrd review
/deckrd review usage
```

**Behavior:**

- Display usage information and available options
- Show phase descriptions (explore/harden/fix)
- Show document phase mappings (req/spec/impl/tasks)
- **DO NOT execute any review or modify files**

**Output Example:**

```bash
Review Command - deckrd

Review documents with phase-specific analysis.

Usage:
  /deckrd review                              Show this help
  /deckrd review <doc_phase> [--phase <p>]    Review document by phase
  /deckrd review --phase <p> @<path>          Review specific document

Document Phases:
  req     Review requirements/requirements.md
  spec    Review specifications/specifications.md
  impl    Review implementation/implementation.md
  tasks   Review tasks/tasks.md

Review Phases:
  explore   Design Reviewer - identify gaps, alternatives (default)
  harden    Normative Reviewer - promote to MUST/SHALL, generate DR
  fix       Spec Auditor - normalize, verify consistency

Options:
  --phase <p>       Review phase: explore, harden, fix (default: explore)
  --output <file>   Output file path (default: stdout)
  --lang <lang>     Output language (default: session setting)
```

### Review Mode

```bash
/deckrd review <doc_phase> [--phase <review_phase>]
/deckrd review --phase <review_phase> [@document_path]
```

**Behavior:**

- Execute document review with specified phase persona
- Generate findings and recommendations
- (harden only) Generate and append DR entries to decision-records.md

## Arguments

| Argument      | Description                          |
| ------------- | ------------------------------------ |
| usage         | Show usage information               |
| `<doc_phase>` | req / spec / impl / tasks            |
| `[@doc_path]` | @path/to/file.md (@ prefix required) |

## Options

| Option   | Required | Default | Description            |
| -------- | -------- | ------- | ---------------------- |
| --phase  | No*      | explore | explore / harden / fix |
| --output | No       | stdout  | Output file path       |
| --lang   | No       | session | Output language        |

- When `doc_phase` is specified, `--phase` is optional (default: explore)
- When `@doc_path` is specified, `--phase` is required

## Argument Resolution

**Resolution order:**

1. No arguments or "usage":
   → Display usage, exit

2. First argument is req/spec/impl/tasks:
   → Interpret as doc_phase, resolve to corresponding file

3. First argument starts with @:
   → Interpret as doc_path, --phase is required

**Document phase to file mapping:**

| Doc Phase | Resolved File                    |
| --------- | -------------------------------- |
| req       | requirements/requirements.md     |
| spec      | specifications/specifications.md |
| impl      | implementation/implementation.md |
| tasks     | tasks/tasks.md                   |

## Review Phases

### explore Phase

**Persona:** Design Reviewer

**Purpose:** Initial exploration, identify gaps and alternatives

**Rules:**

- SHOULD / MAY language: Allowed
- MUST / SHALL language: **PROHIBITED**
- Decision Records: **PROHIBITED**

**Focus areas:**

- Completeness - are all scenarios covered?
- Ambiguity - are terms clearly defined?
- Alternatives - what other approaches exist?
- Assumptions - are implicit assumptions stated?

### harden Phase

**Persona:** Normative Requirements Reviewer

**Purpose:** Harden requirements, make definitive decisions

**Rules:**

- SHOULD / MAY language: Extract WHEN conditions
- MUST / SHALL language: Promote where evidence supports
- Decision Records: **REQUIRED** for each promotion

**Focus areas:**

- WHEN extraction - identify conditions for SHOULD statements
- Promotion - upgrade SHOULD → MUST with justification
- Gap filling - add missing normative requirements
- DR generation - document each decision

### fix Phase

**Persona:** Spec Auditor

**Purpose:** Final cleanup, ensure consistency

**Rules:**

- SHOULD / MAY language: **PROHIBITED** (no new soft requirements)
- MUST / SHALL language: **PROHIBITED** (no new hard requirements)
- Decision Records: **PROHIBITED**

**Focus areas:**

- Terminology consistency - same terms for same concepts
- Testability verification - each requirement is testable
- Structure normalization - consistent formatting
- Cross-reference validation - all references valid

## DR Integration (harden Phase Only)

When review phase is `harden`:

1. AI generates DR entries in standard format
2. Script extracts DR sections from output
3. DR entries are appended to `decision-records.md`
4. DR-ID is auto-assigned (max existing + 1)

**DR format in review output:**

```markdown
## Decision Records

### DR-XX: Decision Title

**Phase**: review-harden
**Status**: Accepted

### Context

Why this decision was needed during review

### Decision

What was decided (requirement promoted, gap filled, etc.)

### Alternatives Considered

- Option A: ...
- Option B: ...

### Rationale

Why this option was chosen

### Consequences

- Positive: ...
- Negative: ...
```

## Preconditions (STRICT)

- Session must exist at `docs/.deckrd/.session.json`
- `session.active` must be set
- Target document must exist
- For `@path` syntax: `--phase` must be specified

## Error Handling

| Condition                 | Action                          |
| ------------------------- | ------------------------------- |
| No session file           | Error, exit with non-zero       |
| No active module          | Error, exit with non-zero       |
| Target document not found | Error with message, no file ops |
| Invalid doc_phase         | Error with valid options        |
| Invalid review_phase      | Error with valid options        |
| @path without --phase     | Error, require --phase          |

**Error Philosophy:**

- Fail fast
- No partial writes
- No silent fallbacks
- Prefer explicit errors over guessing

## Examples

```bash
# Show usage
/deckrd review
/deckrd review usage

# Review requirements with explore phase (default)
/deckrd review req

# Review requirements with harden phase (generates DR)
/deckrd review req --phase harden

# Review specifications with fix phase
/deckrd review spec --phase fix

# Review specific file with explicit phase
/deckrd review --phase explore @requirements/requirements.md

# Review with output file
/deckrd review req --phase harden --output reviews/req-harden-2026-01-16.md
```

## Prompt & Documents

### Prompt

Review derives findings using the shared prompt file:

```text
deckrd/assets/
       └── prompts/review.prompt.md
```

### Templates (Phase-Specific)

Each review phase uses a dedicated template:

| Phase   | Template File                        |
|---------|--------------------------------------|
| explore | templates/review-explore.template.md |
| harden  | templates/review-harden.template.md  |
| fix     | templates/review-fix.template.md     |

## AI Interaction Engine

Deckrd commands rely on an AI interaction engine to derive documents
from user input and interaction logs.

Execute: [run-prompt.sh](../../scripts/run-prompt.sh)

For review mode:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/run-prompt.sh review @<document> --phase <phase> [--lang <lang>] [--output <file>]
```
