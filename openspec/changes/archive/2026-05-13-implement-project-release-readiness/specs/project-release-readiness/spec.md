## ADDED Requirements

### Requirement: Release Readiness
The project SHALL define a release readiness checklist before the first usable installer milestone.

#### Scenario: Documentation matches implementation
- **WHEN** release readiness is checked
- **THEN** README and docs SHALL describe implemented behavior accurately
- **AND** planned behavior SHALL be labeled as planned

#### Scenario: No local artifacts or secrets
- **WHEN** the repository is reviewed for release
- **THEN** it SHALL NOT track secrets, ISO files, qcow2 disks, or local credentials

#### Scenario: Guardrail status
- **WHEN** release readiness is checked
- **THEN** the checklist SHALL report audit bundle, secret input policy, Handbook traceability, libvirt matrix, first-boot validation, install report, real hardware readiness, cleanup/reset, supported host requirements, and manual escape-hatch status
