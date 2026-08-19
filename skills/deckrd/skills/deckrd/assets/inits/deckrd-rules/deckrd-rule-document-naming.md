---
title: "Deckrd Rule: Document Naming"
description: "Naming convention for all Deckrd documents"
version: 1.0.0
---

## Deckrd Rule: Document Naming

All Deckrd documents must follow the naming convention:

`<prefix>-<number>-<slug>.md`

Prefixes:

- req : requirement
- spec : specification
- task : design / implementation task
- impl : implementation unit (commit-level change)
- test : verification specification

Number rules:

- Sequential numbering
- 3-digit padding (001, 002, 003)

Slug rules:

- lowercase
- kebab-case
- human readable

Examples:

- req-001-cli-input.md
- spec-001-cli-input-format.md
- task-001-parser-design.md
- impl-001-cli-parser.md
- test-001-cli-input.md
