# install-report-summary Specification

## Purpose
TBD - created by archiving change implement-install-report-summary. Update Purpose after archive.
## Requirements
### Requirement: Install Report Summary
The project SHALL produce a concise human-readable install report summary.

#### Scenario: Generate summary
- **WHEN** an install report is requested
- **THEN** it SHALL summarize run id, profile, filesystem, disk identity, partitions, UUIDs, hostname, users, network, kernel, bootloader, final checks, and next action when available

#### Scenario: Secret-safe summary
- **WHEN** the report includes access or authentication status
- **THEN** it SHALL omit passwords, password hashes, tokens, private keys, and secret variable values

#### Scenario: Audit linkage
- **WHEN** an audit bundle exists
- **THEN** the report SHALL include the audit bundle path

