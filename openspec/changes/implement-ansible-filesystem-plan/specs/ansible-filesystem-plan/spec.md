## ADDED Requirements

### Requirement: Read-only Ansible Filesystem Plan
The project SHALL provide a Makefile-mediated Ansible filesystem planning workflow that reports the intended filesystem creation plan without running filesystem creation, mounting, unmounting, partitioning, wiping, or directory creation commands.

#### Scenario: Require explicit install disk
- **WHEN** the operator runs `make filesystem-plan` without `INSTALL_DISK`
- **THEN** the workflow SHALL fail before any filesystem plan is produced
- **AND** `INSTALL_DISK` SHALL NOT have a default value

#### Scenario: Generate ext4 filesystem plan
- **WHEN** the operator runs `make filesystem-plan PROFILE=openrc FILESYSTEM=ext4 INSTALL_DISK=/dev/vda`
- **THEN** the workflow SHALL reuse disk detection, install planning, partition planning, and mount planning safety checks
- **AND** it SHALL report planned EFI filesystem `vfat` for partition 1
- **AND** it SHALL report planned root filesystem `ext4` for partition 2
- **AND** it SHALL report no active Btrfs subvolume creation plan
- **AND** it SHALL NOT run `mkfs.*`, `wipefs`, `mount`, `umount`, `mkdir`, partitioning, formatting, or wiping commands

#### Scenario: Generate Btrfs filesystem plan
- **WHEN** the operator runs `make filesystem-plan PROFILE=openrc FILESYSTEM=btrfs INSTALL_DISK=/dev/vda`
- **THEN** the workflow SHALL reuse disk detection, install planning, partition planning, and mount planning safety checks
- **AND** it SHALL report planned EFI filesystem `vfat` for partition 1
- **AND** it SHALL report planned root filesystem `btrfs` for partition 2
- **AND** it SHALL report planned Btrfs subvolumes for root, home, var, var log, var cache, and snapshots
- **AND** it SHALL NOT create filesystems or Btrfs subvolumes

#### Scenario: Report current planned partition state
- **WHEN** planned partition device paths exist
- **THEN** the workflow SHALL report current filesystem type, UUID, and mountpoints where available
- **AND** it SHALL report whether planned partition paths are mounted
- **AND** it SHALL NOT modify the partition state

#### Scenario: Preserve shared OpenRC and systemd logic
- **WHEN** the operator runs `make filesystem-plan PROFILE=systemd FILESYSTEM=btrfs INSTALL_DISK=/dev/vda`
- **THEN** the workflow SHALL use the same shared filesystem planning logic as OpenRC
- **AND** it SHALL vary only profile/init metadata that is genuinely profile-specific
