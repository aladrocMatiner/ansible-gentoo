# Design: implement-ansible-mount-plan

## Overview
`mount-plan` is a read-only planning checkpoint between `partition-plan` and any future destructive or state-changing mount implementation. It should answer: "If the planned partitions and filesystems existed, what would this project mount and with which options?"

The workflow runs from the operator/controller machine through Makefile, connects to a booted official Gentoo live ISO target over SSH, and executes Ansible read-only tasks. The local libvirt VM is one supported validation target, not a role dependency.

## Makefile Integration
Add:

- `make mount-plan`

The target should call `scripts/ansible-mount-plan.sh`.

Required variables:

- `INSTALL_DISK`: required, no default.
- `PROFILE`: defaults to `openrc`, supports `openrc|systemd`.
- `FILESYSTEM`: defaults to `ext4`, supports `ext4|btrfs`.

The help output must document the target and make clear that it is read-only.

## Script Design
Add `scripts/ansible-mount-plan.sh`.

The script should:

- use `bash` with `set -euo pipefail`,
- source `scripts/vm-libvirt-common.sh`,
- require `ansible-playbook`,
- use `ANSIBLE_LIVE_HOST` when an explicit network target is provided,
- fall back to local libvirt VM SSH discovery only for validation when no explicit network target is provided,
- fail clearly if no live ISO SSH target can be determined,
- validate `PROFILE=openrc|systemd`,
- validate `FILESYSTEM=ext4|btrfs`,
- require explicit `INSTALL_DISK`,
- reject unsafe `INSTALL_DISK` values before invoking Ansible: no wildcards, parent traversal, whitespace, shell metacharacters, or Ansible extra-var injection characters,
- run `ansible/playbooks/mount-plan.yml`.

The script must not run raw `ssh` commands beyond existing Ansible transport behavior and must not run disk-changing commands.

## Ansible Playbook Design
Add `ansible/playbooks/mount-plan.yml`.

The playbook should target `gentoo_live` and include shared roles:

1. `common/disk_detection`
2. `common/install_plan`
3. `common/partition_plan`
4. `common/mount_plan`

This preserves reuse-first architecture. OpenRC and systemd must share the same mount planning role.

## Role Design
Add `ansible/roles/common/mount_plan/tasks/main.yml`.

The role should consume:

- `install_disk`
- `install_plan_filesystem`
- `partition_plan_report`

The role should produce:

- `mount_plan_report`

The role should not infer partitions from live device names beyond planning labels. Because actual partitioning has not happened yet, it should report planned partition references derived from `INSTALL_DISK`, such as:

- EFI partition reference: `${INSTALL_DISK} partition 1`
- root partition reference: `${INSTALL_DISK} partition 2`

Future implementation can replace these references with exact partition paths after the partitioning role exists.

## Mountpoint Inspection
The role may inspect path state using Ansible `stat` for:

- `/mnt/gentoo`
- `/mnt/gentoo/boot`
- `/mnt/gentoo/boot/efi`
- Btrfs-specific planned mountpoints when `FILESYSTEM=btrfs`

The role must not create those paths.

To determine whether a path is currently a mountpoint, the role may run read-only `findmnt --mountpoint <path>` with `changed_when: false` and `failed_when: false`.

## ext4 Plan
For `FILESYSTEM=ext4`, report:

- root filesystem: `ext4`
- root mountpoint: `/mnt/gentoo`
- root source: planned root partition
- EFI filesystem: `vfat`
- EFI mountpoint: `/mnt/gentoo/boot/efi`
- no Btrfs subvolumes

## Btrfs Plan
For `FILESYSTEM=btrfs`, report:

- root filesystem: `btrfs`
- root mountpoint: `/mnt/gentoo`
- root source: planned root partition
- root mount options: `noatime`, `compress=zstd`, `subvol=@`
- EFI filesystem: `vfat`
- EFI mountpoint: `/mnt/gentoo/boot/efi`
- planned subvolumes:
  - `@` at `/mnt/gentoo`
  - `@home` at `/mnt/gentoo/home`
  - `@var` at `/mnt/gentoo/var`
  - `@var_log` at `/mnt/gentoo/var/log`
  - `@var_cache` at `/mnt/gentoo/var/cache`
  - `@snapshots` at `/mnt/gentoo/.snapshots`

The root mount options must include `subvol=@`.

## Safety Model
`mount-plan` is read-only.

Allowed read-only commands:

- `lsblk` through reused roles,
- `findmnt` for mountpoint inspection,
- Ansible `stat`.

Forbidden commands:

- `mount`
- `umount`
- `mkdir`
- `parted`
- `sgdisk`
- `fdisk`
- `wipefs`
- `mkfs.*`
- `chroot`
- `passwd`
- `useradd`
- `usermod`
- `grub-install`
- `efibootmgr`

The role must reuse the `partition_plan` safety gate so mounted selected disk descendants still fail closed.

## Documentation
Add `docs/ansible-mount-plan.md`.

Update reusable skills to document:

- `make mount-plan`,
- required variables,
- ext4 and Btrfs behavior,
- read-only safety boundary,
- future separation from destructive `mount-target`.

## Review Checklist
- Is `INSTALL_DISK` required and never defaulted?
- Does `mount-plan` use Makefile as the operator-facing entrypoint?
- Does the Ansible playbook reuse shared roles?
- Is OpenRC/systemd logic shared?
- Does ext4 avoid Btrfs subvolume options?
- Does Btrfs include `subvol=@` for root?
- Are planned mountpoint path states reported without creating paths?
- Are `mount`, `umount`, and `mkdir` absent?
- Are docs and skills updated?
- Do OpenSpec validations pass?
