---
title: subcommands
test_scope: SUB
owns:
  - skills/deckrd/skills/deckrd/scripts/subcommands/**
---

## subcommands

コマンドから呼ばれる補助スクリプト。ドキュメント生成プロンプトの組み立てを担う。

## テスト対象の略語

| 略語  | 対象                                           |
| ----- | ---------------------------------------------- |
| `EP`  | `execute_prompt` (generate-doc.sh)             |
| `GPF` | `get_prompt_file` (generate-doc.sh)            |
| `LD`  | generate-doc.sh の読み込みと ai-runner.sh 連携 |
| `VAM` | `validate_ai_model` (ai-runner.sh 版)          |
