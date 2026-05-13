# ansible-users-and-access Specification

## Purpose
TBD - created by archiving change implement-ansible-users-and-access. Update Purpose after archive.
## Requirements
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

#### Scenario: Passwordless sudo policy
- **WHEN** passwordless sudo is requested for the admin account
- **THEN** the workflow SHALL require an explicit yes/no policy value
- **AND** password-requiring sudo SHALL remain the normal default outside disposable E2E tests

### Requirement: Configurable Admin Passwordless Sudo
The project SHALL support an explicit admin sudo policy option that can require passwords by default or allow passwordless sudo for disposable test installs.

#### Scenario: Normal installs default to password-requiring sudo
- **WHEN** `ADMIN_SUDO_NOPASSWD` is unset for a normal installer or configure-users workflow
- **THEN** the workflow SHALL configure sudo without `NOPASSWD`

#### Scenario: Explicit passwordless sudo
- **WHEN** `ADMIN_SUDO_NOPASSWD=yes` is provided
- **THEN** the users role SHALL configure the admin sudoers drop-in with `NOPASSWD: ALL`
- **AND** final checks SHALL validate that passwordless sudo is present

#### Scenario: Disposable libvirt E2E default
- **WHEN** `make vm-e2e-install` or `make vm-e2e-matrix` runs without an explicit `ADMIN_SUDO_NOPASSWD`
- **THEN** the workflow SHALL use `VM_E2E_ADMIN_SUDO_NOPASSWD=yes`
- **AND** first-boot validation SHALL verify non-interactive sudo for the installed admin user

#### Scenario: Secret safety preserved
- **WHEN** passwordless sudo is enabled
- **THEN** the workflow SHALL NOT create, log, or commit plaintext passwords, password hashes, private keys, or tokens

