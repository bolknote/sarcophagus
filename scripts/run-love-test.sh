#!/usr/bin/env bash

set -euo pipefail

if [[ $# -lt 2 ]]; then
    echo "Usage: $0 LOVE_EXECUTABLE GAME_PATH [ARGUMENT ...]" >&2
    exit 2
fi

love_binary="$1"
shift
game_path="$1"
shift

if [[ "$love_binary" != /* ]]; then
    love_binary="$(cd "$(dirname "$love_binary")" && pwd)/$(basename "$love_binary")"
fi
if [[ ! -x "$love_binary" ]]; then
    echo "LÖVE executable not found: $love_binary" >&2
    exit 2
fi
if [[ "$game_path" != /* ]]; then
    game_path="$(cd "$(dirname "$game_path")" && pwd)/$(basename "$game_path")"
fi
if [[ ! -e "$game_path" ]]; then
    echo "LÖVE game path not found: $game_path" >&2
    exit 2
fi
if [[ -z "${SARCOPHAGUS_SMOKE_TEST:-}" ]]; then
    echo "SARCOPHAGUS_SMOKE_TEST must be set for the test launcher." >&2
    exit 2
fi

export SARCOPHAGUS_TEST_BACKGROUND="${SARCOPHAGUS_TEST_BACKGROUND:-1}"

external_log="${SARCOPHAGUS_TEST_LOG:-}"
temporary_directory=""
if [[ -n "$external_log" ]]; then
    stdout_log="$external_log"
    stderr_log="$external_log.stderr"
    : > "$stdout_log"
    : > "$stderr_log"
else
    temporary_directory="$(mktemp -d "${TMPDIR:-/tmp}/sarcophagus-love-test.XXXXXX")"
    stdout_log="$temporary_directory/stdout.log"
    stderr_log="$temporary_directory/stderr.log"
    : > "$stdout_log"
    : > "$stderr_log"
fi

cleanup() {
    if [[ -n "$temporary_directory" ]]; then
        rm -r "$temporary_directory"
    else
        rm -f "$stderr_log"
    fi
}
trap cleanup EXIT

use_hidden_open=false
love_app=""
background_safe=false
case "$SARCOPHAGUS_SMOKE_TEST" in
    actors | network | network-process-*)
        background_safe=true
        ;;
esac
if [[ "$(uname -s)" == "Darwin"
    && "$SARCOPHAGUS_TEST_BACKGROUND" == "1"
    && "$background_safe" == true
    && "${SARCOPHAGUS_TEST_HIDDEN:-1}" != "0"
    && "$love_binary" == */Contents/MacOS/* ]]; then
    love_app="${love_binary%/Contents/MacOS/*}"
    open_help="$(/usr/bin/open -h 2>&1 || true)"
    if [[ -d "$love_app"
        && "$open_help" == *"--hide"*
        && "$open_help" == *"--stdout"*
        && "$open_help" == *"--env"* ]]; then
        use_hidden_open=true
    fi
fi

run_status=0
if [[ "$use_hidden_open" == true ]]; then
    open_environment=()
    while IFS='=' read -r variable value; do
        case "$variable" in
            SARCOPHAGUS_TEST_LOG | SARCOPHAGUS_TEST_HIDDEN)
                ;;
            SARCOPHAGUS_*)
                open_environment+=(--env "$variable=$value")
                ;;
        esac
    done < <(env)
    open_environment+=(--env "SARCOPHAGUS_TEST_NO_MINIMIZE=1")

    /usr/bin/open -j -g -W -n -a "$love_app" \
        --stdout "$stdout_log" \
        --stderr "$stderr_log" \
        "${open_environment[@]}" \
        --args "$game_path" "$@" || run_status=$?
else
    if [[ "$(uname -s)" == "Darwin" && "$background_safe" != true ]]; then
        # Graphics-heavy tests need a live Metal surface. Running them hidden or
        # minimized makes fullscreen transitions invalidate LÖVE Canvases.
        SARCOPHAGUS_TEST_NO_MINIMIZE=1 \
            "$love_binary" "$game_path" "$@" \
            >"$stdout_log" 2>"$stderr_log" || run_status=$?
    else
        "$love_binary" "$game_path" "$@" \
            >"$stdout_log" 2>"$stderr_log" || run_status=$?
    fi
fi

if [[ -n "$external_log" ]]; then
    if [[ -s "$stderr_log" ]]; then
        cat "$stderr_log" >> "$stdout_log"
    fi
else
    cat "$stdout_log"
    if [[ -s "$stderr_log" ]]; then
        cat "$stderr_log" >&2
    fi
fi

if [[ $run_status -ne 0 ]]; then
    message="LÖVE test process exited with status $run_status."
elif grep -Fq "SARCOPHAGUS_SMOKE_FAIL " "$stdout_log" \
    || grep -Fq "SARCOPHAGUS_SMOKE_FAIL " "$stderr_log"; then
    message="LÖVE smoke test reported failure."
elif ! grep -Fq "SARCOPHAGUS_SMOKE_OK " "$stdout_log" \
    && ! grep -Fq "SARCOPHAGUS_SMOKE_OK " "$stderr_log"; then
    message="LÖVE smoke test ended without a success marker."
else
    exit 0
fi

if [[ -n "$external_log" ]]; then
    echo "$message" >> "$stdout_log"
else
    echo "$message" >&2
fi
exit 1
