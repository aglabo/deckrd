# 📦 OSS Project Starter Template

<!-- textlint-disable ja-technical-writing/sentence-length -->
<!-- markdownlint-disable line-length -->

This template is designed to help you quickly launch a modern open source project with best practices and essential tools pre-configured.

---

## 🛠 Features

- Easy development environment setup via PowerShell scripts
  - Lightweight setup using Scoop & pnpm for Windows
- Includes common boilerplate files such as `.editorconfig`, `.gitignore`, and more
  - Minimal configuration with flexibility for future extensions
- Lightweight Git hook environment powered by `lefthook`
  - Prevents credential leakage using tools like `gitleaks` and `secretlint`

---

## 🚀 Getting Started

1. Fork this template repository to your own GitHub account.
2. Customize it as needed (e.g., change the name in the `LICENSE` file to your GitHub handle).
3. When creating a new repository, select this template as a base.
4. You'll get a ready-to-use repository with all essential configurations preloaded.

---

## 🧰 Included Tools

| Tool       | Description                                    |
| ---------- | ---------------------------------------------- |
| lefthook   | Git commit hook manager                        |
| delta      | Visual Git diff viewer                         |
| commitlint | Linting for commit message format              |
| gitleaks   | Detects secrets and credentials in source code |
| secretlint | Static analysis tool to catch secrets in files |
| cspell     | Spellchecker for code and documentation        |
| dprint     | Fast and extensible code formatter (optional)  |

> **Note**
> These tools are installed independently using Scoop or pnpm and are not bundled with the repository.
> You are responsible for managing their versions and keeping them up to date.

---

## 📄 License

This template is licensed under the MIT License.
For more details, see [LICENSE](./LICENSE).
