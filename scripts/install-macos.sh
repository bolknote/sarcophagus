#!/usr/bin/env bash

set -euo pipefail

# This installer is intentionally pinned to one immutable GitHub release.
# Update the version, URL, and SHA-256 together when publishing a new release.
readonly version="0.11.2"
readonly archive_name="Sarcophagus-macos-universal-$version.zip"
readonly archive_url="https://github.com/bolknote/sarcophagus/releases/download/v$version/$archive_name"
readonly archive_sha256="492779dd965c3b4a20f5f6f6f73b083bd98a0bb251cd3e5f157807397dfbf199"
readonly bundle_identifier="ru.spectator.sarcophagus"

install_directory="${SARCOPHAGUS_INSTALL_DIR:-$HOME/Applications}"
launch_application=1
temporary_directory=""
transaction_directory=""
destination=""
previous_application=""
previous_application_moved=0
new_application_moved=0
installation_committed=0

usage() {
    cat <<'EOF'
Install Sarcophagus for the current macOS user.

Usage:
  install-macos.sh [--install-dir DIRECTORY] [--no-launch]

Options:
  --install-dir DIRECTORY  Install into DIRECTORY (default: ~/Applications).
  --no-launch              Do not launch Sarcophagus after installation.
  -h, --help               Show this help.

No sudo access is requested and no global Gatekeeper setting is changed.
EOF
}

fail() {
    echo "Error: $*" >&2
    exit 1
}

remove_tree() {
    local target="$1"
    if [[ -e "$target" || -L "$target" ]]; then
        find "$target" -depth -delete
    fi
}

cleanup() {
    local status=$?
    local preserve_transaction=0
    trap - EXIT

    if ((status != 0 && !installation_committed)); then
        if ((new_application_moved)) && \
            [[ -n "$destination" && ( -e "$destination" || -L "$destination" ) ]]; then
            if ! remove_tree "$destination"; then
                echo "Warning: could not remove the incomplete installation: $destination" >&2
                preserve_transaction=1
            fi
        fi
        if ((previous_application_moved)) && [[ -e "$previous_application" ]]; then
            if [[ -e "$destination" || -L "$destination" ]] || \
                ! mv "$previous_application" "$destination"; then
                echo "Warning: the previous app is preserved at: $previous_application" >&2
                preserve_transaction=1
            else
                echo "The previous Sarcophagus installation was restored." >&2
            fi
        fi
    fi

    if [[ -n "$transaction_directory" && -d "$transaction_directory" ]]; then
        if ((preserve_transaction)); then
            echo "Recovery files were left at: $transaction_directory" >&2
        else
            remove_tree "$transaction_directory"
        fi
    fi
    if [[ -n "$temporary_directory" && -d "$temporary_directory" ]]; then
        remove_tree "$temporary_directory"
    fi

    exit "$status"
}
trap cleanup EXIT

while (($#)); do
    case "$1" in
        --install-dir)
            (($# >= 2)) || fail "--install-dir requires a directory."
            install_directory="$2"
            shift 2
            ;;
        --no-launch)
            launch_application=0
            shift
            ;;
        -h | --help)
            usage
            exit 0
            ;;
        *)
            fail "Unknown option: $1"
            ;;
    esac
done

[[ "$(uname -s)" == "Darwin" ]] || fail "This installer requires macOS."

for tool in codesign curl ditto find mktemp open pgrep plutil shasum sleep; do
    command -v "$tool" >/dev/null 2>&1 || fail "Required macOS tool is missing: $tool"
done

mkdir -p "$install_directory"
install_directory="$(cd "$install_directory" && pwd -P)"
[[ "$install_directory" != "/" ]] || fail "Refusing to install directly into /."

destination="$install_directory/Sarcophagus.app"
if [[ -L "$destination" ]]; then
    fail "Refusing to replace a symbolic link: $destination"
fi
if [[ -e "$destination" && ! -d "$destination" ]]; then
    fail "The installation target exists but is not an app directory: $destination"
fi
if [[ -e "$destination" ]] && \
    pgrep -f "$destination/Contents/MacOS/Sarcophagus" >/dev/null 2>&1; then
    fail "Quit the installed Sarcophagus app before updating it."
fi

temporary_root="${TMPDIR:-/tmp}"
temporary_directory="$(mktemp -d "$temporary_root/sarcophagus-download.XXXXXX")"
archive="$temporary_directory/$archive_name"
extraction_directory="$temporary_directory/extracted"
curl_error_log="$temporary_directory/curl-errors.log"

echo "Downloading Sarcophagus $version..."
download_succeeded=0
for download_attempt in 1 2 3 4 5; do
    if curl \
        --disable \
        --fail \
        --location \
        --proto '=https' \
        --proto-redir '=https' \
        --silent \
        --tlsv1.2 \
        --output "$archive" \
        "$archive_url" 2>"$curl_error_log"; then
        download_succeeded=1
        break
    fi
    if ((download_attempt < 5)); then
        echo "Download interrupted; retrying ($download_attempt/5)..." >&2
        sleep 1
    fi
done
if ((!download_succeeded)); then
    while IFS= read -r error_line; do
        echo "$error_line" >&2
    done < "$curl_error_log"
    fail "Could not download $archive_url"
fi

read -r actual_sha256 _ < <(shasum -a 256 "$archive")
if [[ "$actual_sha256" != "$archive_sha256" ]]; then
    fail "SHA-256 mismatch; the downloaded archive was not installed."
fi
echo "SHA-256 verified."

mkdir -p "$extraction_directory"
ditto -x -k "$archive" "$extraction_directory"
extracted_application="$extraction_directory/Sarcophagus.app"
[[ -d "$extracted_application" ]] || fail "The archive does not contain Sarcophagus.app."

actual_bundle_identifier="$(
    plutil -extract CFBundleIdentifier raw -o - \
        "$extracted_application/Contents/Info.plist"
)"
if [[ "$actual_bundle_identifier" != "$bundle_identifier" ]]; then
    fail "Unexpected bundle identifier: $actual_bundle_identifier"
fi

actual_version="$(
    plutil -extract CFBundleShortVersionString raw -o - \
        "$extracted_application/Contents/Info.plist"
)"
if [[ "$actual_version" != "$version" ]]; then
    fail "Unexpected app version: $actual_version"
fi

codesign --verify --deep --strict "$extracted_application"
echo "Code-signature integrity verified."

# Stage the new app on the destination volume, then replace the old copy with
# renames. If the final rename fails, the previous copy is restored.
transaction_directory="$(mktemp -d "$install_directory/.sarcophagus-install.XXXXXX")"
staged_application="$transaction_directory/Sarcophagus.app.new"
previous_application="$transaction_directory/Sarcophagus.app.previous"
ditto "$extracted_application" "$staged_application"
codesign --verify --deep --strict "$staged_application"

if [[ -d "$destination" ]]; then
    mv "$destination" "$previous_application"
    previous_application_moved=1
fi

if ! mv "$staged_application" "$destination"; then
    fail "Could not move Sarcophagus.app into $install_directory"
fi
new_application_moved=1

if ! codesign --verify --deep --strict "$destination"; then
    fail "The installed app failed its final code-signature check."
fi
installation_committed=1

echo "Installed Sarcophagus $version to: $destination"

if ((launch_application)); then
    echo "Launching Sarcophagus..."
    open "$destination"
else
    echo "Run it with: open \"$destination\""
fi
