# Ansible fstab Generation

`make generate-fstab` writes the target `/mnt/gentoo/etc/fstab` from verified filesystem UUIDs.

It runs from the operator machine over SSH into the official Gentoo live ISO target. It does not partition, format, mount, install packages, install a kernel, install GRUB, create users, enable services, or reboot.

The generated root UUID entries feed the boot command line policy in `docs/boot-kernel-commandline-policy.md`.

## Required State

Run the earlier target setup first:

```sh
make mount-target PROFILE=openrc FILESYSTEM=btrfs INSTALL_DISK=/dev/vda
make stage3-install PROFILE=openrc FILESYSTEM=btrfs
make prepare-chroot PROFILE=openrc FILESYSTEM=btrfs
make configure-portage PROFILE=openrc FILESYSTEM=btrfs
make configure-system PROFILE=openrc FILESYSTEM=btrfs
```

For a real network target, pass `ANSIBLE_LIVE_HOST=...` and use the disk selected from that target's own `make detect-disks` output.

## Command

```sh
make generate-fstab PROFILE=openrc FILESYSTEM=btrfs INSTALL_DISK=/dev/vda
```

For ext4:

```sh
make generate-fstab PROFILE=openrc FILESYSTEM=ext4 INSTALL_DISK=/dev/vda
```

For systemd, use the same shared role with `PROFILE=systemd`.

## Variables

| Variable | Default | Meaning |
| --- | --- | --- |
| `PROFILE` | `openrc` | Selects OpenRC or systemd variant context. |
| `FILESYSTEM` | `ext4` | Must be `ext4` or `btrfs`; determines root fstab entries. |
| `INSTALL_DISK` | none | Required; derives partition 1 as EFI and partition 2 as root. |
| `TARGET_MOUNT` | `/mnt/gentoo` | Must remain `/mnt/gentoo` for the current implementation. |

## Behavior

The shared role:

- verifies the live ISO target and disk identity,
- allows already-mounted descendants only for this target because fstab generation runs after mounting,
- refuses target roots other than `/mnt/gentoo`,
- confirms `/mnt/gentoo` is mounted,
- reads the EFI partition UUID and requires a FAT/vfat filesystem,
- reads the ext4 root UUID with `blkid` when `FILESYSTEM=ext4`,
- reads the Btrfs root UUID with `btrfs filesystem show` when `FILESYSTEM=btrfs`,
- rejects empty, missing, or invalid UUID values,
- writes only `/mnt/gentoo/etc/fstab`,
- preserves one backup at `/mnt/gentoo/etc/fstab.gentoo-ai-installer.bak` when an fstab already exists,
- records evidence under `logs/install-runs/<run-id>/fstab/`.

## Generated Entries

For `FILESYSTEM=ext4`, fstab contains:

- `/` as `ext4` with the verified root UUID,
- `/boot/efi` as `vfat` with the verified EFI UUID.

For `FILESYSTEM=btrfs`, fstab contains:

- `/` with `subvol=@`,
- `/home` with `subvol=@home`,
- `/var` with `subvol=@var`,
- `/var/log` with `subvol=@var_log`,
- `/var/cache` with `subvol=@var_cache`,
- `/.snapshots` with `subvol=@snapshots`,
- `/boot/efi` as `vfat`.

The Btrfs layout must stay aligned with `docs/btrfs-layout-policy.md`.

## Handbook Order

The Gentoo AMD64 Handbook covers fstab during system configuration. This automation may generate fstab once filesystems are created, mounted, and UUIDs exist. Later final checks must still validate fstab before bootloader installation and reboot readiness.

## Safety

This workflow is target-mutating but not disk-destructive. It writes only inside `/mnt/gentoo` and refuses to run without an explicit `INSTALL_DISK`.

Do not edit fstab with ad-hoc commands to recover from failures. Fix the detected disk, mount, UUID, or filesystem state, then rerun `make generate-fstab`.

## Failure Modes

- `INSTALL_DISK` is missing or does not match exactly one detected disk.
- `/mnt/gentoo` is not mounted.
- EFI partition UUID or type cannot be verified.
- Root filesystem UUID cannot be verified.
- `FILESYSTEM` does not match the actual root filesystem.
- Btrfs UUID extraction fails.
- Generated entries do not match the approved ext4 or Btrfs policy.

## Recovery

If UUID validation fails, inspect the target from the live ISO with `blkid`, `lsblk -f`, and for Btrfs `btrfs filesystem show <root-partition>`.

If the target is not mounted, rerun `make mount-target PROFILE=... FILESYSTEM=... INSTALL_DISK=...`.

If an existing fstab was wrong, compare it with `/mnt/gentoo/etc/fstab.gentoo-ai-installer.bak` after the generated file passes validation.
