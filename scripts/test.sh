#!/usr/bin/env bash

set -euo pipefail

export SARCOPHAGUS_TEST_BACKGROUND="${SARCOPHAGUS_TEST_BACKGROUND:-1}"

script_directory="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
project_root="$(cd "$script_directory/.." && pwd)"
love_binary="${LOVE_BIN:-$project_root/.tools/love-11.5/runtime/love.app/Contents/MacOS/love}"
love_test="$script_directory/run-love-test.sh"

if [[ ! -x "$love_binary" ]]; then
    echo "LÖVE 11.5 executable not found: $love_binary" >&2
    echo "Set LOVE_BIN to an executable LÖVE 11.5 binary." >&2
    exit 1
fi

if command -v luac >/dev/null 2>&1; then
    while IFS= read -r -d '' lua_file; do
        luac -p "$lua_file"
    done < <(find "$project_root" -type f -name '*.lua' \
        -not -path "$project_root/.git/*" \
        -not -path "$project_root/.tools/*" \
        -not -path "$project_root/build/*" \
        -not -path "$project_root/dist/*" \
        -print0)
fi

LOVE_BIN="$love_binary" "$script_directory/check-locales.sh"
LOVE_BIN="$love_binary" "$script_directory/check-ui-strings.sh"
bash "$script_directory/check-release-manifest.sh"
"$script_directory/check-platform-packaging.sh"

SARCOPHAGUS_BUILD_MODE=development \
SARCOPHAGUS_SMOKE_TEST=actors \
    "$love_test" "$love_binary" "$project_root"

SARCOPHAGUS_BUILD_MODE=development \
SARCOPHAGUS_SMOKE_TEST=network \
    "$love_test" "$love_binary" "$project_root"

SARCOPHAGUS_PROCESS_DISCOVERY=multicast \
LOVE_BIN="$love_binary" "$script_directory/test-multiplayer-process.sh"

SARCOPHAGUS_PROCESS_DISCOVERY=broadcast \
LOVE_BIN="$love_binary" "$script_directory/test-multiplayer-process.sh"

SARCOPHAGUS_NET_LATENCY_MS=25 \
SARCOPHAGUS_NET_JITTER_MS=15 \
SARCOPHAGUS_NET_LOSS_PERCENT=20 \
SARCOPHAGUS_NET_DUPLICATION_PERCENT=15 \
LOVE_BIN="$love_binary" "$script_directory/test-multiplayer-process.sh"

SARCOPHAGUS_NET_LATENCY_MS=25 \
SARCOPHAGUS_NET_JITTER_MS=15 \
SARCOPHAGUS_NET_LOSS_PERCENT=20 \
SARCOPHAGUS_NET_DUPLICATION_PERCENT=15 \
SARCOPHAGUS_NET_DISCONNECT_AFTER=0.35 \
SARCOPHAGUS_PROCESS_RECONNECT_BACKLOG=64 \
LOVE_BIN="$love_binary" "$script_directory/test-multiplayer-process.sh"

LOVE_BIN="$love_binary" "$script_directory/test-multiplayer-crash-process.sh"

SARCOPHAGUS_PROCESS_MODE=multiplayer-gameplay \
LOVE_BIN="$love_binary" "$script_directory/test-multiplayer-process.sh"

SARCOPHAGUS_PROCESS_MODE=multiplayer-gameplay \
SARCOPHAGUS_NET_LATENCY_MS=25 \
SARCOPHAGUS_NET_JITTER_MS=15 \
SARCOPHAGUS_NET_LOSS_PERCENT=10 \
SARCOPHAGUS_NET_DUPLICATION_PERCENT=10 \
SARCOPHAGUS_NET_DISCONNECT_AFTER=0.75 \
LOVE_BIN="$love_binary" "$script_directory/test-multiplayer-process.sh"

SARCOPHAGUS_BUILD_MODE=development \
SARCOPHAGUS_SMOKE_TEST=multiplayer-gameplay \
    "$love_test" "$love_binary" "$project_root"

SARCOPHAGUS_BUILD_MODE=development \
SARCOPHAGUS_SMOKE_TEST=multiplayer-benchmark \
	"$love_test" "$love_binary" "$project_root"

SARCOPHAGUS_BUILD_MODE=development \
SARCOPHAGUS_SMOKE_TEST=display \
    "$love_test" "$love_binary" "$project_root"

SARCOPHAGUS_BUILD_MODE=development \
SARCOPHAGUS_SMOKE_TEST=display-modes \
    "$love_test" "$love_binary" "$project_root"

/usr/bin/env -u SARCOPHAGUS_LANGUAGE \
    SARCOPHAGUS_BUILD_MODE=development \
    SARCOPHAGUS_SMOKE_TEST=settings \
    "$love_test" "$love_binary" "$project_root"

for language in en ru; do
    SARCOPHAGUS_BUILD_MODE=development \
    SARCOPHAGUS_LANGUAGE="$language" \
    SARCOPHAGUS_SMOKE_TEST=load:9 \
        "$love_test" "$love_binary" "$project_root"
done

SARCOPHAGUS_BUILD_MODE=development \
SARCOPHAGUS_LANGUAGE=ru \
SARCOPHAGUS_SMOKE_TEST=persistence \
    "$love_test" "$love_binary" "$project_root"

SARCOPHAGUS_BUILD_MODE=development \
SARCOPHAGUS_LANGUAGE=ru \
SARCOPHAGUS_SMOKE_TEST=autosave \
    "$love_test" "$love_binary" "$project_root"

SARCOPHAGUS_BUILD_MODE=development \
SARCOPHAGUS_LANGUAGE=ru \
SARCOPHAGUS_SMOKE_TEST=mapgen \
    "$love_test" "$love_binary" "$project_root"
