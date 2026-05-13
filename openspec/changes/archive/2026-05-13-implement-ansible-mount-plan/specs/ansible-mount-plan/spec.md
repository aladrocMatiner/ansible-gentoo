## ADDED Requirements

### Requirement: Read-only Ansible Mount Plan
The project SHALL provide a Makefile-mediated Ansible mount planning workflow that reports the intended target mount layout without mounting, unmounting, creating directories, partitioning, formatting, or modifying filesystems.

#### Scenario: Require explicit install disk
- **WHEN** the operator runs `make mount-plan` without `INSTALL_DISK`
- **THEN** the workflow SHALL fail before any mount plan is produced
- **AND** `INSTALL_DISK` SHALL NOT have a default value

#### Scenario: Generate ext4 mount plan
- **WHEN** the operator runs `make mount-plan PROFILE=openrc FILESYSTEM=ext4 INSTALL_DISK=/dev/vda`
- **THEN** the workflow SHALL reuse disk detection, install planning, and partition planning safety checks
- **AND** it SHALL report `/mnt/gentoo` as the planned root mountpoint
- **AND** it SHALL report `/mnt/gentoo/boot/efi` as the planned EFI mountpoint
- **AND** it SHALL NOT report Btrfs subvolume mount options as active
- **AND** it SHALL NOT run `mount`, `umount`, `mkdir`, partitioning, formatting, or wiping commands

#### Scenario: Generate Btrfs mount plan
- **WHEN** the operator runs `make mount-plan PROFILE=openrc FILESYSTEM=btrfs INSTALL_DISK=/dev/vda`
- **THEN** the workflow SHALL reuse disk detection, install planning, and partition planning safety checks
- **AND** it SHALL report `/mnt/gentoo` as the planned root mountpoint
- **AND** the planned root mount options SHALL include `subvol=@`
- **AND** it SHALL report planned Btrfs subvolume mountpoints for root, home, var, var log, var cache, and snapshots
- **AND** it SHALL NOT create Btrfs subvolumes or mount filesystems

#### Scenario: Report mountpoint path state
- **WHEN** the operator runs `make mount-plan PROFILE=openrc FILESYSTEM=ext4 INSTALL_DISK=/dev/vda`
- **THEN** the workflow SHALL report whether planned mountpoint paths exist
- **AND** it SHALL report whether planned mountpoint paths are already mountpoints
- **AND** it SHALL NOT create missing paths

#### Scenario: Preserve shared OpenRC and systemd logic
- **WHEN** the operator runs `make mount-plan PROFILE=systemd FILESYSTEM=btrfs INSTALL_DISK=/dev/vda`
- **THEN** the workflow SHALL use the same shared mount planning logic as OpenRC
- **AND** it SHALL vary only profile/init metadata that is genuinely profile-specific
