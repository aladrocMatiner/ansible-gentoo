# Ansible Partition Plan

This workflow generates a read-only partition plan against a booted official Gentoo live ISO target over SSH. It is the checkpoint before any future destructive partitioning or formatting implementation.

Use `ANSIBLE_LIVE_HOST=...` for a real network target. If it is omitted, the wrappers may use the local libvirt VM as the validation target.

It does not partition, format, wipe, mount, unmount, chroot, install packages, create users, change passwords, enable services, or install bootloaders.

After this plan is reviewed, use `make mount-plan PROFILE=... FILESYSTEM=... INSTALL_DISK=...` to inspect the future target mount layout without mounting anything.

## Required State

Run the live ISO preflight and disk detection first:

```sh
make vm-start
make vm-bootstrap-ssh
make ansible-live-preflight
make detect-disks
```

## Required Variables

`INSTALL_DISK` is required and has no default. Inside the libvirt VM, `/dev/vda` is the expected guest disk backed by the project-local qcow2 image. On real network targets, use the explicit disk path reported by `make detect-disks`.

`PROFILE` defaults to `openrc`. Supported values are `openrc` and `systemd`.

`FILESYSTEM` defaults to `ext4`. Supported values are `ext4` and `btrfs`.

## Commands

Generate an ext4 partition plan for the local VM harness:

```sh
make partition-plan PROFILE=openrc FILESYSTEM=ext4 INSTALL_DISK=/dev/vda
```

For a real network target, provide the live ISO address and the target disk discovered from that machine:

```sh
make partition-plan ANSIBLE_LIVE_HOST=192.0.2.10 PROFILE=openrc FILESYSTEM=ext4 INSTALL_DISK=/dev/<target-disk>
```

Generate a Btrfs partition plan for the local VM harness:

```sh
make partition-plan PROFILE=openrc FILESYSTEM=btrfs INSTALL_DISK=/dev/vda
```

Generate a systemd/Btrfs plan through the same shared logic for the local VM harness:

```sh
make partition-plan PROFILE=systemd FILESYSTEM=btrfs INSTALL_DISK=/dev/vda
```

## Output

The plan reports:

- selected disk identity,
- existing child partitions,
- whether existing data would be destroyed by a future apply step,
- partition table type: GPT,
- EFI system partition: 512 MiB, FAT32, `/boot/efi`,
- root partition: remaining disk, `/mnt/gentoo`,
- no swap partition,
- whether confirmation is required now: false,
- whether future destructive apply requires confirmation: true.

For `FILESYSTEM=ext4`, the root partition is planned as ext4.

For `FILESYSTEM=btrfs`, the root partition is planned as Btrfs with root mount options including `subvol=@` and these subvolumes:

- `@` at `/mnt/gentoo`
- `@home` at `/mnt/gentoo/home`
- `@var` at `/mnt/gentoo/var`
- `@var_log` at `/mnt/gentoo/var/log`
- `@var_cache` at `/mnt/gentoo/var/cache`
- `@snapshots` at `/mnt/gentoo/.snapshots`

## Safety

`partition-plan` is read-only and does not require `I_UNDERSTAND_THIS_WIPES_DISK=yes`.

It fails if:

- `INSTALL_DISK` is missing,
- `INSTALL_DISK` is not an explicit safe `/dev/...` path,
- `INSTALL_DISK` does not match exactly one detected disk,
- the selected path is not type `disk`,
- the selected disk has mounted child partitions or nested descendants such as mapped LUKS/LVM devices,
- `PROFILE` is unsupported,
- `FILESYSTEM` is unsupported.

Forbidden commands in this workflow include `parted`, `sgdisk`, `fdisk`, `wipefs`, `mkfs.*`, `mount`, `umount`, `chroot`, `passwd`, `useradd`, `usermod`, `grub-install`, and `efibootmgr`.

## Recovery

If the plan fails, rerun:

```sh
make detect-disks
```

Then pass one exact disk path:

```sh
make partition-plan PROFILE=openrc FILESYSTEM=ext4 INSTALL_DISK=/dev/vda
```

Do not run manual disk commands to recover from a planning failure.
