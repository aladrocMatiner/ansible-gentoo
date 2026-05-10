## ADDED Requirements

### Requirement: Safe User and Access Configuration
The project SHALL configure target users and privileged access without committing secrets.

#### Scenario: Missing admin user
- **WHEN** user creation is requested without an explicit admin username
- **THEN** the workflow SHALL fail before creating users

#### Scenario: No plaintext secrets
- **WHEN** user access configuration is committed
- **THEN** it SHALL NOT contain plaintext passwords, private keys, tokens, or local credentials

#### Scenario: Secret-safe input
- **WHEN** passwords, password hashes, SSH keys, or privileged access secrets are provided
- **THEN** the workflow SHALL follow the approved secret input policy
- **AND** logs, state, and audit bundles SHALL NOT expose secret values

#### Scenario: Installed SSH policy
- **WHEN** SSH access is configured for the installed target
- **THEN** root SSH restrictions and authorized key handling SHALL follow the installed SSH policy
