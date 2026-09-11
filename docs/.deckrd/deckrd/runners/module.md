---
title: runners
test_scope: RUN
owns:
  - runners/**
---

## runners

テスト・リント・フォーマットの実行ラッパー。pnpm スクリプトから呼ばれ、ツール本体への引数を組み立てる。

## テスト対象の略語

| 略語  | 対象                                      |
| ----- | ----------------------------------------- |
| `ATF` | `args_to_filter`                          |
| `BT`  | `base_targets`                            |
| `CD`  | `check_duplicates` (検査 C)               |
| `CM`  | `check_module` (検査 B)                   |
| `CS`  | `check_scopes` (検査 A)                   |
| `CT`  | `check_targets` (検査 D)                  |
| `ECI` | `extract_case_ids`                        |
| `ESG` | `expand_spec_glob`                        |
| `FMR` | `read_module_scalar` / `read_module_owns` |
| `FUC` | `find_unidentified_cases`                 |
| `GFL` | `get_filelist`                            |
| `GSF` | `get_spec_files`                          |
| `IGP` | `is_glob_pattern`                         |
| `ISF` | `is_spec_file`                            |
| `ISG` | `is_spec_glob`                            |
| `ITT` | `is_test_type`                            |
| `LS`  | `layer_suffix`                            |
| `MN`  | `main` (run-check-test-ids.sh)            |
| `MRS` | `main` (run-shellspec.sh)                 |
| `NP`  | `normalize_path`                          |
| `PMG` | `path_matches_glob`                       |
| `PO`  | `parse_options`                           |
| `RMT` | `read_module_targets`                     |
| `RSF` | `resolve_spec_files`                      |
