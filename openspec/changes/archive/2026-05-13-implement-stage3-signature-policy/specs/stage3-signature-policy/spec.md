## ADDED Requirements

### Requirement: Stage3 Verification Policy
The project SHALL verify official Gentoo stage3 artifacts before extraction.

#### Scenario: Checksum verification
- **WHEN** a stage3 tarball is downloaded
- **THEN** the workflow SHALL verify it against official checksum metadata before extraction
- **AND** checksum failure SHALL stop the workflow

#### Scenario: Signature verification
- **WHEN** official signature metadata and required verification tooling are available
- **THEN** the workflow SHALL verify the stage3 metadata signature before extraction
- **AND** signature failure SHALL stop the workflow

#### Scenario: Signature unavailable
- **WHEN** signature verification cannot be performed
- **THEN** the workflow SHALL fail closed or require an explicit documented override approved by OpenSpec

#### Scenario: Verification evidence
- **WHEN** verification completes
- **THEN** filenames, timestamps, checksum status, and signature status SHALL be logged without secrets
