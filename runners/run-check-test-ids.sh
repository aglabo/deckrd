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

# Test case ID grammar (testing guidelines §5.1)
readonly TEST_ID_PATTERN='T-[A-Z0-9]+(-[A-Z0-9]+)*-[0-9]{2}(-[0-9]{2})?'

# ShellSpec case declaration lines; extraction is restricted to these (§6.1)
readonly CASE_DECL_PATTERN='^[[:space:]]*(It|Example)[[:space:]]'

# Heading that introduces the target abbreviation table in module.md (§5.2)
readonly TARGET_TABLE_HEADING='テスト対象の略語'

#
# @description Extract every test case ID assigned in a case declaration (§6.1).
#   Occurrences are never de-duplicated per file, so same-file duplicates survive.
# @arg $@ string Spec file paths (absolute or relative to the current directory)
# @stdout One ID per occurrence, sorted; empty when no ID is assigned
# @exitcode 0 always
#
extract_case_ids() {
  [[ $# -gt 0 ]] || return 0
  grep -hE "$CASE_DECL_PATTERN" "$@" |
    tr -c 'A-Za-z0-9-' '\n' |
    grep -xE "$TEST_ID_PATTERN" |
    sort || true
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
  [[ -f "$file" ]] || return 0
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
}

#
# @description Read the `owns` glob list from a module.md YAML frontmatter block
# @arg $1 string Path to module.md
# @stdout One glob per line, in declaration order; empty when undeclared
# @exitcode 0 always
#
read_module_owns() {
  local file="$1"
  [[ -f "$file" ]] || return 0
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
}

#
# @description Read the base target abbreviations declared in a module.md (§5.2).
#   Only the table under the abbreviation heading is read; it ends at the next heading.
# @arg $1 string Path to module.md
# @stdout One abbreviation per line, in declaration order; empty when the table is absent
# @exitcode 0 always
#
read_module_targets() {
  local file="$1"
  [[ -f "$file" ]] || return 0
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
  local path="$1" regex
  regex="$(glob_to_regex "$2")"
  [[ "$path" =~ $regex ]]
}

#
# @description List module declaration files under the scan root
# @stdout One module.md path per line, sorted; empty when the docs root is absent
# @exitcode 0 always
#
list_module_files() {
  local docs_root="${TEST_ID_CHECK_ROOT}/${MODULE_DOCS_SUBDIR}"
  [[ -d "$docs_root" ]] || return 0
  find "$docs_root" -type f -name 'module.md' | sort
}

#
# @description Derive the `<ns>/<mod>` reference of a module declaration file
# @arg $1 string Path to module.md as produced by list_module_files
# @stdout Module reference
# @exitcode 0 always
#
module_ref_of() {
  local ref="${1#"${TEST_ID_CHECK_ROOT}/${MODULE_DOCS_SUBDIR}/"}"
  printf '%s\n' "${ref%/module.md}"
}

#
# @description Resolve a module reference to its declaration file path.
#   The inverse of module_ref_of; the file is not required to exist.
# @arg $1 string Module reference (<ns>/<mod>)
# @stdout Path to module.md
# @exitcode 0 always
#
module_file_of() {
  printf '%s
' "${TEST_ID_CHECK_ROOT}/${MODULE_DOCS_SUBDIR}/${1}/module.md"
}

#
# @description List every spec file under the scan root
# @stdout One repository-relative path per line, sorted; empty when none exist
# @exitcode 0 always
#
list_spec_files() {
  get_filelist "$TEST_ID_CHECK_ROOT" '*.spec.sh' | sed 's|^\./||' | sort
}

#
# @description List the module declarations that own a given spec file
# @arg $1 string Repository-relative spec file path
# @arg $@ string Module declaration file paths to test against
# @stdout One owning module.md path per line
# @exitcode 0 always
#
owners_of() {
  local path="$1"
  shift
  local module glob
  for module in "$@"; do
    while IFS= read -r glob; do
      [[ -n "$glob" ]] || continue
      if path_matches_glob "$path" "$glob"; then
        printf '%s\n' "$module"
        break
      fi
    done < <(read_module_owns "$module")
  done
}

#
# @description Check A (§6.2): every `test_scope` is unique and every spec file is
#   owned by exactly one module. Reads declarations and file names only.
# @stdout Summary counts when the check passes
# @stderr Offending scopes and files
# @exitcode 0 Check passed
# @exitcode 1 Duplicate scope, unowned file, or multiply-owned file found
#
check_scopes() {
  local -a modules=()
  mapfile -t modules < <(list_module_files)
  if [[ ${#modules[@]} -eq 0 ]]; then
    echo "Error: no module.md found under ${TEST_ID_CHECK_ROOT}/${MODULE_DOCS_SUBDIR}" >&2
    return 1
  fi

  local result=0 module scope
  local -a declarations=()
  for module in "${modules[@]}"; do
    scope="$(read_module_scalar "$module" 'test_scope')"
    if [[ -z "$scope" ]]; then
      echo "Error: ${module}: frontmatter declares no 'test_scope'" >&2
      result=1
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
  mapfile -t specs < <(list_spec_files)
  local spec
  local -a owners=()
  for spec in ${specs[@]+"${specs[@]}"}; do
    mapfile -t owners < <(owners_of "$spec" "${modules[@]}")
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
  local -a specs=()
  mapfile -t specs < <(list_spec_files)
  local spec glob
  for spec in ${specs[@]+"${specs[@]}"}; do
    while IFS= read -r glob; do
      [[ -n "$glob" ]] || continue
      if path_matches_glob "$spec" "$glob"; then
        printf '%s\n' "${TEST_ID_CHECK_ROOT}/${spec}"
        break
      fi
    done < <(read_module_owns "$module_file")
  done
}

#
# @description List the spec files that assign a given test case ID
# @arg $1 string Test case ID
# @arg $@ string Spec file paths to search
# @stdout One matching file path per line
# @exitcode 0 always
#
locate_case_id() {
  local id="$1"
  shift
  [[ $# -gt 0 ]] || return 0
  local pattern="${CASE_DECL_PATTERN}.*${id}"'([^A-Za-z0-9-]|$)'
  grep -lE "$pattern" "$@" || true
}

#
# @description Check B (§6.3): within one module, no test ID is assigned twice and
#   every ID carries that module's declared `test_scope`.
# @arg $1 string Module reference (<ns>/<mod>)
# @stdout Summary counts when the check passes
# @stderr Offending IDs and the files that assign them
# @exitcode 0 Check passed, or no ID is assigned yet
# @exitcode 1 Missing declaration, duplicate ID, or foreign scope found
#
check_module() {
  local module_ref="$1"
  local module_file
  module_file="$(module_file_of "$module_ref")"
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

  local -a owned=() ids=()
  mapfile -t owned < <(list_module_spec_files "$module_file")
  mapfile -t ids < <(extract_case_ids ${owned[@]+"${owned[@]}"})

  if [[ ${#ids[@]} -eq 0 ]]; then
    echo "Warning: module '${module_ref}': scanned ${#owned[@]} spec files, found 0 test IDs (none assigned yet)" >&2
    return 0
  fi

  local result=0 id
  local -a duplicates=() unique_ids=()
  mapfile -t duplicates < <(printf '%s\n' "${ids[@]}" | uniq -d)
  for id in ${duplicates[@]+"${duplicates[@]}"}; do
    echo "Error: module '${module_ref}': test ID '${id}' is assigned more than once:" >&2
    locate_case_id "$id" "${owned[@]}" | sed 's/^/  /' >&2
    result=1
  done

  local id_scope
  mapfile -t unique_ids < <(printf '%s\n' "${ids[@]}" | uniq)
  for id in "${unique_ids[@]}"; do
    id_scope="${id#T-}"
    id_scope="${id_scope%%-*}"
    [[ "$id_scope" == "$scope" ]] && continue
    echo "Error: module '${module_ref}': test ID '${id}' uses scope '${id_scope}' but the module declares '${scope}':" >&2
    locate_case_id "$id" "${owned[@]}" | sed 's/^/  /' >&2
    result=1
  done

  if [[ $result -eq 0 ]]; then
    echo "check B: module '${module_ref}': ${#owned[@]} spec files, ${#ids[@]} test IDs, 0 duplicates, all scoped '${scope}'"
  fi
  return "$result"
}

#
# @description Check C (§6.4): no test ID is assigned twice anywhere in the repository
# @stdout Summary counts when the check passes
# @stderr Duplicated IDs and the files that assign them
# @exitcode 0 Check passed, or no ID is assigned yet
# @exitcode 1 A duplicate ID was found
#
check_duplicates() {
  local -a specs=() files=() ids=() duplicates=()
  mapfile -t specs < <(list_spec_files)
  local spec
  for spec in ${specs[@]+"${specs[@]}"}; do
    files+=("${TEST_ID_CHECK_ROOT}/${spec}")
  done

  mapfile -t ids < <(extract_case_ids ${files[@]+"${files[@]}"})
  if [[ ${#ids[@]} -eq 0 ]]; then
    echo "Warning: repository: scanned ${#files[@]} spec files, found 0 test IDs (none assigned yet)" >&2
    return 0
  fi

  mapfile -t duplicates < <(printf '%s\n' "${ids[@]}" | uniq -d)
  if [[ ${#duplicates[@]} -eq 0 ]]; then
    echo "check C: ${#files[@]} spec files, ${#ids[@]} test IDs, 0 duplicates"
    return 0
  fi

  local id
  for id in "${duplicates[@]}"; do
    echo "Error: repository: test ID '${id}' is assigned more than once:" >&2
    locate_case_id "$id" "${files[@]}" | sed 's/^/  /' >&2
  done
  return 1
}

#
# @description Derive the layer suffix (§5.1) of a spec file from the directory it
#   sits in. The suffix is never guessed from the spelling of a target token (§6.5).
# @arg $1 string Spec file path
# @stdout The layer suffix; empty for unit and for unrecognized layouts
# @exitcode 0 always
#
layer_suffix() {
  case "$1" in
  *"/__tests__/integration/"*) printf 'I\n' ;;
  *"/__tests__/functional/"*) printf 'F\n' ;;
  *"/__tests__/system/"*) printf 'S\n' ;;
  *"/__tests__/e2e/"*) printf 'E\n' ;;
  esac
}

#
# @description Derive the base target abbreviations (§5.1) assigned in spec files.
#   Each file contributes the second ID segment of its cases, less the layer suffix
#   its own directory implies; the same target seen in several layers collapses to one.
# @arg $@ string Spec file paths
# @stdout One base abbreviation per line, sorted and de-duplicated
# @exitcode 0 always
#
base_targets() {
  local file suffix id target
  for file in "$@"; do
    suffix="$(layer_suffix "$file")"
    while IFS= read -r id; do
      [[ -n "$id" ]] || continue
      target="${id#T-}"
      target="${target#*-}"
      target="${target%%-*}"
      [[ -z "$suffix" ]] || target="${target%?}"
      printf '%s\n' "$target"
    done < <(extract_case_ids "$file")
  done | sort -u
}

#
# @description Print each argument on its own line, and nothing at all when given none.
#   `printf '%s\n'` without an argument would emit one empty line instead.
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
# @arg $1 string Module reference (<ns>/<mod>)
# @stdout Summary counts when the check passes
# @stderr Missing and unused abbreviations
# @exitcode 0 Check passed
# @exitcode 1 Missing declaration, or the table and the tests disagree
#
check_targets() {
  local module_ref="$1"
  local module_file
  module_file="$(module_file_of "$module_ref")"
  if [[ ! -f "$module_file" ]]; then
    echo "Error: module '${module_ref}': declaration not found at ${module_file}" >&2
    return 1
  fi

  local -a owned=() used=() declared=() missing=() unused=()
  mapfile -t owned < <(list_module_spec_files "$module_file")
  mapfile -t used < <(base_targets ${owned[@]+"${owned[@]}"})
  mapfile -t declared < <(read_module_targets "$module_file" | sort -u)
  mapfile -t missing < <(
    comm -23 <(print_lines ${used[@]+"${used[@]}"}) <(print_lines ${declared[@]+"${declared[@]}"})
  )
  mapfile -t unused < <(
    comm -13 <(print_lines ${used[@]+"${used[@]}"}) <(print_lines ${declared[@]+"${declared[@]}"})
  )

  local result=0 target
  for target in ${missing[@]+"${missing[@]}"}; do
    echo "Error: module '${module_ref}': target '${target}' is used by a test but is missing from the abbreviation table in ${module_file}" >&2
    result=1
  done
  for target in ${unused[@]+"${unused[@]}"}; do
    echo "Error: module '${module_ref}': target '${target}' is listed in the abbreviation table in ${module_file} but no test uses it" >&2
    result=1
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
  local module
  local module_ref
  for module in ${modules[@]+"${modules[@]}"}; do
    module_ref="$(module_ref_of "$module")"
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
  --module <ns>/<mod>  Check B: intra-module ID duplication and scope consistency
  --targets <ns>/<mod> Check D: abbreviation table matches the targets the tests use
  --all                Checks A, B, D (all modules) and C: repository-wide duplication
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
