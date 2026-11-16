# LidAwake

A tiny macOS menu-bar utility. One click makes your Mac **stay awake with the lid closed** — so a download,
render, build, music, call, server or script keeps running while the laptop is shut. Click again to go back to
normal sleep.

| Icon | Meaning |
|------|---------|
| Coffee cup (☕️) | Awake: the Mac will **not** sleep when the lid is closed |
| Zzz (💤) | Sleep: normal behavior |
| Lock (🔒) | Access not granted yet (one-time setup needed) |
| Warning triangle (⚠️) | Access granted, but the sleep state cannot be read |

No Dock icon, no windows — only the menu-bar icon. Works without an external monitor. macOS 13 or later.

## Install (from source)

You need the Xcode Command Line Tools (`xcode-select --install`).

```bash
make test      # optional: run the unit tests
make install   # build, sign (ad-hoc) and copy to /Applications
open /Applications/LidAwake.app
```

## Use

- **Left click** the icon: switch between ☕️ and 💤 immediately.
- **Ctrl+click** (or right click): open the panel. The large icon at the top shows the state and switches the
  mode when you click it. Below are a reminder while awake, *Launch at login*, an *Access* row (tap it to see the
  rule in effect and *Revoke access*), and *Quit*.
- Hover over the icon for a short description of the current state.

### One-time setup

On first launch the icon is 🔒. Click it; the panel explains the one-time permission. Press **Show command** to see
exactly what will be allowed, then **Grant access** and confirm with your administrator password in the standard macOS dialog. After that, toggling never asks for a
password. **Revoke access** in the panel removes the permission again.

The permission is a sudoers rule that allows exactly two commands for your user, nothing else:

```
<you> ALL=(root) NOPASSWD: /usr/bin/pmset -a disablesleep 0, /usr/bin/pmset -a disablesleep 1
```

The scripts that install and remove it are in [`Resources/scripts/`](Resources/scripts). The rule is checked with
`visudo -cf` before it is activated. The app embeds the text of these scripts at build time and runs that text,
never a script file on disk.

## Important

- The mode **never turns off by itself.** Before you put the Mac in a bag, switch back to 💤 — otherwise it may
  overheat and drain the battery.
- After a restart the mode can still be on while LidAwake is not running, so there is no icon. Turn on
  **Launch at login** in the panel to always see the state.
- Quitting LidAwake does not change the mode; if ☕️ is on, the app asks for confirmation first.

## How it works

State comes only from the system: `pmset -g` (`SleepDisabled`) and `sudo -n -l` (is the rule in effect). The
icon is never based on what the app last clicked. Switching runs `sudo -n /usr/bin/pmset -a disablesleep 1|0`
and then re-reads the real state. Only Swift, SwiftUI/AppKit and system commands are used — no third-party code.

## Uninstall

Turn off *Launch at login* in the panel, then:

```bash
make uninstall   # removes the sudoers rule (asks for your password) and deletes the app
```

## Project docs

