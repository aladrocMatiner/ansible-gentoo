# ansible-mount-target Specification

## Purpose
TBD - created by archiving change implement-ansible-mount-target. Update Purpose after archive.
## Requirements
### Requirement: Target Mount Apply
The project SHALL mount the approved target root and EFI filesystems through a guarded Makefile-mediated workflow.

#### Scenario: Mount ext4 target
- **WHEN** ext4 filesystems exist on approved partitions
- **THEN** the workflow SHALL mount root at `/mnt/gentoo` and EFI at `/mnt/gentoo/boot/efi`

#### Scenario: Mount Btrfs target
- **WHEN** Btrfs filesystems and subvolumes exist
- **THEN** the workflow SHALL mount root with `subvol=@`
- **AND** mount approved Btrfs subvolumes at their target paths according to the approved Btrfs layout policy
- **AND** mount EFI at `/mnt/gentoo/boot/efi`

#### Scenario: Mount preview
- **WHEN** target mount apply is requested
- **THEN** the workflow SHALL report planned mount-over behavior before changing mount state

