#!/usr/bin/env bash
# src: ./scripts/github-publish.sh
# @(#) : Publish release files to GitHub
#
# Copyright (c) 2025 atsushifx <http://github.com/atsushifx>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT
#
# @file github-publish.sh
# @brief Publish deckrd release files to GitHub
# @description
#   Publishes release files to GitHub using gh CLI.
#   Version can be provided as a parameter or via stdin.
#
#   The script:
#   1. Accepts version from parameter or prompts via stdin
#   2. Normalizes version to vX.Y.Z format
#   3. Verifies release files exist in releases/<version>/
#   4. Creates GitHub release and uploads files
#
# @example
#   # Publish with version parameter
#   github-publish.sh 0.0.4
#
#   # Publish with interactive version input
#   github-publish.sh
#   > Enter version: 0.0.4
#
# @exitcode 0 Success - release published
# @exitcode 1 Error during execution
#
# @author atsushifx
# @version 1.0.0
# @license MIT

# don't use -u for checking error by Agent
set -eo pipefail

# ============================================================================
# Script Configuration
# ============================================================================

##
# @description Script directory path
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR

##
# @description Project root directory
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
readonly PROJECT_ROOT

##
# @description Release base directory
RELEASES_DIR="${PROJECT_ROOT}/releases"
readonly RELEASES_DIR

##
# @description Archive name prefix
ARCHIVE_PREFIX="deckrd"
readonly ARCHIVE_PREFIX

##
# @description Dry-run mode flag
DRY_RUN=false

# ============================================================================
# Functions
# ============================================================================

##
# @description Show usage information
show_usage() {
  cat <<EOF
Usage: github-publish.sh [VERSION]

Publish deckrd release files to GitHub.

Arguments:
  VERSION    Version to release (e.g., 0.0.4, v0.0.4, 0.0)
             If not provided, prompts for input via stdin.

The script will:
  1. Normalize version to vX.Y.Z format
  2. Verify files exist in releases/<version>/
  3. Create GitHub release with tag
  4. Upload zip and sha256 files

Required files in releases/<version>/:
  - deckrd-<version>.zip
  - deckrd-<version>.zip.sha256

Optional files:
  - release-notes.md    Release notes content (markdown, used as GitHub release body)

Options:
  -n, --dry-run    Show what would be done without executing
  -h, --help       Show this help message

Examples:
  github-publish.sh --dry-run 0.0.4
  github-publish.sh -n v0.0.4
  github-publish.sh 0.0.4
  github-publish.sh v0.0.4
  echo "0.0.4" | github-publish.sh
EOF
}

##
# @description Read version from standard input
# @stdout Version string
# @return 0 on success, 1 on error
read_version_from_stdin() {
  local version
  echo "Enter version (e.g., 0.0.4, v0.0.4, 0.0):" >&2
  read -r version || {
    echo "Error: Failed to read version from stdin" >&2
    return 1
  }

  if [ -z "$version" ]; then
    echo "Error: Version cannot be empty" >&2
    return 1
  fi

  echo "$version"
}

##
# @description Normalize version to vX.Y.Z format
# @arg $1 string Raw version string
# @stdout Normalized version (vX.Y.Z)
# @return 0 on success, 1 on invalid format
normalize_version() {
  local version="$1"

  # Remove v/V prefix
  version="${version#v}"
  version="${version#V}"

  # Extract version number (first 3 digit groups)
  # Suffixes like -beta are not allowed
  if [[ ! "$version" =~ ^([0-9]+)(\.[0-9]+)?(\.[0-9]+)?$ ]]; then
    echo "Error: Invalid version format: $version" >&2
    return 1
  fi

  local major="${BASH_REMATCH[1]}"
  local minor="${BASH_REMATCH[2]#.}"
  local patch="${BASH_REMATCH[3]#.}"

  # Set default values
  minor="${minor:-0}"
  patch="${patch:-0}"

  # Return in vX.Y.Z format
  echo "v${major}.${minor}.${patch}"
}

##
# @description Get version from parameter or stdin and normalize it
# @arg $1 string Optional version parameter
# @stdout Normalized version (vX.Y.Z)
# @return 0 on success, 1 on error
get_normalized_version() {
  local raw_version="$1"

  # If no parameter, read from stdin
  if [ -z "$raw_version" ]; then
    raw_version=$(read_version_from_stdin) || return 1
  fi

  normalize_version "$raw_version" || return 1
}

##
# @description Verify release files exist
# @arg $1 string Normalized version (vX.Y.Z)
# @return 0 if files exist, 1 otherwise
verify_release_files() {
  local normalized_version="$1"
  local release_dir="${RELEASES_DIR}/${normalized_version}"
  local archive_file="${ARCHIVE_PREFIX}-${normalized_version}.zip"
  local checksum_file="${archive_file}.sha256"

  echo "Checking release files in: $release_dir"

  # Check release directory exists
  if [ ! -d "$release_dir" ]; then
    echo "Error: Release directory not found: $release_dir" >&2
    return 1
  fi

  # Check archive file exists
  if [ ! -f "${release_dir}/${archive_file}" ]; then
    echo "Error: Archive file not found: ${release_dir}/${archive_file}" >&2
    return 1
  fi

  # Check checksum file exists
  if [ ! -f "${release_dir}/${checksum_file}" ]; then
    echo "Error: Checksum file not found: ${release_dir}/${checksum_file}" >&2
    return 1
  fi

  echo "Found: ${archive_file}"
  echo "Found: ${checksum_file}"

  # Check optional release-notes file (markdown format)
  local release_notes_file="release-notes.md"
  if [ -f "${release_dir}/${release_notes_file}" ]; then
    echo "Found: ${release_notes_file} (will be used as release body)"
  else
    echo "Note: ${release_notes_file} not found (will use default message)"
  fi

  return 0
}

##
# @description Check if gh CLI is available and authenticated
# @return 0 if available, 1 otherwise
check_gh_cli() {
  # Check gh is installed
  if ! command -v gh >/dev/null 2>&1; then
    echo "Error: gh CLI is not installed" >&2
    echo "Install it from: https://cli.github.com/" >&2
    return 1
  fi

  # Check gh is authenticated
  if ! gh auth status >/dev/null 2>&1; then
    echo "Error: gh CLI is not authenticated" >&2
    echo "Run: gh auth login" >&2
    return 1
  fi

  echo "GitHub CLI: authenticated"
  return 0
}

##
# @description Create GitHub release and upload files
# @arg $1 string Normalized version (vX.Y.Z)
# @return 0 on success, 1 on error
publish_to_github() {
  local normalized_version="$1"
  local release_dir="${RELEASES_DIR}/${normalized_version}"
  local archive_file="${ARCHIVE_PREFIX}-${normalized_version}.zip"
  local checksum_file="${archive_file}.sha256"
  local release_notes_file="${release_dir}/release-notes.md"
  local tag_name="${normalized_version}"

  echo ""
  echo "Publishing release ${normalized_version} to GitHub..."
  echo ""

  # Check if release already exists (skip in dry-run mode)
  if [ "$DRY_RUN" != true ]; then
    if gh release view "$tag_name" >/dev/null 2>&1; then
      echo "Warning: Release ${tag_name} already exists on GitHub" >&2
      echo "Use 'gh release delete ${tag_name}' to delete it first if needed" >&2
      return 1
    fi
  fi

  # Get repository URL dynamically for display
  local repo_url
  repo_url="$(gh repo view --json url -q .url 2>/dev/null)" || repo_url="https://github.com/aglabo/deckrd"

  # Determine notes description for dry-run display only
  local notes_desc
  if [ -f "$release_notes_file" ]; then
    notes_desc="--notes-file \"${release_notes_file}\""
    echo "Using release notes from: ${release_notes_file}"
  else
    notes_desc="--notes \"Release ${normalized_version}\""
    echo "Using default release notes"
  fi

  # Build the command for display (dry-run only)
  local gh_command="gh release create \"$tag_name\" \\
    --title \"deckrd ${normalized_version}\" \\
    ${notes_desc} \\
    --draft=false \\
    \"${release_dir}/${archive_file}\" \\
    \"${release_dir}/${checksum_file}\""

  # Dry-run mode: show command without executing
  if [ "$DRY_RUN" = true ]; then
    echo ""
    echo "[DRY-RUN] Would execute:"
    echo ""
    echo "  $gh_command"
    echo ""
    echo "[DRY-RUN] Files to upload:"
    echo "  - ${release_dir}/${archive_file}"
    echo "  - ${release_dir}/${checksum_file}"
    if [ -f "$release_notes_file" ]; then
      echo ""
      echo "[DRY-RUN] Release notes content:"
      echo "---"
      cat "$release_notes_file"
      echo "---"
    fi
    echo ""
    echo "[DRY-RUN] Release URL would be:"
    echo "  ${repo_url}/releases/tag/${tag_name}"
    return 0
  fi

  # Create release with files
  if [ -f "$release_notes_file" ]; then
    # Use release-notes file
    if gh release create "$tag_name" \
      --title "deckrd ${normalized_version}" \
      --notes-file "$release_notes_file" \
      --draft=false \
      "${release_dir}/${archive_file}" \
      "${release_dir}/${checksum_file}"; then
      echo ""
      echo "Successfully published release ${normalized_version}"
      echo "View at: ${repo_url}/releases/tag/${tag_name}"
      return 0
    else
      echo "Error: Failed to create GitHub release" >&2
      return 1
    fi
  else
    # Use default notes
    if gh release create "$tag_name" \
      --title "deckrd ${normalized_version}" \
      --notes "Release ${normalized_version}" \
      --draft=false \
      "${release_dir}/${archive_file}" \
      "${release_dir}/${checksum_file}"; then
      echo ""
      echo "Successfully published release ${normalized_version}"
      echo "View at: ${repo_url}/releases/tag/${tag_name}"
      return 0
    else
      echo "Error: Failed to create GitHub release" >&2
      return 1
    fi
  fi
}

# ============================================================================
# Main Function
# ============================================================================

main() {
  local raw_version=""

  # Parse arguments
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -n|--dry-run)
        DRY_RUN=true
        shift
        ;;
      -h|--help)
        show_usage
        exit 0
        ;;
      -*)
        echo "Error: Unknown option: $1" >&2
        show_usage >&2
        exit 1
        ;;
      *)
        raw_version="$1"
        shift
        ;;
    esac
  done

  echo "Deckrd GitHub Release Publisher"
  echo "================================"
  if [ "$DRY_RUN" = true ]; then
    echo "[DRY-RUN MODE]"
  fi
  echo ""

  # Get and normalize version
  local normalized_version
  normalized_version=$(get_normalized_version "$raw_version") || exit 1

  echo "Version: $normalized_version"
  echo ""

  # Check prerequisites
  check_gh_cli || exit 1
  echo ""

  # Verify release files exist
  verify_release_files "$normalized_version" || exit 1
  echo ""

  # Publish to GitHub
  publish_to_github "$normalized_version" || exit 1
}

# ============================================================================
# Execute main function
# ============================================================================
main "$@"
