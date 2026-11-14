---
title: "spec Phase 13: Second Opinion via Codex"
description: Get an independent review of the specifications before transitioning to impl
---

<!-- textlint-disable
    ja-technical-writing/no-exclamation-question-mark,
    ja-technical-writing/sentence-length,
    ja-technical-writing/max-comma -->
<!-- markdownlint-disable line-length -->

## Phase 13: Second Opinion via Codex

## Standalone Invocation

```bash
/deckrd spec --phase second-opinion
```

## Preconditions

| 必要な入力                  | 生成元   | 欠けているとき          |
| --------------------------- | -------- | ----------------------- |
| 版上げ済みの specifications | Phase 12 | Phase 12 を先に実行する |

## Steps

After Phase 12 completes, invoke `/deckrd:deckrd-review spec` before transitioning to `impl`.

This step is **REQUIRED** when the specifications:

- Reference external systems or third-party APIs heavily
- Define data persistence or schema contracts
- Introduce new module boundaries or public interfaces

In all other cases, this step is **RECOMMENDED** before every `spec → impl` transition.

**Execution:**

```bash
/deckrd:deckrd-review spec
```

Focus: balanced review — correctness, completeness, consistency across behavioral contracts.

**Handling findings:**

- Accept: Note which findings to act on before running `impl`
- Reject: Always provide a rationale — silent rejection is not allowed
- If findings require revisions, return to Phase 10 and regenerate; then re-run Phases 11-13

See `docs/.deckrd/rules/deckrd-rule-second-opinion.md` for the full rule.

## Output

Accepted findings recorded, and the decision to proceed to `impl`.

## Next Phase

最終フェーズ。`spec.md` の Session Update に戻る。

[spec Command](../spec.md)
