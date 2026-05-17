# Post-Install Desktop Login Manager

The desktop login manager workflow is optional. It runs after a Gentoo system has been installed, booted from its own disk, reached over SSH, and validated as an installed target.

It is not part of the base console installer. It must not run against the official Gentoo live ISO, `/mnt/gentoo`, or an unfinished chroot.

## Implemented Login Managers

| Value | Status | Greeter | Session source |
| --- | --- | --- | --- |
| `DESKTOP_DISPLAY_MANAGER=none` | default | none | TTY `startx` or managed Wayland launchers |
| `DESKTOP_DISPLAY_MANAGER=greetd` | implemented | `tuigreet` | `/usr/share/xsessions` and `/usr/share/wayland-sessions` |

The `greetd` workflow uses the Gentoo package atoms `gui-libs/greetd` and `gui-apps/tuigreet`. It validates package availability with Portage before installing. It does not add overlays, write autounmask changes, accept unstable keywords, clone source, or install binary downloads.

## Required Target State

Before running the login manager workflow:

- the installed system has booted from disk,
- SSH access to the installed system works,
- `DESKTOP_TARGET_USER` is `root` or has passwordless `sudo`,
- `DESKTOP_USER` already exists,
- at least one desktop profile session command is installed,
- the target has `/etc/gentoo-release` and `/etc/fstab`,
- the root filesystem is not the live ISO overlay, squashfs, iso9660, or tmpfs root.

## Makefile Targets

Plan login manager changes without mutating the target:

```sh
make desktop-login-plan \
  DESKTOP_DISPLAY_MANAGER=greetd \
  DESKTOP_TARGET_HOST=<host-or-ip> \
  DESKTOP_TARGET_USER=<ssh-user> \
  DESKTOP_USER=<installed-user>
```

Install `greetd`, generate session entries, enable the service for boot, and start it now:

```sh
make desktop-login-install \
  DESKTOP_DISPLAY_MANAGER=greetd \
  DESKTOP_TARGET_HOST=<host-or-ip> \
  DESKTOP_TARGET_USER=<ssh-user> \
  DESKTOP_USER=<installed-user> \
  I_UNDERSTAND_DESKTOP_LOGIN_MANAGER_CHANGES=yes
```

Validate the installed login manager state without mutation:

```sh
make desktop-login-validate \
  DESKTOP_DISPLAY_MANAGER=greetd \
  DESKTOP_TARGET_HOST=<host-or-ip> \
  DESKTOP_TARGET_USER=<ssh-user> \
  DESKTOP_USER=<installed-user>
```

## Variables

| Variable | Default | Required | Meaning |
| --- | --- | --- | --- |
| `DESKTOP_DISPLAY_MANAGER` | `none` | no | Login manager policy. Use `greetd` to install the implemented login screen. |
| `DESKTOP_LOGIN_MANAGER` | `DESKTOP_DISPLAY_MANAGER` | no | Internal login manager selector. Must match `DESKTOP_DISPLAY_MANAGER`. |
| `DESKTOP_LOGIN_SESSIONS` | `installed` | no | `installed` auto-detects installed allowlisted sessions; otherwise use a comma-separated list. |
| `DESKTOP_LOGIN_DEFAULT_SESSION` | first selected session | no | Default session passed to `tuigreet --cmd`. |
| `DESKTOP_LOGIN_ENABLE_SERVICE` | `yes` | no | Enable the login manager service for boot and start it after installing it. |
| `I_UNDERSTAND_DESKTOP_LOGIN_MANAGER_CHANGES` | none | for install | Must be `yes` before service enablement and immediate service start. |
| `DESKTOP_TARGET_HOST` | none | yes | Installed Gentoo target hostname or IP. |
| `DESKTOP_TARGET_PORT` | `22` | no | SSH port on the installed target. |
| `DESKTOP_TARGET_USER` | none | yes | SSH user for Ansible. Must be root or passwordless sudo. |
| `DESKTOP_USER` | none | yes | Installed user who will log in through the session selector. |

Supported `DESKTOP_LOGIN_SESSIONS` values:

- `installed`
- `i3-x11`
- `sway-wayland`
- `hyprland-wayland`
- `niri-wayland`
- `mango-wayland`

For explicit multiple sessions:

```sh
DESKTOP_LOGIN_SESSIONS=i3-x11,sway-wayland
```

## Managed Paths

The workflow may manage only these installed-target paths:

- `/etc/greetd/config.toml`
- `/usr/local/bin/gentoo-ai-desktop-session`
- `/usr/share/xsessions/gentoo-ai-*.desktop`
- `/usr/share/wayland-sessions/gentoo-ai-*.desktop`

It must not touch disks, mountpoints, stage3 artifacts, chroot mounts, bootloader files, EFI entries, password files, SSH authorized keys, or live ISO state.

## Session Behavior

`tuigreet` reads session entries from:

- `/usr/share/xsessions`
- `/usr/share/wayland-sessions`

The generated entries call `/usr/local/bin/gentoo-ai-desktop-session <profile>`. The dispatcher is allowlisted and supports only the project desktop profile names. For X11 sessions, `tuigreet` uses its normal X session wrapper behavior to start X11. For Wayland sessions, the dispatcher runs the selected compositor through `dbus-run-session`.

`DESKTOP_LOGIN_SESSIONS=installed` includes only sessions whose command is already available on the target. If a session is listed explicitly and its command is missing, the workflow fails.

## Safety Boundary

`desktop-login-plan` and `desktop-login-validate` are read-only.

`desktop-login-install` may:

- install `gui-libs/greetd` and `gui-apps/tuigreet`,
- write the managed session dispatcher and session entries,
- write `/etc/greetd/config.toml`,
- enable the `greetd` service for boot,
- start the `greetd` service immediately.

It must not:

- partition, format, wipe, or mount disks,
- extract stage3,
- run chroot installer phases,
- install or configure GRUB,
- call `efibootmgr`,
- change EFI boot entries,
- change user passwords,
- change SSH authorization,
- enable autologin,
- store secrets.

OpenRC targets enable `greetd` only through `rc-update` and start it only through `rc-service`. systemd targets enable and start `greetd.service` only through systemd service tasks.

## Failure Modes

- `DESKTOP_TARGET_HOST is required`: pass the installed system SSH host or IP.
- `DESKTOP_TARGET_USER is required`: pass a user that can connect over SSH and elevate with passwordless `sudo`, or use `root`.
- `DESKTOP_USER must name an existing installed-system user`: create or select the user before running the login manager workflow.
- `target does not look like an installed amd64 Gentoo system`: boot the installed system, not the live ISO.
- `I_UNDERSTAND_DESKTOP_LOGIN_MANAGER_CHANGES=yes is required`: rerun install with the confirmation after reviewing this document.
- `requested greetd packages are unavailable`: sync or fix the target Portage tree; the workflow does not add overlays, keywords, source builds, or binary packages.
- `requested desktop login sessions are unavailable`: install the matching desktop profile first or reduce `DESKTOP_LOGIN_SESSIONS`.
- `greetd appears enabled while DESKTOP_DISPLAY_MANAGER=none was requested`: validate with `DESKTOP_DISPLAY_MANAGER=greetd` or disable the service manually if it should not be used.
- `greetd is enabled but not active`: rerun `make desktop-login-install ... I_UNDERSTAND_DESKTOP_LOGIN_MANAGER_CHANGES=yes` or inspect the target service logs.

## Recovery

If login fails but SSH still works, rerun:

```sh
make desktop-login-validate DESKTOP_DISPLAY_MANAGER=greetd DESKTOP_TARGET_HOST=<host-or-ip> DESKTOP_TARGET_USER=<ssh-user> DESKTOP_USER=<installed-user>
```

If the greeter blocks local login, boot to a TTY or use SSH and stop/disable the service with the target's init system:

```sh
sudo rc-service greetd stop
sudo rc-update del greetd default
```

or:

```sh
sudo systemctl stop greetd.service
sudo systemctl disable greetd.service
```

Then rerun `make desktop-login-plan` before applying changes again.
