#!/usr/bin/env bash
## src: ./scripts/create-release.sh
# @(#) : Create release directory with normalized version
#
# Copyright (c) 2025 atsushifx <http://github.com/atsushifx>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT
#

set -euo pipefail
TZ='UTC'

# バージョンを標準入力から読み込む関数
read_version() {
  local version
  read -r version || {
    echo "Error: Failed to read version from stdin" >&2
    return 1
  }
  echo "$version"
}

# バージョンをvX.Y.Z形式に正規化する関数
normalize_version() {
  local version="$1"

  # v プレフィックスを削除
  version="${version#v}"
  version="${version#V}"

  # バージョン番号の抽出（最初の3つの数字グループ）
  # サフィックス（-beta など）は許容しない
  if [[ ! "$version" =~ ^([0-9]+)(\.[0-9]+)?(\.[0-9]+)?$ ]]; then
    echo "Error: Invalid version format: $version" >&2
    return 1
  fi

  local major="${BASH_REMATCH[1]}"
  local minor="${BASH_REMATCH[2]#.}"
  local patch="${BASH_REMATCH[3]#.}"

  # デフォルト値を設定
  minor="${minor:-0}"
  patch="${patch:-0}"

  # vX.Y.Z形式で返す
  echo "v${major}.${minor}.${patch}"
}

# 標準入力からバージョンを読み込んで正規化する関数
get_normalized_version() {
  local version
  version=$(read_version) || return 1
  normalize_version "$version" || return 1
}

# リリースディレクトリを作成する関数
create_release_directory() {
  local normalized_version="$1"

  # スクリプトのディレクトリを取得
  local script_dir
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  local project_root
  project_root="$(dirname "$script_dir")"

  local release_dir="$project_root/releases/$normalized_version"

  if [ -d "$release_dir" ]; then
    echo "Error: Release directory already exists: $release_dir" >&2
    return 1
  fi

  mkdir -p "$release_dir"
  echo "Created release directory: $release_dir" >&2
  echo "$release_dir"
}

# 一時的なdistディレクトリを作成する関数
create_temp_dist() {
  local temp_dist
  temp_dist="$(mktemp -d)" || {
    echo "Error: Failed to create temporary directory" >&2
    return 1
  }

  echo "$temp_dist"
}

# dist/deckrdをzipアーカイブする関数
archive_deckrd() {
  local normalized_version="$1"
  local temp_dist="$2"

  # スクリプトのディレクトリを取得
  local script_dir
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  local project_root
  project_root="$(dirname "$script_dir")"

  local deckrd_dir="$temp_dist/deckrd"
  local release_dir="$project_root/releases/$normalized_version"
  local archive_file="$release_dir/deckrd-${normalized_version}.zip"

  # dist/deckrd ディレクトリが存在するか確認
  if [ ! -d "$deckrd_dir" ]; then
    echo "Error: Directory not found: $deckrd_dir" >&2
    return 1
  fi

  # リリースディレクトリが存在するか確認
  if [ ! -d "$release_dir" ]; then
    echo "Error: Release directory not found: $release_dir" >&2
    return 1
  fi

  # zipアーカイブを作成
  # 現在のディレクトリをdeckrdの親ディレクトリに変更して、相対パスでアーカイブを作成
  if ! command -v zip &> /dev/null; then
    echo "Error: zip is not installed" >&2
    return 1
  fi

  (cd "$temp_dist" && zip -r "$archive_file" "deckrd")

  if [ $? -eq 0 ]; then
    echo "Created archive: $archive_file"
  else
    echo "Error: Failed to create archive" >&2
    return 1
  fi
}

# LICENSEファイルをdist/deckrd/下にコピーする関数
copy_license_files() {
  local temp_dist="$1"

  # スクリプトのディレクトリを取得
  local script_dir
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  local project_root
  project_root="$(dirname "$script_dir")"

  local dist_deckrd_dir="$temp_dist/deckrd"

  # dist/deckrd ディレクトリが存在するか確認
  if [ ! -d "$dist_deckrd_dir" ]; then
    echo "Error: Directory not found: $dist_deckrd_dir" >&2
    return 1
  fi

  # LICENSE* ファイルをコピー
  local license_files=("$project_root"/LICENSE*)
  local found=false

  for license_file in "${license_files[@]}"; do
    # ファイルが存在するか確認
    if [ -f "$license_file" ]; then
      local filename
      filename=$(basename "$license_file")
      cp "$license_file" "$dist_deckrd_dir/$filename"
      echo "Copied license file: $filename"
      found=true
    fi
  done

  if [ "$found" = false ]; then
    echo "Warning: No LICENSE files found in project root" >&2
  fi
}

# deckrd.jsonファイルをdist/deckrd/下にコピーする関数
copy_deckrd_json() {
  local temp_dist="$1"

  # スクリプトのディレクトリを取得
  local script_dir
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  local project_root
  project_root="$(dirname "$script_dir")"

  local source_json="$project_root/deckrd.json"
  local dest_json="$temp_dist/deckrd/deckrd.json"
  local dist_dir="$temp_dist/deckrd"

  # ソースの deckrd.json が存在するか確認
  if [ ! -f "$source_json" ]; then
    echo "Error: Source file not found: $source_json" >&2
    return 1
  fi

  # dist/deckrd ディレクトリが存在するか確認
  if [ ! -d "$dist_dir" ]; then
    echo "Error: Directory not found: $dist_dir" >&2
    return 1
  fi

  # jq を使用して特定フィールドだけを抽出
  if ! command -v jq &> /dev/null; then
    echo "Error: jq is not installed" >&2
    return 1
  fi

  jq '{name, description, version, stage}' "$source_json" > "$dest_json"

  if [ $? -eq 0 ]; then
    echo "Copied deckrd.json to dist/deckrd/deckrd.json"
  else
    echo "Error: Failed to copy deckrd.json" >&2
    return 1
  fi
}

# skills/deckrdを一時dist下にコピーする関数
copy_deckrd_to_dist() {
  local temp_dist="$1"

  # スクリプトのディレクトリを取得
  local script_dir
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  local project_root
  project_root="$(dirname "$script_dir")"

  local deckrd_source="$project_root/skills/deckrd"
  local deckrd_dest="$temp_dist/deckrd"

  # 一時distディレクトリが存在するか確認
  if [ -z "$temp_dist" ] || [ ! -d "$temp_dist" ]; then
    echo "Error: Invalid temporary dist directory: $temp_dist" >&2
    return 1
  fi

  # skills/deckrd ディレクトリが存在するか確認
  if [ ! -d "$deckrd_source" ]; then
    echo "Error: Source directory not found: $deckrd_source" >&2
    return 1
  fi

  # deckrd_dest が既に存在する場合は削除してクリーンな状態を保つ
  if [ -d "$deckrd_dest" ]; then
    echo "Removing existing directory: $deckrd_dest"
    rm -rf "$deckrd_dest"
  fi

  # skills/deckrd を temp_dist 下にコピー
  if command -v rsync &> /dev/null; then
    # rsync が利用可能な場合
    rsync -a "$deckrd_source" "$deckrd_dest"
    if [ $? -eq 0 ]; then
      echo "Copied skills/deckrd to $temp_dist/deckrd (using rsync)"
    else
      echo "Error: Failed to copy skills/deckrd to $temp_dist/" >&2
      return 1
    fi
  else
    # rsync が利用不可の場合は cp -fr にフォールバック
    echo "rsync not found, falling back to cp -fr"
    mkdir -p "$deckrd_dest"
    cp -fr "$deckrd_source/" "$deckrd_dest"
    if [ $? -eq 0 ]; then
      echo "Copied skills/deckrd to $temp_dist/deckrd (using cp -fr)"
    else
      echo "Error: Failed to copy skills/deckrd to $temp_dist/" >&2
      return 1
    fi
  fi
}

# メイン処理
main() {
  echo "Deckrd Release Directory Creator"
  echo "================================="
  echo ""

  # バージョンを入力して正規化
  echo "Enter version (e.g., 1.0.0, v1.0.0, 1.0, 1):"
  local normalized_version
  normalized_version=$(get_normalized_version) || exit 1

  echo ""
  echo "Normalized version: $normalized_version"
  echo ""

  # 一時的なdistディレクトリを作成
  local temp_dist
  temp_dist=$(create_temp_dist) || exit 1
  echo "Created temporary dist directory: $temp_dist"
  echo ""

  # クリーンアップ関数（終了時に実行）
  cleanup() {
    if [ -n "$temp_dist" ] && [ -d "$temp_dist" ]; then
      echo "Cleaning up temporary directory: $temp_dist"
      rm -rf "$temp_dist"
    fi
  }
  trap cleanup EXIT

  # リリースディレクトリを作成
  local release_dir
  release_dir=$(create_release_directory "$normalized_version") || exit 1

  # skills/deckrdを一時dist下にコピー
  copy_deckrd_to_dist "$temp_dist" || exit 1

  # LICENSEファイルを一時dist/deckrd/下にコピー
  copy_license_files "$temp_dist" || exit 1

  # deckrd.jsonを一時dist/deckrd/下にコピー
  copy_deckrd_json "$temp_dist" || exit 1

  # 一時dist/deckrdをzipアーカイブ
  archive_deckrd "$normalized_version" "$temp_dist" || exit 1

  (cd "$release_dir" && sha256sum -t "deckrd-$normalized_version.zip" \
  > "deckrd-$normalized_version.zip.sha256")
}

main
