# destructive-command-preview Specification

## Purpose
TBD - created by archiving change implement-destructive-command-preview. Update Purpose after archive.
## Requirements
### Requirement: Destructive Command Preview
The project SHALL provide read-only previews for destructive or high-risk installer operations before execution.

#### Scenario: Preview disk operation
- **WHEN** an operator previews a partitioning or formatting operation
- **THEN** the workflow SHALL show disk identity, current partition table, current filesystems, current mountpoints, planned operations, and required confirmations
- **AND** it SHALL NOT mutate disks, filesystems, mountpoints, or state outside logs

#### Scenario: Preview bootloader operation
- **WHEN** an operator previews bootloader installation
- **THEN** the workflow SHALL show the target disk, EFI mountpoint, current EFI boot entries, and planned bootloader tasks
- **AND** it SHALL NOT run `grub-install`, `efibootmgr`, or equivalent bootloader-modifying operations

#### Scenario: Preview mount-over operation
- **WHEN** an operator previews target mounting
- **THEN** the workflow SHALL show planned root and EFI mountpoints, source partitions, filesystem options, and current mountpoint state
- **AND** it SHALL NOT mount, unmount, create directories, or create subvolumes

#### Scenario: Preview user and password operation
- **WHEN** an operator previews target user or password changes
- **THEN** the workflow SHALL show the admin username, groups, privilege tool, SSH enablement, whether optional secret input files are set, and planned user/access changes
- **AND** it SHALL NOT print password hashes, authorized key contents, private keys, or local secret file paths
- **AND** it SHALL NOT create users, change passwords, write sudoers files, install authorized keys, or enable services

#### Scenario: Preview does not confirm
- **WHEN** a preview completes successfully
- **THEN** it SHALL NOT satisfy or persist destructive confirmation variables
- **AND** destructive apply targets SHALL still require explicit confirmation

