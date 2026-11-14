---
title: "Universal Dictionary: {{MODULE_ID}}"
module: "{{MODULE_ID}}"
status: Draft
version: 1.0.0
created: "{{ DATE }}"
---

<!-- textlint-disable
  ja-technical-writing/sentence-length,
  ja-technical-writing/max-comma -->
<!-- markdownlint-disable no-duplicate-heading line-length -->

> **Position of this document**
> This dictionary is the single canonical source of the terms and concepts of {{MODULE_ID}}.
> Every design phase (requirements, decision records, specifications, implementation, tasks) shares it.
> With this dictionary, a reader interprets the same term with the same meaning in any DR or specification.
> It does not replace design decisions: DRs own decisions, requirements and specifications own
> requirements, guarantees, and behavior, implementation and tasks own realization and verification.

## 1. Rules of this Dictionary

### 1.1 Scope

- This dictionary defines concepts, their identity, relations between concepts, and perspective, and assigns stable UD-IDs.
- It does not define obligations (MUST / SHOULD), behavioral conditions, guarantee scopes, or concrete values such as start points and durations.
  The documents listed under **Related rules** are canonical for those.
- The essential properties that identify a concept stay in its definition.
- Other documents cite terms by UD-ID and do not redefine them. No document may use a term with a meaning different from this dictionary.
- When a definition here conflicts with an Accepted DR, verify which side is wrong and resolve it case by case.
  Do not silently reinterpret the DR because this dictionary is canonical (see the Inconsistencies section).
- Do not fix only the dictionary. When a definition changes, align the documents that reference it in the same change.

### 1.2 Items

Each term has a heading `UD-NNN <term>` followed by its definition paragraph, then the items below.

| Item             | 項目       | Meaning                                                                                 |
| ---------------- | ---------- | --------------------------------------------------------------------------------------- |
| Abstraction      | 抽象度     | One of the levels in 1.3                                                                |
| Perspective      | 立場       | Whose viewpoint the concept belongs to (client / server / common)                       |
| Settlement       | 確定状況   | One of the values in 1.4                                                                |
| Broader concept  | 上位概念   | The concept this term is a kind of, or a value of                                       |
| Components       | 構成要素   | Concepts that make up this concept                                                      |
| States           | 状態       | Concepts that represent states this concept takes                                       |
| Distinguish from | 対立・区別 | Concepts with a different meaning that are easy to confuse. Not for banning synonyms    |
| Related          | 関連       | Related concepts not covered above                                                      |
| Evidence         | 定義根拠   | The passage that grounds the meaning of the definition                                  |
| Related rules    | 関連規則   | DR decisions, requirements, or rules that use this concept to set obligations or values |

- Broader concept, Components, and States are written only from this term toward the other. Do not write the reverse relation.
  For example, a state value lists the state concept as its broader concept; the state concept does not enumerate its values.
- Broader concept, Components, States, Distinguish from, Related, and Related rules are omitted when they do not apply.
- The UD-ID leads the heading. Numbers are never renumbered, and deprecated numbers are never reused.
  The numeric order does not have to match the order of the headings.

### 1.3 Abstraction Levels

| Level          | Meaning                                       |
| -------------- | --------------------------------------------- |
| Principle      | Concepts of guarantee scope and policy        |
| Concept        | Artifacts, actors, units of operation         |
| State/Decision | States, classifications, results of decisions |
| Time/Scope     | Deadlines, periods, points in time, ranges    |
| Concrete       | Values, formats, individual responses         |

<!-- Japanese labels: 原則 / 概念 / 状態・判断 / 時間・範囲 / 具体. Keep only the levels in use. -->

### 1.4 Settlement

| Value                              | Meaning                                                                       |
| ---------------------------------- | ----------------------------------------------------------------------------- |
| Confirmed                          | The meaning is settled                                                        |
| Confirmed (feasibility unverified) | The meaning is settled, but feasibility against sibling issues is not checked |
| Unsettled                          | The meaning or content is not yet decided                                     |
| Deprecated                         | The term is no longer used. The heading and UD-ID stay                        |

<!-- Japanese labels: 確定 / 確定 (実現可能性は未確認) / 未確定 / 廃止 -->

---

## 2. {{CATEGORY_1}}

<!--
Group terms into one chapter per category (## N. <category>). Sub-groups may use ### N.M with #### UD-NNN headings.
Within and across chapters, the UD-ID order does not have to match the heading order.
Do not put the terms in a single table.
If the definition itself contains a bullet list, write "Items:" (項目:) on its own line before the item list.
A deprecated term keeps its heading, sets Settlement: Deprecated, and states the reason (and successor UD-ID, if any) in the definition.
-->

### UD-001 {{TERM_1}}

{{DEFINITION_1}}

- Abstraction: {{ABSTRACTION_1}}
- Perspective: {{PERSPECTIVE_1}}
- Settlement: {{SETTLEMENT_1}}
- Broader concept: {{BROADER_1}} <!-- optional -->
- Components: {{COMPONENTS_1}} <!-- optional -->
- States: {{STATES_1}} <!-- optional -->
- Distinguish from: {{DISTINGUISH_1}} <!-- optional -->
- Related: {{RELATED_1}} <!-- optional: UD-xxx -->
- Evidence: {{EVIDENCE_1}} <!-- REQ / DR / design note. A definition moved from another document: "migrated from <doc> vX.Y.Z <section>" -->
- Related rules: {{RELATED_RULES_1}} <!-- optional: DR-xx decision N / REQ-xx / R-xxx -->

---

## 3. Inconsistencies with DRs

<!--
Record each conflict between a definition here and an Accepted DR, with the verification of which side is wrong and the result.
Do not reinterpret either side. Mark Resolved only after the revised DR text has been checked against this dictionary.
One entry may involve several UD-IDs. If none: "None identified."
-->

The DR text was checked against `decision-records.md` v{{DR_VERSION}}.

### 3.1 {{DR_ID}} {{DECISION}}: {{SUBJECT}}

- Location: {{DR_ID}} {{DECISION}} (v{{DR_VERSION_AT_FINDING}}) "{{QUOTED_TEXT}}"
- Conflict: {{WHAT_DIFFERS_FROM_UD_XXX}}
- Verification: {{WHICH_SIDE_IS_WRONG_AND_WHY}}
- Resolution: {{FIX_DICTIONARY_OR_DR_REFINE_OR_DR_REPLACE}}
- Status: Open <!-- Open / Resolved (state the revised DR text and the version checked) -->

<!--
Optional: a table of the DR decisions checked against the dictionary.

| Decision | DR text (summary) | UD checked | Result     |
| -------- | ----------------- | ---------- | ---------- |
| N        | {{SUMMARY}}       | UD-xxx     | Consistent |
-->

---

<!--
Optional section: use it when terms are moved into this dictionary from IDs defined in other documents (e.g. TM-xx).
When used, place it before Change History and renumber Change History.

## 4. Mapping from Former Term IDs

The term IDs defined in `<doc>` v<version> are retired and moved to the UD-IDs below.

| Former ID | Former term | UD-ID  |
| --------- | ----------- | ------ |
| TM-01     | {{TERM}}    | UD-xxx |

Content removed from a definition while moving it (obligations, conditions) and the documents that now own it are noted below the table.

---
-->

## 4. Change History

<!-- SemVer for the dictionary:
     MAJOR = meaning of a definition changed, term deprecated
     MINOR = term added, structural change (item added, etc.)
     PATCH = clarification that keeps the meaning, relation / evidence added, typo
     Keep frontmatter `version` equal to the newest row.
     In Description, list the documents whose impact was checked (found with `grep -rn "UD-NNN"`) and the result.
     See docs/.deckrd/rules/deckrd-rule-document-versioning.md
     and docs/.deckrd/rules/deckrd-rule-document-model.md -->

| Date     | Version | Description                        |
| -------- | ------- | ---------------------------------- |
| {{DATE}} | 1.0.0   | Initial release (UD-001 to UD-NNN) |
