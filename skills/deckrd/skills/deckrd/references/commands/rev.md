---
title: rev Command
description: Reverse-engineer existing code into deckrd documentation artifacts
---

<!-- textlint-disable
  ja-technical-writing/sentence-length
  ja-technical-writing/no-exclamation-question-mark,
  ja-technical-writing/max-comma -->
<!-- markdownlint-disable line-length -->

## rev Command

Reverse-engineer existing code into deckrd documentation artifacts.
Supports legacy codebases, post-PoC documentation, and applying deckrd to existing projects.

The chain runs in the opposite direction of the standard flow: code → impl → spec → req.

## Usage

```bash
/deckrd rev [--to req|spec|impl] [--path <path>]...
```

## Options

| Option   | Values                | Default       | Description                                                        |
| -------- | --------------------- | ------------- | ------------------------------------------------------------------ |
| `--to`   | `req`, `spec`, `impl` | `impl`        | Target document to generate                                        |
| `--path` | file or directory     | whole project | Limit the investigation to this path. Repeatable. `--to impl` only |

The source of each target is fixed by the chain:

| `--to` | Source                            | Needs before running           |
| ------ | --------------------------------- | ------------------------------ |
| `impl` | existing code (and tests, docs)   | nothing                        |
| `spec` | `implementation.md` of the module | `implementation.md` must exist |
| `req`  | `specifications.md` of the module | `specifications.md` must exist |

There is no `tasks` target and no `--from`. The target decides the source.

The output path follows the session's `active` module. Switch modules with `/deckrd module` before running `rev`.

`--path` rules:

- Each value is a file or directory, relative to the project root. Repeat the option for several paths.
- Use it with `--to impl` only. With `--to spec` or `--to req`, stop with an error: those targets read a document, not code.
- Check each path before Phase 0. If one does not exist or lies outside the project root, stop with the path in the error message. Do not skip it silently.
- Without `--path`, the whole project is investigated.
- It limits only what is read. The output path and the module do not change.

## Preconditions

- Session must exist
- `init` must be completed
- `module` must be set (active module required)
- The source document in the table above must exist (not for `--to impl`)

If the source document is missing, stop and tell the user which `rev --to` step creates it (`impl` for `spec`, `spec` for `req`).

## Existing Target Document

If the target document already exists, `rev` MUST NOT overwrite it.
Write the result next to it as `<name>.rev.md` (for example `requirements/requirements.rev.md`) so the two can be compared.
In this case, do not update `session.json`. The existing document stays the current one, and the user merges the result by hand.

Tell the user which path was written before Phase 3.

## Commitment Declaration (REQUIRED)

Before Phase 0, YOU MUST output:

> "I am executing /deckrd rev for module [MODULE_NAME].
> Target document: [TARGET]. Source: [code | implementation.md | specifications.md].
> I will complete phases in order: 0 -> 1 -> 2 -> 3. I will NOT skip phases."

---

## Execution Flow

```text
Phase 0: Source Collection (impl: explore-agent 委譲 / spec, req: read the source document)
Phase 1: Source Review & Gap Detection
Phase 2: Document Generation
Phase 3: Review Loop
```

---

### Phase 0: Source Collection

#### `--to impl`: Codebase Extraction (explore-agent 委譲)

Delegate deep codebase extraction to explore-agent:

1. Read `<local_dir>/session.json` to confirm active module
2. Spawn **explore-agent** with:
   - `skill_dir`, `local_dir`: absolute paths, see "Path arguments" in SKILL.md
   - `scope`: `codebase-extraction`
   - `directory`: project root
   - `module`: active module (`active` in `<local_dir>/session.json`)
   - `focus`: module name + `implementation`
   - `paths`: the `--path` values, comma-separated (omit when `--path` is not given)
   - Role: [`roles/explorer.md`](../roles/explorer.md) (no subagent: follow it yourself, see SKILL.md)
3. The agent writes findings to `<local_dir>/temp/deckrd-work/codebase-extraction.md`
4. Read the **Summary** returned by the agent and store as **EXTRACTION CONTEXT**

#### `--to spec` / `--to req`: Read the Source Document

1. Read `<local_dir>/session.json` to confirm active module
2. Read the source document directly (no explore-agent):
   `docs/.deckrd/<namespace>/<module>/implementation/implementation.md` for `spec`,
   `docs/.deckrd/<namespace>/<module>/specifications/specifications.md` for `req`.
   When the document is split, read the index file recorded in `session.json` and every file it lists.
3. Store the full text as **SOURCE DOCUMENT**

---

### Phase 1: Source Review & Gap Detection

Review the collected source and identify gaps:

#### Step 1-1: Present Summary

Show the user what was collected.

For `--to impl`:

```text
[Reverse Engineering Scan]

Target: implementation
Scope: <paths from --path, or "whole project">
Detected artifacts:
  - Source files: <count> files
  - Existing docs: <list or "none">
  - Detected patterns: <list>
  - Detectable phases: <count> inferred phases

Gaps that need user input:
  - <gap-1>: <what could not be inferred>
  - <gap-2>: <what could not be inferred>

Proceed to generate the implementation document? (Y / add more context)
```

For `--to spec` / `--to req`:

```text
[Reverse Engineering Scan]

Target: <specifications | requirements>
Source: <path of the source document>
Items in source: <count> <phases | behavioral rules>

Gaps that need user input:
  - <gap-1>: <what the source does not say>

Proceed to generate the [TARGET] document? (Y / add more context)
```

#### Step 1-2: Gap-Filling Loop (max 3 rounds)

If the user provides additional context:

- Ask EXACTLY 1 question per round. No exceptions.
- Accumulate answers as **GAP NOTES**

**Termination conditions** (stop as soon as either is met):

1. User responds with "十分", "以上です", "OK", "done", or equivalent
2. 3 rounds completed

---

### Phase 2: Document Generation

Build the combined prompt context:

```text
EXTRACTION CONTEXT: <Phase 0 findings>      # --to impl
SOURCE DOCUMENT:    <Phase 0 document text> # --to spec, --to req
GAP NOTES:          <Phase 1 accumulated answers>
TARGET:             <--to value>
```

`generate-doc.sh` reads the `TARGET:` line and adds the standard template for it
(`implementation` / `specifications` / `requirements`) to the AI input.
The generated document therefore has the standard headings, IDs, `version`, and Change History.
An unknown `TARGET` (including `tasks`) stops with `Error: unknown rev target`.

If the target document already exists, use `<name>.rev.md` as the output file
(see "Existing Target Document"). The examples below use the normal name.

Execute based on `--to` value:

**`--to impl`**:

```bash
bash "<DECKRD_SKILL_DIR>/scripts/subcommands/generate-doc.sh" @rev "<context>" \
  --lang <DOC_LANG> \
  --output "implementation/implementation.md"
```

**`--to spec`**:

```bash
bash "<DECKRD_SKILL_DIR>/scripts/subcommands/generate-doc.sh" @rev "<context>" \
  --lang <DOC_LANG> \
  --output "specifications/specifications.md"
```

**`--to req`**:

```bash
bash "<DECKRD_SKILL_DIR>/scripts/subcommands/generate-doc.sh" @rev "<context>" \
  --lang <DOC_LANG> \
  --output "requirements/requirements.md"
```

`<context>` is the combined prompt context built above. The target is passed through its
`TARGET` line — `generate-doc.sh` has no `--mode` option.

---

### Phase 3: Review Loop (max 3 rounds)

After the document is generated, conduct a review loop.

#### Step 3-1: Self-Review

Read the generated document and evaluate:

| Check Item             | Pass Criteria                                                                                                                  |
| ---------------------- | ------------------------------------------------------------------------------------------------------------------------------ |
| Reflects the source    | `impl`: each item has a `Source: path:line` that exists. `spec` / `req`: each item has a `Source: <doc>#<heading>` that exists |
| No fabricated content  | Nothing is stated that the source does not say or imply                                                                        |
| Gaps clearly marked    | Items without a `Source:` line are labeled `[INFERRED]`                                                                        |
| Open Questions present | Unverifiable items listed as open questions                                                                                    |
| Standard format        | Template headings, standard IDs (`REQ-F-001` etc.), `version` kept                                                             |
| Right level            | `spec` has no phase or file detail from impl. `req` has no behavioral rule detail from spec                                    |

#### Step 3-2: Present Review Findings

**If issues found**: List each issue and ask user to confirm:

```toml
[Review Finding]
- REQ-F-003 marked [INFERRED] — no direct source found
  Accept as inferred, or remove? (keep / remove / custom)
```

**If no issues**:

```toml
[Review Summary] No critical issues found.
Approve [TARGET] document? (Y / revise)
```

#### Step 3-3: Rewrite (if needed)

If the user requests revisions:

1. Collect revision instructions as **REVIEW NOTES**
2. Re-execute Phase 2 with `REVIEW NOTES` appended to context
3. Return to Step 3-1

**Termination conditions**:

1. User approves with "Y", "承認", "OK", "done", or equivalent
2. 3 review rounds completed — present document as-is for explicit approval

#### Step 3-4: Settle `[INFERRED]` Items

After approval, settle each `[INFERRED]` item by the answer given in Step 3-2:

| Answer   | Result in the document                                                            |
| -------- | --------------------------------------------------------------------------------- |
| `keep`   | Keep the `[INFERRED]` label. The item stays as an accepted assumption.            |
| `remove` | Delete the item (and its Traceability row)                                        |
| `custom` | Rewrite with the user's evidence. Remove the label when a `Source:` line is added |

The document keeps `status: Draft` after `rev`. Later commands (`spec`, `impl`, `tasks`, `review`)
treat the remaining `[INFERRED]` items as assumptions to confirm, not as verified facts.
Do not remove the label without evidence.

---

## Input

| `--to` | Input                                                                |
| ------ | -------------------------------------------------------------------- |
| `impl` | Existing source code, tests, and documentation (limited by `--path`) |
| `spec` | `implementation.md` of the active module                             |
| `req`  | `specifications.md` of the active module                             |

## Output

Depends on `--to` value:

| `--to` | Output Path                                                          |
| ------ | -------------------------------------------------------------------- |
| `impl` | `docs/.deckrd/<namespace>/<module>/implementation/implementation.md` |
| `spec` | `docs/.deckrd/<namespace>/<module>/specifications/specifications.md` |
| `req`  | `docs/.deckrd/<namespace>/<module>/requirements/requirements.md`     |

## Prompt & Documents

```bash
deckrd/assets/
       ├── prompts/rev.prompt.md          # evidence rules (all modes)
       └── templates/
              ├── implementation.template.md   # --to impl
              ├── specifications.template.md   # --to spec
              └── requirements.template.md     # --to req
```

`rev` has no template of its own. The standard template for `--to` is used, so the output matches the standard flow.

## Session Update

After Phase 3 approval, update `<local_dir>/session.json`.
The chain does not follow the standard order, so mark only the step that `rev` created.
Add it to `completed` (keep the steps already there), record the document, and set `current_step` to it.
Do not update the session when the result was written as `<name>.rev.md`.

**`--to impl`**:

```json
{
  "current_step": "impl",
  "completed": ["module", "impl"],
  "documents": {
    "implementation": "implementation.md",
    "implementation_files": ["implementation.md"]
  }
}
```

**`--to spec`** (`implementation.md` already exists):

```json
{
  "current_step": "spec",
  "completed": ["module", "impl", "spec"],
  "documents": {
    "implementation": "implementation.md",
    "implementation_files": ["implementation.md"],
    "specifications": "specifications.md"
  }
}
```

**`--to req`** (`specifications.md` already exists):

```json
{
  "current_step": "req",
  "completed": ["module", "impl", "spec", "req"],
  "documents": {
    "implementation": "implementation.md",
    "implementation_files": ["implementation.md"],
    "specifications": "specifications.md",
    "requirements": "requirements.md"
  }
}
```

## Relationship to Standard Flow

`rev` is a bootstrap command. It generates the same document types as the standard flow,
but derives them from existing code, in the opposite order.

```text
[existing code]
     |
     v
[/deckrd rev --to impl]  → implementation.md
     |
     v
[/deckrd rev --to spec]  → specifications.md
     |
     v
[/deckrd rev --to req]   → requirements.md
```

After `impl` exists, the standard `tasks` command can already run (its gate needs only `impl`).
After the whole chain, the standard commands (`review`, `dr`, `spec --phase`, `tasks`) work on the three documents as usual.

## Next Step

After `--to impl`: Run `rev --to spec` to derive specifications, or `tasks` to derive executable tasks.
After `--to spec`: Run `rev --to req` to derive requirements.
After `--to req`: The three documents exist. Run `review`, or `tasks` and `/bdd-coder:bdd-coder` to implement.
