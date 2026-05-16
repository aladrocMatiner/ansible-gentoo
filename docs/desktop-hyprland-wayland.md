# Hyprland Wayland Desktop Profile

The `hyprland-wayland` profile installs Hyprland as the advanced visual Wayland option. It is experimental in this project because Hyprland packaging can move quickly and may be unavailable or keyworded differently across Gentoo trees.

## Required Acknowledgement

Installation requires:

```sh
DESKTOP_EXPERIMENTAL_OK=yes
```

The role does not add overlays, accept unstable keywords, clone upstream repositories, build from source, or install prebuilt binaries. `DESKTOP_PACKAGE_SOURCE=gentoo` is the only supported source.

## Install

Plan:

```sh
make desktop-plan \
  DESKTOP_PROFILE=hyprland-wayland \
  DESKTOP_TARGET_HOST=<host-or-ip> \
  DESKTOP_TARGET_USER=<ssh-user> \
  DESKTOP_USER=<installed-user>
```

Install:

```sh
make desktop-install \
  DESKTOP_PROFILE=hyprland-wayland \
  DESKTOP_TARGET_HOST=<host-or-ip> \
  DESKTOP_TARGET_USER=<ssh-user> \
  DESKTOP_USER=<installed-user> \
  DESKTOP_EXPERIMENTAL_OK=yes
```

Validate:

```sh
make desktop-validate \
  DESKTOP_PROFILE=hyprland-wayland \
  DESKTOP_TARGET_HOST=<host-or-ip> \
  DESKTOP_TARGET_USER=<ssh-user> \
  DESKTOP_USER=<installed-user>
```

## Package Policy

Core packages:

- `sys-apps/dbus`
- `gui-wm/hyprland`
- `gui-apps/foot`

Recommended packages include `gui-apps/waybar`, `gui-apps/wofi`, `gui-apps/wl-clipboard`, `gui-apps/grim`, `gui-apps/slurp`, and `gui-apps/hyprpaper`.

Portal packages when enabled are `sys-apps/xdg-desktop-portal` and `gui-libs/xdg-desktop-portal-hyprland`.

## Start The Session

Log in on a TTY as `DESKTOP_USER` and run:

```sh
~/.config/gentoo-ai-installer/hyprland-wayland-session.sh
```

The launcher runs `exec dbus-run-session -- Hyprland`.

## Failure Modes And Recovery

- Experimental acknowledgement missing: rerun install with `DESKTOP_EXPERIMENTAL_OK=yes` after reviewing this document.
- Hyprland package unavailable: use Sway or i3, or create a future OpenSpec change for a reviewed overlay/source policy.
- Session fails: verify GPU/KMS support and Wayland session permissions.
- Config issue: rerun `make desktop-install` to rewrite the managed config, then validate again.
