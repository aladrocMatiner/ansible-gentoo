## ADDED Requirements

### Requirement: Download Cache And Mirror Policy
The project SHALL define safe cache and mirror behavior for downloaded installation artifacts.

#### Scenario: Project-local cache
- **WHEN** installer downloads artifacts
- **THEN** it SHALL use documented project-local or live-ISO-local cache paths
- **AND** it SHALL NOT write to arbitrary host paths

#### Scenario: Verified cache reuse
- **WHEN** a cached stage3 artifact is reused
- **THEN** checksum/signature verification SHALL still pass before extraction

#### Scenario: Mirror override
- **WHEN** an operator overrides mirrors
- **THEN** the variable and source shall be documented
- **AND** the workflow SHALL still verify downloaded artifacts

#### Scenario: Partial download
- **WHEN** a download fails or is interrupted
- **THEN** partial files SHALL NOT be treated as verified artifacts
