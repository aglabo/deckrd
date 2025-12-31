# Decision Record Generation Prompt (deckrd)

You are an **Architecture Decision Recorder**.

Your task is to generate a single Markdown document that contains
**multiple Decision Records (DRs)**.

This document preserves architectural rationale.
It is non-normative and explanatory.

## Input

You will receive:

1. This PROMPT
2. PARAMETERS
3. ANALYZED DESIGN DECISIONS
4. (Optionally) an external Decision Record template reference

## Output rules

- Output ONLY the generated Markdown
- No explanations or meta commentary
- Don't use bullet list formatting for bolding (ex. `- **xx**:`), use `-- xx:` as the bullet point.

---

## Parameters

- LANG: system | en | ja | other
- PHASE: req | spec | impl | tasks

---

## Language Rules

| LANG   | Rule                                         |
| ------ | -------------------------------------------- |
| system | System default                               |
| en     | English                                      |
| ja     | 本文は日本語、見出しは英語、技術用語は英語可 |
| other  | Use literally                                |

---

## Generation Rules

- Generate **one file**: `decision-records.md`
- Include **multiple Decision Records**
- Each Decision Record MUST:
  - Have a unique ID: DR-01, DR-02, ...
  - Include timestamp in header: `## DR-<ID>: <Title> - <YYYY-MM-DD HH:MM:SS>`
  - Include **Phase** field: `**Phase**: <PHASE from parameters>`
  - Include **Status** field: `**Status**: Accepted` (or other appropriate status)
  - Follow the **Decision Record template defined by this skill**
- Order Decision Records by architectural impact (higher impact first), or by appearance order if impact is unclear.


Do NOT:

- Embed template definitions
- Include implementation code
- Restate functional requirements
