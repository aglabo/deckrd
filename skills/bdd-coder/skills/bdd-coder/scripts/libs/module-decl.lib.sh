#!/usr/bin/env bash
# skills/deckrd/skills/deckrd/scripts/libs/module-decl.lib.sh - Module declaration paths and references
#
# Copyright (c) 2026- atsushifx <https://github.com/atsushifx>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT
#
# @version 0.1.0
# USAGE: source this file, do NOT execute directly.
#   . "$(dirname "${BASH_SOURCE[0]}")/module-decl.lib.sh"
#
# MODULE_FILE_SUFFIX is where a module declaration sits inside its `<ns>/<mod>`
# directory. It is the one spelling shared by module_decl_list, module_decl_ref_of and
# module_decl_file_of, which must agree on it for a reference derived from a listed file
# to resolve back to that same file. A `module.md` anywhere else, the legacy
# `<ns>/<mod>/module.md` included, is not a declaration.
#
# module_decl_ref_of and module_decl_file_of answer in global scalars rather than on
# stdout, so that no caller pays for a subshell: copy the answer into a local before
# calling anything that could fill the same variable again.

if [[ -n ${_LIB_MODULE_DECL_LOADED:-}   ]]; then
  return 0
fi
readonly _LIB_MODULE_DECL_LOADED=1

# Declaration path inside `<ns>/<mod>`
readonly MODULE_FILE_SUFFIX='workspaces/module/module.md'

# Output variables
_MODULE_REF=''
_MODULE_FILE=''

# module_decl_list - List the module declaration files under a docs root
#
# @arg $1 string Directory holding the module declarations (docs root)
# @stdout One declaration path (`<ns>/<mod>/` + MODULE_FILE_SUFFIX) per line, sorted;
#   empty when the docs root is absent
# @return 0 on success or when the docs root is absent
module_decl_list() {
  [[ -d $1   ]] || return 0
  find "$1" -type f -path "*/${MODULE_FILE_SUFFIX}" | sort
}

# module_decl_ref_of - Derive the `<ns>/<mod>` reference of a module declaration file
#
# Assigns instead of printing, for the fork cost spelled out on module_decl_file_of;
# the two are each other's inverse and stay symmetrical.
# The docs root comes off the front and MODULE_FILE_SUFFIX off the back, in that order:
# a namespace may carry slashes of its own, so only the two ends are known. No trailing
# newline is appended, for the reason given on module_decl_file_of.
#
# @arg $1 string Docs root
# @arg $2 string Path to module.md as produced by module_decl_list
# @set _MODULE_REF string The reference, replaced on every call
# @return 0 always
module_decl_ref_of() {
  local ref="${2#"$1/"}"
  _MODULE_REF="${ref%/"${MODULE_FILE_SUFFIX}"}"
  return 0
}

# module_decl_file_of - Resolve a module reference to its declaration file path
#
# The inverse of module_decl_ref_of; the file is not required to exist. Assigns instead
# of printing because the accessors only expand parameters, and wrapping them in `$( )`
# costs a subshell per module: 0.22-0.33s each on the Windows hosts the callers run on.
# No trailing newline is appended: a path carrying one would split a report quoting it
# over two lines. The variable is assigned unconditionally, so a reference resolved
# earlier is never reported in place of this one.
#
# @arg $1 string Docs root
# @arg $2 string Module reference (<ns>/<mod>)
# @set _MODULE_FILE string The declaration path, replaced on every call
# @return 0 always
module_decl_file_of() {
  _MODULE_FILE="$1/$2/${MODULE_FILE_SUFFIX}"
  return 0
}
