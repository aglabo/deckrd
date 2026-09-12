---
title: spec Command
description: Derive technically verifiable behavioral specifications from requirements
---

<!-- textlint-disable
    ja-technical-writing/no-exclamation-question-mark,
    ja-technical-writing/sentence-length,
    ja-technical-writing/max-comma -->
<!-- markdownlint-disable line-length -->

## spec Command

Derive technically verifiable behavioral goals and constraints from requirements.

このファイルは目次であり、フェーズの手順は含まない。手順は `spec-phases/` 配下にある。

## Usage

```bash
/deckrd spec                          # 全フェーズを Phase 1 から順に実行
/deckrd spec --phase design-draft     # 単一フェーズだけ再実行
```

`--phase` には下表の slug を渡す。単一フェーズの再実行は `spec` 完了後にも行うため、
順序ゲートの対象外とする。

## Preconditions

- Session must exist with active module
- `req` must be completed for active module
- `requirements/requirements.md` must exist

## Execution Flow

**下表の「読むタイミング」欄を見て、該当フェーズの開始前に `spec-phases/<ファイル名>` を Read すること。**
記憶や推測でフェーズを実行してはならない。

| Phase | slug                 | ファイル                                                         | 内容                          | 読むタイミング                               |
| ----- | -------------------- | ---------------------------------------------------------------- | ----------------------------- | -------------------------------------------- |
| 1     | `read-requirements`  | [01-read-requirements.md](spec-phases/01-read-requirements.md)   | 要件読解・コードベース調査    | spec 開始時。常に最初                        |
| 2     | `prior-art`          | [02-prior-art.md](spec-phases/02-prior-art.md)                   | PoC / 参考 PR の調査          | Phase 1 の Step 1-2 と並行して開始           |
| 3     | `design-draft`       | [03-design-draft.md](spec-phases/03-design-draft.md)             | 設計方針の起草                | Phase 1 と Phase 2 の agent が両方完了した後 |
| 4     | `user-review`        | [04-user-review.md](spec-phases/04-user-review.md)               | ユーザーレビュー (対話)       | DESIGN DRAFT ができた直後                    |
| 5     | `design-dialogue`    | [05-design-dialogue.md](spec-phases/05-design-dialogue.md)       | 外部設計対話 (AI 内部推論)    | CONFIRMED DESIGN が確定した後                |
| 6     | `api-decisions`      | [06-api-decisions.md](spec-phases/06-api-decisions.md)           | 外部 API の決定 (対話)        | Phase 5 完了後。ドキュメント生成の前         |
| 7     | `function-decisions` | [07-function-decisions.md](spec-phases/07-function-decisions.md) | 公開関数の決定 (対話)         | Phase 6 完了後。ドキュメント生成の前         |
| 8     | `split-assessment`   | [08-split-assessment.md](spec-phases/08-split-assessment.md)     | 分割判定・版の baseline 取得  | Phase 7 完了後。FR 数によらず必ず通る        |
| 9     | `generate`           | [09-generate.md](spec-phases/09-generate.md)                     | ドキュメント生成              | SPLIT PLAN が確定した後                      |
| 10    | `spec-review`        | [10-spec-review.md](spec-phases/10-spec-review.md)               | 外部仕様レビューと除去 (対話) | 生成直後。版上げの前                         |
| 11    | `version-bump`       | [11-version-bump.md](spec-phases/11-version-bump.md)             | 版上げ                        | Phase 10 をユーザーが承認した後              |
| 12    | `second-opinion`     | [12-second-opinion.md](spec-phases/12-second-opinion.md)         | codex による second opinion   | Phase 11 完了後。`impl` へ移る前             |

## Context Ledger

フェーズ間で受け渡す名前付きブロックは、次のファイルに記録する。

```bash
temp/deckrd-work/<namespace>/<module>/spec-context.md
```

各フェーズは自分の Output ブロックを、同名の `##` 見出しの下に追記または上書きする。

| ブロック                | 書くフェーズ |
| ----------------------- | ------------ |
| `REQ SUMMARY`           | Phase 1      |
| `REQ VERSION`           | Phase 1      |
| `CODEBASE CONTEXT`      | Phase 1      |
| `PRIOR ART`             | Phase 2      |
| `DESIGN DRAFT`          | Phase 3      |
| `CONFIRMED DESIGN`      | Phase 4      |
| `EXTERNAL DESIGN NOTES` | Phase 5      |
| `API DECISIONS`         | Phase 6      |
| `FUNCTION DECISIONS`    | Phase 7      |
| `SPLIT PLAN`            | Phase 8      |
| `BASELINE VERSION`      | Phase 8      |
| `BASELINE HISTORY`      | Phase 8      |

`--phase` で単一フェーズを実行するときは、そのフェーズの Preconditions 表に従い、
このファイルから前提ブロックを読む。ledger に無いものは、生成元フェーズを先に実行する。

## Input

Read requirements document from session's active module:

```bash
docs/.deckrd/<namespace>/<module>/requirements/requirements.md
```

The `@` prefix indicates file reference:

```bash
specifications @requirements/requirements.md
```

## Output

**Single file** (≤ 7 FRs):

```bash
docs/.deckrd/<namespace>/<module>/specifications/specifications.md
```

**Split files** (≥ 8 FRs or user choice):

```bash
docs/.deckrd/<namespace>/<module>/specifications/specifications-<area>.md
```

An index file is always created when split:

```bash
docs/.deckrd/<namespace>/<module>/specifications/specifications-index.md
```

## Prompt & Documents

Use prompt and template for writing specifications.md

> Note:
> Specifications define **technical behavioral contracts**.
> They bridge requirements to implementation planning, without prescribing code structure.

```bash
deckrd/assets/
       ├── prompts/specifications.prompt.md
       └── templates/specifications.template.md
```

## Script

Execute: [generate-doc.sh](../../scripts/subcommands/generate-doc.sh)

```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/generate-doc.sh @specifications @requirements/requirements.md [--lang <lang>] --output "specifications/specifications.md"
```

> **Note**:
> The `@` prefix resolves to the active module's document path:
> `docs/.deckrd/<namespace>/<module>/requirements/requirements.md`

## Session Update

After Phase 12 (or Phase 11 if Phase 12 is skipped), update `.session.json`:

```json
{
  "current_step": "spec",
  "completed": ["module", "req", "spec"],
  "documents": {
    "requirements": "requirements.md",
    "specifications": "specifications.md"
  }
}
```

When split, record the index file as the `specifications` entry.
List each split file under `specifications_files`:

```json
{
  "documents": {
    "requirements": "requirements.md",
    "specifications": "specifications-index.md",
    "specifications_files": [
      "specifications-auth.md",
      "specifications-notify.md"
    ]
  }
}
```

## Next Step

Run `impl` to derive implementation plan from specifications.

## Common Rationalizations

| 言い訳                                   | 反論                                                                         |
| ---------------------------------------- | ---------------------------------------------------------------------------- |
| 表の「内容」欄を見れば手順は分かる       | 表は目次であり手順ではない。終了条件・質問数の上限・除去基準は本体にしかない |
| 毎回フェーズファイルを開くのは無駄       | 701 行を常時読むのをやめた分を、必要な 1 本を正確に読むことに使う            |
| 前に同じフェーズを実行したから覚えている | 手順は更新される。参照した内容が現行版である保証はない                       |
| 短いフェーズは読まなくても書ける         | Phase 11 は 30 行だが、baseline の復元順序を間違えると版が壊れる             |
