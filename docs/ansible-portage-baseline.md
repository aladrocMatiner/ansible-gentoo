# Ansible Portage Baseline

`make configure-portage` configures the minimal Portage baseline inside the mounted Gentoo target root.

It runs from the operator machine over SSH into the official Gentoo live ISO target. It mutates only the target root under `/mnt/gentoo`. It does not install packages, install a kernel, install a bootloader, create users, enable services, run `emerge @world`, or install Codex into the target system.

Mirror behavior follows `docs/download-cache-and-mirror-policy.md`.

## Required State

Run the earlier apply targets first:

```sh
make mount-target PROFILE=openrc FILESYSTEM=btrfs INSTALL_DISK=/dev/vda
make stage3-install PROFILE=openrc FILESYSTEM=btrfs
make prepare-chroot PROFILE=openrc FILESYSTEM=btrfs
```

For a real network target, pass `ANSIBLE_LIVE_HOST=...` and use the disk selected from that target's own `make detect-disks` output.

## Command

```sh
make configure-portage PROFILE=openrc FILESYSTEM=btrfs
```

For systemd:

```sh
make configure-portage PROFILE=systemd FILESYSTEM=ext4
```

## Variables

| Variable | Default | Meaning |
| --- | --- | --- |
| `PROFILE` | `openrc` | Selects `openrc` or `systemd` variant data. |
| `PORTAGE_GENTOO_MIRRORS` | `https://distfiles.gentoo.org` | Single HTTPS distfiles mirror written to `GENTOO_MIRRORS`. |
| `TARGET_MOUNT` | `/mnt/gentoo` | Must remain `/mnt/gentoo` for the current implementation. |

Variant profile paths are stored under `ansible/group_vars/`:

- `PROFILE=openrc`: `default/linux/amd64/23.0`
- `PROFILE=systemd`: `default/linux/amd64/23.0/systemd`

## Behavior

The workflow:

- verifies the live ISO target, architecture, UEFI, network, DNS, and time,
- ensures chroot pseudo-filesystems and DNS readiness through `common/chroot`,
- verifies stage3 marker directories exist under `/mnt/gentoo`,
- writes a conservative target `/etc/portage/make.conf`,
- installs the official Gentoo repository configuration from the stage3,
- runs `emerge --sync --quiet` for the official Gentoo repository,
- selects the Portage profile matching `PROFILE`,
- refuses installed-system GURU repository configuration,
- reports pending protected config updates without applying them,
- writes evidence under `logs/install-runs/<run-id>/portage/`.

The generated `make.conf` uses:

```text
COMMON_FLAGS="-O2 -pipe"
MAKEOPTS="-j<N>"
USE=""
ACCEPT_LICENSE="-* @FREE @BINARY-REDISTRIBUTABLE"
GENTOO_MIRRORS="<PORTAGE_GENTOO_MIRRORS>"
GRUB_PLATFORMS="efi-64"
LC_MESSAGES=C.UTF-8
```

`MAKEOPTS` is derived conservatively from detected CPU count and capped at 8 jobs.

## Safety

The role refuses target roots other than `/mnt/gentoo`. It does not write secrets, enable overlays, run package installs, run broad `@world`, or modify host block devices.

GURU may be used for temporary live ISO Codex bootstrap, but this target must keep GURU disabled in the installed Gentoo system unless a later approved OpenSpec change explicitly enables it.

## Failure Modes

- `/mnt/gentoo` is not mounted or does not contain extracted stage3 markers.
- Chroot pseudo-filesystems or DNS are not ready.
- Official Gentoo repository sync fails.
- The requested profile path is not available after sync.
- `PORTAGE_GENTOO_MIRRORS` is not an HTTPS URL.
- GURU is already configured in the target system.
- Pending protected config updates exist and require manual review before later package operations.

## Recovery

If repo sync fails, verify live ISO network, DNS, time, and mirror reachability, then rerun `make configure-portage`.

If profile selection fails, inspect `eselect profile list` inside the target chroot and update only the variant variables through an approved OpenSpec change.

If pending protected config files are reported, review them before later package or service steps. Do not run unattended config update commands as part of v1 baseline setup.
