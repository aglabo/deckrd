#!/usr/bin/env bash
# src: ./scripts/create-release.sh
# @(#) : Create release archive with normalized version
#
# Copyright (c) 2025 atsushifx <http://github.com/atsushifx>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT
#
# @file create-release.sh
# @brief Create a release archive containing deckrd skill and metadata
# @description
#   Creates a release archive with a normalized version number.
#   Packages the deckrd skill along with LICENSE, README, and deckrd.json files.
#
#   The script:
#   1. Prompts for a version number and normalizes it to vX.Y.Z format
#   2. Creates a release directory: releases/<normalized-version>/
#   3. Copies skills/deckrd to temporary directory
#   4. Includes LICENSE, README files from project root
#   5. Includes deckrd.json with name, description, version, and stage fields
#   6. Creates a zip archive
#   7. Generates SHA256 checksum
#
# @example
#   # Create release with interactive version input
#   create-release.sh
#
# @exitcode 0 Success - archive created
# @exitcode 1 Error during execution
#
# @author atsushifx
# @version 2.0.0
# @license MIT

# don't use -u for checking error by Agent
set -eo pipefail

# set TimeZone to UTC for consistent timestamps
export TZ
[[ ${TZ+x} ]] && TZold="$TZ"
export TZ=UTC
trap cleanup EXIT

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
# @description Temporary directory for building release
TEMP_DIST=""

# ============================================================================
# Functions
# ============================================================================

##
# @description Show usage information
show_usage() {
  cat <<EOF
Usage: create-release.sh

Create a release archive for deckrd skill.

The script will:
  1. Prompt for version number (e.g., 1.0.0, v1.0.0, 1.0, 1)
  2. Normalize version to vX.Y.Z format
  3. Create releases/<version>/ directory
  4. Package deckrd skill with metadata
  5. Generate zip archive and SHA256 checksum

Output:
  releases/<normalized-version>/
    ├── deckrd-<version>.zip
    └── deckrd-<version>.zip.sha256

Version Format:
  Input: 1.0.0, v1.0.0, 1.0, or 1
  Output: v1.0.0
EOF
}

##
# @description Read version from standard input
# @stdout Version string
# @return 0 on success, 1 on error
read_version() {
  local version
  read -r version || {
    echo "Error: Failed to read version from stdin" >&2
    return 1
  }
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
# @description Read and normalize version from stdin
# @stdout Normalized version (vX.Y.Z)
# @return 0 on success, 1 on error
get_normalized_version() {
  local version
  version=$(read_version) || return 1
  normalize_version "$version" || return 1
}

##
# @description Create release directory for given version
# @arg $1 string Normalized version
# @stdout Path to created release directory
# @return 0 on success, 1 if directory already exists
create_release_directory() {
  local normalized_version="$1"
  local release_dir="${RELEASES_DIR}/${normalized_version}"

  if [ -d "$release_dir" ]; then
    echo "Error: Release directory already exists: $release_dir" >&2
    return 1
  fi

  mkdir -p "$release_dir"
  echo "Created release directory: $release_dir" >&2
  echo "$release_dir"
}

##
# @description Create temporary distribution directory
# @stdout Path to temporary directory
# @return 0 on success, 1 on error
create_temp_dist() {
  local temp_dist
  temp_dist="$(mktemp -d)" || {
    echo "Error: Failed to create temporary directory" >&2
    return 1
  }

  echo "$temp_dist"
}

##
# @description Copy deckrd skill to temporary distribution
# @arg $1 string Temporary dist directory path
# @return 0 on success, 1 on error
copy_deckrd_to_dist() {
  local temp_dist="$1"
  local deckrd_source="${PROJECT_ROOT}/skills/deckrd"
  local deckrd_dest="${temp_dist}/deckrd"

  # Validate temporary dist directory
  if [ -z "$temp_dist" ] || [ ! -d "$temp_dist" ]; then
    echo "Error: Invalid temporary dist directory: $temp_dist" >&2
    return 1
  fi

  # Check source directory exists
  if [ ! -d "$deckrd_source" ]; then
    echo "Error: Source directory not found: $deckrd_source" >&2
    return 1
  fi

  # Remove existing destination for clean copy
  if [ -d "$deckrd_dest" ]; then
    echo "Removing existing directory: $deckrd_dest"
    rm -rf "$deckrd_dest"
  fi

  # Copy using rsync if available, otherwise fallback to cp
  if command -v rsync >/dev/null 2>&1; then
    if rsync -a "$deckrd_source/" "$deckrd_dest/"; then
      echo "Copied skills/deckrd to $temp_dist/deckrd (using rsync)"
    else
      echo "Error: Failed to copy skills/deckrd to $temp_dist/" >&2
      return 1
    fi
  else
    echo "rsync not found, falling back to cp -fr"
    mkdir -p "$deckrd_dest"
    if cp -fr "$deckrd_source/" "$deckrd_dest"; then
      echo "Copied skills/deckrd to $temp_dist/deckrd (using cp -fr)"
    else
      echo "Error: Failed to copy skills/deckrd to $temp_dist/" >&2
      return 1
    fi
  fi
}

##
# @description Copy LICENSE and README files to distribution
# @arg $1 string Temporary dist directory path
# @return 0 on success, 1 on error
copy_files_to_dist() {
  local temp_dist="$1"
  local dist_deckrd_dir="${temp_dist}/deckrd"

  # Validate dist directory exists
  if [ ! -d "$dist_deckrd_dir" ]; then
    echo "Error: Directory not found: $dist_deckrd_dir" >&2
    return 1
  fi

  # Copy LICENSE and README files
  local patterns=("README" "LICENSE")
  local glob_patterns=()

  # Build glob patterns
  for pattern in "${patterns[@]}"; do
    glob_patterns+=("${PROJECT_ROOT}"/${pattern}*)
  done

  # Copy files
  if cp -fr "${glob_patterns[@]}" "$dist_deckrd_dir/" 2>/dev/null; then
    echo "Copied files to dist/deckrd/"
  else
    echo "Warning: Failed to copy some files" >&2
  fi
}

##
# @description Copy deckrd.json with selected fields to distribution
# @arg $1 string Temporary dist directory path
# @return 0 on success, 1 on error
copy_deckrd_json() {
  local temp_dist="$1"
  local source_json="${PROJECT_ROOT}/deckrd.json"
  local dest_json="${temp_dist}/deckrd/deckrd.json"
  local dist_dir="${temp_dist}/deckrd"

  # Check source exists
  if [ ! -f "$source_json" ]; then
    echo "Error: Source file not found: $source_json" >&2
    return 1
  fi

  # Check dist directory exists
  if [ ! -d "$dist_dir" ]; then
    echo "Error: Directory not found: $dist_dir" >&2
    return 1
  fi

  # Check jq is available
  if ! command -v jq >/dev/null 2>&1; then
    echo "Error: jq is not installed" >&2
    return 1
  fi

  # Extract only required fields
  if jq '{name, description, version, stage}' "$source_json" > "$dest_json"; then
    echo "Copied deckrd.json to dist/deckrd/deckrd.json"
  else
    echo "Error: Failed to copy deckrd.json" >&2
    return 1
  fi
}

##
# @description Create zip archive of distribution
# @arg $1 string Normalized version
# @arg $2 string Temporary dist directory path
# @return 0 on success, 1 on error
archive_deckrd() {
  local normalized_version="$1"
  local temp_dist="$2"
  local deckrd_dir="${temp_dist}/deckrd"
  local release_dir="${RELEASES_DIR}/${normalized_version}"
  local archive_file="${release_dir}/deckrd-${normalized_version}.zip"

  # Validate directories exist
  if [ ! -d "$deckrd_dir" ]; then
    echo "Error: Directory not found: $deckrd_dir" >&2
    return 1
  fi

  if [ ! -d "$release_dir" ]; then
    echo "Error: Release directory not found: $release_dir" >&2
    return 1
  fi

  # Check zip is available
  if ! command -v zip >/dev/null 2>&1; then
    echo "Error: zip is not installed" >&2
    return 1
  fi

  # Create archive from temp_dist parent directory
  if (cd "$temp_dist" && zip -r "$archive_file" "deckrd"); then
    echo "Created archive: $archive_file"
  else
    echo "Error: Failed to create archive" >&2
    return 1
  fi
}

##
# @description Generate SHA256 checksum for archive
# @arg $1 string Normalized version
# @return 0 on success, 1 on error
generate_checksum() {
  local normalized_version="$1"
  local release_dir="${RELEASES_DIR}/${normalized_version}"
  local archive_file="deckrd-${normalized_version}.zip"

  if [ ! -d "$release_dir" ]; then
    echo "Error: Release directory not found: $release_dir" >&2
    return 1
  fi

  if (cd "$release_dir" && sha256sum -t "$archive_file" > "${archive_file}.sha256"); then
    echo "Generated checksum: ${archive_file}.sha256"
  else
    echo "Error: Failed to generate checksum" >&2
    return 1
  fi
}

##
# @description Cleanup temporary directory and Restore TZ on exit
cleanup() {
  if [ -n "$TEMP_DIST" ] && [ -d "$TEMP_DIST" ]; then
    echo "Cleaning up temporary directory: $TEMP_DIST"
    rm -rf "$TEMP_DIST"
  fi

  # Restore TZ
  if [[ ${TZold+x} ]]; then
    export TZ="$TZold"
  else
    unset TZ
  fi
}

# ============================================================================
# Main Function
# ============================================================================

main() {
  echo "Deckrd Release Directory Creator"
  echo "================================="
  echo ""

  # Prompt for version
  echo "Enter version (e.g., 1.0.0, v1.0.0, 1.0, 1):"
  local normalized_version
  normalized_version=$(get_normalized_version) || exit 1

  echo ""
  echo "Normalized version: $normalized_version"
  echo ""

  # Create temporary dist directory
  TEMP_DIST=$(create_temp_dist) || exit 1
  echo "Created temporary dist directory: $TEMP_DIST"
  echo ""

  # Set cleanup trap

  # Create release directory
  local release_dir
  release_dir=$(create_release_directory "$normalized_version") || exit 1

  # Copy skills/deckrd
  copy_deckrd_to_dist "$TEMP_DIST" || exit 1

  # Copy LICENSE and README files
  copy_files_to_dist "$TEMP_DIST" || exit 1

  # Copy deckrd.json with selected fields
  copy_deckrd_json "$TEMP_DIST" || exit 1

  # Create zip archive
  archive_deckrd "$normalized_version" "$TEMP_DIST" || exit 1

  # Generate checksum
  generate_checksum "$normalized_version" || exit 1
}

# ============================================================================
# Execute main function
# ============================================================================
main "$@"
