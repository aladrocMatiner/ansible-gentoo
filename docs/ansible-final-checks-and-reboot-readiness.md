# Ansible Final Checks and Reboot Readiness

`make final-checks` runs read-only checks against the official Gentoo live ISO target before the operator reboots into the installed system.

It does not install packages, change files under `/mnt/gentoo`, alter EFI boot entries, create users, change passwords, or reboot.

The role evaluates the v1 target baseline defined in `docs/target-system-baseline.md`, including the installed time-sync policy in `docs/installed-time-sync-policy.md` and installed SSH policy in `docs/installed-ssh-policy.md`.

## Run

For the disposable libvirt VM:

```sh
make final-checks PROFILE=openrc FILESYSTEM=btrfs ADMIN_USER=gentoo ENABLE_SSH=no
```

For a network target, pass the live ISO address:

```sh
make final-checks \
  ANSIBLE_LIVE_HOST=<live-iso-ip> \
  PROFILE=openrc \
  FILESYSTEM=ext4 \
  ADMIN_USER=<admin-user>
```

`ADMIN_USER` is required because final checks verify the installed administrator account, group membership, shell, and sudo policy.

## Preconditions

Run the install steps first:

```sh
make mount-target INSTALL_DISK=...
make stage3-install PROFILE=...
make prepare-chroot
make configure-portage PROFILE=...
make configure-system PROFILE=...
make generate-fstab INSTALL_DISK=... FILESYSTEM=...
make install-kernel PROFILE=... FILESYSTEM=...
make install-system-packages PROFILE=... FILESYSTEM=...
make configure-users PROFILE=... ADMIN_USER=...
make install-bootloader INSTALL_DISK=... I_UNDERSTAND_BOOTLOADER_CHANGES=yes
```

The target root must still be mounted at `/mnt/gentoo`, the ESP at `/mnt/gentoo/boot/efi`, and chroot pseudo-filesystems must already be prepared.

## Checks

The role validates:

- live ISO evidence, amd64, UEFI, network, DNS, and clock sanity
- target root and EFI mount state
- chroot pseudo-filesystem mounts
- `/etc/fstab` root and EFI UUID entries
- Btrfs `subvol=@` root and approved subvolume entries when `FILESYSTEM=btrfs`
- `/etc/kernel/cmdline` and installkernel command-line input
- GRUB config, EFI loader, and root UUID policy
- kernel, initramfs, and module artifacts
- required package installation state
- NetworkManager, time-sync, syslog, cron, and optional SSH service enablement
- admin user, group membership, shell, and sudoers syntax
- hostname, timezone, locale, and keymap baseline
- Portage profile, `make.conf`, GURU-disabled policy, and pending config-update files
- controller `make secret-check` status and high-risk secret-like target text

## Output

On success, Ansible prints a `status: PASS` report and writes non-secret evidence under:

```text
logs/install-runs/<run-id>/final-checks/reboot-readiness.json
```

The wrapper generates the audit bundle after successful final checks:

```text
logs/install-runs/<run-id>/audit-bundle/
```

The bundle contains secret-scanned local evidence and includes the final reboot readiness report when available.

## Failure Modes

- Missing `ADMIN_USER`: rerun with the admin account configured by `make configure-users`.
- Missing target root or ESP mount: rerun `make mount-target`.
- Missing chroot pseudo-filesystems: rerun `make prepare-chroot`.
- Missing fstab or wrong UUID policy: rerun `make generate-fstab`.
- Missing kernel or initramfs: rerun `make install-kernel`.
- Missing GRUB or EFI files: rerun `make install-bootloader`.
- Missing packages or services: rerun `make install-system-packages` with the same `PROFILE`, `FILESYSTEM`, and `ENABLE_SSH` values.
- Missing admin user or sudoers policy: rerun `make configure-users`.
- Pending Portage config updates: inspect the listed `._cfg` files before reboot.

Do not reboot until final checks pass or a manual recovery note has been recorded.
