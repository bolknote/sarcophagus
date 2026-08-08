#!/usr/bin/env bash

set -euo pipefail

script_directory="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
project_root="$(cd "$script_directory/.." && pwd)"
source_icon="$project_root/packaging/icon.png"
macos_icon="$project_root/packaging/macos/Sarcophagus.icns"
windows_icon="$project_root/packaging/windows/Sarcophagus.ico"
temporary_directory="$(mktemp -d)"
iconset="$temporary_directory/Sarcophagus.iconset"

cleanup() {
    find "$temporary_directory" -mindepth 1 -delete 2>/dev/null || true
    rmdir "$temporary_directory" 2>/dev/null || true
}
trap cleanup EXIT

for tool in magick iconutil; do
    if ! command -v "$tool" >/dev/null 2>&1; then
        echo "Required icon generation tool is missing: $tool" >&2
        exit 1
    fi
done
if [[ ! -f "$source_icon" ]]; then
    echo "Source icon is missing: $source_icon" >&2
    exit 1
fi

source_dimensions="$(magick identify -format '%wx%h' "$source_icon")"
if [[ "$source_dimensions" != "256x256" ]]; then
    echo "Source icon must be a 256x256 PNG; found $source_dimensions." >&2
    exit 1
fi

mkdir -p "$iconset"
make_png() {
    local size="$1"
    local destination="$2"
    magick "$source_icon" \
        -alpha on \
        -filter point \
        -resize "${size}x${size}!" \
        -strip \
        "$destination"
}

make_png 16 "$iconset/icon_16x16.png"
make_png 32 "$iconset/icon_16x16@2x.png"
make_png 32 "$iconset/icon_32x32.png"
make_png 64 "$iconset/icon_32x32@2x.png"
make_png 128 "$iconset/icon_128x128.png"
make_png 256 "$iconset/icon_128x128@2x.png"
make_png 256 "$iconset/icon_256x256.png"
make_png 512 "$iconset/icon_256x256@2x.png"
make_png 512 "$iconset/icon_512x512.png"
make_png 1024 "$iconset/icon_512x512@2x.png"

iconutil --convert icns --output "$macos_icon" "$iconset"

for size in 16 24 32 48 64 128 256; do
    make_png "$size" "$temporary_directory/icon-${size}.png"
done
magick \
    "$temporary_directory/icon-16.png" \
    "$temporary_directory/icon-24.png" \
    "$temporary_directory/icon-32.png" \
    "$temporary_directory/icon-48.png" \
    "$temporary_directory/icon-64.png" \
    "$temporary_directory/icon-128.png" \
    "$temporary_directory/icon-256.png" \
    "$windows_icon"

echo "Built $macos_icon"
echo "Built $windows_icon"
shasum -a 256 "$macos_icon" "$windows_icon"
