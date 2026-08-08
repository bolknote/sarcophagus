#!/usr/bin/env bash

set -euo pipefail

script_directory="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
project_root="$(cd "$script_directory/.." && pwd)"
manifest="$script_directory/release-manifest.txt"
archive="${1:-$project_root/dist/Sarcophagus.love}"
max_archive_bytes="${MAX_LOVE_ARCHIVE_BYTES:-12582912}"
expected_files="$(mktemp)"
archive_files="$(mktemp)"

cleanup() {
    unlink "$expected_files" 2>/dev/null || true
    unlink "$archive_files" 2>/dev/null || true
}
trap cleanup EXIT

if [[ ! -f "$archive" ]]; then
    echo "Release archive not found: $archive" >&2
    exit 1
fi

if [[ ! -f "$manifest" ]]; then
    echo "Release manifest not found: $manifest" >&2
    exit 1
fi

if [[ ! "$max_archive_bytes" =~ ^[0-9]+$ ]] || [[ "$max_archive_bytes" == "0" ]]; then
    echo "MAX_LOVE_ARCHIVE_BYTES must be a positive integer: $max_archive_bytes" >&2
    exit 1
fi

{
    LC_ALL=C sort -u "$manifest"
    printf '%s\n' quad.png quad.table release_config.lua
} | LC_ALL=C sort -u > "$expected_files"

/usr/bin/unzip -tqq "$archive"
/usr/bin/unzip -Z1 "$archive" | sed '/\/$/d' | LC_ALL=C sort -u > "$archive_files"

if ! diff -u "$expected_files" "$archive_files"; then
    echo "Release archive differs from scripts/release-manifest.txt" >&2
    exit 1
fi

file_count="$(wc -l < "$archive_files" | tr -d ' ')"
archive_bytes="$(stat -f '%z' "$archive" 2>/dev/null || stat -c '%s' "$archive")"
if (( archive_bytes > max_archive_bytes )); then
    echo "Release archive is too large: $archive_bytes bytes (limit: $max_archive_bytes)." >&2
    echo "Review large assets or override MAX_LOVE_ARCHIVE_BYTES intentionally." >&2
    exit 1
fi
echo "SARCOPHAGUS_RELEASE_AUDIT_OK files=$file_count bytes=$archive_bytes limit=$max_archive_bytes"
