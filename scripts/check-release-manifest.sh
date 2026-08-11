#!/usr/bin/env bash

set -euo pipefail

script_directory="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
project_root="$(cd "$script_directory/.." && pwd)"
manifest="$script_directory/release-manifest.txt"

if [[ ! -f "$manifest" ]]; then
    echo "Release manifest not found: $manifest" >&2
    exit 1
fi

duplicate_entries="$(LC_ALL=C sort "$manifest" | uniq -d)"
if [[ -n "$duplicate_entries" ]]; then
    echo "Release manifest contains duplicate entries:" >&2
    echo "$duplicate_entries" >&2
    exit 1
fi

while IFS= read -r entry; do
    if [[ -z "$entry" || "$entry" == /* || "$entry" == *"../"* || \
        "$entry" == *"/.."* || ! -f "$project_root/$entry" ]]; then
        echo "Invalid or missing release manifest entry: $entry" >&2
        exit 1
    fi
done < "$manifest"

missing_entries="$(
    {
        printf '%s\n' conf.lua LICENSE.md main.lua packaging/icon.png version.txt
        (
            cd "$project_root"
            find src -type f -name '*.lua' -print
            find \
                assets/cursors \
                assets/fonts \
                assets/maps \
                assets/shaders \
                assets/sounds \
                -type f -print
        )
    } | LC_ALL=C sort -u | while IFS= read -r runtime_file; do
        if ! grep -Fxq "$runtime_file" "$manifest"; then
            printf '%s\n' "$runtime_file"
        fi
    done
)"

if [[ -n "$missing_entries" ]]; then
    echo "Release manifest omits runtime files:" >&2
    echo "$missing_entries" >&2
    exit 1
fi

echo "Release manifest is complete."
