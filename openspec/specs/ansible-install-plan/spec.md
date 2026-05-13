# ansible-install-plan Specification

## Purpose
TBD - created by archiving change implement-ansible-disk-detection-and-install-plan. Update Purpose after archive.
## Requirements
### Requirement: Read-only Ansible Disk Detection
The project SHALL provide a Makefile-mediated Ansible disk detection workflow that reports visible disks from the booted official Gentoo live ISO without selecting or modifying an install disk.

#### Scenario: Detect disks
- **WHEN** the operator runs `make detect-disks`
- **THEN** the workflow SHALL run a read-only Ansible playbook against the live ISO
- **AND** the workflow SHALL report disk path, type, size, model, serial when available, filesystem, mountpoints, and partition children
- **AND** the workflow SHALL NOT partition, format, wipe, mount, unmount, or otherwise mutate disks
- **AND** the workflow SHALL NOT select or default `install_disk`

### Requirement: Read-only Ansible Install Plan
The project SHALL provide a Makefile-mediated Ansible install plan workflow for OpenRC and systemd that remains read-only.

#### Scenario: Generate profile-aware plan
- **WHEN** the operator runs `make install-plan PROFILE=openrc` or `make install-plan PROFILE=systemd`
- **THEN** the workflow SHALL validate that the profile is supported
- **AND** the workflow SHALL report the selected init system and stage3 variant
- **AND** the workflow SHALL report v1 assumptions for amd64, UEFI, selected filesystem, `gentoo-kernel-bin`, GRUB, NetworkManager, and no LUKS
- **AND** the workflow SHALL report planned partition layout without applying it
- **AND** the workflow SHALL NOT require destructive confirmation variables

#### Scenario: Generate ext4 filesystem plan
- **WHEN** the operator runs `make install-plan PROFILE=openrc FILESYSTEM=ext4`
- **THEN** the workflow SHALL report an EFI system partition and an ext4 root partition
- **AND** it SHALL NOT report Btrfs subvolumes as active planned mounts

#### Scenario: Generate Btrfs filesystem plan
- **WHEN** the operator runs `make install-plan PROFILE=openrc FILESYSTEM=btrfs`
- **THEN** the workflow SHALL report an EFI system partition and a Btrfs root partition
- **AND** it SHALL report planned Btrfs subvolumes for root, home, var, var log, var cache, and snapshots
- **AND** the planned Btrfs root mount options SHALL include `subvol=@`
- **AND** it SHALL NOT create the filesystem or subvolumes

#### Scenario: Preserve explicit install disk selection
- **WHEN** the operator runs `make install-plan PROFILE=openrc INSTALL_DISK=/dev/vda`
- **THEN** the workflow SHALL treat `/dev/vda` as an explicitly provided read-only planning input
- **AND** the workflow SHALL match the disk against detected live ISO block devices
- **AND** the workflow SHALL report matching disk identity
- **AND** the workflow SHALL NOT modify the disk

#### Scenario: No default install disk
- **WHEN** the operator runs `make install-plan PROFILE=openrc` without `INSTALL_DISK`
- **THEN** the workflow SHALL explicitly report that no install disk was selected
- **AND** it SHALL NOT infer a disk from `/dev/vda`, `/dev/sda`, detected order, size, model, or any other heuristic

