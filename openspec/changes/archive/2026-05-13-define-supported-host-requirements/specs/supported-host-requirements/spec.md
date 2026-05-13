## ADDED Requirements

### Requirement: Supported Host Requirements
The project SHALL define and check host prerequisites for libvirt-based testing.

#### Scenario: Host check
- **WHEN** host readiness is checked
- **THEN** the workflow SHALL report required tools, libvirt access, UEFI firmware, network availability, storage, and ISO status
- **AND** it SHALL be read-only

#### Scenario: Boundary clarity
- **WHEN** host requirements are documented
- **THEN** docs SHALL distinguish host requirements from live ISO and installed target requirements

#### Scenario: Missing requirement
- **WHEN** a host requirement is missing
- **THEN** the workflow SHALL fail or warn with an actionable message before VM workflows depend on it
