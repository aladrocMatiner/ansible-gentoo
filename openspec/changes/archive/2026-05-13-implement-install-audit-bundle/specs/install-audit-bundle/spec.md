## ADDED Requirements

### Requirement: Install Audit Bundle
The project SHALL produce a secret-safe audit bundle for installation runs.

#### Scenario: Generate bundle
- **WHEN** an audit bundle is requested through Makefile
- **THEN** the workflow SHALL write non-secret installation evidence under project-local logs
- **AND** it SHALL include disk, partition, filesystem, mount, stage3, Portage, kernel, service, bootloader, and final-check evidence when available

#### Scenario: Secret safety
- **WHEN** audit data is collected
- **THEN** passwords, API keys, login tokens, private keys, and secret variable values SHALL be omitted or redacted
- **AND** the workflow SHALL fail or warn clearly if it detects unsafe secret material

#### Scenario: Final checks integration
- **WHEN** final checks complete
- **THEN** the final report SHALL be included in the audit bundle or point to the generated bundle path
