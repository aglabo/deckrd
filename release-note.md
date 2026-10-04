# deckrd v0.6.0

<!-- textlint-disable
  ja-technical-writing/sentence-length,
  ja-technical-writing/max-comma,
  -->

v0.6.0 では、アセット管理・作業ディレクトリ・テスト基盤・Codex CLI 連携を中心に改善しました。

## Highlights

### `/deckrd update` を追加

配置済みアセットの差分確認と更新を、`init` から分離しました。

```sh
/deckrd update
/deckrd update --update
```

- 不足・古いアセットを検出
- `--update` で更新を適用
- ネストしたアセットに対応
- ユーザー編集済み・新しいファイルを保持
- `.local/deckrd/.gitignore` の workspace ルール移行に対応

### `init` の再実行を安全化

通常の `init` は未配置アセットのみ追加し、既存ファイルを保持します。

```sh
/deckrd init --force
```

`--force` を指定した場合のみ、管理対象アセットを同梱版で再配置します。

シンボリックリンクやハードリンクを経由した Deckrd 自身のアセット領域への誤配置も防止します。

### Workspace 構成を整理

作業ファイルを用途別に整理しました。

```text
.local/deckrd/
├── session.json
├── .project.json
├── temp/          # 再生成可能な一時ファイル
└── workspaces/    # セッションをまたいで残すメモ
````

モジュール固有のメタデータは次へ移動しました。

```text
docs/.deckrd/<namespace>/<module>/workspaces/module/module.md
```

### Windows で ShellSpec を WSL 実行可能に

Windows 環境では ShellSpec を WSL へ委譲できるようになりました。

- Windows / WSL の自動判定
- login shell の PATH を引き継ぎ
- 複数 spec / glob の処理を改善
- `SHELLSPEC_NO_WSL` で無効化可能

### テスト ID 管理を刷新

テスト ID を次の 2層に分離しました。

- Group ID
- Case ID

`run-check-test-ids.sh` も新しいモデルに合わせて再構築し、重複・所属・略語定義の検証を強化しました。

### Codex MCP から Codex CLI へ移行

Codex MCP の利用を廃止し、以下へ統一しました。

```sh
codex exec
```

対象:

- deckrd-review
- bdd-coder code review
- AI runner
- 開発者向けドキュメント

Codex CLI は PATH 上にあり、ログイン済みである必要があります。

### AI runner を強化

`run_ai` の入出力契約とエラー処理を改善しました。

- 空 stdin / terminal stdin を拒否
- 空レスポンスをエラー扱い
- エラーを stderr へ分離
- stdout を正常レスポンス専用化
- timeout 処理を統一
- `set -e` 下でも終了コードを保持
- Codex 実行時の設定を隔離

### bdd-coder のテスト生成を厳格化

ケース生成を次の原則に統一しました。

```text
1 task = 1 test = 1 input
```

複数入力を含む Case は自動展開せず `BLOCKED` として扱います。

カバレッジ取得不能時は `coverage = 0` を仮定しません。

```text
cov=N/A
CRAP=N/A
```

として Cyclomatic Complexity を代替判定に使用します。

### Spec workflow を 12 Phase に分割

`spec` の処理を 12 個の独立したフェーズへ整理しました。

```sh
/deckrd spec --phase <phase>
```

要件確認、設計、API 判断、生成、レビュー、version bump、second opinion までを段階的に実行できます。

## Other Changes

- `jq` を優先し、`jaq` を fallback とする JSON 処理へ統一
- コマンドエラーを stderr へ統一
- `SKILL_ROOT` など共有ライブラリのパス解決を改善
- 並列実行時の一時ファイル名衝突を軽減
- `.gitignore` を allowlist ベースへ変更
- Gitleaks から Betterleaks へ移行
- commit message 生成モデルを `gpt-5.6-luna` へ変更
- `fable` モデルを追加サポート
- SKILL.md の詳細説明を references へ分離

## Migration

既存プロジェクトでは、まず次を実行してください。

```sh
/deckrd update
```

適用には、次を実行します。

で適用できます。

また、以下の移行が必要です。

- module metadata を workspaces/module/module.md へ移動
- 一時ファイルを .local/deckrd/temp/ へ移動
- 永続メモを .local/deckrd/workspaces/ へ配置
- Codex MCP を Codex CLI に置き換え

Codex を利用する場合は次を確認してください。

```sh
codex --version
codex login status
```
