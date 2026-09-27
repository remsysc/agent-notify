#!/usr/bin/env bash
# agent-notify.sh — shared desktop notification helper for AI coding agents.
# Managed by agent-notify-setup. Edit via: agent-notify-setup install
set -euo pipefail

KIND="${1:-done}"
APP="${2:-AI Agent}"
BODY_ARG="${3:-}"

# Restore D-Bus/display session env when spawned with a stripped environment.
: "${XDG_RUNTIME_DIR:=/run/user/$(id -u)}"
if [[ -z "${DBUS_SESSION_BUS_ADDRESS:-}" ]] && [[ -S "$XDG_RUNTIME_DIR/bus" ]]; then
    export DBUS_SESSION_BUS_ADDRESS="unix:path=$XDG_RUNTIME_DIR/bus"
fi
: "${WAYLAND_DISPLAY:=wayland-1}"; export WAYLAND_DISPLAY
: "${DISPLAY:=:0}";                export DISPLAY

# Auto-detect icon: prefer a hicolor theme entry named after the app.
_default_icon() {
    local name="${1,,}"
    if [[ -f "$HOME/.local/share/icons/hicolor/scalable/apps/${name}.svg" ]] || \
       [[ -n "$(find /usr/share/icons/hicolor "$HOME/.local/share/icons/hicolor" \
               -name "${name}.*" 2>/dev/null | head -1)" ]]; then
        printf '%s' "$name"
    else
        printf 'dialog-information'
    fi
}
ICON="${AGENT_NOTIFY_ICON:-$(_default_icon "$APP")}"

EVENT=""
if [[ ! -t 0 ]]; then EVENT="$(cat || true)"; fi

json_str() {
    local key="$1"
    { printf '%s' "$EVENT" \
        | grep -oE "\"$key\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" \
        | head -n1 \
        | sed -E "s/.*:[[:space:]]*\"([^\"]*)\"/\1/"; } || true
}

SOUND_DIR="/usr/share/sounds/freedesktop/stereo"
play_sound() {
    local file="$SOUND_DIR/$1"; [[ -r "$file" ]] || return 0
    if   command -v paplay            >/dev/null 2>&1; then paplay            "$file" >/dev/null 2>&1 &
    elif command -v canberra-gtk-play >/dev/null 2>&1; then canberra-gtk-play -f "$file" >/dev/null 2>&1 &
    fi
    disown 2>/dev/null || true
}

case "$KIND" in
    done)
        URGENCY="normal"
        TITLE="$APP — task complete"
        BODY="${BODY_ARG:-Finished responding. Ready for your next instruction.}"
        play_sound "complete.oga"
        ;;
    permission)
        URGENCY="critical"
        TITLE="$APP — needs your approval"
        if [[ -n "$BODY_ARG" ]]; then
            BODY="$BODY_ARG"
        else
            TOOL="$(json_str tool_name)"
            BODY="Waiting for approval to use: ${TOOL:-a tool}"
        fi
        play_sound "window-attention.oga"
        ;;
    *)
        URGENCY="normal"
        TITLE="$APP"
        BODY="${BODY_ARG:-$KIND}"
        ;;
esac

notify-send -a "$APP" -u "$URGENCY" -i "$ICON" "$TITLE" "$BODY" || true
exit 0
