#!/usr/bin/env bash

set -euo pipefail

script_directory="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
project_root="$(cd "$script_directory/.." && pwd)"
love_binary="${LOVE_BIN:-$project_root/.tools/love-11.5/runtime/love.app/Contents/MacOS/love}"

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

SARCOPHAGUS_BUILD_MODE=development \
SARCOPHAGUS_SMOKE_TEST=display \
    "$love_binary" "$project_root"

/usr/bin/env -u SARCOPHAGUS_LANGUAGE \
    SARCOPHAGUS_BUILD_MODE=development \
    SARCOPHAGUS_SMOKE_TEST=settings \
    "$love_binary" "$project_root"

for language in en ru; do
    SARCOPHAGUS_BUILD_MODE=development \
    SARCOPHAGUS_LANGUAGE="$language" \
    SARCOPHAGUS_SMOKE_TEST=load:9 \
        "$love_binary" "$project_root"
done

SARCOPHAGUS_BUILD_MODE=development \
SARCOPHAGUS_LANGUAGE=ru \
SARCOPHAGUS_SMOKE_TEST=persistence \
    "$love_binary" "$project_root"

SARCOPHAGUS_BUILD_MODE=development \
SARCOPHAGUS_LANGUAGE=ru \
SARCOPHAGUS_SMOKE_TEST=mapgen \
    "$love_binary" "$project_root"
