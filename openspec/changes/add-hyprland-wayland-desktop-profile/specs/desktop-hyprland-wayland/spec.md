## ADDED Requirements

### Requirement: Hyprland Wayland Post-Install Desktop Profile
The project SHALL define an optional post-install Ansible profile for installing and validating Hyprland as an advanced Wayland desktop option.

#### Scenario: Require explicit installed target
- **WHEN** the Hyprland profile runs
- **THEN** it SHALL require an installed Gentoo target reachable over SSH
- **AND** it SHALL fail if the target is the live ISO install environment

#### Scenario: Gate experimental installation
- **WHEN** Hyprland is classified as experimental by the project package policy
- **THEN** installation SHALL require `DESKTOP_EXPERIMENTAL_OK=yes`
- **AND** the workflow SHALL NOT add overlays, unmask packages, accept unstable keywords, or build from source by default

#### Scenario: Reuse shared desktop flow
- **WHEN** Hyprland is installed
- **THEN** the workflow SHALL use Makefile-mediated desktop targets with `DESKTOP_PROFILE=hyprland-wayland`
- **AND** common desktop and Wayland helper behavior SHALL be reused where practical

#### Scenario: Preserve installer boundary
- **WHEN** the Hyprland profile runs
- **THEN** it SHALL NOT partition, format, modify bootloader state, modify EFI entries, extract stage3, or run live ISO installer phases

#### Scenario: Validate Hyprland state
- **WHEN** desktop validation runs
- **THEN** it SHALL verify the selected user exists, Hyprland is installed, session configuration exists, and enabled helper packages are present
