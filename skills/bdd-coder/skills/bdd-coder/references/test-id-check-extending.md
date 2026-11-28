<!-- textlint-disable
  ja-technical-writing/sentence-length,
  ja-technical-writing/max-comma -->

# Test ID Checker: Extending

Read this only to change the checker or to add a language.
To run the checker, see [test-id-check.md](test-id-check.md).

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
  track_loop_block "$2" '//'
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
| `parse_title_id`          | `test-id.lib.sh`     | Read the ID of a title and whether it is a group or case. Set `_ID_TRAILING_HYPHEN` if the ID as written ends with `-`       |
| `track_loop_block`        | `test-id.lib.sh`     | Track `for` blocks. The optional 2nd argument is the line comment marker; without it, no comment is dropped                  |

- The three patterns are extended regular expressions.
  They match a group declaration, a case declaration, and a line that starts with a case keyword.
- The first two end with the quote and the rest of the line, as `${_QUOTE}(.*)`.
- The third decides when a case keyword without a title is reported.
  `sh` accepts a space, a tab or the line end after it.
  A [wrapped case declaration](test-id-check-syntax.md#wrapped-case-declarations) also needs the line to end with `(`
  and the third pattern to match the whole line, aside from the CR of a CRLF line.
  Without the next line, `count_line_declaration` reads no declaration as wrapped.
- `read_declaration` reads one line only, so it does not read wrapped titles.
  The `go` plugin calls it directly.
- Write a literal `.` in a keyword as `[.]`, such as `t[.]Run`.
- When a group and a case are the same call, the handler tells them apart.
  See the `go` plugin, which uses the form of the ID.
- Plugins share one shell. Put the plugin ID in the names of the handler and the patterns.
- A plugin is loaded once for each of its selected languages. Declare nothing `readonly`.

For the loop check ([error 6](test-id-check.md#what-is-checked)):

- Call `track_loop_block` for each line in order, before counting the declaration of that line.
- `count_case_declaration` reports the error when `_IN_LOOP` is non-empty
  and `_ID_TRAILING_HYPHEN` is empty.
- A handler that never calls `track_loop_block` gets no loop check, as in `sh` and `go`.
- `read_file_lines` resets the state for each file with `group_id_reset` and `loop_block_reset`.
  A plugin does not call them.

Only the plugins of the selected languages are loaded.
A selected plugin that is missing or fails to load exits 1 and runs no check.
So does an empty `LANG_FILES`, or a `LANG_HANDLER` that names no defined function.

## Requirements

The script needs `bash` 4.3+, `grep`, `sed`, `sort` and `find`.
`rg` and `git` are used when present.
