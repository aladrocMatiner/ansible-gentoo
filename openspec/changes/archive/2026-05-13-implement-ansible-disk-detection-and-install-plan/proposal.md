# implement-ansible-disk-detection-and-install-plan

## Summary
Add the first read-only Ansible install planning workflow for a booted official Gentoo live ISO target over SSH.

The workflow detects disks, reports disk identity, and generates an operator-readable basic console install plan for OpenRC or systemd without partitioning, formatting, mounting target filesystems, extracting stage3, or installing Gentoo.

## Motivation
The project can boot the official Gentoo live ISO under libvirt, bootstrap temporary SSH, and run a read-only Ansible live preflight. It can also target an explicit network-reachable live ISO through `ANSIBLE_LIVE_HOST`. The next safe step is to inspect disks through reusable Ansible roles and produce a plan before any destructive installer work exists.

Disk identity and install plan output are prerequisites for later partitioning, filesystem creation, stage3 installation, chroot work, and bootloader work.

## Problem Statement
Future automation must not infer or default an install disk. Operators need a Makefile-mediated way to:

- list visible disks from inside the live ISO,
- confirm the expected target disk from live ISO disk detection,
- see whether a specific `INSTALL_DISK` was explicitly provided,
- produce a profile-aware OpenRC or systemd plan,
- keep all behavior read-only until a later approved destructive change.

## Scope
- Add read-only Ansible disk detection using shared/common roles.
- Add read-only Ansible install plan generation for `PROFILE=openrc` and `PROFILE=systemd`.
- Add read-only filesystem plan selection for `FILESYSTEM=ext4` and `FILESYSTEM=btrfs`.
- Add Makefile targets for `make ansible-check`, `make detect-disks`, and `make install-plan`.
- Support explicit network live ISO targets and keep VM SSH discovery as a local validation fallback.
- Document the new operator workflow.
- Keep implementation aligned with the official Gentoo AMD64 Handbook baseline and the reuse-first Ansible architecture.

## Non-goals
- Do not partition, format, wipe, or overwrite disks.
- Do not mount target filesystems.
- Do not extract stage3.
- Do not chroot.
- Do not install packages, kernels, users, services, or bootloaders.
- Do not automate a full Gentoo installation.
- Do not add LUKS, BIOS boot, custom ISO, or graphical desktop support.
- Do not implement Btrfs formatting or subvolume creation yet; only plan the layout.

## Safety Considerations
- `INSTALL_DISK` must not have a default.
- `make detect-disks` must not select an install disk.
- `make install-plan` may accept `INSTALL_DISK`, but must clearly report when it is unset.
- Any provided `INSTALL_DISK` is used only for read-only identity matching in this change.
- The workflow must not require or consume `I_UNDERSTAND_THIS_WIPES_DISK`.
- The workflow must not run destructive commands such as `parted`, `sgdisk`, `fdisk`, `wipefs`, `mkfs.*`, `mount`, `umount`, `chroot`, `passwd`, `useradd`, `usermod`, `grub-install`, or `efibootmgr`.
- VM guest `/dev/vda` is allowed only when explicitly passed as `INSTALL_DISK=/dev/vda` inside the guest VM context. Real network targets must use disk paths reported by `make detect-disks`.

## Acceptance Criteria
- `make ansible-check` validates Ansible availability and syntax for the implemented live ISO playbooks.
- `make detect-disks` runs a read-only Ansible disk detection playbook against the live ISO.
- `make detect-disks` reports disk path, model, serial when available, size, type, filesystem, mountpoints, and partition children.
- `make detect-disks ANSIBLE_LIVE_HOST=...` works without requiring libvirt VM discovery.
- `make install-plan PROFILE=openrc` produces a read-only OpenRC plan and does not default `INSTALL_DISK`.
- `make install-plan PROFILE=systemd` produces a read-only systemd plan and does not default `INSTALL_DISK`.
- `make install-plan PROFILE=openrc FILESYSTEM=ext4` reports the ext4 root filesystem plan.
- `make install-plan PROFILE=openrc FILESYSTEM=btrfs` reports the Btrfs root filesystem and planned subvolumes.
- `make install-plan PROFILE=... INSTALL_DISK=/dev/vda` reports matching disk identity without modifying `/dev/vda`.
- The implementation uses shared roles for disk detection and install planning.
- Documentation explains the new targets, `PROFILE`, optional `INSTALL_DISK`, and read-only safety boundary.
- OpenSpec validation passes with `openspec validate implement-ansible-disk-detection-and-install-plan --strict`.
- Full validation passes with `openspec validate --all --strict`.

## Affected Files
- `Makefile`
- `ansible/`
- `scripts/`
- `docs/ansible-install-plan.md`
- `docs/ansible-live-preflight.md`
- `skills/ansible-gentoo-installer.md`
- `skills/makefile-control-plane.md`
- `skills/gentoo-disk-planning.md`
- `openspec/changes/implement-ansible-disk-detection-and-install-plan/`
