# 🤝 コントリビューションガイドライン

<!-- textlint-disable ja-technical-writing/no-exclamation-question-mark -->

このプロジェクトへの貢献をご検討いただき、ありがとうございます!
皆さまのご協力により、よりよいプロジェクトを築いていけることを願っております。

<!-- textlint-enable -->

## 📝 貢献の方法

### 1. Issue の報告

- バグ報告や機能提案は、[Issue](https://github.com/aglabo/deckrd/issues) にてお願いいたします。
- 報告の際は、再現手順や期待される動作、実際の動作など、詳細な情報を提供してください。

### 2. プルリクエストの提出

- リポジトリをフォークし、`feature/your-feature-name` のようなブランチを作成してください。
- ソースコード、あるいはドキュメントを変更し、順次コミットしてください。
  - コミットメッセージは [ConventionalCommit](https://www.conventionalcommits.org/ja/v1.0.0/) にしたがってください。
  - １機能ごとにコミットし、あとで rebase することでいいコミットが作成できます。
- プルリクエストには、タイトルに変更の概要や目的を１行で、本文に概要の説明や背景を描いてください。

## プロジェクト環境

### 開発環境のセットアップ

次の手順で、開発環境をセットアップします。

```bash
git clone https://github.com/aglabo/deckrd.git
```

### テスト

変更を加えた際は、以下のコマンドでテストを実行し、既存の機能が影響を受けていないことを確認してください。

- textlint
  技術文書として読みやすく、表現上の問題がないかを検証します。
- markdownlint
  マークダウン形式のテキストの、マークダウンが正しく設定されているか確認します。

### コードスタイルとフォーマット

このプロジェクトでは、コードのフォーマット、リントに以下を使用しています。

- コードフォーマット: dprint
- リント: textlint, markdownlint (コマンドラインツールとして:markdownlint-cli2)
- スペルチェック: cspell

## 行動規範

すべてのコントリビューターは、[行動規範](https://github.com/aglabo/.github/blob/main/.github/CODE_of_CONDUCT.ja.md) を遵守してください。

## 参考

- [GitHub Docs: リポジトリコントリビューターのためのガイドラインを定める](https://docs.github.com/ja/communities/setting-up-your-project-for-healthy-contributions/setting-guidelines-for-repository-contributors)

---

## 📬 Issue / Pull Request

<!-- textlint-disable @textlint-ja/ai-writing/no-ai-list-formatting -->

- [🐛 バグ報告を作成する](https://github.com/aglabo/deckrd/issues/new?template=bug_report.yml)
- [✨ 機能提案を作成する](https://github.com/aglabo/deckrd/issues/new?template=feature_request.yml)
- [💬 自由トピックを投稿する](https://github.com/aglabo/deckrd/issues/new?template=open_topic.yml)
- [🔀 Pull Request を作成する](https://github.com/aglabo/deckrd/compare)

<!-- textlint-enable -->
