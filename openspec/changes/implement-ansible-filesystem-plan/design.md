# Design: implement-ansible-filesystem-plan

## Overview
`filesystem-plan` is a read-only checkpoint after `mount-plan` and before any future destructive format operation. It reports what filesystems and Btrfs subvolumes the project would create after partitioning has been applied, but it does not create anything.

The workflow runs from the operator machine through Makefile, connects to the official Gentoo live ISO VM over SSH, and executes Ansible read-only tasks.

## Makefile Integration
Add:

- `make filesystem-plan`

The target calls `scripts/ansible-filesystem-plan.sh`.

Required variables:

- `INSTALL_DISK`: required, no default.
- `PROFILE`: defaults to `openrc`, supports `openrc|systemd`.
- `FILESYSTEM`: defaults to `ext4`, supports `ext4|btrfs`.

The help output must document the target and make clear that it is read-only.

## Script Design
Add `scripts/ansible-filesystem-plan.sh`.

The script should:

- use `bash` with `set -euo pipefail`,
- source `scripts/vm-libvirt-common.sh`,
- require `ansible-playbook`,
- validate `PROFILE=openrc|systemd`,
- validate `FILESYSTEM=ext4|btrfs`,
- require explicit `INSTALL_DISK`,
- reject wildcard characters in `INSTALL_DISK`,
- validate libvirt VM configuration,
- discover VM SSH target through `scripts/vm-ssh-target.sh env`,
- fail at SSH discovery if the VM is not reachable or has no target,
- run `ansible/playbooks/filesystem-plan.yml`.

## Ansible Playbook Design
Add `ansible/playbooks/filesystem-plan.yml`.

The playbook should target `gentoo_live` and include shared roles:

1. `common/disk_detection`
2. `common/install_plan`
3. `common/partition_plan`
4. `common/mount_plan`
5. `common/filesystem_plan`

This preserves reuse-first architecture. OpenRC and systemd must share the same filesystem planning role.

## Role Design
Add `ansible/roles/common/filesystem_plan/tasks/main.yml`.

The role should consume:

- `install_disk`
- `install_plan_filesystem`
- `partition_plan_report`
- `mount_plan_report`

The role should produce:

- `filesystem_plan_report`

The role should derive planned partition paths from `mount_plan_report`:

- EFI partition source from `mount_plan_report.planned_partitions.efi.source`
- root partition source from `mount_plan_report.planned_partitions.root.source`

## Existing State Inspection
The role may inspect planned partition paths with read-only tools:

- `stat` to see whether the planned device path exists,
- `lsblk --json` to report current filesystem, UUID, type, and mountpoints when the path exists,
- `findmnt --source <path>` to report whether a planned path is mounted.

The role must tolerate planned partition paths that do not yet exist, because `filesystem-plan` may run before destructive partitioning is implemented.

## ext4 Plan
For `FILESYSTEM=ext4`, report:

- EFI partition: `vfat`, label policy `EFI`, future format target partition 1.
- root partition: `ext4`, future format target partition 2.
- Btrfs subvolumes: empty list.
- format commands: not run.

## Btrfs Plan
For `FILESYSTEM=btrfs`, report:

- EFI partition: `vfat`, label policy `EFI`, future format target partition 1.
- root partition: `btrfs`, future format target partition 2.
- Btrfs subvolumes:
  - `@`
  - `@home`
  - `@var`
  - `@var/log`
  - `@var/cache`
  - `@snapshots`
- format commands: not run.
- subvolume commands: not run.

## Safety Model
`filesystem-plan` is read-only.

Allowed read-only commands:

- `lsblk`
- `findmnt`
- Ansible `stat`

Forbidden commands:

- `mkfs.*`
- `wipefs`
- `parted`
- `sgdisk`
- `fdisk`
- `mount`
- `umount`
- `mkdir`
- `btrfs subvolume create`
- `chroot`
- `passwd`
- `useradd`
- `usermod`
- `grub-install`
- `efibootmgr`

The role must reuse the earlier planning roles so selected disk and mounted-descendant safety checks remain consistent.

## Documentation
Add `docs/ansible-filesystem-plan.md`.

Update reusable docs and skills to document:

- `make filesystem-plan`,
- required variables,
- ext4 and Btrfs behavior,
- read-only safety boundary,
- future separation from destructive `format`.

## Review Checklist
- Is `INSTALL_DISK` required and never defaulted?
- Does `filesystem-plan` use Makefile as the operator-facing entrypoint?
- Does the Ansible playbook reuse shared roles?
- Is OpenRC/systemd logic shared?
- Does ext4 report no Btrfs subvolumes?
- Does Btrfs report all planned subvolumes?
- Are existing partition filesystem states reported without formatting?
- Are `mkfs.*`, `wipefs`, `mount`, `umount`, and `mkdir` absent?
- Are docs and skills updated?
- Do OpenSpec validations pass?
