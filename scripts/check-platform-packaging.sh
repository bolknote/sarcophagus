#!/usr/bin/env bash

set -euo pipefail

script_directory="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
project_root="$(cd "$script_directory/.." && pwd)"
windows_manifest="$project_root/packaging/windows/Sarcophagus.exe.manifest"
macos_entitlements="$project_root/packaging/macos/entitlements.plist"
windows_builder="$script_directory/build-windows.ps1"
macos_builder="$script_directory/build-macos.sh"
linux_builder="$script_directory/build-linux-appimage.sh"
linux_apprun="$project_root/packaging/linux/AppRun"
linux_desktop="$project_root/packaging/linux/ru.spectator.sarcophagus.desktop"
linux_workflow="$project_root/.github/workflows/linux-appimage.yml"
shared_icon="$project_root/packaging/icon.png"
macos_icon="$project_root/packaging/macos/Sarcophagus.icns"
windows_icon="$project_root/packaging/windows/Sarcophagus.ico"
icon_generator="$script_directory/generate-platform-icons.sh"

for required_file in \
    "$windows_manifest" \
    "$macos_entitlements" \
    "$windows_builder" \
    "$macos_builder" \
    "$linux_builder" \
    "$linux_apprun" \
    "$linux_desktop" \
    "$linux_workflow" \
    "$shared_icon" \
    "$macos_icon" \
    "$windows_icon" \
    "$icon_generator"; do
    if [[ ! -f "$required_file" ]]; then
        echo "Platform packaging file is missing: $required_file" >&2
        exit 1
    fi
done

bash -n "$macos_builder"
bash -n "$linux_builder"
bash -n "$icon_generator"
sh -n "$linux_apprun"

for executable_file in \
    "$macos_builder" \
    "$linux_builder" \
    "$linux_apprun" \
    "$icon_generator"; do
    if [[ ! -x "$executable_file" ]]; then
        echo "Platform packaging file is not executable: $executable_file" >&2
        exit 1
    fi
done

if command -v xmllint >/dev/null 2>&1; then
    xmllint --noout "$windows_manifest" "$macos_entitlements"
fi
if command -v plutil >/dev/null 2>&1; then
    plutil -lint "$macos_entitlements" >/dev/null
fi
if command -v pwsh >/dev/null 2>&1; then
    SARCOPHAGUS_POWERSHELL_FILE="$windows_builder" pwsh -NoLogo -NoProfile -Command '
        $ErrorActionPreference = "Stop"
        $tokens = $null
        $errors = $null
        [System.Management.Automation.Language.Parser]::ParseFile(
            $env:SARCOPHAGUS_POWERSHELL_FILE, [ref]$tokens, [ref]$errors) | Out-Null
        if ($errors.Count -ne 0) {
            $errors | ForEach-Object { [Console]::Error.WriteLine($_) }
            exit 1
        }
        $content = Get-Content -LiteralPath $env:SARCOPHAGUS_POWERSHELL_FILE -Raw
        $match = [regex]::Match(
            $content,
            "(?s)\$nativeManifestSource = @\x27\r?\n(?<source>.*?)\r?\n\x27@")
        if (-not $match.Success) {
            throw "Embedded Windows resource source was not found."
        }
        Add-Type -TypeDefinition $match.Groups["source"].Value -Language CSharp
    '
fi

for expected in \
    '<dpiAware xmlns="http://schemas.microsoft.com/SMI/2005/WindowsSettings">true</dpiAware>' \
    '<dpiAwareness xmlns="http://schemas.microsoft.com/SMI/2016/WindowsSettings">system</dpiAwareness>'; do
    if ! grep -Fq "$expected" "$windows_manifest"; then
        echo "Windows manifest is missing: $expected" >&2
        exit 1
    fi
done

for entitlement in \
    com.apple.security.cs.allow-jit \
    com.apple.security.cs.allow-unsigned-executable-memory \
    com.apple.security.cs.disable-library-validation; do
    if ! grep -Fq "<key>$entitlement</key>" "$macos_entitlements"; then
        echo "macOS entitlements are missing: $entitlement" >&2
        exit 1
    fi
done

for desktop_entry in \
    'Type=Application' \
    'Name=Sarcophagus' \
    'Exec=Sarcophagus' \
    'Icon=ru.spectator.sarcophagus' \
    'Terminal=false' \
    'Categories=Game;AdventureGame;'; do
    if ! grep -Fxq "$desktop_entry" "$linux_desktop"; then
        echo "Linux desktop entry is missing: $desktop_entry" >&2
        exit 1
    fi
done

for linux_runtime_pin in \
    '65a673406431eff7167a15a032bf7a2e4ba50108e091eb7b176465831f9b5e00' \
    'a6d71e2b6cd66f8e8d16c37ad164658985e0cf5fcaa950c90a482890cb9d13e0' \
    '1cc49bcf1e2ccd593c379adb17c9f85a36d619088296504de95b1d06215aebbf' \
    '--runtime-file' \
    'scripts/build-linux-appimage.sh'; do
    if ! grep -Fq -- "$linux_runtime_pin" "$linux_builder" "$linux_workflow"; then
        echo "Linux packaging is missing its pinned input: $linux_runtime_pin" >&2
        exit 1
    fi
done

if ! grep -Fq 'bin/Sarcophagus' "$linux_apprun"; then
    echo "Linux AppRun does not launch the fused Sarcophagus executable." >&2
    exit 1
fi
if ! grep -Fq 'share/luajit-2.1/?.lua' "$linux_apprun" || \
    ! grep -Fq 'LUA_PATH=";"' "$linux_apprun"; then
    echo "Linux AppRun does not preserve the official LuaJIT module search path." >&2
    exit 1
fi
if grep -Eq 'uses:[[:space:]]+[^@[:space:]]+@v[0-9]+' "$linux_workflow"; then
    echo "Linux workflow actions must be pinned to immutable commit hashes." >&2
    exit 1
fi

icon_header() {
    od -An -tx1 -N4 "$1" | tr -d '[:space:]'
}
if [[ "$(icon_header "$shared_icon")" != "89504e47" ]]; then
    echo "Shared application icon is not a PNG: $shared_icon" >&2
    exit 1
fi
if [[ "$(icon_header "$macos_icon")" != "69636e73" ]]; then
    echo "macOS application icon is not an ICNS file: $macos_icon" >&2
    exit 1
fi
if [[ "$(icon_header "$windows_icon")" != "00000100" ]]; then
    echo "Windows application icon is not an ICO file: $windows_icon" >&2
    exit 1
fi

for macos_icon_marker in \
    'packaging/macos/Sarcophagus.icns' \
    'CFBundleIconFile' \
    'Delete :CFBundleIconName' \
    'OS X AppIcon.icns' \
    'Contents/Resources/Sarcophagus.icns'; do
    if ! grep -Fq "$macos_icon_marker" "$macos_builder"; then
        echo "macOS builder is missing icon integration: $macos_icon_marker" >&2
        exit 1
    fi
done
for macos_archive_marker in \
    'love_archive_override="${LOVE_ARCHIVE:-}"' \
    'if [[ -z "$love_archive_override" ]]' \
    '"$script_directory/build-love.sh"'; do
    if ! grep -Fq "$macos_archive_marker" "$macos_builder"; then
        echo "macOS builder can reuse a stale default archive: $macos_archive_marker" >&2
        exit 1
    fi
done
for macos_zip_marker in \
    'create_package' \
    '/usr/bin/zip -9 -q -r -y -X' \
    'Packaged macOS ZIP contains AppleDouble metadata'; do
    if ! grep -Fq "$macos_zip_marker" "$macos_builder"; then
        echo "macOS builder does not reject metadata junk: $macos_zip_marker" >&2
        exit 1
    fi
done
for windows_icon_marker in \
    'packaging/windows/Sarcophagus.ico' \
    'ReplaceIcon' \
    'IconMatches'; do
    if ! grep -Fq "$windows_icon_marker" "$windows_builder"; then
        echo "Windows builder is missing icon integration: $windows_icon_marker" >&2
        exit 1
    fi
done

echo "Platform packaging definitions are valid."
