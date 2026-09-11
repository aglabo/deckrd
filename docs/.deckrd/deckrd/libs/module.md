---
title: libs
test_scope: LIB
owns:
  - skills/deckrd/skills/deckrd/scripts/libs/**
---

## libs

deckrd プラグインの共有ライブラリ。bootstrap・kv-store・session・ai-runner・config・naming などの基盤関数を提供する。

## テスト対象の略語

| 略語    | 対象                                            |
| ------- | ----------------------------------------------- |
| `ABC`   | `_build_ai_command` (ai-runner.sh)              |
| `AMLD`  | ai-runner.sh の読み込み (`resolve_ai_model` 側) |
| `AMRM`  | `resolve_ai_model` (ai-runner.sh)               |
| `ARLD`  | ai-runner.sh の読み込み (`resolve_ai_cli` 側)   |
| `ARRC`  | `resolve_ai_cli` (ai-runner.sh)                 |
| `ARVM`  | `validate_ai_model` (ai-runner.sh)              |
| `BDATA` | `DECKRD_DATA_DIR` の決定 (bootstrap.lib.sh)     |
| `BDOCS` | `DECKRD_DOCS_DIR` の決定                        |
| `BENV`  | 副作用: シェル環境変数                          |
| `BEXP`  | `bootstrap_init` の export 検証                 |
| `BFIN`  | `bootstrap_finalize`                            |
| `BIDEM` | 冪等性: `bootstrap_init` 2 回                   |
| `BIDM2` | 冪等性: 2 回 source                             |
| `BIDM3` | 冪等性: 3 回 source                             |
| `BINT`  | 副作用: 内部変数                                |
| `BLIBD` | `DECKRD_LIB_DIR` の決定                         |
| `BLOAD` | bootstrap.lib.sh の読み込み                     |
| `BLOCD` | `DECKRD_LOCAL_DATA` の決定                      |
| `BPR`   | `PROJECT_ROOT`: 事前設定の維持                  |
| `BPRF`  | `PROJECT_ROOT`: `BASH_SOURCE` fallback          |
| `BPRG`  | `PROJECT_ROOT`: git 自動検出                    |
| `BROOT` | `DECKRD_ROOT` の決定                            |
| `BSCR`  | `DECKRD_SCRIPTS_DIR` の決定                     |
| `BSIDE` | 副作用: 他変数                                  |
| `BSRC`  | bdd-coder パス検出 (`BASH_SOURCE` 依存)         |
| `BSYM`  | `SYMBOL` の決定                                 |
| `CALL`  | `config_all` (config.sh)                        |
| `CGS`   | `config_get` / `config_set`                     |
| `CINI`  | `config_init`                                   |
| `CLD`   | config.sh の読み込み                            |
| `KLOAD` | `kv_load` (functional / integration)            |
| `KMS`   | 複数ストアの独立性                              |
| `KPFP`  | `_kv_file_path`                                 |
| `KPLD`  | kv-store.lib.sh の読み込み                      |
| `KPNF`  | `_kv_normalize_filename`                        |
| `KPSP`  | `kv_store_path`                                 |
| `KRT`   | ラウンドトリップ (`kv_save` → `kv_load`)        |
| `KSAL`  | `kv_all`                                        |
| `KSAVE` | `kv_save` (functional / integration)            |
| `KSGT`  | `kv_get`                                        |
| `KSIN`  | `kv_init`                                       |
| `KSLD`  | `kv_load` (unit)                                |
| `KSNK`  | `_kv_normalize_key`                             |
| `KSST`  | `kv_set`                                        |
| `KSSV`  | `kv_save` (unit)                                |
| `NAR`   | `adjective_random` (naming.lib.sh)              |
| `NDT`   | `normalize_doc_type`                            |
| `NGF`   | `generate_filename`                             |
| `NHR`   | `hacker_random`                                 |
| `NLD`   | naming.lib.sh の読み込み                        |
| `NTCC`  | `_try_create_cache_file`                        |
| `RA`    | `run_ai` (ai-runner.sh)                         |
| `SGS`   | `session_get` / `session_set`                   |
| `SINI`  | `session_init`                                  |
| `SLD`   | session.sh の読み込み                           |
| `SLOAD` | `session_load`                                  |
| `SSAVE` | `session_save`                                  |
| `UJR`   | `jq_read` (utils.lib.sh)                        |
| `VENV`  | `validate_env` (validate-env.sh)                |
| `VLD`   | validate-env.sh の読み込み                      |
