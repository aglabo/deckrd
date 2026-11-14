---
title: "spec Phase 11: External Spec Review & Cleanup"
description: Strip implementation detail and requirements restatement from each generated file
---

<!-- textlint-disable
    ja-technical-writing/no-exclamation-question-mark,
    ja-technical-writing/sentence-length,
    ja-technical-writing/max-comma -->
<!-- markdownlint-disable line-length -->

## Phase 11: External Spec Review & Cleanup (max 2 rounds)

## Standalone Invocation

```bash
/deckrd spec --phase spec-review
```

## Preconditions

| 必要な入力                 | 生成元   | 欠けているとき          |
| -------------------------- | -------- | ----------------------- |
| `specifications/` の生成物 | Phase 10 | Phase 10 を先に実行する |

## Steps

After all specification files are written, review each file.
Ensure each file contains **only external specification content**.

### Step 11-1: Self-Scan

Read each generated file and flag every passage that matches a removal criterion:

| Criterion                | Examples                                                                                                   | Action                            |
| ------------------------ | ---------------------------------------------------------------------------------------------------------- | --------------------------------- |
| Implementation detail    | Function names, type signatures, file paths, class names                                                   | Remove or rewrite                 |
| Requirements restatement | Sentences copied verbatim from `requirements.md`; FR/NFR bullet re-listing                                 | Remove                            |
| Notes / impl hints       | `<!-- impl: ... -->`, `> Note for impl:` comments                                                          | **Keep** (pass-through to `impl`) |
| Missing class            | A row in Sections 3–5 with an empty or unknown `Class`                                                     | Suggest a class                   |
| Misclassification        | A caller-observable item marked `Guarantee`; an internal property marked `Contract`                        | Suggest the correct class         |
| Extension overreach      | An `Extension` row with an implementation obligation, or with no source in REQUIREMENTS / confirmed design | Rewrite or remove                 |

Classes follow "Item Classification" in `assets/prompts/specifications.prompt.md`.

**Do NOT remove:**

- Behavioral rules expressed in declarative form
- Edge cases and invariants
- Interface contracts (pre/post-conditions without code)
- Cross-unit interaction ordering
- Notes explicitly marked as implementation hints
- `Extension` rows that have a source (they record scope excluded from `impl` and `tasks`)

### Step 11-1b: Dictionary Consistency

`universal-dictionary.md` が存在する場合、ルール (`deckrd-rule-document-model.md`) の
「整合性の検証」に従って次を確かめる。

| 検証       | 確かめること                                                         | 方法     |
| ---------- | -------------------------------------------------------------------- | -------- |
| 参照整合性 | 仕様書中の `UD-NNN` がすべて辞書の見出しに存在し、意図した概念を指す | 機械検査 |
| 定義整合性 | 仕様書が辞書の用語を別の意味で使っていない・定義し直していない       | レビュー |
| 責務整合性 | 辞書が仕様書の義務・保証・具体値を重複して定義していない             | レビュー |

次のコマンドで参照切れを検出する。出力は空でなければならない。

```bash
dict=docs/.deckrd/<namespace>/<module>/universal-dictionary.md
comm -23   <(grep -rhoE "UD-[0-9]{3}" docs/.deckrd/<namespace>/<module>/specifications/ | sort -u)   <(grep -oE "^#{2,6} UD-[0-9]{3} " "$dict" | awk '{print $2}' | sort -u)
```

指摘は Step 11-2 の提示に含める。辞書に無い新しい概念が見つかった場合は、仕様書で定義せず、
Phase 9 に戻って辞書へ追加するか、Section 7 (Open Questions) に辞書への追加候補として記録する。

### Step 11-2: Present Findings to User

For each flagged passage, present a concise diff-style summary:

```bash
[Spec Review] specifications-auth.md

REMOVE (implementation detail):
  Line 42: "calls authenticate() function and checks return value"
  → Suggest: "performs authentication and evaluates the result"
  Accept? (Y / keep / custom)

REMOVE (requirements restatement):
  Line 67: "FR-03: The system SHALL validate email format"
  → This duplicates requirements.md FR-03. Remove?
  Accept? (Y / keep)
```

If no issues found:

```bash
[Spec Review] No external-spec violations found in <filename>.
```

### Step 11-3: Apply Changes

For each accepted removal or rewrite:

1. Edit the file in-place
2. If a passage was rewritten, append the original as an impl note:

   ```yaml
   <!-- impl-note: original said "calls authenticate() function" -->
   ```

3. After all files are cleaned, show a final summary:

   ```bash
   [Cleanup Complete]
   - specifications-auth.md: 2 removed, 1 rewritten
   - specifications-notify.md: no changes
   ```

**Termination conditions:**

1. User approves all changes with "Y", "OK", "承認", or equivalent
2. 2 rounds completed — record any remaining disputed items in Section 7 (Open Questions)

## Output

Cleaned specification files, and the user's approval that gates Phase 12.

## Next Phase

[Phase 12: Version Bump](12-version-bump.md)
