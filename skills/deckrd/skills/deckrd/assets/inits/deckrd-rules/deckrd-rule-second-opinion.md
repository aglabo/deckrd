# Deckrd Rule: Second Opinion via Codex

<!-- textlint-disable
  ja-technical-writing/sentence-length,
  -->

Use `/deckrd:deckrd-review` to get an independent critical review from codex
When Claude's own analysis may be insufficient or biased.

## When to Invoke (REQUIRED)

Invoke automatically in these situations:

| Situation                                                          | Recommended focus |
| ------------------------------------------------------------------ | ----------------- |
| After `/deckrd review req` or `/deckrd review spec`                | `risk`            |
| Before transitioning to the next phase (e.g., spec → impl)         | (none — balanced) |
| When a design decision has no clear winner                         | `consistency`     |
| When `/deckrd impl` or `/deckrd tasks` result feels underspecified | `completeness`    |

## When to Invoke (RECOMMENDED)

Consider invoking in these situations:

| Situation                                         | Recommended focus |
| ------------------------------------------------- | ----------------- |
| An implementation approach has failed twice       | `feasibility`     |
| Requirements feel ambiguous after `/deckrd req`   | `completeness`    |
| Specifications reference external systems heavily | `risk`            |

## How Codex Differs from Claude Review

Claude (`/deckrd review`) and codex (`/deckrd:deckrd-review <phase>`) play different roles:

| Aspect      | Claude review                 | Codex second opinion            |
| ----------- | ----------------------------- | ------------------------------- |
| Perspective | Primary analyst, constructive | Independent critic, adversarial |
| Goal        | Mature the document           | Challenge assumptions           |
| Output      | Findings + DR entries         | Risks, gaps, blind spots        |
| Tone        | Collaborative                 | Devil's advocate                |

## Common Rationalizations

| Rationalization                               | Reality                                                                                                                         |
| --------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------- |
| "I'm confident, no need for a second opinion" | Confidence correlates poorly with correctness. Moments of certainty are exactly when blind spots hide.                          |
| "Invoking codex is expensive"                 | Debugging a wrong decision downstream (spec/impl/commit) is more expensive than one review call.                                |
| "A second opinion is just noise"              | Noise comes from an unscoped prompt, not from the practice itself. Don't skip it on the REQUIRED situations in the table above. |

## Handling Codex Findings

- Accept: Note which findings to act on before the next command
- Reject: Always provide a reason — silent rejection is not allowed
- Follow-up: Use `q` to ask codex clarifying questions in the same session
- Never skip second opinion on `req` or `spec` before moving to the next phase
  on features that affect external interfaces or data persistence
