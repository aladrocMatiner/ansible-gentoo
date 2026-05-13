## ADDED Requirements

### Requirement: Installed SSH Policy
The project SHALL define SSH behavior for the installed Gentoo target.

#### Scenario: SSH disabled
- **WHEN** `ENABLE_SSH` is not enabled
- **THEN** installed SSH service enablement SHALL NOT be assumed

#### Scenario: SSH enabled
- **WHEN** `ENABLE_SSH=yes`
- **THEN** the workflow SHALL install and enable the approved SSH service through init-specific logic
- **AND** final checks SHALL verify SSH package/service status

#### Scenario: Root SSH safety
- **WHEN** SSH is configured
- **THEN** passwordless root SSH and root password login SHALL NOT be enabled by default

#### Scenario: Authorized keys
- **WHEN** authorized keys are configured
- **THEN** they SHALL come from approved secret-safe channels
- **AND** private keys SHALL NOT be stored in the repository, logs, state, or audit bundles
