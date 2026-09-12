---
title: bdd-coder-review Usage
description: Invocation examples, when to use each form, and related documents
---

<!-- textlint-disable
  ja-technical-writing/sentence-length -->

## bdd-coder-review Usage

## Examples

```bash
# Review uncommitted changes (most common — right after /bdd-coder:bdd-coder)
/bdd-coder:bdd-coder-review

# Review the whole branch before opening a PR (base resolved automatically)
/bdd-coder:bdd-coder-review --branch

# Review the whole branch against an explicit base
/bdd-coder:bdd-coder-review --branch develop

# Review specific files
/bdd-coder:bdd-coder-review src/parser.ts src/parser.spec.ts

# Review with an explicit task ID and coverage command
/bdd-coder:bdd-coder-review T-01-02-01 --coverage-cmd "pnpm run test:coverage"
```

## When to Use

| Trigger                                        | Recommended form |
| ---------------------------------------------- | ---------------- |
| `/bdd-coder:bdd-coder` finished, before commit | (no arguments)   |
| Before opening a PR                            | `--branch`       |
| A specific file feels over-complex             | explicit paths   |

Inside `/bdd-coder:bdd-coder`, Phase 4 already runs this review; invoking it manually is unnecessary there.

## Reference

- Agent definition: [agents/code-reviewer.md](../../../agents/code-reviewer.md)
- CRAP formula and thresholds: [bdd-coder/assets/test-quality.md](../../bdd-coder/assets/test-quality.md)
- Phase 4 in the BDD flow: [bdd-coder/references/workflow.md](../../bdd-coder/references/workflow.md)
