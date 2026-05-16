# Post-Install Desktop Profiles

Desktop profiles are optional post-install Ansible workflows. They run after the base Gentoo system has been installed, booted from its own disk, reached over SSH, and validated with the normal first-boot checks.

They are not part of the basic-console installer. They must not run against the official Gentoo live ISO, a mounted `/mnt/gentoo` chroot, or an unfinished install.

## Implemented Profiles

| Profile | Status | Session | Default display manager |
| --- | --- | --- | --- |
| `i3-x11` | implemented | `startx` | `none` |

Future desktop profiles should reuse the same Makefile targets, wrapper scripts, `post_install/desktop_common` role, and installed-target SSH model.

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

## Variables

| Variable | Default | Required | Meaning |
| --- | --- | --- | --- |
| `DESKTOP_PROFILE` | `i3-x11` | yes | Desktop profile to run. |
| `DESKTOP_TARGET_HOST` | none | yes | Installed Gentoo target hostname or IP. |
| `DESKTOP_TARGET_PORT` | `22` | no | SSH port on the installed target. |
| `DESKTOP_TARGET_USER` | none | yes | SSH user for Ansible. Must be root or passwordless sudo. |
| `DESKTOP_USER` | none | yes | Installed user that receives session files. |
| `DESKTOP_INSTALL_RECOMMENDS` | `yes` | no | Install profile helper packages. |
| `DESKTOP_DISPLAY_MANAGER` | `none` | no | Display manager policy. Only `none` is implemented. |
| `DESKTOP_SESSION_START` | `startx` | no | Session start method. Only `startx` is implemented. |
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
- store passwords, tokens, or private keys.

The role validates the installed target boundary before package work. If the target looks like a live ISO root, the workflow fails.

## Failure Modes

- `DESKTOP_TARGET_HOST is required`: pass the installed system SSH host or IP.
- `DESKTOP_TARGET_USER is required`: pass a user that can connect over SSH and elevate with `sudo`.
- `DESKTOP_USER must name an existing installed-system user`: create or select the user before running the desktop profile.
- `target does not look like an installed amd64 Gentoo system`: boot the installed system, not the live ISO.
- `requested packages are unavailable`: sync or fix the target Portage tree, then rerun the plan.
- SSH timeouts: verify the installed system network, firewall, SSH daemon, port, and host key.

## Recovery

Run `make desktop-plan` again after correcting inputs or target state. If package installation fails, fix the Portage error on the installed target and rerun `make desktop-install`; the package task uses `--noreplace` and validates installed state before deciding whether to run.

If session files are wrong, rerun `make desktop-install` for the same `DESKTOP_USER`. The managed `.xinitrc` and i3 config are rewritten from templates.
