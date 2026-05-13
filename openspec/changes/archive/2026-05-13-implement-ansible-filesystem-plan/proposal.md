# Change: implement-ansible-filesystem-plan

## Summary
Add a Makefile-mediated, read-only Ansible filesystem planning workflow. The workflow reports the exact filesystems that a future destructive format step would create for the planned Gentoo installation, including ext4 and Btrfs variants, without running `mkfs.*`, partitioning, mounting, or modifying disks.

## Motivation
The project now has read-only disk detection, install planning, partition planning, and mount planning. Before introducing any destructive formatting target, operators need a dedicated filesystem plan that shows what would be formatted and how existing filesystem state would be treated.

This keeps the project aligned with the Gentoo AMD64 Handbook while preserving the safety-first, Makefile-mediated workflow.

## Problem Statement
The current plans show the intended partition and mount layout, but they do not yet provide a focused filesystem-format checkpoint. Without this, a future format implementation could accidentally:

- format a partition whose current filesystem was not reported,
- omit the EFI FAT32 filesystem,
- choose the wrong root filesystem,
- create an incomplete Btrfs subvolume plan,
- ignore mounted existing filesystems,
- duplicate ext4/Btrfs logic across OpenRC and systemd flows.

## Scope
- Add `make filesystem-plan`.
- Add a wrapper script for running the Ansible filesystem plan against a live ISO target over SSH.
- Add an Ansible playbook and shared role for read-only filesystem planning.
- Reuse existing disk detection, install plan, partition plan, and mount plan roles.
- Support `PROFILE=openrc|systemd`.
- Support `FILESYSTEM=ext4|btrfs`.
- Require explicit `INSTALL_DISK`.
- Report planned EFI filesystem as FAT32/vfat.
- Report planned root filesystem as ext4 or Btrfs.
- Report planned Btrfs subvolumes when `FILESYSTEM=btrfs`.
- Report current filesystem state for planned partition paths if they already exist.
- Report whether planned partition paths are mounted.
- Keep all behavior read-only.
- Update documentation, skills, and OpenSpec tasks.

## Non-goals
- Do not run `mkfs.*`.
- Do not partition, format, wipe, mount, unmount, or create directories.
- Do not create Btrfs subvolumes.
- Do not implement destructive `format`.
- Do not implement `mount-target`.
- Do not implement stage3 extraction or chroot preparation.
- Do not duplicate OpenRC and systemd filesystem logic.

## Safety Requirements
- The workflow must not require or consume `I_UNDERSTAND_THIS_WIPES_DISK` because it is read-only.
- The workflow must not run destructive commands such as `parted`, `sgdisk`, `fdisk`, `wipefs`, `mkfs.*`, `mount`, `umount`, `mkdir`, `chroot`, `passwd`, `useradd`, `usermod`, `grub-install`, or `efibootmgr`.
- `INSTALL_DISK` must be explicit and must not have a default.
- VM guest `/dev/vda` is allowed only when explicitly passed as `INSTALL_DISK=/dev/vda` inside the guest VM.
- Real network targets must use disk paths reported by `make detect-disks`.
- The workflow must reuse selected disk and mount safety checks from earlier planning roles.
- The workflow must fail closed if the selected disk or descendants are mounted.
- Future destructive formatting must require a separate approved OpenSpec change and explicit confirmation.

## Acceptance Criteria
- `make filesystem-plan PROFILE=openrc FILESYSTEM=ext4 INSTALL_DISK=/dev/vda` prints a read-only ext4 filesystem plan.
- `make filesystem-plan PROFILE=openrc FILESYSTEM=btrfs INSTALL_DISK=/dev/vda` prints a read-only Btrfs filesystem plan.
- `make filesystem-plan PROFILE=systemd FILESYSTEM=btrfs INSTALL_DISK=/dev/vda` uses the same shared filesystem planning logic as OpenRC.
- `make filesystem-plan` fails when `INSTALL_DISK` is missing.
- `make filesystem-plan ANSIBLE_LIVE_HOST=... INSTALL_DISK=...` works without requiring libvirt VM discovery.
- The filesystem plan reports planned EFI filesystem `vfat`/FAT32 on partition 1.
- The filesystem plan reports planned root filesystem `ext4` or `btrfs` on partition 2.
- The Btrfs plan reports planned subvolumes for root, home, var, var log, var cache, and snapshots.
- The workflow reports current filesystem state for planned partition paths when they exist.
- The workflow reports whether planned partition paths are mounted.
- The workflow does not run `mkfs.*`, `mount`, `umount`, `mkdir`, partitioning, formatting, or wiping commands.
- `make ansible-check` validates the new playbook syntax.
- `openspec validate implement-ansible-filesystem-plan --strict` passes.
- `openspec validate --all --strict` passes.

## Affected Files
- `Makefile`
- `scripts/ansible-filesystem-plan.sh`
- `scripts/ansible-check.sh`
- `ansible/playbooks/filesystem-plan.yml`
- `ansible/roles/common/filesystem_plan/tasks/main.yml`
- `docs/ansible-filesystem-plan.md`
- `docs/ansible-mount-plan.md`
- `docs/ansible-architecture.md`
- `skills/ansible-gentoo-installer.md`
- `skills/gentoo-disk-planning.md`
- `skills/gentoo-stage3-and-chroot.md`
- `skills/makefile-control-plane.md`
- `openspec/changes/implement-ansible-filesystem-plan/tasks.md`
