---
name: deckrd-review
description: >
  Get an independent second opinion from codex on any document or deckrd phase.
  Codex acts as a critical reviewer — challenging assumptions and surfacing blind spots
  from a different angle than Claude's primary analysis.
  Use after /deckrd review, before phase transitions, or when a design decision is unclear.
metadata:
  author: aglabo
  version: 0.5.0
  license: MIT
allowed-tools:
  - mcp__plugin_deckrd_codex-mcp__codex
  - mcp__plugin_deckrd_codex-mcp__codex-reply
  - mcp__plugin_idd_codex-mcp__codex
  - mcp__plugin_idd_codex-mcp__codex-reply
  - Read
  - Bash(jq:*)
argument-hint: "<file_or_phase> [--focus completeness|risk|consistency|feasibility]"
---

<!-- textlint-disable
  ja-technical-writing/sentence-length -->

# /deckrd:deckrd-review — Second Opinion via Codex

## Overview

Invoke codex as an **independent critical reviewer** on any document.

Codex challenges assumptions and surfaces blind spots that the primary analysis may miss.
The final judgment always stays with the user (accept / reject / follow-up).

## Usage

```bash
/deckrd:deckrd-review <target> [--focus <area>]
```

### Arguments

| Argument   | Required | Description                                                            |
| ---------- | -------- | ---------------------------------------------------------------------- |
| `<target>` | Yes      | File path (`@path/to/file.md`) or deckrd phase (`req/spec/impl/tasks`) |
| `--focus`  | No       | `completeness` / `risk` / `consistency` / `feasibility` (default: all) |

### Focus Areas

| Focus          | Codex Persona          | Key Questions                                       |
| -------------- | ---------------------- | --------------------------------------------------- |
| `completeness` | Coverage Auditor       | Missing scenarios? Uncovered edge cases?            |
| `risk`         | Devil's Advocate       | Dangerous assumptions? Failure modes?               |
| `consistency`  | Consistency Checker    | Terminology drift? Contradictions between sections? |
| `feasibility`  | Implementation Realist | Ambiguous requirements? Conflicting constraints?    |
| (none)         | Critical Reviewer      | All of the above, balanced                          |

---

## Execution Steps

### Step 1: Resolve target document

**If `<target>` is a deckrd phase** (`req` / `spec` / `impl` / `tasks`):

1. Read `.local/deckrd/session.json`
2. Resolve `session.active` to get active module path
3. Map phase to file:

   | Phase | File                             |
   | ----- | -------------------------------- |
   | req   | requirements/requirements.md     |
   | spec  | specifications/specifications.md |
   | impl  | implementation/implementation.md |
   | tasks | tasks/tasks.md                   |

4. Full path: `docs/.deckrd/<active>/<file>`

**If `<target>` starts with `@`**: use the path directly (strip `@` prefix).

**If the file does not exist**: report error and stop.

### Step 2: Read the document

Read the resolved file content in full.

### Step 3: Build codex prompt

1. `--focus` からテンプレートファイルを選ぶ。

   | `--focus`      | File                                    |
   | -------------- | --------------------------------------- |
   | (none)         | `assets/prompts/balanced.prompt.md`     |
   | `completeness` | `assets/prompts/completeness.prompt.md` |
   | `risk`         | `assets/prompts/risk.prompt.md`         |
   | `consistency`  | `assets/prompts/consistency.prompt.md`  |
   | `feasibility`  | `assets/prompts/feasibility.prompt.md`  |

2. そのファイルを Read し、`text` コードブロックの中身をそのまま使う。
   記憶や推測でプロンプトを組み立ててはならない。
3. `<target>` を Step 1 で解決したターゲット名に、
   `<document content>` を Step 2 で読んだ本文に置換する。

### Step 4: Call codex and display result

Call the available codex MCP tool
(`mcp__plugin_deckrd_codex-mcp__codex` or `mcp__plugin_idd_codex-mcp__codex`)
with the constructed prompt.
Display codex's findings clearly, preceded by:

```text
── Codex Second Opinion ──────────────────────────
Focus: <focus or "balanced">   Target: <resolved file>
──────────────────────────────────────────────────
```

### Step 5: Interactive loop

After displaying findings, show the choice prompt and wait for user input:

```text
What would you like to do?
  a  Accept   — note findings to act on
  r  Reject   — dismiss (reason required)
  q  Ask      — follow-up question to codex
  d  Done     — exit

Choice (a/r/q/d):
```

#### a — Accept

Ask: `Which findings will you act on? (brief description):`
Output summary to user. Done.

#### r — Reject

Ask: `Reason for dismissal:`
Acknowledge the dismissal with the reason. Done.

#### q — Ask follow-up

Ask: `Your follow-up question for codex:`
Call the matching codex reply tool
(`mcp__plugin_deckrd_codex-mcp__codex-reply` or `mcp__plugin_idd_codex-mcp__codex-reply`)
with the follow-up question and prior conversation context.
Display codex's answer.
Return to the choice prompt.

#### d — Done

Exit silently.

---

## Reference

呼び出し例と focus の使い分けは [usage.md](references/usage.md) にあります。
どの focus を選ぶか迷ったときに読んでください。
