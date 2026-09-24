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
  - Read
  - Write
  - Bash(codex:*)
  - Bash(mkdir:*)
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

Every invocation gets its own working files, so that two `/deckrd:deckrd-review` runs in
the same checkout never read or overwrite each other's results. Pick a run id once — a UTC
timestamp such as `20260924T141903Z` — and use it for all three paths below.

| Purpose       | Path                                                   |
| ------------- | ------------------------------------------------------ |
| Prompt        | `temp/deckrd-work/deckrd-review-<run-id>.prompt.md`    |
| Final message | `temp/deckrd-work/deckrd-review-<run-id>.out.md`       |
| Event stream  | `temp/deckrd-work/deckrd-review-<run-id>.events.jsonl` |

`Write` is allowed for these working files only. Never write to the reviewed document, or
anywhere outside `temp/deckrd-work/`.

1. Write the Step 3 prompt to the prompt file with the **Write tool**, never through a
   shell heredoc. The reviewed document is untrusted input: a heredoc ends at a body line
   equal to its delimiter however the delimiter is quoted, so a document containing that
   line would truncate the prompt and hand its remainder to the shell. The Write tool does
   not parse the content, so no delimiter can collide with it.

2. Run codex over the prompt file:

   ```bash
   mkdir -p temp/deckrd-work
   ```

   ```bash
   if codex exec -s read-only --color never --json \
     -o temp/deckrd-work/deckrd-review-<run-id>.out.md \
     - <temp/deckrd-work/deckrd-review-<run-id>.prompt.md \
     >temp/deckrd-work/deckrd-review-<run-id>.events.jsonl &&
     [[ -s temp/deckrd-work/deckrd-review-<run-id>.out.md ]]; then
     jq -r 'select(.type == "thread.started") | .thread_id' \
       temp/deckrd-work/deckrd-review-<run-id>.events.jsonl
   else
     echo "CODEX_SECOND_OPINION_UNAVAILABLE"
   fi
   ```

3. Read the out file **only when the command above printed a session id**. On
   `CODEX_SECOND_OPINION_UNAVAILABLE`, do not read it: the file may be empty or hold an
   earlier run's answer, and presenting that as the second opinion turns a failed run into
   a fabricated one.

4. Record the printed session id. Step 5 resumes that exact session.

`-s read-only` lets codex read the tree while keeping it unable to write. `-o` captures
just the final message, and `--json` puts the event stream on stdout, where the single
`thread.started` event carries the session id. The `&& [[ -s ... ]]` guard covers both a
non-zero exit — API outage, rate limit, invalid model — and an empty result.

Never read an empty or missing codex result as "no findings". A review that found
nothing and a review that never ran are different outcomes.

Do **not** pass `--ephemeral`: the `q` branch of Step 5 resumes this session, and an
ephemeral run leaves nothing to resume.

**If `codex` is missing from `PATH`, or `codex login status` reports logged out**: report
that the second opinion is unavailable and stop. Do not fall back to a self-review —
the whole point of this command is that the reviewer is a different model.

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

Write the question to `temp/deckrd-work/deckrd-review-<run-id>.followup-<n>.md` with the
Write tool, numbering `<n>` from 1 within this invocation. The reason is the same as in
Step 4: the question is untrusted input and must not reach the shell as a heredoc body.

Resume the Step 4 session by the session id recorded there, so that codex still has the
document and its own findings in context — do not rebuild the prompt:

```bash
if codex exec resume <session-id> -c sandbox_mode="read-only" \
  -o temp/deckrd-work/deckrd-review-<run-id>.followup-<n>.out.md \
  - <temp/deckrd-work/deckrd-review-<run-id>.followup-<n>.md &&
  [[ -s temp/deckrd-work/deckrd-review-<run-id>.followup-<n>.out.md ]]; then
  echo "CODEX_FOLLOWUP_OK"
else
  echo "CODEX_SECOND_OPINION_UNAVAILABLE"
fi
```

Read that out file and display codex's answer — again only on `CODEX_FOLLOWUP_OK`, and
never overwriting the Step 4 out file, so the original findings stay readable. Return to
the choice prompt.

Resume the recorded id, never `--last`. `--last` picks the newest session on the machine,
so any codex run started between Step 4 and the follow-up — a second
`/deckrd:deckrd-review` among them — would silently answer against a different document.

If no session id was recorded, re-run Step 4 rather than asking the follow-up. Do not fall
back to `--last`.

`codex exec resume` takes a narrower set of flags than `codex exec`: `--color` and
`-s/--sandbox` are rejected, so do not carry them over from Step 4. Without `-s` the
resumed run falls back to the sandbox in the codex config — usually `workspace-write` —
so `-c sandbox_mode="read-only"` above keeps the follow-up as read-only as Step 4.

#### d — Done

Exit silently.

---

## Reference

呼び出し例と focus の使い分けは [usage.md](references/usage.md) にあります。
どの focus を選ぶか迷ったときに読んでください。
