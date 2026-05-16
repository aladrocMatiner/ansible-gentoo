# Post-Install Desktop Profiles

Desktop profiles are optional post-install Ansible workflows. They run after the base Gentoo system has been installed, booted from its own disk, reached over SSH, and validated with the normal first-boot checks.

They are not part of the basic-console installer. They must not run against the official Gentoo live ISO, a mounted `/mnt/gentoo` chroot, or an unfinished install.

## Implemented Profiles

| Profile | Status | Session | Default display manager |
| --- | --- | --- | --- |
| `i3-x11` | implemented | `startx` | `none` |
| `sway-wayland` | implemented, conservative Wayland | manual TTY launch | `none` |
| `hyprland-wayland` | implemented, experimental | manual TTY launch | `none` |
| `niri-wayland` | implemented, experimental/innovative | manual TTY launch | `none` |
| `mango-wayland` | implemented, experimental package availability | manual TTY launch | `none` |

Future desktop profiles should reuse the same Makefile targets, wrapper scripts, `post_install/desktop_common` role, shared Wayland helper role where relevant, and installed-target SSH model.

## Required Target State

Before running a desktop profile:

- the installed system has completed `make final-checks` before reboot,
- the installed system has booted from disk,
- installed SSH access works,
- the target has `/etc/gentoo-release` and `/etc/fstab`,
- the root filesystem is not the live ISO overlay, squashfs, iso9660, or tmpfs root,
- `DESKTOP_USER` already exists,
- `DESKTOP_TARGET_USER` is `root` or has passwordless `sudo`,
- the target has a usable Portage tree for package availability checks.

## Makefile Targets

Plan the selected desktop profile without mutating the target:

```sh
make desktop-plan \
  DESKTOP_PROFILE=i3-x11 \
  DESKTOP_TARGET_HOST=<host-or-ip> \
  DESKTOP_TARGET_USER=<ssh-user> \
  DESKTOP_USER=<installed-user>
```

Install the selected desktop profile:

```sh
make desktop-install \
  DESKTOP_PROFILE=i3-x11 \
  DESKTOP_TARGET_HOST=<host-or-ip> \
  DESKTOP_TARGET_USER=<ssh-user> \
  DESKTOP_USER=<installed-user>
```

Validate the selected profile after installation:

```sh
make desktop-validate \
  DESKTOP_PROFILE=i3-x11 \
  DESKTOP_TARGET_HOST=<host-or-ip> \
  DESKTOP_TARGET_USER=<ssh-user> \
  DESKTOP_USER=<installed-user>
```

The i3 convenience target is equivalent to `DESKTOP_PROFILE=i3-x11 make desktop-install`:

```sh
make desktop-i3-install \
  DESKTOP_TARGET_HOST=<host-or-ip> \
  DESKTOP_TARGET_USER=<ssh-user> \
  DESKTOP_USER=<installed-user>
```

Wayland convenience targets:

```sh
make desktop-sway-install DESKTOP_TARGET_HOST=<host-or-ip> DESKTOP_TARGET_USER=<ssh-user> DESKTOP_USER=<installed-user>
make desktop-hyprland-install DESKTOP_TARGET_HOST=<host-or-ip> DESKTOP_TARGET_USER=<ssh-user> DESKTOP_USER=<installed-user> DESKTOP_EXPERIMENTAL_OK=yes
make desktop-niri-install DESKTOP_TARGET_HOST=<host-or-ip> DESKTOP_TARGET_USER=<ssh-user> DESKTOP_USER=<installed-user> DESKTOP_EXPERIMENTAL_OK=yes
make desktop-mango-install DESKTOP_TARGET_HOST=<host-or-ip> DESKTOP_TARGET_USER=<ssh-user> DESKTOP_USER=<installed-user> DESKTOP_EXPERIMENTAL_OK=yes
```

## Variables

| Variable | Default | Required | Meaning |
| --- | --- | --- | --- |
| `DESKTOP_PROFILE` | `i3-x11` | yes | Desktop profile to run. |
| `DESKTOP_TARGET_HOST` | none | yes | Installed Gentoo target hostname or IP. |
| `DESKTOP_TARGET_PORT` | `22` | no | SSH port on the installed target. |
| `DESKTOP_TARGET_USER` | none | yes | SSH user for Ansible. Must be root or passwordless sudo. |
| `DESKTOP_USER` | none | yes | Installed user that receives session files. |
| `DESKTOP_INSTALL_RECOMMENDS` | `yes` | no | Install profile helper packages. |
| `DESKTOP_ENABLE_PORTAL` | `yes` | no | Install Wayland portal support where the profile defines portal packages. |
| `DESKTOP_ENABLE_XWAYLAND` | `yes` | no | Install Xwayland compatibility packages where the profile defines them. |
| `DESKTOP_EXPERIMENTAL_OK` | `no` | for experimental installs | Required for Hyprland, Niri, and Mango install targets. |
| `DESKTOP_PACKAGE_SOURCE` | `gentoo` | no | Only `gentoo` is allowed; overlays/source builds need a later OpenSpec change. |
| `DESKTOP_DISPLAY_MANAGER` | `none` | no | Display manager policy. Only `none` is implemented. |
| `DESKTOP_SESSION_START` | profile default | no | `startx` for i3; `manual` for Wayland profiles. |
| `DESKTOP_PRIVILEGE_TOOL` | `sudo` | no | Privilege tool. Only `sudo` is implemented. |

## Safety Boundary

Desktop workflows may install packages and write session files under the selected installed user's home directory. They must not:

- partition, wipe, format, or mount disks,
- extract stage3,
- run installer chroot phases,
- install GRUB,
- call `efibootmgr`,
- change EFI boot entries,
- edit live ISO state as if it were the installed target,
- enable overlays, accept unstable keywords, clone upstream repositories, source-build compositors, or install prebuilt binaries,
- store passwords, tokens, or private keys.

The role validates the installed target boundary before package work. If the target looks like a live ISO root, the workflow fails.

## Failure Modes

- `DESKTOP_TARGET_HOST is required`: pass the installed system SSH host or IP.
- `DESKTOP_TARGET_USER is required`: pass a user that can connect over SSH and elevate with `sudo`.
- `DESKTOP_USER must name an existing installed-system user`: create or select the user before running the desktop profile.
- `target does not look like an installed amd64 Gentoo system`: boot the installed system, not the live ISO.
- `requested packages are unavailable`: sync or fix the target Portage tree, then rerun the plan.
- `DESKTOP_EXPERIMENTAL_OK=yes is required`: only install Hyprland, Niri, or Mango after accepting their package availability and compatibility risk.
- `DESKTOP_PACKAGE_SOURCE must be gentoo`: overlay, source-build, or binary package behavior is not implemented in these profiles.
- SSH timeouts: verify the installed system network, firewall, SSH daemon, port, and host key.

## Recovery

Run `make desktop-plan` again after correcting inputs or target state. If package installation fails, fix the Portage error on the installed target and rerun `make desktop-install`; the package task uses `--noreplace` and validates installed state before deciding whether to run.

If session files are wrong, rerun `make desktop-install` for the same `DESKTOP_USER`. Managed session launchers and profile configs are rewritten from templates.

For Wayland profile details:

- `docs/desktop-sway-wayland.md`
- `docs/desktop-hyprland-wayland.md`
- `docs/desktop-niri-wayland.md`
- `docs/desktop-mango-wayland.md`
