## ADDED Requirements

### Requirement: Secret Input Policy
The project SHALL define and enforce secret-safe input and logging behavior.

#### Scenario: Secret input
- **WHEN** a workflow requires a password, token, private key, or secret variable
- **THEN** it SHALL use an approved secret-safe channel
- **AND** it SHALL NOT require committing secret material to the repository

#### Scenario: Secret documentation
- **WHEN** documentation describes secret variables
- **THEN** it SHALL use `.env.example` variable names with empty secret values only
- **AND** it SHALL NOT include real secret values

#### Scenario: Secret logs and bundles
- **WHEN** logs, state files, or audit bundles are written
- **THEN** secret values SHALL be omitted, redacted, or rejected

#### Scenario: Secret scan
- **WHEN** release readiness or final checks run
- **THEN** the workflow SHALL include a secret-safety check or document why it is unavailable
