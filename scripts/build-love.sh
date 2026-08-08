#!/usr/bin/env bash

set -euo pipefail

script_directory="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
project_root="$(cd "$script_directory/.." && pwd)"
love_binary="${LOVE_BIN:-$project_root/.tools/love-11.5/runtime/love.app/Contents/MacOS/love}"
build_root="$project_root/build"
generated_directory="$build_root/generated"
staging_directory="$build_root/staging"
smoke_archive="$build_root/Sarcophagus-smoke.love"
distribution_directory="$project_root/dist"
release_archive="$distribution_directory/Sarcophagus.love"

if [[ ! -f "$project_root/main.lua" || ! -f "$project_root/version.txt" ]]; then
    echo "Project root validation failed: $project_root" >&2
    exit 1
fi

if [[ ! -x "$love_binary" ]]; then
    echo "LÖVE 11.5 executable not found: $love_binary" >&2
    echo "Set LOVE_BIN to an executable LÖVE 11.5 binary." >&2
    exit 1
fi

LOVE_BIN="$love_binary" "$script_directory/check-locales.sh"

mkdir -p "$generated_directory" "$staging_directory" "$distribution_directory"
find "$generated_directory" -mindepth 1 -delete
find "$staging_directory" -mindepth 1 -delete

SARCOPHAGUS_BUILD_MODE=development \
SARCOPHAGUS_SMOKE_TEST=atlas \
SARCOPHAGUS_ATLAS_OUTPUT="$generated_directory" \
    "$love_binary" "$project_root"

rsync -a \
    --exclude '/.git/' \
    --exclude '/.tools/' \
    --exclude '/build/' \
    --exclude '/dist/' \
    --exclude '/docs/' \
    --exclude '/gr/' \
    --exclude '/scripts/' \
    --exclude '/.DS_Store' \
    --exclude '/.gitignore' \
    --exclude '/9.sav' \
    --exclude '/README.md' \
    --exclude '/plan.md' \
    --exclude '/main_old.lua' \
    --exclude '/moving_editor.lua' \
    --exclude '/lurker.lua' \
    --exclude '/lume.lua' \
    --exclude '/locales/ru_legacy.lua' \
    --exclude '/texture.lua' \
    --exclude '/sarcophagous.sublime-project' \
    --exclude '/sarcophagous.sublime-workspace' \
    --exclude '/maps/log.txt' \
    --exclude '/maps/sar.sublime-completions' \
    --exclude '/maps/sarco.py' \
    "$project_root/" "$staging_directory/"

printf '%s\n' 'return { build_mode = "release" }' > "$staging_directory/release_config.lua"
cp "$generated_directory/quad.png" "$staging_directory/quad.png"
cp "$generated_directory/quad.table" "$staging_directory/quad.table"

make_archive() {
    local target="$1"
    rm -f "$target"
    (
        cd "$staging_directory"
        /usr/bin/zip -9 -q -r "$target" .
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

if /usr/bin/unzip -Z1 "$release_archive" | \
    grep -E '(^|/)(gr|tests|docs|scripts|\.git)(/|$)|(^|/)(9\.sav|lurker\.lua|moving_editor\.lua|ru_legacy\.lua)$' >/dev/null; then
    echo "Release archive contains development-only files" >&2
    exit 1
fi

shasum -a 256 "$release_archive"
echo "Built $release_archive"
