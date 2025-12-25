---
title: "Implementation: {{FEATURE_NAME}}"
Based on: specifications.md v{{SPEC_VERSION}}
Status: Draft
---

## 1. Overview

### 1.1 Purpose

{{WHAT_THIS_IMPLEMENTATION_DEFINES}}

### 1.2 Module Location

- File: `{{FILE_PATH}}`
- Export: {{EXPORT_TYPE}} (internal/public)

---

## 2. Type Definitions

### 2.1 Input Type

```typescript
{
  {
    <INPUT_TYPE_DEFINITION>;
  }
}
```

> NOTE: The following code blocks contain explicit placeholders and are not valid TypeScript until filled.

### 2.2 Output Type

```typescript
{
  {
    <OUTPUT_TYPE_DEFINITION>;
  }
}
```

### 2.3 Conceptual Types (Informative)

The following types are referenced **conceptually**
to explain the implementation constraints.
They are not required to exist as concrete exported types.

{{CONCEPTUAL_TYPE_DESCRIPTION}}

---

## 3. Function Contract

### 3.1 Signature

```typescript
{
  {
    FUNCTION_SIGNATURE;
  }
}
```

### 3.2 Preconditions

- {{PRECONDITION_1}}
- {{PRECONDITION_2}}

### 3.3 Postconditions

- {{POSTCONDITION_1}}
- {{POSTCONDITION_2}}

### 3.4 Invariants

- {{INVARIANT_1}}

---

## 4. Implementation Constraints

### 4.1 Decision Logic

Derived from specifications Decision Rules:

| Step | Check                | Implementation Note       |
| ---: | -------------------- | ------------------------- |
|    1 | {{DECISION_CHECK_1}} | {{IMPLEMENTATION_NOTE_1}} |
|    2 | {{DECISION_CHECK_2}} | {{IMPLEMENTATION_NOTE_2}} |
|    3 | {{DECISION_CHECK_3}} | {{IMPLEMENTATION_NOTE_3}} |

### 4.2 Instance Checks

Implementation MAY rely on runtime instance checks
as constrained by the specifications assumptions.

{{INSTANCE_CHECK_DESCRIPTION}}

### 4.3 Performance Constraints

- Time Complexity: {{TIME_COMPLEXITY}}
- Space Complexity: {{SPACE_COMPLEXITY}}
- {{OTHER_CONSTRAINTS}}

---

## 5. Dependencies

### 5.1 Internal Dependencies

| Module             | Purpose           |
| ------------------ | ----------------- |
| {{INTERNAL_DEP_1}} | {{DEP_PURPOSE_1}} |
| {{INTERNAL_DEP_2}} | {{DEP_PURPOSE_2}} |

### 5.2 External Dependencies

- None (zero-dependency requirement)

---

## 6. Error Handling

### 6.1 Error Cases

| Condition        | Behavior       |
| ---------------- | -------------- |
| {{ERROR_CASE_1}} | {{BEHAVIOR_1}} |
| {{ERROR_CASE_2}} | {{BEHAVIOR_2}} |

### 6.2 Error Strategy

{{ERROR_STRATEGY_DESCRIPTION}}

---

## 7. Specifications Traceability

| Spec Section   | Implementation Section |
| -------------- | ---------------------- |
| {{SPEC_REF_1}} | {{IMPL_REF_1}}         |
| {{SPEC_REF_2}} | {{IMPL_REF_2}}         |

---

## 8. Change History

| Date     | Version | Description            |
| -------- | ------- | ---------------------- |
| {{DATE}} | 1.0     | Initial implementation |
