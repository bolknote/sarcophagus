#!/usr/bin/env bash

set -euo pipefail

script_directory="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
project_root="$(cd "$script_directory/.." && pwd)"
version="$(tr -d '[:space:]' < "$project_root/version.txt")"

love_version="11.5"
love_runtime_url="https://github.com/love2d/love/releases/download/11.5/love-11.5-x86_64.AppImage"
love_runtime_sha256="65a673406431eff7167a15a032bf7a2e4ba50108e091eb7b176465831f9b5e00"

# The continuous URLs are mutable, so both downloads are accepted only when
# they match these artifacts and commits exactly.
appimagetool_commit="8c8c91f762b412a19f4e8d2c4b35afb98f2d7c81"
appimagetool_url="https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-x86_64.AppImage"
appimagetool_sha256="a6d71e2b6cd66f8e8d16c37ad164658985e0cf5fcaa950c90a482890cb9d13e0"
appimage_runtime_commit="75849dce7cc37e4319b633df1f116ca895c71a12"
appimage_runtime_url="https://github.com/AppImage/type2-runtime/releases/download/continuous/runtime-x86_64"
appimage_runtime_sha256="1cc49bcf1e2ccd593c379adb17c9f85a36d619088296504de95b1d06215aebbf"

love_archive="${LOVE_ARCHIVE:-$project_root/dist/Sarcophagus.love}"
love_appimage="${LOVE_APPIMAGE:-$project_root/.tools/love-$love_version/love-$love_version-x86_64.AppImage}"
appimagetool="${APPIMAGETOOL:-$project_root/.tools/appimagetool/$appimagetool_commit/appimagetool-x86_64.AppImage}"
appimage_runtime="${APPIMAGE_RUNTIME:-$project_root/.tools/appimagetool/$appimage_runtime_commit/runtime-x86_64}"
distribution_directory="${OUTPUT_DIRECTORY:-$project_root/dist}"
build_directory="$project_root/build/native/linux-x86_64"
extraction_directory="$build_directory/runtime"
verification_directory="$build_directory/verification"
appdir="$extraction_directory/squashfs-root"
verified_appdir="$verification_directory/squashfs-root"
package="$distribution_directory/Sarcophagus-linux-x86_64-$version.AppImage"
apprun_source="$project_root/packaging/linux/AppRun"
desktop_source="$project_root/packaging/linux/ru.spectator.sarcophagus.desktop"
icon_source="$project_root/packaging/icon.png"

if [[ "$(uname -s)" != "Linux" ]]; then
    echo "The Linux AppImage must be built on Linux." >&2
    exit 1
fi
case "$(uname -m)" in
    x86_64 | amd64) ;;
    *)
        echo "The x86_64 AppImage must be built on an x86_64 host." >&2
        exit 1
        ;;
esac

for tool in curl sha256sum awk cmp tail find touch; do
    if ! command -v "$tool" >/dev/null 2>&1; then
        echo "Required Linux packaging tool is missing: $tool" >&2
        exit 1
    fi
done
for required_file in "$apprun_source" "$desktop_source" "$icon_source"; do
    if [[ ! -f "$required_file" ]]; then
        echo "Linux packaging file is missing: $required_file" >&2
        exit 1
    fi
done

download_pinned() {
    local label="$1"
    local url="$2"
    local expected_sha256="$3"
    local destination="$4"
    local actual_sha256
    local temporary_download="$destination.download"

    mkdir -p "$(dirname "$destination")"
    if [[ ! -f "$destination" ]]; then
        rm -f "$temporary_download"
        echo "Downloading $label..."
        curl -fL --retry 3 --output "$temporary_download" "$url"
        mv "$temporary_download" "$destination"
    fi

    actual_sha256="$(sha256sum "$destination" | awk '{print $1}')"
    if [[ "$actual_sha256" != "$expected_sha256" ]]; then
        echo "Unexpected $label checksum: $actual_sha256 (expected $expected_sha256)" >&2
        exit 1
    fi
}

if [[ ! -f "$love_archive" ]]; then
    echo "Release archive not found: $love_archive" >&2
    echo "Build dist/Sarcophagus.love first with scripts/build-love.sh." >&2
    exit 1
fi
"$script_directory/audit-release.sh" "$love_archive"

download_pinned "official LÖVE $love_version x86_64 AppImage" \
    "$love_runtime_url" "$love_runtime_sha256" "$love_appimage"
download_pinned "appimagetool at $appimagetool_commit" \
    "$appimagetool_url" "$appimagetool_sha256" "$appimagetool"
download_pinned "AppImage x86_64 runtime at $appimage_runtime_commit" \
    "$appimage_runtime_url" "$appimage_runtime_sha256" "$appimage_runtime"
chmod +x "$love_appimage" "$appimagetool"

mkdir -p "$build_directory" "$distribution_directory"
find "$build_directory" -mindepth 1 -delete
mkdir -p "$extraction_directory"

(
    cd "$extraction_directory"
    "$love_appimage" --appimage-extract >/dev/null
)

runtime_executable="$appdir/bin/love"
fused_executable="$appdir/bin/Sarcophagus"
if [[ ! -x "$appdir/AppRun" || ! -x "$runtime_executable" ]]; then
    echo "The official LÖVE AppImage has an unexpected AppDir layout." >&2
    exit 1
fi

cat "$runtime_executable" "$love_archive" > "$fused_executable"
chmod +x "$fused_executable"
love_size="$(stat -c '%s' "$love_archive")"
if ! tail -c "$love_size" "$fused_executable" | cmp -s - "$love_archive"; then
    echo "The fused Linux executable does not contain the expected .love archive." >&2
    exit 1
fi
rm -f "$runtime_executable"

find "$appdir" -maxdepth 1 \
    \( -name '*.desktop' -o -name '*.png' -o -name '*.svg' -o -name '.DirIcon' \) \
    -delete
for applications_directory in \
    "$appdir/share/applications" \
    "$appdir/usr/share/applications"; do
    if [[ -d "$applications_directory" ]]; then
        find "$applications_directory" -maxdepth 1 -type f -name '*.desktop' -delete
    fi
done
rm -f \
    "$appdir/share/icons/hicolor/scalable/mimetypes/application-x-love-game.svg" \
    "$appdir/share/mime/packages/love.xml" \
    "$appdir/share/pixmaps/love.svg"

rm -f "$appdir/AppRun"
cp "$apprun_source" "$appdir/AppRun"
chmod +x "$appdir/AppRun"
cp "$desktop_source" "$appdir/ru.spectator.sarcophagus.desktop"
cp "$icon_source" "$appdir/ru.spectator.sarcophagus.png"
ln -s ru.spectator.sarcophagus.png "$appdir/.DirIcon"

mkdir -p \
    "$appdir/share/applications" \
    "$appdir/share/icons/hicolor/256x256/apps"
cp "$desktop_source" \
    "$appdir/share/applications/ru.spectator.sarcophagus.desktop"
cp "$icon_source" \
    "$appdir/share/icons/hicolor/256x256/apps/ru.spectator.sarcophagus.png"

if [[ -n "${SOURCE_DATE_EPOCH:-}" ]]; then
    source_date_epoch="$SOURCE_DATE_EPOCH"
elif command -v git >/dev/null 2>&1 && \
    source_date_epoch="$(git -C "$project_root" log -1 --format=%ct 2>/dev/null)" && \
    [[ -n "$source_date_epoch" ]]; then
    :
else
    source_date_epoch="$(stat -c '%Y' "$project_root/version.txt")"
fi
if [[ ! "$source_date_epoch" =~ ^[0-9]+$ ]]; then
    echo "SOURCE_DATE_EPOCH must be a non-negative integer: $source_date_epoch" >&2
    exit 1
fi
find "$appdir" -exec touch -h -d "@$source_date_epoch" {} +

rm -f "$package"
APPIMAGE_EXTRACT_AND_RUN=1 \
ARCH=x86_64 \
SOURCE_DATE_EPOCH="$source_date_epoch" \
    "$appimagetool" \
    --no-appstream \
    --runtime-file "$appimage_runtime" \
    "$appdir" "$package"
chmod +x "$package"

mkdir -p "$verification_directory"
(
    cd "$verification_directory"
    "$package" --appimage-extract >/dev/null
)

root_desktop_count="$(find "$verified_appdir" -maxdepth 1 -type f -name '*.desktop' | wc -l | tr -d ' ')"
if [[ "$root_desktop_count" != "1" ]]; then
    echo "The AppImage must contain exactly one root desktop file; found $root_desktop_count." >&2
    exit 1
fi
if ! cmp -s "$desktop_source" "$verified_appdir/ru.spectator.sarcophagus.desktop"; then
    echo "The AppImage desktop entry differs from its packaging source." >&2
    exit 1
fi
if ! cmp -s "$icon_source" "$verified_appdir/ru.spectator.sarcophagus.png"; then
    echo "The AppImage icon differs from its packaging source." >&2
    exit 1
fi
if ! cmp -s "$apprun_source" "$verified_appdir/AppRun"; then
    echo "The AppImage AppRun differs from its packaging source." >&2
    exit 1
fi
if [[ -e "$verified_appdir/bin/love" || ! -x "$verified_appdir/bin/Sarcophagus" ]]; then
    echo "The AppImage contains an unexpected LÖVE executable layout." >&2
    exit 1
fi
for obsolete_runtime_file in \
    "$verified_appdir/share/icons/hicolor/scalable/mimetypes/application-x-love-game.svg" \
    "$verified_appdir/share/mime/packages/love.xml" \
    "$verified_appdir/share/pixmaps/love.svg"; do
    if [[ -e "$obsolete_runtime_file" ]]; then
        echo "The AppImage still contains obsolete LÖVE desktop integration: $obsolete_runtime_file" >&2
        exit 1
    fi
done

embedded_love="$verification_directory/Sarcophagus.love"
tail -c "$love_size" "$verified_appdir/bin/Sarcophagus" > "$embedded_love"
if ! cmp -s "$love_archive" "$embedded_love"; then
    echo "The AppImage embedded .love archive failed checksum verification." >&2
    exit 1
fi
"$script_directory/audit-release.sh" "$embedded_love"

sha256sum "$package"
echo "Built $package"
