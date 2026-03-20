#!/usr/bin/env bash
# plugins/deckrd/skills/deckrd/scripts/libs/normalize-doc-type.sh - doc-type normalization
#
# Copyright (c) 2026- atsushifx <https://github.com/atsushifx>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT
#
# @version 0.1.0
# USAGE: source this file, do NOT execute directly.
#   . "$(dirname "${BASH_SOURCE[0]}")/libs/normalize-doc-type.sh"

# Guard: prevent re-sourcing
if [[ -n "${_NORMALIZE_DOC_TYPE_LOADED:-}" ]]; then
  return 0
fi
readonly _NORMALIZE_DOC_TYPE_LOADED=1

# Short form aliases
# shellcheck disable=SC2034
readonly -a SHORT_TYPES=(
  "req"
  "spec"
  "impl"
  "task"
  "explore"
  "harden"
  "fix"
)

# Canonical long forms
# shellcheck disable=SC2034
readonly -a LONG_TYPES=(
  "implementation"
  "requirements"
  "review-explore"
  "review-fix"
  "review-harden"
  "specifications"
  "tasks"
)

# normalize_doc_type - Normalize short doc-type aliases to canonical long form
#
# @arg $1 string Doc-type (short or long form)
# @stdout Canonical doc-type string
# @return 0 on success, 1 on unknown doc-type
normalize_doc_type() {
  local doc_type="${1:-}"

  if [[ -z "${doc_type}" ]]; then
    echo "Error: doc-type is required"
    return 1
  fi

  if [[ ! "${doc_type}" =~ ^[a-z]([a-z-]*[a-z])?$ ]]; then
    echo "Error: doc-type must match [a-z][a-z-]* ${doc_type}"
    return 1
  fi

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
    echo "Unknown doc-type: ${doc_type}"
    return 1
    ;;
  esac
}
