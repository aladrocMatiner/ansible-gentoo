## MODIFIED Requirements

### Requirement: Stage3 Verification Policy
The project SHALL verify official Gentoo stage3 artifacts before extraction.

#### Scenario: Checksum verification
- **WHEN** a stage3 tarball is downloaded
- **THEN** the workflow SHALL verify it against official checksum metadata before extraction
- **AND** checksum failure SHALL stop the workflow

#### Scenario: Signed latest index verification
- **WHEN** the selected official `latest-stage3-*` index is OpenPGP clearsigned
- **THEN** the workflow SHALL verify that latest index before extraction
- **AND** latest-index signature failure SHALL stop the workflow

#### Scenario: Unsigned latest index handling
- **WHEN** the selected official `latest-stage3-*` index is not OpenPGP clearsigned
- **THEN** the workflow SHALL record that the latest index was unsigned
- **AND** the workflow SHALL treat the latest index as selection metadata only
- **AND** extraction SHALL still require signed DIGESTS verification, tarball detached signature verification, and checksum verification

#### Scenario: Mandatory artifact signature verification
- **WHEN** official tarball signature metadata and signed DIGESTS metadata are available
- **THEN** the workflow SHALL verify both before extraction
- **AND** signature failure SHALL stop the workflow

#### Scenario: Signature unavailable
- **WHEN** mandatory tarball or DIGESTS signature verification cannot be performed
- **THEN** the workflow SHALL fail closed or require an explicit documented override approved by OpenSpec

#### Scenario: Verification evidence
- **WHEN** verification completes
- **THEN** filenames, timestamps, checksum status, latest-index signature status, mandatory artifact signature status, and signature status SHALL be logged without secrets
