# i3 X11 Desktop Profile

The `i3-x11` profile installs a minimal X11/i3 desktop on an already installed Gentoo system. It is intended for operators who want a lightweight tiling desktop after the basic-console installation is stable.

## Scope

The profile manages:

- core X11 and i3 packages,
- optional helper packages when `DESKTOP_INSTALL_RECOMMENDS=yes`,
- `~/.xinitrc` for `startx`,
- `~/.config/i3/config`,
- validation that no display manager is enabled by default.

It does not configure a full desktop environment, GPU-specific drivers, login managers, audio, Bluetooth, printers, or per-user secrets.

## Package Set

Core packages:

- `sys-apps/dbus`
- `x11-base/xorg-server`
- `x11-apps/xinit`
- `x11-wm/i3`

Recommended packages when `DESKTOP_INSTALL_RECOMMENDS=yes`:

- `x11-misc/dmenu`
- `x11-misc/i3status`
- `x11-terms/xterm`

Before installing, the role runs `portageq match / <atom>` for each package so missing package atoms fail with a clear message.

## Install

Plan first:

```sh
make desktop-plan \
  DESKTOP_TARGET_HOST=<host-or-ip> \
  DESKTOP_TARGET_USER=<ssh-user> \
  DESKTOP_USER=<installed-user>
```

Install:

```sh
make desktop-install \
  DESKTOP_TARGET_HOST=<host-or-ip> \
  DESKTOP_TARGET_USER=<ssh-user> \
  DESKTOP_USER=<installed-user>
```

Validate:

```sh
make desktop-validate \
  DESKTOP_TARGET_HOST=<host-or-ip> \
  DESKTOP_TARGET_USER=<ssh-user> \
  DESKTOP_USER=<installed-user>
```

Use `DESKTOP_INSTALL_RECOMMENDS=no` to install only the core packages.

## Start The Session

Log in as `DESKTOP_USER` on the installed system and run:

```sh
startx
```

The managed `.xinitrc` starts:

```sh
exec dbus-run-session -- i3
```

## Validation Checks

`make desktop-validate` verifies:

- the target is installed Gentoo on amd64,
- the target root is not a live ISO root,
- `DESKTOP_USER` exists and has a `/home/...` directory,
- the package set is installed,
- `i3` and `startx` are available in `PATH`,
- `~/.xinitrc` exists and launches i3,
- `~/.config/i3/config` exists,
- OpenRC or systemd display-manager enablement is absent unless a future profile explicitly allows it.

## Failure Modes And Recovery

- Missing user: create the installed user through the base installer or manually, then rerun `make desktop-plan`.
- Missing package atoms: run the target's Portage sync/update procedure, verify repositories, then rerun the plan.
- `sudo -n true` fails: connect as `root` or configure passwordless sudo for `DESKTOP_TARGET_USER`.
- `startx` opens a blank or unusable session: verify GPU/input drivers and user permissions on the installed system. This profile installs the generic X11/i3 session, not hardware-specific graphics policy.
- Display manager enabled: disable it manually or wait for a later profile that explicitly supports display managers.

## Evidence

The Ansible output reports the selected profile, target user, requested packages, missing packages before installation, `.xinitrc` path, i3 config path, session method, and display manager policy. It does not print secrets.
