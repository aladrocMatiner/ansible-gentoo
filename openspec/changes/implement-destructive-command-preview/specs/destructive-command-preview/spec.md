## ADDED Requirements

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

#### Scenario: Preview does not confirm
- **WHEN** a preview completes successfully
- **THEN** it SHALL NOT satisfy or persist destructive confirmation variables
- **AND** destructive apply targets SHALL still require explicit confirmation
