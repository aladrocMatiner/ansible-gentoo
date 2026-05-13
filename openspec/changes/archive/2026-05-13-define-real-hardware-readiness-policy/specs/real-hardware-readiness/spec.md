## ADDED Requirements

### Requirement: Real Hardware Readiness
The project SHALL require a documented readiness check before destructive workflows are run on physical hardware.

#### Scenario: Readiness check
- **WHEN** an operator prepares for real hardware installation
- **THEN** the workflow SHALL provide a read-only readiness check covering backups, UEFI, network, power, disk identity, and validation status

#### Scenario: Stable disk identity
- **WHEN** a real hardware destructive workflow is planned
- **THEN** the operator SHALL be encouraged to use stable disk identity paths where possible
- **AND** no default disk SHALL be inferred

#### Scenario: Libvirt validation
- **WHEN** libvirt validation has not been completed for the selected profile/filesystem/stage3 flavor
- **THEN** real hardware docs/checks SHALL warn clearly and require explicit acknowledgement before destructive work
