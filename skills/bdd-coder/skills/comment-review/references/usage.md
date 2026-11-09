---
title: comment-review Usage
description: Invocation examples, when to use each form, and related documents
---

<!-- textlint-disable
  ja-technical-writing/sentence-length -->

## comment-review Usage

## Examples

```bash
# Review the comments in uncommitted changes
/bdd-coder:comment-review

# Review the comments in every file changed on the branch (base resolved automatically)
/bdd-coder:comment-review --branch

# Review a directory (searched recursively)
/bdd-coder:comment-review skills/deckrd/skills/deckrd/scripts/libs

# Review specific files or a glob
/bdd-coder:comment-review scripts/init.sh "scripts/libs/*.lib.sh"
```

## When to Use

| Trigger                                        | Recommended form |
| ---------------------------------------------- | ---------------- |
| After writing code with AI help, before commit | (no arguments)   |
| Before opening a PR                            | `--branch`       |
| Cleaning up comments in existing code          | explicit paths   |

Large directories produce long drafts. Review one directory or a few files at a time.

## Reference

- Comment rules: [code-comments.md](../../bdd-coder/references/guidelines/code-comments.md)
- Procedure: [comment-refiner Role](../../bdd-coder/references/roles/comment-refiner.md)
- Agent definition: [agents/comment-refiner.md](../../../agents/comment-refiner.md)
