# agent-notify

Desktop notifications for AI coding agents on Linux.

Get a popup when your agent finishes responding or needs your approval to run a command — works with **Kiro** (`kiro-cli`) and **Antigravity** (`agy`).

![Notifications demo](https://github.com/user-attachments/assets/placeholder)

## Features

- 🔔 **Done notification** — fires when the agent finishes a turn
- ⚠️ **Approval notification** — fires when the agent needs permission to run a command or write a file
- 🎨 **Branded icons** — Kiro gets a purple K, Antigravity uses its own logo
- 🔊 **Sound cues** — uses freedesktop sounds if available
- 🌐 **Portable** — works on any Linux desktop: X11, Wayland, any notification daemon (dunst, mako, swaync, notifd, quickshell, …)
- ⚡ **Auto-detect** — installer detects which agents are installed and configures only those
- 🔄 **Idempotent** — safe to re-run; backs up any file it modifies

## Requirements

- `bash`
- `python3`
- `notify-send` (from `libnotify`)
- Any freedesktop notification daemon
- One or more supported agents: `kiro-cli`, `agy`

## Install

```bash
# Clone the repo
git clone https://github.com/remsysc/agent-notify.git
cd agent-notify

# Run the installer
./agent-notify-setup install
```

Then **restart your agent session** for hooks to take effect.

## Usage

```
agent-notify-setup install      # detect agents and configure notifications
agent-notify-setup uninstall    # remove hooks (scripts are kept)
agent-notify-setup status       # show current installation state
agent-notify-setup test         # fire a test notification for each detected agent
```

### Status output (all good)

```
  ✓ notify-send found: /usr/bin/notify-send
  ✓ D-Bus session socket: /run/user/1000/bus

  ✓ Script: /home/user/.local/share/agent-notify/agent-notify.sh
  ✓ Script: /home/user/.local/share/agent-notify/agent-notify-agy.sh

  ✓ Kiro detected (/home/user/.local/bin/kiro-cli)
  ✓   stop hook configured
  ✓   permission hook configured
  ✓   Kiro icon installed

  ✓ Antigravity detected (/home/user/.local/bin/agy)
  ✓   hooks.json configured
```

## What gets installed

```
~/.local/share/agent-notify/
├── agent-notify.sh          # shared notification script (used by Kiro)
├── agent-notify-agy.sh      # Antigravity wrapper (stdin/stdout JSON contract)
└── kiro.svg                 # Kiro icon source

~/.local/share/icons/hicolor/scalable/apps/
└── kiro.svg                 # registered in icon theme

~/.kiro/agents/default.json  # Kiro: stop + preToolUse hooks merged in
~/.gemini/antigravity-cli/hooks.json  # Antigravity: hooks written
```

## Supported agents

| Agent | Detected by | Hook mechanism |
|-------|-------------|----------------|
| [Kiro](https://kiro.dev) | `kiro-cli` on PATH + `~/.kiro/agents/` | `hooks` in `default.json` |
| [Antigravity](https://antigravity.dev) | `agy` on PATH + `~/.gemini/antigravity-cli/` | `hooks.json` |

## Adding a new agent

1. Add a detection function `detect_<agent>()` in `agent-notify-setup`
2. Add `install_<agent>()` that writes hooks pointing to `agent-notify.sh` (or a wrapper if the agent has a special stdin/stdout contract)
3. Add `remove_<agent>()` to undo the hooks
4. Wire them into `cmd_install`, `cmd_uninstall`, `cmd_status`, and `cmd_test`

## Troubleshooting

**No notification appears**
- Run `agent-notify-setup status` — check all items are ✓
- Run `agent-notify-setup test` — if popups appear, the scripts work; the issue is hooks not firing
- In Kiro, run `/hooks` to verify hooks are loaded in the current session
- Check `notify-send` works: `notify-send "test" "hello"`

**Duplicate notifications (Antigravity)**
- You may have two `hooks.json` files active. Run `agent-notify-setup install` — it neutralizes `~/.gemini/config/hooks.json` automatically.

**Permission notification doesn't appear**
- The notification script must exit 0 and the `preToolUse` hook must not emit exit code 2 (that blocks the tool). Both are handled; see `agent-notify.sh` comments.

## License

MIT
