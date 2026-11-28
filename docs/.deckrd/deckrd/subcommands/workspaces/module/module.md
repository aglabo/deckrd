---
title: subcommands
test_scope: SUB
owns:
  - skills/deckrd/skills/deckrd/scripts/subcommands/__tests__/**
---

## subcommands

deckrd プラグインのサブコマンドスクリプト。ドキュメントを生成する `generate-doc.sh` を持つ。

## テスト対象の略語

| 略語    | 対象                                                    |
| ------- | ------------------------------------------------------- |
| `EP`    | `execute_prompt` の `run_ai` 呼び出し (generate-doc.sh) |
| `GDAV`  | `DECKRD_ASSETS_DIR` 自前定義の除去 (generate-doc.sh)    |
| `GPF`   | `get_prompt_file` (generate-doc.sh)                     |
| `LD`    | generate-doc.sh 経由の ai-runner 読み込み               |
| `MAINF` | `main` (generate-doc.sh, functional)                    |
| `MAINS` | `main` (generate-doc.sh, system)                        |
| `PO`    | `parse_options` の verbose フラグ (generate-doc.sh)     |
| `RDB`   | `resolve_deckrd_base` (generate-doc.sh)                 |
| `RDP`   | `resolve_doc_paths` (generate-doc.sh)                   |
| `SU`    | `show_usage` (generate-doc.sh)                          |
| `VAM`   | `validate_ai_model` (generate-doc.sh から利用)          |
| `VE`    | `validate_env` の呼び出し配線 (generate-doc.sh)         |
