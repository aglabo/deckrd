# Test Abbreviation Checker

Checks that every target abbreviation is declared only once in the project.

## Run

`<BDD_CODER_SKILL_DIR>` is the absolute path of the directory containing `SKILL.md`.
Run from the target repository:

```bash
bash "<BDD_CODER_SKILL_DIR>/scripts/check-test-abbrs.sh"
```

`-h` or `--help` prints the usage and exits 0.
Any other argument exits 1 and runs no check.

## What is read

Every module declaration, `docs/.deckrd/**/workspaces/module/module.md`.
The abbreviation table is under the heading `## テスト対象の略語`.
The first column holds the abbreviation in backquotes.

- A heading is a line of one or more `#` followed by a space or a tab.
  Spaces and tabs at its end are ignored. The table ends at the next heading.
- Lines inside a fenced code block, opened with three backquotes or tildes, are not read.
  A line of backquotes opens no block when another backquote follows on it (inline code).

No test file is read.

## What is checked

Each abbreviation appears exactly once across all module declarations.

It fails when:

- An abbreviation appears twice, in one table or in two
- The declarations cannot be listed, or one cannot be read
- A declaration ends inside a fenced code block
- No abbreviation is found

The error names the abbreviation and the declarations that hold it.
All duplicates are reported, and the script exits 1.
It exits 0 with a count of abbreviations and declarations when there is no error.

The tables are not compared with the tests.

## Scan root

The git toplevel of the current directory.
The current directory itself is scanned outside a git repository, or when git is not installed.
Override with `TEST_ID_CHECK_ROOT`; git is then not called.
Module declarations are read from `docs/.deckrd` (override with `MODULE_DOCS_SUBDIR`).

Any other git failure, such as `detected dubious ownership`, runs no check and exits 1.
The error is one line: `Error: cannot find the git toplevel: <first line of the git message>`.
