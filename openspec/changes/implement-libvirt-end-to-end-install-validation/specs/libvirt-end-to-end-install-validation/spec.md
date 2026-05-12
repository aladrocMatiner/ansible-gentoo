## ADDED Requirements

### Requirement: Libvirt End-to-End Install Validation
The project SHALL validate full installer flows in libvirt before real hardware use.

#### Scenario: VM storage safety
- **WHEN** end-to-end validation runs
- **THEN** it SHALL use only project-local qcow2 storage
- **AND** it SHALL NOT attach host block devices

#### Scenario: Installed boot validation
- **WHEN** installation completes in VM
- **THEN** validation SHALL boot from the virtual disk and verify network access

#### Scenario: Matrix integration
- **WHEN** end-to-end validation is planned
- **THEN** it SHALL report OpenRC/systemd, ext4/Btrfs, and supported stage3 flavor validation status

#### Scenario: Audit evidence
- **WHEN** end-to-end validation completes
- **THEN** it SHALL write or reference logs and audit bundle evidence
