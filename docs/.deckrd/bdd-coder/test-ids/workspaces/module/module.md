---
title: test-ids
test_scope: RUN
owns:
  - skills/bdd-coder/skills/bdd-coder/scripts/check-test-ids.sh
  - skills/bdd-coder/skills/bdd-coder/scripts/check-ids/languages.sh
  - skills/bdd-coder/skills/bdd-coder/scripts/check-ids/plugins/*.plugin.sh
  - skills/bdd-coder/skills/bdd-coder/scripts/check-ids/plugins/__tests__/unit/*.spec.sh
  - skills/bdd-coder/skills/bdd-coder/scripts/check-ids/libs/*.lib.sh
  - skills/bdd-coder/skills/bdd-coder/scripts/check-ids/libs/__tests__/unit/*.spec.sh
  - skills/bdd-coder/skills/bdd-coder/scripts/__tests__/unit/check-test-ids.unit.spec.sh
---

## test-ids

bdd-coder のテスト ID 検査スクリプト `check-test-ids.sh` と、その言語テーブル、言語プラグイン、専用ライブラリを持つ。

## テスト対象の略語

| 略語   | 対象                                                    |
| ------ | ------------------------------------------------------- |
| `CCD`  | declaration.lib.sh の `count_case_declaration`          |
| `CDI`  | test-id.lib.sh の `check_declared_id`                   |
| `CGD`  | declaration.lib.sh の `count_group_declaration`         |
| `CLD2` | declaration.lib.sh の `count_line_declaration`          |
| `CLI`  | check-test-ids.sh のコマンドライン                      |
| `CNA`  | report.lib.sh の `counts_add`                           |
| `CNI`  | report.lib.sh の `counts_init`                          |
| `CNS`  | report.lib.sh の `counts_summary`                       |
| `DCL`  | check-test-ids.sh の宣言の行の判定とエラー報告          |
| `DII`  | test-id.lib.sh の `declared_ids_init`                   |
| `FLR`  | check-test-ids.sh の 0 件の言語と、列挙・読み込みの失敗 |
| `GRR`  | test-id.lib.sh の `group_id_reset`                      |
| `LBR`  | test-id.lib.sh の `loop_block_reset`                    |
| `LNG`  | 言語プラグインのファイル名と行の読み方                  |
| `LST`  | check-test-ids.sh のファイル列挙とスキャンルート        |
| `PDA`  | dart プラグインの `check_dart_line`                     |
| `PGO`  | go プラグインの `check_go_line`                         |
| `PLG`  | check-test-ids.sh の言語プラグイン                      |
| `PSH`  | sh プラグインの `check_sh_line`                         |
| `PTS`  | tsjs プラグインの `check_tsjs_line`                     |
| `RDC`  | declaration.lib.sh の `read_declaration`                |
| `RER`  | report.lib.sh の `report_error`                         |
| `RFL`  | file-reader.lib.sh の `read_file_lines`                 |
| `TIP`  | test-id.lib.sh の `parse_title_id`                      |
| `TLB`  | test-id.lib.sh の `track_loop_block`                    |
