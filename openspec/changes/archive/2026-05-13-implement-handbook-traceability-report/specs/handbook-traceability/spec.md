## ADDED Requirements

### Requirement: Handbook Traceability
The project SHALL maintain a traceability view from installer implementation to the official Gentoo AMD64 Handbook baseline.

#### Scenario: Role trace entry
- **WHEN** an installer role or playbook implements a Gentoo installation phase
- **THEN** it SHALL identify the related Handbook phase or a documented project-specific deviation

#### Scenario: Generate trace report
- **WHEN** the traceability report is generated
- **THEN** it SHALL list installer phases, Makefile targets, Ansible roles, implementation status, safety gates, and deviations
- **AND** it SHALL be read-only

#### Scenario: Reviewed deviation
- **WHEN** project behavior differs from the Handbook's simplest example
- **THEN** the deviation SHALL be documented with the project reason and OpenSpec change reference where practical
