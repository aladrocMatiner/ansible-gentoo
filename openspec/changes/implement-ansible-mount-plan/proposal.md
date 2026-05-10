# Change: implement-ansible-mount-plan

## Summary
Add a Makefile-mediated, read-only Ansible mount planning workflow for the Gentoo live ISO VM. The workflow reports how the planned target root and EFI filesystem would be mounted for `ext4` and `btrfs` without running `mount`, creating directories, formatting filesystems, or changing host or guest disks.

## Motivation
The project already has read-only disk detection, install planning, and partition planning. Before destructive partitioning, formatting, or real mounting is introduced, operators need a clear mount plan that maps the planned partition layout to future mountpoints and options.

This is especially important because `ext4` and `btrfs` have different root mount behavior. Btrfs must mount the intended root subvolume with `subvol=@` rather than the top-level filesystem.

## Problem Statement
The current workflow can report the intended partition layout, but it does not yet produce a dedicated mount plan. Without this checkpoint, a future mount implementation could accidentally:

- mount the wrong partition at `/mnt/gentoo`,
- omit the Btrfs root subvolume option,
- mount EFI at the wrong path,
- proceed while `/mnt/gentoo` or `/mnt/gentoo/boot/efi` is already occupied,
- duplicate OpenRC and systemd logic that should remain shared.

## Scope
- Add `make mount-plan`.
- Add a wrapper script for running the Ansible mount plan against the live ISO VM.
- Add an Ansible playbook and shared role for read-only mount planning.
- Reuse existing disk detection, install plan, and partition plan roles.
- Support `PROFILE=openrc|systemd`.
- Support `FILESYSTEM=ext4|btrfs`.
- Require explicit `INSTALL_DISK`.
- Report planned root and EFI mountpoints.
- Report planned Btrfs subvolume mountpoints and mount options.
- Detect whether planned mountpoints already exist or are mountpoints.
- Keep all behavior read-only.
- Update documentation, skills, and OpenSpec tasks.

## Non-goals
- Do not run `mount` or `umount`.
- Do not create directories under `/mnt/gentoo`.
- Do not partition, format, wipe, or modify filesystems.
- Do not implement stage3 extraction.
- Do not implement chroot preparation.
- Do not implement destructive `mount-target`.
- Do not implement separate OpenRC and systemd mount logic.

## Safety Requirements
- The workflow must not require or consume `I_UNDERSTAND_THIS_WIPES_DISK` because it is read-only.
- The workflow must not run destructive commands such as `parted`, `sgdisk`, `fdisk`, `wipefs`, `mkfs.*`, `mount`, `umount`, `chroot`, `passwd`, `useradd`, `usermod`, `grub-install`, or `efibootmgr`.
- `INSTALL_DISK` must be explicit and must not have a default.
- VM guest `/dev/vda` is allowed only when explicitly passed as `INSTALL_DISK=/dev/vda` inside the guest VM.
- The workflow must fail closed if the selected disk or descendants are mounted, reusing the partition-plan safety gate.
- The workflow must report existing mountpoint state without creating or altering paths.

## Acceptance Criteria
- `make mount-plan PROFILE=openrc FILESYSTEM=ext4 INSTALL_DISK=/dev/vda` prints a read-only ext4 mount plan.
- `make mount-plan PROFILE=openrc FILESYSTEM=btrfs INSTALL_DISK=/dev/vda` prints a read-only Btrfs mount plan.
- `make mount-plan PROFILE=systemd FILESYSTEM=btrfs INSTALL_DISK=/dev/vda` uses the same shared mount planning logic as OpenRC.
- `make mount-plan` fails when `INSTALL_DISK` is missing.
- The mount plan reports planned root mountpoint `/mnt/gentoo`.
- The mount plan reports planned EFI mountpoint `/mnt/gentoo/boot/efi`.
- For ext4, the root mount uses the root partition without Btrfs subvolume options.
- For Btrfs, the root mount options include `subvol=@`.
- For Btrfs, planned subvolume mountpoints are reported for root, home, var, var log, var cache, and snapshots.
- The workflow reports whether planned mountpoint paths exist and whether they are already mountpoints.
- The workflow does not run `mount`, `umount`, `mkdir`, or any destructive disk command.
- `make ansible-check` validates the new playbook syntax.
- `openspec validate implement-ansible-mount-plan --strict` passes.
- `openspec validate --all --strict` passes.

## Affected Files
- `Makefile`
- `scripts/ansible-mount-plan.sh`
- `scripts/ansible-check.sh`
- `ansible/playbooks/mount-plan.yml`
- `ansible/roles/common/mount_plan/tasks/main.yml`
- `docs/ansible-mount-plan.md`
- `docs/ansible-partition-plan.md`
- `skills/ansible-gentoo-installer.md`
- `skills/gentoo-disk-planning.md`
- `skills/gentoo-stage3-and-chroot.md`
- `skills/makefile-control-plane.md`
- `openspec/changes/implement-ansible-mount-plan/tasks.md`
