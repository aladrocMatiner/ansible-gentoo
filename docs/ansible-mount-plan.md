# Ansible Mount Plan

This workflow generates a read-only mount plan against a booted official Gentoo live ISO target over SSH. It is the checkpoint after `partition-plan` and before `make mount-target`.

Use `ANSIBLE_LIVE_HOST=...` for a real network target. If it is omitted, the wrappers may use the local libvirt VM as the validation target.

It does not mount, unmount, create directories, partition, format, wipe, chroot, install packages, create users, change passwords, enable services, or install bootloaders.

After this plan is reviewed, use `make filesystem-plan PROFILE=... FILESYSTEM=... INSTALL_DISK=...` to inspect the future filesystem creation plan without formatting anything.

## Required State

Run the live ISO checks and partition plan first:

```sh
make vm-start
make vm-bootstrap-ssh
make ansible-live-preflight
make detect-disks
make partition-plan PROFILE=openrc FILESYSTEM=ext4 INSTALL_DISK=/dev/vda
```

Inside the libvirt VM, `/dev/vda` is the expected guest disk backed by the project-local qcow2 image. It must still be passed explicitly. On real network targets, use the disk path reported by `make detect-disks`.

## Required Variables

`INSTALL_DISK` is required and has no default.

`PROFILE` defaults to `openrc`. Supported values are `openrc` and `systemd`.

`FILESYSTEM` defaults to `ext4`. Supported values are `ext4` and `btrfs`.

## Commands

Generate an ext4 mount plan for the local VM harness:

```sh
make mount-plan PROFILE=openrc FILESYSTEM=ext4 INSTALL_DISK=/dev/vda
```

For a real network target:

```sh
make mount-plan ANSIBLE_LIVE_HOST=192.0.2.10 PROFILE=openrc FILESYSTEM=ext4 INSTALL_DISK=/dev/<target-disk>
```

Generate a Btrfs mount plan for the local VM harness:

```sh
make mount-plan PROFILE=openrc FILESYSTEM=btrfs INSTALL_DISK=/dev/vda
```

Generate an amd64 systemd/Btrfs plan through the same shared logic for the local VM harness:

```sh
make mount-plan PROFILE=systemd FILESYSTEM=btrfs INSTALL_DISK=/dev/vda
```

## Output

The plan reports:

- selected disk identity,
- planned root source partition,
- planned EFI source partition,
- root mountpoint `/mnt/gentoo`,
- EFI mountpoint `/mnt/gentoo/boot/efi`,
- mount options,
- whether planned mountpoint paths exist,
- whether planned mountpoint paths are already mountpoints,
- whether confirmation is required now: false,
- `mount_target_requires_review: true`, meaning `make mount-target` should only run after the plan has been reviewed.

For `FILESYSTEM=ext4`, the root partition is planned as partition 2 of the explicit `INSTALL_DISK` mounted at `/mnt/gentoo` with default options, and EFI is planned as partition 1 mounted at `/mnt/gentoo/boot/efi`. In the local VM examples, those paths are `/dev/vda2` and `/dev/vda1`.

For `FILESYSTEM=btrfs`, root is planned with options:

- `noatime`
- `compress=zstd`
- `subvol=@`

The Btrfs plan reports these subvolumes:

- `@` at `/mnt/gentoo`
- `@home` at `/mnt/gentoo/home`
- `@var` at `/mnt/gentoo/var`
- `@var_log` at `/mnt/gentoo/var/log`
- `@var_cache` at `/mnt/gentoo/var/cache`
- `@snapshots` at `/mnt/gentoo/.snapshots`

These names and mountpoints are shared policy, documented in `docs/btrfs-layout-policy.md`. The `mount-target`, fstab, and final-check workflows must use the same policy and verify that root is mounted with `subvol=@`.

## Safety

`mount-plan` is read-only and does not require `I_UNDERSTAND_THIS_WIPES_DISK=yes`.

It reuses the partition-plan safety checks and fails if:

- `INSTALL_DISK` is missing,
- `INSTALL_DISK` is not an explicit safe `/dev/...` path,
- `INSTALL_DISK` does not match exactly one detected disk,
- the selected path is not type `disk`,
- the selected disk has mounted child partitions or nested descendants,
- `PROFILE` is unsupported,
- `FILESYSTEM` is unsupported.

Allowed read-only inspection includes `lsblk`, Ansible `stat`, and `findmnt`.

Forbidden commands in this workflow include `parted`, `sgdisk`, `fdisk`, `wipefs`, `mkfs.*`, `mount`, `umount`, `mkdir`, `chroot`, `passwd`, `useradd`, `usermod`, `grub-install`, and `efibootmgr`.

## Recovery

If the plan fails, rerun:

```sh
make detect-disks
make partition-plan PROFILE=openrc FILESYSTEM=ext4 INSTALL_DISK=/dev/vda
```

Then rerun:

```sh
make mount-plan PROFILE=openrc FILESYSTEM=ext4 INSTALL_DISK=/dev/vda
```

Do not create directories or run manual mount commands to recover from a planning failure.
