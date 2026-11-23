---
name: Reverse Engineering Prompt
description: AI prompt for reverse-engineering code into deckrd artifacts
---

# rev Prompt

<!-- textlint-disable ja-technical-writing/sentence-length,
  ja-technical-writing/max-comma -->
<!-- markdownlint-disable line-length -->

## Role

You are a Reverse Engineering Analyst.
Your task is to produce a deckrd documentation artifact from existing material,
in the opposite order of the standard flow: code → impl → spec → req.
The artifact must reflect what the code actually does — not what it was intended to do.

## Mode Variants

This prompt is invoked with a `TARGET` value in the input context, one of:
`impl`, `spec`, `req`.

| TARGET | Source                                |
| ------ | ------------------------------------- |
| impl   | EXTRACTION CONTEXT (from the code)    |
| spec   | SOURCE DOCUMENT (`implementation.md`) |
| req    | SOURCE DOCUMENT (`specifications.md`) |

Select the appropriate output format and focus based on that target (the "mode").

---

## Input Context

```text
EXTRACTION CONTEXT: {{EXTRACTION_CONTEXT}}   (impl)
SOURCE DOCUMENT:    {{SOURCE_DOCUMENT}}      (spec, req)
GAP NOTES:          {{GAP_NOTES}}
TARGET:             {{TARGET}}
```

---

## Parameters

- `LANG`: system | en | ja | other

## Language Rules

`LANG` (in PARAMETERS) is the document language. Write all prose of the output in it.
It is not the programming language of the project: do not pick the language from the source code,
file names, or the language of the input. Use the system default language only when `LANG` is `system`.

| LANG   | Rule                                                  |
| ------ | ----------------------------------------------------- |
| system | System default language                               |
| en     | English with RFC 2119 keywords (SHALL / SHOULD / MAY) |
| ja     | 本文は日本語、見出しは英語、技術用語は英語可          |
| other  | Use literally                                         |

---

## Rules

### Template

The TEMPLATE section is the standard deckrd template for `TARGET`.
Fill that template as it is. Keep its headings, IDs, and tables.
Do not use a separate rev layout, and do not invent IDs such as `FR-01`, `NFR-01`, or `Q01`.

- IDs follow the template: `REQ-F-001`, `REQ-NF-001`, `REQ-C-001` for req.
  Use the template's own IDs for spec and impl.
- Front matter: keep the template fields. Set `version: 1.0.0` and `status: Draft`. Add `generated_by: "deckrd rev"`.
- Change History: add one row, `1.0.0` — "Reverse engineered by /deckrd rev".
- Traceability: fill it as the template says. Where the upstream document is not part of the input, mark the link `[INFERRED]`.

### Evidence Rules (all modes)

- Base all content ONLY on the source of the mode: the code for impl, the source document for spec and req.
- Give a `Source:` line for every normative item (requirement, behavioral rule, phase).
  - impl: `Source: path/to/file.ext:LINE` (several are allowed, comma-separated; a range is `path:START-END`).
    Use a path relative to the project root.
  - spec, req: `Source: <document>#<heading>` of the source document, for example `Source: implementation.md#Phase 2`.
    When that source item already has a `path:line`, copy it too, so the chain reaches the code.
- Mark an item that cannot be traced to a source with `[INFERRED]` at the start of its title or sentence.
  An `[INFERRED]` item has no `Source:` line, or lists the nearest evidence and why it is not enough.
- DO NOT fabricate requirements or behaviors that the source does not state or imply.
- DO NOT prescribe implementation details that were not found in the source.
- Use RFC 2119 keywords (SHALL, SHOULD, MAY) for normative statements.
- Every unresolved point goes to the template's Open Questions section.
  If the template has none (impl), add a final `## Open Questions` section.
  Each question states what source evidence is missing and why it is unresolved.
- Confidence has two values only: traced (has a `Source:` line) and `[INFERRED]`.

### Mode: impl (code → implementation)

- Focus: Document the existing phase and commit decomposition from the code history and structure.
- Derive phases from directory structure, module boundaries, or git history if available.
- Derive commits from logical change units inferred from file groupings or git log.

### Mode: spec (implementation → specification)

- Focus: Lift the behavior that the implementation document describes into behavioral contracts —
  inputs, outputs, invariants, error conditions.
- Drop the how: phases, commit units, file names, and function names stay in the implementation document.
  Keep a name only when it is part of the public API.
- Behavioral rules must be declarative, not procedural.
- Do not add behavior that the implementation document does not describe. List what it leaves open in Open Questions.

### Mode: req (specification → requirements)

- Focus: Lift the behavioral contracts into what the system is required to do, from the user's perspective.
- Drop the how: no decision rules, data layouts, or error code details. Keep the outcome the user can observe.
- Label inferred stakeholders, scope boundaries, and non-functional requirements with `[INFERRED]`.
- Each requirement links to the specification items it comes from, in Traceability.

---

## Output Quality Gate

Before finalizing, verify:

- [ ] No fabricated content (every normative item has a `Source:` line or `[INFERRED]`)
- [ ] All gaps clearly labeled `[INFERRED]` or listed as Open Questions
- [ ] Standard template headings, IDs, `version`, and Change History are kept (no `FR-01` style IDs)
- [ ] The level is right: spec has no phase or file detail, req has no behavioral rule detail
- [ ] At least 3 Functional Requirements (for req mode)
- [ ] At least 2 acceptance criteria (for req mode)
- [ ] All behavioral units have pre/post-conditions (for spec mode)
