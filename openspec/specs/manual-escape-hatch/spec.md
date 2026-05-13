# manual-escape-hatch Specification

## Purpose
TBD - created by archiving change define-manual-escape-hatch-policy. Update Purpose after archive.
## Requirements
### Requirement: Manual Escape Hatch
The project SHALL define how manual intervention is recorded and revalidated before resuming automation.

#### Scenario: Record manual intervention
- **WHEN** an operator performs a manual step during installation
- **THEN** the project SHALL provide a way to record non-secret notes about what changed and why

#### Scenario: Revalidate after manual step
- **WHEN** automation resumes after manual intervention
- **THEN** the workflow SHALL re-run relevant validation and fail closed if state differs unexpectedly

#### Scenario: No safety bypass
- **WHEN** manual intervention occurs before a destructive step
- **THEN** subsequent destructive automation SHALL still require the standard safety gates and confirmations

