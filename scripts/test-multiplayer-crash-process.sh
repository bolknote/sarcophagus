#!/usr/bin/env bash

set -euo pipefail

export SARCOPHAGUS_TEST_BACKGROUND="${SARCOPHAGUS_TEST_BACKGROUND:-1}"

script_directory="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
project_root="$(cd "$script_directory/.." && pwd)"
love_binary="${LOVE_BIN:-$project_root/.tools/love-11.5/runtime/love.app/Contents/MacOS/love}"
love_test="$script_directory/run-love-test.sh"
test_directory="$(mktemp -d "${TMPDIR:-/tmp}/sarcophagus-crash-matrix.XXXXXX")"
host_pid=""
client_pid=""

cleanup() {
    for process_id in "$host_pid" "$client_pid"; do
        if [[ -n "$process_id" ]] && kill -0 "$process_id" 2>/dev/null; then
            kill "$process_id" 2>/dev/null || true
            wait "$process_id" 2>/dev/null || true
        fi
    done
    rm -r "$test_directory"
}
trap cleanup EXIT INT TERM

run_case() {
    local crash_role="$1"
    local crash_phase="$2"
    local case_name="${crash_role}-${crash_phase}"
    local host_log="$test_directory/${case_name}-host.log"
    local client_log="$test_directory/${case_name}-client.log"
    local trigger="$test_directory/${case_name}.trigger"
    local test_port
    test_port="$(python3 -c 'import socket; s=socket.socket(); s.bind(("127.0.0.1", 0)); print(s.getsockname()[1]); s.close()')"
    : > "$host_log"
    : > "$client_log"

    SARCOPHAGUS_BUILD_MODE=development \
    SARCOPHAGUS_PROCESS_CRASH_ROLE="$crash_role" \
    SARCOPHAGUS_PROCESS_CRASH_PHASE="$crash_phase" \
    SARCOPHAGUS_PROCESS_CRASH_TRIGGER="$trigger" \
    SARCOPHAGUS_SMOKE_TEST="network-process-host:$test_port" \
    SARCOPHAGUS_TEST_LOG="$host_log" \
        "$love_test" "$love_binary" "$project_root" &
    host_pid=$!

    local host_ready=false
    for _ in $(seq 1 240); do
        if grep -Fq "SARCOPHAGUS_PROCESS_HOST_READY" "$host_log"; then
            host_ready=true
            break
        fi
        if ! kill -0 "$host_pid" 2>/dev/null; then break; fi
        sleep 0.05
    done
    if [[ "$host_ready" != true ]]; then
        cat "$host_log"
        echo "Crash-matrix host did not become ready: $case_name" >&2
        return 1
    fi

    SARCOPHAGUS_BUILD_MODE=development \
    SARCOPHAGUS_PROCESS_CRASH_ROLE="$crash_role" \
    SARCOPHAGUS_PROCESS_CRASH_PHASE="$crash_phase" \
    SARCOPHAGUS_PROCESS_CRASH_TRIGGER="$trigger" \
    SARCOPHAGUS_SMOKE_TEST="network-process-client:$test_port" \
    SARCOPHAGUS_TEST_LOG="$client_log" \
        "$love_test" "$love_binary" "$project_root" &
    client_pid=$!

    local target_log="$host_log"
    local survivor_log="$client_log"
    local survivor_role="client"
    if [[ "$crash_role" == "client" ]]; then
        target_log="$client_log"
        survivor_log="$host_log"
        survivor_role="host"
    fi

    local crash_ready=false
    for _ in $(seq 1 300); do
        if grep -Fq "SARCOPHAGUS_PROCESS_CRASH_READY role=$crash_role phase=$crash_phase" \
            "$target_log"; then
            crash_ready=true
            break
        fi
        if ! kill -0 "$host_pid" 2>/dev/null \
            || ! kill -0 "$client_pid" 2>/dev/null; then
            break
        fi
        sleep 0.05
    done
    if [[ "$crash_ready" != true ]]; then
        cat "$host_log"
        cat "$client_log"
        echo "Crash phase was not reached: $case_name" >&2
        return 1
    fi

    touch "$trigger"
    set +e
    wait "$host_pid"
    local host_status=$?
    wait "$client_pid"
    local client_status=$?
    set -e
    host_pid=""
    client_pid=""

    local survivor_status="$client_status"
    local target_status="$host_status"
    if [[ "$crash_role" == "client" ]]; then
        survivor_status="$host_status"
        target_status="$client_status"
    fi
    if [[ "$target_status" -eq 0 || "$survivor_status" -ne 0 ]] \
        || ! grep -Fq "SARCOPHAGUS_SMOKE_OK mode=network-process-$survivor_role peer_crash=true phase=$crash_phase" \
            "$survivor_log"; then
        cat "$host_log"
        cat "$client_log"
        echo "Crash recovery failed: $case_name target=$target_status survivor=$survivor_status" >&2
        return 1
    fi
    echo "SARCOPHAGUS_CRASH_CASE_OK role=$crash_role phase=$crash_phase"
}

for crash_phase in handshake snapshot catchup playing; do
    run_case client "$crash_phase"
    run_case host "$crash_phase"
done

echo "SARCOPHAGUS_MULTIPLAYER_CRASH_MATRIX_OK cases=8"
