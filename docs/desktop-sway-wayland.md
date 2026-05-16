# Sway Wayland Desktop Profile

The `sway-wayland` profile installs Sway as the conservative Wayland desktop option. It is for installed Gentoo systems that already passed the basic-console workflow and are reachable over SSH.

## Scope

The profile manages:

- Sway compositor packages,
- Wayland terminal, launcher, bar, clipboard, screenshot helpers when recommends are enabled,
- optional wlroots portal packages,
- `~/.config/sway/config`,
- `~/.config/gentoo-ai-installer/sway-wayland-session.sh`.

It does not install a display manager, GPU vendor stack, audio stack, Bluetooth, printers, or base installer components.

## Install

Plan:

```sh
make desktop-plan \
  DESKTOP_PROFILE=sway-wayland \
  DESKTOP_TARGET_HOST=<host-or-ip> \
  DESKTOP_TARGET_USER=<ssh-user> \
  DESKTOP_USER=<installed-user>
```

Install:

```sh
make desktop-install \
  DESKTOP_PROFILE=sway-wayland \
  DESKTOP_TARGET_HOST=<host-or-ip> \
  DESKTOP_TARGET_USER=<ssh-user> \
  DESKTOP_USER=<installed-user>
```

Validate:

```sh
make desktop-validate \
  DESKTOP_PROFILE=sway-wayland \
  DESKTOP_TARGET_HOST=<host-or-ip> \
  DESKTOP_TARGET_USER=<ssh-user> \
  DESKTOP_USER=<installed-user>
```

## Package Policy

Core packages:

- `sys-apps/dbus`
- `gui-wm/sway`
- `gui-apps/foot`

Recommended packages:

- `gui-apps/waybar`
- `gui-apps/wofi`
- `gui-apps/wl-clipboard`
- `gui-apps/grim`
- `gui-apps/slurp`

Portal packages when `DESKTOP_ENABLE_PORTAL=yes`:

- `sys-apps/xdg-desktop-portal`
- `gui-libs/xdg-desktop-portal-wlr`

The role checks package availability with Portage before install. It does not add overlays or unmask packages.

## Start The Session

Log in on a TTY as `DESKTOP_USER` and run:

```sh
~/.config/gentoo-ai-installer/sway-wayland-session.sh
```

The launcher runs `exec dbus-run-session -- sway`.

## Failure Modes

- Missing `sway` or helper packages: sync/fix the Gentoo repository or disable optional helpers, then rerun `make desktop-plan`.
- Sway exits immediately: verify KMS/GPU support, seat permissions, and that the user session is launched from a TTY.
- Portal packages unavailable: set `DESKTOP_ENABLE_PORTAL=no` or add a later package-policy change.
- Display manager enabled: disable it manually; this profile is TTY-launch by default.

## Recovery

Rerun `make desktop-install` after package or permission fixes. The managed Sway config and session launcher are rewritten idempotently.
