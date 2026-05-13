## ADDED Requirements

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
