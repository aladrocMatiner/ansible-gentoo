# cleanup-reset-policy Specification

## Purpose
TBD - created by archiving change implement-cleanup-and-reset-policy. Update Purpose after archive.
## Requirements
### Requirement: Cleanup Reset Policy
The project SHALL define safe cleanup and reset behavior for generated project artifacts.

#### Scenario: Confirm destructive cleanup
- **WHEN** cleanup deletes generated disks, logs, state, audit bundles, or downloaded artifacts
- **THEN** it SHALL require explicit confirmation
- **AND** it SHALL report exactly what paths are eligible for deletion

#### Scenario: Path boundary
- **WHEN** cleanup runs
- **THEN** it SHALL operate only under approved project-local paths
- **AND** it SHALL NOT delete arbitrary paths, host block devices, or symlink-escaped files

#### Scenario: Audit preservation
- **WHEN** cleanup runs without an explicit audit cleanup scope
- **THEN** audit bundles SHALL be preserved by default

