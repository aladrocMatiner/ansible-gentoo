## ADDED Requirements

### Requirement: Desktop Login Manager Reuses Post-Install Ansible Architecture
The desktop login manager workflow SHALL follow the reuse-first Ansible architecture.

#### Scenario: Common login manager behavior is shared
- **WHEN** Ansible implements desktop login manager behavior
- **THEN** installed-target validation, package-policy checks, variable normalization, session allowlists, session-entry templates, dispatcher validation, confirmation checks, and documentation evidence SHALL live in shared post-install roles or task files
- **AND** desktop-profile roles SHALL NOT duplicate login manager package, service, or session-entry logic

#### Scenario: Greetd-specific behavior is isolated
- **WHEN** `DESKTOP_DISPLAY_MANAGER=greetd` is selected
- **THEN** only `greetd` package selection, config rendering, greeter validation, and manager-specific validation SHALL live in a greetd-specific role or task file
- **AND** common session and installed-target behavior SHALL remain shared

#### Scenario: Init-specific service enablement and runtime state are isolated
- **WHEN** login manager service state is changed
- **THEN** OpenRC service enablement and start operations SHALL use only OpenRC-specific tasks
- **AND** systemd service enablement and start operations SHALL use only systemd-specific tasks
- **AND** init-specific tasks SHALL NOT bypass shared confirmation or installed-target validation

#### Scenario: Existing desktop profiles remain reusable
- **WHEN** desktop login manager support is added
- **THEN** existing `i3-x11`, `sway-wayland`, `hyprland-wayland`, `niri-wayland`, and `mango-wayland` profile roles SHALL remain responsible for installing their desktop packages and user configs
- **AND** the login manager workflow SHALL consume validated installed profile state instead of reimplementing profile installation

#### Scenario: Makefile targets call shared flow
- **WHEN** Makefile exposes desktop login manager operations
- **THEN** `desktop-login-plan`, `desktop-login-install`, and `desktop-login-validate` SHALL call shared Ansible entrypoints where practical
- **AND** they SHALL pass display-manager, session, target, user, and confirmation variables through documented wrapper logic
