#!/bin/env bash
# deckrd init-docs.sh - Initialize documentation directory structure and session
# Usage: init-docs.sh <namespace>/<module>

set -euo pipefail

REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
DECKRD_BASE="${REPO_ROOT}/docs/.deckrd"
SESSION_FILE="${DECKRD_BASE}/.session.json"

show_usage() {
  cat <<EOF
Usage: init-docs.sh [OPTIONS] <namespace>/<module>

Initialize DECKRD documentation directory structure and session.

Arguments:
  <namespace>/<module>  Path in format "Namespace/ModuleName"
                        Example: AGTKind/isCollection

Options:
  --lang <lang>         Document language (default: system)
                        Values: system, en, ja
  -h, --help            Show this help message

Created directories:
  docs/.deckrd/<namespace>/<module>/
    ├── requirements/
    ├── specifications/
    ├── implementation/
    └── tasks/

Session file:
  docs/.deckrd/.session.json
EOF
}

init_directories() {
  local path="$1"
  local namespace module

  # Parse namespace/module from path
  if [[ "$path" != */* ]]; then
    echo "Error: Path must be in format <namespace>/<module>" >&2
    echo "   Example: AGTKind/isCollection" >&2
    exit 1
  fi

  namespace="${path%%/*}"
  module="${path#*/}"

  local base_path="${DECKRD_BASE}/${namespace}/${module}"

  echo "Initializing DECKRD structure: ${namespace}/${module}"

  # Create base directory
  mkdir -p "$DECKRD_BASE"

  for subdir in requirements specifications implementation tasks; do
    local full_path="${base_path}/${subdir}"
    mkdir -p "$full_path"
    echo "  Created: ${subdir}/"
  done

  echo ""
  echo "Base path: ${base_path}"
}

init_session() {
  local path="$1"
  local lang="$2"
  local namespace module
  namespace="${path%%/*}"
  module="${path#*/}"
  local timestamp
  timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

  if [[ -f "$SESSION_FILE" ]]; then
    # Update existing session
    # Use node/jq if available, otherwise create simple JSON
    if command -v node &> /dev/null; then
      node -e "
        const fs = require('fs');
        const session = JSON.parse(fs.readFileSync('${SESSION_FILE}', 'utf8'));
        session.active = '${path}';
        session.lang = '${lang}';
        session.updated_at = '${timestamp}';
        session.modules = session.modules || {};
        session.modules['${path}'] = {
          current_step: 'init',
          completed: ['init'],
          documents: {},
        };
        fs.writeFileSync('${SESSION_FILE}', JSON.stringify(session, null, 2));
      "
    else
      # Fallback: overwrite with new session
      create_new_session "$path" "$timestamp" "$lang"
    fi
  else
    create_new_session "$path" "$timestamp" "$lang"
  fi

  echo "Session updated: ${SESSION_FILE}"
  echo "  Active module: ${path}"
  echo "  Language: ${lang}"
}

create_new_session() {
  local path="$1"
  local timestamp="$2"
  local lang="$3"
  local namespace module
  namespace="${path%%/*}"
  module="${path#*/}"

  cat > "$SESSION_FILE" <<EOF
{
  "active": "${path}",
  "lang": "${lang}",
  "created_at": "${timestamp}",
  "updated_at": "${timestamp}",
  "modules": {
    "${path}": {
      "current_step": "init",
      "completed": ["init"],
      "documents": {}
    }
  }
}
EOF
}

# Main
LANG_OPT="system"
MODULE_PATH=""

# Parse arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
      show_usage
      exit 0
      ;;
    --lang)
      if [[ -n "${2:-}" ]]; then
        LANG_OPT="$2"
        shift 2
      else
        echo "Error: --lang requires a value" >&2
        exit 1
      fi
      ;;
    --lang=*)
      LANG_OPT="${1#*=}"
      shift
      ;;
    -*)
      echo "Error: Unknown option: $1" >&2
      show_usage
      exit 1
      ;;
    *)
      MODULE_PATH="$1"
      shift
      ;;
  esac
 done

if [[ -z "$MODULE_PATH" ]]; then
  show_usage
  exit 0
fi

init_directories "$MODULE_PATH"
init_session "$MODULE_PATH" "$LANG_OPT"
