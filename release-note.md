# deckrd v0.6.1 - 2026-11-10

<!-- textlint-disable
  ja-technical-writing/sentence-length,
  ja-technical-writing/max-comma,
  -->

v0.6.1 は v0.6.0 の修正リリースです。表示とドキュメントの誤りを直しました。

## v0.6.1 での修正

- `project.sh` のヘルプと実行結果が示す設定ファイルのパスを `.local/deckrd/.project.json` に修正
- `rev` プロンプトが、存在しない `--mode` オプションではなく入力コンテキストの `TARGET` を読むように修正
- コマンドリファレンスの記載を実装に合わせて修正
  - `.local/deckrd/.project.json` のパス
  - `generate-doc.sh @implementation` / `@rev` の呼び出し形式
  - `init <project> <project-type> --force` の引数形式
- セッションの保存先を変更する環境変数名を `DECKRD_LOCAL_DATA` に修正
- v0.6.0 のリリースノートと CHANGELOG の挙動説明を訂正 (`init --force`、`/deckrd update --update`、AI タイムアウト、コミットメッセージフックのモデル)

以下は v0.6.0 の変更点です (訂正済み)。

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
- 配置先のほうが新しいファイルは保持 (同梱版より古く内容が異なるファイルは `--update` で上書き)
- 既存の `.gitignore` は変更しない
- `.local/deckrd/.gitignore` の workspace ルール移行に対応

### `init` の再実行を安全化

通常の `init` は未配置アセットのみ追加し、既存ファイルを保持します。

```sh
/deckrd init <project> <project-type> --force
```

`--force` を指定した場合のみ、すべての同梱アセットを同梱版で再配置します。

> `--force` は `.gitignore` とユーザーが編集したファイルも上書きします。保持されるのは `session.json` のみです。
> 古いファイルだけを更新したい場合は `/deckrd update --update` を使ってください。

シンボリックリンクやハードリンクを経由した Deckrd 自身のアセット領域への誤配置も防止します。

### Workspace 構成を整理

作業ファイルを用途別に整理しました。

```text
.local/deckrd/
├── session.json
├── .project.json
├── temp/          # 再生成可能な一時ファイル
└── workspaces/    # セッションをまたいで残すメモ
```

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
- 開発者向けドキュメント

Codex CLI は PATH 上にあり、ログイン済みである必要があります。

### AI runner を強化

`run_ai` の入出力契約とエラー処理を改善しました。

- 空 stdin / terminal stdin を拒否
- 空レスポンスをエラー扱い
- エラーを stderr へ分離
- stdout を正常レスポンス専用化
- timeout 処理を統一 (既定値を 120 秒から 300 秒へ変更、`DECKRD_AI_TIMEOUT` で上書き可能)
- `set -e` 下でも終了コードを保持
- Codex 実行時の設定を隔離

### bdd-coder のテスト生成を厳格化

ケース生成を次の原則に統一しました。

```text
1 task = 1 test = 1 input
```

Task ID 指定の Case が複数入力を含む場合は、自動展開せず `BLOCKED` として扱います。

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

- コマンドエラーを stderr へ統一
- `SKILL_ROOT` など共有ライブラリのパス解決を改善
- 並列実行時の一時ファイル名衝突を軽減
- `.gitignore` を allowlist ベースへ変更
- Gitleaks から Betterleaks へ移行
- commit message フック (`lefthook.yml`) の生成モデルを `gpt-5.6-luna` へ変更
- `fable` モデルを追加サポート
- SKILL.md の詳細説明を references へ分離

## Migration

既存プロジェクトでは、まず次を実行してください。

```sh
/deckrd update
```

適用には、次を実行します。

```sh
/deckrd update --update
```

また、以下の移行が必要です。

- module metadata を workspaces/module/module.md へ手動で移動 (`/deckrd update` では移動されません。旧配置は読み込まれません)
- 一時ファイルを .local/deckrd/temp/ へ移動
- 永続メモを .local/deckrd/workspaces/ へ配置
- Codex MCP を Codex CLI に置き換え

Codex を利用する場合は次を確認してください。

```sh
codex --version
codex login status
```
