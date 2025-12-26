<!-- markdownlint-disable first-line-h1 -->

|English|[日本語](README.ja.md)|

# deckrd - "Your Goals to Task" framework

## About deckrd

<!-- markdownlint-disable line-length -->

deckrd is a **document-driven workflow for progressively documenting and organizing requirements through implementation decisions**.

It manages the following documents as separate, distinct layers:

- requirements (demands and conditions)
- decision-records (history of design decisions)
- specifications (detailed specifications)
- implementation (implementation decisions and guidelines)
- tasks (implementation tasks)

The implementation layer in particular is designed to capture **decisions not directly written in code**, such as:
"Why was this implementation approach chosen?" and "What is the scope of implementation?"

This template positions deckrd as an **assistive tool for preventing the cognitive gap between design and implementation**.

> Prerequisites (Usage Environment):
>
> - AI execution environment (Claude Code / codex cli, etc.)
> - Access to a compatible LLM

<!-- markdownlint-enable -->

## Installation

### Using as Claude Code plugins

In Claude Code, you can use deckrd as a plugin.

```bash
# Add marketplace if needed
claude plugin marketplace add aglabo/deckrd

# Install deckrd
claude plugin install deckrd@deckrd
```

> **Note**
> On Windows, installation may fail if TEMP/TMP points to
> a different drive than the plugins cache.
> In that case, set TEMP/TMP to the same drive.

### Agent Skills

For `codex` and similar tools:

`deckrd` is implemented as `Agent Skills`. Therefore, you can install it using the following steps:

1. Download the `zip` archive:
   Download the zip archive from [deckrd - release](https://github.com/aglabo/deckrd/releases)

2. Copy the files:
   Copy the `deckrd` directory from the extracted zip to your Agent Skills directory

   Example (Unix-like environments):

   ```bash
   cp -fr deckrd ~/.codex/skills
   ```

## Basic Usage

### Document Creation Flow

In `deckrd`, documents are created in the following order:

```plaintext
Goals / Ideas
|
v
requirements
|
v
decision-records (as needed)
|
v
specifications
|
v
implementation
|
v
tasks
|
v
Code / Tests
```

### `deckrd` Subcommands

`deckrd` uses subcommands to create documents.
The following subcommands are available:

- `init`: Prepare directories for document creation
- `req`: Create `requirements` (requirements definition document)
- `spec`: Create `specification` (specification document)
- `impl`: Create `implementation` (implementation decision criteria document)
- `task`: Create `tasks.md` (implementation task list; test definitions in BDD)
- `dr`: Create `Decision Records`

Execute the commands in order from top to bottom to create the implementation task list.

> Notes:
>
> - You can iterate between requirements / specifications / implementation
> - tasks is the entry point to the implementation phase; there is generally no going back

### Directory Structure

`deckrd` creates a `docs/.deckrd` directory in the project root.
The directory structure is as follows:

```bash
/docs/.deckrd/<namespace>/<module>/
  |-- decision-records.md
  |-- implementation
  |   `-- implementation.md
  |-- requirements
  |   `-- requirements.md
  |-- specifications
  |   `-- specifications.md
  `-- tasks
      `-- tasks.md
```

`<namespace>` and `<module>` are specified as arguments to the `init` command.

### `dr` Command (`Decision Records`)

With `deckrd`, you don't just create documents and stop there.
You continue to refine documents through discussions with AI.

The `dr` command records the results of these discussions as `Decision Records`.
To ensure only necessary discussions are recorded, you must include the `--add` option as a safeguard.

```bash
# Example (Agent command)
/deckrd dr --add
```

## implementation (Implementation Decision Criteria)

In deckrd, there is a document layer called
**implementation (implementation decision criteria)** between specifications and tasks.

The implementation layer records:

- Rationale for choosing implementation strategies
- Decision basis when multiple options existed
- Constraints (compatibility, performance, dependencies, etc.)
- Items intentionally decided "not to implement"
- Prerequisites that strongly affect implementation but don't appear in specifications

The implementation layer is **not a place to write actual code**.
It is also not intended to provide copy-paste implementation examples.

The role of this document is to enable tracking of
"why the implementation turned out this way" afterwards,
and to prevent the cognitive gap that occurs between design (specifications) and implementation (tasks).

The final deliverables of implementation are reflected in tasks and code,
but the decision-making process is preserved in implementation.

## What deckrd Does NOT Do

deckrd does not aim to:

- Automatically generate code
- Enforce implementation details
- Impose a single development methodology (TDD / BDD, etc.)

deckrd is purely an **assistive framework for organizing thoughts and decisions**.
