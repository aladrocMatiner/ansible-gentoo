# boot-kernel-commandline Specification

## Purpose
TBD - created by archiving change define-boot-kernel-commandline-policy. Update Purpose after archive.
## Requirements
### Requirement: Boot Kernel Commandline Policy
The project SHALL define kernel command line expectations for the installed Gentoo target.

#### Scenario: Root by stable identifier
- **WHEN** GRUB configuration is generated
- **THEN** it SHALL reference the intended root filesystem by stable identifier where practical
- **AND** no disk shall be inferred from a default device path

#### Scenario: Btrfs root flags
- **WHEN** `FILESYSTEM=btrfs`
- **THEN** boot configuration SHALL include `rootflags=subvol=@` or equivalent verified behavior for the approved root subvolume

#### Scenario: v1 exclusions
- **WHEN** boot configuration is generated for v1
- **THEN** it SHALL NOT include LUKS or BIOS-only assumptions

#### Scenario: Final validation
- **WHEN** final checks run
- **THEN** they SHALL verify GRUB/kernel command line root UUID and Btrfs root flags when applicable

