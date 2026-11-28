# Test ID Checker: Syntax and Limits

Reference for [test-id-check.md](test-id-check.md).
Read it when an error is unclear, or when a test uses a wrapped declaration or a loop.

## Rules

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

## Wrapped case declarations

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
the case ID, its group, duplicates, and the loop branch
(errors 1 to 3 and 6 in [What is checked](test-id-check.md#what-is-checked)).
An error on a wrapped declaration names the line of the keyword.

`go` does not read wrapped titles.
A line that starts with `t.Run(`, after optional spaces and tabs, and ends there is error 1 (`no case ID`).
Neither does `sh`: an `It` line without a title is error 1, even when the next line starts with a quote.

## Table-driven cases

Write the ID up to its sequence number literally and expand only the branch.
A trailing `-` is dropped, so the checker reads `T-CFG-GI-03` from each of these:

```text
It "T-CFG-GI-03-${branch}: ..."
it(`T-CFG-GI-03-${branch}: ...`, ...)
t.Run("T-CFG-GI-03-"+tc.name, ...)
```

The form of an ID as written depends on where its declaration is:

```text
Outside a loop block                 : T-([A-Z0-9]+-)+[A-Z0-9]+-?   the last - is optional
In a for block (ts, js, dart only)   : T-([A-Z0-9]+-)+[A-Z0-9]+-    the last - is required
```

A case ID also ends with `-NN` or `-NN-NN`, before that last `-`, in both places.
Letters, digits, and `-` right after the last `-` are read as part of the ID,
so `T-CFG-GI-03-case-${n}` is error 1 in both places.

The blocks are those of `for (...) {`, `for await (...) {`, and `await for (...) {`.
[Loop blocks](#loop-blocks) tells where a block starts and ends.
Cases after the block are not affected.

| Title in the block, as written | Result                                                                    |
| ------------------------------ | ------------------------------------------------------------------------- |
| `T-CFG-GI-03-$branch`          | Pass                                                                      |
| `T-CFG-GI-03-${row.branch}`    | Pass                                                                      |
| `T-CFG-GI-03-02-${x}`          | Pass                                                                      |
| `'T-CFG-GI-03-' + branch`      | Pass                                                                      |
| `T-CFG-GI-03-: title`          | Pass: no variable is looked for after the `-`                             |
| `T-CFG-GI-03`                  | [Error 6](test-id-check.md#what-is-checked): no last `-`                  |
| `T-CFG-GI-03-01`               | [Error 6](test-id-check.md#what-is-checked): a fixed branch is not enough |

## Loop blocks

The checker finds `for` blocks line by line. It does not parse the language or count braces.

- A `for` line starts with `for (`, `for await (`, or `await for (`, after optional spaces and tabs.
  The space before `(` is optional, as in `for(`.
- A `for` line that ends with `{` opens a block.
- Any other `for` line starts a header that may span lines:
  - The block opens at a line that starts with `)`, `]`, or `}`
    at the indentation of the `for` line, and ends with `{`.
  - Blank lines and deeper lines before it are skipped.
  - Any other line drops the header. Another `for` line, at any depth, replaces it.
- A block ends at a line that starts with `}` at the indentation of the `for` line
  and does not end with `{`. So `} else {` does not end it.
- Other lines in a block do not change it. An inner `for` loop is part of the outer block.

## Declarations and errors

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

## What is not checked

### Lines that are not declarations

These lines are not declarations. Their IDs are not read, and duplicates among them are not found.

- Derived keywords, such as `xIt` or `fit(`
- Modified calls, such as `it.each(` or `test.skip(`
- A call that does not start its line, such as `if !t.Run(`
- A wrapped group declaration, a line that ends with `describe(` or `group(`.
  The cases after it are checked against the group ID read before it,
  so a case of the wrapped group is error 2 unless its ID also fits that earlier group.

### Loop branch check

Error 6 has these limits, and those of loop tracking in [Comments and strings](#comments-and-strings).

#### Scope

- `go` and `sh` are not covered.
  Their loop cases are expected to be written as `<testID>-{branch}` already.
- Only the last `-` of the ID is checked. No variable is looked for after it,
  so a literal `T-CFG-GI-03-: title` passes.
- The values a branch takes are not read, so duplicate branch values are not found.
- Only `for` is tracked. `while`, `do`, and callback loops such as `forEach` are not.

#### `for` shapes that open no block

The cases in these loops are not checked.

- A header whose closing line is indented deeper than the `for` line, such as `i++) {`.
  `dart format` can write a long header this way, such as a split `in` clause
  of `for-in` or `await for`. A header that it closes with `]) {`
  at the `for` indentation is checked.
- A `for` that closes on its own line, as `for (...) { ... }`
- A `for` without braces, as `for (...) stmt;`
- An opening brace on its own line
- A `for` that does not start its line, as `outer: for` or `else for`
- A `for` line that ends in a block comment, as `for (...) { /* note */`

#### Block end

Indentation is compared as written, spaces and tabs.
A block whose closing `}` is not at the exact indentation of the `for` line stays open
until a matching line or the end of the file. So later cases can be false errors.

### Comments and strings

A line inside a comment block or a multi-line string is not told apart.
It is read as a declaration when a keyword starts it. A heredoc body is the same.

Loop tracking, used for error 6, reads such lines as code too.

- A `for (...) {` line in one, without its closing `}`, opens a block.
  Later cases can then be false errors, not only missed ones.
- In a block, a line in one that looks like the closing `}` ends the block early.
  The later cases of the loop are then not checked.

Only loop tracking drops line comments. Declarations are read from the whole line.

- A line is cut from `//` to its end. So `} // end` ends a block,
  and a `//` comment line counts as blank.
- A `//` in a URL, such as `http://...`, does not cut the line.
- Any other `//` in a string literal cuts it too, so such a `for` line may open no block.

## Scan root

The git toplevel of the current directory.
The current directory itself is scanned outside a git repository, or when git is not installed.
Override with `TEST_ID_CHECK_ROOT`; git is then not called. No module declaration is read.

Any other git failure, such as `detected dubious ownership`, exits 1 and runs no check.
The error is one line: `Error: cannot find the git toplevel: <first line of the git message>`.

Hidden directories and `node_modules` are not listed.
With `rg`, ignored files are not listed either.
