# Mango Wayland Desktop Profile

The `mango-wayland` profile is an experimental post-install profile for Mango/MangoWC. It exists to test a newer compositor path without destabilizing the base installer.

## Required Acknowledgement

Installation requires:

```sh
DESKTOP_EXPERIMENTAL_OK=yes
```

Mango package availability may be limited. The role fails closed when required packages are unavailable. It never clones upstream repositories, runs arbitrary build commands, adds overlays, unmasks packages, or installs prebuilt binaries.

## Install

Plan:

```sh
make desktop-plan \
  DESKTOP_PROFILE=mango-wayland \
  DESKTOP_TARGET_HOST=<host-or-ip> \
  DESKTOP_TARGET_USER=<ssh-user> \
  DESKTOP_USER=<installed-user>
```

Install:

```sh
make desktop-install \
  DESKTOP_PROFILE=mango-wayland \
  DESKTOP_TARGET_HOST=<host-or-ip> \
  DESKTOP_TARGET_USER=<ssh-user> \
  DESKTOP_USER=<installed-user> \
  DESKTOP_EXPERIMENTAL_OK=yes
```

Validate:

```sh
make desktop-validate \
  DESKTOP_PROFILE=mango-wayland \
  DESKTOP_TARGET_HOST=<host-or-ip> \
  DESKTOP_TARGET_USER=<ssh-user> \
  DESKTOP_USER=<installed-user>
```

## Package Policy

Core packages:

- `sys-apps/dbus`
- `gui-wm/mango`
- `gui-apps/foot`

Recommended helpers include `gui-apps/wl-clipboard`, `gui-apps/grim`, and `gui-apps/slurp`.

Validation accepts either `mangowc` or `mango` as the compositor command because binary naming may vary with the eventual Gentoo package.

## Start The Session

Log in on a TTY as `DESKTOP_USER` and run:

```sh
~/.config/gentoo-ai-installer/mango-wayland-session.sh
```

The default launcher runs `exec dbus-run-session -- mangowc`.

## Failure Modes And Recovery

- `gui-wm/mango` unavailable: use Sway, i3, Hyprland, or Niri; do not add overlays without a new OpenSpec change.
- Binary name differs: update the package policy and validation commands through a reviewed change.
- Session fails: verify compositor documentation, GPU/KMS support, and seat/session permissions.
- Managed config is unsuitable for the package version: adjust through a later profile-specific OpenSpec change.
