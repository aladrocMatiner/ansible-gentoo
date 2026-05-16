## ADDED Requirements

### Requirement: Sway Wayland Post-Install Desktop Profile
The project SHALL define an optional post-install Ansible profile for installing and validating Sway as the conservative Wayland desktop option.

#### Scenario: Require stable installed system
- **WHEN** the Sway profile runs
- **THEN** it SHALL require an installed Gentoo target reachable over SSH
- **AND** it SHALL fail if the target is the live ISO install environment

#### Scenario: Use Makefile desktop flow
- **WHEN** an operator installs Sway
- **THEN** the workflow SHALL be exposed through Makefile targets
- **AND** it SHALL use the shared post-install desktop Ansible flow with `DESKTOP_PROFILE=sway-wayland`

#### Scenario: Keep Wayland behavior isolated
- **WHEN** the Sway role is implemented
- **THEN** Sway package, session, portal, and Wayland validation behavior SHALL live in the Sway-specific role
- **AND** common desktop validation and package framework behavior SHALL be reused

#### Scenario: Avoid destructive installer behavior
- **WHEN** the Sway profile runs
- **THEN** it SHALL NOT partition, format, modify bootloader state, modify EFI entries, extract stage3, or run live ISO installer phases

#### Scenario: Validate Sway state
- **WHEN** desktop validation runs
- **THEN** it SHALL verify the selected user exists, Sway is installed, required Wayland helpers are installed where enabled, and no display manager is enabled unless explicitly requested
