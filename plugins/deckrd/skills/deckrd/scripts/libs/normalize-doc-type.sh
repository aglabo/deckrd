#!/usr/bin/env bash
# plugins/deckrd/skills/deckrd/scripts/libs/normalize-doc-type.sh - doc-type normalization
#
# Copyright (c) 2026- atsushifx <https://github.com/atsushifx>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT
#
# USAGE: source this file, do NOT execute directly.
#   . "$(dirname "${BASH_SOURCE[0]}")/libs/normalize-doc-type.sh"

# Guard: prevent re-sourcing
if [[ -n "${_NORMALIZE_DOC_TYPE_LOADED:-}" ]]; then
  return 0
fi
readonly _NORMALIZE_DOC_TYPE_LOADED=1

# normalize_doc_type - Normalize short doc-type aliases to canonical long form
#
# @arg $1 string Doc-type (short or long form)
# @stdout Canonical doc-type string
# @return 0 on success, 1 on unknown doc-type
normalize_doc_type() {
  local doc_type="${1:-}"

  case "${doc_type}" in
  req)
    echo "requirements"
    ;;
  spec)
    echo "specifications"
    ;;
  impl)
    echo "implementation"
    ;;
  task)
    echo "tasks"
    ;;
  requirements | specifications | implementation | tasks | review)
    echo "${doc_type}"
    ;;
  explore)
    echo "review-explore"
    ;;
  harden)
    echo "review-harden"
    ;;
  fix)
    echo "review-fix"
    ;;
  review-*)
    echo "${doc_type}"
    ;;
  *)
    echo "Unknown doc-type: ${doc_type}" >&2
    return 1
    ;;
  esac
}
