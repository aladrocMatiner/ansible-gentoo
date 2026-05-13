# libvirt-e2e-matrix-runner Specification

## Purpose
TBD - created by archiving change implement-libvirt-e2e-matrix-runner. Update Purpose after archive.
## Requirements
### Requirement: Libvirt E2E Matrix Runner
The project SHALL provide a Makefile-mediated runner for full disposable libvirt end-to-end validation across the supported amd64 profile/filesystem/stage3 flavor matrix.

#### Scenario: Run all supported cases
- **WHEN** an operator runs the matrix E2E target with required confirmations
- **THEN** the workflow SHALL run amd64 OpenRC/systemd, ext4/Btrfs, and supported stage3 flavor cases
- **AND** each case SHALL execute through the existing single-case end-to-end install workflow

#### Scenario: Require explicit destructive-in-VM confirmations
- **WHEN** the matrix E2E target is requested
- **THEN** it SHALL require `I_UNDERSTAND_THIS_WIPES_DISK=yes`
- **AND** it SHALL require `I_UNDERSTAND_BOOTLOADER_CHANGES=yes`
- **AND** it SHALL require `I_UNDERSTAND_CLEANUP_DELETE=DELETE`
- **AND** it SHALL require `VM_E2E_RESET_DISK=yes`

#### Scenario: Keep host storage safe
- **WHEN** matrix E2E validation runs
- **THEN** host block devices SHALL NOT be accepted as VM disks
- **AND** manual `VM_DISK` overrides SHALL be rejected
- **AND** generated qcow2 disks SHALL remain case-specific project-local artifacts

#### Scenario: Report matrix evidence
- **WHEN** matrix E2E validation completes
- **THEN** the workflow SHALL write per-case logs
- **AND** it SHALL write a matrix summary report
- **AND** it SHALL exit non-zero if any case fails

