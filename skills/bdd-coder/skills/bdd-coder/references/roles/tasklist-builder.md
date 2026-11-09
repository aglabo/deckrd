---
title: "Role: tasklist-builder"
description: "Procedure for breaking a natural-language request or a tasks.md Target into a task list, one item per checklist. Canonical steps for the tasklist-builder agent"
version: 1.0.0
---

## Role: tasklist-builder

<!-- textlint-disable
  ja-technical-writing/sentence-length,
  ja-technical-writing/max-comma -->
<!-- markdownlint-disable line-length -->
<!-- cspell:words MECE -->

This Role is the **canonical procedure** for building a task list before checklist-builder runs.

- In Claude Code, the `tasklist-builder` agent (`agents/tasklist-builder.md` at the plugin root) loads this Role and runs it in a sub-context.
- Where agents are not available, the main session follows this Role step by step itself.

All paths below are relative to the bdd-coder skill directory unless they start with `.local/` or `docs/`.

## Responsibility

Break the input into a task list where **each item is one task, and one item makes one checklist**.
Each item carries a `Handoff`: the exact input that the caller passes to checklist-builder.

The Role does **not**: build checklists, choose which item to run, write code, run tests, edit `tasks.md`, or register anything in `.local/deckrd/session.json`. The caller does the first two. Session registration and resuming belong to #211.

## Inputs

| Parameter     | Description                                                                |
| ------------- | -------------------------------------------------------------------------- |
| `instruction` | A natural-language request, or a Target ID (`T-01` or `T01`)               |
| `tasks_md`    | Path to `tasks.md`. Required only when `instruction` is a Target ID        |
| `answers`     | The user's answer to the question of a previous `questions` run (optional) |

A Scenario ID (`T01-02`, `T-01-02`) or a Case ID (`T-01-02-03`) is already one task. The caller sends it straight to checklist-builder. If one reaches this Role, return `status: invalid-input`.

## Procedure

### Step 1: Classify the input

| Input                                        | Kind             |
| -------------------------------------------- | ---------------- |
| Matches `^T-?[0-9]{2}$`                      | Target ID        |
| Matches `^T-?[0-9]{2}-[0-9]{2}(-[0-9]{2})?$` | `invalid-input`  |
| Anything else                                | Natural language |

Normalize a Target ID to the canonical form `T-XX` (`T01` → `T-01`).

### Step 2: Target ID

1. Output path: `.local/deckrd/temp/tasklist/T-XX.tasklist.md`.
   If the file already exists, do not rebuild it. Return its path with `status: reused`.
2. If `tasks_md` is missing or unreadable, return `status: invalid-input`.
3. Read the `## T-XX:` section of `tasks_md`. If there is none, return `status: invalid-input`.
4. Make one item per Scenario heading `#### T-XX-YY: <scenario>`, in file order.
   - Title: the Scenario heading text.
   - Target: the `Target:` value of the Scenario's Case lines. If they differ, list them comma-separated.
   - Handoff: the invocation form `TXX-YY` (for example `T01-02`), as checklist-builder accepts it.
   - Depends-on: `-`. `tasks.md` does not record dependencies between Scenarios.
5. Set each item's Status from its Case lines `- [ ] **T-XX-YY-ZZ**: ...`:

   | Condition                                                                   | Status                                   |
   | --------------------------------------------------------------------------- | ---------------------------------------- |
   | Every Case line is `- [x]`                                                  | `done`, and the item checkbox is `[x]`   |
   | A Case lists more than one input ("A or B", "any of A / B", several inputs) | `needs-split (<Case ID> has <N> inputs)` |
   | Otherwise                                                                   | `pending`                                |

   The multi-input check is the same as checklist-builder Phase 1 step 3. Do not split the Case yourself: `tasks.md` is split only by `/deckrd tasks`.

### Step 3: Natural language

1. Read the instruction and identify every **Target**: a function, class, or module that the request asks to create or change.
   - If the request extends existing code, use `mcp__plugin_deckrd_cocoindex-code__search` (query: `"<Target> implementation"`) to confirm the real names and files.
   - If the Targets or the scope are unclear and `answers` does not settle them, return `status: questions` with ONE question. Write no file.
2. Make one item per Target.
   - Check the 100% rule: every Target in the request has an item, and no two items cover the same Target (MECE).
   - Do not split one Target into several items by behavior. checklist-builder builds all Scenarios and Cases of one Target in one checklist.
3. For each item:
   - Title: verb + Target, such as "Implement parseConfig".
   - Target: the Target name.
   - Handoff: a natural-language instruction for this Target only. Include the behaviors and constraints from the request that apply to it. **Do not mention the content of other items**, because the Handoff is all that checklist-builder sees for this task.
   - Depends-on: IDs of items that must be done first (for example, a Target that calls another). Use `-` when there are none.
   - Status: `pending`.
4. Order the items so that each item comes after the items in its `Depends-on`.
5. Output path: `.local/deckrd/temp/tasklist/<content-slug>-<adjective>.tasklist.md`.
   - `<content-slug>`: kebab-case summary of the whole request, verb + noun, at most 4 words.
   - `<adjective>`: pick it with `adjective_random()`:

     ```bash
     SKILL_ROOT="<absolute path of the bdd-coder skill directory>"
     . "${SKILL_ROOT}/scripts/libs/naming.lib.sh"
     adjective=$(adjective_random)
     ```

     Always set `SKILL_ROOT` yourself: an inherited value may point to another skill.
   - If the file already exists, pick another adjective. Never overwrite a task list.

### Step 4: Write the task list

1. Fill the template `assets/templates/tasklist.tpl.md`:

   | Placeholder           | Value                                                   |
   | --------------------- | ------------------------------------------------------- |
   | `{{ SOURCE }}`        | `tasks` or `natural-language`                           |
   | `{{ TASK_ID }}`       | `T-XX`, or `-` for natural language                     |
   | `{{ TASKS_MD }}`      | The `tasks_md` path, or `-` for natural language        |
   | `YYYY-MM-DD HH:MM:SS` | Current timestamp                                       |
   | Item block            | One block per item, IDs `L-01`, `L-02`, … in list order |

2. Write a Target ID Handoff inline in backticks: `` - Handoff: `T01-02` ``.
   Write a natural-language Handoff as an indented block quote under the field:

   ```markdown
   - Handoff:

     > Implement `parseConfig(path)` that reads a TOML file and returns a Config object.
     > Return an error when the file does not exist.
   ```

3. Create `.local/deckrd/temp/tasklist/` if needed and write the file.
4. Check the written file: no `{{` remains, every item has all five fields, and every `Depends-on` ID exists in the list.

### Step 5: Return the summary

```text
TASKLIST: .local/deckrd/temp/tasklist/<name>.tasklist.md
STATUS: created | reused
ITEMS: <n> total, <n> pending, <n> needs-split, <n> done
NEEDS_SPLIT: L-02 (T-01-02-03), ...      # omit when none
NEXT: L-01 → <Handoff>                   # first pending item; "none" when no item is pending
```

For `questions` and `invalid-input`, return only:

```text
STATUS: questions | invalid-input
DETAIL: <the question, or what was wrong with the input>
```

## Failure Handling

| Condition                                              | Action                                   |
| ------------------------------------------------------ | ---------------------------------------- |
| Scenario or Case ID given                              | `status: invalid-input`; no file         |
| Target ID without a readable `tasks_md`                | `status: invalid-input`; no file         |
| Target ID not found in `tasks_md`                      | `status: invalid-input`; no file         |
| Task list for the Target ID already exists             | `status: reused`; file unchanged         |
| Targets or scope of a natural-language request unclear | `status: questions`; no file             |
| A Case lists more than one input                       | Item gets `needs-split`; list is written |

## Constraints

- Write only under `.local/deckrd/temp/tasklist/`. Read `tasks.md`; never edit it.
- Never write code or run tests.
- One task list per invocation.
- Never overwrite an existing task list.
- Do not commit. Git operations belong to the user.
