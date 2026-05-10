## ADDED Requirements

### Requirement: Reboot Readiness Checks
The project SHALL provide read-only final checks that determine whether the installed system is ready for manual reboot.

#### Scenario: Required artifact missing
- **WHEN** kernel, fstab, GRUB, EFI files, or network enablement is missing
- **THEN** final checks SHALL fail
- **AND** the workflow SHALL NOT reboot automatically

#### Scenario: Audit bundle reference
- **WHEN** final checks complete
- **THEN** the workflow SHALL produce or reference a secret-safe audit bundle path

#### Scenario: Btrfs final check
- **WHEN** `FILESYSTEM=btrfs`
- **THEN** final checks SHALL verify root uses `subvol=@` and approved Btrfs subvolume entries

#### Scenario: Target baseline
- **WHEN** final checks run
- **THEN** they SHALL evaluate the target system baseline, including hostname, timezone, locale, package/service status, users, and boot readiness
- **AND** they SHALL provide inputs for the install report summary

#### Scenario: Target policies
- **WHEN** final checks run
- **THEN** they SHALL report installed time sync status, installed SSH status when enabled, Portage sync/update/config-update status, and boot kernel command line status
