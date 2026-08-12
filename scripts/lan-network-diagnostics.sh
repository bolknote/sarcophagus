#!/usr/bin/env bash

set -u

peer_address="${1:-}"

section() {
    printf '\n[%s]\n' "$1"
}

run_if_available() {
    local command_name="$1"
    shift
    if command -v "$command_name" >/dev/null 2>&1; then
        "$command_name" "$@" 2>&1 || true
    else
        printf '%s is not installed\n' "$command_name"
    fi
}

section "Sarcophagus LAN diagnostics"
printf 'Captured: %s\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
printf 'Discovery: IPv4 UDP 239.255.77.77:22121 and 255.255.255.255:22121\n'
printf 'Gameplay: ENet/UDP, default port range 22122-22132\n'
run_if_available uname -a

platform="$(uname -s 2>/dev/null || true)"
if [[ "$platform" == "Darwin" ]]; then
    section "macOS"
    run_if_available sw_vers

    section "Hardware ports"
    run_if_available networksetup -listallhardwareports

    section "Active IPv4 interfaces and routes"
    run_if_available scutil --nwi
    run_if_available route -n get default
    run_if_available netstat -rn -f inet
    run_if_available ifconfig -a

    section "VPN services"
    run_if_available scutil --nc list

    section "Application firewall"
    firewall_tool="/usr/libexec/ApplicationFirewall/socketfilterfw"
    if [[ -x "$firewall_tool" ]]; then
        "$firewall_tool" --getglobalstate 2>&1 || true
        "$firewall_tool" --getblockall 2>&1 || true
        "$firewall_tool" --getstealthmode 2>&1 || true
    else
        printf 'macOS application firewall tool is unavailable\n'
    fi

    section "Sarcophagus UDP listeners"
    run_if_available lsof -nP -iUDP:22121
    run_if_available lsof -nP -iUDP:22122-22132
else
    section "IPv4 interfaces and routes"
    run_if_available ip -brief -4 address
    run_if_available ip -4 route

    section "Sarcophagus UDP listeners"
    run_if_available ss -lunp
fi

if [[ -n "$peer_address" ]]; then
    section "Peer reachability"
    printf 'Peer: %s\n' "$peer_address"
    if [[ "$platform" == "Darwin" ]]; then
        run_if_available dscacheutil -q host -a name "$peer_address"
    else
        run_if_available getent ahostsv4 "$peer_address"
    fi
    run_if_available ping -c 3 "$peer_address"
fi

section "Interpretation"
printf '%s\n' \
    '1. No automatic server after 6 s: check AP isolation, firewall and UDP gameplay port.' \
    '2. Compare active interfaces/routes on both machines; temporarily disable VPN only as a diagnostic.' \
    '3. This report sends no discovery probe and changes no network or firewall setting.'
