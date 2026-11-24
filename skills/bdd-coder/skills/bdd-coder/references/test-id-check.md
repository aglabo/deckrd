# Test ID Checker

Detects missing, misplaced and duplicated test IDs in ShellSpec files.
The script is self-contained.
It sources nothing from this repository, so it works when bdd-coder is installed as a plugin.

## Run

`<BDD_CODER_SKILL_DIR>` is the absolute path of the directory containing `SKILL.md`.
Use the path you loaded it from.
Replace it first, then run from the target repository:

```bash
bash "<BDD_CODER_SKILL_DIR>/scripts/check-test-ids.sh" <mode>
```

| Mode                   | Check                                                                  |
| ---------------------- | ---------------------------------------------------------------------- |
| `--scopes`             | A: `test_scope` and target abbreviation uniqueness, ownership coverage |
| `--module <ns>/<mod>`  | B: ID coverage, case membership, duplication and scope consistency     |
| `--targets <ns>/<mod>` | D: abbreviation table matches the targets the tests use                |
| `--all`                | A, B, D for every module, plus C: repository-wide group ID duplication |

Exit 0 means every requested check passed; exit 1 means a check failed or the mode is unknown.

## Scan root

The git toplevel of the current directory (the current directory itself outside git).
Override with `TEST_ID_CHECK_ROOT`. Module declarations are read from `docs/.deckrd`
(override with `MODULE_DOCS_SUBDIR`).

## Table-driven and fixture cases

Write the ID up to its sequence number literally and expand only the branch:
`T-CFG-GI-03-${branch}`. The checker reads `T-CFG-GI-03`; the branch is not checked.

## Requirements

- `bash` 4+ (associative arrays)
- `gawk` or `awk` (`gawk` is preferred; set `AWK` to force one)
- `sed`, `sort`, `find`
- `rg` and `git`, used when present
