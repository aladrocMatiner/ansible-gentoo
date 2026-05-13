## ADDED Requirements

### Requirement: Logging And Error Taxonomy
The project SHALL use shared error categories and project-local logs for installer workflows.

#### Scenario: Structured error
- **WHEN** a workflow fails
- **THEN** it SHALL report a clear error category, summary, safe context, and recovery hint where practical

#### Scenario: Project-local logs
- **WHEN** logs are written
- **THEN** they SHALL be written under project-local log paths
- **AND** they SHALL be associated with a run id when available

#### Scenario: Secret-safe logs
- **WHEN** log output includes configuration or failure context
- **THEN** it SHALL omit or redact secret values
