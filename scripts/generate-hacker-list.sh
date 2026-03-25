#!/usr/bin/env bash
# src: ./scripts/generate-hacker-list.sh
# @(#) : Extract .short names from hackers.meta.yaml
#
# Copyright (c) 2026- aglabo <https://github.com/aglabo>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT
#
# shellcheck shell=bash

set -euo pipefail

DEFAULT_INPUT="plugins/_data/hackers.meta.yaml"

usage() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS] [INPUT_FILE]

Extract .short names from a hackers metadata YAML file.

OPTIONS:
  -i          Read YAML from stdin
  -o FILE     Write output to FILE (default: stdout)
  -h          Show this help

ARGS:
  INPUT_FILE  Input YAML file (ignored if -i is set; default: ${DEFAULT_INPUT})

EXAMPLES:
  $(basename "$0") plugins/_data/hackers.meta.yaml
  cat hackers.meta.yaml | $(basename "$0") -i
  $(basename "$0") -o hacker-list.txt plugins/_data/hackers.meta.yaml
EOF
}

use_stdin=false
output_file=""

while getopts "io:h" opt; do
  case "$opt" in
    i) use_stdin=true ;;
    o) output_file="$OPTARG" ;;
    h) usage; exit 0 ;;
    *) usage >&2; exit 1 ;;
  esac
done
shift $((OPTIND - 1))

if ! command -v yq >/dev/null 2>&1; then
  echo "Error: yq is required" >&2
  exit 1
fi

if "$use_stdin"; then
  input_source="/dev/stdin"
elif [[ $# -gt 0 ]]; then
  input_source="$1"
else
  input_source="$DEFAULT_INPUT"
fi

result=$(yq -r '.[] | .short' "$input_source" | awk 'NF' | sort -u)

generated_at=$(date '+%Y-%m-%d %H:%M:%S %Z')

header="# @(#) Hacker Name List -- generated: ${generated_at} from ${input_source}"

if [[ -n "$output_file" ]]; then
  { printf '%s\n' "$header"; printf '%s\n' "$result"; } >"$output_file"
  echo "Generated: $output_file" >&2
else
  printf '%s\n' "$header"
  printf '%s\n' "$result"
fi
