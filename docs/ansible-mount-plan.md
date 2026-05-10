# Ansible Mount Plan

This workflow generates a read-only mount plan from inside the booted official Gentoo live ISO VM. It is the checkpoint after `partition-plan` and before any future `mount-target` implementation.

It does not mount, unmount, create directories, partition, format, wipe, chroot, install packages, create users, change passwords, enable services, or install bootloaders.

## Required State

Run the live ISO checks and partition plan first:

```sh
make vm-start
make vm-bootstrap-ssh
make ansible-live-preflight
make detect-disks
make partition-plan PROFILE=openrc FILESYSTEM=ext4 INSTALL_DISK=/dev/vda
```

Inside the libvirt VM, `/dev/vda` is the expected guest disk backed by the project-local qcow2 image. It must still be passed explicitly.

## Required Variables

`INSTALL_DISK` is required and has no default.

`PROFILE` defaults to `openrc`. Supported values are `openrc` and `systemd`.

`FILESYSTEM` defaults to `ext4`. Supported values are `ext4` and `btrfs`.

## Commands

Generate an ext4 mount plan:

```sh
make mount-plan PROFILE=openrc FILESYSTEM=ext4 INSTALL_DISK=/dev/vda
```

Generate a Btrfs mount plan:

```sh
make mount-plan PROFILE=openrc FILESYSTEM=btrfs INSTALL_DISK=/dev/vda
```

Generate a systemd/Btrfs plan through the same shared logic:

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
- whether a future `mount-target` needs review: true.

For `FILESYSTEM=ext4`, root is planned as `/dev/vda2` mounted at `/mnt/gentoo` with default options, and EFI is planned as `/dev/vda1` mounted at `/mnt/gentoo/boot/efi`.

For `FILESYSTEM=btrfs`, root is planned with options:

- `noatime`
- `compress=zstd`
- `subvol=@`

The Btrfs plan reports these subvolumes:

- `@` at `/mnt/gentoo`
- `@home` at `/mnt/gentoo/home`
- `@var` at `/mnt/gentoo/var`
- `@var/log` at `/mnt/gentoo/var/log`
- `@var/cache` at `/mnt/gentoo/var/cache`
- `@snapshots` at `/mnt/gentoo/.snapshots`

## Safety

`mount-plan` is read-only and does not require `I_UNDERSTAND_THIS_WIPES_DISK=yes`.

It reuses the partition-plan safety checks and fails if:

- `INSTALL_DISK` is missing,
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
