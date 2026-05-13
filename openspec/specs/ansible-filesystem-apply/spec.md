# ansible-filesystem-apply Specification

## Purpose
TBD - created by archiving change implement-ansible-filesystem-apply. Update Purpose after archive.
## Requirements
### Requirement: Destructive Filesystem Apply
The project SHALL provide a guarded filesystem apply workflow that creates filesystems only on approved partition paths after explicit confirmation.

#### Scenario: Create ext4 layout
- **WHEN** `FILESYSTEM=ext4` and confirmation is present
- **THEN** the workflow SHALL create vfat on the ESP and ext4 on the root partition

#### Scenario: Create Btrfs layout
- **WHEN** `FILESYSTEM=btrfs` and confirmation is present
- **THEN** the workflow SHALL create vfat on the ESP and Btrfs on the root partition
- **AND** it SHALL create the approved Btrfs subvolumes
- **AND** it SHALL follow the approved Btrfs layout policy

#### Scenario: Verify formatting tools
- **WHEN** filesystem apply starts
- **THEN** required formatting tools for the selected filesystem SHALL be verified before destructive commands run
- **AND** missing tools SHALL fail clearly before formatting

#### Scenario: Preview before format
- **WHEN** filesystem apply is requested
- **THEN** the workflow SHALL print or call a read-only destructive preview before accepting confirmation

