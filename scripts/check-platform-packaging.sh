#!/usr/bin/env bash

set -euo pipefail

script_directory="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
project_root="$(cd "$script_directory/.." && pwd)"
windows_manifest="$project_root/packaging/windows/Sarcophagus.exe.manifest"
macos_entitlements="$project_root/packaging/macos/entitlements.plist"
windows_builder="$script_directory/build-windows.ps1"
macos_builder="$script_directory/build-macos.sh"

for required_file in \
    "$windows_manifest" \
    "$macos_entitlements" \
    "$windows_builder" \
    "$macos_builder"; do
    if [[ ! -f "$required_file" ]]; then
        echo "Platform packaging file is missing: $required_file" >&2
        exit 1
    fi
done

bash -n "$macos_builder"

if command -v xmllint >/dev/null 2>&1; then
    xmllint --noout "$windows_manifest" "$macos_entitlements"
fi
if command -v plutil >/dev/null 2>&1; then
    plutil -lint "$macos_entitlements" >/dev/null
fi
if command -v pwsh >/dev/null 2>&1; then
    SARCOPHAGUS_POWERSHELL_FILE="$windows_builder" pwsh -NoLogo -NoProfile -Command '
        $tokens = $null
        $errors = $null
        [System.Management.Automation.Language.Parser]::ParseFile(
            $env:SARCOPHAGUS_POWERSHELL_FILE, [ref]$tokens, [ref]$errors) | Out-Null
        if ($errors.Count -ne 0) {
            $errors | ForEach-Object { [Console]::Error.WriteLine($_) }
            exit 1
        }
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

echo "Platform packaging definitions are valid."
