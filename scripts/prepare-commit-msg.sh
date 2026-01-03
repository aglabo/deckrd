#!/usr/bin/env bash
# src: ./scripts/prepare-commit-msg.sh
# @(#) : Prepare commit message using Codex CLI
#
# Copyright (c) 2025 atsushifx <http://github.com/atsushifx>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT
#
# @file prepare-commit-msg.sh
# @brief Prepare commit message using AI (Codex, Claude, or similar)
# @description
#   Automatically generates Conventional Commits format messages by analyzing
#   staged changes and recent commit history using AI.
#
#   **Design Contract (CRITICAL):**
#   1. Template (commit-message-generator.md) MUST output:
#      - === commit header === marker at start
#      - === commit footer === marker at end
#      - Message content between markers (no context data)
#   2. Git context (diff/log) is INPUT ONLY to the AI:
#      - NOT included in final message
#      - Filtered out before extracting message
#   3. Git Hook Compatibility:
#      - Conforms to prepare-commit-msg hook interface
#      - Can be symlinked to .git/hooks/prepare-commit-msg
#      - Non-zero exit skips hook (safe failure mode)
#
#   Features:
#   - Conventional Commits format compliance
#   - Context-aware message generation
#   - Dual output modes: stdout or Git buffer
#   - Skips if existing message detected (hook mode)
#   - Safe failure: markers not found → error exit
#
# @example
#   # Output to stdout (interactive)
#   prepare-commit-msg.sh
#
#   # Output to Git commit buffer (hook mode)
#   prepare-commit-msg.sh --git-buffer
#
#   # Use specific AI model
#   prepare-commit-msg.sh --git-buffer --model claude-sonnet-4-5
#
# @exitcode 0 Success or skipped (existing message found)
# @exitcode 1 Error during generation (AI output invalid, markers missing, etc.)
#
# @author atsushifx
# @version 2.0.0
# @license MIT

set -euo pipefail

# ============================================================================
# Path Initialization
# ============================================================================

##
# @description Repository root path
REPO_ROOT="$(git rev-parse --show-toplevel)"
readonly REPO_ROOT

##
# @description Script directory path
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR

# ============================================================================
# Script Configuration
# ============================================================================

##
# @description Git commit message file path (default: .git/COMMIT_EDITMSG)
GIT_COMMIT_MSG=".git/COMMIT_EDITMSG"

##
# @description Flag to output to stdout (true) or Git buffer (false, default: true)
FLAG_OUTPUT_TO_STDOUT=true

##
# @description AI model name for commit message generation (default: sonnet)
DEFAULT_AI_MODEL="gpt-5.2"

###
# @description AI model name for commit message generation (default: sonnet)
AI_MODEL="gpt-5.2"

##
# @description Path to commit message generator template
readonly AGENT_TEMPLATE_PATH=".claude/agents/commit-message-generator.md"

##
# @description Maximum number of recent commits to show in context
readonly MAX_LOG_ENTRIES=10

##
# @description Global array to store AI model command and arguments
# Populated by get_model_command() for safe command execution (no eval needed)
declare -a AI_COMMAND=()

# ============================================================================
# Functions
# ============================================================================

##
# @description Display usage information and help message
# @stdout Help message in standard format
# @return Always exits with 0
# @example
#   display_help
display_help() {
  local script_name
  script_name=$(basename "$0")
  cat <<EOF
Usage: $script_name [OPTIONS] [commit_msg_file]

Generate Conventional Commits format messages by analyzing staged changes
and recent commit history using AI.

Options:
  --git-buffer, --to-buffer   Output to Git commit buffer (default: stdout)
  --model MODEL               AI model name (default: sonnet)
                              Supported: gpt-*, o1-*, claude-*, haiku, sonnet, opus
  -h, --help                  Show this help message

Arguments:
  [commit_msg_file]           Git commit message file (default: .git/COMMIT_EDITMSG)

Examples:
  # Output to stdout
  $script_name

  # Output to Git buffer with specific model
  $script_name --git-buffer --model claude-sonnet-4-5

  # Custom commit message file
  $script_name /path/to/COMMIT_EDITMSG
EOF
}

##
# @description Parse command-line options and set configuration
# @arg $@ string Command-line arguments to parse
# @option --git-buffer|--to-buffer Output to Git commit buffer (.git/COMMIT_EDITMSG)
# @option --model MODEL Specify AI model name (default: sonnet)
# @option -h|--help Display usage information
# @example
#   parse_options "$@"
#   parse_options --model claude-sonnet-4-5 --to-buffer
# @exitcode 0 If parsing succeeds
# @exitcode 1 If unknown option provided or required argument missing
# @global FLAG_OUTPUT_TO_STDOUT
# @global GIT_COMMIT_MSG
# @global AI_MODEL
parse_options() {
  while [[ $# -gt 0 ]]; do
    case $1 in
      --git-buffer|--to-buffer)
        FLAG_OUTPUT_TO_STDOUT=false
        shift
        ;;
      --model)
        if [[ -z "${2:-}" ]]; then
          echo "Error: --model requires an argument" >&2
          exit 1
        fi
        AI_MODEL="$2"
        shift 2
        ;;
      --help|-h)
        display_help
        exit 0
        ;;
      -*)
        echo "Error: Unknown option: $1" >&2
        exit 1
        ;;
      *)
        # Non-option argument treated as commit message file
        GIT_COMMIT_MSG="$1"
        shift
        ;;
    esac
  done
}



##
# @description Check if an existing commit message is present in file
# Filters out comment lines (starting with #) and empty lines, then checks for content
# @arg $1 string Path to commit message file
# @return 0 If file exists and non-comment, non-empty content found
# @return 1 If file not found, or only comments/empty lines found
# @example
#   if has_existing_message ".git/COMMIT_EDITMSG"; then
#     echo "Message already exists"
#   fi
has_existing_message() {
  local file="$1"

  # Fail safely if file does not exist
  if [[ ! -f "$file" ]]; then
    return 1
  fi

  # Check for non-comment, non-empty lines
  grep -vE '^\s*(#|$)' "$file" | grep -q '.'
}

##
# @description Build context block with recent git logs and staged diff
# Provides AI with repository context to make informed commit messages
# @stdout Formatted context block with clear delimiters
# @return 0 Always succeeds (includes fallback messages if git commands fail)
# @example
#   context=$(make_context_block)
#   echo "$context" | claude -p
make_context_block() {
  echo "===== GIT LOGS ====="
  git log --oneline -10 || echo "No logs available."
  echo ""

  echo "===== GIT DIFF ====="
  git diff --cached || echo "No diff available."
  echo "===== END DIFF ====="
}


##
# @description Set AI command array for specified model
#
# **Design Contract:**
# - Maps model names to provider CLI commands
# - Populates global AI_COMMAND array (not echo output)
# - Array format: (command arg1 arg2 ... )
# - Supports piped stdin: ... | "${AI_COMMAND[@]}"
#
# **Supported Providers:**
# - OpenAI (gpt-*, o1-*) → codex exec --model <model>
# - Anthropic (claude-*, haiku, sonnet, opus) → claude -p --model <model>
# - OpenCode (org/model) → opencode run --model <model>
#
# **Safety Notes:**
# - Uses array expansion, NOT eval (shell injection safe)
# - All model names validated before array creation
# - Unknown models exit with error
#
# @arg $1 string AI model name (default: sonnet)
# @return 0 If model is supported and AI_COMMAND is set
# @return 1 If model is unsupported
# @global AI_COMMAND Array populated with (command arg1 arg2 ...)
# @example
#   get_model_command "claude-sonnet-4-5"
#   echo "data" | "${AI_COMMAND[@]}"
#
#   get_model_command "gpt-5" || { echo "Error"; exit 1; }
get_model_command() {
  local model="${1:-${DEFAULT_AI_MODEL}}"

  case "$model" in
    # OpenAI models
    gpt-* | o1-*)
      AI_COMMAND=("codex" "exec" "--model" "${model}")
      ;;

    # Anthropic (Claude) models
    claude-* | haiku | sonnet | opus)
      AI_COMMAND=("claude" "-p" "--model" "${model}")
      ;;

    # Copilot models (copilot/model format)
    copilot/*)
      local copilot_model="${model#copilot/}"
      AI_COMMAND=("copilot" "--model" "${copilot_model}")
      ;;

    # OpenCode models (provider/model format)
    */*)
      AI_COMMAND=("opencode" "run" "--model" "${model}")
      ;;

    # Unsupported model
    *)
      echo "Error: Unsupported model: ${model}" >&2
      return 1
      ;;
  esac
}


##
# @description Generate commit message using configured AI model
#
# **Execution Contract:**
# 1. Loads commit-message-generator.md template
# 2. Appends git context (logs + diff) as AI input
# 3. Pipes combined input to AI command
# 4. Extracts message between === commit header === markers
# 5. Validates markers exist and message is non-empty
#
# **Input Format to AI:**
#   cat template.md | cat logs | cat diff | <AI_COMMAND>
#
# **Required Template Output:**
#   === commit header ===
#   <commit message here>
#   === commit footer ===
#
# Execution flow:
#   Template + Context → AI → Validate Markers → Extract Message → Return
#
# @arg $1 string Optional test message (for testing/debugging only)
# @return 0 If generation and validation succeeds
# @return 1 If model setup fails, markers missing, or message empty
# @stdout Generated Conventional Commits format message
# @global AI_MODEL Used to determine AI command
# @global AI_COMMAND Populated by get_model_command()
# @example
#   commit_msg=$(generate_commit_message) || exit 1
#   echo "$commit_msg"
#
#   # For testing with mock message
#   generate_commit_message "fix: test message" || exit 1
generate_commit_message() {
  local test_message="${1:-}"

  # Return test message if provided (for testing purposes)
  if [[ -n "$test_message" ]]; then
    echo "${test_message}"
    return 0
  fi

  # Set up AI command for the configured model
  get_model_command "${AI_MODEL}" || return 1

  local full_output
  full_output=$({
    cat .claude/agents/commit-message-generator.md
    echo
    make_context_block
  } | "${AI_COMMAND[@]}"
  )

  # Extract the commit message from AI response
  # Skip context output and extract only the message between markers
  local after_diff
  if echo "$full_output" | grep -q "^===== END DIFF =====$"; then
    after_diff=$(echo "$full_output" | sed -n '/^===== END DIFF =====$/,$p' | sed '1d')
  else
    after_diff="$full_output"
  fi

  # Validate that message markers exist in AI output
  if ! echo "$after_diff" | grep -q '^=== commit header ==='; then
    echo "Error: commit message markers not found in AI output" >&2
    echo "Debug output:" >&2
    echo "$full_output" >&2
    return 1
  fi

  # Extract content between message markers
  local extracted_msg
  extracted_msg=$(echo "$after_diff" | \
    sed -n '/^=== commit header ===/,/^=== commit footer ===/p' | \
    sed '1d;$d')

  # Validate extracted message is not empty
  if [[ -z "$extracted_msg" ]]; then
    echo "Error: extracted commit message is empty" >&2
    return 1
  fi

  echo "$extracted_msg"
}

##
# @description Output commit message to stdout or write to file
# Handles both interactive (stdout) and Git hook (file) output modes
# @arg $1 string Commit message content
# @arg $2 string Optional output file path (default: GIT_COMMIT_MSG)
# @return 0 Always succeeds
# @stdout Commit message (if FLAG_OUTPUT_TO_STDOUT is true)
# @stderr Status message (if outputting to file)
# @global FLAG_OUTPUT_TO_STDOUT Determines output mode
# @global GIT_COMMIT_MSG Default output file path
# @example
#   output_commit_message "$commit_msg"
#   output_commit_message "$commit_msg" ".git/COMMIT_EDITMSG"
output_commit_message() {
  local commit_msg="$1"
  local output_file="${2:-$GIT_COMMIT_MSG}"

  if [[ "$FLAG_OUTPUT_TO_STDOUT" == true ]]; then
    # Output to stdout (interactive mode)
    echo "$commit_msg"
  else
    # Write to file (Git hook mode)
    rm -f "${output_file}"
    echo "${commit_msg}" > "${output_file}"
    echo "[OK] Commit message written to $output_file" >&2
  fi
}

# ============================================================================
# Main Execution
# ============================================================================

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  cd "$REPO_ROOT"

  # Parse command-line options
  parse_options "$@"

  # Check for existing message in Git buffer mode
  # Skip generation if commit message was previously generated
  if [[ "$FLAG_OUTPUT_TO_STDOUT" == false && -f "$GIT_COMMIT_MSG" ]]; then
    if has_existing_message "$GIT_COMMIT_MSG"; then
      echo "[OK] Detected existing Git-generated commit message. Skipping generation." >&2
      exit 0
    fi
  fi

  # Generate commit message
  commit_msg=$(generate_commit_message) || exit 1

  # Output commit message
  output_commit_message "$commit_msg"
fi
