#!/usr/bin/env bash

set -euo pipefail

export SARCOPHAGUS_TEST_BACKGROUND="${SARCOPHAGUS_TEST_BACKGROUND:-1}"

script_directory="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
project_root="$(cd "$script_directory/.." && pwd)"
love_binary="${LOVE_BIN:-$project_root/.tools/love-11.5/runtime/love.app/Contents/MacOS/love}"
build_root="$project_root/build"
generated_directory="$build_root/generated"
staging_directory="$build_root/staging"
smoke_archive="$build_root/Sarcophagus-smoke.love"
distribution_directory="$project_root/dist"
release_archive="$distribution_directory/Sarcophagus.love"
release_manifest="$script_directory/release-manifest.txt"

if [[ -n "${SOURCE_DATE_EPOCH:-}" ]]; then
    source_date_epoch="$SOURCE_DATE_EPOCH"
elif command -v git >/dev/null 2>&1 && \
    source_date_epoch="$(git -C "$project_root" log -1 --format=%ct 2>/dev/null)" && \
    [[ -n "$source_date_epoch" ]]; then
    :
else
    if source_date_epoch="$(stat -f '%m' "$project_root/version.txt" 2>/dev/null)" &&
        [[ "$source_date_epoch" =~ ^[0-9]+$ ]]; then
        :
    else
        source_date_epoch="$(stat -c '%Y' "$project_root/version.txt")"
    fi
fi
if [[ ! "$source_date_epoch" =~ ^[0-9]+$ ]]; then
    echo "SOURCE_DATE_EPOCH must be a non-negative integer: $source_date_epoch" >&2
    exit 1
fi
if normalized_timestamp="$(date -u -r "$source_date_epoch" '+%Y%m%d%H%M.%S' 2>/dev/null)"; then
    :
else
    normalized_timestamp="$(date -u -d "@$source_date_epoch" '+%Y%m%d%H%M.%S')"
fi

if [[ ! -f "$project_root/main.lua" || ! -f "$project_root/version.txt" ]]; then
    echo "Project root validation failed: $project_root" >&2
    exit 1
fi

if [[ ! -x "$love_binary" ]]; then
    echo "LÖVE 11.5 executable not found: $love_binary" >&2
    echo "Set LOVE_BIN to an executable LÖVE 11.5 binary." >&2
    exit 1
fi

if [[ ! -f "$release_manifest" ]]; then
    echo "Release manifest not found: $release_manifest" >&2
    exit 1
fi

bash "$script_directory/check-release-manifest.sh"

while IFS= read -r runtime_file; do
    if [[ -z "$runtime_file" || ! -f "$project_root/$runtime_file" ]]; then
        echo "Release manifest entry is missing: $runtime_file" >&2
        exit 1
    fi
done < "$release_manifest"

LOVE_BIN="$love_binary" "$script_directory/check-locales.sh"
LOVE_BIN="$love_binary" "$script_directory/check-ui-strings.sh"

mkdir -p "$generated_directory" "$staging_directory" "$distribution_directory"
find "$generated_directory" -mindepth 1 -delete
find "$staging_directory" -mindepth 1 -delete

SARCOPHAGUS_BUILD_MODE=development \
SARCOPHAGUS_SMOKE_TEST=atlas \
SARCOPHAGUS_ATLAS_OUTPUT="$generated_directory" \
    "$love_binary" "$project_root"

rsync -a --files-from="$release_manifest" \
    "$project_root/" "$staging_directory/"

mkdir -p "$staging_directory/tests"
cp "$project_root/tests/smoke.lua" "$staging_directory/tests/smoke.lua"

printf '%s\n' 'return { build_mode = "release" }' > "$staging_directory/release_config.lua"
cp "$generated_directory/quad.png" "$staging_directory/sprite-atlas-v1.png"
cp "$generated_directory/quad.table" "$staging_directory/sprite-atlas-v1.table"

make_archive() {
    local target="$1"
    rm -f "$target"
    find "$staging_directory" -exec touch -h -t "$normalized_timestamp" {} +
    (
        cd "$staging_directory"
        find . -type f -print | LC_ALL=C sort | /usr/bin/zip -9 -X -q "$target" -@
    )
}

make_archive "$smoke_archive"

/usr/bin/env -u SARCOPHAGUS_BUILD_MODE \
    SARCOPHAGUS_SMOKE_TEST=mapgen \
    "$love_binary" "$smoke_archive"

find "$staging_directory/tests" -mindepth 1 -delete
rmdir "$staging_directory/tests"
make_archive "$release_archive"
rm -f "$smoke_archive"

"$script_directory/audit-release.sh" "$release_archive"

shasum -a 256 "$release_archive"
echo "Built $release_archive"
