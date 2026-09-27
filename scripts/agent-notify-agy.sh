#!/usr/bin/env bash
# agent-notify-agy.sh — Antigravity (agy) hook wrapper.
# Managed by agent-notify-setup.
# agy hooks: read JSON from stdin, MUST print JSON on stdout, exit 0.
set -euo pipefail

NOTIFY="/home/rem/.local/share/agent-notify/agent-notify.sh"
KIND="${1:-stop}"
APP="Antigravity"

: "${XDG_RUNTIME_DIR:=/run/user/$(id -u)}"
if [[ -z "${DBUS_SESSION_BUS_ADDRESS:-}" ]] && [[ -S "$XDG_RUNTIME_DIR/bus" ]]; then
    export DBUS_SESSION_BUS_ADDRESS="unix:path=$XDG_RUNTIME_DIR/bus"
fi
: "${WAYLAND_DISPLAY:=wayland-1}"; export WAYLAND_DISPLAY
: "${DISPLAY:=:0}";                export DISPLAY

PAYLOAD=""
if [[ ! -t 0 ]]; then PAYLOAD="$(cat || true)"; fi

json_str() {
    local key="$1"
    { printf '%s' "$PAYLOAD"         | grep -oE "\"$key\"[[:space:]]*:[[:space:]]*\"[^\"]*\""         | head -n1         | sed -E "s/.*:[[:space:]]*\"([^\"]*)\"/\1/"; } || true
}

AGY_ICON="$HOME/.gemini/config/logo.png"
[[ -r "$AGY_ICON" ]] && export AGENT_NOTIFY_ICON="$AGY_ICON"

case "$KIND" in
    stop)
        printf '%s' "$PAYLOAD" | "$NOTIFY" done "$APP" || true
        printf '{}\n'
        ;;
    pretool)
        CMD="$(json_str CommandLine)"
        BODY="About to run: ${CMD:-a command}"
        printf '%s' "$PAYLOAD" | "$NOTIFY" permission "$APP" "$BODY" || true
        printf '{"decision":"ask"}\n'
        ;;
    *)
        printf '{}\n'
        ;;
esac
exit 0
