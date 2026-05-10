# Ansible Filesystem Plan

This workflow generates a read-only filesystem plan against a booted official Gentoo live ISO target over SSH. It is the checkpoint after `mount-plan` and before any future destructive `format` implementation.

Use `ANSIBLE_LIVE_HOST=...` for a real network target. If it is omitted, the wrappers may use the local libvirt VM as the validation target.

It does not format, wipe, partition, mount, unmount, create directories, create Btrfs subvolumes, chroot, install packages, create users, change passwords, enable services, or install bootloaders.

## Required State

Run the live ISO checks and earlier plans first:

```sh
make vm-start
make vm-bootstrap-ssh
make ansible-live-preflight
make detect-disks
make partition-plan PROFILE=openrc FILESYSTEM=ext4 INSTALL_DISK=/dev/vda
make mount-plan PROFILE=openrc FILESYSTEM=ext4 INSTALL_DISK=/dev/vda
```

Inside the libvirt VM, `/dev/vda` is the expected guest disk backed by the project-local qcow2 image. It must still be passed explicitly. On real network targets, use the disk path reported by `make detect-disks`.

## Required Variables

`INSTALL_DISK` is required and has no default.

`PROFILE` defaults to `openrc`. Supported values are `openrc` and `systemd`.

`FILESYSTEM` defaults to `ext4`. Supported values are `ext4` and `btrfs`.

## Commands

Generate an ext4 filesystem plan for the local VM harness:

```sh
make filesystem-plan PROFILE=openrc FILESYSTEM=ext4 INSTALL_DISK=/dev/vda
```

For a real network target:

```sh
make filesystem-plan ANSIBLE_LIVE_HOST=192.0.2.10 PROFILE=openrc FILESYSTEM=ext4 INSTALL_DISK=/dev/<target-disk>
```

Generate a Btrfs filesystem plan for the local VM harness:

```sh
make filesystem-plan PROFILE=openrc FILESYSTEM=btrfs INSTALL_DISK=/dev/vda
```

Generate a systemd/Btrfs plan through the same shared logic for the local VM harness:

```sh
make filesystem-plan PROFILE=systemd FILESYSTEM=btrfs INSTALL_DISK=/dev/vda
```

## Output

The plan reports:

- selected disk identity,
- planned EFI partition source,
- planned root partition source,
- planned EFI filesystem `vfat`,
- planned root filesystem `ext4` or `btrfs`,
- planned future command family, such as `mkfs.vfat`, `mkfs.ext4`, or `mkfs.btrfs`,
- whether planned partition paths currently exist,
- current block state from `lsblk` when a planned path exists,
- whether planned partition paths are mounted,
- whether confirmation is required now: false,
- whether a future format target requires confirmation: true.

For `FILESYSTEM=ext4`, the plan reports no Btrfs subvolumes.

For `FILESYSTEM=btrfs`, the plan reports these subvolumes for future creation after the Btrfs filesystem exists:

- `@` at `/mnt/gentoo`
- `@home` at `/mnt/gentoo/home`
- `@var` at `/mnt/gentoo/var`
- `@var_log` at `/mnt/gentoo/var/log`
- `@var_cache` at `/mnt/gentoo/var/cache`
- `@snapshots` at `/mnt/gentoo/.snapshots`

This mapping is defined by the shared Btrfs layout policy in `docs/btrfs-layout-policy.md`. Future destructive formatting must consume the same policy and must not create OpenRC/systemd-specific Btrfs layouts.

## Safety

`filesystem-plan` is read-only and does not require `I_UNDERSTAND_THIS_WIPES_DISK=yes`.

It reuses the earlier planning checks and fails if:

- `INSTALL_DISK` is missing,
- `INSTALL_DISK` is not an explicit safe `/dev/...` path,
- `INSTALL_DISK` does not match exactly one detected disk,
- the selected path is not type `disk`,
- the selected disk has mounted child partitions or nested descendants,
- `PROFILE` is unsupported,
- `FILESYSTEM` is unsupported.

Allowed read-only inspection includes `lsblk`, Ansible `stat`, and `findmnt`.

Forbidden commands in this workflow include `parted`, `sgdisk`, `fdisk`, `wipefs`, `mkfs.*`, `mount`, `umount`, `mkdir`, `btrfs subvolume create`, `chroot`, `passwd`, `useradd`, `usermod`, `grub-install`, and `efibootmgr`.

## Recovery

If the plan fails, rerun the earlier read-only checks:

```sh
make detect-disks
make partition-plan PROFILE=openrc FILESYSTEM=ext4 INSTALL_DISK=/dev/vda
make mount-plan PROFILE=openrc FILESYSTEM=ext4 INSTALL_DISK=/dev/vda
```

Then rerun:

```sh
make filesystem-plan PROFILE=openrc FILESYSTEM=ext4 INSTALL_DISK=/dev/vda
```

Do not run manual formatting, wipe, mount, or Btrfs subvolume commands to recover from a planning failure.
