# Test ID Checker

Checks that the test cases carry test IDs, belong to their group, and are not duplicated.
The target abbreviations are checked by another script (see [test-abbr-check.md](test-abbr-check.md)).

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

## Writing tests

A declaration is one line: a keyword, then a title literal that holds the ID,
except a [wrapped case declaration](#wrapped-case-declarations) in `ts`, `js`, and `dart`.

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

### Rules

- A keyword starts its line. Only spaces and tabs may precede it.
  A UTF-8 byte order mark at the start of a file is ignored.
- The title literal starts right after the keyword, with a quote: `'`, `"`, or a backquote.
  In `sh`, spaces or tabs separate the keyword and the quote.
  In a wrapped case declaration, it starts the next line, after optional spaces and tabs.
  A keyword followed by anything else, such as `It=1`, is not a declaration. The line end is allowed.
- The title ends at the next quote of the same kind. Text after it is not read.
- The ID is the first word of the title that starts like `T-<segment>-`.
  Words may precede it, such as `Then: [Normal]`, separated by spaces or tabs.
- The ID ends at the first character other than a letter, a digit, or `-`.
  `T-CFG-GI-01:` and `T-CFG-GI-01_x` both read as `T-CFG-GI-01`.

An ID is `T-` followed by two or more segments joined by `-`.
A segment is uppercase letters and digits.

| ID    | Form                         | Example       |
| ----- | ---------------------------- | ------------- |
| Group | Any ID that is not a case ID | `T-CFG-GI`    |
| Case  | `<group form>-NN[-NN]`       | `T-CFG-GI-01` |

- A case ID ends with `-NN` or `-NN-NN` after at least two segments.
- A word with other characters, such as `T-CFG-GI-01a`, is not an ID.
- The checker does not limit the length of a segment.

### Wrapped case declarations

The title of a case may start on the line after its keyword:

```text
it(
  'T-CFG-GI-01: returns the same instance',
```

- In `ts` and `js`, the keyword line ends right after the `(` of `it(` or `test(`.
  In `dart`, it ends right after the `(` of `test(` or `testWidgets(`.
  Even spaces or tabs after the `(` stop the wrapping.
  The CR of a CRLF line is ignored.
- The next line starts, after optional spaces and tabs, with a string literal.
  That literal is read as the title.
  Only that line is read, so a blank line before the literal stops the wrapping.
- The literal is a plain one, quoted by `'`, `"`, or a backquote.
  A Dart raw string, such as `r'...'`, is not one.
  A Dart triple-quoted string, such as `'''...'''`, is not read as a title either.
  Both are error 1, on the keyword line as well as on the next line.
- A case keyword with no title literal on its line, and not wrapped this way, is error 1 (`no case ID`).

A wrapped title gets the same checks as a title on the keyword line:
the case ID, its group, and duplicates (errors 1 to 3 in [What is checked](#what-is-checked)).
An error on a wrapped declaration names the line of the keyword.

`go` does not read wrapped titles.
A line that starts with `t.Run(`, after optional spaces and tabs, and ends there is error 1 (`no case ID`).
Neither does `sh`: an `It` line without a title is error 1, even when the next line starts with a quote.

### Table-driven cases

Write the ID up to its sequence number literally and expand only the branch.
A trailing `-` is dropped, so the checker reads `T-CFG-GI-03` from each of these:

```text
It "T-CFG-GI-03-${branch}: ..."
it(`T-CFG-GI-03-${branch}: ...`, ...)
t.Run("T-CFG-GI-03-"+tc.name, ...)
```

## What is checked

| No | Error                                                                        |
| -- | ---------------------------------------------------------------------------- |
| 1  | A case declaration whose title holds no case ID                              |
| 2  | A case ID that is not the group ID declared last in the file plus `-NN[-NN]` |
| 3  | A group ID or a case ID declared twice among the checked files               |
| 4  | A selected language with no test file, or with no group ID                   |
| 5  | A listing that fails, or a test file that cannot be read                     |

- A group declaration without an ID, such as `Describe 'When: ...'`, is allowed.
- A case ID in the title of a group declaration declares nothing.
  It is neither counted nor checked for duplicates. `go` reads it as a case.
- `go` declares groups and cases with `t.Run(` alike. The form of the ID tells them apart.
  Every `t.Run(` line therefore needs a group ID or a case ID.
- A case keyword needs a title literal right after it,
  or on the next line in a [wrapped case declaration](#wrapped-case-declarations).
  Anything else, such as a variable title, is error 1.
  In `ts`, `js`, and `dart`, a wrapped case declaration with a title literal on the next line
  is therefore not error 1 for being wrapped. In `go` and `sh`, a wrapped case declaration is error 1.

Every error names the file and the line. The checker exits 1 after it reports all of them.
It exits 0 with a count of files, group IDs and case IDs when there is none.

## What is not checked

These lines are not declarations. Their IDs are not read, and duplicates among them are not found.

- Derived keywords, such as `xIt` or `fit(`
- Modified calls, such as `it.each(` or `test.skip(`
- A call that does not start its line, such as `if !t.Run(`
- A wrapped group declaration, a line that ends with `describe(` or `group(`.
  The cases after it are checked against the group ID read before it,
  so a case of the wrapped group is error 2 unless its ID also fits that earlier group.

A line inside a comment block or a multi-line string is not told apart.
It is read as a declaration when a keyword starts it. A heredoc body is the same.

## Scan root

The git toplevel of the current directory.
The current directory itself is scanned outside a git repository, or when git is not installed.
Override with `TEST_ID_CHECK_ROOT`; git is then not called. No module declaration is read.

Any other git failure, such as `detected dubious ownership`, exits 1 and runs no check.
The error is one line: `Error: cannot find the git toplevel: <first line of the git message>`.

Hidden directories and `node_modules` are not listed.
With `rg`, ignored files are not listed either.

## Layout

| Path                                                  | Content                                          |
| ----------------------------------------------------- | ------------------------------------------------ |
| `scripts/check-test-ids.sh`                           | Command line, plugin loading, file listing       |
| `scripts/check-ids/languages.sh`                      | The language table: the plugin of each language  |
| `scripts/check-ids/plugins/<id>-id-checker.plugin.sh` | Plugins: how the lines of a language are read    |
| `scripts/check-ids/libs/`                             | Reading, counting and checking, for this checker |
| `scripts/libs/`                                       | Shell libraries shared with other scripts        |

All paths are located relative to `check-test-ids.sh` or to the plugin.
Nothing is sourced from the checked repository.

## Adding a language

Add a plugin file, `scripts/check-ids/plugins/<id>-id-checker.plugin.sh`.
Then add one row, `[<lang>]=<id>`, to the table in `scripts/check-ids/languages.sh`:

```bash
declare -gA LANG_PLUGIN=([sh]=sh [ts]=tsjs [js]=tsjs [dart]=dart [go]=go)
```

The table alone defines the values that `--lang` accepts.
A plugin file without a row is not selectable.

A plugin loads the libraries it uses and defines a line handler.
It sets two values with `<lang>` as the key.
One plugin may serve several languages, such as `tsjs` for `ts` and `js`.
It must set both values for each of them.

```bash
. "${BASH_SOURCE[0]%/*}/../libs/report.lib.sh" || return 1
. "${BASH_SOURCE[0]%/*}/../libs/test-id.lib.sh" || return 1
. "${BASH_SOURCE[0]%/*}/../libs/declaration.lib.sh" || return 1

declare -g _TSJS_GROUP_PATTERN="^[[:blank:]]*(describe)[(]${_QUOTE}(.*)"
declare -g _TSJS_CASE_PATTERN="^[[:blank:]]*(it|test)[(]${_QUOTE}(.*)"
declare -g _TSJS_CASE_START_PATTERN='^[[:blank:]]*(it|test)[(]'

check_tsjs_line() {
  count_line_declaration "$1" "$2" "$_TSJS_GROUP_PATTERN" "$_TSJS_CASE_PATTERN" "$_TSJS_CASE_START_PATTERN" "${3-}"
}

LANG_FILES[ts]='*.spec.ts *.spec.tsx'
LANG_HANDLER[ts]=check_tsjs_line
LANG_FILES[js]='*.spec.js *.spec.jsx *.spec.mjs *.spec.cjs'
LANG_HANDLER[js]=check_tsjs_line
```

| Table          | Value                                |
| -------------- | ------------------------------------ |
| `LANG_FILES`   | File name globs, separated by spaces |
| `LANG_HANDLER` | The name of the line handler         |

The handler is called for each line with `<file>:<line number>`, the line and the next line.
The next line is the last argument, and it is an empty string for the last line of a file.
The handler must return 0, otherwise the checker stops with no message (`set -e`).
Everything that differs between languages belongs in the plugin. The libraries do not branch on the language.

| Function                  | Library              | Use                                                                                                                          |
| ------------------------- | -------------------- | ---------------------------------------------------------------------------------------------------------------------------- |
| `count_line_declaration`  | `declaration.lib.sh` | Read a line with three patterns and count it. The optional next line, its 6th argument, is used to read a wrapped case title |
| `read_declaration`        | `declaration.lib.sh` | Read a line as a declaration, without counting it                                                                            |
| `count_group_declaration` | `declaration.lib.sh` | Count a group ID. A title without one adds nothing                                                                           |
| `count_case_declaration`  | `declaration.lib.sh` | Count a case ID, or report that there is none                                                                                |
| `parse_title_id`          | `test-id.lib.sh`     | Read the ID of a title and whether it is a group or case                                                                     |

- The three patterns are extended regular expressions.
  They match a group declaration, a case declaration, and a line that starts with a case keyword.
- The first two end with the quote and the rest of the line, as `${_QUOTE}(.*)`.
- The third decides when a case keyword without a title is reported.
  `sh` accepts a space, a tab or the line end after it.
  A [wrapped case declaration](#wrapped-case-declarations) also needs the line to end with `(`
  and the third pattern to match the whole line, aside from the CR of a CRLF line.
  Without the next line, `count_line_declaration` reads no declaration as wrapped.
- `read_declaration` reads one line only, so it does not read wrapped titles.
  The `go` plugin calls it directly.
- Write a literal `.` in a keyword as `[.]`, such as `t[.]Run`.
- When a group and a case are the same call, the handler tells them apart.
  See the `go` plugin, which uses the form of the ID.
- Plugins share one shell. Put the plugin ID in the names of the handler and the patterns.
- A plugin is loaded once for each of its selected languages. Declare nothing `readonly`.

Only the plugins of the selected languages are loaded.
A selected plugin that is missing or fails to load exits 1 and runs no check.
So does an empty `LANG_FILES`, or a `LANG_HANDLER` that names no defined function.

## Requirements

The script needs `bash` 4.3+, `grep`, `sed`, `sort` and `find`.
`rg` and `git` are used when present.
