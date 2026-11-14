---
name: Universal Dictionary Generation Prompt
description: AI prompt for generating or updating a module's universal-dictionary.md (the canonical source of terms and concepts)
---

# Universal Dictionary Generation Prompt

<!-- textlint-disable
  ja-technical-writing/sentence-length,
  ja-technical-writing/max-comma -->
<!-- markdownlint-disable line-length -->

You are a domain analyst.
Generate or update the module's `universal-dictionary.md`: the single canonical source of the
terms and concepts shared by every design phase (requirements, decision records,
specifications, implementation, tasks).

The dictionary lets a reader interpret the same term with the same meaning in any DR or
specification. It defines **concepts**, not decisions, rules, or behavior.

## Input Format

You will receive:

1. TEMPLATE: Document structure to follow
2. PARAMETERS: Configuration including LANG
3. REQUIREMENTS: The requirements document
4. DICTIONARY TERMS: The user-approved term list from spec Phase 9, each classified as
   NEW / REUSE / CHANGED / INCONSISTENT, with UD-IDs already assigned
5. EXISTING DICTIONARY (optional): The current `universal-dictionary.md`
6. CONFIRMED DESIGN (optional): User-approved design direction
7. EXTERNAL DESIGN NOTES (optional): Unit contracts, interaction map, edge cases
8. API DECISIONS / FUNCTION DECISIONS (optional): Confirmed external interfaces
9. DECISION RECORDS (optional): The module's `decision-records.md`

## Core Principles

- One canonical place per concept. Define each term exactly once
- Do NOT generate:
  - Obligations (MUST / SHOULD / MAY), behavioral conditions, guarantee scopes
  - Concrete values (durations, start points, limits, counts)
  - Source code, function names, type names, file paths
- Keep the **essential properties that identify the concept** in its definition.
  Example: "the right, among registrations of the same key, to proceed to registration"
  is the meaning of the concept, not a restated rule
- Rules, obligations, and concrete values belong in DRs, requirements, and
  specifications. The dictionary only points to them under **Related rules**
- Do NOT invent terms that are not in DICTIONARY TERMS

---

## Step 0: Preserve the Existing Dictionary

If **EXISTING DICTIONARY** is provided:

- Keep every existing UD heading, definition, and item unless DICTIONARY TERMS marks it CHANGED
- NEVER renumber UD-IDs
- NEVER delete a term. A deprecated term keeps its heading, sets `確定状況: 廃止` (or `Settlement: Deprecated`), and states the reason (and successor UD-ID, if any) in its definition
- Never reuse a deprecated number
- Keep the existing Change History table unchanged (the version bump happens later, in spec Phase 12)
- Keep existing entries in the Inconsistencies section until they are verified as resolved
- Keep the existing category chapters and the position of each term; do not reorder existing headings

## Step 1: Assign and Group Terms

- Use the UD-IDs given in DICTIONARY TERMS. A NEW term without an ID gets the next number after the highest existing one
- Format: `UD-NNN`, three digits, zero-padded (`UD-001`)
- Group terms into one chapter per category (`## N. <category>`). Sub-groups may use `### N.M` with `#### UD-NNN` headings
- Place a new term in the chapter it belongs to, next to related terms. The UD-ID order does not have to match the heading order

## Step 2: Write Each Term

Write one heading per term: `### UD-NNN <term>` (or `#### UD-NNN <term>` inside a sub-group).
Put the definition paragraph directly under the heading, then the items as a bullet list.
If the definition itself contains a bullet list, write `項目:` (or `Items:`) on its own line before the item list.
**Do NOT put the term list in a single table.**

| Item                          | Content                                                                                                       | Optional |
| ----------------------------- | ------------------------------------------------------------------------------------------------------------- | -------- |
| Definition (paragraph)        | The meaning and the essential identifying properties                                                          | No       |
| Abstraction (抽象度)          | One of the levels defined in the dictionary (principle, concept, state, decision, time, scope, concrete, ...) | No       |
| Perspective (立場)            | Whose viewpoint: client / server / common                                                                     | No       |
| Settlement (確定状況)         | One of the four values below                                                                                  | No       |
| Broader concept (上位概念)    | The concept this term is a kind of, or a value of                                                             | Yes      |
| Components (構成要素)         | Concepts that make up this concept                                                                            | Yes      |
| States (状態)                 | Concepts that represent states this concept takes                                                             | Yes      |
| Distinguish from (対立・区別) | Concepts with a different meaning that are easy to confuse. Not for banning synonyms                          | Yes      |
| Related (関連)                | Related concepts not covered above                                                                            | Yes      |
| Evidence (定義根拠)           | The source passage that grounds the meaning (REQ / DR / design note)                                          | No       |
| Related rules (関連規則)      | DR decisions, requirements, or rules that use this concept to set obligations or values                       | Yes      |

Reference other terms by UD-ID and term (`UD-003 処理権`).

### Relation Direction

Broader concept, components, and states are written **only from this term toward the other**.
Do not write the reverse relation.
Example: a state value lists the state concept as its broader concept; the state concept does
not enumerate its values.

### Settlement

| Settlement                                                    | Meaning                                                                         |
| ------------------------------------------------------------- | ------------------------------------------------------------------------------- |
| 確定 (Confirmed)                                              | The meaning is settled                                                          |
| 確定 (実現可能性は未確認) (Confirmed, feasibility unverified) | Meaning settled, but feasibility against sibling issues etc. is not yet checked |
| 未確定 (Unsettled)                                            | The meaning or content is not yet decided                                       |
| 廃止 (Deprecated)                                             | The term is no longer used. The heading and UD-ID stay                          |

## Step 3: Record Inconsistencies

For each INCONSISTENT entry in DICTIONARY TERMS:

- Do NOT silently reinterpret the DR to match the dictionary, or the dictionary to match the DR
- Add one subsection per conflict to the Inconsistencies section with these items:
  Location (DR, decision, version, quoted text), Conflict (what differs, with the UD-IDs involved),
  Verification (which side is wrong and why), Resolution (fix the dictionary / `dr --refine` / DR replacement), Status `Open`
- One conflict may involve several UD-IDs; write it once, not once per UD-ID
- Mark an entry resolved only when the input states that the revised DR text was checked against the dictionary.
  Then quote the revised text and state the `decision-records.md` version that was checked

## Step 4: Apply Language

Follow the LANG parameter exactly.

- `ja`: Body in Japanese, technical terms may stay in English. Translate headings, and use the Japanese item labels
  (抽象度・立場・確定状況・上位概念・構成要素・状態・対立・区別・関連・定義根拠・関連規則) and the Japanese
  abstraction levels and settlement values shown in the TEMPLATE comments
- `en`: English throughout; use the English item labels of the TEMPLATE

## Step 5: Change History

- Keep the three columns: Date / Version / Description
- In Description, list the documents whose impact was checked and the result

---

## Output

Output ONLY the generated markdown document.
Do not include explanations or meta-commentary.

**Self-check before output**:

- No MUST / SHOULD / MAY, conditions, or concrete values inside a definition
- Every term has definition, abstraction, perspective, settlement, and evidence
- No UD-ID appears twice as a heading; no existing UD-ID is missing
- No reverse relations under broader concept / components / states
- No term table
