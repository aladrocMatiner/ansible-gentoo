# Ansible System Packages and Services

`make install-system-packages` installs the minimal console package set in the target Gentoo root and enables init-specific services.

This target follows the Gentoo AMD64 Handbook system tools and networking phases, with one project policy difference: `gentoo-ai-installer` uses NetworkManager as the v1 network manager instead of the Handbook's simplest `dhcpcd` example.

The package and service set contributes to the v1 target baseline in `docs/target-system-baseline.md`.

## Scope

This target modifies the mounted target root under `/mnt/gentoo`.

It does:

- install common console packages,
- install FAT32/vfat tooling for the EFI system partition,
- verify ext4 tooling,
- install Btrfs tooling when `FILESYSTEM=btrfs`,
- install OpenRC-specific syslog, cron, and time-sync packages for OpenRC,
- use systemd built-in service policy for systemd where applicable,
- install OpenSSH only when `ENABLE_SSH=yes`,
- enable services through init-specific roles,
- record non-secret package and service evidence under `logs/install-runs/<run-id>/system-packages/`.

It does not:

- create users,
- set passwords,
- install GRUB,
- change EFI boot entries,
- partition disks,
- format filesystems,
- reboot.

## Package Policy

Common packages:

- `app-admin/sudo`
- `app-editors/nano`
- `sys-fs/dosfstools`
- `sys-fs/e2fsprogs`
- `net-misc/networkmanager`

Btrfs-only package:

- `sys-fs/btrfs-progs`

OpenRC variant packages:

- `app-admin/sysklogd`
- `sys-process/cronie`
- `net-misc/chrony`

SSH package when `ENABLE_SSH=yes`:

- `net-misc/openssh`

The role writes `/mnt/gentoo/etc/portage/package.use/gentoo-ai-installer-system` to keep the basic console target conservative. It disables optional desktop, modem, Wi-Fi, documentation, and mail stacks unless a later OpenSpec policy adds them.

## Service Policy

OpenRC services are enabled with `rc-update` only:

- `dbus`
- `NetworkManager`
- `sysklogd`
- `cronie`
- `chronyd`
- `sshd` when `ENABLE_SSH=yes`

systemd services are enabled with `systemctl` only:

- `NetworkManager.service`
- `systemd-timesyncd.service`
- `sshd.service` when `ENABLE_SSH=yes`

OpenRC roles must not call `systemctl`. systemd roles must not call `rc-update` or `rc-service`.

## Commands

OpenRC ext4:

```sh
make install-system-packages PROFILE=openrc FILESYSTEM=ext4
```

OpenRC Btrfs:

```sh
make install-system-packages PROFILE=openrc FILESYSTEM=btrfs
```

Enable installed SSH:

```sh
make install-system-packages PROFILE=openrc FILESYSTEM=ext4 ENABLE_SSH=yes
```

`make install-base-packages` is a compatibility alias for `make install-system-packages`.

For a remote official Gentoo live ISO target, pass:

```sh
make install-system-packages PROFILE=openrc FILESYSTEM=ext4 ANSIBLE_LIVE_HOST=192.0.2.10
```

If `ANSIBLE_LIVE_HOST` is empty, the wrapper may discover the configured local libvirt VM for testing.

## Required State

Run after:

- `make mount-target`
- `make stage3-install`
- `make prepare-chroot`
- `make configure-portage`

The target root must be `/mnt/gentoo`, and chroot pseudo-filesystems must be mounted.

## Validation

Successful output must show:

- all requested packages installed,
- NetworkManager enabled for the selected init system,
- time-sync service enabled according to policy,
- SSH service enabled only when `ENABLE_SSH=yes`,
- package/service report with `final_checks_input: true`.

## Failure Modes

- `/mnt/gentoo` is not mounted.
- Stage3 was not extracted.
- Chroot pseudo-filesystems are missing.
- Portage profile or repository sync was not prepared.
- Package USE policy needs adjustment.
- OpenRC service names do not exist in the target.
- systemd unit names do not exist in the target.
- OpenRC workflow attempts to call systemd tooling.
- systemd workflow attempts to call OpenRC tooling.

## Recovery

- If target-root checks fail, rerun `make mount-target` and `make prepare-chroot`.
- If Portage cannot resolve packages, rerun `make configure-portage` and inspect `/mnt/gentoo/etc/portage/package.use/gentoo-ai-installer-system`.
- If a service cannot be enabled, confirm the selected `PROFILE` matches the stage3 and Portage profile.
- If SSH is needed after a run with `ENABLE_SSH=no`, rerun with `ENABLE_SSH=yes`; do not manually enable it outside the Makefile workflow.

## Output Artifacts

- `/mnt/gentoo/etc/portage/package.use/gentoo-ai-installer-system`
- enabled OpenRC runlevel entries or systemd unit symlinks in the target
- `logs/install-runs/<run-id>/system-packages/packages-services.json`
