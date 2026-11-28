---
title: shared-copies
test_scope: SHR
owns:
  - skills/bdd-coder/skills/bdd-coder/scripts/__tests__/integration/shared-copies.integration.spec.sh
  - skills/bdd-coder/skills/bdd-coder/scripts/libs/*.lib.sh
  - skills/bdd-coder/skills/bdd-coder/assets/dic/*.dic
---

## shared-copies

bdd-coder が deckrd (正本) からコピーして持つ共有ライブラリと辞書を持つ。

## テスト対象の略語

| 略語  | 対象                         |
| ----- | ---------------------------- |
| `SCL` | bdd-coder の共有コピーの配置 |
| `SCS` | bdd-coder 単体コピーの起動   |
| `SCT` | spec の `_compare_copy`      |
