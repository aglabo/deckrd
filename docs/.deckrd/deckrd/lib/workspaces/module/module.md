---
title: lib
test_scope: LIB
owns:
  - skills/deckrd/skills/deckrd/scripts/libs/__tests__/functional/ai-runner.functional.spec.sh
  - skills/deckrd/skills/deckrd/scripts/libs/__tests__/functional/bootstrap.lib.functional.spec.sh
  - skills/deckrd/skills/deckrd/scripts/libs/__tests__/functional/kv-store.lib.functional.spec.sh
  - skills/deckrd/skills/deckrd/scripts/libs/__tests__/integration/ai-runner.integration.spec.sh
  - skills/deckrd/skills/deckrd/scripts/libs/__tests__/integration/bootstrap.lib.integration.spec.sh
  - skills/deckrd/skills/deckrd/scripts/libs/__tests__/integration/kv-store.lib.integration.spec.sh
  - skills/deckrd/skills/deckrd/scripts/libs/__tests__/system/ai-runner.system.spec.sh
  - skills/deckrd/skills/deckrd/scripts/libs/__tests__/unit/ai-runner-build.unit.spec.sh
  - skills/deckrd/skills/deckrd/scripts/libs/__tests__/unit/ai-runner-model.unit.spec.sh
  - skills/deckrd/skills/deckrd/scripts/libs/__tests__/unit/ai-runner-resolve-timeout.unit.spec.sh
  - skills/deckrd/skills/deckrd/scripts/libs/__tests__/unit/ai-runner-resolve.unit.spec.sh
  - skills/deckrd/skills/deckrd/scripts/libs/__tests__/unit/ai-runner-stderr-separation.unit.spec.sh
  - skills/deckrd/skills/deckrd/scripts/libs/__tests__/unit/ai-runner-stdin-guard.unit.spec.sh
  - skills/deckrd/skills/deckrd/scripts/libs/__tests__/unit/ai-runner-stdout-contract.unit.spec.sh
  - skills/deckrd/skills/deckrd/scripts/libs/__tests__/unit/args.lib.unit.spec.sh
  - skills/deckrd/skills/deckrd/scripts/libs/__tests__/unit/asset-copy.lib.unit.spec.sh
  - skills/deckrd/skills/deckrd/scripts/libs/__tests__/unit/asset-diff.lib.unit.spec.sh
  - skills/deckrd/skills/deckrd/scripts/libs/__tests__/unit/bootstrap.lib.unit.spec.sh
  - skills/deckrd/skills/deckrd/scripts/libs/__tests__/unit/config.unit.spec.sh
  - skills/deckrd/skills/deckrd/scripts/libs/__tests__/unit/frontmatter.lib.unit.spec.sh
  - skills/deckrd/skills/deckrd/scripts/libs/__tests__/unit/glob.lib.unit.spec.sh
  - skills/deckrd/skills/deckrd/scripts/libs/__tests__/unit/kv-store.lib.path.unit.spec.sh
  - skills/deckrd/skills/deckrd/scripts/libs/__tests__/unit/kv-store.lib.store.unit.spec.sh
  - skills/deckrd/skills/deckrd/scripts/libs/__tests__/unit/module-decl.lib.unit.spec.sh
  - skills/deckrd/skills/deckrd/scripts/libs/__tests__/unit/naming.lib.unit.spec.sh
  - skills/deckrd/skills/deckrd/scripts/libs/__tests__/unit/normalize-doc-type.unit.spec.sh
  - skills/deckrd/skills/deckrd/scripts/libs/__tests__/unit/session.unit.spec.sh
  - skills/deckrd/skills/deckrd/scripts/libs/__tests__/unit/spec-helper.unit.spec.sh
  - skills/deckrd/skills/deckrd/scripts/libs/__tests__/unit/utils.unit.spec.sh
  - skills/deckrd/skills/deckrd/scripts/libs/__tests__/unit/validate-env.unit.spec.sh
---

## lib

deckrd プラグインの共有シェルライブラリ。bdd-coder は `scripts/libs` にコピーを持つ。
`owns` には本モジュールが所有する spec を 1 本ずつ列挙する。

## テスト対象の略語

| 略語      | 対象                                                                      |
| --------- | ------------------------------------------------------------------------- |
| `ABC`     | `_build_ai_command` (ai-runner.lib.sh)                                    |
| `AFIX`    | `parse_args` の修正 (args.lib.sh)                                         |
| `AFLG`    | `args_flag` (args.lib.sh)                                                 |
| `AINI`    | `args_init` (args.lib.sh)                                                 |
| `AMLD`    | ai-runner.lib.sh の読み込み (モデル解決の spec)                           |
| `AMRM`    | `resolve_ai_model` (ai-runner.lib.sh)                                     |
| `APEX`    | `_args_positional`、`parse_args` 経由 (args.lib.sh)                       |
| `APOS`    | `args_positional` (args.lib.sh)                                           |
| `ARLD`    | ai-runner.lib.sh の読み込み (CLI 解決の spec)                             |
| `ARRC`    | `resolve_ai_cli` (ai-runner.lib.sh)                                       |
| `ARVM`    | `validate_ai_model` (ai-runner.lib.sh)                                    |
| `ASCP`    | asset-copy.lib.sh                                                         |
| `ASPL`    | `--name=value` 分割: `_args_option` (args.lib.sh)                         |
| `ATKV`    | `_args_take_value`、`parse_args` 経由 (args.lib.sh)                       |
| `AVAL`    | `args_value` (args.lib.sh)                                                |
| `BASSET`  | `DECKRD_ASSETS_DIR` (bootstrap.lib.sh)                                    |
| `BASSETF` | `DECKRD_ASSETS_DIR`: 事前設定維持と実アセットツリー (functional)          |
| `BDATA`   | `DECKRD_DATA_DIR` (bootstrap.lib.sh)                                      |
| `BDOCS`   | `DECKRD_DOCS_DIR` (bootstrap.lib.sh)                                      |
| `BENVF`   | 副作用: シェル環境変数 (bootstrap.lib.sh, functional)                     |
| `BEXP`    | export 検証 (bootstrap.lib.sh)                                            |
| `BFIN`    | `bootstrap_finalize` (bootstrap.lib.sh)                                   |
| `BIDEM`   | 冪等性: `bootstrap_init` 2 回 (bootstrap.lib.sh)                          |
| `BIDM2I`  | 冪等性: 2 回 source (bootstrap.lib.sh, integration)                       |
| `BIDM3I`  | 冪等性: 3 回 source (bootstrap.lib.sh, integration)                       |
| `BINTF`   | 副作用: 内部変数 (bootstrap.lib.sh, functional)                           |
| `BLIBD`   | `DECKRD_LIB_DIR` (bootstrap.lib.sh)                                       |
| `BLOAD`   | bootstrap.lib.sh の読み込み                                               |
| `BLOCD`   | `DECKRD_LOCAL_DATA` (bootstrap.lib.sh)                                    |
| `BLOCDF`  | `DECKRD_LOCAL_DATA` / `DECKRD_DOCS_DIR`: `PROJECT_ROOT` 連鎖 (functional) |
| `BLOCT`   | `DECKRD_LOCAL_TEMP` (bootstrap.lib.sh)                                    |
| `BLOCW`   | `DECKRD_LOCAL_WORKSPACES` (bootstrap.lib.sh)                              |
| `BPRF`    | `PROJECT_ROOT`: 事前設定維持 (bootstrap.lib.sh, functional)               |
| `BPRFI`   | `PROJECT_ROOT`: カレントディレクトリ fallback (integration)               |
| `BPRGI`   | `PROJECT_ROOT`: git 自動検出 (integration)                                |
| `BROOT`   | `DECKRD_ROOT` (bootstrap.lib.sh)                                          |
| `BROOTF`  | `DECKRD_ROOT`: `BASH_SOURCE` 基点 (functional)                            |
| `BSCR`    | `DECKRD_SCRIPTS_DIR` (bootstrap.lib.sh)                                   |
| `BSCRF`   | `DECKRD_SCRIPTS_DIR` / `DECKRD_LIB_DIR`: `DECKRD_ROOT` 連鎖 (functional)  |
| `BSIDE`   | 副作用: 他変数 (bootstrap.lib.sh)                                         |
| `BSKR`    | `SKILL_ROOT` (bootstrap.lib.sh)                                           |
| `BSRC`    | `BASH_SOURCE` 依存: bdd-coder パス検出 (bootstrap.lib.sh)                 |
| `BSRCF`   | bdd-coder パス検出 (bootstrap.lib.sh, functional)                         |
| `BSYM`    | `SYMBOL` (bootstrap.lib.sh)                                               |
| `CALL`    | `config_all` (config.lib.sh)                                              |
| `CGS`     | `config_get` / `config_set` (config.lib.sh)                               |
| `CINI`    | `config_init` (config.lib.sh)                                             |
| `CLD`     | config.lib.sh の読み込み                                                  |
| `FLLS`    | `file_list_by_globs` (glob.lib.sh)                                        |
| `FMLL`    | `fm_load_list` (frontmatter.lib.sh)                                       |
| `FMLS`    | `fm_read_list` (frontmatter.lib.sh)                                       |
| `FMSC`    | `fm_read_scalar` (frontmatter.lib.sh)                                     |
| `GLPM`    | `path_matches_glob` (glob.lib.sh)                                         |
| `GLRE`    | `glob_to_regex` (glob.lib.sh)                                             |
| `IAD`     | `init_asset_dirs` (asset-diff.lib.sh)                                     |
| `KLOADF`  | `kv_load` (kv-store.lib.sh, functional)                                   |
| `KLOADI`  | `kv_load` (kv-store.lib.sh, integration)                                  |
| `KMSF`    | 複数ストアの独立性 (kv-store.lib.sh, functional)                          |
| `KPFP`    | `_kv_file_path` (kv-store.lib.sh)                                         |
| `KPLD`    | kv-store.lib.sh の読み込み                                                |
| `KPNF`    | `_kv_normalize_filename` (kv-store.lib.sh)                                |
| `KPSP`    | `kv_store_path` (kv-store.lib.sh)                                         |
| `KRTF`    | `kv_save` → `kv_load` のラウンドトリップ (functional)                     |
| `KSAL`    | `kv_all` (kv-store.lib.sh)                                                |
| `KSAVEF`  | `kv_save` (kv-store.lib.sh, functional)                                   |
| `KSAVEI`  | `kv_save` (kv-store.lib.sh, integration)                                  |
| `KSGT`    | `kv_get` (kv-store.lib.sh)                                                |
| `KSIN`    | `kv_init` (kv-store.lib.sh)                                               |
| `KSLD`    | `kv_load` (kv-store.lib.sh)                                               |
| `KSNK`    | `_kv_normalize_key` (kv-store.lib.sh)                                     |
| `KSST`    | `kv_set` (kv-store.lib.sh)                                                |
| `KSSV`    | `kv_save` (kv-store.lib.sh)                                               |
| `LAF`     | `list_asset_files` (asset-diff.lib.sh)                                    |
| `LALF`    | `_list_all_files` (asset-diff.lib.sh)                                     |
| `MDFL`    | `module_decl_file_of` (module-decl.lib.sh)                                |
| `MDLS`    | `module_decl_list` (module-decl.lib.sh)                                   |
| `MDRF`    | `module_decl_ref_of` (module-decl.lib.sh)                                 |
| `NAR`     | `adjective_random` (naming.lib.sh)                                        |
| `NDP`     | `normalize_dir_path` (utils.lib.sh)                                       |
| `NDT`     | `normalize_doc_type` (normalize-doc-type.lib.sh)                          |
| `NGF`     | `generate_filename` (naming.lib.sh)                                       |
| `NGFR`    | `generate_filename` の並列実行 (naming.lib.sh)                            |
| `NHR`     | `hacker_random` (naming.lib.sh)                                           |
| `NLD`     | naming.lib.sh の読み込み                                                  |
| `NTCC`    | `_try_create_cache_file` (naming.lib.sh)                                  |
| `PARG`    | `parse_args` (args.lib.sh)                                                |
| `RAF`     | `run_ai` (ai-runner.lib.sh, functional)                                   |
| `RAI`     | `run_ai` (ai-runner.lib.sh, integration)                                  |
| `RAIT`    | `resolve_ai_timeout` (ai-runner.lib.sh)                                   |
| `RAS`     | `run_ai` (ai-runner.lib.sh, system)                                       |
| `RASC`    | `run_ai` の stdout 契約 (ai-runner.lib.sh)                                |
| `RASE`    | `run_ai` の stdout/stderr 分離 (ai-runner.lib.sh)                         |
| `RASI`    | `run_ai` の stdin ガード (ai-runner.lib.sh)                               |
| `RATW`    | `run_ai` のタイムアウト解決の配線 (ai-runner.lib.sh)                      |
| `SGS`     | `session_get` / `session_set` (session.lib.sh)                            |
| `SHCT`    | `setup_coder_tmpscript` (libs の spec_helper.sh)                          |
| `SHNC`    | `setup_naming_cache` (libs の spec_helper.sh)                             |
| `SINI`    | `session_init` (session.lib.sh)                                           |
| `SLD`     | session.lib.sh の読み込み                                                 |
| `SLMN`    | `session_lang_migration_needed` (session.lib.sh)                          |
| `SLOAD`   | `session_load` (session.lib.sh)                                           |
| `SMIG`    | `session_migrate_lang_to_prog` (session.lib.sh)                           |
| `SSAVE`   | `session_save` (session.lib.sh)                                           |
| `SSF`     | `strip_suffix` (utils.lib.sh)                                             |
| `UJR`     | `jq_read` (utils.lib.sh)                                                  |
| `VENV`    | `validate_env` (validate-env.lib.sh)                                      |
| `VLD`     | validate-env.lib.sh の読み込み                                            |
| `WJF`     | `write_json_file` (utils.lib.sh)                                          |
| `WRB`     | `workspaces_rule_block` (asset-diff.lib.sh)                               |
| `WRM`     | `workspaces_rule_missing` (asset-diff.lib.sh)                             |
