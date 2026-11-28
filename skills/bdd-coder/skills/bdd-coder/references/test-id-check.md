# Test ID Checker

Checks that the test cases carry test IDs, belong to their group, and are not duplicated.
In `ts`, `js`, and `dart`, it also checks that a case ID in a `for` block ends with `-`,
where its branch follows.
The checker reads one simple way of writing tests. It is not a language parser.

## Run

`<BDD_CODER_SKILL_DIR>` is the absolute path of the directory containing `SKILL.md`.
Run from the target repository:

```bash
bash "<BDD_CODER_SKILL_DIR>/scripts/check-test-ids.sh" [--lang <lang>[,<lang>...]]
```

- `--lang` also accepts `--lang=<list>`. Without it, only `sh` is checked.
- `-h` or `--help` prints the usage and exits 0.
- An unknown option, an extra argument, or an unknown language exits 1 and runs no check.
- An empty element of `--lang`, as in `sh,`, is an unknown language.
- The git toplevel of the current directory is scanned.

## Writing tests

A declaration is one line: a keyword at the start of the line, then a quoted title that holds the ID.

```text
describe('T-CFG-GI: getInstance', ...)
  it('[Normal] T-CFG-GI-01: returns the same instance', ...)
```

| `--lang`       | Files                                              | Group keyword                       | Case keyword             |
| -------------- | -------------------------------------------------- | ----------------------------------- | ------------------------ |
| `sh` (default) | `*.spec.sh`                                        | `Describe` `Context` `ExampleGroup` | `It` `Example` `Specify` |
| `ts`           | `*.spec.ts` `*.spec.tsx`                           | `describe(`                         | `it(` `test(`            |
| `js`           | `*.spec.js` `*.spec.jsx` `*.spec.mjs` `*.spec.cjs` | `describe(`                         | `it(` `test(`            |
| `dart`         | `*.spec.dart`                                      | `group(`                            | `test(` `testWidgets(`   |
| `go`           | `*_test.go`                                        | `t.Run(`                            | `t.Run(`                 |

- A group ID is `T-` and two or more segments of uppercase letters and digits, joined by `-`.
- A case ID is the group ID declared last in the file plus `-NN` or `-NN-NN`.
- In `ts`, `js`, and `dart`, the title of a case may start on the line after `it(`, `test(`,
  or `testWidgets(` ([wrapped case declarations](test-id-check-syntax.md#wrapped-case-declarations)).

In table-driven cases, write the ID up to its sequence number and expand only the branch,
as `T-CFG-GI-03-${branch}`. The form of an ID as written is:

```text
Outside a loop block                 : T-([A-Z0-9]+-)+[A-Z0-9]+-?   the last - is optional
In a for block (ts, js, dart only)   : T-([A-Z0-9]+-)+[A-Z0-9]+-    the last - is required
```

## What is checked

| No | Error                                                                        | Fix                                                |
| -- | ---------------------------------------------------------------------------- | -------------------------------------------------- |
| 1  | A case declaration whose title holds no case ID                              | Write the case ID literally in the title           |
| 2  | A case ID that is not the group ID declared last in the file plus `-NN[-NN]` | Match the case ID to the group above it            |
| 3  | A group ID or a case ID declared twice among the checked files               | Use another sequence number or target abbreviation |
| 4  | A selected language with no test file, or with no group ID                   | Check `--lang` and the file names                  |
| 5  | A listing that fails, or a test file that cannot be read                     | Check the path and its permissions                 |
| 6  | In `ts`, `js`, `dart`: a case ID in a `for` block that does not end with `-` | End the ID with `-` and add the branch variable    |

Errors 1, 2, 3, and 6 name the file and the line, the keyword line for a wrapped case declaration.
Error 4 names the language. Error 5 names the file or the language.
Error 6 reads `case ID without a variable branch in a loop: <ID>`.

The checker exits 1 after it reports all errors.
It exits 0 with a count of files, group IDs and case IDs when there is none.

## More documents

Read these only when you need them.

| Document                                                 | Read it when                                                                    |
| -------------------------------------------------------- | ------------------------------------------------------------------------------- |
| [test-id-check-syntax.md](test-id-check-syntax.md)       | An error is unclear, a loop or wrapped declaration is involved, or for limits   |
| [test-id-check-extending.md](test-id-check-extending.md) | You change the checker or add a language, or need the requirements              |
| [test-abbr-check.md](test-abbr-check.md)                 | You check that the target abbreviations are unique (another script checks them) |
