#!/usr/bin/env bash
# skills/deckrd/skills/deckrd/scripts/libs/session.lib.sh - Session data management
#
# Copyright (c) 2026- atsushifx <https://github.com/atsushifx>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT
#
# @version 0.1.0
# USAGE: source this file, do NOT execute directly.
#   . "$(dirname "${BASH_SOURCE[0]}")/libs/session.lib.sh"

if [[ -n ${_SESSION_LOADED:-}   ]]; then
  return 0
fi
readonly _SESSION_LOADED=1

# shellcheck disable=SC1091
. "${DECKRD_LIB_DIR}/kv-store.lib.sh"

# Load utils for jq_read / write_json_file (the lang -> prog migration functions read
# and rewrite session.json directly)
# shellcheck source=skills/deckrd/skills/deckrd/scripts/libs/utils.lib.sh
# shellcheck disable=SC1091
. "${DECKRD_LIB_DIR}/utils.lib.sh"

# SESSION_SCHEMA - compatibility shim: exposes _KV_SCHEMA as SESSION_SCHEMA
# This allows existing code that checks SESSION_SCHEMA[$buffer] to work.
# shellcheck disable=SC2034
declare -n SESSION_SCHEMA="_KV_SCHEMA"

# session_init - Register schema for a buffer and initialize with defaults
#
# @arg $1 string Buffer name (store name)
# @arg $2 string Schema string
session_init()
               {
  local buffer="$1"
  local schema="$2"
  kv_init "$buffer" "$schema"
}

# session_load - Load session from JSON file into buffer
#
# @arg $1 string JSON file path
# @arg $2 string Buffer name (store name)
# @return 0 on success (including file-not-found with default init), 1 on schema error, invalid JSON, or unknown key
session_load()
               {
  local file="$1"
  local buffer="$2"

  if [[ -z ${_KV_SCHEMA[$buffer]+set}   ]]; then
    echo "Error: session_load: schema not registered for buffer '${buffer}'" >&2
    return 1
  fi

  kv_load "$buffer" "$file"
}

# session_save - Save buffer contents to JSON file
#
# @arg $1 string JSON file path
# @arg $2 string Buffer name (store name)
# @return 0 on success
session_save()
               {
  local file="$1"
  local buffer="$2"
  kv_save "$buffer" "$file"
}

# session_get - Get value from buffer
#
# @arg $1 string Buffer name (store name)
# @arg $2 string Key name
# @stdout Value (empty string if key not found)
session_get()
              {
  local buffer="$1"
  local key="$2"
  kv_get "$buffer" "$key"
}

# session_set - Set value in buffer
#
# @arg $1 string Buffer name (store name)
# @arg $2 string Key name
# @arg $3 string Value
session_set()
              {
  local buffer="$1"
  local key="$2"
  local value="${3:-}"
  kv_set "$buffer" "$key" "$value"
}

# session_lang_migration_needed - Tell whether session.json needs the lang -> prog migration
#
# Migration is needed when the file is a JSON object with no `prog` key and its
# `lang` is exactly one of typescript / go / python / rust / shell / bash.
# Read-only: the file is never modified and nothing is printed on stdout.
#
# @arg $1 string session.json file path
# @stderr One `Error:` line when the return value is 2
# @return 0 if migration is needed, 1 if the file is a JSON object that needs no
#         migration, 2 if the file is missing or is not a JSON object (including
#         an empty file)
session_lang_migration_needed()
                                {
  local file="$1"

  if [[ ! -f $file   ]]; then
    echo "Error: session_lang_migration_needed: file not found: ${file}" >&2
    return 2
  fi

  local check='if type != "object" then error("not an object")
    elif (has("prog") | not) and (.lang | IN("typescript", "go", "python", "rust", "shell", "bash")) then "migrate"
    else "skip" end'
  local verdict

  # An empty file makes jq print nothing and succeed, so it falls into `*` too
  verdict="$(jq_read -r "$check" "$file" 2> /dev/null)"
  case "$verdict" in
    migrate) return 0 ;;
    skip) return 1 ;;
    *)
      echo "Error: session_lang_migration_needed: not a JSON object: ${file}" >&2
      return 2
      ;;
  esac
}

# session_migrate_lang_to_prog - Move a programming language from `lang` to `prog`
#
# Older session.json files stored the programming language in `lang`. When
# session_lang_migration_needed says migration is needed (`lang` is exactly one of
# typescript / go / python / rust / shell / bash and there is no `prog` key), the
# value is moved to `prog` and `lang` is deleted; all other keys are kept. The new
# content is written through write_json_file (libs/utils.lib.sh): a temporary file
# in the same directory is moved over the original, and the temporary file is
# removed on failure.
# Otherwise (`prog` already present, `lang` absent, or any other `lang` value such
# as a document language code) the file is left untouched.
#
# @arg $1 string session.json file path
# @stderr One notice line when the file is migrated; an `Error:` line on failure
# @return 0 on migration or no-op, 1 if the file is missing, is not a JSON object
#         (including an empty file), or cannot be written
session_migrate_lang_to_prog()
                               {
  local file="$1"
  local rc=0

  # The predicate prints the `Error:` line itself when it returns 2
  session_lang_migration_needed "$file" || rc=$?
  case "$rc" in
    0) ;;
    1) return 0 ;;
    *) return 1 ;;
  esac

  if ! write_json_file "$file" '(. + {prog: .lang}) | del(.lang)' "$file"; then
    echo "Error: session_migrate_lang_to_prog: failed to write: ${file}" >&2
    return 1
  fi
  echo "session: migrated programming language from 'lang' to 'prog' in ${file}" >&2
}
