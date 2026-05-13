# config-validation-report Specification

## Purpose
TBD - created by archiving change implement-config-validation-report. Update Purpose after archive.
## Requirements
### Requirement: Config Validation Report
The project SHALL provide a read-only configuration validation report before installer workflows rely on operator variables.

#### Scenario: Validate schema
- **WHEN** config validation runs
- **THEN** it SHALL validate operator variables against the install configuration schema
- **AND** unsupported or missing values SHALL produce actionable errors

#### Scenario: Read-only behavior
- **WHEN** config validation runs
- **THEN** it SHALL NOT partition, format, mount, chroot, install packages, create users, change passwords, or install bootloaders

#### Scenario: Secret policy check
- **WHEN** config validation inspects inputs
- **THEN** it SHALL detect or reject obvious secret-policy violations without printing secret values

#### Scenario: Next action
- **WHEN** config validation completes
- **THEN** it SHALL report PASS/FAIL and the next safe Makefile target when determinable

