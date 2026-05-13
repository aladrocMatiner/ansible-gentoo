# ansible-partition-plan Specification

## Purpose
TBD - created by archiving change implement-ansible-partition-plan. Update Purpose after archive.
## Requirements
### Requirement: Read-only Ansible Partition Plan
The project SHALL provide a Makefile-mediated Ansible partition planning workflow that reports the exact intended disk layout without modifying disks.

#### Scenario: Require explicit install disk
- **WHEN** the operator runs `make partition-plan` without `INSTALL_DISK`
- **THEN** the workflow SHALL fail before any partition plan is produced
- **AND** `INSTALL_DISK` SHALL NOT have a default value

#### Scenario: Generate ext4 partition plan
- **WHEN** the operator runs `make partition-plan PROFILE=openrc FILESYSTEM=ext4 INSTALL_DISK=/dev/vda`
- **THEN** the workflow SHALL match `/dev/vda` against detected live ISO disks
- **AND** it SHALL report a GPT plan with a 512 MiB EFI system partition and an ext4 root partition using the remaining disk
- **AND** it SHALL report that no swap partition is planned
- **AND** it SHALL NOT write a partition table, format a filesystem, mount filesystems, or require destructive confirmation variables

#### Scenario: Generate Btrfs partition plan
- **WHEN** the operator runs `make partition-plan PROFILE=openrc FILESYSTEM=btrfs INSTALL_DISK=/dev/vda`
- **THEN** the workflow SHALL match `/dev/vda` against detected live ISO disks
- **AND** it SHALL report a GPT plan with a 512 MiB EFI system partition and a Btrfs root partition using the remaining disk
- **AND** it SHALL report planned Btrfs subvolumes for root, home, var, var log, var cache, and snapshots
- **AND** the planned Btrfs root mount options SHALL include `subvol=@`
- **AND** it SHALL NOT create a Btrfs filesystem or subvolumes

#### Scenario: Fail on mounted selected disk descendants
- **WHEN** the selected `INSTALL_DISK`, any child partition, or any nested descendant has mountpoints
- **THEN** the workflow SHALL fail closed
- **AND** it SHALL report the mounted paths that must be reviewed before destructive work is considered

#### Scenario: Preserve shared OpenRC and systemd logic
- **WHEN** the operator runs `make partition-plan PROFILE=systemd FILESYSTEM=btrfs INSTALL_DISK=/dev/vda`
- **THEN** the workflow SHALL use the same shared disk detection and partition planning logic as OpenRC
- **AND** it SHALL vary only profile/init metadata that is genuinely profile-specific

