# ansible-bootloader-grub Specification

## Purpose
TBD - created by archiving change implement-ansible-bootloader-grub. Update Purpose after archive.
## Requirements
### Requirement: GRUB UEFI Bootloader
The project SHALL install GRUB for UEFI through a high-risk guarded workflow.

#### Scenario: UEFI required
- **WHEN** bootloader installation runs outside UEFI mode
- **THEN** it SHALL fail before GRUB installation

#### Scenario: EFI entries shown
- **WHEN** bootloader installation is requested
- **THEN** current EFI boot entries SHALL be shown before changes
- **AND** the workflow SHALL print or call a read-only bootloader preview before accepting confirmation

#### Scenario: Project EFI mountpoint
- **WHEN** GRUB is installed for UEFI
- **THEN** it SHALL use the target EFI mountpoint `/boot/efi`
- **AND** before chroot this SHALL correspond to `/mnt/gentoo/boot/efi`

#### Scenario: Bootloader evidence
- **WHEN** bootloader installation completes
- **THEN** the workflow SHALL record non-secret bootloader and EFI evidence in logs or audit output

#### Scenario: Boot command line policy
- **WHEN** GRUB configuration is generated
- **THEN** it SHALL follow the approved boot kernel command line policy for root UUID and Btrfs `rootflags=subvol=@` behavior

