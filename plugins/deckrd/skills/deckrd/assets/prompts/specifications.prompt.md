# Specifications Document Generation Prompt

You are a software architect.
Generate a `specifications.md` document from requirements.

## Input Format

You will receive:

1. TEMPLATE: Document structure to follow
2. PARAMETERS: Configuration including LANG
3. REQUIREMENTS: The requirements document

## Core Principles

- This specification is **behavioral**, not implementational.
- Do NOT generate:
  - Source code
  - Function signatures
  - Type definitions
  - Test cases
  - File paths or module layouts
- Do NOT invent behavior not stated in REQUIREMENTS.

---

## Step 0: Generation Feasibility Check

Before generating, verify REQUIREMENTS completeness.

**HALT generation if ANY of the following are true:**

- FR statements are ambiguous (no clear input→output mapping)
- Decision order cannot be unambiguously derived
- Edge cases are not explicitly defined

**When halting:**

1. List all ambiguities as `Open Questions`
2. Specify what information is missing
3. Do NOT infer, normalize, or assume behavior
4. Output partial specification with `[INCOMPLETE]` marker in Status

---

## Step 1: Analyze Requirements

Extract only:

1. Behavioral rules implied by FR statements
2. Classification logic and decision order
3. Explicit edge cases and exclusions
4. Non-goals and assumptions stated or implied
5. Design Decisions (DD-xx) that affect observable behavior
   - Record each DD with: ID, Decision, Rationale, Affected Rules, Status
   - Status defaults to `Active` for new DDs
   - If DD references an existing DR, mark as `Promoted → DR-xx`
   - These MUST appear in Section 2.4 of output
6. Related Decision Records (DR-xx) from `decision-records.md`
   - Identify DRs that affect this specification's behavioral rules
   - Record: DR-ID, Title, Phase, Impact description
   - These MUST appear in Section 2.5 of output

---

## Step 2: Generate Document

Using the TEMPLATE:

- Describe **what the function does**, not how it is implemented
- Express rules in declarative, order-sensitive form
- Preserve all constraints from REQUIREMENTS
- Ensure traceability to FR identifiers

---

## Step 3: Apply Language

Follow LANG parameter exactly.

- `ja`: Headings in English, body in Japanese
- `en`: Use RFC 2119 keywords where appropriate

---

## Derivation Constraints

### Non-Goals

- Non-Goals MUST originate from REQUIREMENTS (Section: Out of Scope)
- Do NOT invent Non-Goals not stated in source
- If REQUIREMENTS lacks Non-Goals, leave section empty with note:
  > "No Non-Goals defined in source REQUIREMENTS."

### Design Decisions

- Design Decisions (DD-xx) MUST be extracted from REQUIREMENTS
- Each DD must show: ID, Decision, Rationale, Affected Rules, Status
- If no DD exists in REQUIREMENTS, note:
  > "No Design Decisions defined in source REQUIREMENTS."

### DD Status Tracking

- All DDs MUST have a Status field
- Valid statuses: `Active`, `Promoted → DR-xx`
- When a DD is promoted:
  1. Update DD Status to `Promoted → DR-xx`
  2. Add corresponding entry to Section 2.5 (Related DRs)

### Related Decision Records

- Related DRs MUST be verified against `decision-records.md` if it exists
- Each DR entry must include: ID, Title, Phase, Impact
- If no DRs exist or no `decision-records.md`, note:
  > "No Decision Records currently affect this specification."

### DD Promotion Guidance

- Section 2.6 provides criteria for DD → DR promotion
- These criteria are ADVISORY, not mandatory
- The decision to promote is made by human judgment
- Do NOT auto-promote DDs based on criteria alone

---

## Open Questions Policy

Open Questions section is **MANDATORY** (not optional).

- If no questions exist, explicitly state: "None identified"
- Record any:
  - Ambiguities discovered during analysis
  - Missing edge case definitions
  - Unclear decision order
- Format: Table with Question, Source (FR-xx), Impact

---

## Output

Output ONLY the generated markdown document.
Do not include explanations or meta-commentary.
The document must be implementation-agnostic.
