#!/usr/bin/env bash

set -euo pipefail

export SARCOPHAGUS_TEST_BACKGROUND="${SARCOPHAGUS_TEST_BACKGROUND:-1}"

script_directory="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
project_root="$(cd "$script_directory/.." && pwd)"
love_binary="${LOVE_BIN:-$project_root/.tools/love-11.5/runtime/love.app/Contents/MacOS/love}"

if [[ ! -x "$love_binary" ]]; then
    echo "LÖVE 11.5 executable not found: $love_binary" >&2
    echo "Set LOVE_BIN to an executable LÖVE 11.5 binary." >&2
    exit 1
fi

SARCOPHAGUS_BUILD_MODE=development \
SARCOPHAGUS_LANGUAGE=en \
SARCOPHAGUS_SMOKE_TEST=ui-strings \
    "$love_binary" "$project_root"
