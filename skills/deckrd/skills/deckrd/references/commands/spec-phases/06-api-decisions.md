---
title: "spec Phase 6: External API Decision Loop"
description: Identify and confirm every external interface before generating specifications
---

<!-- textlint-disable
    ja-technical-writing/no-exclamation-question-mark,
    ja-technical-writing/sentence-length,
    ja-technical-writing/max-comma -->
<!-- markdownlint-disable line-length -->

## Phase 6: External API Decision Loop (max 3 rounds)

## Standalone Invocation

```bash
/deckrd spec --phase api-decisions
```

## Preconditions

| 必要な入力                     | 生成元  | 欠けているとき                                       |
| ------------------------------ | ------- | ---------------------------------------------------- |
| `requirements/requirements.md` | `req`   | `req` を先に実行する                                 |
| EXTERNAL DESIGN NOTES          | Phase 5 | Context Ledger から読む。無ければ Phase 5 を実行する |

## Steps

Before generating specifications, identify and confirm all external interfaces.

### Step 6-1: Extract API Candidates

Read `requirements/requirements.md` and identify candidates:

- External services called (REST API, GraphQL, gRPC, message queue, etc.)
- External services that call this module (webhooks, callbacks)
- Shared data stores accessed by multiple modules (DB, cache, file storage)
- CLI / SDK interfaces exposed to end users or other tools

### Step 6-2: Ask API Clarification Questions

For each candidate, ask the user to confirm or decide:

**Rules**:

- Ask **at most 3 questions per round**
- Prefer concrete choices (A/B/C) or Yes/No over open-ended questions
- Accumulate confirmed decisions as **API DECISIONS**

Example question patterns:

```bash
[External API] The requirements mention sending email notifications.
Q1. Which service will you use?
    A) SendGrid  B) AWS SES  C) SMTP (self-hosted)  D) Not decided yet

Q2. Is the API key management in scope for this spec?
    Yes / No

Q3. Should failure to send email be fatal (block the operation) or non-fatal?
    A) Fatal  B) Non-fatal (log and continue)
```

**Termination conditions** (stop as soon as either is met):

1. User responds with "十分", "以上です", "OK", "done", or equivalent
2. All extracted API candidates have a confirmed decision (service, protocol, error handling policy)

### Step 6-3: Summarize API Decisions

Compile confirmed decisions as **API DECISIONS** block:

```text
API DECISIONS:
- Email notification: SendGrid REST API; non-fatal on failure
- User data store: PostgreSQL via existing DB module; read-only from this spec
- CLI interface: exposed as subcommand `deckrd spec`; no SDK
```

## Output

Append **API DECISIONS** to the Context Ledger.

## Next Phase

[Phase 7: Public Function Interface Decision Loop](07-function-decisions.md)
