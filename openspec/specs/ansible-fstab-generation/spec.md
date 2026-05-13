# ansible-fstab-generation Specification

## Purpose
TBD - created by archiving change implement-ansible-fstab-generation. Update Purpose after archive.
## Requirements
### Requirement: UUID-based fstab
The project SHALL generate target fstab entries from verified filesystem UUIDs.

#### Scenario: ext4 fstab
- **WHEN** `FILESYSTEM=ext4`
- **THEN** fstab SHALL include root and EFI UUID entries
- **AND** the EFI entry SHALL mount at `/boot/efi`

#### Scenario: Btrfs fstab
- **WHEN** `FILESYSTEM=btrfs`
- **THEN** fstab SHALL include root and planned subvolume entries with explicit subvolume options
- **AND** the root entry SHALL include `subvol=@`

