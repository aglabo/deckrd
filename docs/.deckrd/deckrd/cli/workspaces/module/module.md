---
title: cli
test_scope: CLI
owns:
  - skills/deckrd/skills/deckrd/scripts/*.sh
  - skills/deckrd/skills/deckrd/scripts/__tests__/**
---

## cli

deckrd プラグインのコマンドエントリポイント。init / module / project / status / update の各サブコマンドスクリプトを持つ。

## テスト対象の略語

| 略語    | 対象                                                    |
| ------- | ------------------------------------------------------- |
| `CDS`   | `collect_declared_scopes` (module.sh)                   |
| `CMD`   | `create_module_dirs` (module.sh)                        |
| `DEPE`  | init.sh / update.sh asset deploy (e2e)                  |
| `DTS`   | `derive_test_scope` (module.sh)                         |
| `GDN`   | `_get_default_ns` (module.sh)                           |
| `MAINI` | init.sh: main() integration (integration)               |
| `MIV`   | `init_vars` (module.sh)                                 |
| `MMT`   | create_module_meta と CLI 連携                          |
| `MOD`   | module.sh の引数処理とディレクトリ生成                  |
| `MPA`   | `parse_args` (module.sh)                                |
| `PA`    | `parse_args` (init.sh)                                  |
| `PRJ`   | project.sh の引数処理と `.project.json` 更新            |
| `RDS`   | `read_declared_scope` (module.sh)                       |
| `RTS`   | `resolve_test_scope` (module.sh)                        |
| `SHIV`  | spec_helper.sh の sandbox 隔離不変条件                  |
| `SHPO`  | `path_outside_repo` (spec_helper.sh)                    |
| `SHTD`  | `setup_deckrd_tmpdir` (spec_helper.sh)                  |
| `ST`    | status.sh のセッション表示                              |
| `UPA`   | `parse_args` (update.sh)                                |
| `UPDA`  | update.sh --update: apply outdated assets (integration) |
| `UPDI`  | update.sh: list outdated assets (integration)           |
| `VA`    | `validate_args` (init.sh)                               |
| `VAN`   | `validate_and_normalize` (module.sh)                    |
| `VL`    | `validate_language` (init.sh)                           |
| `VNF`   | `validate_and_normalize_with_fallback` (module.sh)      |
