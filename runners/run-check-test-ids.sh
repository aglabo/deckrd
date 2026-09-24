#!/usr/bin/env bash
# src: ./runners/run-check-test-ids.sh
# @(#) : test case ID checker runner
#
# Copyright (c) 2026- atsushifx <https://github.com/atsushifx>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

# shellcheck disable=SC1091

set -euo pipefail

# shellcheck source=runners/libs/init-vars.lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/libs/init-vars.lib.sh"
# shellcheck source=runners/libs/get-filelist.lib.sh
. "${SCRIPT_ROOT}/libs/get-filelist.lib.sh"

# Repository root the checks scan (override in tests to point at a fixture tree)
TEST_ID_CHECK_ROOT="${TEST_ID_CHECK_ROOT:-${PROJECT_ROOT}}"

# Directory holding module declarations, relative to the scan root
MODULE_DOCS_SUBDIR="${MODULE_DOCS_SUBDIR:-docs/.deckrd}"

# Path of a module declaration, relative to its module directory. Declared next to
# MODULE_DOCS_SUBDIR because the two only make sense together: one locates the docs
# root, the other the declaration inside a module. The canonical definition is §4 of
# docs/.deckrd/rules/deckrd-rule-document-model.md, and the generator declares the
# same value in skills/deckrd/skills/deckrd/scripts/module.sh - keep them equal.
readonly MODULE_META_SUBDIR='workspaces/modules'

# The four constants below are the whole grammar the scanner knows, declared together
# because they only make sense as two pairs: one declaration pattern and one ID pattern
# per layer. §6.1 forbids extracting both layers with one pattern, and keeping the
# pairs side by side is what makes a later edit to one of them notice the other.
# Repetition counts are spelled out as repeated atoms rather than as `{2,4}`, because
# the scanner's awk is mawk under WSL and mawk has no interval expressions; the
# language each pattern describes is the same either way.

# ShellSpec group declaration lines; group ID extraction is restricted to these (§6.1).
# All nine spellings ShellSpec maps to block_example_group, `x` and `f` prefixes
# included: a spelling left out here makes the group IDs declared with it invisible,
# and check C then reads their duplicates as "none found".
readonly GROUP_DECL_PATTERN='^[[:space:]]*[xf]?(ExampleGroup|Describe|Context)[[:space:]]'

# Test group ID grammar (§5.1): `T-<scope>-<target>`, with exactly one target segment
readonly GROUP_ID_PATTERN='T-[A-Z0-9][A-Z0-9][A-Z0-9]?[A-Z0-9]?-[A-Z0-9]+'

# ShellSpec case declaration lines; case ID extraction is restricted to these (§6.1).
# All nine spellings ShellSpec maps to block_example. `Todo` is deliberately absent:
# it is a placeholder that carries no ID, so counting it as a case declaration would
# report every one as unidentified. The trailing `[[:space:]]` is what separates
# `Example` from `ExampleGroup`, which the group pattern above owns.
readonly CASE_DECL_PATTERN='^[[:space:]]*[xf]?(Example|Specify|It)[[:space:]]'

# Test case ID grammar (§5.1): a group ID plus a sequence number and an optional branch.
# Written as the group ID grammar extended, because that prefix relation is the one
# §6.1 warns not to blur - the two are matched against different declaration lines and
# never against the same one, so a case ID can never be read as a group ID.
readonly TEST_ID_PATTERN="${GROUP_ID_PATTERN}-[0-9][0-9](-[0-9][0-9])?"

# Grammar of the `test_scope` a module declares (testing guidelines §5.1)
readonly TEST_SCOPE_PATTERN='^[A-Z0-9]{2,4}$'

# Heading that introduces the target abbreviation table in module.md (§5.2)
readonly TARGET_TABLE_HEADING='テスト対象の略語'

# Memoized reader results, keyed by the file they were read from. A full run reads the
# same handful of module.md files and the same spec file list dozens of times, and on
# Windows every re-read costs a fork plus an awk exec. The caches live in this process
# only and are never written to disk: a stale on-disk cache would read as "no duplicate
# found", which is exactly the failure this checker exists to catch.
declare -A _MODULE_SCALAR_CACHE=()
declare -A _MODULE_OWNS_CACHE=()
declare -A _MODULE_TARGETS_CACHE=()

# Compiled `owns` globs, keyed by the glob itself. The conversion depends on nothing but
# its argument, so this entry never goes stale; it is cleared with the rest for symmetry.
declare -A _GLOB_REGEX_CACHE=()

# The whole repository's group and case declarations, indexed six ways from one
# traversal. Checks B, C and D each want a different cut of the same records, and
# re-reading the tree per check costs one awk exec per check; scanning once and
# indexing in-process turns those re-reads into array lookups. Values are
# newline-separated lists with a trailing newline, the same shape read_module_owns
# records (§6.1).
# The group indexes mirror the case ones exactly - by file for the declarations a file
# makes, by ID for the files that claim it - because §5.4 asks the same two questions
# of both layers. _CASE_GROUP_BY_RECORD is the third shape: one record per case ID
# naming the group it sits under, plus the file and line, because a case-membership
# violation has to be reported at the declaration that commits it.
# Only files and IDs the scan actually produced a record for get a key: the checks
# derive their answers from the records, so an empty entry would be indistinguishable
# from a file that was never scanned. Like every other cache here these live in this
# process only, because a stale on-disk copy would read as "no duplicate found".
# Every answer the checks give is derived from these: check B through the four
# load_indexed_* accessors, check C and check D through the group indexes, and the
# location of a reported ID through locate_group_id or locate_case_id. No check reads
# a spec file a second time; the public scanners stay for callers that name a file
# this traversal never enumerated.
declare -A _GROUP_IDS_BY_FILE=()
declare -A _GROUP_FILES_BY_ID=()
declare -A _CASE_IDS_BY_FILE=()
declare -A _CASE_FILES_BY_ID=()
declare -A _CASE_GROUP_BY_RECORD=()
declare -A _UNIDENT_BY_FILE=()

# Spec file list cache, plus the scan root it was built from. The root is part of the
# validity condition because the tests repoint TEST_ID_CHECK_ROOT at a fresh fixture
# tree; an empty list is a legitimate cached value, so a separate flag marks validity.
_SPEC_FILES_CACHE=''
_SPEC_FILES_CACHE_ROOT=''
_SPEC_FILES_CACHE_VALID=0

# Validity of the six indexes above, on the same terms as the spec file list cache:
# the root they were built from, because the tests repoint TEST_ID_CHECK_ROOT at a
# fresh fixture tree, and a separate flag, because a repository with no declaration at
# all is a legitimate result that leaves every index empty.
_SPEC_RECORDS_ROOT=''
_SPEC_RECORDS_VALID=0

# Scratch variables the fork-free accessors fill; callers copy them into their own
# locals. The middle four are the cuts of the spec record indexes the checks consume,
# and the last two the answer find_duplicate_ids leaves behind.
_MODULE_OWNS_GLOBS=()
_SPEC_FILES=()
_OWNERS=()
_GROUP_IDS=()
_CASE_IDS=()
_CASE_GROUP_RECORDS=()
_UNIDENT_RECORDS=()
_DISTINCT_IDS=()
_DUPLICATE_IDS=()

# The reference and the declaration path the two module accessors leave behind.
# Scalars rather than arrays, but the same contract: the caller copies the answer
# into a local before calling anything that could fill the same variable.
#
# A nameref out-parameter, as _load_indexed_entries takes, would have suited these two
# better than the arrays above and would have saved the declaration, the reset line and
# the two the spec seeds and asserts: the arrays hold cuts of the indexes that several
# consumers read, while these two are read once, immediately after the call, which is
# the shape a nameref is for. They are globals anyway to stay with the flavour the nine
# scratch variables above already set - running two out-parameter styles side by side
# for one purpose costs more than the four registration points it would save.
_MODULE_REF=''
_MODULE_FILE=''

#
# @description Drop every memoized reader result and every scratch array.
#   Nothing in a single run invalidates a cache, but the tests rebuild a fixture tree
#   per example and must not see the values read from the previous one.
# @exitcode 0 always
#
reset_check_caches() {
  _MODULE_SCALAR_CACHE=()
  _MODULE_OWNS_CACHE=()
  _MODULE_TARGETS_CACHE=()
  _GLOB_REGEX_CACHE=()
  _GROUP_IDS_BY_FILE=()
  _GROUP_FILES_BY_ID=()
  _CASE_IDS_BY_FILE=()
  _CASE_FILES_BY_ID=()
  _CASE_GROUP_BY_RECORD=()
  _UNIDENT_BY_FILE=()
  _SPEC_FILES_CACHE=''
  _SPEC_FILES_CACHE_ROOT=''
  _SPEC_FILES_CACHE_VALID=0
  _SPEC_RECORDS_ROOT=''
  _SPEC_RECORDS_VALID=0
  _MODULE_OWNS_GLOBS=()
  _SPEC_FILES=()
  _OWNERS=()
  _GROUP_IDS=()
  _CASE_IDS=()
  _CASE_GROUP_RECORDS=()
  _UNIDENT_RECORDS=()
  _DISTINCT_IDS=()
  _DUPLICATE_IDS=()
  _MODULE_REF=''
  _MODULE_FILE=''
  return 0
}

#
# @description Scan every group and case declaration of the given spec files in a
#   single awk pass (§6.1). A declaration counts as identified only when one of its
#   tokens matches the ID grammar in full, so a malformed ID reads the same as no ID
#   at all. Every public scanner is a thin wrapper over this one traversal.
# @arg $@ string Spec file paths (absolute or relative to the current directory)
# @stdout One record per declaration, always five tab separated fields, with the
#   variable-length content last:
#     `G<TAB><group id><TAB><file><TAB><line><TAB>`
#     `I<TAB><case id><TAB><file><TAB><line><TAB><enclosing group id, or empty>`
#     `U<TAB><file><TAB><line><TAB><TAB><declaration text>`
#   `G` and `I` come one per well-formed ID occurrence, `U` one per case declaration
#   assigning none. Records stay in file argument order and each names the declaration
#   it came from. Never sorted and never de-duplicated; the wrappers decide.
#   A reader peels the leading four fields one separator at a time, by parameter
#   expansion or by offset, and keeps the remainder whole. `IFS=$'\t' read -r` with
#   five variables cannot be used: Bash counts a tab as IFS whitespace, so the two
#   adjacent tabs of a `U` record collapse into one separator and every field after
#   them lands one variable too early. load_spec_records peels by parameter expansion
#   and find_unidentified_cases by `substr`, for that reason and no other.
# @stderr One warning per unreadable argument, as `grep` emitted before the traversal
#   was merged into awk.
# @exitcode 0 always
#
scan_spec_declarations() {
  # Also keeps awk from reading stdin when the caller has no file to scan
  [[ $# -gt 0 ]] || return 0
  # gawk aborts the whole run on the first unreadable argument and never reads the
  # files behind it, which would silently shorten the ID list and turn checks B and C
  # green. `grep` only warned and kept going, so unreadable paths are dropped here and
  # reported, leaving awk a list it can read from end to end in one pass.
  local file
  local -a readable=()
  for file in "$@"; do
    if [[ -r $file ]]; then
      readable+=("$file")
    else
      printf '%s: cannot read %s\n' "${0##*/}" "$file" >&2
    fi
  done
  # Same stdin guard as above: every argument may have been dropped
  [[ ${#readable[@]} -gt 0 ]] || return 0
  # awk's `~` matches a substring, so both ID grammars are anchored before they are
  # applied: that token-boundary full match is what keeps a case ID from reading as a
  # group ID and the other way round (§6.1)
  awk \
    -v group_decl="$GROUP_DECL_PATTERN" -v group_id="^($GROUP_ID_PATTERN)\$" \
    -v case_decl="$CASE_DECL_PATTERN" -v case_id="^($TEST_ID_PATTERN)\$" '
    # The enclosing group is not tracked through nesting: declarations appear in file
    # order, so remembering the last group ID seen is enough (§6.1). It is cleared at
    # every file boundary so a group cannot leak into the file scanned after it.
    FNR == 1 { last_group = "" }
    $0 ~ group_decl {
      count = split($0, tokens, /[^A-Za-z0-9-]/)
      # FNR, not NR: line numbers restart at 1 in every file. FILENAME is the path
      # exactly as it was passed in, so callers keep the paths they asked about.
      # Every record kind carries them, so any one traces back to its declaration
      for (i = 1; i <= count; i++) {
        if (tokens[i] ~ group_id) { printf "G\t%s\t%s\t%d\t%s\n", tokens[i], FILENAME, FNR, ""; last_group = tokens[i] }
      }
      next
    }
    $0 ~ case_decl {
      count = split($0, tokens, /[^A-Za-z0-9-]/)
      identified = 0
      for (i = 1; i <= count; i++) {
        # Every full match is emitted: one declaration may assign several IDs, and
        # the records then all carry the one file and line it was declared on
        if (tokens[i] ~ case_id) { printf "I\t%s\t%s\t%d\t%s\n", tokens[i], FILENAME, FNR, last_group; identified = 1 }
      }
      # The empty fourth field is deliberate: it keeps every record five fields wide,
      # so one peeling of four separators lands the declaration text - the one field
      # that may carry tabs of its own - in the remainder whatever the kind. The two
      # adjacent tabs it creates are exactly what rules out a multi-variable `read`
      if (!identified) { printf "U\t%s\t%d\t%s\t%s\n", FILENAME, FNR, "", $0 }
    }
  ' "${readable[@]}"
}

#
# @description Extract every group ID assigned in a group declaration (§6.1).
#   The same shape as extract_case_ids, differing only in the record kind it keeps:
#   the two IDs are never extracted by one pattern, because a group ID is a prefix of
#   the case IDs under it and mixing them would rob both checks of their meaning.
#   Occurrences are never de-duplicated per file, so same-file duplicates survive.
# @arg $@ string Spec file paths (absolute or relative to the current directory)
# @stdout One ID per occurrence, sorted; empty when no group ID is assigned
# @stderr One warning per unreadable argument; the remaining files are still scanned
# @exitcode 0 always
#
extract_group_ids() {
  [[ $# -gt 0 ]] || return 0
  # Plain `sort`, never `sort -u`, and applied once after every file has been read,
  # so the order is global across files and duplicate occurrences are preserved:
  # a group ID claimed by two files is exactly what check C looks for
  scan_spec_declarations "$@" | awk -F'\t' '$1 == "G" { print $2 }' | sort || true
}

#
# @description Extract every test case ID assigned in a case declaration (§6.1).
#   Occurrences are never de-duplicated per file, so same-file duplicates survive.
# @arg $@ string Spec file paths (absolute or relative to the current directory)
# @stdout One ID per occurrence, sorted; empty when no ID is assigned
# @stderr One warning per unreadable argument; the remaining files are still scanned
# @exitcode 0 always
#
extract_case_ids() {
  [[ $# -gt 0 ]] || return 0
  # Plain `sort`, never `sort -u`, and applied once after every file has been read,
  # so the order is global across files and duplicate occurrences are preserved.
  # Only `I` records pass: `G` records carry a group ID, which is not an assignment
  # this function reports even though it reads as the prefix of one
  scan_spec_declarations "$@" | awk -F'\t' '$1 == "I" { print $2 }' | sort || true
}

#
# @description List the case declarations that assign no well-formed test ID (§6.1).
# @arg $@ string Spec file paths (absolute or relative to the current directory)
# @stdout One tab separated `<file><TAB><line><TAB><content>` record per offending
#   declaration, in file argument order and never sorted. Tabs keep the fields
#   readable even though both a Windows path (`C:/...`) and the declaration text
#   carry colons of their own.
# @stderr One warning per unreadable argument; the remaining files are still scanned
# @exitcode 0 always
#
find_unidentified_cases() {
  [[ $# -gt 0 ]] || return 0
  # The public contract is three fields, so the record's kind and its empty group
  # field are dropped here rather than in the scanner: every scanner record stays
  # five fields wide so one peeling of four separators fits them all.
  # The text is cut out by offset rather than re-joined from split fields, because it
  # may carry tabs of its own and would come back split. The offset is computed from
  # the fields that precede it plus their separators, so it holds whatever they are.
  scan_spec_declarations "$@" | awk -F'\t' -v OFS='\t' '
    $1 == "U" {
      leading = length($1) + length($2) + length($3) + length($4) + 4
      print $2, $3, substr($0, leading + 1)
    }
  ' || true
}

#
# @description Read a scalar field from a module.md YAML frontmatter block.
#   jq cannot read frontmatter, so the block is parsed with awk.
# @arg $1 string Path to module.md
# @arg $2 string Field name
# @stdout Field value with surrounding quotes stripped; empty when undeclared
# @exitcode 0 always
#
read_module_scalar() {
  local file="$1" field="$2"
  # Unit separator: neither a field name nor a path can carry it, so the composite key
  # cannot collide the way a `:` or `/` joined one could
  local key="${field}"$'\037'"${file}"
  if [[ -n ${_MODULE_SCALAR_CACHE[$key]+x} ]]; then
    printf '%s' "${_MODULE_SCALAR_CACHE[$key]}"
    return 0
  fi
  local value=''
  if [[ -f "$file" ]]; then
    # The trailing sentinel survives the newline stripping of `$(...)`, so the cached
    # bytes replay exactly what awk wrote, trailing newline included
    value="$(
      awk -v key="$field" '
    NR == 1 && $0 == "---" { in_fm = 1; next }
    in_fm && $0 == "---" { exit }
    in_fm && index($0, key ":") == 1 {
      value = substr($0, length(key) + 2)
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", value)
      # Unwrap only a matching pair of quotes; an unbalanced quote stays in the value
      if (length(value) >= 2 && substr(value, 1, 1) == substr(value, length(value), 1) && (substr(value, 1, 1) == "\"" || substr(value, 1, 1) == "\047")) {
        unwrapped = substr(value, 2, length(value) - 2)
        # Empty quotes are a declared-but-invalid value, not an undeclared field:
        # keep the quotes so the caller format check rejects it loudly
        if (unwrapped != "") { value = unwrapped }
      }
      print value
      exit
    }
  ' "$file"
      printf 'x'
    )"
    value="${value%x}"
  fi
  _MODULE_SCALAR_CACHE[$key]="$value"
  printf '%s' "$value"
}

#
# @description Read the `owns` glob list from a module.md YAML frontmatter block
# @arg $1 string Path to module.md
# @stdout One glob per line, in declaration order; empty when undeclared
# @exitcode 0 always
#
read_module_owns() {
  local file="$1"
  if [[ -n ${_MODULE_OWNS_CACHE[$file]+x} ]]; then
    printf '%s' "${_MODULE_OWNS_CACHE[$file]}"
    return 0
  fi
  local value=''
  if [[ -f "$file" ]]; then
    value="$(
      awk '
    NR == 1 && $0 == "---" { in_fm = 1; next }
    in_fm && $0 == "---" { exit }
    in_fm && /^owns:[[:space:]]*$/ { in_owns = 1; next }
    in_owns && /^[[:space:]]*-[[:space:]]+/ {
      value = $0
      sub(/^[[:space:]]*-[[:space:]]+/, "", value)
      gsub(/^[ \t]+|[ \t]+$/, "", value)
      gsub(/^[\047"]|[\047"]$/, "", value)
      print value
      next
    }
    in_owns { in_owns = 0 }
  ' "$file"
      printf 'x'
    )"
    value="${value%x}"
  fi
  _MODULE_OWNS_CACHE[$file]="$value"
  printf '%s' "$value"
}

#
# @description Load the `owns` globs of a module into _MODULE_OWNS_GLOBS.
#   Equivalent to reading read_module_owns through `< <(...)`, minus the subshell:
#   the hot loops call this once per spec file, and a fork there dominates the run.
# @arg $1 string Path to module.md
# @sideeffect Replaces the contents of _MODULE_OWNS_GLOBS
# @exitcode 0 always
#
load_module_owns() {
  local file="$1"
  # Populates the cache on a miss; the value itself is read from the cache below
  read_module_owns "$file" >/dev/null
  _MODULE_OWNS_GLOBS=()
  local value="${_MODULE_OWNS_CACHE[$file]}"
  [[ -n "$value" ]] || return 0
  # A here-string appends a newline of its own, so the recorded one is dropped first
  mapfile -t _MODULE_OWNS_GLOBS <<<"${value%$'\n'}"
  return 0
}

#
# @description Read the target abbreviations declared in a module.md (§5.2).
#   Only the table under the abbreviation heading is read; it ends at the next heading.
# @arg $1 string Path to module.md
# @stdout One abbreviation per line, in declaration order; empty when the table is absent
# @exitcode 0 always
#
read_module_targets() {
  local file="$1"
  if [[ -n ${_MODULE_TARGETS_CACHE[$file]+x} ]]; then
    printf '%s' "${_MODULE_TARGETS_CACHE[$file]}"
    return 0
  fi
  local value=''
  if [[ -f "$file" ]]; then
    value="$(
      awk -v heading="$TARGET_TABLE_HEADING" '
    $0 ~ "^##[[:space:]]+" heading "[[:space:]]*$" { in_table = 1; next }
    in_table && /^#/ { exit }
    in_table && /^\|/ {
      split($0, cells, "|")
      value = cells[2]
      gsub(/[[:space:]`]/, "", value)
      if (value == "" || value == "略語" || value ~ /^[-:]+$/) { next }
      print value
    }
  ' "$file"
      printf 'x'
    )"
    value="${value%x}"
  fi
  _MODULE_TARGETS_CACHE[$file]="$value"
  printf '%s' "$value"
}

#
# @description Convert an `owns` glob into a fully anchored ERE.
#   `**` spans directory separators, a single `*` does not.
# @arg $1 string Glob pattern
# @stdout Anchored ERE
# @exitcode 0 always
#
glob_to_regex() {
  local glob="$1"
  glob="${glob//./[.]}"
  glob="${glob//\*\*/$'\001'}"
  glob="${glob//\*/[^\/]*}"
  glob="${glob//$'\001'/.*}"
  printf '^%s$\n' "$glob"
}

#
# @description Test whether a repository-relative path is owned by a glob
# @arg $1 string Repository-relative path
# @arg $2 string `owns` glob pattern
# @exitcode 0 when the path is owned, 1 otherwise
#
path_matches_glob() {
  local path="$1" glob="$2" regex
  # Checks A, B and D test every spec file against every glob, so this runs hundreds of
  # times over a handful of distinct globs; without the cache each call forks a subshell
  # for the command substitution, which is the single most expensive thing in the run
  if [[ -n ${_GLOB_REGEX_CACHE[$glob]+x} ]]; then
    regex="${_GLOB_REGEX_CACHE[$glob]}"
  else
    regex="$(glob_to_regex "$glob")"
    _GLOB_REGEX_CACHE[$glob]="$regex"
  fi
  [[ "$path" =~ $regex ]]
}

#
# @description List module declaration files under the scan root
# @stdout One `<ns>/<mod>/${MODULE_META_SUBDIR}/module.md` path per line, sorted; empty
#   when the docs root is absent
# @exitcode 0 always
#
list_module_files() {
  local docs_root="${TEST_ID_CHECK_ROOT}/${MODULE_DOCS_SUBDIR}"
  [[ -d "$docs_root" ]] || return 0
  # `-path`, not `-name`: only the declaration inside the metadata subdirectory counts,
  # and a `module.md` left behind at the old location must stay invisible here so that
  # check_scopes can report it as a leftover rather than scan it as a declaration.
  # `-path`'s `*` spans `/`, so the namespace may be nested any number of levels deep
  find "$docs_root" -type f -path "*/${MODULE_META_SUBDIR}/module.md" | sort
}

#
# @description List module declarations left outside the metadata subdirectory, that is,
#   at the location it replaced. The complement of list_module_files over the same
#   traversal, written next to it so the two stay exhaustive: every `module.md` under
#   the docs root is enumerated by exactly one of them, and a declaration this one
#   returns is one check_scopes reports rather than reads.
# @stdout One module.md path per line, sorted; empty when none is left behind or the
#   docs root is absent
# @exitcode 0 always
#
list_legacy_module_files() {
  local docs_root="${TEST_ID_CHECK_ROOT}/${MODULE_DOCS_SUBDIR}"
  [[ -d "$docs_root" ]] || return 0
  find "$docs_root" -type f -name 'module.md' -not -path "*/${MODULE_META_SUBDIR}/*" | sort
}

#
# @description Derive the `<ns>/<mod>` reference of a module declaration file, into
#   _MODULE_REF. Assigns instead of printing, for the fork cost spelled out on
#   module_file_of; the two are each other's inverse and stay symmetrical.
# @arg $1 string Path to module.md as produced by list_module_files
# @sideeffect Replaces _MODULE_REF
# @exitcode 0 always
#
module_ref_of() {
  # The docs root comes off the front and the file name off the back, in that order:
  # a namespace may carry slashes of its own, so only the two ends are known. No
  # trailing newline is appended, for the reason given on module_file_of.
  # The suffix peeled off the back is the metadata subdirectory as well as the file
  # name, and it is double quoted: a suffix carrying a parameter expansion is read as a
  # glob otherwise, so a namespace spelling that happened to match would silently yield
  # a shortened reference
  local ref="${1#"${TEST_ID_CHECK_ROOT}/${MODULE_DOCS_SUBDIR}/"}"
  _MODULE_REF="${ref%"/${MODULE_META_SUBDIR}/module.md"}"
  return 0
}

#
# @description Resolve a module reference to its declaration file path, into
#   _MODULE_FILE. The inverse of module_ref_of; the file is not required to exist.
#   Assigns instead of printing because every caller of these two accessors wrapped
#   them in `$( )` for functions that only expand parameters: check_module and
#   check_targets resolve a path each and check_repository derives a reference, which
#   over the four modules of this repository is 12 subshells, some 2.7 seconds of a
#   run at the 0.22-0.33s a fork costs on the Windows hosts this runs on.
# @arg $1 string Module reference (<ns>/<mod>)
# @sideeffect Replaces _MODULE_FILE
# @exitcode 0 always
#
module_file_of() {
  # No trailing newline, unlike the `printf '%s\n'` this replaces: the `$( )` that is
  # now gone used to strip it, and a path still carrying it would split the
  # "declaration not found" report over two lines. Assigned unconditionally, so a
  # reference resolved earlier is never reported in place of this one.
  # The metadata subdirectory sits between the reference and the file name, which is
  # exactly the suffix module_ref_of peels back off
  _MODULE_FILE="${TEST_ID_CHECK_ROOT}/${MODULE_DOCS_SUBDIR}/${1}/${MODULE_META_SUBDIR}/module.md"
  return 0
}

#
# @description List every spec file under the scan root
# @stdout One repository-relative path per line, sorted; empty when none exist
# @exitcode 0 always
#
list_spec_files() {
  # The scan root is part of the validity condition: the tests repoint it at a fresh
  # fixture tree, and a list carried over from the previous one would be a false report
  if [[ $_SPEC_FILES_CACHE_VALID -eq 0 || "$_SPEC_FILES_CACHE_ROOT" != "$TEST_ID_CHECK_ROOT" ]]; then
    local value
    value="$(
      get_filelist "$TEST_ID_CHECK_ROOT" '*.spec.sh' | sed 's|^\./||' | sort
      printf 'x'
    )"
    _SPEC_FILES_CACHE="${value%x}"
    _SPEC_FILES_CACHE_ROOT="$TEST_ID_CHECK_ROOT"
    _SPEC_FILES_CACHE_VALID=1
  fi
  printf '%s' "$_SPEC_FILES_CACHE"
}

#
# @description Load the spec file list into _SPEC_FILES without the subshell that
#   `mapfile < <(list_spec_files)` would cost. An empty tree yields an empty array.
# @sideeffect Replaces the contents of _SPEC_FILES
# @exitcode 0 always
#
load_spec_files() {
  list_spec_files >/dev/null
  _SPEC_FILES=()
  [[ -n "$_SPEC_FILES_CACHE" ]] || return 0
  mapfile -t _SPEC_FILES <<<"${_SPEC_FILES_CACHE%$'\n'}"
  return 0
}

#
# @description Load the module declarations that own a given spec file into _OWNERS.
#   Equivalent to reading the owners through `< <(...)`, minus the subshell: check A
#   runs this once per spec file, and a fork there throws away the reader caches every
#   time, which is what dominates the check.
# @arg $1 string Repository-relative spec file path
# @arg $@ string Module declaration file paths to test against
# @sideeffect Replaces the contents of _OWNERS
# @exitcode 0 always
#
load_owners_of() {
  local path="$1"
  shift
  _OWNERS=()
  local module glob
  for module in "$@"; do
    load_module_owns "$module"
    for glob in ${_MODULE_OWNS_GLOBS[@]+"${_MODULE_OWNS_GLOBS[@]}"}; do
      [[ -n "$glob" ]] || continue
      if path_matches_glob "$path" "$glob"; then
        _OWNERS+=("$module")
        break
      fi
    done
  done
  return 0
}

#
# @description Index every group and case declaration under the scan root from a single
#   traversal, on the same fork-free terms as the accessors above. Scanning all 34
#   spec files through one awk costs about 0.6s, while a fork costs 0.11s-0.13s on
#   Windows, so the whole run is priced in forks rather than in work: the
#   body below spends exactly two, the awk exec and the process substitution feeding the
#   loop. The first call also pays for load_spec_files, whose listing forks several times;
#   from the second call on the list is cached and only those two remain.
#   That is why the dispatch below is plain Bash. A command substitution, a pipe, a
#   here-string or a `sort` inside the loop would each add a fork per record and undo
#   the traversal this exists to share.
# @sideeffect Replaces the contents of _GROUP_IDS_BY_FILE, _GROUP_FILES_BY_ID,
#   _CASE_IDS_BY_FILE, _CASE_FILES_BY_ID, _CASE_GROUP_BY_RECORD and _UNIDENT_BY_FILE,
#   and records the root they were built from
# @exitcode 0 always
#
load_spec_records() {
  # The negation of the rebuild condition in list_spec_files, written as an early
  # return because the body below is long enough that nesting it would hurt. Two
  # things have to agree before the indexes are reused, and they cover each other:
  # reset_check_caches drops the flag when a test rebuilds the fixture tree in place,
  # and the root comparison catches a scan root repointed without a reset.
  if [[ $_SPEC_RECORDS_VALID -eq 1 && "$_SPEC_RECORDS_ROOT" == "$TEST_ID_CHECK_ROOT" ]]; then
    return 0
  fi
  # Cleared in one block, in declaration order, so a seventh index added later is
  # noticed here rather than surviving a rebuild holding the previous tree's contents
  _GROUP_IDS_BY_FILE=()
  _GROUP_FILES_BY_ID=()
  _CASE_IDS_BY_FILE=()
  _CASE_FILES_BY_ID=()
  _CASE_GROUP_BY_RECORD=()
  _UNIDENT_BY_FILE=()

  load_spec_files
  local rel
  local -a paths=()
  for rel in ${_SPEC_FILES[@]+"${_SPEC_FILES[@]}"}; do
    paths+=("${TEST_ID_CHECK_ROOT}/${rel}")
  done

  # The four trailing fields are named a/b/c/d rather than for their contents because
  # each kind lays them out differently: `G` is id/file/line/empty, `I` is
  # id/file/line/group and `U` is file/line/empty/content.
  # They are peeled by parameter expansion instead of by `IFS=$'\t' read -r kind a b c d`:
  # Bash counts a tab as IFS whitespace, so the two adjacent tabs around the empty
  # field of a `U` record collapse into one separator and its text lands one variable
  # too early. Peeling leaves the remainder - the only field that may carry tabs of
  # its own - in the last variable, which is what the five-field format exists for.
  # The scanner's stderr is deliberately left unredirected: a spec that was listed but
  # is no longer readable is warned about and left out of the indexes, and silencing
  # that would turn a shortened index into a silent pass.
  local record rest kind a b c d
  while IFS= read -r record; do
    rest="${record#*$'\t'}"
    kind="${record%%$'\t'*}"
    a="${rest%%$'\t'*}"
    rest="${rest#*$'\t'}"
    b="${rest%%$'\t'*}"
    rest="${rest#*$'\t'}"
    c="${rest%%$'\t'*}"
    d="${rest#*$'\t'}"
    # A kind with no branch is skipped, so a record type added later is inert here
    # until something asks for it, rather than corrupting an index
    case "$kind" in
    G)
      # The mirror image of the `I` branch below, field for field: §5.4 asks the same
      # two questions of both layers, so both are indexed by file and by ID
      _GROUP_IDS_BY_FILE[$b]+="${a}"$'\n'
      if [[ $'\n'"${_GROUP_FILES_BY_ID[$a]-}" != *$'\n'"${b}"$'\n'* ]]; then
        _GROUP_FILES_BY_ID[$a]+="${b}"$'\n'
      fi
      ;;
    I)
      # Every occurrence is kept here: check C counts same-file duplicates, so
      # collapsing them would hide exactly what it looks for
      _CASE_IDS_BY_FILE[$b]+="${a}"$'\n'
      # The reverse index answers "which files claim this ID", so a file that claims
      # it twice still belongs on the list once. Comparing with the newlines on both
      # sides makes the match whole-entry: a bare substring test would read an
      # already-listed `.../b.spec.sh` as covering `.../b.spec.sh.bak` too. A pattern
      # test is used rather than `grep`, which would cost a fork per record
      if [[ $'\n'"${_CASE_FILES_BY_ID[$a]-}" != *$'\n'"${b}"$'\n'* ]]; then
        _CASE_FILES_BY_ID[$a]+="${b}"$'\n'
      fi
      # An empty group field is stored as it came rather than dropped: a case sitting
      # outside every group is a membership violation (§5.4), and this record is where
      # the report of it, file and line included, is read from
      _CASE_GROUP_BY_RECORD[$b]+="${a}"$'\t'"${d}"$'\t'"${b}"$'\t'"${c}"$'\n'
      ;;
    U)
      # Stored as the scanner emitted it, file and line included, so a consumer can
      # report the offending declaration without going back to the tree
      _UNIDENT_BY_FILE[$a]+="${a}"$'\t'"${b}"$'\t'"${d}"$'\n'
      ;;
    esac
  done < <(scan_spec_declarations ${paths[@]+"${paths[@]}"})

  _SPEC_RECORDS_ROOT="$TEST_ID_CHECK_ROOT"
  _SPEC_RECORDS_VALID=1
  # Stated rather than inherited: under `set -e` the status of a `while` fed by a
  # process substitution is the loop's, not the scanner's, so it is pinned here
  return 0
}

#
# @description Flatten the entries the given spec files have in one of the by-file
#   indexes into an array, without the fork a `< <(...)` or a `$(...)` would cost.
#   The shared body of the four load_indexed_* accessors below, which differ in nothing
#   but the index they read and the scratch array they fill: the trailing newline
#   handling and the rule that a file with no entry contributes nothing live here once.
#   Never sorted and never de-duplicated - every caller either compares two counts
#   (§6.1) or reports records in the order the declarations appear.
# @arg $1 string Name of the by-file index to read
# @arg $2 string Name of the scratch array to fill
# @arg $@ string Spec file paths, as keyed in the index (absolute)
# @sideeffect Replaces the contents of the named array
# @exitcode 0 always
#
_load_indexed_entries() {
  # The locals are named apart from every global they may be pointed at: a nameref
  # that resolves to itself is a circular reference Bash refuses to expand
  local -n _source_index="$1" _target_array="$2"
  shift 2
  load_spec_records
  _target_array=()
  local file joined=''
  for file in "$@"; do
    # Pure parameter expansion on purpose: a command substitution or a pipe here would
    # cost a fork per spec file, which is what this whole index exists to avoid
    joined+="${_source_index[$file]-}"
  done
  [[ -n "$joined" ]] || return 0
  # The recorded trailing newline is dropped first; the here-string appends its own
  mapfile -t _target_array <<<"${joined%$'\n'}"
  return 0
}

#
# @description Collect the case IDs the given spec files assign, from the indexes
#   rather than from the tree. The index-derived counterpart of extract_case_ids, and
#   the reason the two exist side by side: the public scanner takes any file at all,
#   while this one can only answer for files load_spec_records enumerated. A file with
#   no entry contributes nothing, exactly as a file assigning no ID would.
#   Neither sorted nor de-duplicated. The one caller compares the number of
#   assignments against the number of distinct ones (§6.1), which no ordering can
#   change; `sort` was here only to put duplicates next to each other for a `uniq -d`,
#   and dropping it takes a fork out of check B. The public extract_case_ids still
#   sorts, because a report reads better in order - that contract lives there, not here.
# @arg $@ string Spec file paths, as keyed in the indexes (absolute)
# @sideeffect Replaces the contents of _CASE_IDS
# @exitcode 0 always
#
load_indexed_case_ids() {
  _load_indexed_entries _CASE_IDS_BY_FILE _CASE_IDS "$@"
}

#
# @description Collect the membership records of the given spec files, from the indexes
#   rather than from the tree. One record per assigned case ID, on the same terms as
#   load_indexed_case_ids, laid out as
#   `<case id><TAB><enclosing group id, or empty><TAB><file><TAB><line>`.
#   Records stay in argument order and are never sorted, so a caller reports a
#   membership violation (§5.4) in the order the declarations appear.
# @arg $@ string Spec file paths, as keyed in the indexes (absolute)
# @sideeffect Replaces the contents of _CASE_GROUP_RECORDS
# @exitcode 0 always
#
load_indexed_case_groups() {
  _load_indexed_entries _CASE_GROUP_BY_RECORD _CASE_GROUP_RECORDS "$@"
}

#
# @description Collect the group IDs the given spec files declare, from the indexes
#   rather than from the tree. The group-layer mirror of load_indexed_case_ids, on the
#   same terms: only files load_spec_records enumerated can be asked about, and no
#   occurrence is dropped, because a group ID claimed twice is exactly what checks B
#   and C look for. Never sorted: the verdict is a comparison of two counts (§6.1), so
#   the order the IDs arrive in decides nothing but the order they are reported in.
# @arg $@ string Spec file paths, as keyed in the indexes (absolute)
# @sideeffect Replaces the contents of _GROUP_IDS
# @exitcode 0 always
#
load_indexed_group_ids() {
  _load_indexed_entries _GROUP_IDS_BY_FILE _GROUP_IDS "$@"
}

#
# @description Collect the case declarations that assign no well-formed ID in the
#   given spec files, from the indexes rather than from the tree. The index-derived
#   counterpart of find_unidentified_cases, on the same terms as load_indexed_case_ids:
#   only files load_spec_records enumerated can be asked about.
#   Records stay in argument order and are never sorted, so a caller reports them in
#   the order find_unidentified_cases would have emitted them.
# @arg $@ string Spec file paths, as keyed in the indexes (absolute)
# @sideeffect Replaces the contents of _UNIDENT_RECORDS
# @exitcode 0 always
#
load_indexed_unidentified() {
  _load_indexed_entries _UNIDENT_BY_FILE _UNIDENT_RECORDS "$@"
}

#
# @description Decide whether a list of assigned IDs holds a duplicate, by comparing
#   how many assignments there are against how many of them are distinct (§6.1).
#   The counting is an associative array rather than a `sort | uniq -d` pipeline: it
#   costs no fork, and it does not care in which order the IDs arrive, where `uniq -d`
#   reports only the duplicates the extraction happened to leave adjacent. The verdict
#   is the comparison of the two counts; the list of offending IDs is read off the same
#   pass, for the report, and is never what decides the outcome.
# @arg $@ string Assigned IDs, in any order
# @sideeffect Replaces the contents of _DISTINCT_IDS and _DUPLICATE_IDS, both in order
#   of first occurrence and both free of repeats
# @exitcode 0 when the two counts agree, 1 when an ID was assigned more than once
#
find_duplicate_ids() {
  _DISTINCT_IDS=()
  _DUPLICATE_IDS=()
  local -A occurrences=()
  local id
  for id in "$@"; do
    # `(( occurrences[$id]++ ))` cannot be used here: an arithmetic command evaluating
    # to 0 exits non-zero, so under `set -e` the first ID seen would abort the run
    occurrences[$id]=$((${occurrences[$id]-0} + 1))
    # Each list is appended to at the single occurrence that makes it true, which is
    # what keeps both free of repeats without a second pass over the IDs
    case "${occurrences[$id]}" in
    1) _DISTINCT_IDS+=("$id") ;;
    2) _DUPLICATE_IDS+=("$id") ;;
    esac
  done
  # The whole check, and deliberately the last command: the caller reads its status
  [[ $# -eq ${#occurrences[@]} ]]
}

#
# @description Check A (§6.2): every `test_scope` is unique, every spec file is owned by
#   exactly one module, and no declaration is left outside the metadata subdirectory.
#   Reads declarations and file names only.
# @stdout Summary counts when the check passes
# @stderr Offending scopes and files
# @exitcode 0 Check passed
# @exitcode 1 Declaration at the old location, duplicate scope, unowned file, or
#   multiply-owned file found
#
check_scopes() {
  local docs_root="${TEST_ID_CHECK_ROOT}/${MODULE_DOCS_SUBDIR}"
  local result=0 module scope
  local -a modules=()
  mapfile -t modules < <(list_module_files)

  # Declarations left where the metadata subdirectory now goes. list_module_files matches
  # on the subdirectory, so an unmoved file is no longer enumerated: without this it would
  # be neither scanned nor reported, and its stale test_scope and owns would sit in the
  # tree claiming ownership no check ever reads
  local -a leftovers=()
  mapfile -t leftovers < <(list_legacy_module_files)
  for module in ${leftovers[@]+"${leftovers[@]}"}; do
    echo "Error: ${module}: module declaration at the old location; move it into ${MODULE_META_SUBDIR}/" >&2
    result=1
  done

  if [[ ${#modules[@]} -eq 0 ]]; then
    echo "Error: no module.md found under ${docs_root}/*/*/${MODULE_META_SUBDIR}" >&2
    return 1
  fi

  local -a declarations=()
  for module in "${modules[@]}"; do
    scope="$(read_module_scalar "$module" 'test_scope')"
    if [[ -z "$scope" ]]; then
      echo "Error: ${module}: frontmatter declares no 'test_scope'" >&2
      result=1
      continue
    fi
    if [[ ! "$scope" =~ $TEST_SCOPE_PATTERN ]]; then
      echo "Error: ${module}: test_scope '${scope}' must be 2-4 uppercase letters or digits" >&2
      result=1
      # A malformed value must not reach the duplicate check: two modules sharing it
      # would be reported as a scope collision instead of as two broken declarations
      continue
    fi
    declarations+=("${scope}"$'\t'"${module}")
  done

  local -a duplicate_scopes=()
  mapfile -t duplicate_scopes < <(
    printf '%s\n' ${declarations[@]+"${declarations[@]}"} | cut -f1 | sort | uniq -d
  )
  for scope in ${duplicate_scopes[@]+"${duplicate_scopes[@]}"}; do
    echo "Error: test_scope '${scope}' is declared by more than one module:" >&2
    printf '%s\n' "${declarations[@]}" | awk -F'\t' -v s="$scope" '$1 == s { print "  " $2 }' >&2
    result=1
  done

  local -a specs=()
  load_spec_files
  specs=(${_SPEC_FILES[@]+"${_SPEC_FILES[@]}"})
  local spec
  local -a owners=()
  for spec in ${specs[@]+"${specs[@]}"}; do
    load_owners_of "$spec" "${modules[@]}"
    owners=(${_OWNERS[@]+"${_OWNERS[@]}"})
    if [[ ${#owners[@]} -eq 0 ]]; then
      echo "Error: ${spec}: owned by no module; add it to some module's 'owns'" >&2
      result=1
    elif [[ ${#owners[@]} -gt 1 ]]; then
      echo "Error: ${spec}: owned by ${#owners[@]} modules:" >&2
      printf '  %s\n' "${owners[@]}" >&2
      result=1
    fi
  done

  if [[ $result -eq 0 ]]; then
    echo "check A: ${#modules[@]} modules, ${#specs[@]} spec files, each owned by exactly 1 module"
  fi
  return "$result"
}

#
# @description List the spec files owned by one module declaration
# @arg $1 string Path to the module.md
# @stdout One absolute spec file path per line
# @exitcode 0 always
#
list_module_spec_files() {
  local module_file="$1"
  local -a specs=() globs=()
  load_spec_files
  specs=(${_SPEC_FILES[@]+"${_SPEC_FILES[@]}"})
  # Read once for the whole traversal: the globs cannot change between spec files
  load_module_owns "$module_file"
  globs=(${_MODULE_OWNS_GLOBS[@]+"${_MODULE_OWNS_GLOBS[@]}"})
  local spec glob
  for spec in ${specs[@]+"${specs[@]}"}; do
    for glob in ${globs[@]+"${globs[@]}"}; do
      [[ -n "$glob" ]] || continue
      if path_matches_glob "$spec" "$glob"; then
        printf '%s\n' "${TEST_ID_CHECK_ROOT}/${spec}"
        break
      fi
    done
  done
}

#
# @description List the files a given ID is recorded against in one of the by-ID
#   indexes, narrowed to the given files. The shared body of locate_case_id and
#   locate_group_id, which differ in nothing but the index they read.
# @arg $1 string Name of the by-ID index to read
# @arg $2 string The ID to locate
# @arg $@ string Spec file paths to narrow the answer to
# @stdout One matching file path per line, in argument order and once per argument
# @exitcode 0 always
#
_locate_id() {
  local -n _source_index="$1"
  local id="$2"
  shift 2
  [[ $# -gt 0 ]] || return 0
  load_spec_records
  # Newlines on both sides make the comparison whole-entry, the way load_spec_records
  # builds the index: a bare substring test would read a listed `.../b.spec.sh` as
  # covering `.../b.spec.sh.bak` too
  local list=$'\n'"${_source_index[$id]-}"
  local file
  for file in "$@"; do
    [[ "$list" == *$'\n'"${file}"$'\n'* ]] && printf '%s\n' "$file"
  done
  # Under `set -e` a final `[[ ]]` that tests false would make the function fail
  return 0
}

#
# @description List the spec files that assign a given test case ID, read off the
#   reverse index and narrowed to the given files. Where an ID is reported matters as
#   much as that it is, so the answer comes from the same tokenizer that assigned it:
#   the `grep` this replaces also matched an ID sitting inside a longer leading token
#   (`XT-AAA-BB-01` read as a location of `T-AAA-BB-01`), which the scanner never
#   counted as an assignment. Location and assignment now agree; T-RUN-LCI-03 pins it.
#   Only files load_spec_records enumerated can be asked about.
# @arg $1 string Test case ID
# @arg $@ string Spec file paths to narrow the answer to
# @stdout One matching file path per line, in argument order and once per argument
# @exitcode 0 always
#
locate_case_id() {
  _locate_id _CASE_FILES_BY_ID "$@"
}

#
# @description List the spec files that declare a given group ID, read off the reverse
#   index and narrowed to the given files. The group-layer mirror of locate_case_id,
#   and what lets checks B and C name the files behind a duplicated group ID without
#   reading the tree a second time. Only files load_spec_records enumerated can be
#   asked about.
# @arg $1 string Group ID
# @arg $@ string Spec file paths to narrow the answer to
# @stdout One matching file path per line, in argument order and once per argument
# @exitcode 0 always
#
locate_group_id() {
  _locate_id _GROUP_FILES_BY_ID "$@"
}

#
# @description Check B (§6.3): within one module, every case declaration carries a
#   well-formed ID, every case ID belongs to the group it sits under, no group ID and
#   no case ID is assigned twice, and every group ID carries that module's declared
#   `test_scope`.
# @arg $1 string Module reference (<ns>/<mod>)
# @stdout Summary counts when the check passes
# @stderr Offending IDs and the files that assign them
# @exitcode 0 Check passed, or no ID is assigned yet
# @exitcode 1 Missing declaration, unidentified case, membership violation, duplicate
#   ID, or foreign scope found
#
check_module() {
  local module_ref="$1"
  # Copied into a local straight away, the convention every scratch variable in this
  # file is read under. Nothing reached from here resolves a path of its own today;
  # the copy is kept so this stays correct if one of them ever does
  module_file_of "$module_ref"
  local module_file="$_MODULE_FILE"
  if [[ ! -f "$module_file" ]]; then
    echo "Error: module '${module_ref}': declaration not found at ${module_file}" >&2
    return 1
  fi

  local scope
  scope="$(read_module_scalar "$module_file" 'test_scope')"
  if [[ -z "$scope" ]]; then
    echo "Error: ${module_file}: frontmatter declares no 'test_scope'" >&2
    return 1
  fi

  local result=0
  local -a owned=() ids=()
  mapfile -t owned < <(list_module_spec_files "$module_file")

  # Records are tab separated, so a path holding a colon (`C:/...` on Windows) and a
  # declaration text holding one cannot be mistaken for the line number. Only the
  # first two fields are peeled off, because the content field carries tabs of its own.
  # A plain `for` over the loaded records, so result=1 is set in this shell: the
  # process substitution this replaces was there to keep a pipe from losing it
  local record spec_file rest line
  load_indexed_unidentified ${owned[@]+"${owned[@]}"}
  for record in ${_UNIDENT_RECORDS[@]+"${_UNIDENT_RECORDS[@]}"}; do
    spec_file="${record%%$'\t'*}"
    rest="${record#*$'\t'}"
    line="${rest%%$'\t'*}"
    echo "Error: module '${module_ref}': case declaration has no well-formed test ID: ${spec_file}:${line}" >&2
    result=1
  done

  # Case membership (§5.4): a case ID is a sequence number inside the group it sits
  # under, so it has to carry that group's ID. The record fields are peeled one
  # separator at a time rather than read with an `IFS=$'\t' read`, because the group
  # field is empty for a case declared above every group declaration and Bash would
  # collapse the two adjacent tabs that leaves into one separator
  local group id
  load_indexed_case_groups ${owned[@]+"${owned[@]}"}
  for record in ${_CASE_GROUP_RECORDS[@]+"${_CASE_GROUP_RECORDS[@]}"}; do
    id="${record%%$'\t'*}"
    rest="${record#*$'\t'}"
    group="${rest%%$'\t'*}"
    rest="${rest#*$'\t'}"
    spec_file="${rest%%$'\t'*}"
    line="${rest##*$'\t'}"
    if [[ -z "$group" ]]; then
      echo "Error: module '${module_ref}': test ID '${id}' is declared under no group ID: ${spec_file}:${line}" >&2
      result=1
    elif [[ "$id" != "${group}-"* ]]; then
      echo "Error: module '${module_ref}': test ID '${id}' does not belong to its enclosing group ID '${group}': ${spec_file}:${line}" >&2
      result=1
    fi
  done

  # Group uniqueness (§5.4) is checked on its own, before the case IDs: the case
  # layer is a sequence number inside a group, so two groups sharing an ID collide
  # even where every case number under them differs
  local -a group_ids=() duplicates=()
  load_indexed_group_ids ${owned[@]+"${owned[@]}"}
  group_ids=(${_GROUP_IDS[@]+"${_GROUP_IDS[@]}"})
  if ! find_duplicate_ids ${group_ids[@]+"${group_ids[@]}"}; then
    # Copied out before the next call to the detector overwrites it
    duplicates=(${_DUPLICATE_IDS[@]+"${_DUPLICATE_IDS[@]}"})
    for id in "${duplicates[@]}"; do
      echo "Error: module '${module_ref}': group ID '${id}' is declared more than once:" >&2
      locate_group_id "$id" "${owned[@]}" | sed 's/^/  /' >&2
      result=1
    done
  fi

  # Scope consistency (§5.4) is read off the group IDs for the same reason: a case ID
  # carries the scope of the group it belongs to, and membership is checked above, so
  # the group layer is where a foreign scope is actually declared. The distinct list
  # is the one the detector above already built, copied out before the case layer
  # overwrites it, so a group declared twice is reported here only once
  local id_scope
  local -a distinct_groups=()
  distinct_groups=(${_DISTINCT_IDS[@]+"${_DISTINCT_IDS[@]}"})
  for id in ${distinct_groups[@]+"${distinct_groups[@]}"}; do
    id_scope="${id#T-}"
    id_scope="${id_scope%%-*}"
    [[ "$id_scope" == "$scope" ]] && continue
    echo "Error: module '${module_ref}': group ID '${id}' uses scope '${id_scope}' but the module declares '${scope}':" >&2
    locate_group_id "$id" "${owned[@]}" | sed 's/^/  /' >&2
    result=1
  done

  # Sequence uniqueness (§5.4). A module owning no spec at all, or owning specs that
  # assign nothing yet, is a legitimate state rather than a broken pipeline, so unlike
  # check C this warns and passes
  load_indexed_case_ids ${owned[@]+"${owned[@]}"}
  ids=(${_CASE_IDS[@]+"${_CASE_IDS[@]}"})
  if [[ ${#ids[@]} -eq 0 ]]; then
    echo "Warning: module '${module_ref}': scanned ${#owned[@]} spec files, found 0 test IDs (none assigned yet)" >&2
    return "$result"
  fi

  # Membership above pins every case ID to its group, so what is left for this layer
  # is a sequence number colliding inside one group
  if ! find_duplicate_ids "${ids[@]}"; then
    duplicates=(${_DUPLICATE_IDS[@]+"${_DUPLICATE_IDS[@]}"})
    for id in "${duplicates[@]}"; do
      echo "Error: module '${module_ref}': test ID '${id}' is assigned more than once:" >&2
      locate_case_id "$id" "${owned[@]}" | sed 's/^/  /' >&2
      result=1
    done
  fi

  if [[ $result -eq 0 ]]; then
    echo "check B: module '${module_ref}': ${#owned[@]} spec files, ${#group_ids[@]} group IDs, ${#ids[@]} test IDs, 0 duplicates, all scoped '${scope}'"
  fi
  return "$result"
}

#
# @description Check C (§6.4): no group ID is declared twice anywhere in the
#   repository. The final gate: group IDs are the unit of assignment, so with check B
#   holding case membership and sequence uniqueness, repository-wide uniqueness of the
#   case IDs follows from this one and is not collated again.
# @stdout Summary counts when the check passes
# @stderr Duplicated group IDs and the files that declare them
# @exitcode 0 Check passed, or the scan root holds no spec file at all
# @exitcode 1 A duplicate group ID was found, or spec files yielded no group ID
#
check_duplicates() {
  local -a specs=() files=() group_ids=() duplicates=()
  load_spec_files
  specs=(${_SPEC_FILES[@]+"${_SPEC_FILES[@]}"})
  local spec
  for spec in ${specs[@]+"${specs[@]}"}; do
    files+=("${TEST_ID_CHECK_ROOT}/${spec}")
  done

  # Only the group IDs are collated (§6.4): they are the unit of assignment, and the
  # case IDs under them are pinned to their group and to each other by check B, so
  # their repository-wide uniqueness follows from this one and needs no second pass.
  # The index is keyed by absolute path, which is what the list above builds
  load_indexed_group_ids ${files[@]+"${files[@]}"}
  group_ids=(${_GROUP_IDS[@]+"${_GROUP_IDS[@]}"})

  # A repository holding spec files but declaring no group ID at all is an extraction
  # that broke somewhere, not a repository without duplicates: the two counts this
  # check compares are both 0 and would agree (§6.1). Unlike check B, which answers for
  # one module and may legitimately find one that has not been given IDs yet, this is
  # the final gate and has every spec file in front of it
  if [[ ${#group_ids[@]} -eq 0 && ${#files[@]} -gt 0 ]]; then
    echo "Error: repository: scanned ${#files[@]} spec files, extracted 0 group IDs; the extraction is broken" >&2
    return 1
  fi

  if ! find_duplicate_ids ${group_ids[@]+"${group_ids[@]}"}; then
    duplicates=(${_DUPLICATE_IDS[@]+"${_DUPLICATE_IDS[@]}"})
    local id
    for id in "${duplicates[@]}"; do
      echo "Error: repository: group ID '${id}' is declared more than once:" >&2
      locate_group_id "$id" "${files[@]}" | sed 's/^/  /' >&2
    done
    return 1
  fi

  echo "check C: ${#files[@]} spec files, ${#group_ids[@]} group IDs, 0 duplicates"
  return 0
}

#
# @description Derive the target abbreviations (§5.1) the given spec files use.
#   The abbreviation is the second segment of a group ID, taken exactly as spelled:
#   a group is the unit of assignment (§6.5), so each one is counted once however many
#   cases sit under it, and the layer a file lives in is never subtracted from the
#   spelling - `CINI` is one word, not `CIN` plus a layer letter (§5.1).
#   The IDs come from the indexes, so only files load_spec_records enumerated
#   contribute anything (T-RUN-BT-05); check D only ever passes files from
#   list_module_spec_files, which are all under the scan root.
#   Check D used to spend two thirds of the whole run in here, one awk pipeline and
#   one command substitution per spec file, so the body forks exactly once: the
#   `sort -u` that turns the per-group abbreviations into the set the table is
#   compared against.
# @arg $@ string Spec file paths, as keyed in the indexes (absolute)
# @stdout One abbreviation per line, sorted and de-duplicated
# @exitcode 0 always
#
base_targets() {
  load_indexed_group_ids "$@"
  local id target
  for id in ${_GROUP_IDS[@]+"${_GROUP_IDS[@]}"}; do
    target="${id#T-}"
    printf '%s\n' "${target#*-}"
  done | sort -u
}

#
# @description Print each argument on its own line, and nothing at all when given none.
#   `printf '%s\n'` without an argument would emit one empty line instead.
#   Check D used to call it inside the `comm` process substitutions; that caller is gone,
#   and the next one is planned: `load_owners_of` is to print its `_OWNERS` through it,
#   for the same reason (an empty owner list must print nothing, not one blank line).
# @arg $@ string Lines to print
# @stdout One line per argument
# @exitcode 0 always
#
print_lines() {
  [[ $# -gt 0 ]] || return 0
  printf '%s\n' "$@"
}

#
# @description Check D (§6.5): the abbreviation table of one module matches the base
#   targets its tests actually use, with neither a missing nor an unused row.
#   Both differences are taken with associative arrays, not with `comm`. The pipeline
#   form forked 6 subshells per call - the two outer process substitutions plus the four
#   `print_lines` ones nested inside them - so 24 per `--all` across the four module.md
#   files, and a fork costs 0.22-0.33s on the Windows hosts this runs on: some 5 seconds
#   of a run whose actual work here is comparing two short lists of abbreviations.
#   Looking the membership up in memory costs no fork at all.
#   One real difference comes with that: `comm` compared its inputs under `LC_COLLATE`,
#   an associative-array key matches byte for byte. Two spellings that collate equal but
#   differ in bytes used to count as the same abbreviation and now appear as both a
#   missing and an unused one. Abbreviations are `[A-Z0-9]`, so the case does not arise
#   here, and byte equality is the meaning check D wants anyway.
# @arg $1 string Module reference (<ns>/<mod>)
# @stdout Summary counts when the check passes
# @stderr Missing and unused abbreviations
# @exitcode 0 Check passed
# @exitcode 1 Missing declaration, or the table and the tests disagree
#
check_targets() {
  local module_ref="$1"
  # Copied into a local straight away, the convention every scratch variable in this
  # file is read under. Nothing reached from here resolves a path of its own today;
  # the copy is kept so this stays correct if one of them ever does
  module_file_of "$module_ref"
  local module_file="$_MODULE_FILE"
  if [[ ! -f "$module_file" ]]; then
    echo "Error: module '${module_ref}': declaration not found at ${module_file}" >&2
    return 1
  fi

  local -a owned=() used=() declared=()
  mapfile -t owned < <(list_module_spec_files "$module_file")
  mapfile -t used < <(base_targets ${owned[@]+"${owned[@]}"})
  mapfile -t declared < <(read_module_targets "$module_file" | sort -u)

  # Membership is read off the keys and never off the values, so that an abbreviation is
  # matched as a whole string and an empty one is not mistaken for an absent one. Both are
  # `local -A`, which is what keeps one module's abbreviations out of the next call's answer.
  local -A declared_set=() used_set=()
  local target
  for target in ${declared[@]+"${declared[@]}"}; do
    declared_set[$target]=1
  done
  for target in ${used[@]+"${used[@]}"}; do
    used_set[$target]=1
  done

  # Report order is external behaviour, so it stays the order `comm` printed: that of the
  # `sort -u` both inputs came through, which is the locale's collation order rather than
  # a byte order. Neither list is re-sorted here - `base_targets` ends in a `sort -u` and
  # `declared` is piped through one - so walking each in the order it was received keeps
  # that order, and nothing here may iterate the associative arrays instead: theirs is a
  # hash order.
  local result=0
  # used - declared
  for target in ${used[@]+"${used[@]}"}; do
    if [[ -z ${declared_set[$target]+x} ]]; then
      echo "Error: module '${module_ref}': target '${target}' is used by a test but is missing from the abbreviation table in ${module_file}" >&2
      result=1
    fi
  done
  # declared - used, in its own pass: every missing row is reported before the first
  # unused one, which is the grouping the report has always had
  for target in ${declared[@]+"${declared[@]}"}; do
    if [[ -z ${used_set[$target]+x} ]]; then
      echo "Error: module '${module_ref}': target '${target}' is listed in the abbreviation table in ${module_file} but no test uses it" >&2
      result=1
    fi
  done

  if [[ $result -eq 0 ]]; then
    echo "check D: module '${module_ref}': ${#used[@]} target abbreviations, table matches"
  fi
  return "$result"
}

#
# @description Run checks A, B and D (for every module) and C in that order.
#   Every check runs even when an earlier one fails, so one pass reports everything.
# @stdout Summary counts of each passing check
# @stderr Findings of each failing check
# @exitcode 0 All checks passed
# @exitcode 1 At least one check failed
#
check_repository() {
  local result=0
  check_scopes || result=1

  local -a modules=()
  mapfile -t modules < <(list_module_files)
  # The reference is copied out of the scratch variable at the top of the iteration,
  # the convention every scratch variable in this file is read under. No check called
  # below writes _MODULE_REF today, so this is a rule kept in advance rather than a
  # live hazard: it is what keeps the second and later modules correct should a call
  # to module_ref_of ever appear inside one of them
  local module module_ref
  for module in ${modules[@]+"${modules[@]}"}; do
    module_ref_of "$module"
    module_ref="$_MODULE_REF"
    check_module "$module_ref" || result=1
    check_targets "$module_ref" || result=1
  done

  check_duplicates || result=1
  return "$result"
}

#
# @description Print the command usage
# @stdout Usage line
# @exitcode 0 always
#
usage() {
  cat <<'USAGE'
Usage: run-check-test-ids.sh <mode>

Modes:
  --scopes             Check A: test_scope uniqueness and ownership coverage
  --module <ns>/<mod>  Check B: intra-module ID coverage, case membership,
                       duplication and scope consistency
  --targets <ns>/<mod> Check D: abbreviation table matches the targets the tests use
  --all                Checks A, B, D (all modules) and C: repository-wide group ID
                       duplication
USAGE
}

#
# @description Main entry point
# @arg $1 string Mode (--scopes | --module | --targets | --all)
# @arg $2 string Module reference (<ns>/<mod>), required by --module and --targets
# @exitcode 0 All requested checks passed
# @exitcode 1 A check failed or the mode is unknown
#
main() {
  case "${1:-}" in
  --scopes)
    check_scopes
    ;;
  --module)
    if [[ $# -lt 2 || -z "$2" ]]; then
      echo "Error: --module requires a module reference (<ns>/<mod>)" >&2
      return 1
    fi
    check_module "$2"
    ;;
  --targets)
    if [[ $# -lt 2 || -z "$2" ]]; then
      echo "Error: --targets requires a module reference (<ns>/<mod>)" >&2
      return 1
    fi
    check_targets "$2"
    ;;
  --all)
    check_repository
    ;;
  *)
    usage >&2
    return 1
    ;;
  esac
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
