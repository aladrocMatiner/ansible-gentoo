# Niri Wayland Desktop Profile

The `niri-wayland` profile installs Niri as the innovative scrollable-tiling Wayland option. It is optional and experimental because Gentoo package availability and Xwayland compatibility may vary.

## Required Acknowledgement

Installation requires:

```sh
DESKTOP_EXPERIMENTAL_OK=yes
```

No overlay, source build, unmasking, or binary download behavior is implemented.

## Install

Plan:

```sh
make desktop-plan \
  DESKTOP_PROFILE=niri-wayland \
  DESKTOP_TARGET_HOST=<host-or-ip> \
  DESKTOP_TARGET_USER=<ssh-user> \
  DESKTOP_USER=<installed-user>
```

Install:

```sh
make desktop-install \
  DESKTOP_PROFILE=niri-wayland \
  DESKTOP_TARGET_HOST=<host-or-ip> \
  DESKTOP_TARGET_USER=<ssh-user> \
  DESKTOP_USER=<installed-user> \
  DESKTOP_EXPERIMENTAL_OK=yes
```

Validate:

```sh
make desktop-validate \
  DESKTOP_PROFILE=niri-wayland \
  DESKTOP_TARGET_HOST=<host-or-ip> \
  DESKTOP_TARGET_USER=<ssh-user> \
  DESKTOP_USER=<installed-user>
```

## Package Policy

Core packages:

- `sys-apps/dbus`
- `gui-wm/niri`
- `gui-apps/foot`

Recommended packages include `gui-apps/fuzzel`, `gui-apps/wl-clipboard`, `gui-apps/grim`, and `gui-apps/slurp`.

Xwayland compatibility uses `gui-wm/xwayland-satellite` when `DESKTOP_ENABLE_XWAYLAND=yes`. If that package is unavailable, rerun with `DESKTOP_ENABLE_XWAYLAND=no` or create a later package-policy change.

## Start The Session

Log in on a TTY as `DESKTOP_USER` and run:

```sh
~/.config/gentoo-ai-installer/niri-wayland-session.sh
```

The launcher runs `exec dbus-run-session -- niri-session`.

## Failure Modes And Recovery

- Niri unavailable: use Sway/i3 or add a future OpenSpec package-source policy.
- `xwayland-satellite` unavailable: disable Xwayland compatibility for the first install attempt.
- Session fails: verify GPU/KMS support and Niri package documentation for the installed version.
- Config issue: rerun `make desktop-install` to rewrite the managed Niri config.
