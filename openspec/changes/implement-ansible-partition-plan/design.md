# Design: Read-only Ansible Partition Plan

## Overview
This change adds a read-only partition plan target. It is the final planning checkpoint before any future destructive partitioning or formatting target.

The workflow follows the official Gentoo AMD64 Handbook as the baseline and remains compatible with the reuse-first Ansible architecture.

## Operator Flow
Expected commands:

```sh
make vm-start
make vm-bootstrap-ssh
make ansible-live-preflight
make detect-disks
make install-plan PROFILE=openrc FILESYSTEM=ext4 INSTALL_DISK=/dev/vda
make partition-plan PROFILE=openrc FILESYSTEM=ext4 INSTALL_DISK=/dev/vda
make partition-plan PROFILE=openrc FILESYSTEM=btrfs INSTALL_DISK=/dev/vda
make partition-plan PROFILE=systemd FILESYSTEM=btrfs INSTALL_DISK=/dev/vda
```

`partition-plan` is read-only. It does not require `I_UNDERSTAND_THIS_WIPES_DISK=yes`.

## Makefile Target
Add:

- `make partition-plan`: run read-only partition planning.

Rules:

- `INSTALL_DISK` is required.
- `INSTALL_DISK` must not have a default.
- `PROFILE` defaults to `openrc`; valid values are `openrc` and `systemd`.
- `FILESYSTEM` defaults to `ext4`; valid values are `ext4` and `btrfs`.
- The target must use the existing VM SSH discovery wrapper.
- The target must not expose raw `ansible-playbook` as the normal operator workflow.
- The target must fail clearly before running Ansible if `INSTALL_DISK` is empty.

## Ansible Layout
Add:

```text
ansible/
  playbooks/
    partition-plan.yml
  roles/
    common/
      partition_plan/
        tasks/
          main.yml
```

The playbook should call:

1. `common/disk_detection`
2. `common/install_plan`
3. `common/partition_plan`

This keeps OpenRC and systemd behavior shared. Init-specific roles must not participate in disk planning.

## Partition Plan Role
`common/partition_plan` must:

- require `install_disk`,
- require the selected disk to match exactly one detected disk,
- require the selected path type to be `disk`,
- fail if the selected disk, child partition, or nested descendant has mountpoints,
- report existing filesystems and child partitions,
- report whether current data would be destroyed by a later apply step,
- report the planned GPT partition table,
- report the filesystem-specific root layout,
- remain read-only.

## Planned Layout
Common layout:

- partition table: GPT
- partition 1:
  - purpose: EFI system partition
  - size: 512 MiB
  - filesystem: FAT32
  - mountpoint: `/boot/efi`
- partition 2:
  - purpose: root filesystem
  - size: remaining disk
  - mountpoint: `/mnt/gentoo`
- no swap partition

For `FILESYSTEM=ext4`:

- partition 2 filesystem: ext4
- root mountpoint: `/mnt/gentoo`
- no Btrfs subvolumes

For `FILESYSTEM=btrfs`:

- partition 2 filesystem: Btrfs
- root mount options must include `subvol=@`
- planned subvolumes:
  - `@` mounted at `/mnt/gentoo`
  - `@home` mounted at `/mnt/gentoo/home`
  - `@var` mounted at `/mnt/gentoo/var`
  - `@var/log` mounted at `/mnt/gentoo/var/log`
  - `@var/cache` mounted at `/mnt/gentoo/var/cache`
  - `@snapshots` mounted at `/mnt/gentoo/.snapshots`

## Safety Rules
- No destructive commands.
- No partition table writes.
- No filesystem writes.
- No mount or umount.
- No chroot.
- No bootloader changes.
- No service or user changes.
- No default `INSTALL_DISK`.
- No wildcard disk matching.
- Fail closed if selected disk has any mounted partition or nested mounted descendant.
- Fail closed if selected disk identity is ambiguous.

## Documentation
Update:

- `docs/ansible-partition-plan.md`
- `docs/ansible-install-plan.md`
- `skills/ansible-gentoo-installer.md`
- `skills/makefile-control-plane.md`
- `skills/gentoo-disk-planning.md`

Documentation must distinguish `partition-plan` from future destructive `partition` and `format` targets.

## Review Checklist
- Is `INSTALL_DISK` required and never defaulted?
- Are ext4 and Btrfs handled through shared logic?
- Does Btrfs root include `subvol=@`?
- Does the plan fail on mounted selected disk children and nested descendants?
- Are destructive commands absent?
- Does the plan report what would be destroyed?
- Are all operator actions exposed through Makefile targets?
- Does OpenSpec validation pass?
