#!/usr/bin/env bash

set -euo pipefail

script_directory="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
project_root="$(cd "$script_directory/.." && pwd)"
version="$(tr -d '[:space:]' < "$project_root/version.txt")"
love_archive_override="${LOVE_ARCHIVE:-}"
love_archive="${love_archive_override:-$project_root/dist/Sarcophagus.love}"
love_app="${LOVE_APP:-$project_root/.tools/love-11.5/runtime/love.app}"
signing_identity="${MACOS_SIGNING_IDENTITY:--}"
notary_profile="${MACOS_NOTARY_PROFILE:-}"
entitlements="$project_root/packaging/macos/entitlements.plist"
icon_source="$project_root/packaging/macos/Sarcophagus.icns"
build_directory="$project_root/build/native/macos"
application="$build_directory/Sarcophagus.app"
distribution_directory="$project_root/dist"
package="$distribution_directory/Sarcophagus-macos-universal-$version.zip"
plist_buddy="/usr/libexec/PlistBuddy"

if [[ "$(uname -s)" != "Darwin" ]]; then
    echo "The macOS package must be built on macOS." >&2
    exit 1
fi

for tool in codesign ditto plutil spctl xcrun; do
    if ! command -v "$tool" >/dev/null 2>&1; then
        echo "Required macOS tool is missing: $tool" >&2
        exit 1
    fi
done

if [[ ! -x "$plist_buddy" ]]; then
    echo "Required macOS tool is missing: $plist_buddy" >&2
    exit 1
fi
if [[ ! -d "$love_app" || ! -x "$love_app/Contents/MacOS/love" ]]; then
    echo "Official LÖVE 11.5 app not found: $love_app" >&2
    echo "Set LOVE_APP to the extracted LÖVE 11.5 love.app bundle." >&2
    exit 1
fi
if [[ ! -f "$entitlements" ]]; then
    echo "Entitlements file not found: $entitlements" >&2
    exit 1
fi
if [[ ! -f "$icon_source" ]]; then
    echo "macOS application icon not found: $icon_source" >&2
    echo "Regenerate platform icons with scripts/generate-platform-icons.sh." >&2
    exit 1
fi
if [[ -n "$notary_profile" && "$signing_identity" == "-" ]]; then
    echo "MACOS_NOTARY_PROFILE requires a Developer ID identity in MACOS_SIGNING_IDENTITY." >&2
    exit 1
fi

if [[ -z "$love_archive_override" ]]; then
    "$script_directory/build-love.sh"
elif [[ ! -f "$love_archive" ]]; then
    echo "Explicit LOVE_ARCHIVE not found: $love_archive" >&2
    exit 1
fi
"$script_directory/audit-release.sh" "$love_archive"

mkdir -p "$build_directory" "$distribution_directory"
find "$build_directory" -mindepth 1 -delete
rm -f "$package"

ditto "$love_app" "$application"
cp "$love_archive" "$application/Contents/Resources/Sarcophagus.love"
if ! cmp -s "$love_archive" "$application/Contents/Resources/Sarcophagus.love"; then
    echo "Embedded .love archive failed its checksum verification." >&2
    exit 1
fi
mv "$application/Contents/MacOS/love" "$application/Contents/MacOS/Sarcophagus"
chmod +x "$application/Contents/MacOS/Sarcophagus"
rm -f \
    "$application/Contents/Resources/GameIcon.icns" \
    "$application/Contents/Resources/OS X AppIcon.icns"
cp "$icon_source" "$application/Contents/Resources/Sarcophagus.icns"

info_plist="$application/Contents/Info.plist"
"$plist_buddy" -c "Set :CFBundleExecutable Sarcophagus" "$info_plist"
"$plist_buddy" -c "Set :CFBundleIdentifier ru.spectator.sarcophagus" "$info_plist"
"$plist_buddy" -c "Set :CFBundleName Sarcophagus" "$info_plist"
"$plist_buddy" -c "Set :CFBundleShortVersionString $version" "$info_plist"
"$plist_buddy" -c "Set :NSHumanReadableCopyright © Dmitry Smirnov" "$info_plist"
"$plist_buddy" -c "Add :CFBundleIconFile string Sarcophagus.icns" "$info_plist" 2>/dev/null || \
    "$plist_buddy" -c "Set :CFBundleIconFile Sarcophagus.icns" "$info_plist"
"$plist_buddy" -c "Delete :CFBundleIconName" "$info_plist" 2>/dev/null || true
"$plist_buddy" -c "Delete :CFBundleDocumentTypes" "$info_plist" 2>/dev/null || true
"$plist_buddy" -c "Delete :UTExportedTypeDeclarations" "$info_plist" 2>/dev/null || true
"$plist_buddy" -c "Add :CFBundleDisplayName string Sarcophagus" "$info_plist" 2>/dev/null || \
    "$plist_buddy" -c "Set :CFBundleDisplayName Sarcophagus" "$info_plist"
"$plist_buddy" -c "Add :CFBundleVersion string $version" "$info_plist" 2>/dev/null || \
    "$plist_buddy" -c "Set :CFBundleVersion $version" "$info_plist"
"$plist_buddy" -c "Add :NSMicrophoneUsageDescription string Audio input is available to the LÖVE runtime." "$info_plist" 2>/dev/null || \
    "$plist_buddy" -c "Set :NSMicrophoneUsageDescription Audio input is available to the LÖVE runtime." "$info_plist"
plutil -lint "$info_plist" >/dev/null

sign_code() {
    local target="$1"
    if [[ "$signing_identity" == "-" ]]; then
        codesign --force --options runtime --sign - "$target"
    else
        codesign --force --options runtime --timestamp --sign "$signing_identity" "$target"
    fi
}

while IFS= read -r framework; do
    sign_code "$framework"
done < <(find "$application/Contents/Frameworks" -type d -name '*.framework' -prune | LC_ALL=C sort)

if [[ "$signing_identity" == "-" ]]; then
    codesign --force --options runtime --entitlements "$entitlements" --sign - "$application"
else
    codesign --force --options runtime --timestamp \
        --entitlements "$entitlements" \
        --sign "$signing_identity" \
        "$application"
fi

codesign --verify --deep --strict --verbose=2 "$application"
embedded_entitlements="$(codesign -d --entitlements - "$application" 2>/dev/null)"
for entitlement in \
    com.apple.security.cs.allow-jit \
    com.apple.security.cs.allow-unsigned-executable-memory \
    com.apple.security.cs.disable-library-validation; do
    if [[ "$embedded_entitlements" != *"$entitlement"* ]]; then
        echo "Signed app is missing entitlement: $entitlement" >&2
        exit 1
    fi
done

ditto -c -k --sequesterRsrc --keepParent "$application" "$package"

if [[ -n "$notary_profile" ]]; then
    xcrun notarytool submit "$package" --keychain-profile "$notary_profile" --wait
    xcrun stapler staple "$application"
    xcrun stapler validate "$application"
    rm -f "$package"
    ditto -c -k --sequesterRsrc --keepParent "$application" "$package"
    spctl --assess --type execute --verbose=4 "$application"
    echo "Built Developer ID-signed and notarized package: $package"
elif [[ "$signing_identity" == "-" ]]; then
    echo "Built ad-hoc signed package for local testing: $package"
    echo "Gatekeeper warnings for downloaded copies require Developer ID signing and notarization." >&2
else
    echo "Built Developer ID-signed package without notarization: $package"
    echo "Set MACOS_NOTARY_PROFILE to produce a Gatekeeper-ready public download." >&2
fi

verification_directory="$build_directory/verification"
mkdir -p "$verification_directory"
ditto -x -k "$package" "$verification_directory"
codesign --verify --deep --strict "$verification_directory/Sarcophagus.app"
cmp -s \
    "$love_archive" \
    "$verification_directory/Sarcophagus.app/Contents/Resources/Sarcophagus.love"
cmp -s \
    "$icon_source" \
    "$verification_directory/Sarcophagus.app/Contents/Resources/Sarcophagus.icns"
verified_icon="$($plist_buddy -c 'Print :CFBundleIconFile' "$verification_directory/Sarcophagus.app/Contents/Info.plist")"
if [[ "$verified_icon" != "Sarcophagus.icns" ]]; then
    echo "Packaged macOS app references an unexpected icon: $verified_icon" >&2
    exit 1
fi
if "$plist_buddy" -c 'Print :CFBundleIconName' \
    "$verification_directory/Sarcophagus.app/Contents/Info.plist" >/dev/null 2>&1; then
    echo "Packaged macOS app still contains the inherited LÖVE icon name." >&2
    exit 1
fi
for inherited_icon in "GameIcon.icns" "OS X AppIcon.icns"; do
    if [[ -e "$verification_directory/Sarcophagus.app/Contents/Resources/$inherited_icon" ]]; then
        echo "Packaged macOS app still contains the inherited LÖVE icon: $inherited_icon" >&2
        exit 1
    fi
done
find "$verification_directory" -mindepth 1 -delete
rmdir "$verification_directory"

shasum -a 256 "$package"
