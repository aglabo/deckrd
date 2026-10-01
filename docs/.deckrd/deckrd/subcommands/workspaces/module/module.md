---
title: subcommands
test_scope: SUB
owns:
  - skills/deckrd/skills/deckrd/scripts/subcommands/**
---

## subcommands

コマンドから呼ばれる補助スクリプト。ドキュメント生成プロンプトの組み立てを担う。

## テスト対象の略語

| 略語    | 対象                                                             |
| ------- | ---------------------------------------------------------------- |
| `EP`    | `execute_prompt` (generate-doc.sh)                               |
| `GDAV`  | generate-doc.sh の `DECKRD_ASSETS_DIR` 自前定義の除去 (静的検査) |
| `GPF`   | `get_prompt_file` (generate-doc.sh)                              |
| `LD`    | generate-doc.sh の読み込みと ai-runner.sh 連携                   |
| `MAINF` | `main` (generate-doc.sh, functional)                             |
| `MAINS` | `main` (generate-doc.sh, system)                                 |
| `PO`    | `parse_options` (generate-doc.sh)                                |
| `RDB`   | `resolve_deckrd_base` (generate-doc.sh)                          |
| `RDP`   | `resolve_doc_paths` (generate-doc.sh)                            |
| `VAM`   | `validate_ai_model` (ai-runner.sh 版)                            |
| `VE`    | generate-doc.sh の `validate_env` 呼び出し配線                   |
