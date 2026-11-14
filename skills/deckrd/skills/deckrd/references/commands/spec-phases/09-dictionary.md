---
title: "spec Phase 9: Universal Dictionary"
description: Extract the module's terms and concepts and create or update universal-dictionary.md before the specifications are generated
---

<!-- textlint-disable
    ja-technical-writing/no-exclamation-question-mark,
    ja-technical-writing/sentence-length,
    ja-technical-writing/max-comma -->
<!-- markdownlint-disable line-length -->

## Phase 9: Universal Dictionary

## Standalone Invocation

```bash
/deckrd spec --phase dictionary
```

## Preconditions

| 必要な入力                                          | 生成元    | 欠けているとき                                          |
| --------------------------------------------------- | --------- | ------------------------------------------------------- |
| `requirements/requirements.md`                      | `req`     | `req` を先に実行する                                    |
| REQ SUMMARY / CONFIRMED DESIGN                      | Phase 1-4 | Context Ledger から読む。無ければ該当フェーズを実行する |
| EXTERNAL DESIGN NOTES / API・FUNCTION DECISIONS     | Phase 5-7 | Context Ledger から読む。無い場合は省略して進めてよい   |
| `decision-records.md`（モジュール直下、存在すれば） | `dr`      | 無ければ省略する                                        |

## Rule

辞書の構造・UD-ID の採番・版・整合性検証は `docs/.deckrd/rules/deckrd-rule-document-model.md` の
「用語の ID (UD)」と「universal-dictionary.md (概念の正本)」に従う。**このフェーズの開始前に Read すること。**

辞書はモジュール直下に置く。

```bash
docs/.deckrd/<namespace>/<module>/universal-dictionary.md
```

辞書は既定で作成する。ただし置くかどうかはルール上任意であり、Step 9-3 でユーザーがスキップを選べる。

## Steps

### Step 9-1: Read the Existing Dictionary

`universal-dictionary.md` が存在する場合:

- frontmatter の `version` と `## Change History` の表全体を **DICTIONARY BASELINE** として保存する
- 既存の UD-ID と用語の一覧を控える（Step 9-5 の消失チェックに使う）

存在しない場合は初回作成とし、baseline は無い。

### Step 9-2: Extract Term Candidates

REQ SUMMARY・CONFIRMED DESIGN・EXTERNAL DESIGN NOTES・API DECISIONS・FUNCTION DECISIONS・
`decision-records.md` から用語と概念を抽出する。対象は、複数の文書・工程が同じ意味を共有すべきものとする。

候補ごとに、ルールの「新しい概念を見つけたとき」の手順で既存の UD と照合し、次のいずれかに分類する。

| 分類     | 意味                                     | 扱い                                |
| -------- | ---------------------------------------- | ----------------------------------- |
| 再利用   | 既存の UD に同じ概念がある               | 既存の UD-ID をそのまま使う         |
| 新規     | 既存の UD に該当がなく、再利用もできない | 既存の最大番号の次から UD-ID を発行 |
| 意味変更 | 既存の UD の定義の意味が変わる           | 参照元を列挙して影響を評価する      |
| 不整合   | 辞書と Accepted の DR の記述が食い違う   | 読み替えず、辞書の不整合節に記録    |

抽出しないもの:

- 1 つの文書の中だけで完結する一般語
- 関数名・型名・ファイルパスなど実装の識別子

意味変更の候補は、参照元を列挙して影響を受ける文書を控える。

```bash
grep -rn "UD-<NNN>" --include=*.md docs/.deckrd/<namespace>/<module>/
```

### Step 9-3: Confirm with the User

候補の一覧をユーザーに提示し、承認を得る。

```text
[Universal Dictionary] <namespace>/<module>

NEW:
  UD-004 処理権     (概念 / サーバー / 確定)
  UD-005 処理中     (状態 / サーバー / 未確定)
REUSE:
  UD-001 登録キー
CHANGED:
  UD-002 登録要求   — 定義に「再送」を含める (影響: DR-03, specifications.md)
INCONSISTENT:
  UD-003 有効期間   — DR-05 の記述と食い違う

Create / update universal-dictionary.md with these terms? (Y / edit / skip)
```

- `Y`: 承認した一覧を **DICTIONARY TERMS** として確定する
- `edit`: ユーザーの指摘を反映して再提示する（最大 2 回）
- `skip`: 辞書を作成・更新しない。ledger に `DICTIONARY TERMS: skipped` と記録して Phase 10 へ進む。
  既存の辞書がある場合は、Phase 10 でそのまま参照に使う

意味変更を含む場合、辞書だけを直して済ませてはならない。影響を受ける DR・要件の改訂を
同じ変更単位で行うか、辞書の改訂を止めるかをユーザーに確認する。

### Step 9-4: Generate the Dictionary

```bash
bash "<DECKRD_SKILL_DIR>/scripts/subcommands/generate-doc.sh" @universal-dictionary \
  @requirements/requirements.md \
  [--lang <lang>] \
  --output "universal-dictionary.md"
```

DICTIONARY TERMS、既存の辞書（EXISTING DICTIONARY）、CONFIRMED DESIGN、EXTERNAL DESIGN NOTES、
API DECISIONS、FUNCTION DECISIONS、`decision-records.md` を文脈として渡す。

`generate-doc.sh` は出力ファイルを上書きする。既存の UD 見出し・定義・廃止の記録は、
文脈として渡した既存の辞書から引き継がせる。

### Step 9-5: Machine Check

UD-ID の重複を検出する。出力は空でなければならない。

```bash
grep -oE "^#{2,6} UD-[0-9]{3} " docs/.deckrd/<namespace>/<module>/universal-dictionary.md \
  | awk '{print $2}' | sort | uniq -d
```

Step 9-1 で控えた既存の UD-ID が、すべて見出しとして残っていることを確かめる。
廃止した用語も見出しは残す。消えた UD-ID があれば Step 9-4 からやり直す。

版上げはここでは行わない。Phase 12 でユーザーの承認後に行う。

## Output

- `universal-dictionary.md`（スキップした場合は作成・更新しない）
- Context Ledger に **DICTIONARY TERMS** と **DICTIONARY BASELINE** を追記する。
  意味変更があれば、影響を受ける文書の一覧を DICTIONARY TERMS に含める

## Next Phase

[Phase 10: Document Generation](10-generate.md)
