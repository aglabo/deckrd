---
title: "Deckrd Rule: Test and Lint Runners"
description: "Always run tests and linters through pnpm scripts, never the underlying tools"
version: 1.0.0
---

## Deckrd Rule: Test and Lint Runners

Always use `pnpm run` scripts. Never invoke runners or tools directly.

| Task                  | Command                  | Do NOT use                              |
| --------------------- | ------------------------ | --------------------------------------- |
| Run tests (ShellSpec) | `pnpm run test:sh`       | `shellspec`, `runners/run-shellspec.sh` |
| Lint markdown         | `pnpm run lint:markdown` | `runners/run-markdownlint.sh`           |
| Lint text             | `pnpm run lint:text`     | `runners/run-textlint.sh`               |
| Format check          | `dprint check`           | —                                       |
| Format fix            | `dprint fmt`             | —                                       |
