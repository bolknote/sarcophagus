#!/usr/bin/env bash

set -euo pipefail

export SARCOPHAGUS_TEST_BACKGROUND="${SARCOPHAGUS_TEST_BACKGROUND:-1}"

script_directory="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
project_root="$(cd "$script_directory/.." && pwd)"
love_binary="${LOVE_BIN:-$project_root/.tools/love-11.5/runtime/love.app/Contents/MacOS/love}"
love_test="$script_directory/run-love-test.sh"

if [[ ! -x "$love_binary" ]]; then
    echo "LÖVE 11.5 executable not found: $love_binary" >&2
    exit 1
fi

test_directory="$(mktemp -d "${TMPDIR:-/tmp}/sarcophagus-multiplayer.XXXXXX")"
host_log="$test_directory/host.log"
client_log="$test_directory/client.log"
host_pid=""
: > "$host_log"
: > "$client_log"

cleanup() {
    if [[ -n "$host_pid" ]] && kill -0 "$host_pid" 2>/dev/null; then
        kill "$host_pid" 2>/dev/null || true
        wait "$host_pid" 2>/dev/null || true
    fi
    rm -r "$test_directory"
}
trap cleanup EXIT INT TERM

test_port="$(python3 -c 'import socket; s=socket.socket(); s.bind(("127.0.0.1", 0)); print(s.getsockname()[1]); s.close()')"
test_specification="$test_port"
if [[ "${SARCOPHAGUS_PROCESS_DISCOVERY:-0}" == "1" || \
    "${SARCOPHAGUS_PROCESS_DISCOVERY:-0}" == "multicast" ]]; then
    discovery_port="$(python3 -c 'import socket; s=socket.socket(socket.AF_INET, socket.SOCK_DGRAM); s.bind(("127.0.0.1", 0)); print(s.getsockname()[1]); s.close()')"
    test_specification="$test_port,$discovery_port"
fi

SARCOPHAGUS_BUILD_MODE=development \
SARCOPHAGUS_SMOKE_TEST="network-process-host:$test_specification" \
SARCOPHAGUS_TEST_LOG="$host_log" \
    "$love_test" "$love_binary" "$project_root" &
host_pid=$!

host_ready=false
for _ in $(seq 1 200); do
    if grep -Fq "SARCOPHAGUS_PROCESS_HOST_READY" "$host_log"; then
        host_ready=true
        break
    fi
    if ! kill -0 "$host_pid" 2>/dev/null; then
        break
    fi
    sleep 0.05
done

if [[ "$host_ready" != true ]]; then
    cat "$host_log"
    echo "Multiplayer process host did not become ready." >&2
    exit 1
fi

set +e
SARCOPHAGUS_BUILD_MODE=development \
SARCOPHAGUS_SMOKE_TEST="network-process-client:$test_specification" \
SARCOPHAGUS_TEST_LOG="$client_log" \
    "$love_test" "$love_binary" "$project_root"
client_status=$?
wait "$host_pid"
host_status=$?
set -e
host_pid=""

cat "$host_log"
cat "$client_log"

if [[ $host_status -ne 0 || $client_status -ne 0 ]]; then
    echo "Two-process multiplayer smoke test failed." >&2
    exit 1
fi
if ! grep -Fq "SARCOPHAGUS_SMOKE_OK mode=network-process-host" "$host_log"; then
    echo "Multiplayer host success marker is missing." >&2
    exit 1
fi
if ! grep -Fq "SARCOPHAGUS_SMOKE_OK mode=network-process-client" "$client_log"; then
    echo "Multiplayer client success marker is missing." >&2
    exit 1
fi

echo "SARCOPHAGUS_MULTIPLAYER_PROCESS_OK port=$test_port"
