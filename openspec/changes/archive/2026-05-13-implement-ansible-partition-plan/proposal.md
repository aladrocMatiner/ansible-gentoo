# implement-ansible-partition-plan

## Summary
Add a read-only Ansible partition planning workflow for a booted Gentoo live ISO target over SSH.

The workflow requires an explicit `INSTALL_DISK`, validates that the disk is visible and safe to plan against, and prints the exact GPT partition plan for `FILESYSTEM=ext4` and `FILESYSTEM=btrfs` without writing to the disk.

## Motivation
The project can currently detect disks and produce a read-only install plan. Before introducing destructive partitioning or formatting, operators need a stricter partition-specific plan that shows:

- the selected disk identity,
- existing partitions, filesystems, and mountpoints,
- what data would be destroyed by a later apply step,
- the exact partition layout that would be created,
- filesystem-specific root layout details for ext4 and Btrfs.

This creates a reviewable safety checkpoint before any destructive Ansible task exists.

## Problem Statement
The install plan proves high-level intent, but it is not precise enough to be used as the immediate predecessor to a destructive `partition` target. The project needs a Makefile-mediated `partition-plan` target that:

- refuses to run without explicit `INSTALL_DISK`,
- refuses unsupported `PROFILE` or `FILESYSTEM` values,
- reuses shared disk detection and planning logic,
- fails closed when the selected disk is missing, not a disk, or has mounted partitions,
- reports the exact partition plan while remaining read-only.

## Scope
- Add an OpenSpec-approved read-only `make partition-plan` workflow.
- Add a shared `common/partition_plan` Ansible role later during implementation.
- Reuse `common/disk_detection` and `common/install_plan`.
- Support `FILESYSTEM=ext4` and `FILESYSTEM=btrfs`.
- Support OpenRC and systemd profiles through shared variables.
- Document the target, variables, safety boundary, and failure modes.

## Non-goals
- Do not partition disks.
- Do not format filesystems.
- Do not wipe existing signatures.
- Do not mount target filesystems.
- Do not create Btrfs filesystems or subvolumes.
- Do not extract stage3.
- Do not chroot.
- Do not install packages, kernels, users, services, or bootloaders.
- Do not implement `make partition` or `make format`.
- Do not add LUKS, BIOS boot, custom ISO, graphical desktop, swap partition, or separate `/home` partition support.

## Safety Considerations
- `INSTALL_DISK` is required and must not have a default.
- `FILESYSTEM` may default to `ext4`; supported values are `ext4` and `btrfs`.
- `PROFILE` may default to `openrc`; supported values are `openrc` and `systemd`.
- The workflow must not require or consume `I_UNDERSTAND_THIS_WIPES_DISK` because it is read-only.
- The workflow must not run destructive commands such as `parted`, `sgdisk`, `fdisk`, `wipefs`, `mkfs.*`, `mount`, `umount`, `chroot`, `passwd`, `useradd`, `usermod`, `grub-install`, or `efibootmgr`.
- VM guest `/dev/vda` is allowed only when explicitly passed as `INSTALL_DISK=/dev/vda` inside the guest VM. Real network targets must use disk paths reported by `make detect-disks`.
- If mounted partitions or nested descendants exist on the selected disk, the plan must fail closed.
- If the selected disk cannot be matched exactly to one detected disk, the plan must fail closed.

## Acceptance Criteria
- `make partition-plan PROFILE=openrc FILESYSTEM=ext4 INSTALL_DISK=/dev/vda` prints a read-only ext4 partition plan.
- `make partition-plan PROFILE=openrc FILESYSTEM=btrfs INSTALL_DISK=/dev/vda` prints a read-only Btrfs partition and subvolume plan.
- `make partition-plan PROFILE=systemd FILESYSTEM=btrfs INSTALL_DISK=/dev/vda` prints a read-only amd64 systemd/Btrfs plan through shared logic for the local VM harness.
- `make partition-plan` fails when `INSTALL_DISK` is missing.
- `make partition-plan ANSIBLE_LIVE_HOST=... INSTALL_DISK=...` works without requiring libvirt VM discovery.
- The partition plan reports selected disk path, type, size, model, serial when available, current filesystems, current mountpoints, current children, and nested descendants.
- The partition plan reports what would be destroyed by a future destructive apply step.
- The partition plan reports GPT layout:
  - partition 1: EFI system partition, 512 MiB, FAT32, mounted at `/boot/efi`;
  - partition 2: root partition, remaining disk;
  - no swap partition.
- For `FILESYSTEM=ext4`, partition 2 is planned as ext4 mounted at `/mnt/gentoo`.
- For `FILESYSTEM=btrfs`, partition 2 is planned as Btrfs mounted with `subvol=@`, with planned subvolumes for root, home, var, var log, var cache, and snapshots.
- The implementation uses shared Ansible roles and does not duplicate OpenRC/systemd logic.
- OpenSpec validation passes with `openspec validate implement-ansible-partition-plan --strict`.
- Full validation passes with `openspec validate --all --strict`.

## Affected Files
- `Makefile`
- `ansible/playbooks/partition-plan.yml`
- `ansible/roles/common/partition_plan/`
- `scripts/ansible-partition-plan.sh`
- `docs/ansible-partition-plan.md`
- `docs/ansible-install-plan.md`
- `skills/ansible-gentoo-installer.md`
- `skills/makefile-control-plane.md`
- `skills/gentoo-disk-planning.md`
- `agents/safety-review-agent.md`
- `openspec/changes/implement-ansible-partition-plan/`
