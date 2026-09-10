---
title: cli
test_scope: CLI
owns:
  - skills/deckrd/skills/deckrd/scripts/*.sh
  - skills/deckrd/skills/deckrd/scripts/__tests__/**
---

## cli

deckrd プラグインのコマンドエントリポイント。init / module / project / status の各サブコマンドスクリプトを持つ。

## テスト対象の略語

| 略語   | 対象                                         |
| ------ | -------------------------------------------- |
| `CDS`  | `collect_declared_scopes` (module.sh)        |
| `DTS`  | `derive_test_scope` (module.sh)              |
| `GDN`  | `_get_default_ns` (module.sh)                |
| `MAIN` | `main` (init.sh)                             |
| `MOD`  | module.sh の引数処理とディレクトリ生成       |
| `PA`   | `parse_args` (init.sh)                       |
| `PRJ`  | project.sh の引数処理と `.project.json` 更新 |
| `RDS`  | `read_declared_scope` (module.sh)            |
| `RTS`  | `resolve_test_scope` (module.sh)             |
| `ST`   | status.sh のセッション表示                   |
| `VA`   | `validate_args` (init.sh)                    |
| `VL`   | `validate_language` (init.sh)                |
